import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController logoController;
  late Animation<double> logoScale;

  late AnimationController textController;
  late Animation<double> textOpacity;

  late AnimationController oliveController;

  final List<_DustParticle> fairyDust = [];
  final Random random = Random();

  bool _skipped = false; // ⭐ verhindert doppeltes Navigieren

  @override
  void initState() {
    super.initState();

    logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    logoScale = CurvedAnimation(
      parent: logoController,
      curve: Curves.easeOutBack,
    );

    textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    textOpacity = CurvedAnimation(
      parent: textController,
      curve: Curves.easeIn,
    );

    oliveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )
      ..addListener(() {
        setState(() {});
      })
      ..forward();

    logoController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) textController.forward();
    });

    // ⭐ Automatischer Übergang nach 9 Sekunden
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 9), () {
        _skipSplash();
      });
    });
  }

  void _skipSplash() {
    if (_skipped || !mounted) return;
    _skipped = true;

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    logoController.dispose();
    textController.dispose();
    oliveController.dispose();
    super.dispose();
  }

  // ❤️ Herzpfad
  Offset heartPath(double t, double w, double h) {
    final x = 16 * pow(sin(t), 3);
    final y = 13 * cos(t) -
        5 * cos(2 * t) -
        2 * cos(3 * t) -
        cos(4 * t);

    final scale = w * 0.022;
    final centerX = w * 0.5;
    final centerY = h * 0.45;

    return Offset(centerX + x * scale, centerY - y * scale);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final feeHead = Offset(w * 0.68, h * 0.28);

    Offset pos;
    final t = oliveController.value;

    if (t <= 0.8) {
      final heartT = (t / 0.8) * 2 * pi;

      pos = heartPath(heartT, w, h) +
          Offset(
            sin(heartT * 3) * 2,
            cos(heartT * 2) * 2,
          );

      for (int i = 0; i < 26; i++) {
        fairyDust.add(
          _DustParticle(
            position: pos +
                Offset(
                  random.nextDouble() * 14 - 7,
                  random.nextDouble() * 14 - 7,
                ),
            size: 3 + random.nextDouble() * 4,
            opacity: 0.40 + random.nextDouble() * 0.35,
            color: const Color(0xFFF3E9E2),
            life: random.nextDouble(),
            isGlow: false,
          ),
        );

        fairyDust.add(
          _DustParticle(
            position: pos +
                Offset(
                  random.nextDouble() * 20 - 10,
                  random.nextDouble() * 20 - 10,
                ),
            size: 6 + random.nextDouble() * 8,
            opacity: 0.10 + random.nextDouble() * 0.15,
            color: Colors.white,
            life: random.nextDouble(),
            isGlow: true,
          ),
        );
      }
    } else {
      final landT = (t - 0.8) / 0.2;
      final lastHeartPos = heartPath(2 * pi, w, h);
      pos = Offset.lerp(lastHeartPos, feeHead, Curves.easeOut.transform(landT))!;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // ⭐ GANZER SCREEN tappbar
      onTap: _skipSplash,               // ⭐ Tap → sofort weiter

      child: Scaffold(
        backgroundColor: LutaliaTheme.creme,
        body: Stack(
          children: [
            ...fairyDust.map((dust) {
              final glow = 0.5 + 0.5 * sin(dust.life * 6);

              return Positioned(
                left: dust.position.dx,
                top: dust.position.dy,
                child: Container(
                  width: dust.size,
                  height: dust.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dust.color.withOpacity(
                      dust.opacity * (dust.isGlow ? 1 : glow),
                    ),
                  ),
                ),
              );
            }).toList(),

            Positioned(
              left: pos.dx,
              top: pos.dy,
              child: Image.asset(
                'assets/images/olive.png',
                width: 55,
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: logoScale,
                    child: Image.asset(
                      'assets/logo/legaldeclara.logo.png',
                      width: 200,
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeTransition(
                    opacity: textOpacity,
                    child: Column(
                      children: const [
                        Text(
                          "Willkommen",
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: LutaliaTheme.espresso,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Benvenuti",
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: LutaliaTheme.espresso,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DustParticle {
  final Offset position;
  final double size;
  final double opacity;
  final Color color;
  final double life;
  final bool isGlow;

  _DustParticle({
    required this.position,
    required this.size,
    required this.opacity,
    required this.color,
    required this.life,
    required this.isGlow,
  });
}
