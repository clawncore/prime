import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';
import '../services/state_service.dart';
import '../services/audio_service.dart';

class MiniBar extends StatefulWidget {
  const MiniBar({super.key});

  @override
  State<MiniBar> createState() => _MiniBarState();
}

class _MiniBarState extends State<MiniBar> {
  bool _expanded = false;
  Offset _position = const Offset(20, 20);


  @override
  Widget build(BuildContext context) {
    final stateService = context.watch<StateService>();
    final state = stateService.state;

    return Positioned(
      left: _position.dx,
      bottom: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position.dx + details.delta.dx,
              _position.dy - details.delta.dy,
            );
          });
        },

        onTap: () {
          AudioService.instance.playClick();
          setState(() => _expanded = !_expanded);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: _expanded ? 320 : 140,
          height: _expanded ? 180 : 36,
          decoration: BoxDecoration(
            color: PrimeTheme.surface900,
            borderRadius: BorderRadius.circular(_expanded ? 12 : 18),
            border: Border.all(
              color: state.stateColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: state.stateColor.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: _expanded ? _buildExpandedView(state) : _buildCollapsedView(state),
        ),
      ),
    );
  }

  Widget _buildCollapsedView(PrimeState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 12),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state.stateColor,
            boxShadow: [
              BoxShadow(
                color: state.stateColor.withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          state.stateLabel,
          style: TextStyle(
            color: state.stateColor,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const Spacer(),
        Text(
          'PRIME',
          style: TextStyle(
            color: PrimeTheme.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildExpandedView(PrimeState state) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '◈',
                style: TextStyle(
                  color: PrimeTheme.primeCyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'PRIME MINI',
                style: TextStyle(
                  color: PrimeTheme.primeCyan,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    AudioService.instance.playClickSecondary();
                    setState(() => _expanded = false);
                  },
                  child: const Icon(
                    Icons.minimize,
                    size: 12,
                    color: PrimeTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _QuickAction(
            label: 'CORE',
            value: state.coreOnline ? 'ONLINE' : 'OFFLINE',
            color: state.coreOnline ? PrimeTheme.primeGreen : PrimeTheme.primeRed,
            onTap: () => context.read<StateService>().toggleCore(),
          ),
          const SizedBox(height: 4),
          _QuickAction(
            label: 'MODE',
            value: state.mode.name.toUpperCase(),
            color: PrimeTheme.primeBlue,
            onTap: () {
              final modes = PrimeMode.values;
              final nextIndex = (modes.indexOf(state.mode) + 1) % modes.length;
              context.read<StateService>().updateMode(modes[nextIndex]);
            },
          ),
          const SizedBox(height: 4),
          _QuickAction(
            label: 'CPU',
            value: '${state.telemetry.cpuUsage.toStringAsFixed(0)}%',
            color: PrimeTheme.primeCyan,
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            AudioService.instance.playClick();
            onTap!();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: PrimeTheme.surface800,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
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
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
