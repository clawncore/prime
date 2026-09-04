import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';
import '../services/state_service.dart';
import '../services/voice_service.dart';
import '../widgets/prime_core.dart';
import '../widgets/system_orbit.dart';
import '../widgets/conversation_panel.dart';
import '../widgets/command_bar.dart';
import '../widgets/agent_network.dart';
import '../widgets/telemetry_compact.dart';
import '../widgets/activity_feed_compact.dart';
import '../widgets/current_mission.dart';
import '../widgets/ambient_particles.dart';
import '../widgets/debug_console.dart';

class CommandCenter extends StatefulWidget {
  const CommandCenter({super.key});

  @override
  State<CommandCenter> createState() => _CommandCenterState();
}

class _CommandCenterState extends State<CommandCenter> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _coreSizeController;
  late AnimationController _ambientController;
  double _audioAmplitude = 0;
  Timer? _amplitudeTimer;
  final _rng = math.Random();
  double _speakPhase = 0;
  double _listenPhase = 0;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _coreSizeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // Clock update
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });

    // Audio amplitude simulation
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      final state = context.read<StateService>();
      final now = DateTime.now().millisecondsSinceEpoch / 1000.0;

      if (state.voiceState == VoiceState.speaking) {
        _speakPhase += 0.15;
        final burst = math.sin(_speakPhase * 2.3) * 0.5 + 0.5;
        final syllable = math.sin(_speakPhase * 8.7) * 0.3;
        final jitter = _rng.nextDouble() * 0.15;
        final pause = math.sin(_speakPhase * 0.4) > 0.7 ? 0.0 : 1.0;
        setState(() {
          _audioAmplitude = (burst * 0.6 + syllable * 0.2 + jitter * 0.2) * pause;
        });
      } else if (state.voiceState == VoiceState.listening) {
        _listenPhase += 0.08;
        final ambient = math.sin(_listenPhase * 1.5) * 0.15 + 0.15;
        final microBurst = _rng.nextDouble() * 0.05;
        setState(() {
          _audioAmplitude = ambient + microBurst;
        });
      } else {
        setState(() {
          _audioAmplitude = 0.02 + math.sin(now * 0.5) * 0.02;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _coreSizeController.dispose();
    _ambientController.dispose();
    _amplitudeTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  CoreState _mapCoreState(StateService svc) {
    if (!svc.coreOnline) return CoreState.offline;
    if (svc.voiceState == VoiceState.listening) return CoreState.listening;
    if (svc.voiceState == VoiceState.speaking) return CoreState.speaking;
    if (svc.voiceState == VoiceState.processing) return CoreState.thinking;
    return CoreState.idle;
  }

  String _mapStateLabel(StateService svc) {
    if (!svc.coreOnline) return 'OFFLINE';
    switch (svc.voiceState) {
      case VoiceState.listening: return 'LISTENING';
      case VoiceState.speaking: return 'SPEAKING';
      case VoiceState.processing: return 'THINKING';
      case VoiceState.error: return 'ATTENTION';
      default: return 'READY';
    }
  }

  void _openDebugConsole(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          margin: const EdgeInsets.all(12),
          child: const DebugConsole(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StateService>();
    final coreState = _mapCoreState(state);
    final stateLabel = _mapStateLabel(state);

    final systems = <String, bool>{
      'LLM': state.llmAvailable,
      'MEMORY': true,
      'AGENTS': state.agents.any((a) => a.status == AgentStatus.online || a.status == AgentStatus.busy),
      'VOICE': state.voiceEnabled,
      'FILES': true,
      'SYSTEM': state.coreOnline,
    };

    return Scaffold(
      backgroundColor: PrimeTheme.bgDeep,
      body: FadeTransition(
        opacity: _fadeController,
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(gradient: PrimeTheme.bgGradient),
            ),

            // Subtle grid
            CustomPaint(
              size: Size.infinite,
              painter: _GridPainter(),
            ),

            // Ambient particles
            AnimatedBuilder(
              animation: _ambientController,
              builder: (context, _) => CustomPaint(
                size: Size.infinite,
                painter: AmbientParticlesPainter(
                  animation: _ambientController.value,
                  color: PrimeTheme.primeCyan,
                ),
              ),
            ),

            // Main layout
            Column(
              children: [
                // Header
                _buildHeader(state, coreState, stateLabel),

                // Main content
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 1100;

                      if (isWide) {
                        return _buildWideLayout(state, coreState, stateLabel, systems, constraints);
                      } else {
                        return _buildNarrowLayout(state, coreState, stateLabel, systems, constraints);
                      }
                    },
                  ),
                ),

                // Command bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: const CommandBar(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(StateService state, CoreState coreState, String stateLabel) {
    final timeStr = '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: PrimeTheme.bgSurface,
        border: Border(bottom: BorderSide(color: PrimeTheme.borderSubtle)),
      ),
      child: Row(
        children: [
          // Logo mark (geometric symbol)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: PrimeTheme.primeCyan.withValues(alpha: 0.5), width: 1.5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: PrimeTheme.primeCyan.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('PRIME', style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.0,
            color: PrimeTheme.textPrimary,
          )),
          const SizedBox(width: 8),
          Text('PERSONAL AI SYSTEM', style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 8,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.8,
            color: PrimeTheme.textDim,
          )),

          const Spacer(),

          // Core status with state
          _CoreStatusChip(
            isOnline: state.coreOnline,
            coreState: coreState,
            stateLabel: stateLabel,
          ),
          const SizedBox(width: 8),

          // LLM status
          _LLMStatusChip(isAvailable: state.llmAvailable),
          const SizedBox(width: 12),

          // Mode selector
          _ModeChip(
            currentMode: state.mode,
            onModeChanged: (mode) => state.updateMode(mode),
          ),
          const SizedBox(width: 12),

          // Time
          Text(timeStr, style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: PrimeTheme.textSecondary,
            letterSpacing: 1.0,
          )),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    StateService state,
    CoreState coreState,
    String stateLabel,
    Map<String, bool> systems,
    BoxConstraints constraints,
  ) {
    // Responsive core sizing - 45-55% of available space
    final availableHeight = constraints.maxHeight - 120; // mission + padding
    final availableWidth = constraints.maxWidth - 440; // side panels
    final coreSize = math.min(
      availableHeight * 0.8,
      availableWidth * 0.5,
    ).clamp(340.0, 700.0);
    final orbitSize = coreSize * 1.3;

    return Row(
      children: [
        // Left panel - Agent Network
        SizedBox(
          width: 210,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
            child: AgentNetwork(
              agents: state.agents,
              coreState: coreState,
            ),
          ),
        ),

        // Center column
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                const SizedBox(height: 8),

                // Neural Core (dominant)
                Expanded(
                  flex: 4,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // System orbit
                        AnimatedBuilder(
                          animation: _coreSizeController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _coreSizeController.value,
                              child: SizedBox(
                                width: orbitSize,
                                height: orbitSize,
                                child: SystemOrbit(systems: systems, size: orbitSize),
                              ),
                            );
                          },
                        ),

                        // PRIME Core
                        AnimatedBuilder(
                          animation: _coreSizeController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _coreSizeController.value,
                              child: SizedBox(
                                width: coreSize,
                                height: coreSize,
                                child: PrimeCore(
                                  coreState: coreState,
                                  neuralActivity: state.state.neuralActivity,
                                  coreFrequency: state.telemetry.cpuUsage,
                                  audioAmplitude: _audioAmplitude,
                                  stateLabel: stateLabel,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Current Mission
                SizedBox(
                  height: 80,
                  child: CurrentMission(
                    state: state,
                    coreState: coreState,
                    stateLabel: stateLabel,
                  ),
                ),

                const SizedBox(height: 8),

                // Activity timeline
                SizedBox(
                  height: 120,
                  child: ActivityFeedCompact(
                    feed: state.activityFeed,
                  ),
                ),

                const SizedBox(height: 8),

                // Conversation
                const SizedBox(
                  height: 180,
                  child: ConversationPanel(),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Right panel - Telemetry
        SizedBox(
          width: 210,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
            child: TelemetryCompact(
              telemetry: state.telemetry,
              voiceState: state.voiceState,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
    StateService state,
    CoreState coreState,
    String stateLabel,
    Map<String, bool> systems,
    BoxConstraints constraints,
  ) {
    // Responsive core sizing for narrow view
    final coreSize = math.min(
      constraints.maxHeight * 0.4,
      constraints.maxWidth * 0.65,
    ).clamp(260.0, 450.0);
    final orbitSize = coreSize * 1.3;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Core + Orbit (dominant)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: orbitSize,
                    height: orbitSize,
                    child: SystemOrbit(systems: systems, size: orbitSize),
                  ),
                  SizedBox(
                    width: coreSize,
                    height: coreSize,
                    child: PrimeCore(
                      coreState: coreState,
                      neuralActivity: state.state.neuralActivity,
                      coreFrequency: state.telemetry.cpuUsage,
                      audioAmplitude: _audioAmplitude,
                      stateLabel: stateLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Current Mission (narrow)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              height: 70,
              child: CurrentMission(
                state: state,
                coreState: coreState,
                stateLabel: stateLabel,
              ),
            ),
          ),

          // Conversation
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(height: 180, child: ConversationPanel()),
          ),

          // Bottom row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 180,
                    child: AgentNetwork(
                      agents: state.agents,
                      coreState: coreState,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 180,
                    child: TelemetryCompact(
                      telemetry: state.telemetry,
                      voiceState: state.voiceState,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Core Status Chip ──
class _CoreStatusChip extends StatelessWidget {
  final bool isOnline;
  final CoreState coreState;
  final String stateLabel;

  const _CoreStatusChip({
    required this.isOnline,
    required this.coreState,
    required this.stateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? PrimeTheme.statusOnline : PrimeTheme.statusOffline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isOnline
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text('CORE: ${stateLabel}', style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: color,
          )),
        ],
      ),
    );
  }
}

// ── LLM Status Chip ──
class _LLMStatusChip extends StatelessWidget {
  final bool isAvailable;

  const _LLMStatusChip({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? PrimeTheme.statusOnline : PrimeTheme.statusOffline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isAvailable
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text('PRIME: ${isAvailable ? 'ONLINE' : 'OFFLINE'}', style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: color,
          )),
        ],
      ),
    );
  }
}

// ── Mode Chip ──
class _ModeChip extends StatefulWidget {
  final PrimeMode currentMode;
  final ValueChanged<PrimeMode> onModeChanged;

  const _ModeChip({required this.currentMode, required this.onModeChanged});

  @override
  State<_ModeChip> createState() => _ModeChipState();
}

class _ModeChipState extends State<_ModeChip> {
  bool _expanded = false;

  Color _modeColor(PrimeMode mode) {
    switch (mode) {
      case PrimeMode.standard: return PrimeTheme.primeCyan;
      case PrimeMode.stealth: return PrimeTheme.primePurple;
      case PrimeMode.combat: return PrimeTheme.statusError;
      case PrimeMode.diagnostic: return PrimeTheme.primeBlue;
      case PrimeMode.sleep: return PrimeTheme.statusBusy;
      case PrimeMode.offline: return PrimeTheme.statusOffline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(widget.currentMode);

    return GestureDetector(
      onTap: () {
        if (_expanded) {
          // Show mode selector
          showModalBottomSheet(
            context: context,
            backgroundColor: PrimeTheme.bgCard,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            builder: (context) => _ModeSelector(
              currentMode: widget.currentMode,
              onModeSelected: (mode) {
                widget.onModeChanged(mode);
                Navigator.pop(context);
              },
            ),
          );
        }
        setState(() => _expanded = !_expanded);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.currentMode.name.toUpperCase(), style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: color,
              )),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, size: 10, color: color.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mode Selector Bottom Sheet ──
class _ModeSelector extends StatelessWidget {
  final PrimeMode currentMode;
  final ValueChanged<PrimeMode> onModeSelected;

  const _ModeSelector({required this.currentMode, required this.onModeSelected});

  Color _modeColor(PrimeMode mode) {
    switch (mode) {
      case PrimeMode.standard: return PrimeTheme.primeCyan;
      case PrimeMode.stealth: return PrimeTheme.primePurple;
      case PrimeMode.combat: return PrimeTheme.statusError;
      case PrimeMode.diagnostic: return PrimeTheme.primeBlue;
      case PrimeMode.sleep: return PrimeTheme.statusBusy;
      case PrimeMode.offline: return PrimeTheme.statusOffline;
    }
  }

  String _modeDescription(PrimeMode mode) {
    switch (mode) {
      case PrimeMode.standard: return 'Normal operation';
      case PrimeMode.stealth: return 'Reduced visibility';
      case PrimeMode.combat: return 'High priority mode';
      case PrimeMode.diagnostic: return 'Technical information';
      case PrimeMode.sleep: return 'Low power standby';
      case PrimeMode.offline: return 'System offline';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('SELECT MODE', style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: PrimeTheme.textSecondary,
          )),
          const SizedBox(height: 12),
          ...PrimeMode.values.map((mode) {
            final color = _modeColor(mode);
            final isSelected = mode == currentMode;
            return GestureDetector(
              onTap: () => onModeSelected(mode),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? color.withValues(alpha: 0.3) : PrimeTheme.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? color : PrimeTheme.textDim,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mode.name.toUpperCase(), style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? color : PrimeTheme.textPrimary,
                        )),
                        Text(_modeDescription(mode), style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 8,
                          color: PrimeTheme.textDim,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Grid Painter ──
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Subtle technical grid
    final paint = Paint()
      ..color = PrimeTheme.borderSubtle.withValues(alpha: 0.1)
      ..strokeWidth = 0.3;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Radial illumination from center
    final center = Offset(size.width / 2, size.height / 2);
    final radialPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          PrimeTheme.primeCyan.withValues(alpha: 0.025),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.35));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), radialPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
