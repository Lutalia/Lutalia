import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:health/health.dart';
import '../screens/lutalia_page.dart';

class SchritteScreen extends StatefulWidget {
  final VoidCallback onGoHome;

  const SchritteScreen({
    super.key,
    required this.onGoHome,
  });

  @override
  State<SchritteScreen> createState() => _SchritteScreenState();
}

class _SchritteScreenState extends State<SchritteScreen> {
  late VideoPlayerController _videoController;

  final Health _health = Health(); // ⭐ Health 13.x API
  int todaySteps = 0;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _loadSteps();
  }

  // ⭐ VIDEO INITIALISIEREN
  void _initVideo() {
    _videoController = VideoPlayerController.asset(
      "assets/videos/gesundheitsscreen.mp4",
    )
      ..initialize().then((_) {
        setState(() {});
        _videoController
          ..setLooping(true)
          ..setVolume(0)
          ..play();
      });
  }

  // ⭐ ECHTES SCHRITT-TRACKING (Health 13.x API)
  Future<void> _loadSteps() async {
    final types = <HealthDataType>[HealthDataType.STEPS];
    final permissions = <HealthDataAccess>[HealthDataAccess.READ];

    // ⭐ Berechtigungen anfragen (NEUE API)
    bool granted = await _health.requestAuthorization(
      types,
      permissions: permissions,
    );

    if (!granted) {
      setState(() => todaySteps = 0);
      return;
    }

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      // ⭐ NEUE API: benannte Parameter
      final data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: types,
      );

      int steps = 0;

      for (var item in data) {
        if (item.value is int) {
          steps += item.value as int;
        } else if (item.value is double) {
          steps += (item.value as double).toInt();
        }
      }

      setState(() => todaySteps = steps);
    } catch (e) {
      setState(() => todaySteps = 0);
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LutaliaPage(
      title: "Schritte & Bewegung",
      showBack: true,
      onBackPressed: widget.onGoHome,
      child: Column(
        children: [
          const SizedBox(height: 10),

          if (_videoController.value.isInitialized)
            SizedBox(
              height: 200,
              width: double.infinity,
              child: VideoPlayer(_videoController),
            ),

          const SizedBox(height: 10),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _sectionTitle("Heutige Schritte"),
                  const SizedBox(height: 8),
                  _stepsBubble("$todaySteps Schritte"),

                  const SizedBox(height: 24),

                  _sectionTitle("Wochenübersicht"),
                  const SizedBox(height: 10),
                  _weekBar(),

                  const SizedBox(height: 24),

                  _sectionTitle("Monatsübersicht"),
                  const SizedBox(height: 10),
                  _monthBox(),

                  const SizedBox(height: 24),

                  _sectionTitle("Challenges"),
                  const SizedBox(height: 10),
                  _challengeTile("7‑Tage‑Schritte‑Challenge"),
                  const SizedBox(height: 12),
                  _challengeTile("10.000‑Schritte‑Challenge"),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ UI ELEMENTE

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: "Cinzel",
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFFB3AA97),
      ),
    );
  }

  Widget _stepsBubble(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFB3AA97),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: "Cinzel",
          fontSize: 20,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _weekBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        return Container(
          width: 22,
          height: (i == 5) ? 70 : (i == 3 ? 55 : 40),
          decoration: BoxDecoration(
            color: const Color(0xFFB3AA97),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1.4),
          ),
        );
      }),
    );
  }

  Widget _monthBox() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFB3AA97),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      alignment: Alignment.center,
      child: const Text(
        "Durchschnitt: 6.420 Schritte / Tag",
        style: TextStyle(
          fontFamily: "Cinzel",
          fontSize: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _challengeTile(String label) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFB3AA97),
          width: 1.4,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white,
            width: 1.4,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFB3AA97),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: "Cinzel",
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
