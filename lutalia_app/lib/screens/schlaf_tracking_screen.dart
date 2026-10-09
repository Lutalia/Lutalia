import 'package:flutter/material.dart';

import '../models/health_day_summary.dart';
import '../services/health/health_sync_service.dart';
import '../services/health/health_texts.dart';

class SchlafTrackingScreen extends StatefulWidget {
  const SchlafTrackingScreen({super.key});

  @override
  State<SchlafTrackingScreen> createState() => _SchlafTrackingScreenState();
}

class _SchlafTrackingScreenState extends State<SchlafTrackingScreen>
    with TickerProviderStateMixin {
  // Slider & Phasen State
  double sleepHours = 7.5;
  int deepSleepMinutes = 120;
  int remSleepMinutes = 100;
  int awakeMinutes = 15;

  // Einflüsse vor der Nachtruhe
  bool lateScreenTime = false;
  bool heavyMeal = false;
  bool lateCaffeine = false;
  bool lateWorkout = false;
  bool alcohol = false;
  bool highStress = false;
  bool racingThoughts = false;

  final TextEditingController _customInfluenceController =
      TextEditingController();
  final ValueNotifier<String> _customInfluenceNotifier = ValueNotifier<String>(
    '',
  );

  late final PageController _tipsController;
  int _currentTipPage = 0;

  // Ausgewählter Tag in der Timeline (Standard: heute, 24.09.2026 - Index 4)
  int _selectedDayIndex = 4;

  // Mock-Daten für die Timeline: Alle Tage außer dem heutigen (Index 4) haben 0 Werte
  final List<Map<String, dynamic>> _weeklyData = [
    {
      'date': '20.09',
      'day': 'So',
      'score': 0.0,
      'hours': 0.0,
      'deep': 0,
      'rem': 0,
      'awake': 0,
      'quality': 'Keine Aufzeichnung',
      'influences': [],
    },
    {
      'date': '21.09',
      'day': 'Mo',
      'score': 0.0,
      'hours': 0.0,
      'deep': 0,
      'rem': 0,
      'awake': 0,
      'quality': 'Keine Aufzeichnung',
      'influences': [],
    },
    {
      'date': '22.09',
      'day': 'Di',
      'score': 0.0,
      'hours': 0.0,
      'deep': 0,
      'rem': 0,
      'awake': 0,
      'quality': 'Keine Aufzeichnung',
      'influences': [],
    },
    {
      'date': '23.09',
      'day': 'Mi',
      'score': 0.0,
      'hours': 0.0,
      'deep': 0,
      'rem': 0,
      'awake': 0,
      'quality': 'Keine Aufzeichnung',
      'influences': [],
    },
    {
      'date': '24.09',
      'day': 'Do',
      'score': 78.0, // Nur der heutige Tag (Index 4) wird dynamisch berechnet
      'hours': 7.0,
      'deep': 95,
      'rem': 85,
      'awake': 20,
      'quality': 'Solide',
      'influences': ['Spätes Workout'],
    },
    {
      'date': '25.09',
      'day': 'Fr',
      'score': 0.0,
      'hours': 0.0,
      'deep': 0,
      'rem': 0,
      'awake': 0,
      'quality': 'Ausstehend',
      'influences': [],
    },
    {
      'date': '26.09',
      'day': 'Sa',
      'score': 0.0,
      'hours': 0.0,
      'deep': 0,
      'rem': 0,
      'awake': 0,
      'quality': 'Ausstehend',
      'influences': [],
    },
  ];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Apple Health / Health Connect
  bool _isSyncing = false;
  HealthDaySummary? _healthDay;

  @override
  void initState() {
    super.initState();
    _loadHealthOnOpen();
    _tipsController = PageController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _customInfluenceController.addListener(() {
      _customInfluenceNotifier.value = _customInfluenceController.text;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tipsController.dispose();
    _customInfluenceController.dispose();
    _customInfluenceNotifier.dispose();
    super.dispose();
  }

  /// Cached values first (instant, offline), then a silent platform refresh
  /// for users who already connected. Never shows a permission prompt.
  Future<void> _loadHealthOnOpen() async {
    final HealthDaySummary? cached = await HealthSyncService.cachedDay(
      DateTime.now(),
    );
    if (!mounted) return;
    _applyHealthDay(cached);
    final HealthDaySummary? fresh = await HealthSyncService.refreshToday();
    if (!mounted) return;
    _applyHealthDay(fresh);
  }

  Future<void> _syncHealth() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final HealthSyncResult result = await HealthSyncService.connect();
    if (!mounted) return;
    setState(() => _isSyncing = false);
    _applyHealthDay(result.today);
    _showHealthMessage(result.outcome);
  }

  /// Real values replace the manual defaults only when a night was recorded.
  /// Missing stages become 0 (shown with a hint) rather than invented numbers.
  void _applyHealthDay(HealthDaySummary? day) {
    if (day == null) return;
    setState(() {
      _healthDay = day;
      final SleepSummary? sleep = day.sleep;
      if (sleep == null) return;
      sleepHours = double.parse(sleep.asleepHours.toStringAsFixed(1));
      deepSleepMinutes = sleep.deepMinutes ?? 0;
      remSleepMinutes = sleep.remMinutes ?? 0;
      awakeMinutes = sleep.awakeMinutes ?? 0;
    });
  }

  void _showHealthMessage(HealthSyncOutcome outcome) {
    final String? actionLabel = HealthTexts.actionLabel(outcome);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(HealthTexts.message(outcome)),
          backgroundColor: const Color(0xFF4A3B32),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: actionLabel == null ? 3 : 6),
          action: actionLabel == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  textColor: const Color(0xFFC89B7B),
                  onPressed: () => _resolveHealthOutcome(outcome),
                ),
        ),
      );
  }

  void _resolveHealthOutcome(HealthSyncOutcome outcome) {
    if (outcome == HealthSyncOutcome.notInstalled ||
        outcome == HealthSyncOutcome.needsUpdate) {
      HealthSyncService.installHealthConnect();
    } else {
      HealthSyncService.openPermissionSettings();
    }
  }

  String _bedtimeText(String fallback) {
    final DateTime? at = _healthDay?.sleep?.bedtime;
    return at == null ? fallback : HealthTexts.clock(at);
  }

  String _wakeTimeText(String fallback) {
    final DateTime? at = _healthDay?.sleep?.wakeTime;
    return at == null ? fallback : HealthTexts.clock(at);
  }

  double _calculatePerfectSleepScore(
    double hours,
    int deepMin,
    int remMin,
    int awakeMin,
    String customInf,
  ) {
    double durationScore = 40.0;
    if (hours < 7.5) {
      durationScore = (hours / 7.5) * 40.0;
    } else if (hours > 8.5) {
      durationScore = 40.0 - ((hours - 8.5) * 8.0);
    }
    if (durationScore < 0) durationScore = 0;

    double deepScore = (deepMin / 120.0) * 25.0;
    if (deepScore > 25.0) deepScore = 25.0;

    double remScore = (remMin / 100.0) * 20.0;
    if (remScore > 20.0) remScore = 20.0;

    double awakeScore = 15.0 - (awakeMin / 2.0);
    if (awakeScore < 0) awakeScore = 0;
    if (awakeScore > 15.0) awakeScore = 15.0;

    double totalScore = durationScore + deepScore + remScore + awakeScore;

    if (lateScreenTime) totalScore -= 3.0;
    if (heavyMeal) totalScore -= 4.0;
    if (lateCaffeine) totalScore -= 4.0;
    if (lateWorkout) totalScore -= 2.0;
    if (alcohol) totalScore -= 6.0;
    if (highStress) totalScore -= 5.0;
    if (racingThoughts) totalScore -= 4.0;
    if (customInf.trim().isNotEmpty) totalScore -= 3.0;

    if (totalScore > 100.0) return 100.0;
    if (totalScore < 0.0) return 0.0;
    return totalScore;
  }

  String _getQualityText(double score) {
    if (score <= 0) return 'Keine Aufzeichnung';
    if (score >= 90) return 'Hervorragend & Tief';
    if (score >= 80) return 'Gute Schlafqualität';
    if (score >= 70) return 'Solide & Ausreichend';
    return 'Eingeschränkt / Mangelhaft';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _customInfluenceNotifier,
      builder: (context, customInfVal, child) {
        double calculatedScore = _calculatePerfectSleepScore(
          sleepHours,
          deepSleepMinutes,
          remSleepMinutes,
          awakeMinutes,
          customInfVal,
        );

        // Aktualisiere exklusiv den heutigen Tag (Index 4)
        _weeklyData[4]['score'] = calculatedScore;
        _weeklyData[4]['hours'] = sleepHours;
        _weeklyData[4]['deep'] = deepSleepMinutes;
        _weeklyData[4]['rem'] = remSleepMinutes;
        _weeklyData[4]['awake'] = awakeMinutes;
        _weeklyData[4]['quality'] = _getQualityText(calculatedScore);

        List<String> currentInfluences = [];
        if (lateScreenTime) currentInfluences.add('Späte Bildschirmzeit');
        if (heavyMeal) currentInfluences.add('Schweres Essen');
        if (lateCaffeine) currentInfluences.add('Spätes Koffein');
        if (lateWorkout) currentInfluences.add('Spätes Workout');
        if (alcohol) currentInfluences.add('Alkoholgenuss');
        if (highStress) currentInfluences.add('Hohes Stresslevel');
        if (racingThoughts) currentInfluences.add('Gedankenkreisen');
        if (customInfVal.trim().isNotEmpty) {
          currentInfluences.add(customInfVal.trim());
        }
        _weeklyData[4]['influences'] = currentInfluences;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F0EB),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFF4A3B32),
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Lutalia',
                  style: TextStyle(
                    color: Color(0xFF4A3B32),
                    fontSize: 26,
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF4A3B32),
                  size: 26,
                ),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: const [
                      Text(
                        'Schlaftracking &\nRegeneration',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF4A3B32),
                          fontSize: 30,
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE3DD),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFD6CBC1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Flexible(
                          child: Text(
                            'TIEFE & INNERE BALANCE',
                            style: TextStyle(
                              color: Color(0xFF4A3B32),
                              fontSize: 13,
                              fontFamily: 'Cinzel',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE3DD),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFD6CBC1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.analytics_outlined,
                            color: Color(0xFFC89B7B),
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'SCHLAFANALYSE (HEUTE)',
                              style: TextStyle(
                                color: Color(0xFF4A3B32),
                                fontSize: 16,
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildHealthSyncButton(),
                      _buildHealthSyncStatus(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'SCHLAFDAUER (GESAMT):',
                              style: TextStyle(
                                color: Color(0xFF4A3B32),
                                fontSize: 13,
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${sleepHours.toStringAsFixed(1)} STD.',
                            style: const TextStyle(
                              color: Color(0xFFC89B7B),
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cinzel',
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        // Synced nights can fall outside the manual range;
                        // the label and score keep the real value.
                        value: sleepHours.clamp(3.0, 12.0),
                        min: 3.0,
                        max: 12.0,
                        divisions: 18,
                        activeColor: const Color(0xFFC89B7B),
                        inactiveColor: const Color(0xFFD6CBC1),
                        onChanged: (val) {
                          setState(() {
                            sleepHours = val;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 130,
                                height: 130,
                                child: CircularProgressIndicator(
                                  value: calculatedScore / 100,
                                  backgroundColor: const Color(0xFFD6CBC1),
                                  color: const Color(0xFFC89B7B),
                                  strokeWidth: 9,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    calculatedScore.toStringAsFixed(0),
                                    style: const TextStyle(
                                      color: Color(0xFF4A3B32),
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cinzel',
                                    ),
                                  ),
                                  const Text(
                                    'SCHLAF-SCORE',
                                    style: TextStyle(
                                      color: Color(0xFF8C7A70),
                                      fontSize: 10,
                                      fontFamily: 'Cinzel',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A3B32),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _getQualityText(calculatedScore),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Cinzel',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 38, color: Color(0xFFD6CBC1)),
                      _buildPhaseDetailRow(
                        'Tiefschlaf (ca.)',
                        '${deepSleepMinutes ~/ 60} Std ${deepSleepMinutes % 60} Min',
                        const Color(0xFF4A3B32),
                      ),
                      const SizedBox(height: 12),
                      _buildPhaseDetailRow(
                        'REM-Schlaf (ca.)',
                        '${remSleepMinutes ~/ 60} Std ${remSleepMinutes % 60} Min',
                        const Color(0xFF8C7A70),
                      ),
                      const SizedBox(height: 12),
                      _buildPhaseDetailRow(
                        'Wachphase',
                        '$awakeMinutes Min',
                        const Color(0xFFD4A373),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE3DD),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD6CBC1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.bedtime_outlined,
                            color: Color(0xFFC89B7B),
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'EINFLÜSSE VOR DER NACHTRUHE',
                              style: TextStyle(
                                color: Color(0xFF4A3B32),
                                fontSize: 16,
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Wähle alle zutreffenden Faktoren aus:',
                        style: TextStyle(
                          color: Color(0xFF6B5B52),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildCheckboxTile(
                        'Späte Bildschirmzeit (Handy / TV)',
                        lateScreenTime,
                        (val) => setState(() => lateScreenTime = val ?? false),
                      ),
                      _buildCheckboxTile(
                        'Schweres Essen kurz vor dem Schlafen',
                        heavyMeal,
                        (val) => setState(() => heavyMeal = val ?? false),
                      ),
                      _buildCheckboxTile(
                        'Koffein am späten Nachmittag / Abend',
                        lateCaffeine,
                        (val) => setState(() => lateCaffeine = val ?? false),
                      ),
                      _buildCheckboxTile(
                        'Spätes Workout / körperliche Aktivität',
                        lateWorkout,
                        (val) => setState(() => lateWorkout = val ?? false),
                      ),
                      _buildCheckboxTile(
                        'Alkoholgenuss am Abend',
                        alcohol,
                        (val) => setState(() => alcohol = val ?? false),
                      ),
                      _buildCheckboxTile(
                        'Hohes Stresslevel / Termindruck',
                        highStress,
                        (val) => setState(() => highStress = val ?? false),
                      ),
                      _buildCheckboxTile(
                        'Gedankenkreisen / Innere Unruhe',
                        racingThoughts,
                        (val) => setState(() => racingThoughts = val ?? false),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _customInfluenceController,
                        style: const TextStyle(
                          color: Color(0xFF4A3B32),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              'Sonstiges (z. B. spätes Meeting, Lärm)...',
                          labelStyle: const TextStyle(
                            color: Color(0xFF8C7A70),
                            fontSize: 12,
                            fontFamily: 'Cinzel',
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F0EB),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFD6CBC1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFC89B7B),
                              width: 1.5,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Color(0xFF8C7A70),
                              size: 18,
                            ),
                            onPressed: () {
                              _customInfluenceController.clear();
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE3DD),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD6CBC1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.timeline,
                            color: Color(0xFFC89B7B),
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'SCHLAF-TIMELINE',
                              style: TextStyle(
                                color: Color(0xFF4A3B32),
                                fontSize: 16,
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Grafischer Verlauf der Nachtphasen (23:15 – 06:45 Uhr)',
                        style: TextStyle(
                          color: Color(0xFF6B5B52),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F0EB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD6CBC1)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD4A373),
                                  borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(11),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Wach',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Container(
                                color: const Color(0xFF8C7A70),
                                child: const Center(
                                  child: Text(
                                    'REM',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 8,
                              child: Container(
                                color: const Color(0xFF4A3B32),
                                child: const Center(
                                  child: Text(
                                    'Tiefschlaf',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Container(
                                color: const Color(0xFF8C7A70),
                                child: const Center(
                                  child: Text(
                                    'REM',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD4A373),
                                  borderRadius: BorderRadius.horizontal(
                                    right: Radius.circular(11),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Wach',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            '23:15',
                            style: TextStyle(
                              color: Color(0xFF8C7A70),
                              fontSize: 11,
                              fontFamily: 'Cinzel',
                            ),
                          ),
                          Text(
                            '02:00',
                            style: TextStyle(
                              color: Color(0xFF8C7A70),
                              fontSize: 11,
                              fontFamily: 'Cinzel',
                            ),
                          ),
                          Text(
                            '04:30',
                            style: TextStyle(
                              color: Color(0xFF8C7A70),
                              fontSize: 11,
                              fontFamily: 'Cinzel',
                            ),
                          ),
                          Text(
                            '06:45',
                            style: TextStyle(
                              color: Color(0xFF8C7A70),
                              fontSize: 11,
                              fontFamily: 'Cinzel',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A3B32),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => _showDetailedSleepModal(context),
                          child: const Text(
                            'UHR-DETAILANSICHT ÖFFNEN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontFamily: 'Cinzel',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE3DD),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD6CBC1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.insights,
                                color: Color(0xFFC89B7B),
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'SCORE-ZEITSTRAHL',
                                style: TextStyle(
                                  color: Color(0xFF4A3B32),
                                  fontSize: 16,
                                  fontFamily: 'Cinzel',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Tippe auf Tag',
                            style: TextStyle(
                              color: Color(0xFF8C7A70),
                              fontSize: 11,
                              fontFamily: 'Cinzel',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Verlauf & Prognose auf der durchgehenden Zeitachse',
                        style: TextStyle(
                          color: Color(0xFF6B5B52),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_weeklyData.length, (index) {
                            final dayData = _weeklyData[index];
                            bool isSelected = _selectedDayIndex == index;
                            double sval = dayData['score'];

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDayIndex = index;
                                });
                                _showDayDetailModal(context, dayData);
                              },
                              child: Container(
                                width: 52,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      sval > 0 ? sval.toStringAsFixed(0) : '0',
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF4A3B32)
                                            : const Color(0xFF8C7A70),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 60,
                                      child: Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          Container(
                                            width: 5,
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFD6CBC1,
                                              ).withValues(alpha: 0.4),
                                              borderRadius:
                                                  BorderRadius.circular(2.5),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            heightFactor: sval > 0
                                                ? sval / 100.0
                                                : 0.0,
                                            child: Container(
                                              width: 5,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? const Color(0xFF4A3B32)
                                                    : const Color(0xFFC89B7B),
                                                borderRadius:
                                                    BorderRadius.circular(2.5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          height: 2,
                                          width: 52,
                                          color: const Color(0xFFD6CBC1),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF4A3B32)
                                                : const Color(0xFFF5F0EB),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF4A3B32)
                                                  : const Color(0xFFD6CBC1),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                dayData['day'],
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : const Color(0xFF4A3B32),
                                                  fontSize: 10,
                                                  fontFamily: 'Cinzel',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                dayData['date'],
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white70
                                                      : const Color(0xFF6B5B52),
                                                  fontSize: 8,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Regenerations-Tipps',
                  style: TextStyle(
                    color: Color(0xFF4A3B32),
                    fontSize: 18,
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 135,
                  child: PageView(
                    controller: _tipsController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentTipPage = index;
                      });
                    },
                    children: [
                      _buildTipCard(
                        'Bildschirmzeit reduzieren',
                        'Vermeide helle Displays eine Stunde vor der Nachtruhe, um die Melatoninausschüttung optimal zu unterstützen.',
                      ),
                      _buildTipCard(
                        'Optimale Raumtemperatur',
                        'Ein kühles Schlafzimmer zwischen 16 und 18 Grad begünstigt einen tiefen und erholsamen Schlaf.',
                      ),
                      _buildTipCard(
                        'Feste Schlafzeiten',
                        'Ein gleichbleibender Rhythmus stärkt deine innere biologische Uhr und verbessert die Schlafarchitektur nachhaltig.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentTipPage == index ? 12 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentTipPage == index
                            ? const Color(0xFFC89B7B)
                            : const Color(0xFFD6CBC1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHealthSyncButton() {
    return Material(
      color: const Color(0xFFF5F0EB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isSyncing ? null : _syncHealth,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD6CBC1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF4A3B32),
                      ),
                    )
                  : const Icon(Icons.sync, color: Color(0xFF4A3B32), size: 18),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _isSyncing ? HealthTexts.syncing : HealthTexts.syncButton,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4A3B32),
                    fontSize: 11,
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthSyncStatus() {
    final HealthDaySummary? day = _healthDay;
    if (day == null) return const SizedBox.shrink();
    final SleepSummary? sleep = day.sleep;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            HealthTexts.lastSynced(day.syncedAt),
            style: const TextStyle(color: Color(0xFF8C7A70), fontSize: 11),
          ),
          if (sleep == null) ...[
            const SizedBox(height: 4),
            Text(
              HealthTexts.noSleepLastNight,
              style: const TextStyle(color: Color(0xFF8C7A70), fontSize: 11),
            ),
          ],
          if (sleep != null && !sleep.hasStages) ...[
            const SizedBox(height: 4),
            const Text(
              HealthTexts.noStages,
              style: TextStyle(color: Color(0xFF8C7A70), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhaseDetailRow(String title, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF4A3B32),
                fontSize: 14,
                fontFamily: 'Cinzel',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF4A3B32),
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cinzel',
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    // Own transparent Material: the card's coloured Container would otherwise
    // hide the tile's ink and trigger a ListTile assertion.
    return Material(
      type: MaterialType.transparency,
      child: CheckboxListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF4A3B32),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFC89B7B),
        checkColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTipCard(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAE3DD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6CBC1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Regeneration',
                style: TextStyle(
                  color: Color(0xFF8C7A70),
                  fontSize: 10,
                  fontFamily: 'Cinzel',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4A3B32),
              fontSize: 14,
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF6B5B52),
              fontSize: 12,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showDayDetailModal(BuildContext context, Map<String, dynamic> dayData) {
    List<dynamic> infs = dayData['influences'] ?? [];
    double score = dayData['score'];
    String quality = dayData['quality'];
    bool hasData = score > 0;
    final bool isToday = identical(dayData, _weeklyData[4]);
    final String bedtime = isToday ? _bedtimeText('23:15 Uhr') : '23:15 Uhr';
    final String wakeTime = isToday ? _wakeTimeText('06:45 Uhr') : '06:45 Uhr';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F0EB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(26),
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6CBC1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'TAGES-DETAILS: ${dayData['date']}.2026',
                        style: const TextStyle(
                          color: Color(0xFF4A3B32),
                          fontSize: 16,
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC89B7B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Score: ${hasData ? score.toStringAsFixed(0) : '0'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cinzel',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Vollständige Aufzeichnung und Einflussfaktoren',
                style: TextStyle(
                  color: Color(0xFF6B5B52),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAE3DD),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD6CBC1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_outline,
                            color: Color(0xFFC89B7B),
                            size: 24,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Einschätzung',
                                  style: TextStyle(
                                    color: Color(0xFF8C7A70),
                                    fontSize: 11,
                                    fontFamily: 'Cinzel',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  quality,
                                  style: const TextStyle(
                                    color: Color(0xFF4A3B32),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cinzel',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildModalDetailTile(
                      Icons.bedtime_outlined,
                      'Einschlafzeit',
                      hasData ? bedtime : HealthTexts.noData,
                    ),
                    const SizedBox(height: 12),
                    _buildModalDetailTile(
                      Icons.wb_sunny_outlined,
                      'Aufwachzeit',
                      hasData ? wakeTime : HealthTexts.noData,
                    ),
                    const SizedBox(height: 12),
                    _buildModalDetailTile(
                      Icons.hourglass_bottom,
                      'Schlafdauer Gesamt',
                      hasData ? '${dayData['hours']} Stunden' : '0 Stunden',
                    ),
                    const SizedBox(height: 12),
                    _buildModalDetailTile(
                      Icons.nightlight,
                      'Tiefschlaf',
                      hasData ? '${dayData['deep']} Minuten' : '0 Minuten',
                    ),
                    const SizedBox(height: 12),
                    _buildModalDetailTile(
                      Icons.waves,
                      'REM-Schlaf',
                      hasData ? '${dayData['rem']} Minuten' : '0 Minuten',
                    ),
                    const SizedBox(height: 12),
                    _buildModalDetailTile(
                      Icons.remove_red_eye_outlined,
                      'Wachphase',
                      hasData ? '${dayData['awake']} Minuten' : '0 Minuten',
                    ),
                    const SizedBox(height: 12),
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: _buildModalDetailTile(
                        Icons.favorite,
                        'Herzfrequenz im Schlaf',
                        hasData ? 'Ø58 bpm (Stabil & Optimal)' : '0 bpm',
                        iconColor: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAE3DD),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD6CBC1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFC89B7B),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Faktoren vor der Nachtruhe:',
                                style: TextStyle(
                                  color: Color(0xFF4A3B32),
                                  fontSize: 13,
                                  fontFamily: 'Cinzel',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          !hasData
                              ? const Text(
                                  'An diesem Tag wurden keine Daten oder Einflüsse erfasst.',
                                  style: TextStyle(
                                    color: Color(0xFF6B5B52),
                                    fontSize: 13,
                                  ),
                                )
                              : infs.isEmpty
                              ? const Text(
                                  'Keine negativen Einflüsse dokumentiert. Hervorragende Voraussetzungen!',
                                  style: TextStyle(
                                    color: Color(0xFF6B5B52),
                                    fontSize: 13,
                                  ),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: infs
                                      .map(
                                        (inf) => Chip(
                                          label: Text(
                                            inf,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF4A3B32),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          backgroundColor: const Color(
                                            0xFFF5F0EB,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFD6CBC1),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A3B32),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'SCHLIESSEN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Cinzel',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
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

  void _showDetailedSleepModal(BuildContext context) {
    bool hasNegativeInfluences =
        heavyMeal ||
        alcohol ||
        lateCaffeine ||
        highStress ||
        _customInfluenceController.text.isNotEmpty;
    String hrStatusText = hasNegativeInfluences
        ? 'Außergewöhnlich erhöht (Ø68 bpm)'
        : 'Normal & Stabil (Ø58 bpm)';
    String hrExplanation = hasNegativeInfluences
        ? 'Deine Herzfrequenz lag heute Nacht im Schnitt über deinem normalen Ruhepuls. Das lässt sich auf spätere Einflüsse vor der Nachtruhe zurückführen.'
        : 'Deine Herzfrequenz befand sich während der gesamten Schlafdauer im optimalen, tiefen Erholungsbereich ohne nennenswerte Ausschläge.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F0EB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(26),
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6CBC1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Expanded(
                    child: Text(
                      'UHR-MESSDATEN & DETAILS',
                      style: TextStyle(
                        color: Color(0xFF4A3B32),
                        fontSize: 18,
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Präzise Aufzeichnung deiner Smartwatch / Fitness-App',
                style: TextStyle(
                  color: Color(0xFF6B5B52),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildModalDetailTile(
                      Icons.bedtime_outlined,
                      'Einschlafzeit',
                      _bedtimeText('23:15 Uhr'),
                    ),
                    const SizedBox(height: 12),
                    _buildModalDetailTile(
                      Icons.wb_sunny_outlined,
                      'Aufwachzeit',
                      _wakeTimeText('06:45 Uhr'),
                    ),
                    const SizedBox(height: 12),
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: _buildModalDetailTile(
                        Icons.favorite,
                        'Herzfrequenz im Schlaf',
                        hrStatusText,
                        iconColor: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAE3DD),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD6CBC1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analyse der Herzfrequenz:',
                            style: TextStyle(
                              color: Color(0xFF4A3B32),
                              fontSize: 13,
                              fontFamily: 'Cinzel',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hrExplanation,
                            style: const TextStyle(
                              color: Color(0xFF6B5B52),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A3B32),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'SCHLIESSEN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Cinzel',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
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

  Widget _buildModalDetailTile(
    IconData icon,
    String label,
    String value, {
    Color iconColor = const Color(0xFFC89B7B),
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAE3DD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6CBC1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8C7A70),
                    fontSize: 11,
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF4A3B32),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
