import 'dart:async';
import 'package:flutter/material.dart';
import '../services/debug_service.dart';
import '../theme/prime_theme.dart';

/// PRIME Widgets - Debug Console
///
/// Displays structured logs with filtering by level and component.

class DebugConsole extends StatefulWidget {
  const DebugConsole({super.key});

  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final DebugService _debug = DebugService.instance;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _subscription;

  LogLevel? _selectedLevel;
  String? _selectedComponent;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _subscription = _debug.eventStream.listen((_) {
      if (_autoScroll && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: PrimeTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PrimeTheme.borderDefault),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(child: _buildLogList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PrimeTheme.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Icon(Icons.terminal, color: PrimeTheme.primeCyan, size: 16),
          const SizedBox(width: 8),
          Text(
            'DEBUG CONSOLE',
            style: TextStyle(
              color: PrimeTheme.primeCyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.arrow_downward : Icons.pause,
              color: _autoScroll ? PrimeTheme.primeCyan : PrimeTheme.statusBusy,
              size: 16,
            ),
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
            tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
          ),
          IconButton(
            icon: Icon(Icons.delete, color: PrimeTheme.textSecondary, size: 16),
            onPressed: () {
              setState(() => _debug.clear());
            },
            tooltip: 'Clear logs',
          ),
          IconButton(
            icon: Icon(Icons.copy, color: PrimeTheme.textSecondary, size: 16),
            onPressed: _exportLogs,
            tooltip: 'Export logs',
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: PrimeTheme.bgElevated,
      ),
      child: Row(
        children: [
          // Level filter
          DropdownButton<LogLevel?>(
            value: _selectedLevel,
            dropdownColor: PrimeTheme.bgSurface,
            style: TextStyle(color: PrimeTheme.textPrimary, fontSize: 12),
            underline: const SizedBox(),
            isDense: true,
            hint: Text('All', style: TextStyle(color: PrimeTheme.textSecondary)),
            items: [
              DropdownMenuItem<LogLevel?>(
                value: null,
                child: Text('ALL'),
              ),
              ...LogLevel.values.map((l) => DropdownMenuItem(
                value: l,
                child: Text(l.name.toUpperCase()),
              )),
            ],
            onChanged: (v) => setState(() => _selectedLevel = v),
          ),
          const SizedBox(width: 12),

          // Component filter
          SizedBox(
            width: 100,
            child: TextField(
              style: TextStyle(color: PrimeTheme.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Component',
                hintStyle: TextStyle(color: PrimeTheme.textSecondary.withAlpha(128)),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: PrimeTheme.borderDefault),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: PrimeTheme.borderDefault),
                ),
              ),
              onChanged: (v) => setState(() =>
                  _selectedComponent = v.isEmpty ? null : v.toUpperCase()),
            ),
          ),

          const Spacer(),

          // Log count
          Text(
            '${_getFilteredLogs().length} entries',
            style: TextStyle(color: PrimeTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    final logs = _getFilteredLogs();

    if (logs.isEmpty) {
      return Center(
        child: Text(
          'No logs matching filter',
          style: TextStyle(color: PrimeTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogEntry(log);
      },
    );
  }

  Widget _buildLogEntry(DebugEvent log) {
    Color levelColor;
    switch (log.level) {
      case LogLevel.debug:
        levelColor = PrimeTheme.textSecondary;
        break;
      case LogLevel.info:
        levelColor = PrimeTheme.primeCyan;
        break;
      case LogLevel.warning:
        levelColor = PrimeTheme.statusBusy;
        break;
      case LogLevel.error:
        levelColor = PrimeTheme.statusError;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        color: log.level == LogLevel.error
            ? PrimeTheme.statusError.withAlpha(20)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            log.formattedTime,
            style: TextStyle(
              color: PrimeTheme.textSecondary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),

          // Level
          SizedBox(
            width: 50,
            child: Text(
              log.level.name.toUpperCase(),
              style: TextStyle(
                color: levelColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Component
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: PrimeTheme.primeCyan.withAlpha(30),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              log.component,
              style: TextStyle(
                color: PrimeTheme.primeCyan,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Message
          Expanded(
            child: Text(
              log.message,
              style: TextStyle(
                color: PrimeTheme.textPrimary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }

  List<DebugEvent> _getFilteredLogs() {
    var logs = _debug.recentLogs;

    if (_selectedLevel != null) {
      logs = logs.where((l) => l.level == _selectedLevel).toList();
    }

    if (_selectedComponent != null) {
      logs = logs.where((l) =>
          l.component.toUpperCase().contains(_selectedComponent!)).toList();
    }

    return logs;
  }

  void _exportLogs() {
    _debug.exportForClipboard;
    debugPrint('[DebugConsole] Exported ${_getFilteredLogs().length} logs');
  }
}
