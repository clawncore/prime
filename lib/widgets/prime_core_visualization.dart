import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';

class PrimeCoreVisualization extends StatefulWidget {
  final PrimeState primeState;
  final double size;

  const PrimeCoreVisualization({
    super.key,
    required this.primeState,
    this.size = 320,
  });

  @override
  State<PrimeCoreVisualization> createState() =>
      _PrimeCoreVisualizationState();
}

class _PrimeCoreVisualizationState extends State<PrimeCoreVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _PrimeCorePainter(
            animation: _controller.value,
            state: widget.primeState,
          ),
        );
      },
    );
  }
}

class _PrimeCorePainter extends CustomPainter {
  final double animation;
  final PrimeState state;

  _PrimeCorePainter({required this.animation, required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    _drawBackgroundGlow(canvas, center, radius);
    _drawOuterRing(canvas, center, radius);
    _drawMiddleRing(canvas, center, radius);
    _drawInnerRing(canvas, center, radius);
    _drawCoreOrb(canvas, center, radius);
    _drawOrbitalElements(canvas, center, radius);
    _drawSignalPulses(canvas, center, radius);
    _drawParticleField(canvas, center, radius);
  }

  void _drawBackgroundGlow(Canvas canvas, Offset center, double radius) {
    final glowRadius = radius * 0.9;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          state.stateColor.withValues(alpha: 0.15),
          state.stateColor.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: glowRadius),
      );

    canvas.drawCircle(center, glowRadius, paint);
  }

  void _drawOuterRing(Canvas canvas, Offset center, double radius) {
    final ringRadius = radius * 0.82;
    final paint = Paint()
      ..color = PrimeTheme.primeCyan.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, ringRadius, paint);

    final segmentPaint = Paint()
      ..color = PrimeTheme.primeCyan.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final segmentCount = 60;
    final activeSegments = (state.coreFrequency / 100 * segmentCount).round().clamp(3, segmentCount);

    for (int i = 0; i < activeSegments; i++) {
      final angle = (i / segmentCount) * 2 * math.pi + animation * 2 * math.pi;
      final startAngle = angle;
      final sweepAngle = 0.03;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        startAngle,
        sweepAngle,
        false,
        segmentPaint,
      );
    }

    final tickPaint = Paint()
      ..color = PrimeTheme.textMuted.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < 36; i++) {
      final angle = (i / 36) * 2 * math.pi;
      final innerR = ringRadius - (i % 3 == 0 ? 8 : 4);
      final outerR = ringRadius;

      final p1 = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );

      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  void _drawMiddleRing(Canvas canvas, Offset center, double radius) {
    final ringRadius = radius * 0.6;
    final neuralFactor = state.neuralActivity / 100;

    final paint = Paint()
      ..color = PrimeTheme.primeBlue.withValues(alpha: 0.2 + neuralFactor * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, ringRadius, paint);

    final wavePaint = Paint()
      ..color = PrimeTheme.primeBlue.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final waveCount = 3;
    final points = 200;

    for (int w = 0; w < waveCount; w++) {
      path.reset();
      final waveOffset = w * (2 * math.pi / waveCount);
      final amplitude = 3.0 + neuralFactor * 8.0;

      for (int i = 0; i <= points; i++) {
        final t = i / points;
        final angle = t * 2 * math.pi + animation * 2 * math.pi;
        final wave = math.sin(angle * 8 + waveOffset) * amplitude;
        final r = ringRadius + wave;

        final point = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );

        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, wavePaint);
    }
  }

  void _drawInnerRing(Canvas canvas, Offset center, double radius) {
    final ringRadius = radius * 0.38;
    final paint = Paint()
      ..color = PrimeTheme.primePurple.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, ringRadius, paint);

    final dashPaint = Paint()
      ..color = PrimeTheme.primePurple.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final segments = 12;
    for (int i = 0; i < segments; i++) {
      final startAngle = (i / segments) * 2 * math.pi + animation * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        startAngle,
        0.15,
        false,
        dashPaint,
      );
    }
  }

  void _drawCoreOrb(Canvas canvas, Offset center, double radius) {
    final orbRadius = radius * 0.15;
    final coreColor = state.stateColor;

    final outerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          coreColor.withValues(alpha: 0.6),
          coreColor.withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: orbRadius * 2.5),
      );
    canvas.drawCircle(center, orbRadius * 2.5, outerGlow);

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          coreColor,
          coreColor.withValues(alpha: 0.5),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: orbRadius),
      );
    canvas.drawCircle(center, orbRadius, corePaint);

    final pulseRadius = orbRadius * (1.2 + 0.3 * math.sin(animation * 4 * math.pi));
    final pulsePaint = Paint()
      ..color = coreColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, pulseRadius, pulsePaint);
  }

  void _drawOrbitalElements(Canvas canvas, Offset center, double radius) {
    final orbits = [0.48, 0.58, 0.72];
    final colors = [PrimeTheme.primeCyan, PrimeTheme.primeBlue, PrimeTheme.primePurple];
    final speeds = [1.0, -0.7, 0.5];
    final dotCounts = [4, 3, 5];

    for (int o = 0; o < orbits.length; o++) {
      final orbitRadius = radius * orbits[o];
      final paint = Paint()
        ..color = colors[o].withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      canvas.drawCircle(center, orbitRadius, paint);

      for (int d = 0; d < dotCounts[o]; d++) {
        final angle =
            (d / dotCounts[o]) * 2 * math.pi + animation * speeds[o] * 2 * math.pi;
        final dotPos = Offset(
          center.dx + orbitRadius * math.cos(angle),
          center.dy + orbitRadius * math.sin(angle),
        );

        final dotSize = 2.5 + 1.0 * math.sin(animation * 6 * math.pi + d);
        final dotPaint = Paint()
          ..color = colors[o].withValues(alpha: 0.7 + 0.3 * math.sin(angle));
        canvas.drawCircle(dotPos, dotSize, dotPaint);
      }
    }
  }

  void _drawSignalPulses(Canvas canvas, Offset center, double radius) {
    if (!state.coreOnline) return;

    final pulseCount = 3;
    final pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < pulseCount; i++) {
      final t = (animation * 2 + i / pulseCount) % 1.0;
      final pulseRadius = t * radius * 0.85;
      final alpha = (1.0 - t) * 0.5;

      pulsePaint.color = state.stateColor.withValues(alpha: alpha);
      canvas.drawCircle(center, pulseRadius, pulsePaint);
    }
  }

  void _drawParticleField(Canvas canvas, Offset center, double radius) {
    if (!state.coreOnline) return;

    final random = math.Random(42);
    final particleCount = 40;
    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final baseAngle = random.nextDouble() * 2 * math.pi;
      final baseRadius = radius * 0.2 + random.nextDouble() * radius * 0.65;

      final angle =
          baseAngle + animation * (0.5 + random.nextDouble()) * 2 * math.pi;
      final r =
          baseRadius + 5 * math.sin(animation * 4 * math.pi + i);

      final pos = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );

      final size = 0.5 + random.nextDouble() * 1.5;
      final alpha = 0.2 + 0.3 * math.sin(animation * 3 * math.pi + i);

      particlePaint.color = state.stateColor.withValues(alpha: alpha);
      canvas.drawCircle(pos, size, particlePaint);
    }
  }

  @override
  bool shouldRepaint(_PrimeCorePainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.state != state;
}
