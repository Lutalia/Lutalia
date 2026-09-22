import 'package:flutter/material.dart';
import 'dart:math';

class LutaliaMacroFlower extends StatelessWidget {
  final double size;

  final double carbs;
  final double fat;
  final double protein;
  final double sugar;

  final double carbsGoal;
  final double fatGoal;
  final double proteinGoal;
  final double sugarGoal;

  const LutaliaMacroFlower({
    super.key,
    required this.size,
    required this.carbs,
    required this.fat,
    required this.protein,
    required this.sugar,
    required this.carbsGoal,
    required this.fatGoal,
    required this.proteinGoal,
    required this.sugarGoal,
  });

  double _progress(double value, double goal) {
    if (goal <= 0) return 0;
    return (value / goal).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final carbProgress = _progress(carbs, carbsGoal);
    final fatProgress = _progress(fat, fatGoal);
    final proteinProgress = _progress(protein, proteinGoal);
    final sugarProgress = _progress(sugar, sugarGoal);

    final List<double> progresses = [
      carbProgress,
      fatProgress,
      proteinProgress,
      sugarProgress,
      (carbProgress + fatProgress + proteinProgress + sugarProgress) / 4,
    ];

    final totalKcal = carbs * 4 + protein * 4 + fat * 9 + sugar * 4;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < 5; i++)
            Transform.rotate(
              angle: (i * 72) * pi / 180,
              child: _EmojiPetal(
                size: size,
                progress: progresses[i],
              ),
            ),

          // Kalorien in der Mitte
          Container(
            width: size * 0.38,
            height: size * 0.38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              "${totalKcal.round()} kcal",
              style: const TextStyle(
                fontFamily: "Cinzel",
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8C6F5A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiPetal extends StatelessWidget {
  final double size;
  final double progress;

  const _EmojiPetal({
    required this.size,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.55,
      height: size * 0.65,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(size * 0.55, size * 0.65),
            painter: _EmojiPetalOutlinePainter(),
          ),
          ClipPath(
            clipper: _EmojiPetalFillClipper(progress),
            child: CustomPaint(
              size: Size(size * 0.55, size * 0.65),
              painter: _EmojiPetalFillPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiPetalOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8C6F5A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // 🌸 Emoji-Blütenblatt – elegant, mittelbreit, leichte Einbuchtung, unten leicht spitz
    path.moveTo(w * 0.50, h * 0.05);

    // linke obere Einbuchtung
    path.quadraticBezierTo(w * 0.32, h * 0.00, w * 0.25, h * 0.18);

    // linke bauchige Seite
    path.quadraticBezierTo(w * 0.15, h * 0.40, w * 0.28, h * 0.60);

    // untere Spitze
    path.quadraticBezierTo(w * 0.50, h * 0.95, w * 0.72, h * 0.60);

    // rechte bauchige Seite
    path.quadraticBezierTo(w * 0.85, h * 0.40, w * 0.75, h * 0.18);

    // rechte obere Einbuchtung
    path.quadraticBezierTo(w * 0.68, h * 0.00, w * 0.50, h * 0.05);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _EmojiPetalFillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Gradient gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFFFF7FA), // innen sehr hell
        const Color(0xFFFFDCEB), // rosa Verlauf
        const Color(0xFFFFC1DA), // außen intensiver
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.50, h * 0.05);
    path.quadraticBezierTo(w * 0.32, h * 0.00, w * 0.25, h * 0.18);
    path.quadraticBezierTo(w * 0.15, h * 0.40, w * 0.28, h * 0.60);
    path.quadraticBezierTo(w * 0.50, h * 0.95, w * 0.72, h * 0.60);
    path.quadraticBezierTo(w * 0.85, h * 0.40, w * 0.75, h * 0.18);
    path.quadraticBezierTo(w * 0.68, h * 0.00, w * 0.50, h * 0.05);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _EmojiPetalFillClipper extends CustomClipper<Path> {
  final double progress;

  _EmojiPetalFillClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    final fillHeight = size.height * (1 - progress);

    path.addRect(Rect.fromLTWH(0, fillHeight, size.width, size.height));
    return path;
  }

  @override
  bool shouldReclip(_) => true;
}
