import 'package:flutter/material.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';
import '../services/voice_service.dart';

class TelemetryCompact extends StatelessWidget {
  final Telemetry telemetry;
  final VoiceState voiceState;

  const TelemetryCompact({
    super.key,
    required this.telemetry,
    required this.voiceState,
  });

  @override
  Widget build(BuildContext context) {
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  // System metrics (not available without backend)
                  _GaugeRow(label: 'CPU', value: telemetry.cpuUsage),
                  const SizedBox(height: 6),
                  _GaugeRow(label: 'MEMORY', value: telemetry.memoryUsage),
                  const SizedBox(height: 6),
                  _GaugeRow(label: 'GPU', value: telemetry.gpuUsage),
                  const SizedBox(height: 10),

                  // Network
                  _InfoRow(label: 'NET IN', value: _formatBytes(telemetry.networkIn)),
                  const SizedBox(height: 4),
                  _InfoRow(label: 'NET OUT', value: _formatBytes(telemetry.networkOut)),
                  const SizedBox(height: 10),

                  // LLM metrics
                  _InfoRow(label: 'TOKENS', value: telemetry.totalTokensUsed > 0
                      ? _formatNumber(telemetry.totalTokensUsed)
                      : 'N/A'),
                  const SizedBox(height: 4),
                  _InfoRow(label: 'TPS', value: telemetry.tokensPerSecond > 0
                      ? '${telemetry.tokensPerSecond}'
                      : 'N/A'),
                  const SizedBox(height: 10),

                  // Voice state
                  _InfoRow(label: 'VOICE', value: _voiceStatusLabel()),
                  const SizedBox(height: 4),

                  // Uptime
                  _InfoRow(label: 'UPTIME', value: _formatUptime(telemetry.uptime)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.speed, size: 12, color: PrimeTheme.statusOnline.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text('TELEMETRY', style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: PrimeTheme.textSecondary,
          )),
        ],
      ),
    );
  }

  String _formatBytes(double mb) {
    if (mb < 1) return '${(mb * 1024).toStringAsFixed(0)} KB/s';
    return '${mb.toStringAsFixed(1)} MB/s';
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _formatUptime(double seconds) {
    final s = seconds.round();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _voiceStatusLabel() {
    switch (voiceState) {
      case VoiceState.idle: return 'IDLE';
      case VoiceState.listening: return 'LISTENING';
      case VoiceState.processing: return 'PROCESSING';
      case VoiceState.speaking: return 'SPEAKING';
      case VoiceState.error: return 'ERROR';
    }
  }
}

class _GaugeRow extends StatelessWidget {
  final String label;
  final double value;

  const _GaugeRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isNA = value == 0.0;
    final color = value > 80
        ? PrimeTheme.statusError
        : value > 50
            ? PrimeTheme.statusBusy
            : PrimeTheme.statusOnline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 8,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              color: PrimeTheme.textMuted,
            )),
            Text(isNA ? 'N/A' : '${value.toStringAsFixed(1)}%', style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isNA ? PrimeTheme.textDim : color,
            )),
          ],
        ),
        const SizedBox(height: 3),
        if (!isNA)
          SizedBox(
            height: 3,
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: PrimeTheme.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isNA = value == 'N/A';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 8,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: PrimeTheme.textDim,
        )),
        Text(value, style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 8,
          fontWeight: FontWeight.w500,
          color: isNA ? PrimeTheme.textDim : PrimeTheme.textSecondary,
        )),
      ],
    );
  }
}
