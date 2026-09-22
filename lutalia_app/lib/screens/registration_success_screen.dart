import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../services/pin_service.dart';
import 'pin_setup_screen.dart';
import 'journal_shell.dart';

class RegistrationSuccessScreen extends StatefulWidget {
  const RegistrationSuccessScreen({super.key});

  @override
  State<RegistrationSuccessScreen> createState() =>
      _RegistrationSuccessScreenState();
}

class _RegistrationSuccessScreenState extends State<RegistrationSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _heartController;
  late AnimationController _confettiController;

  late Animation<double> _fadeIn;
  late Animation<double> _heartPulse;

  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _heartPulse = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _heartController,
        curve: Curves.easeInOutBack,
      ),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        setState(() {});
      });

    _generateConfetti();

    _fadeController.forward();
    _heartController.repeat(reverse: true);
    _confettiController.forward();
  }

  void _generateConfetti() {
    final random = Random();
    for (int i = 0; i < 25; i++) {
      _particles.add(
        _ConfettiParticle(
          x: random.nextDouble(),
          y: random.nextDouble() * -1,
          size: random.nextDouble() * 12 + 8,
          speed: random.nextDouble() * 0.008 + 0.004,
          opacity: random.nextDouble() * 0.6 + 0.4,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _heartController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: Stack(
        children: [
          ..._particles.map((p) {
            final dy = p.y + p.speed * _confettiController.value * 100;
            return Positioned(
              left: MediaQuery.of(context).size.width * p.x,
              top: dy * MediaQuery.of(context).size.height,
              child: Opacity(
                opacity: p.opacity,
                child: Icon(
                  Icons.favorite,
                  color: const Color(0xFFD49A84),
                  size: p.size,
                ),
              ),
            );
          }),

          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _heartPulse,
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFFD49A84),
                        size: 80,
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "✨ Willkommen in deiner Lutalia‑Welt. ✨",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Cinzel",
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: LutaliaTheme.espresso,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Ein Ort, an dem Wärme leise glitzert,\n"
                      "Gedanken wie feiner Goldstaub tanzen\n"
                      "und jeder Moment ein kleines Stück Magie trägt.\n\n"
                      "Hier beginnt deine Reise.\n"
                      "Hier darfst du ankommen.\n"
                      "Hier darfst du strahlen.\n\n"
                      "Schön, dass du da bist. 🌸💫\n"
                      "Du bist jetzt ein Teil davon. ✨💫",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 40),

                    ElevatedButton(
                      onPressed: () async {
                        final hasPin = await PinService.hasPin();

                        if (!hasPin) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PinSetupScreen(
                                onPinCreated: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const JournalShell(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const JournalShell(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LutaliaTheme.espresso,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Zum persönlichen Bereich",
                        style: TextStyle(
                          fontFamily: "Cinzel",
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}
