import 'package:flutter/material.dart';
import 'dart:math';

class MacroRingCircle extends StatefulWidget {
  final num carbs;
  final num fat;
  final num protein;
  final num sugar;
  final String centerText;
  final double size;

  const MacroRingCircle({
    super.key,
    required this.carbs,
    required this.fat,
    required this.protein,
    required this.sugar,
    required this.centerText,
    this.size = 260,
  });

  @override
  State<MacroRingCircle> createState() => _MacroRingCircleState();
}

class _MacroRingCircleState extends State<MacroRingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Farben
    final carbsColor = const Color(0xFFD9A679);
    final fatColor = const Color(0xFFE8A8A1);
    final proteinColor = const Color(0xFFA8C9A1);
    final sugarColor = const Color(0xFFE8C6A1);

    // kcal-Berechnung
    final carbsKcal = widget.carbs * 4;
    final fatKcal = widget.fat * 9;
    final proteinKcal = widget.protein * 4;
    final sugarKcal = widget.sugar * 4;

    final totalKcal = carbsKcal + fatKcal + proteinKcal + sugarKcal;

    double pct(num v) => totalKcal == 0 ? 0 : (v / totalKcal);

    final segments = [
      _Segment(carbsColor, pct(carbsKcal)),
      _Segment(fatColor, pct(fatKcal)),
      _Segment(proteinColor, pct(proteinKcal)),
      _Segment(sugarColor, pct(sugarKcal)),
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final anim = Curves.easeOutCubic.transform(_controller.value);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 4-Segment-Ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _MacroRingPainter(
                  segments: segments,
                  thickness: widget.size * 0.12, // A2 mitteldick
                  animation: anim,
                ),
              ),

              // Innerer Kreis
              Container(
                width: widget.size * 0.52,
                height: widget.size * 0.52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.centerText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: "Cinzel",
                      fontSize: 22,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Segment {
  final Color color;
  final double percent;

  _Segment(this.color, this.percent);
}

class _MacroRingPainter extends CustomPainter {
  final List<_Segment> segments;
  final double thickness;
  final double animation;

  _MacroRingPainter({
    required this.segments,
    required this.thickness,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - thickness / 2;

    double startAngle = -pi / 2;

    for (final seg in segments) {
      final sweep = 2 * pi * seg.percent * animation;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
