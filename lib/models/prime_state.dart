import 'package:flutter/material.dart';

enum PrimeMode { standard, stealth, combat, diagnostic, sleep, offline }

enum AgentStatus { online, offline, busy, error }

enum TaskStatus { pending, running, completed, failed }

class Agent {
  final String id;
  final String name;
  final String role;
  final AgentStatus status;
  final double load;
  final DateTime lastActive;
  final String? currentTask;

  const Agent({
    required this.id,
    required this.name,
    required this.role,
    this.status = AgentStatus.offline,
    this.load = 0.0,
    required this.lastActive,
    this.currentTask,
  });

  Agent copyWith({
    String? id,
    String? name,
    String? role,
    AgentStatus? status,
    double? load,
    DateTime? lastActive,
    String? currentTask,
    bool clearTask = false,
  }) {
    return Agent(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      load: load ?? this.load,
      lastActive: lastActive ?? this.lastActive,
      currentTask: clearTask ? null : (currentTask ?? this.currentTask),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'status': status.name,
        'load': load,
        'last_active': lastActive.toIso8601String(),
        'current_task': currentTask,
      };

  factory Agent.fromJson(Map<String, dynamic> json) => Agent(
        id: json['id'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        status: AgentStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => AgentStatus.offline,
        ),
        load: (json['load'] as num?)?.toDouble() ?? 0.0,
        lastActive: json['last_active'] != null
            ? DateTime.parse(json['last_active'] as String)
            : DateTime.now(),
        currentTask: json['current_task'] as String?,
      );
}

class Telemetry {
  final double cpuUsage;
  final double memoryUsage;
  final double gpuUsage;
  final double networkIn;
  final double networkOut;
  final int tokensPerSecond;
  final int totalTokensUsed;
  final double uptime;

  const Telemetry({
    this.cpuUsage = 0.0,
    this.memoryUsage = 0.0,
    this.gpuUsage = 0.0,
    this.networkIn = 0.0,
    this.networkOut = 0.0,
    this.tokensPerSecond = 0,
    this.totalTokensUsed = 0,
    this.uptime = 0.0,
  });

  Telemetry copyWith({
    double? cpuUsage,
    double? memoryUsage,
    double? gpuUsage,
    double? networkIn,
    double? networkOut,
    int? tokensPerSecond,
    int? totalTokensUsed,
    double? uptime,
  }) {
    return Telemetry(
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      gpuUsage: gpuUsage ?? this.gpuUsage,
      networkIn: networkIn ?? this.networkIn,
      networkOut: networkOut ?? this.networkOut,
      tokensPerSecond: tokensPerSecond ?? this.tokensPerSecond,
      totalTokensUsed: totalTokensUsed ?? this.totalTokensUsed,
      uptime: uptime ?? this.uptime,
    );
  }

  Map<String, dynamic> toJson() => {
        'cpu_usage': cpuUsage,
        'memory_usage': memoryUsage,
        'gpu_usage': gpuUsage,
        'network_in': networkIn,
        'network_out': networkOut,
        'tokens_per_second': tokensPerSecond,
        'total_tokens_used': totalTokensUsed,
        'uptime': uptime,
      };

  factory Telemetry.fromJson(Map<String, dynamic> json) => Telemetry(
        cpuUsage: (json['cpu_usage'] as num?)?.toDouble() ?? 0.0,
        memoryUsage: (json['memory_usage'] as num?)?.toDouble() ?? 0.0,
        gpuUsage: (json['gpu_usage'] as num?)?.toDouble() ?? 0.0,
        networkIn: (json['network_in'] as num?)?.toDouble() ?? 0.0,
        networkOut: (json['network_out'] as num?)?.toDouble() ?? 0.0,
        tokensPerSecond: (json['tokens_per_second'] as num?)?.toInt() ?? 0,
        totalTokensUsed: (json['total_tokens_used'] as num?)?.toInt() ?? 0,
        uptime: (json['uptime'] as num?)?.toDouble() ?? 0.0,
      );
}

class ConversationMessage {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;

  const ConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
  });

  ConversationMessage copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'is_streaming': isStreaming,
      };

  factory ConversationMessage.fromJson(Map<String, dynamic> json) =>
      ConversationMessage(
        id: json['id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isStreaming: json['is_streaming'] as bool? ?? false,
      );
}

class ActivityEvent {
  final String id;
  final String type;
  final String message;
  final DateTime timestamp;
  final String? agentId;
  final String severity;

  const ActivityEvent({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    this.agentId,
    this.severity = 'info',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'agent_id': agentId,
        'severity': severity,
      };

  factory ActivityEvent.fromJson(Map<String, dynamic> json) => ActivityEvent(
        id: json['id'] as String,
        type: json['type'] as String,
        message: json['message'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        agentId: json['agent_id'] as String?,
        severity: json['severity'] as String? ?? 'info',
      );
}

class Task {
  final String id;
  final String description;
  final TaskStatus status;
  final String? assignedAgent;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? result;

  const Task({
    required this.id,
    required this.description,
    this.status = TaskStatus.pending,
    this.assignedAgent,
    required this.createdAt,
    this.completedAt,
    this.result,
  });

  Task copyWith({
    String? id,
    String? description,
    TaskStatus? status,
    String? assignedAgent,
    DateTime? createdAt,
    DateTime? completedAt,
    String? result,
  }) {
    return Task(
      id: id ?? this.id,
      description: description ?? this.description,
      status: status ?? this.status,
      assignedAgent: assignedAgent ?? this.assignedAgent,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      result: result ?? this.result,
    );
  }
}

class PrimeState {
  final PrimeMode mode;
  final bool coreOnline;
  final double coreFrequency;
  final double neuralActivity;
  final Telemetry telemetry;
  final List<Agent> agents;
  final List<ConversationMessage> conversation;
  final List<ActivityEvent> activityFeed;
  final List<Task> tasks;
  final DateTime lastUpdate;

  const PrimeState({
    this.mode = PrimeMode.offline,
    this.coreOnline = false,
    this.coreFrequency = 0.0,
    this.neuralActivity = 0.0,
    this.telemetry = const Telemetry(),
    this.agents = const [],
    this.conversation = const [],
    this.activityFeed = const [],
    this.tasks = const [],
    required this.lastUpdate,
  });

  String get stateLabel {
    switch (mode) {
      case PrimeMode.offline:
        return 'OFFLINE';
      case PrimeMode.sleep:
        return 'STANDBY';
      case PrimeMode.standard:
        return coreOnline ? 'ONLINE' : 'INITIALIZING';
      case PrimeMode.stealth:
        return 'STEALTH';
      case PrimeMode.combat:
        return 'COMBAT';
      case PrimeMode.diagnostic:
        return 'DIAGNOSTIC';
    }
  }

  Color get stateColor {
    switch (mode) {
      case PrimeMode.offline:
        return const Color(0xFF666666);
      case PrimeMode.sleep:
        return const Color(0xFFffaa00);
      case PrimeMode.standard:
        return coreOnline
            ? const Color(0xFF33cc66)
            : const Color(0xFF3399ff);
      case PrimeMode.stealth:
        return const Color(0xFF8855ff);
      case PrimeMode.combat:
        return const Color(0xFFff3366);
      case PrimeMode.diagnostic:
        return const Color(0xFF00d4ff);
    }
  }

  PrimeState copyWith({
    PrimeMode? mode,
    bool? coreOnline,
    double? coreFrequency,
    double? neuralActivity,
    Telemetry? telemetry,
    List<Agent>? agents,
    List<ConversationMessage>? conversation,
    List<ActivityEvent>? activityFeed,
    List<Task>? tasks,
    DateTime? lastUpdate,
  }) {
    return PrimeState(
      mode: mode ?? this.mode,
      coreOnline: coreOnline ?? this.coreOnline,
      coreFrequency: coreFrequency ?? this.coreFrequency,
      neuralActivity: neuralActivity ?? this.neuralActivity,
      telemetry: telemetry ?? this.telemetry,
      agents: agents ?? this.agents,
      conversation: conversation ?? this.conversation,
      activityFeed: activityFeed ?? this.activityFeed,
      tasks: tasks ?? this.tasks,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'core_online': coreOnline,
        'core_frequency': coreFrequency,
        'neural_activity': neuralActivity,
        'telemetry': telemetry.toJson(),
        'agents': agents.map((a) => a.toJson()).toList(),
        'conversation': conversation.map((m) => m.toJson()).toList(),
        'activity_feed': activityFeed.map((e) => e.toJson()).toList(),
        'last_update': lastUpdate.toIso8601String(),
      };

  factory PrimeState.fromJson(Map<String, dynamic> json) => PrimeState(
        mode: PrimeMode.values.firstWhere(
          (e) => e.name == json['mode'],
          orElse: () => PrimeMode.offline,
        ),
        coreOnline: json['core_online'] as bool? ?? false,
        coreFrequency: (json['core_frequency'] as num?)?.toDouble() ?? 0.0,
        neuralActivity: (json['neural_activity'] as num?)?.toDouble() ?? 0.0,
        telemetry: json['telemetry'] != null
            ? Telemetry.fromJson(json['telemetry'] as Map<String, dynamic>)
            : const Telemetry(),
        agents: (json['agents'] as List<dynamic>?)
                ?.map((a) => Agent.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
        conversation: (json['conversation'] as List<dynamic>?)
                ?.map(
                    (m) => ConversationMessage.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        activityFeed: (json['activity_feed'] as List<dynamic>?)
                ?.map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        lastUpdate: json['last_update'] != null
            ? DateTime.parse(json['last_update'] as String)
            : DateTime.now(),
      );
}
