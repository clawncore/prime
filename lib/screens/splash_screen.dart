import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/prime_theme.dart';
import '../services/audio_service.dart';
import '../services/state_service.dart';
import '../services/voice_service.dart';
import 'command_center.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;

  int _currentStep = 0;
  bool _booting = true;

  final _steps = const [
    'INITIALIZING PRIME...',
    'LOADING CORE MODULES...',
    'CHECKING LLM STATUS...',
    'LOADING CONFIGURATION...',
    'CHECKING AGENT STATUS...',
    'CORE ONLINE',
  ];

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoController.forward();
    _startBoot();
  }

  Future<void> _startBoot() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() => _currentStep = i);
      AudioService.instance.playNotification();
    }

    _progressController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    AudioService.instance.playStartup();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CommandCenter(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrimeTheme.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: PrimeTheme.bgGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: _buildLogo(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'PRIME',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6.0,
                  color: PrimeTheme.primeCyan,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'PERSONAL AI SYSTEM',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2.0,
                  color: PrimeTheme.textMuted,
                ),
              ),

              const SizedBox(height: 48),

              // Boot steps
              ...List.generate(_steps.length, (i) {
                return _buildStep(i);
              }),

              const SizedBox(height: 40),

              // Progress bar
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressController.value,
                          backgroundColor: PrimeTheme.borderSubtle,
                          valueColor: const AlwaysStoppedAnimation<Color>(PrimeTheme.primeCyan),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return Text(
                          '${(_progressController.value * 100).round()}%',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 9,
                            color: PrimeTheme.textDim,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: PrimeTheme.primeCyan.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: PrimeTheme.primeCyan.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'P',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: PrimeTheme.primeCyan,
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int index) {
    final isComplete = index < _currentStep;
    final isActive = index == _currentStep;

    Color dotColor;
    Widget dot;

    if (isComplete) {
      dotColor = PrimeTheme.statusOnline;
      dot = Icon(Icons.check_circle, size: 12, color: dotColor);
    } else if (isActive) {
      dotColor = PrimeTheme.primeCyan;
      dot = Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: dotColor, width: 1.5),
        ),
        child: Center(
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else {
      dotColor = PrimeTheme.textDim;
      dot = Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: dotColor, width: 1),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 10),
          Text(
            _steps[index],
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: 0.8,
              color: isComplete
                  ? PrimeTheme.statusOnline
                  : isActive
                      ? PrimeTheme.primeCyan
                      : PrimeTheme.textDim,
            ),
          ),
        ],
      ),
    );
  }
}
