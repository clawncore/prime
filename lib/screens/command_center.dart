import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';
import '../services/state_service.dart';
import '../services/audio_service.dart';
import '../widgets/neural_brain_visualization.dart';
import '../widgets/status_bar.dart';
import '../widgets/agent_panel.dart';
import '../widgets/telemetry_panel.dart';
import '../widgets/activity_feed.dart';
import '../widgets/jarvis_hud.dart';
import '../widgets/mini_bar.dart';
import '../widgets/hud_overlay.dart';
import '../services/voice_service.dart';

class CommandCenter extends StatefulWidget {
  const CommandCenter({super.key});

  @override
  State<CommandCenter> createState() => _CommandCenterState();
}

class _CommandCenterState extends State<CommandCenter>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateService = context.watch<StateService>();
    final state = stateService.state;
    final voiceState = stateService.voiceState;

    return Scaffold(
      backgroundColor: PrimeTheme.surface950,
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                const StatusBar(),
                Expanded(
                  child: Row(
                    children: [
                      const AgentPanel(),
                      Expanded(
                        child: _buildMainArea(state, voiceState),
                      ),
                      const TelemetryPanel(),
                    ],
                  ),
                ),
                const JarvisHud(),
              ],
            ),
          ),
          HudOverlay(primeState: state),
          const MiniBar(),
          _buildModeSelector(state),
        ],
      ),
    );
  }

  Widget _buildMainArea(PrimeState state, VoiceState voiceState) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: _buildCoreArea(state, voiceState),
        ),
        const SizedBox(height: 1),
        SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(
                child: _buildActivitySection(),
              ),
              const SizedBox(width: 1),
              Expanded(
                flex: 2,
                child: _buildTranscriptSection(state),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoreArea(PrimeState state, VoiceState voiceState) {
    return Container(
      decoration: const BoxDecoration(
        color: PrimeTheme.surface950,
      ),
      child: Stack(
        children: [
          Center(
            child: NeuralBrainVisualization(
              primeState: state,
              voiceState: voiceState,
              size: 400,
            ),
          ),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: _buildCoreLabel(state),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: _buildModeControls(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreLabel(PrimeState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: PrimeTheme.surface900.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: state.stateColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.stateColor,
              boxShadow: [
                BoxShadow(
                  color: state.stateColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'CORE: ${state.stateLabel}',
            style: TextStyle(
              color: state.stateColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${state.coreFrequency.toStringAsFixed(1)} Hz',
            style: const TextStyle(
              color: PrimeTheme.textSecondary,
              fontSize: 9,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'N: ${state.neuralActivity.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: PrimeTheme.textSecondary,
              fontSize: 9,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeControls(PrimeState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: PrimeMode.values.map((mode) {
        final isActive = state.mode == mode;
        final color = _modeColor(mode);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                AudioService.instance.playClick();
                context.read<StateService>().updateMode(mode);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? color.withValues(alpha: 0.15)
                      : PrimeTheme.surface800,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive
                        ? color.withValues(alpha: 0.5)
                        : PrimeTheme.border,
                  ),
                ),
                child: Text(
                  mode.name.toUpperCase(),
                  style: TextStyle(
                    color: isActive ? color : PrimeTheme.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivitySection() {
    return const ActivityFeed();
  }

  Widget _buildTranscriptSection(PrimeState state) {
    return Container(
      decoration: const BoxDecoration(
        color: PrimeTheme.surface950,
      ),
      child: Column(
        children: [
          _buildTranscriptHeader(),
          const Divider(height: 1, color: PrimeTheme.border),
          Expanded(
            child: state.conversation.isEmpty
                ? _buildTranscriptEmpty()
                : _buildTranscriptList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptHeader() {
    return const Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(Icons.record_voice_over, size: 14, color: PrimeTheme.primeGreen),
          SizedBox(width: 8),
          Text(
            'TRANSCRIPT',
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

  Widget _buildTranscriptEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hearing, size: 32, color: PrimeTheme.textMuted),
          SizedBox(height: 12),
          Text(
            'VOICE INTERACTION ACTIVE',
            style: TextStyle(
              color: PrimeTheme.textMuted,
              fontSize: 10,
              letterSpacing: 2,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Speak to interact with PRIME',
            style: TextStyle(
              color: PrimeTheme.textMuted,
              fontSize: 9,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptList(PrimeState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: state.conversation.length,
      itemBuilder: (context, index) {
        final msg = state.conversation[index];
        final isUser = msg.role == 'user';
        final color = isUser ? PrimeTheme.primeCyan : PrimeTheme.primeGreen;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUser ? 'YOU' : 'PRIME',
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      msg.content,
                      style: const TextStyle(
                        color: PrimeTheme.textPrimary,
                        fontSize: 10,
                        fontFamily: 'JetBrains Mono',
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeSelector(PrimeState state) {
    return const SizedBox.shrink();
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
