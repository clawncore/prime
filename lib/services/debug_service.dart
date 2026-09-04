import 'dart:async';
import 'package:flutter/foundation.dart';

/// PRIME Debug Service
///
/// Structured logging with levels, components, and timestamps.
/// Provides event stream for debug console UI.

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class DebugEvent {
  final DateTime timestamp;
  final LogLevel level;
  final String component;
  final String message;

  const DebugEvent({
    required this.timestamp,
    required this.level,
    required this.component,
    required this.message,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get formatted {
    final levelStr = level.name.toUpperCase().padLeft(7);
    return '[$formattedTime] [$levelStr] [$component] $message';
  }

  @override
  String toString() => formatted;
}

class DebugService {
  DebugService._();
  static final DebugService instance = DebugService._();

  final List<DebugEvent> _logs = [];
  final StreamController<DebugEvent> _eventController =
      StreamController<DebugEvent>.broadcast();

  static const int _maxLogs = 500;

  Stream<DebugEvent> get eventStream => _eventController.stream;
  List<DebugEvent> get recentLogs => List.unmodifiable(_logs);

  /// Log a debug message
  void debug(String component, String message) =>
      _log(LogLevel.debug, component, message);

  /// Log an info message
  void info(String component, String message) =>
      _log(LogLevel.info, component, message);

  /// Log a warning
  void warning(String component, String message) =>
      _log(LogLevel.warning, component, message);

  /// Log an error
  void error(String component, String message) =>
      _log(LogLevel.error, component, message);

  void _log(LogLevel level, String component, String message) {
    final event = DebugEvent(
      timestamp: DateTime.now(),
      level: level,
      component: component,
      message: message,
    );

    _logs.add(event);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // Also print to debug console in debug mode
    if (kDebugMode) {
      print(event.formatted);
    }

    _eventController.add(event);
  }

  /// Get logs filtered by level
  List<DebugEvent> getLogsByLevel(LogLevel level) =>
      _logs.where((e) => e.level == level).toList();

  /// Get logs filtered by component
  List<DebugEvent> getLogsByComponent(String component) =>
      _logs.where((e) => e.component == component).toList();

  /// Get recent logs (last N)
  List<DebugEvent> getRecent({int count = 100}) {
    final start = _logs.length - count;
    return _logs.sublist(start.clamp(0, _logs.length));
  }

  /// Clear all logs
  void clear() {
    _logs.clear();
  }

  /// Export logs as text
  String exportAsText({LogLevel? minLevel}) {
    final filtered = minLevel != null
        ? _logs.where((e) => e.level.index >= minLevel.index).toList()
        : _logs;
    return filtered.map((e) => e.formatted).join('\n');
  }

  /// Copy logs to clipboard-friendly format
  String get exportForClipboard {
    final buffer = StringBuffer();
    buffer.writeln('PRIME Debug Log Export');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${_logs.length}');
    buffer.writeln('---');
    for (final log in _logs) {
      buffer.writeln(log.formatted);
    }
    return buffer.toString();
  }

  void dispose() {
    _eventController.close();
  }
}
