import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';
import '../services/state_service.dart';
import '../services/audio_service.dart';
import '../services/websocket_service.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final stateService = context.watch<StateService>();
    final state = stateService.state;
    final ws = WebSocketService.instance;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: PrimeTheme.surface900,
        border: Border(
          bottom: BorderSide(color: PrimeTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildLogo(),
          const SizedBox(width: 16),
          _buildStateChip(state),
          const SizedBox(width: 16),
          _buildCoreToggle(stateService, state),
          const Spacer(),
          _buildConnectionStatus(ws),
          const SizedBox(width: 12),
          _buildModeChip(state),
          const SizedBox(width: 12),
          _buildTelemetryMini(state),
          const SizedBox(width: 12),
          _buildMuteButton(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '◈',
          style: TextStyle(
            color: PrimeTheme.primeCyan,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: 8),
        Text(
          'PRIME',
          style: TextStyle(
            color: PrimeTheme.primeCyan,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ],
    );
  }

  Widget _buildStateChip(PrimeState state) {
    final color = state.stateColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            state.stateLabel,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreToggle(StateService stateService, PrimeState state) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          AudioService.instance.playClick();
          stateService.toggleCore();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: state.coreOnline
                ? PrimeTheme.primeGreen.withValues(alpha: 0.1)
                : PrimeTheme.surface800,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: state.coreOnline
                  ? PrimeTheme.primeGreen.withValues(alpha: 0.3)
                  : PrimeTheme.border,
            ),
          ),
          child: Text(
            state.coreOnline ? 'CORE: ON' : 'CORE: OFF',
            style: TextStyle(
              color:
                  state.coreOnline ? PrimeTheme.primeGreen : PrimeTheme.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(WebSocketService ws) {
    return StreamBuilder<bool>(
      stream: ws.connectionStatus,
      initialData: false,
      builder: (context, snapshot) {
        final connected = snapshot.data ?? false;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: connected
                ? PrimeTheme.primeGreen.withValues(alpha: 0.1)
                : PrimeTheme.primeRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                connected ? Icons.wifi : Icons.wifi_off,
                size: 10,
                color: connected ? PrimeTheme.primeGreen : PrimeTheme.primeRed,
              ),
              const SizedBox(width: 4),
              Text(
                connected ? 'LINKED' : 'OFFLINE',
                style: TextStyle(
                  color:
                      connected ? PrimeTheme.primeGreen : PrimeTheme.primeRed,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeChip(PrimeState state) {
    final color = _modeColor(state.mode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        state.mode.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          fontFamily: 'JetBrains Mono',
        ),
      ),
    );
  }

  Widget _buildTelemetryMini(PrimeState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TelemetryItem(
          label: 'CPU',
          value: '${state.telemetry.cpuUsage.toStringAsFixed(0)}%',
          color: PrimeTheme.primeCyan,
        ),
        const SizedBox(width: 8),
        _TelemetryItem(
          label: 'MEM',
          value: '${state.telemetry.memoryUsage.toStringAsFixed(0)}%',
          color: PrimeTheme.primeBlue,
        ),
        const SizedBox(width: 8),
        _TelemetryItem(
          label: 'NET',
          value: '${state.telemetry.networkIn.toStringAsFixed(1)}',
          color: PrimeTheme.primePurple,
        ),
      ],
    );
  }

  Widget _buildMuteButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          AudioService.instance.toggleMute();
        },
        child: Icon(
          AudioService.instance.isMuted
              ? Icons.volume_off_rounded
              : Icons.volume_up_rounded,
          size: 14,
          color: PrimeTheme.textMuted,
        ),
      ),
    );
  }

  Color _modeColor(PrimeMode mode) {
    switch (mode) {
      case PrimeMode.standard:
        return PrimeTheme.primeCyan;
      case PrimeMode.stealth:
        return PrimeTheme.primePurple;
      case PrimeMode.combat:
        return PrimeTheme.primeRed;
      case PrimeMode.diagnostic:
        return PrimeTheme.primeBlue;
      case PrimeMode.sleep:
        return PrimeTheme.primeAmber;
      case PrimeMode.offline:
        return PrimeTheme.textMuted;
    }
  }
}

class _TelemetryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TelemetryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: PrimeTheme.textMuted,
            fontSize: 7,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ],
    );
  }
}
