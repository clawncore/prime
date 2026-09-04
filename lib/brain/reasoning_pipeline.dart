import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/prime_identity.dart';
import 'llm_provider.dart';
import 'conversation_manager.dart';

/// Processing stage in the reasoning pipeline
enum PipelineStage {
  analyze,
  reason,
  synthesize,
}

extension PipelineStageExt on PipelineStage {
  String get label {
    switch (this) {
      case PipelineStage.analyze:
        return 'ANALYZING';
      case PipelineStage.reason:
        return 'REASONING';
      case PipelineStage.synthesize:
        return 'SYNTHESIZING';
    }
  }

  String get icon {
    switch (this) {
      case PipelineStage.analyze:
        return '🔍';
      case PipelineStage.reason:
        return '⚙️';
      case PipelineStage.synthesize:
        return '✦';
    }
  }
}

enum StepStatus { pending, active, complete, error }

class PipelineStep {
  final PipelineStage stage;
  final StepStatus status;
  final String text;
  final int durationMs;

  const PipelineStep({
    required this.stage,
    required this.status,
    this.text = '',
    this.durationMs = 0,
  });
}

class PipelineResult {
  final String finalResponse;
  final List<PipelineStep> steps;
  final Duration totalDuration;
  final String requestId;
  final int promptChars;
  final int responseChars;
  final int responseWords;

  const PipelineResult({
    required this.finalResponse,
    required this.steps,
    required this.totalDuration,
    required this.requestId,
    this.promptChars = 0,
    this.responseChars = 0,
    this.responseWords = 0,
  });
}

/// Single-call reasoning pipeline with STREAMING output.
///
/// Sends ONE LLM call using streaming. Tokens are emitted to
/// chunkStream as they arrive so the UI can render progressively.

class ReasoningPipeline {
  final LLMProvider _llm;
  final ConversationManager _conversation;
  final StreamController<PipelineStep>? _stepController;
  final StreamController<String>? _chunkController;

  ReasoningPipeline({
    required LLMProvider llm,
    required ConversationManager conversation,
    StreamController<PipelineStep>? stepController,
    StreamController<String>? chunkController,
  })  : _llm = llm,
        _conversation = conversation,
        _stepController = stepController,
        _chunkController = chunkController;

  String _makeRequestId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'REQ-${now.toRadixString(36).toUpperCase()}';
  }

  Future<PipelineResult> execute(String userMessage) async {
    final requestId = _makeRequestId();
    final stopwatch = Stopwatch()..start();
    final steps = <PipelineStep>[];
    final responseBuffer = StringBuffer();

    debugPrint('[Pipeline][$requestId] START — input="${userMessage.length > 60 ? userMessage.substring(0, 60) + "..." : userMessage}"');

    // Build context
    final ctxSw = Stopwatch()..start();
    final context = _conversation.getContext();
    ctxSw.stop();
    debugPrint('[Pipeline][$requestId] CONTEXT — ${ctxSw.elapsedMilliseconds}ms, turns=${context.length}');

    // ANALYZE — instant classification
    final analyzeStart = stopwatch.elapsedMilliseconds;
    _emitStep(PipelineStep(stage: PipelineStage.analyze, status: StepStatus.active));
    final isComplex = _isComplexQuery(userMessage);
    final analyzeMs = stopwatch.elapsedMilliseconds - analyzeStart;
    steps.add(PipelineStep(
      stage: PipelineStage.analyze,
      status: StepStatus.complete,
      text: isComplex ? 'complex' : 'simple',
      durationMs: analyzeMs,
    ));
    _emitStep(steps.last);

    // REASON — streaming LLM call
    _emitStep(PipelineStep(stage: PipelineStage.reason, status: StepStatus.active));

    final llmSw = Stopwatch()..start();
    final prompt = _buildPrompt(userMessage, context);
    debugPrint('[Pipeline][$requestId] LLM REQUEST — promptChars=${prompt.length}');

    if (_llm.supportsStreaming) {
      // STREAMING path — tokens arrive in real-time
      debugPrint('[Pipeline][$requestId] USING STREAMING');
      int chunkCount = 0;
      bool firstToken = false;

      final stream = _llm.streamGenerate(
        userMessage: prompt,
        context: [],
        systemPrompt: PrimeIdentity.systemPrompt,
      );

      if (stream != null) {
        await for (final chunk in stream) {
          if (chunk.isComplete) {
            debugPrint('[Pipeline][$requestId] STREAM COMPLETE — '
                'chunks=$chunkCount, time=${llmSw.elapsedMilliseconds}ms');
            break;
          }

          if (chunk.text.isNotEmpty) {
            if (!firstToken) {
              firstToken = true;
              debugPrint('[Pipeline][$requestId] FIRST TOKEN — ${llmSw.elapsedMilliseconds}ms');
            }
            chunkCount++;
            responseBuffer.write(chunk.text);
            _chunkController?.add(chunk.text);
          }
        }
        llmSw.stop();
      } else {
        // Streaming claimed but returned null — fall back
        debugPrint('[Pipeline][$requestId] STREAM NULL — fallback');
        final response = await _llm.generate(
          userMessage: prompt,
          context: [],
          systemPrompt: PrimeIdentity.systemPrompt,
        );
        llmSw.stop();
        responseBuffer.write(response.text);
      }
    } else {
      // NON-STREAMING fallback
      debugPrint('[Pipeline][$requestId] USING NON-STREAMING');
      final response = await _llm.generate(
        userMessage: prompt,
        context: [],
        systemPrompt: PrimeIdentity.systemPrompt,
      );
      llmSw.stop();
      responseBuffer.write(response.text);

      if (response.type == ResponseType.error) {
        debugPrint('[Pipeline][$requestId] LLM ERROR: ${response.text}');
      }
    }

    final responseText = responseBuffer.toString().trim();
    final responseChars = responseText.length;
    final responseWords = responseText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    debugPrint('[Pipeline][$requestId] LLM COMPLETE — '
        'time=${llmSw.elapsedMilliseconds}ms, '
        'chars=$responseChars, words=$responseWords');

    steps.add(PipelineStep(
      stage: PipelineStage.reason,
      status: StepStatus.complete,
      text: '${llmSw.elapsedMilliseconds}ms — $responseWords words',
      durationMs: llmSw.elapsedMilliseconds,
    ));
    _emitStep(steps.last);

    // SYNTHESIZE — validation (instant)
    _emitStep(PipelineStep(stage: PipelineStage.synthesize, status: StepStatus.active));
    if (responseText.isEmpty) {
      steps.add(PipelineStep(
        stage: PipelineStage.synthesize,
        status: StepStatus.error,
        text: 'Empty response',
        durationMs: 0,
      ));
    } else {
      steps.add(PipelineStep(
        stage: PipelineStage.synthesize,
        status: StepStatus.complete,
        text: '$responseChars chars delivered',
        durationMs: 0,
      ));
    }
    _emitStep(steps.last);

    stopwatch.stop();
    debugPrint('[Pipeline][$requestId] TOTAL — ${stopwatch.elapsedMilliseconds}ms');

    return PipelineResult(
      finalResponse: responseText,
      steps: steps,
      totalDuration: stopwatch.elapsed,
      requestId: requestId,
      promptChars: prompt.length,
      responseChars: responseChars,
      responseWords: responseWords,
    );
  }

  bool _isComplexQuery(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.length > 120) return true;
    const keywords = [
      'how', 'why', 'explain', 'compare', 'analyze', 'difference',
      'step by step', 'write', 'create', 'code', 'implement',
      'design', 'architect', 'plan', 'strategy', 'trade-off',
      'pros and cons', 'evaluate', 'review', 'debug', 'optimize',
    ];
    return keywords.any((kw) => lower.contains(kw));
  }

  String _buildPrompt(String userMessage, List<ConversationTurn> context) {
    final buffer = StringBuffer();
    buffer.writeln(userMessage);
    if (context.isNotEmpty) {
      buffer.writeln('\n[Context:]');
      for (final turn in context) {
        buffer.writeln('${turn.role}: ${turn.content}');
      }
    }
    return buffer.toString();
  }

  void _emitStep(PipelineStep step) {
    _stepController?.add(step);
  }
}
