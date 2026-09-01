import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/prime_state.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/audio_service.dart';
import '../services/voice_service.dart';
import '../voice/voice_manager.dart';
import '../brain/llm_provider.dart';

class StateService extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final WebSocketService _ws = WebSocketService.instance;
  final AudioService _audio = AudioService.instance;
  final VoiceService _voice = VoiceService.instance;
  final VoiceManager _voiceManager = VoiceManager.instance;

  PrimeState _state = PrimeState(lastUpdate: DateTime.now());
  Timer? _telemetryTimer;
  Timer? _pollTimer;
  bool _initialized = false;

  // Voice state
  VoiceState _voiceState = VoiceState.idle;
  String _lastCommand = '';
  String _lastResponse = '';
  bool _voiceEnabled = true;

  PrimeState get state => _state;
  VoiceService get voice => _voice;

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
    _addActivity('brain', 'LLM: ${_voiceManager.llmEnabled ? _voiceManager.llmProvider?.name ?? "Enabled" : "Offline (local commands only)"}',
        severity: _voiceManager.llmEnabled ? 'success' : 'warning');

    _ws.events.listen(_handleWebSocketEvent);
    _ws.connectionStatus.listen((connected) {
      if (connected) {
        _addActivity('system', 'Connection established', severity: 'success');
        _ws.requestState();
      } else {
        _addActivity('system', 'Connection lost', severity: 'warning');
      }
    });

    await _ws.connect();

    _telemetryTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _fetchTelemetry(),
    );

    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchState(),
    );

    _fetchState();
    _initializeDefaultAgents();
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

    await Future.delayed(const Duration(milliseconds: 500));
    _addActivity('system', 'PRIME core initializing...', severity: 'info');

    await Future.delayed(const Duration(seconds: 1));
    _updateMode(PrimeMode.standard);
    _addActivity('system', 'Core systems online', severity: 'success');

    await Future.delayed(const Duration(milliseconds: 800));
    _state = _state.copyWith(coreOnline: true, coreFrequency: 42.7, neuralActivity: 68.3);
    notifyListeners();
    _addActivity('system', 'All systems operational', severity: 'success');

    // Start voice listening after boot
    await Future.delayed(const Duration(milliseconds: 500));
    if (_voiceEnabled) {
      _voice.startListening();
      _addActivity('voice', 'Voice system activated', severity: 'success');
    }
  }

  void _initializeDefaultAgents() {
    final defaultAgents = [
      Agent(
        id: 'alpha',
        name: 'ALPHA',
        role: 'Task Orchestrator',
        status: AgentStatus.online,
        load: 34.2,
        lastActive: DateTime.now(),
      ),
      Agent(
        id: 'beta',
        name: 'BETA',
        role: 'Code Analysis',
        status: AgentStatus.online,
        load: 67.8,
        lastActive: DateTime.now(),
      ),
      Agent(
        id: 'gamma',
        name: 'GAMMA',
        role: 'Memory & Context',
        status: AgentStatus.online,
        load: 45.1,
        lastActive: DateTime.now(),
      ),
      Agent(
        id: 'delta',
        name: 'DELTA',
        role: 'Web Intelligence',
        status: AgentStatus.busy,
        load: 89.3,
        lastActive: DateTime.now(),
        currentTask: 'Fetching documentation',
      ),
      Agent(
        id: 'epsilon',
        name: 'EPSILON',
        role: 'File Operations',
        status: AgentStatus.online,
        load: 22.5,
        lastActive: DateTime.now(),
      ),
      Agent(
        id: 'zeta',
        name: 'ZETA',
        role: 'Security Monitor',
        status: AgentStatus.online,
        load: 15.7,
        lastActive: DateTime.now(),
      ),
      Agent(
        id: 'eta',
        name: 'ETA',
        role: 'Performance Tuner',
        status: AgentStatus.offline,
        load: 0.0,
        lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Agent(
        id: 'theta',
        name: 'THETA',
        role: 'Data Synthesis',
        status: AgentStatus.online,
        load: 56.9,
        lastActive: DateTime.now(),
      ),
    ];
    _state = _state.copyWith(agents: defaultAgents);
    notifyListeners();
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

  void _handleWebSocketEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;

    switch (type) {
      case 'state_update':
        _handleStateUpdate(event);
        break;
      case 'telemetry_update':
        _handleTelemetryUpdate(event);
        break;
      case 'agent_update':
        _handleAgentUpdate(event);
        break;
      case 'chat_response':
        _handleChatResponse(event);
        break;
      case 'activity':
        _handleActivityEvent(event);
        break;
      case 'task_update':
        _handleTaskUpdate(event);
        break;
      case 'error':
        _handleErrorEvent(event);
        break;
      default:
        debugPrint('[StateService] Unknown event type: $type');
    }
  }

  void _handleStateUpdate(Map<String, dynamic> event) {
    final data = event['data'] as Map<String, dynamic>?;
    if (data == null) return;

    final newMode = PrimeMode.values.firstWhere(
      (e) => e.name == data['mode'],
      orElse: () => _state.mode,
    );
    final wasOffline = _state.mode == PrimeMode.offline;

    _state = _state.copyWith(
      mode: newMode,
      coreOnline: data['core_online'] ?? _state.coreOnline,
      coreFrequency: (data['core_frequency'] as num?)?.toDouble() ?? _state.coreFrequency,
      neuralActivity: (data['neural_activity'] as num?)?.toDouble() ?? _state.neuralActivity,
    );
    notifyListeners();

    if (wasOffline && newMode != PrimeMode.offline) {
      _audio.playStartup();
    } else if (newMode == PrimeMode.sleep) {
      _audio.playSleep();
    }

    _playSoundForState(newMode);
  }

  void _handleTelemetryUpdate(Map<String, dynamic> event) {
    final data = event['data'] as Map<String, dynamic>?;
    if (data == null) return;

    _state = _state.copyWith(
      telemetry: Telemetry.fromJson(data),
    );
    notifyListeners();
  }

  void _handleAgentUpdate(Map<String, dynamic> event) {
    final data = event['data'] as Map<String, dynamic>?;
    if (data == null) return;

    final agentId = data['agent_id'] as String?;
    if (agentId == null) return;

    final index = _state.agents.indexWhere((a) => a.id == agentId);
    if (index >= 0) {
      final updated = _state.agents[index].copyWith(
        status: AgentStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => _state.agents[index].status,
        ),
        load: (data['load'] as num?)?.toDouble() ?? _state.agents[index].load,
        currentTask: data['current_task'] as String?,
        clearTask: data['current_task'] == null,
        lastActive: DateTime.now(),
      );
      final newAgents = List<Agent>.from(_state.agents);
      newAgents[index] = updated;
      _state = _state.copyWith(agents: newAgents);
      notifyListeners();
    }
  }

  void _handleChatResponse(Map<String, dynamic> event) {
    final data = event['data'] as Map<String, dynamic>?;
    if (data == null) return;

    final message = ConversationMessage(
      id: data['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: data['role'] as String? ?? 'assistant',
      content: data['content'] as String? ?? '',
      timestamp: DateTime.now(),
    );

    _state = _state.copyWith(
      conversation: [..._state.conversation, message],
    );
    notifyListeners();

    // Speak the AI response
    if (message.role == 'assistant' && message.content.isNotEmpty) {
      _voice.speak(message.content);
    }
  }

  void _handleActivityEvent(Map<String, dynamic> event) {
    final data = event['data'] as Map<String, dynamic>?;
    if (data == null) return;

    _addActivity(
      data['type'] as String? ?? 'system',
      data['message'] as String? ?? '',
      severity: data['severity'] as String? ?? 'info',
      agentId: data['agent_id'] as String?,
    );
  }

  void _handleTaskUpdate(Map<String, dynamic> event) {
    final data = event['data'] as Map<String, dynamic>?;
    if (data == null) return;

    final taskId = data['task_id'] as String?;
    if (taskId == null) return;

    final index = _state.tasks.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      final newTasks = List<Task>.from(_state.tasks);
      newTasks[index] = newTasks[index].copyWith(
        status: TaskStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => newTasks[index].status,
        ),
        result: data['result'] as String?,
        completedAt: data['status'] == 'completed' || data['status'] == 'failed'
            ? DateTime.now()
            : null,
      );
      _state = _state.copyWith(tasks: newTasks);
      notifyListeners();
    }
  }

  void _handleErrorEvent(Map<String, dynamic> event) {
    final message = event['message'] as String? ?? 'Unknown error';
    _addActivity('error', message, severity: 'error');
    _audio.playMalfunction();
  }

  void _playSoundForState(PrimeMode newMode) {
    switch (newMode) {
      case PrimeMode.standard:
        break;
      case PrimeMode.stealth:
        _audio.playWake();
        break;
      case PrimeMode.combat:
        _audio.playWarning();
        break;
      case PrimeMode.diagnostic:
        _audio.playNotification();
        break;
      case PrimeMode.sleep:
        _audio.playSleep();
        break;
      case PrimeMode.offline:
        break;
    }
  }

  Future<void> _fetchState() async {
    final data = await _api.getState();
    if (data != null) {
      try {
        final newState = PrimeState.fromJson(data);
        _state = newState;
        notifyListeners();
      } catch (e) {
        debugPrint('[StateService] State parse error: $e');
      }
    }
  }

  Future<void> _fetchTelemetry() async {
    final data = await _api.getTelemetry();
    if (data != null) {
      _state = _state.copyWith(telemetry: Telemetry.fromJson(data));
      notifyListeners();
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

    _ws.sendCommand('set_mode', payload: {'mode': newMode.name});
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
    _ws.sendChatMessage(message);
  }

  void _addActivity(String type, String message,
      {String severity = 'info', String? agentId}) {
    final event = ActivityEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      message: message,
      timestamp: DateTime.now(),
      agentId: agentId,
      severity: severity,
    );

    final feed = [event, ..._state.activityFeed];
    if (feed.length > 100) feed.removeRange(100, feed.length);

    _state = _state.copyWith(activityFeed: feed);
    notifyListeners();
  }

  void updateTelemetry(Telemetry newTelemetry) {
    _state = _state.copyWith(telemetry: newTelemetry);
    notifyListeners();
  }

  Future<Map<String, String>> _loadEnv() async {
    try {
      // Look for .env in the same directory as the executable
      final exePath = Platform.resolvedExecutable;
      final exeDir = File(exePath).parent.path;
      final envFile = File('$exeDir\\.env');

      debugPrint('[StateService] Looking for .env at: $exeDir');

      if (await envFile.exists()) {
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
        return env;
      } else {
        debugPrint('[StateService] .env not found at: $exeDir');
      }
    } catch (e) {
      debugPrint('[StateService] .env load error: $e');
    }
    return {};
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _pollTimer?.cancel();
    _voice.dispose();
    super.dispose();
  }
}
