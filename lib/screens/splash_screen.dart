import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/prime_theme.dart';
import '../services/state_service.dart';
import '../services/audio_service.dart';
import 'command_center.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;

  int _step = 0;
  final List<String> _steps = [
    'INITIALIZING PRIME...',
    'LOADING CORE MODULES...',
    'CONNECTING NEURAL MESH...',
    'CALIBRATING SENSORS...',
    'CHECKING AGENT STATUS...',
    'CORE ONLINE',
  ];
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleUp = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    _advanceSteps();
  }

  void _advanceSteps() {
    _stepTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (_step < _steps.length - 1) {
        setState(() => _step++);
        AudioService.instance.playNotification();
      } else {
        timer.cancel();
        _completeBoot();
      }
    });
  }

  void _completeBoot() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    AudioService.instance.playStartup();
    context.read<StateService>().initialize();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CommandCenter(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrimeTheme.surface950,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeIn,
              child: ScaleTransition(
                scale: _scaleUp,
                child: _buildContent(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PRIME Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: PrimeTheme.primeCyan.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: PrimeTheme.primeCyan.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '◈',
              style: TextStyle(
                color: PrimeTheme.primeCyan,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: PrimeTheme.primeCyan.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'CLAWN PRIME',
          style: TextStyle(
            color: PrimeTheme.primeCyan,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
            fontFamily: 'JetBrains Mono',
            shadows: [
              Shadow(
                color: PrimeTheme.primeCyan,
                blurRadius: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'AUTONOMOUS AI COMMAND CENTER',
          style: TextStyle(
            color: PrimeTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 4,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const SizedBox(height: 40),
        // Step progress
        SizedBox(
          width: 300,
          child: Column(
            children: [
              ...List.generate(_steps.length, (index) {
                final isActive = index == _step;
                final isComplete = index < _step;
                return _buildStepRow(_steps[index], isActive, isComplete);
              }),
            ],
          ),
        ),
        const SizedBox(height: 40),
        // Progress bar
        SizedBox(
          width: 200,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (_step + 1) / _steps.length,
                  backgroundColor: PrimeTheme.surface700,
                  valueColor:
                      const AlwaysStoppedAnimation(PrimeTheme.primeCyan),
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(((_step + 1) / _steps.length) * 100).toInt()}%',
                style: const TextStyle(
                  color: PrimeTheme.textMuted,
                  fontSize: 9,
                  fontFamily: 'JetBrains Mono',
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepRow(String label, bool isActive, bool isComplete) {
    final color = isActive
        ? PrimeTheme.primeCyan
        : isComplete
            ? PrimeTheme.primeGreen
            : PrimeTheme.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: isComplete
                ? Icon(Icons.check, size: 10, color: color)
                : isActive
                    ? _PulsingDot(color: color)
                    : Icon(Icons.circle, size: 6, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: 1.5,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(
              alpha: 0.5 + _pulseController.value * 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                  alpha: 0.3 + _pulseController.value * 0.3,
                ),
                blurRadius: 6,
              ),
            ],
          ),
        );
      },
    );
  }
}
