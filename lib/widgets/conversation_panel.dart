import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';
import '../brain/reasoning_pipeline.dart';
import '../services/state_service.dart';
import '../services/voice_service.dart';

class ConversationPanel extends StatefulWidget {
  const ConversationPanel({super.key});

  @override
  State<ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends State<ConversationPanel> {
  final ScrollController _scroll = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-scroll when conversation or steps change
    final conversation = context.watch<StateService>().conversation;
    final steps = context.watch<StateService>().pendingSteps;
    if (conversation.isNotEmpty || steps.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = context.watch<StateService>().conversation;
    final voiceState = context.watch<StateService>().voiceState;
    final pendingSteps = context.watch<StateService>().pendingSteps;

    // Count total items: messages + active pipeline indicator
    final hasActivePipeline =
        voiceState == VoiceState.processing && pendingSteps.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: PrimeTheme.bgCard,
        border: Border.all(color: PrimeTheme.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: PrimeTheme.borderSubtle),
          Expanded(
            child: conversation.isEmpty && !hasActivePipeline
                ? _buildEmpty(voiceState)
                : _buildMessages(conversation, hasActivePipeline ? pendingSteps : null),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, size: 12, color: PrimeTheme.primeCyan.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text('CONVERSATION', style: PrimeTheme.fontLabel.copyWith(
            fontSize: 10,
            color: PrimeTheme.textSecondary,
          )),
        ],
      ),
    );
  }

  Widget _buildEmpty(VoiceState voiceState) {
    String message;
    switch (voiceState) {
      case VoiceState.listening:
        message = 'LISTENING...';
        break;
      case VoiceState.processing:
        message = 'PRIME IS THINKING...';
        break;
      case VoiceState.speaking:
        message = 'PRIME IS SPEAKING...';
        break;
      default:
        message = 'TALK TO PRIME...';
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic_none, size: 24, color: PrimeTheme.textDim),
          const SizedBox(height: 8),
          Text(message, style: PrimeTheme.fontLabel.copyWith(
            fontSize: 10,
            color: PrimeTheme.textDim,
            letterSpacing: 1.5,
          )),
        ],
      ),
    );
  }

  Widget _buildMessages(
    List<ConversationMessage> messages,
    List<PipelineStep>? activeSteps,
  ) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // +1 for the active pipeline indicator when present
      itemCount: messages.length + (activeSteps != null ? 1 : 0),
      itemBuilder: (context, index) {
        // Active pipeline indicator at the end
        if (activeSteps != null && index == messages.length) {
          return _ThinkingIndicator(steps: activeSteps);
        }

        final msg = messages[index];
        final isUser = msg.role == 'user';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MessageBubble(message: msg, isUser: isUser),
            // Show completed pipeline steps under assistant messages
            if (!isUser && msg.steps.isNotEmpty)
              _StepsTrail(steps: msg.steps),
          ],
        );
      },
    );
  }
}

/// Real-time pipeline step indicator shown while PRIME is thinking
class _ThinkingIndicator extends StatelessWidget {
  final List<PipelineStep> steps;
  const _ThinkingIndicator({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue dot
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5, right: 6),
            decoration: const BoxDecoration(
              color: PrimeTheme.primeBlue,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: PrimeTheme.bgElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: PrimeTheme.primeBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRIME',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: PrimeTheme.primeBlue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...steps.map((step) => _buildStepRow(step)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(PipelineStep step) {
    Color statusColor;
    Widget statusIcon;

    switch (step.status) {
      case StepStatus.active:
        statusColor = PrimeTheme.primeCyan;
        statusIcon = SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation(PrimeTheme.primeCyan),
          ),
        );
        break;
      case StepStatus.complete:
        statusColor = PrimeTheme.statusOnline;
        statusIcon = const Icon(Icons.check_circle, size: 10, color: PrimeTheme.statusOnline);
        break;
      case StepStatus.error:
        statusColor = PrimeTheme.statusError;
        statusIcon = const Icon(Icons.error, size: 10, color: PrimeTheme.statusError);
        break;
      case StepStatus.pending:
        statusColor = PrimeTheme.textDim;
        statusIcon = Icon(Icons.circle_outlined, size: 10, color: PrimeTheme.textDim);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          statusIcon,
          const SizedBox(width: 5),
          Text(
            step.stage.label,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              color: statusColor,
            ),
          ),
          if (step.status == StepStatus.active) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                valueColor: AlwaysStoppedAnimation(
                  PrimeTheme.primeCyan.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
          if (step.status == StepStatus.complete && step.durationMs > 0) ...[
            const Spacer(),
            Text(
              '${step.durationMs}ms',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 8,
                color: PrimeTheme.textDim,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Collapsed trail of pipeline steps shown under completed messages
class _StepsTrail extends StatefulWidget {
  final List<PipelineStep> steps;
  const _StepsTrail({required this.steps});

  @override
  State<_StepsTrail> createState() => _StepsTrailState();
}

class _StepsTrailState extends State<_StepsTrail> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final completedSteps = widget.steps
        .where((s) => s.status == StepStatus.complete || s.status == StepStatus.error)
        .toList();

    if (completedSteps.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 18, bottom: 4),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Always-visible compact summary
              Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 10,
                    color: PrimeTheme.textDim,
                  ),
                  const SizedBox(width: 3),
                  ...completedSteps.map((step) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      '${step.stage.icon} ${step.stage.label}',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 8,
                        color: step.status == StepStatus.error
                            ? PrimeTheme.statusError
                            : PrimeTheme.textDim,
                      ),
                    ),
                  )),
                ],
              ),

              // Expanded details
              if (_expanded) ...[
                const SizedBox(height: 3),
                ...completedSteps.map((step) => Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(
                        '${step.stage.label}: ${step.text}',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 8,
                          color: PrimeTheme.textDim,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final ConversationMessage message;
  final bool isUser;

  const _MessageBubble({required this.message, required this.isUser});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  AnimationController? _blinkController;

  @override
  void initState() {
    super.initState();
    if (widget.message.isStreaming) {
      _blinkController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.isStreaming && _blinkController == null) {
      _blinkController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true);
    } else if (!widget.message.isStreaming && _blinkController != null) {
      _blinkController!.stop();
      _blinkController!.dispose();
      _blinkController = null;
    }
  }

  @override
  void dispose() {
    _blinkController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isUser = widget.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 5, right: 6),
              decoration: BoxDecoration(
                color: PrimeTheme.primeBlue,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isUser
                    ? PrimeTheme.primeCyan.withValues(alpha: 0.08)
                    : PrimeTheme.bgElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: msg.isStreaming
                      ? PrimeTheme.primeBlue.withValues(alpha: 0.4)
                      : isUser
                          ? PrimeTheme.primeCyan.withValues(alpha: 0.15)
                          : PrimeTheme.borderSubtle,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? 'USER' : 'PRIME',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: isUser ? PrimeTheme.primeCyan : PrimeTheme.primeBlue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          msg.content.isEmpty ? '...' : msg.content,
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: msg.content.isEmpty
                                ? PrimeTheme.textDim
                                : PrimeTheme.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                      // Blinking cursor while streaming
                      if (msg.isStreaming && _blinkController != null)
                        AnimatedBuilder(
                          animation: _blinkController!,
                          builder: (context, _) {
                            return Opacity(
                              opacity: _blinkController!.value,
                              child: Container(
                                width: 7,
                                height: 14,
                                margin: const EdgeInsets.only(left: 2, bottom: 1),
                                color: PrimeTheme.primeBlue,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: PrimeTheme.primeCyan,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
