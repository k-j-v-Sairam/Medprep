import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class EcgBackground extends StatefulWidget {
  const EcgBackground({Key? key}) : super(key: key);

  @override
  _EcgBackgroundState createState() => _EcgBackgroundState();
}

class _EcgBackgroundState extends State<EcgBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
      builder: (context, child) {
        return CustomPaint(
          painter: EcgPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class EcgPainter extends CustomPainter {
  final double progress;
  EcgPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height * 0.4; // Slightly above center

    // Create the ECG pattern points
    List<Offset> points = [];
    double x = 0;
    while (x < size.width + 200) {
      points.add(Offset(x, midY));
      x += 60;
      // P wave
      points.add(Offset(x, midY));
      x += 20;
      points.add(Offset(x, midY - 15));
      x += 20;
      points.add(Offset(x, midY));
      x += 30;
      // QRS complex
      points.add(Offset(x, midY + 20)); // Q
      x += 15;
      points.add(Offset(x, midY - 80)); // R
      x += 15;
      points.add(Offset(x, midY + 30)); // S
      x += 15;
      points.add(Offset(x, midY));
      x += 40;
      // T wave
      points.add(Offset(x, midY - 20));
      x += 30;
      points.add(Offset(x, midY));
      x += 70; // Rest
    }

    if (points.isEmpty) return;

    // Background faint grid (medical monitor style)
    final gridPaint = Paint()
      ..color = AppTheme.neonCyan.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }

    // Faint full ECG line
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = AppTheme.neonCyan.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Glowing sweeping pulse
    final currentX = size.width * progress;
    final pulsePaint = Paint()
      ..color = AppTheme.neonCyan.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = AppTheme.neonCyan.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    final pulsePath = Path();
    bool started = false;

    // Draw a fading tail for the pulse (from currentX - 150 to currentX + 20)
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      if (p1.dx <= currentX + 20 && p1.dx >= currentX - 150) {
        if (!started) {
          pulsePath.moveTo(p1.dx, p1.dy);
          started = true;
        }
        pulsePath.lineTo(p2.dx, p2.dy);
      }
    }

    canvas.drawPath(pulsePath, glowPaint);
    canvas.drawPath(pulsePath, pulsePaint);
    
    // Draw the dot at the head of the pulse
    canvas.drawCircle(
      Offset(currentX, _getYForX(points, currentX, midY)),
      6.0,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5.0),
    );
  }

  double _getYForX(List<Offset> points, double targetX, double defaultY) {
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (targetX >= p1.dx && targetX <= p2.dx) {
        // Interpolate Y
        final t = (targetX - p1.dx) / (p2.dx - p1.dx);
        return p1.dy + t * (p2.dy - p1.dy);
      }
    }
    return defaultY;
  }

  @override
  bool shouldRepaint(covariant EcgPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
