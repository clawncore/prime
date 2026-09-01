import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';
import '../services/voice_service.dart';

class NeuralBrainVisualization extends StatefulWidget {
  final PrimeState primeState;
  final VoiceState voiceState;
  final double size;

  const NeuralBrainVisualization({
    super.key,
    required this.primeState,
    required this.voiceState,
    this.size = 400,
  });

  @override
  State<NeuralBrainVisualization> createState() => _NeuralBrainVisualizationState();
}

class _NeuralBrainVisualizationState extends State<NeuralBrainVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
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
          painter: _NeuralBrainPainter(
            animation: _controller.value,
            state: widget.primeState,
            voiceState: widget.voiceState,
          ),
        );
      },
    );
  }
}

class _NeuralBrainPainter extends CustomPainter {
  final double animation;
  final PrimeState state;
  final VoiceState voiceState;

  _NeuralBrainPainter({
    required this.animation,
    required this.state,
    required this.voiceState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    _drawBackgroundAura(canvas, center, radius);
    _drawNeuralMesh(canvas, center, radius);
    _drawBrainOutline(canvas, center, radius);
    _drawNeuralNodes(canvas, center, radius);
    _drawSynapticConnections(canvas, center, radius);
    _drawDataStreams(canvas, center, radius);
    _drawCorePulse(canvas, center, radius);
    _drawVoiceIndicator(canvas, center, radius);
  }

  void _drawBackgroundAura(Canvas canvas, Offset center, double radius) {
    final auraRadius = radius * 1.1;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          _voiceStateColor().withValues(alpha: 0.12),
          state.stateColor.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: auraRadius),
      );
    canvas.drawCircle(center, auraRadius, paint);
  }

  void _drawBrainOutline(Canvas canvas, Offset center, double radius) {
    final brainRadius = radius * 0.65;
    final paint = Paint()
      ..color = PrimeTheme.primeCyan.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Brain-like shape using overlapping ellipses
    final path = Path();
    for (int i = 0; i < 100; i++) {
      final angle = (i / 100) * 2 * math.pi;
      final wobble1 = 0.08 * math.sin(angle * 5 + animation * 4);
      final wobble2 = 0.05 * math.cos(angle * 3 - animation * 3);
      final r = brainRadius * (1.0 + wobble1 + wobble2);

      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle) * 0.85,
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Inner glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          state.stateColor.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: brainRadius),
      );
    canvas.drawPath(path, glowPaint);
  }

  void _drawNeuralMesh(Canvas canvas, Offset center, double radius) {
    final meshRadius = radius * 0.55;
    final nodeCount = 24;
    final rng = math.Random(42);

    final nodes = <Offset>[];
    for (int i = 0; i < nodeCount; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final r = rng.nextDouble() * meshRadius;
      nodes.add(Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      ));
    }

    // Draw mesh connections
    final meshPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < meshRadius * 0.6) {
          final alpha = (1.0 - dist / (meshRadius * 0.6)) * 0.15;
          final pulse = 0.5 + 0.5 * math.sin(animation * 4 * math.pi + i + j);
          meshPaint.color = state.stateColor.withValues(alpha: alpha * pulse);
          canvas.drawLine(nodes[i], nodes[j], meshPaint);
        }
      }
    }
  }

  void _drawNeuralNodes(Canvas canvas, Offset center, double radius) {
    final nodeCount = 16;
    final rng = math.Random(77);

    for (int i = 0; i < nodeCount; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final r = radius * 0.2 + rng.nextDouble() * radius * 0.4;

      final nodeCenter = Offset(
        center.dx + r * math.cos(angle + animation * 0.5),
        center.dy + r * math.sin(angle + animation * 0.5),
      );

      final pulse = 0.5 + 0.5 * math.sin(animation * 6 * math.pi + i * 0.7);
      final nodeSize = 2.0 + pulse * 2.0;

      final activityFactor = state.neuralActivity / 100;
      final color = _getNodeColor(i, activityFactor);

      // Outer glow
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.4 * pulse),
            color.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: nodeCenter, radius: nodeSize * 3),
        );
      canvas.drawCircle(nodeCenter, nodeSize * 3, glowPaint);

      // Core
      final corePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            color,
            color.withValues(alpha: 0.5),
          ],
        ).createShader(
          Rect.fromCircle(center: nodeCenter, radius: nodeSize),
        );
      canvas.drawCircle(nodeCenter, nodeSize, corePaint);
    }
  }

  void _drawSynapticConnections(Canvas canvas, Offset center, double radius) {
    final connectionCount = 8;
    final rng = math.Random(123);

    for (int i = 0; i < connectionCount; i++) {
      final startAngle = rng.nextDouble() * 2 * math.pi;
      final endAngle = startAngle + (rng.nextDouble() - 0.5) * math.pi;
      final r = radius * (0.2 + rng.nextDouble() * 0.35);

      final start = Offset(
        center.dx + r * math.cos(startAngle),
        center.dy + r * math.sin(startAngle),
      );
      final end = Offset(
        center.dx + r * math.cos(endAngle),
        center.dy + r * math.sin(endAngle),
      );

      final control = Offset(
        center.dx + (rng.nextDouble() - 0.5) * radius * 0.3,
        center.dy + (rng.nextDouble() - 0.5) * radius * 0.3,
      );

      final pulse = 0.3 + 0.7 * math.sin(animation * 3 * math.pi + i * 1.2);
      final alpha = 0.1 + pulse * 0.2;

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

      final paint = Paint()
        ..color = state.stateColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawPath(path, paint);

      // Traveling signal
      final t = (animation * 2 + i * 0.15) % 1.0;
      final signalPoint = _quadraticBezier(start, control, end, t);
      final signalPaint = Paint()
        ..color = PrimeTheme.primeCyan.withValues(alpha: 0.6 * pulse)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(signalPoint, 2.0, signalPaint);
    }
  }

  void _drawDataStreams(Canvas canvas, Offset center, double radius) {
    final streamCount = 5;
    final rng = math.Random(456);

    for (int i = 0; i < streamCount; i++) {
      final baseAngle = (i / streamCount) * 2 * math.pi;
      final streamRadius = radius * (0.3 + rng.nextDouble() * 0.25);
      final speed = 1.5 + rng.nextDouble();

      final particleCount = 6;
      for (int p = 0; p < particleCount; p++) {
        final t = (animation * speed + p / particleCount) % 1.0;
        final angle = baseAngle + t * 0.5;
        final r = streamRadius * (0.5 + t * 0.5);

        final pos = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );

        final alpha = (1.0 - t) * 0.4;
        final size = 1.0 + (1.0 - t) * 2.0;

        final paint = Paint()
          ..color = state.stateColor.withValues(alpha: alpha)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, size, paint);
      }
    }
  }

  void _drawCorePulse(Canvas canvas, Offset center, double radius) {
    final coreRadius = radius * 0.08;

    // Outer pulse rings
    final ringCount = 3;
    for (int i = 0; i < ringCount; i++) {
      final t = (animation * 1.5 + i / ringCount) % 1.0;
      final ringRadius = coreRadius * (1.5 + t * 2.5);
      final alpha = (1.0 - t) * 0.3;

      final paint = Paint()
        ..color = state.stateColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, ringRadius, paint);
    }

    // Core orb
    final coreGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.95),
          state.stateColor,
          state.stateColor.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: coreRadius * 3),
      );
    canvas.drawCircle(center, coreRadius * 3, coreGlow);

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 1.0),
          state.stateColor,
          state.stateColor.withValues(alpha: 0.6),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: coreRadius),
      );
    canvas.drawCircle(center, coreRadius, corePaint);
  }

  void _drawVoiceIndicator(Canvas canvas, Offset center, double radius) {
    if (voiceState == VoiceState.idle) return;

    final indicatorRadius = radius * 0.72;
    final voiceColor = _voiceStateColor();
    final arcCount = 12;

    for (int i = 0; i < arcCount; i++) {
      final startAngle = (i / arcCount) * 2 * math.pi + animation * 4;
      final sweepAngle = 0.15;

      double intensity;
      if (voiceState == VoiceState.listening) {
        intensity = 0.3 + 0.7 * math.sin(animation * 8 * math.pi + i);
      } else if (voiceState == VoiceState.speaking) {
        intensity = 0.5 + 0.5 * math.sin(animation * 12 * math.pi + i * 2);
      } else {
        intensity = 0.2;
      }

      final paint = Paint()
        ..color = voiceColor.withValues(alpha: intensity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + intensity * 2.0;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: indicatorRadius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Voice state label
    final label = voiceState == VoiceState.listening
        ? 'LISTENING'
        : voiceState == VoiceState.speaking
            ? 'SPEAKING'
            : voiceState == VoiceState.processing
                ? 'PROCESSING'
                : '';

    if (label.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: voiceColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy + indicatorRadius + 12),
      );
    }
  }

  Color _voiceStateColor() {
    switch (voiceState) {
      case VoiceState.listening:
        return PrimeTheme.primeCyan;
      case VoiceState.speaking:
        return PrimeTheme.primeGreen;
      case VoiceState.processing:
        return PrimeTheme.primeBlue;
      case VoiceState.error:
        return PrimeTheme.primeRed;
      case VoiceState.idle:
      default:
        return PrimeTheme.textMuted;
    }
  }

  Color _getNodeColor(int index, double activity) {
    final colors = [
      PrimeTheme.primeCyan,
      PrimeTheme.primeBlue,
      PrimeTheme.primePurple,
      PrimeTheme.primeAmber,
    ];
    return colors[index % colors.length];
  }

  Offset _quadraticBezier(Offset p0, Offset p1, Offset p2, double t) {
    final x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
    final y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(_NeuralBrainPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.state != state ||
      oldDelegate.voiceState != voiceState;
}
