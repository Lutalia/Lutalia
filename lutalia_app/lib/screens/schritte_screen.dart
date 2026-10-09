import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../screens/lutalia_page.dart';
import '../services/health/health_sync_service.dart';
import '../services/health/health_texts.dart';

class SchritteScreen extends StatefulWidget {
  final VoidCallback onGoHome;

  const SchritteScreen({super.key, required this.onGoHome});

  @override
  State<SchritteScreen> createState() => _SchritteScreenState();
}

class _SchritteScreenState extends State<SchritteScreen> {
  late VideoPlayerController _videoController;

  static const int _historyDays = 30;
  static final NumberFormat _stepsFormat = NumberFormat.decimalPattern('de_DE');

  int todaySteps = 0;
  List<({DateTime day, int? steps})> _days = const [];
  HealthSyncOutcome? _problem;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _loadSteps();
  }

  // ⭐ VIDEO INITIALISIEREN
  void _initVideo() {
    _videoController =
        VideoPlayerController.asset("assets/videos/gesundheitsscreen.mp4")
          ..initialize().then((_) {
            setState(() {});
            _videoController
              ..setLooping(true)
              ..setVolume(0)
              ..play();
          });
  }

  // ⭐ ECHTES SCHRITT-TRACKING (Apple Health / Health Connect)
  // First visit asks for permission (as before); afterwards it refreshes
  // silently. Stored values show instantly and cover offline use.
  Future<void> _loadSteps() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final cached = await HealthSyncService.cachedDay(DateTime.now());
    if (mounted && cached?.steps != null) {
      setState(() => todaySteps = cached!.steps!);
    }

    HealthSyncOutcome? problem;
    if (!await HealthSyncService.isConnected()) {
      final HealthSyncResult result = await HealthSyncService.connect();
      if (!result.isSuccess) problem = result.outcome;
    }
    final days = await HealthSyncService.loadDailySteps(_historyDays);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _problem = problem;
      _days = days;
      todaySteps = days.isEmpty ? todaySteps : (days.last.steps ?? todaySteps);
    });
  }

  void _resolveProblem(HealthSyncOutcome outcome) {
    if (outcome == HealthSyncOutcome.notInstalled ||
        outcome == HealthSyncOutcome.needsUpdate) {
      HealthSyncService.installHealthConnect();
    } else {
      HealthSyncService.openPermissionSettings();
    }
  }

  List<({DateTime day, int? steps})> get _lastWeek =>
      _days.length <= 7 ? _days : _days.sublist(_days.length - 7);

  int? get _monthlyAverage {
    final recorded = _days
        .map((d) => d.steps)
        .whereType<int>()
        .where((s) => s > 0)
        .toList();
    if (recorded.isEmpty) return null;
    return (recorded.reduce((a, b) => a + b) / recorded.length).round();
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
            child: RefreshIndicator(
              color: const Color(0xFFB3AA97),
              onRefresh: _loadSteps,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  children: [
                    _sectionTitle("Heutige Schritte"),
                    const SizedBox(height: 8),
                    _stepsBubble("${_stepsFormat.format(todaySteps)} Schritte"),
                    _healthProblemHint(),

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
          ),
        ],
      ),
    );
  }

  Widget _healthProblemHint() {
    final HealthSyncOutcome? problem = _problem;
    if (problem == null) return const SizedBox.shrink();
    final String? action = HealthTexts.actionLabel(problem);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: action == null ? null : () => _resolveProblem(problem),
        child: Text(
          action == null
              ? HealthTexts.message(problem)
              : '${HealthTexts.message(problem)}\n$action ›',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.35,
            color: Color(0xFF8C7A70),
          ),
        ),
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

  /// Last 7 days, bar height relative to the best day. Days without data
  /// stay as a short stub so the week still reads as seven days.
  Widget _weekBar() {
    const double maxBarHeight = 70;
    const double minBarHeight = 8;
    final week = _lastWeek;
    final int best = week
        .map((d) => d.steps ?? 0)
        .fold(0, (a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final entry = i < week.length ? week[i] : null;
        final int steps = entry?.steps ?? 0;
        final double height = best == 0
            ? minBarHeight
            : (minBarHeight + (maxBarHeight - minBarHeight) * steps / best);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFFB3AA97),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.4),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entry == null
                  ? ''
                  : DateFormat.E('de_DE').format(entry.day).substring(0, 2),
              style: const TextStyle(
                fontFamily: "Cinzel",
                fontSize: 11,
                color: Color(0xFFB3AA97),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _monthBox() {
    final int? average = _monthlyAverage;
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFB3AA97),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      alignment: Alignment.center,
      child: Text(
        "Durchschnitt: "
        "${average == null ? '–' : _stepsFormat.format(average)} Schritte / Tag",
        style: const TextStyle(
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
        border: Border.all(color: const Color(0xFFB3AA97), width: 1.4),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 1.4),
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
