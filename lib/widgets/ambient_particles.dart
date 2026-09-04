import 'dart:math' as math;
import 'package:flutter/material.dart';

class AmbientParticlesPainter extends CustomPainter {
  final double animation;
  final Color color;

  AmbientParticlesPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final particleCount = 40;

    for (int i = 0; i < particleCount; i++) {
      // Each particle has its own trajectory
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.1 + rng.nextDouble() * 0.3;
      final phase = rng.nextDouble() * 2 * math.pi;

      // Gentle drift
      final x = baseX + math.sin(animation * speed * 2 * math.pi + phase) * 30;
      final y = baseY + math.cos(animation * speed * 1.5 * 2 * math.pi + phase * 0.7) * 20;

      // Subtle fade in/out
      final alpha = 0.03 + math.sin(animation * 2 * math.pi + phase) * 0.02;

      final paint = Paint()
        ..color = color.withValues(alpha: alpha.clamp(0.01, 0.05))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 1.0 + rng.nextDouble() * 0.5, paint);
    }

    // Occasional scan lines (very subtle)
    for (int i = 0; i < 3; i++) {
      final scanY = (animation * 0.3 + i * 0.33) % 1.0 * size.height;
      final scanPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            color.withValues(alpha: 0.015),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromLTWH(0, scanY - 30, size.width, 60),
        );
      canvas.drawRect(
        Rect.fromLTWH(0, scanY - 30, size.width, 60),
        scanPaint,
      );
    }
  }

  @override
  bool shouldRepaint(AmbientParticlesPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
