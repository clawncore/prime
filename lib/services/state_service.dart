import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/prime_state.dart';
import '../services/audio_service.dart';
import '../services/voice_service.dart';
import '../services/settings_service.dart';
import '../services/debug_service.dart';
import '../voice/voice_manager.dart';
import '../brain/conversation_manager.dart';
import '../brain/reasoning_pipeline.dart';
import '../providers/factories/provider_factory.dart';
import '../engine/conversation_engine.dart';

class StateService extends ChangeNotifier {
  final AudioService _audio = AudioService.instance;
  final VoiceService _voice = VoiceService.instance;
  final VoiceManager _voiceManager = VoiceManager.instance;

  // Core Intelligence (optional, enabled when configured)
  ConversationEngine? _conversationEngine;
  ProviderFactory? _providerFactory;
  SettingsService? _settingsService;
  DebugService? _debugService;
  ConversationManager? _conversationContext;

  PrimeState _state = PrimeState(lastUpdate: DateTime.now());
  bool _initialized = false;

  // Voice state
  VoiceState _voiceState = VoiceState.idle;
  String _lastCommand = '';
  String _lastResponse = '';
  bool _voiceEnabled = true;

  // LLM availability — separate from coreOnline
  bool _llmAvailable = false;

  // Reasoning pipeline steps — visible to UI during processing
  List<PipelineStep> _pendingSteps = [];
  StreamSubscription<PipelineStep>? _stepSubscription;

  // Streaming text — progressive token delivery
  StreamSubscription<String>? _chunkSubscription;
  String? _streamingMessageId;
  final StringBuffer _streamingBuffer = StringBuffer();

  // Performance diagnostics
  String _lastRequestId = '';
  int _lastPromptChars = 0;
  int _lastResponseChars = 0;
  int _lastResponseWords = 0;
  int _lastTotalMs = 0;

  // Activity feed deduplication
  String? _lastActivityMessage;

  PrimeState get state => _state;
  VoiceService get voice => _voice;

  // Core Intelligence accessors
  ConversationEngine? get conversationEngine => _conversationEngine;
  DebugService? get debugService => _debugService;
  SettingsService? get settingsService => _settingsService;
  bool get coreIntelligenceAvailable => _conversationEngine != null;
  bool get llmAvailable => _llmAvailable;
  List<PipelineStep> get pendingSteps => _pendingSteps;

  // Performance diagnostics getters
  String get lastRequestId => _lastRequestId;
  int get lastPromptChars => _lastPromptChars;
  int get lastResponseChars => _lastResponseChars;
  int get lastResponseWords => _lastResponseWords;
  int get lastTotalMs => _lastTotalMs;

  List<Agent> get agents => _state.agents;
  Telemetry get telemetry => _state.telemetry;
  List<ConversationMessage> get conversation => _state.conversation;
  List<ActivityEvent> get activityFeed => _state.activityFeed;
  PrimeMode get mode => _state.mode;
  bool get coreOnline => _state.coreOnline;
  VoiceState get voiceState => _voiceState;
  String get lastCommand => _lastCommand;
  String get lastResponse => _lastResponse;
  bool get voiceEnabled => _voiceEnabled;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    debugPrint('[StateService] Initializing...');

    // Load .env configuration
    final env = await _loadEnv();

    // Initialize voice service (SAPI for fallback)
    await _voice.initialize();
    _voice.stateStream.listen((voiceState) {
      _voiceState = voiceState;
      notifyListeners();
    });

    _voice.recognizedText.listen((text) {
      if (text.isNotEmpty && _voice.state == VoiceState.processing) {
        handleVoiceCommand(text);
      }
    });

    // Initialize VoiceManager with LLM
    await _voiceManager.initialize(
      geminiApiKey: env['GEMINI_API_KEY'],
      geminiModel: env['GEMINI_MODEL'],
    );

    // Subscribe to reasoning pipeline steps for real-time UI updates + activity feed
    _stepSubscription = _voiceManager.stepStream.listen((step) {
      _updatePendingStep(step);
      _logPipelineStep(step);
    });

    // Subscribe to streaming text chunks — progressive UI rendering
    _chunkSubscription = _voiceManager.chunkStream.listen((chunk) {
      _onStreamingChunk(chunk);
    });

    // Track LLM availability separately from core status
    _llmAvailable = _voiceManager.llmEnabled;
    _addActivity('brain', 'LLM: ${_llmAvailable ? _voiceManager.llmProvider?.name ?? "Enabled" : "Offline (local commands only)"}',
        severity: _llmAvailable ? 'success' : 'warning');

    // Initialize default agents (all idle)
    _initializeDefaultAgents();

    // Boot sequence — truthful, no fake delays
    _startBootSequence();
  }

  void _startBootSequence() async {
    _state = _state.copyWith(
      mode: PrimeMode.offline,
      coreOnline: false,
      coreFrequency: 0,
      neuralActivity: 0,
    );
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    _addActivity('system', 'PRIME core initializing...', severity: 'info');

    await Future.delayed(const Duration(milliseconds: 500));

    // Core is online — PRIME application is running
    _updateMode(PrimeMode.standard);
    _state = _state.copyWith(coreOnline: true);
    notifyListeners();
    _addActivity('system', 'Core systems online', severity: 'success');
  }

  void _initializeDefaultAgents() {
    final defaultAgents = [
      Agent(
        id: 'alpha',
        name: 'ALPHA',
        role: 'Task Orchestrator',
        status: AgentStatus.offline,
        load: 0.0,
        lastActive: DateTime.now(),
      ),
      Agent(
        id: 'beta',
        name: 'BETA',
        role: 'Code Analysis',
        status: AgentStatus.offline,
        load: 0.0,
        lastActive: DateTime.now(),
      ),
      Agent(
        id: 'gamma',
        name: 'GAMMA',
        role: 'Memory & Context',
        status: AgentStatus.offline,
        load: 0.0,
        lastActive: DateTime.now(),
      ),
      Agent(
        id: 'delta',
        name: 'DELTA',
        role: 'Web Intelligence',
        status: AgentStatus.offline,
        load: 0.0,
        lastActive: DateTime.now(),
      ),
      Agent(
        id: 'epsilon',
        name: 'EPSILON',
        role: 'File Operations',
        status: AgentStatus.offline,
        load: 0.0,
        lastActive: DateTime.now(),
      ),
      Agent(
        id: 'zeta',
        name: 'ZETA',
        role: 'Security Monitor',
        status: AgentStatus.offline,
        load: 0.0,
        lastActive: DateTime.now(),
      ),
      Agent(
        id: 'eta',
        name: 'ETA',
        role: 'Performance Tuner',
        status: AgentStatus.offline,
        load: 0.0,
        lastActive: DateTime.now(),
      ),
      Agent(
        id: 'theta',
        name: 'THETA',
        role: 'Data Synthesis',
        status: AgentStatus.offline,
        load: 0.0,
        lastActive: DateTime.now(),
      ),
    ];
    _state = _state.copyWith(agents: defaultAgents);
    notifyListeners();
  }

  /// Called for each streaming token from the LLM — updates the conversation in real-time
  void _onStreamingChunk(String chunk) {
    _streamingBuffer.write(chunk);

    // Create the streaming message if it doesn't exist yet
    if (_streamingMessageId == null) {
      _streamingMessageId = 'streaming-${DateTime.now().millisecondsSinceEpoch}';
      final placeholder = ConversationMessage(
        id: _streamingMessageId!,
        role: 'assistant',
        content: '',
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      _state = _state.copyWith(
        conversation: [..._state.conversation, placeholder],
      );
      notifyListeners();
    }

    // Update the streaming message with accumulated text
    final currentContent = _streamingBuffer.toString();
    final conv = List<ConversationMessage>.from(_state.conversation);
    final idx = conv.indexWhere((m) => m.id == _streamingMessageId);
    if (idx >= 0) {
      conv[idx] = conv[idx].copyWith(content: currentContent);
      _state = _state.copyWith(conversation: conv);
      notifyListeners();
    }
  }

  /// Finalize the streaming message with complete content
  void _finalizeStreamingMessage(String finalText, List<PipelineStep> steps) {
    if (_streamingMessageId == null) return;

    final conv = List<ConversationMessage>.from(_state.conversation);
    final idx = conv.indexWhere((m) => m.id == _streamingMessageId);
    if (idx >= 0) {
      conv[idx] = ConversationMessage(
        id: _streamingMessageId!,
        role: 'assistant',
        content: finalText,
        timestamp: DateTime.now(),
        steps: steps,
        isStreaming: false,
      );
      _state = _state.copyWith(conversation: conv);
    }
    _streamingMessageId = null;
    _streamingBuffer.clear();
  }

  void _updatePendingStep(PipelineStep step) {
    // Replace or append the step in the pending list
    final idx = _pendingSteps.indexWhere((s) => s.stage == step.stage);
    if (idx >= 0) {
      _pendingSteps = List.from(_pendingSteps);
      _pendingSteps[idx] = step;
    } else {
      _pendingSteps = [..._pendingSteps, step];
    }
    notifyListeners();
  }

  void _logPipelineStep(PipelineStep step) {
    switch (step.status) {
      case StepStatus.active:
        _addActivity('pipeline', '${step.stage.icon} ${step.stage.label}...', severity: 'info');
        break;
      case StepStatus.complete:
        _addActivity('pipeline', '${step.stage.icon} ${step.stage.label} complete (${step.durationMs}ms)',
            severity: 'success');
        break;
      case StepStatus.error:
        _addActivity('error', '${step.stage.icon} ${step.stage.label} failed: ${step.text}',
            severity: 'error');
        break;
      case StepStatus.pending:
        break;
    }
  }

  void handleVoiceCommand(String command) async {
    _lastCommand = command;
    _addActivity('voice', 'Command: "$command"', severity: 'info');

    // Process through VoiceManager (handles LLM + local commands)
    final response = await _voiceManager.processInput(command);
    _lastResponse = response.text;

    // Store in conversation
    final userMsg = ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: command,
      timestamp: DateTime.now(),
    );
    final aiMsg = ConversationMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      role: 'assistant',
      content: response.text,
      timestamp: DateTime.now(),
    );

    _state = _state.copyWith(
      conversation: [..._state.conversation, userMsg, aiMsg],
    );
    notifyListeners();

    // Speak the response if should speak
    if (response.shouldSpeak && response.text.isNotEmpty) {
      await _voiceManager.speak(response.text);
    }
  }

  void updateMode(PrimeMode newMode) {
    final oldMode = _state.mode;
    _updateMode(newMode);

    if (oldMode == PrimeMode.offline && newMode != PrimeMode.offline) {
      _audio.playStartup();
    } else if (oldMode == PrimeMode.sleep && newMode != PrimeMode.sleep) {
      _audio.playWakeFromSleep();
    } else if (newMode == PrimeMode.sleep) {
      _audio.playSleep();
    }
  }

  void _updateMode(PrimeMode newMode) {
    _state = _state.copyWith(
      mode: newMode,
      coreOnline: newMode != PrimeMode.offline,
    );
    notifyListeners();
  }

  void toggleCore() {
    if (_state.coreOnline) {
      updateMode(PrimeMode.offline);
    } else {
      updateMode(PrimeMode.standard);
    }
  }

  void toggleVoice() {
    _voiceEnabled = !_voiceEnabled;
    _voice.toggle();
    _addActivity('voice', _voiceEnabled ? 'Voice system enabled' : 'Voice system disabled',
        severity: _voiceEnabled ? 'success' : 'warning');
    notifyListeners();
  }

  void toggleListening() {
    _voice.toggleListening();
  }

  Future<void> sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    final userMessage = ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );

    _state = _state.copyWith(
      conversation: [..._state.conversation, userMessage],
    );
    notifyListeners();

    _audio.playClick();
    _addActivity('user', 'Command: "${message.length > 60 ? '${message.substring(0, 60)}...' : message}"', severity: 'info');

    // Reset state for new request
    _pendingSteps = [];
    _streamingBuffer.clear();
    _streamingMessageId = null;
    _voiceState = VoiceState.processing;
    notifyListeners();

    try {
      // Route through VoiceManager — streaming LLM pipeline
      final response = await _voiceManager.processInput(message);
      _lastResponse = response.text;

      // Store performance diagnostics
      _lastRequestId = response.requestId ?? '';
      _lastPromptChars = response.promptChars;
      _lastResponseChars = response.responseChars;
      _lastResponseWords = response.responseWords;
      _lastTotalMs = response.totalDuration?.inMilliseconds ?? 0;

      // Finalize the streaming message with complete content + steps
      _finalizeStreamingMessage(response.text, response.steps);

      _pendingSteps = [];
      _voiceState = VoiceState.idle;
      notifyListeners();

      // Performance log
      final ms = _lastTotalMs;
      final wpm = ms > 0 ? ((response.responseWords * 60000) / ms).round() : 0;
      _addActivity('brain',
          '${response.requestId ?? "?"} — ${ms}ms, '
          '${response.responseWords} words, ${response.responseChars} chars, '
          '${wpm} wpm',
          severity: 'success');

      // TTS: NON-BLOCKING — fire and forget, never waits for audio
      if (response.shouldSpeak && response.text.isNotEmpty) {
        _voiceManager.speakAsync(response.text);
      }
    } catch (e) {
      debugPrint('[StateService] sendChatMessage error: $e');
      // Remove streaming placeholder if it exists
      if (_streamingMessageId != null) {
        final conv = List<ConversationMessage>.from(_state.conversation);
        conv.removeWhere((m) => m.id == _streamingMessageId);
        _state = _state.copyWith(conversation: conv);
      }
      _pendingSteps = [];
      _streamingMessageId = null;
      _streamingBuffer.clear();
      _voiceState = VoiceState.idle;
      notifyListeners();

      final errorMsg = ConversationMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
        role: 'assistant',
        content: 'I encountered an error processing your request. Please try again.',
        timestamp: DateTime.now(),
      );
      _state = _state.copyWith(
        conversation: [..._state.conversation, errorMsg],
      );
      notifyListeners();

      _addActivity('error', 'Message processing failed: $e', severity: 'error');
    }
  }

  /// Initialize Core Intelligence (Conversation Engine + Providers)
  /// Call this after settings are available to enable real AI conversation
  Future<void> initializeCoreIntelligence() async {
    if (_conversationEngine != null) return;

    try {
      _debugService = DebugService.instance;
      _settingsService = SettingsService();
      await _settingsService!.initialize();

      _providerFactory = ProviderFactory(_settingsService!, _debugService!);
      _conversationContext = ConversationManager();

      _conversationEngine = ConversationEngine(
        providers: _providerFactory!,
        settings: _settingsService!,
        debug: _debugService!,
        context: _conversationContext,
      );

      // Listen to engine state changes
      _conversationEngine!.addListener(() {
        notifyListeners();
      });

      _addActivity('engine', 'Core Intelligence initialized', severity: 'success');
      debugPrint('[StateService] Core Intelligence initialized');
    } catch (e) {
      debugPrint('[StateService] Core Intelligence init failed: $e');
      _addActivity('engine', 'Core Intelligence init failed: $e', severity: 'error');
    }
  }

  void _addActivity(String type, String message,
      {String severity = 'info', String? agentId}) {
    // Deduplicate: don't add same message consecutively
    if (_lastActivityMessage == message) return;
    _lastActivityMessage = message;

    final event = ActivityEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      message: message,
      timestamp: DateTime.now(),
      agentId: agentId,
      severity: severity,
    );

    final feed = [event, ..._state.activityFeed];
    if (feed.length > 50) feed.removeRange(50, feed.length);

    _state = _state.copyWith(activityFeed: feed);
    notifyListeners();
  }

  /// Health check — reports status of each component
  Map<String, bool> healthCheck() => {
    'core': true, // PRIME app is running
    'llm': _llmAvailable,
    'memory': true, // ConversationManager always available
    'network': false, // No backend connected
  };

  Future<Map<String, String>> _loadEnv() async {
    // Try multiple locations for .env
    final locations = <String>[];

    // 1. Next to the executable (production build)
    final exePath = Platform.resolvedExecutable;
    final exeDir = File(exePath).parent.path;
    locations.add('$exeDir${Platform.pathSeparator}.env');

    // 2. Project root (development — flutter run)
    locations.add('/home/clawncore/prime/.env');

    // 3. Current working directory
    locations.add('${Directory.current.path}${Platform.pathSeparator}.env');

    for (final path in locations) {
      try {
        final envFile = File(path);
        if (await envFile.exists()) {
          debugPrint('[StateService] Found .env at: $path');
          final content = await envFile.readAsString();
          final env = <String, String>{};
          for (final line in content.split('\n')) {
            final trimmed = line.trim();
            if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
            final parts = trimmed.split('=');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final value = parts.sublist(1).join('=').trim();
              env[key] = value;
              debugPrint('[StateService] Loaded: $key');
            }
          }
          if (env.isNotEmpty) return env;
        }
      } catch (e) {
        debugPrint('[StateService] .env load error at $path: $e');
      }
    }

    debugPrint('[StateService] .env not found in any location');
    return {};
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _chunkSubscription?.cancel();
    _voice.dispose();
    _conversationEngine?.dispose();
    super.dispose();
  }
}
