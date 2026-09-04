import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';

class HudOverlay extends StatefulWidget {
  final PrimeState primeState;

  const HudOverlay({super.key, required this.primeState});

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.primeState.coreOnline) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _HudPainter(
            animation: _controller.value,
            state: widget.primeState,
          ),
        );
      },
    );
  }
}

class _HudPainter extends CustomPainter {
  final double animation;
  final PrimeState state;

  _HudPainter({required this.animation, required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    _drawCornerBrackets(canvas, size);
    _drawScanLine(canvas, size);
    _drawDataStreams(canvas, size);
  }

  void _drawCornerBrackets(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = state.stateColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final bracketSize = 30.0;
    final margin = 12.0;

    // Top-left
    final tl = Offset(margin, margin);
    canvas.drawLine(tl, Offset(tl.dx + bracketSize, tl.dy), paint);
    canvas.drawLine(tl, Offset(tl.dx, tl.dy + bracketSize), paint);

    // Top-right
    final tr = Offset(size.width - margin, margin);
    canvas.drawLine(tr, Offset(tr.dx - bracketSize, tr.dy), paint);
    canvas.drawLine(tr, Offset(tr.dx, tr.dy + bracketSize), paint);

    // Bottom-left
    final bl = Offset(margin, size.height - margin);
    canvas.drawLine(bl, Offset(bl.dx + bracketSize, bl.dy), paint);
    canvas.drawLine(bl, Offset(bl.dx, bl.dy - bracketSize), paint);

    // Bottom-right
    final br = Offset(size.width - margin, size.height - margin);
    canvas.drawLine(br, Offset(br.dx - bracketSize, br.dy), paint);
    canvas.drawLine(br, Offset(br.dx, br.dy - bracketSize), paint);
  }

  void _drawScanLine(Canvas canvas, Size size) {
    final scanY = (animation * size.height * 2) % (size.height * 1.2) - size.height * 0.1;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          state.stateColor.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(0, scanY, size.width, 60),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, scanY, size.width, 60),
      paint,
    );
  }

  void _drawDataStreams(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final streamCount = 6;
    final rng = math.Random(42);

    for (int i = 0; i < streamCount; i++) {
      final x = rng.nextDouble() * size.width;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final yOffset = (animation * speed * size.height) % size.height;
      final streamHeight = 20.0 + rng.nextDouble() * 40.0;

      final alpha = 0.05 + 0.05 * math.sin(animation * 2 * math.pi + i);
      paint.color = state.stateColor.withValues(alpha: alpha);

      canvas.drawLine(
        Offset(x, yOffset),
        Offset(x, yOffset + streamHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HudPainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.state != state;
}
