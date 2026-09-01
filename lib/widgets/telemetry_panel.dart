import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';
import '../services/state_service.dart';

class TelemetryPanel extends StatelessWidget {
  const TelemetryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final stateService = context.watch<StateService>();
    final telemetry = stateService.telemetry;

    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: PrimeTheme.surface950,
        border: Border(
          left: BorderSide(color: PrimeTheme.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: PrimeTheme.border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _GaugeCard(
                    label: 'CPU USAGE',
                    value: telemetry.cpuUsage,
                    unit: '%',
                    color: PrimeTheme.primeCyan,
                  ),
                  const SizedBox(height: 8),
                  _GaugeCard(
                    label: 'MEMORY',
                    value: telemetry.memoryUsage,
                    unit: '%',
                    color: PrimeTheme.primeBlue,
                  ),
                  const SizedBox(height: 8),
                  _GaugeCard(
                    label: 'GPU',
                    value: telemetry.gpuUsage,
                    unit: '%',
                    color: PrimeTheme.primePurple,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'NETWORK IN',
                    value: '${telemetry.networkIn.toStringAsFixed(1)} MB/s',
                    color: PrimeTheme.primeGreen,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'NETWORK OUT',
                    value: '${telemetry.networkOut.toStringAsFixed(1)} MB/s',
                    color: PrimeTheme.primeAmber,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'TOKENS/SEC',
                    value: telemetry.tokensPerSecond.toString(),
                    color: PrimeTheme.primeCyan,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'TOTAL TOKENS',
                    value: _formatTokens(telemetry.totalTokensUsed),
                    color: PrimeTheme.primeBlue,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'UPTIME',
                    value: _formatUptime(telemetry.uptime),
                    color: PrimeTheme.primeGreen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(Icons.speed, size: 14, color: PrimeTheme.primeAmber),
          SizedBox(width: 8),
          Text(
            'TELEMETRY',
            style: TextStyle(
              color: PrimeTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1000000) return '${(tokens / 1000000).toStringAsFixed(1)}M';
    if (tokens >= 1000) return '${(tokens / 1000).toStringAsFixed(1)}K';
    return tokens.toString();
  }

  String _formatUptime(double seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }
}

class _GaugeCard extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;

  const _GaugeCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: PrimeTheme.surface800,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: PrimeTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: PrimeTheme.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: value / 100,
                  backgroundColor: PrimeTheme.surface700,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: PrimeTheme.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ],
    );
  }
}
