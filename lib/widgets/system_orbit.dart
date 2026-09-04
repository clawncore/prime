import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/prime_theme.dart';

class SystemOrbit extends StatefulWidget {
  final Map<String, bool> systems;
  final double size;

  const SystemOrbit({
    super.key,
    required this.systems,
    this.size = 500,
  });

  @override
  State<SystemOrbit> createState() => _SystemOrbitState();
}

class _SystemOrbitState extends State<SystemOrbit> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
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
          painter: _SystemOrbitPainter(
            anim: _controller.value,
            systems: widget.systems,
          ),
        );
      },
    );
  }
}

class _SystemOrbitPainter extends CustomPainter {
  final double anim;
  final Map<String, bool> systems;

  _SystemOrbitPainter({required this.anim, required this.systems});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) * 0.82;
    final entries = systems.entries.toList();

    // Orbit ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = PrimeTheme.borderSubtle;
    canvas.drawCircle(Offset(cx, cy), radius, ringPaint);

    // Active segments
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < entries.length; i++) {
      final angle = (i / entries.length) * 2 * math.pi - math.pi / 2;
      final nextAngle = ((i + 1) / entries.length) * 2 * math.pi - math.pi / 2;

      if (entries[i].value) {
        final pulse = (math.sin(anim * 2 * math.pi + i * 1.3) + 1) / 2;
        activePaint.color = PrimeTheme.primeCyan.withValues(alpha: 0.25 + pulse * 0.35);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          angle, nextAngle - angle, false, activePaint,
        );
      }
    }

    // Connection lines from center to active nodes
    final connectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < entries.length; i++) {
      if (entries[i].value) {
        final angle = (i / entries.length) * 2 * math.pi - math.pi / 2;
        final x = cx + math.cos(angle) * radius;
        final y = cy + math.sin(angle) * radius;

        // Draw connection line from center area to node
        final innerR = radius * 0.3;
        final startX = cx + math.cos(angle) * innerR;
        final startY = cy + math.sin(angle) * innerR;

        final pulse = (math.sin(anim * 2 * math.pi + i * 1.3) + 1) / 2;
        connectionPaint.color = PrimeTheme.primeCyan.withValues(alpha: 0.08 + pulse * 0.12);
        canvas.drawLine(Offset(startX, startY), Offset(x, y), connectionPaint);

        // Data particles traveling along connection
        final particleCount = 3;
        for (int p = 0; p < particleCount; p++) {
          final t = (anim * 1.5 + p / particleCount) % 1.0;
          final px = startX + (x - startX) * t;
          final py = startY + (y - startY) * t;
          final pAlpha = (1 - t) * 0.4 * pulse;
          canvas.drawCircle(
            Offset(px, py),
            1.5,
            Paint()..color = PrimeTheme.primeCyan.withValues(alpha: pAlpha),
          );
        }
      }
    }

    // System nodes
    for (int i = 0; i < entries.length; i++) {
      final angle = (i / entries.length) * 2 * math.pi - math.pi / 2;
      final x = cx + math.cos(angle) * radius;
      final y = cy + math.sin(angle) * radius;
      final isActive = entries[i].value;

      // Node dot
      final dotPaint = Paint();
      if (isActive) {
        final pulse = (math.sin(anim * 2 * math.pi + i * 1.3) + 1) / 2;
        dotPaint.color = PrimeTheme.primeCyan;
        canvas.drawCircle(Offset(x, y), 3 + pulse * 1.5, dotPaint);
        dotPaint.color = PrimeTheme.primeCyan.withValues(alpha: 0.15);
        canvas.drawCircle(Offset(x, y), 8 + pulse * 3, dotPaint);
      } else {
        dotPaint.color = PrimeTheme.statusOffline;
        canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
      }

      // Label
      final labelAngle = angle;
      final labelR = radius + 18;
      final lx = cx + math.cos(labelAngle) * labelR;
      final ly = cy + math.sin(labelAngle) * labelR;

      final labelPainter = TextPainter(
        text: TextSpan(
          text: entries[i].key,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 8,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
            color: isActive ? PrimeTheme.primeCyan.withValues(alpha: 0.85) : PrimeTheme.textMuted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(canvas, Offset(lx - labelPainter.width / 2, ly - labelPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(_SystemOrbitPainter old) => old.anim != anim || old.systems != systems;
}
