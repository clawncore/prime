import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';

enum CoreState { idle, listening, thinking, speaking, executing, error, offline }

class PrimeCore extends StatefulWidget {
  final CoreState coreState;
  final double neuralActivity;
  final double coreFrequency;
  final double? audioAmplitude;
  final String stateLabel;
  final VoidCallback? onTap;

  const PrimeCore({
    super.key,
    this.coreState = CoreState.idle,
    this.neuralActivity = 0,
    this.coreFrequency = 0,
    this.audioAmplitude,
    this.stateLabel = 'READY',
    this.onTap,
  });

  @override
  State<PrimeCore> createState() => _PrimeCoreState();
}

class _PrimeCoreState extends State<PrimeCore> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _orbitalController;
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late AnimationController _neuralController;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
    _orbitalController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _scanController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _neuralController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _orbitalController.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    _neuralController.dispose();
    super.dispose();
  }

  Color get _stateColor {
    switch (widget.coreState) {
      case CoreState.idle: return PrimeTheme.primeCyan;
      case CoreState.listening: return PrimeTheme.primeCyan;
      case CoreState.thinking: return PrimeTheme.primePurple;
      case CoreState.speaking: return PrimeTheme.primeCyan;
      case CoreState.executing: return PrimeTheme.primeBlue;
      case CoreState.error: return PrimeTheme.statusError;
      case CoreState.offline: return PrimeTheme.statusOffline;
    }
  }

  double get _activity => widget.neuralActivity.clamp(0, 100) / 100;
  double get _amplitude => (widget.audioAmplitude ?? 0).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _orbitalController,
          _pulseController,
          _scanController,
          _neuralController,
        ]),
        builder: (context, _) {
          return CustomPaint(
            painter: _PrimeCorePainter(
              mainAnim: _mainController.value,
              orbitalAnim: _orbitalController.value,
              pulseAnim: _pulseController.value,
              scanAnim: _scanController.value,
              neuralAnim: _neuralController.value,
              stateColor: _stateColor,
              coreState: widget.coreState,
              activity: _activity,
              amplitude: _amplitude,
              stateLabel: widget.stateLabel,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _PrimeCorePainter extends CustomPainter {
  final double mainAnim;
  final double orbitalAnim;
  final double pulseAnim;
  final double scanAnim;
  final double neuralAnim;
  final Color stateColor;
  final CoreState coreState;
  final double activity;
  final double amplitude;
  final String stateLabel;

  _PrimeCorePainter({
    required this.mainAnim,
    required this.orbitalAnim,
    required this.pulseAnim,
    required this.scanAnim,
    required this.neuralAnim,
    required this.stateColor,
    required this.coreState,
    required this.activity,
    required this.amplitude,
    required this.stateLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseRadius = math.min(cx, cy) * 0.38;

    // Layer 1: Ambient radial glow
    _drawAmbientGlow(canvas, cx, cy, baseRadius);
    // Layer 2: Soft energy field
    _drawEnergyField(canvas, cx, cy, baseRadius);
    // Layer 3: Inner nucleus
    _drawNucleus(canvas, cx, cy, baseRadius);
    // Layer 4: Fine circular rings
    _drawOrbitalRings(canvas, cx, cy, baseRadius);
    // Layer 5: Audio-reactive waveform
    _drawWaveformRing(canvas, cx, cy, baseRadius);
    // Layer 6: Technical tick ring
    _drawRadialTicks(canvas, cx, cy, baseRadius);
    // Layer 7: Segmented orbital ring
    _drawOuterSegments(canvas, cx, cy, baseRadius);
    // Layer 8: Orbiting particles
    _drawParticles(canvas, cx, cy, baseRadius);
    // Layer 9: Neural connection paths
    _drawNeuralMesh(canvas, cx, cy, baseRadius);
    // Layer 10: Outer scanning ring
    _drawScanLine(canvas, cx, cy, baseRadius);
    // Core pulse
    _drawCorePulse(canvas, cx, cy, baseRadius);
    // State label
    _drawStateLabel(canvas, cx, cy, baseRadius);
  }

  void _drawAmbientGlow(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          stateColor.withValues(alpha: 0.1 + activity * 0.1),
          stateColor.withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 3.5));
    canvas.drawRect(Rect.fromCircle(center: Offset(cx, cy), radius: r * 3.5), paint);
  }

  void _drawEnergyField(Canvas canvas, double cx, double cy, double r) {
    final fieldR = r * 1.8;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          stateColor.withValues(alpha: 0.06 + amplitude * 0.04),
          stateColor.withValues(alpha: 0.02),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: fieldR));

    // Draw multiple overlapping ellipses for energy field
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(mainAnim * 0.2 * 2 * math.pi);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: fieldR * 2, height: fieldR * 1.6),
      paint,
    );
    canvas.rotate(0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: fieldR * 1.8, height: fieldR * 1.4),
      paint..color = stateColor.withValues(alpha: 0.03),
    );
    canvas.restore();
  }

  void _drawNucleus(Canvas canvas, double cx, double cy, double r) {
    final nucleusR = r * 0.24;
    final breathe = 1 + math.sin(pulseAnim * 2 * math.pi) * 0.05 + amplitude * 0.1;
    final actualR = nucleusR * breathe;

    // Deep outer glow (large, soft)
    final deepGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          stateColor.withValues(alpha: 0.1),
          stateColor.withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: actualR * 7));
    canvas.drawCircle(Offset(cx, cy), actualR * 7, deepGlow);

    // Mid glow
    final midGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          stateColor.withValues(alpha: 0.25),
          stateColor.withValues(alpha: 0.1),
          stateColor.withValues(alpha: 0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: actualR * 4));
    canvas.drawCircle(Offset(cx, cy), actualR * 4, midGlow);

    // Inner glow ring
    final innerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          stateColor.withValues(alpha: 0.5),
          stateColor.withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: actualR * 2.2));
    canvas.drawCircle(Offset(cx, cy), actualR * 2.2, innerGlow);

    // Core orb - multi-layer
    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.98),
          stateColor.withValues(alpha: 0.95),
          stateColor.withValues(alpha: 0.6),
          stateColor.withValues(alpha: 0.2),
          stateColor.withValues(alpha: 0.05),
        ],
        stops: const [0.0, 0.15, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: actualR));
    canvas.drawCircle(Offset(cx, cy), actualR, orbPaint);

    // Sharp bright ring around core
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = stateColor.withValues(alpha: 0.7 + amplitude * 0.3);
    canvas.drawCircle(Offset(cx, cy), actualR + 2, ringPaint);

    // Internal particles (tiny moving dots inside nucleus)
    final rng = math.Random(42);
    for (int i = 0; i < 8; i++) {
      final angle = rng.nextDouble() * 2 * math.pi + neuralAnim * 0.5 * 2 * math.pi;
      final dist = actualR * (0.2 + rng.nextDouble() * 0.6);
      final px = cx + math.cos(angle) * dist;
      final py = cy + math.sin(angle) * dist;
      final pAlpha = 0.3 + math.sin(neuralAnim * 2 * math.pi + i * 0.8) * 0.3;
      canvas.drawCircle(
        Offset(px, py),
        0.8,
        Paint()..color = Colors.white.withValues(alpha: pAlpha),
      );
    }
  }

  void _drawOrbitalRings(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    // Ring 1 - outermost
    final r1 = r * 1.55;
    final offset1 = orbitalAnim * 2 * math.pi;
    for (int i = 0; i < 3; i++) {
      final startAngle = offset1 + (i * 2 * math.pi / 3);
      paint.color = stateColor.withValues(alpha: 0.12);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r1),
        startAngle, math.pi * 0.4, false, paint,
      );
    }

    // Ring 2 - mid
    final r2 = r * 1.35;
    final offset2 = -orbitalAnim * 1.5 * 2 * math.pi;
    for (int i = 0; i < 4; i++) {
      final startAngle = offset2 + (i * 2 * math.pi / 4);
      paint.color = stateColor.withValues(alpha: 0.08);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r2),
        startAngle, math.pi * 0.3, false, paint,
      );
    }

    // Ring 3 - inner fine ring
    final r3 = r * 1.15;
    final offset3 = orbitalAnim * 0.7 * 2 * math.pi;
    paint.color = stateColor.withValues(alpha: 0.06);
    canvas.drawCircle(Offset(cx, cy), r3, paint..style = PaintingStyle.stroke..strokeWidth = 0.3);

    // Orbiting nodes
    _drawOrbitingNode(canvas, cx, cy, r1, offset1, stateColor, 4.0);
    _drawOrbitingNode(canvas, cx, cy, r1, offset1 + math.pi, stateColor.withValues(alpha: 0.6), 3.0);
    _drawOrbitingNode(canvas, cx, cy, r2, offset2 + math.pi / 2, PrimeTheme.primePurple, 3.5);
  }

  void _drawOrbitingNode(Canvas canvas, double cx, double cy, double r, double angle, Color color, double size) {
    final x = cx + math.cos(angle) * r;
    final y = cy + math.sin(angle) * r;
    final paint = Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: Offset(x, y), radius: size * 3));
    canvas.drawCircle(Offset(x, y), size, paint..color = color);
    canvas.drawCircle(Offset(x, y), size * 2, paint..color = color.withValues(alpha: 0.15));
  }

  void _drawRadialTicks(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4;

    final tickR = r * 1.2;
    const tickCount = 72;
    final scanAngle = scanAnim * 2 * math.pi;

    for (int i = 0; i < tickCount; i++) {
      final angle = (i / tickCount) * 2 * math.pi;
      final dist = (angle - scanAngle).abs() % (2 * math.pi);
      final proximity = dist < 0.3 ? 1 - dist / 0.3 : 0;

      paint.color = stateColor.withValues(alpha: 0.1 + proximity * 0.5);

      final start = Offset(cx + math.cos(angle) * (tickR - 3), cy + math.sin(angle) * (tickR - 3));
      final end = Offset(cx + math.cos(angle) * tickR, cy + math.sin(angle) * tickR);
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawOuterSegments(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final outerR = r * 1.7;
    const segments = 60;
    final animOffset = mainAnim * 2 * math.pi;

    for (int i = 0; i < segments; i++) {
      final angle = (i / segments) * 2 * math.pi + animOffset;
      final segActivity = (math.sin(angle * 3 + mainAnim * 4 * math.pi) + 1) / 2;
      final isActive = segActivity > 0.6 || (i % 5 == 0);

      paint.color = isActive
          ? stateColor.withValues(alpha: 0.15 + segActivity * 0.3)
          : PrimeTheme.borderSubtle;

      final start = Offset(cx + math.cos(angle) * (outerR - 4), cy + math.sin(angle) * (outerR - 4));
      final end = Offset(cx + math.cos(angle) * outerR, cy + math.sin(angle) * outerR);
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawWaveformRing(Canvas canvas, double cx, double cy, double r) {
    final waveR = r * 1.08;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    const points = 180;

    for (int i = 0; i <= points; i++) {
      final angle = (i / points) * 2 * math.pi;

      // Multi-frequency wave for realistic voice-like appearance
      final wave1 = math.sin(angle * 6 + mainAnim * 4 * math.pi) * 0.12;
      final wave2 = math.sin(angle * 11 - mainAnim * 3 * 2 * math.pi) * 0.08;
      final wave3 = math.sin(angle * 17 + mainAnim * 5 * 2 * math.pi) * 0.04;

      // Amplitude-reactive distortion
      final ampWave = amplitude * 0.4 *
          (math.sin(angle * 3 + mainAnim * 8 * math.pi) * 0.5 + 0.5);

      final totalWave = wave1 + wave2 + wave3 + ampWave;
      final dist = waveR * (1 + totalWave * 0.1);
      final x = cx + math.cos(angle) * dist;
      final y = cy + math.sin(angle) * dist;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Draw with glow effect
    paint.color = stateColor.withValues(alpha: 0.2 + amplitude * 0.5);
    canvas.drawPath(path, paint);

    // Second pass for glow
    if (amplitude > 0.1) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..color = stateColor.withValues(alpha: amplitude * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawPath(path, glowPaint);
    }
  }

  void _drawNeuralMesh(Canvas canvas, double cx, double cy, double r) {
    final meshR = r * 0.95;
    final rng = math.Random(42);
    final nodes = <Offset>[];

    for (int i = 0; i < 18; i++) {
      final angle = (i / 18) * 2 * math.pi + neuralAnim * 0.3 * 2 * math.pi;
      final dist = meshR * (0.35 + rng.nextDouble() * 0.5);
      nodes.add(Offset(cx + math.cos(angle) * dist, cy + math.sin(angle) * dist));
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final d = (nodes[i] - nodes[j]).distance;
        if (d < meshR * 0.55) {
          final alpha = (1 - d / (meshR * 0.55)) * 0.2 * (0.4 + activity * 0.6);
          linePaint.color = stateColor.withValues(alpha: alpha);
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    final nodePaint = Paint();
    for (final node in nodes) {
      final nAlpha = 0.3 + math.sin(neuralAnim * 2 * math.pi + node.dx) * 0.25;
      nodePaint.color = stateColor.withValues(alpha: nAlpha * (0.4 + activity * 0.6));
      canvas.drawCircle(node, 1.5, nodePaint);
    }
  }

  void _drawParticles(Canvas canvas, double cx, double cy, double r) {
    final rng = math.Random(42);
    final count = 35 + (activity * 25).round();

    for (int i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final dist = r * 0.35 + rng.nextDouble() * r * 1.5;
      final wobble = math.sin(mainAnim * 2 * math.pi + i * 0.7) * r * 0.06;

      final x = cx + math.cos(angle + mainAnim * 0.3 * 2 * math.pi) * (dist + wobble);
      final y = cy + math.sin(angle + mainAnim * 0.3 * 2 * math.pi) * (dist + wobble);

      final pAlpha = 0.08 + rng.nextDouble() * 0.25 * (0.3 + activity * 0.7);
      final pSize = 0.4 + rng.nextDouble() * 1.2;

      final paint = Paint()
        ..color = stateColor.withValues(alpha: pAlpha);
      canvas.drawCircle(Offset(x, y), pSize, paint);
    }
  }

  void _drawCorePulse(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final phase = (pulseAnim + i / 3) % 1.0;
      final pulseR = r * 0.25 + phase * r * 0.7;
      final alpha = (1 - phase) * 0.25 * (0.4 + activity * 0.6);
      paint.color = stateColor.withValues(alpha: alpha);
      canvas.drawCircle(Offset(cx, cy), pulseR, paint);
    }
  }

  void _drawStateLabel(Canvas canvas, double cx, double cy, double r) {
    final textStyle = TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: math.min(r * 0.14, 16),
      fontWeight: FontWeight.w700,
      letterSpacing: 4.0,
      color: stateColor,
    );

    // "PRIME" text
    final primePainter = TextPainter(
      text: TextSpan(text: 'PRIME', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    primePainter.paint(canvas, Offset(cx - primePainter.width / 2, cy - primePainter.height / 2 - 14));

    // State label
    final stateStyle = TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: math.min(r * 0.1, 11),
      fontWeight: FontWeight.w400,
      letterSpacing: 3.0,
      color: stateColor.withValues(alpha: 0.8),
    );

    final statePainter = TextPainter(
      text: TextSpan(text: stateLabel, style: stateStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    statePainter.paint(canvas, Offset(cx - statePainter.width / 2, cy + 8));
  }

  void _drawScanLine(Canvas canvas, double cx, double cy, double r) {
    final scanAngle = scanAnim * 2 * math.pi;
    final scanR = r * 1.65;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          stateColor.withValues(alpha: 0.2),
          stateColor.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: scanR));

    final sweepPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: scanR),
        scanAngle - 0.35, 0.7, false,
      )
      ..close();

    canvas.drawPath(sweepPath, paint);
  }

  @override
  bool shouldRepaint(_PrimeCorePainter oldDelegate) =>
      oldDelegate.mainAnim != mainAnim ||
      oldDelegate.orbitalAnim != orbitalAnim ||
      oldDelegate.pulseAnim != pulseAnim ||
      oldDelegate.scanAnim != scanAnim ||
      oldDelegate.neuralAnim != neuralAnim ||
      oldDelegate.stateColor != stateColor ||
      oldDelegate.coreState != coreState ||
      oldDelegate.activity != activity ||
      oldDelegate.amplitude != amplitude;
}
