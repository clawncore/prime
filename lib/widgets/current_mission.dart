import 'package:flutter/material.dart';
import '../theme/prime_theme.dart';
import '../services/state_service.dart';
import 'prime_core.dart';

class CurrentMission extends StatelessWidget {
  final StateService state;
  final CoreState coreState;
  final String stateLabel;

  const CurrentMission({
    super.key,
    required this.state,
    required this.coreState,
    required this.stateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PrimeTheme.bgCard,
        border: Border.all(color: PrimeTheme.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.radar, size: 12, color: PrimeTheme.primeCyan.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text('CURRENT MISSION', style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: PrimeTheme.textSecondary,
              )),
            ],
          ),
          const SizedBox(height: 8),
          // Mission content
          _buildMissionContent(),
        ],
      ),
    );
  }

  Widget _buildMissionContent() {
    if (!state.coreOnline) {
      return _buildMissionRow('SYSTEM OFFLINE', 'Awaiting initialization', PrimeTheme.statusOffline);
    }

    switch (coreState) {
      case CoreState.listening:
        return _buildMissionRow(
          'VOICE INPUT ACTIVE',
          'Microphone listening',
          PrimeTheme.primeCyan,
        );
      case CoreState.thinking:
        return _buildMissionRow(
          'PROCESSING REQUEST',
          'Analyzing query',
          PrimeTheme.primePurple,
        );
      case CoreState.speaking:
        return _buildMissionRow(
          'RESPONDING',
          'TTS output active',
          PrimeTheme.primeCyan,
        );
      case CoreState.executing:
        return _buildMissionRow(
          'EXECUTING TASK',
          'Agent coordination active',
          PrimeTheme.primeBlue,
        );
      case CoreState.error:
        return _buildMissionRow(
          'ATTENTION REQUIRED',
          'System requires intervention',
          PrimeTheme.statusError,
        );
      default:
        return _buildMissionRow(
          'SYSTEM READY',
          'Awaiting instruction',
          PrimeTheme.statusOnline,
        );
    }
  }

  Widget _buildMissionRow(String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: color,
            )),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 8,
              fontWeight: FontWeight.w400,
              color: PrimeTheme.textDim,
            )),
          ],
        ),
      ],
    );
  }
}
