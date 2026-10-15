import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/health_day_summary.dart';
import '../services/health/health_sync_service.dart';
import '../services/health/health_texts.dart';
import 'xp_challenge_screen.dart';

class SchlafTrackingScreen extends StatefulWidget {
  const SchlafTrackingScreen({super.key});

  @override
  State<SchlafTrackingScreen> createState() => _SchlafTrackingScreenState();
}

class _SchlafTrackingScreenState extends State<SchlafTrackingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  double sleepHours = 7.3;
  int deepSleepMinutes = 110;
  int remSleepMinutes = 95;
  int awakeMinutes = 12;
  DateTime? bedtime;
  DateTime? wakeTime;

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
  
  final List<String> _confirmedCustomInfluences = [];

  late final PageController _tipsController;
  int _currentTipPage = 0;

  late final PageController _phaseInfoController;
  int _currentPhaseInfoPage = 0;

  static const int _pastNights = 14;
  static const int _futureDays = 2;
  static const int _todayIndex = _pastNights;
  static const List<String> _weekdayShort = [
    'Mo',
    'Di',
    'Mi',
    'Do',
    'Fr',
    'Sa',
    'So',
  ];

  int _selectedDayIndex = _todayIndex;
  late final ScrollController _timelineScrollController;

  late List<Map<String, dynamic>> _weeklyData = _buildWeek(DateTime.now());

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _timelinePulseController;
  late Animation<double> _timelinePulseAnimation;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _deerBreathController;
  late Animation<double> _deerScaleAnimation;

  late AnimationController _sparkleController;
  late AnimationController _heartsController;

  bool _isSyncing = false;
  HealthDaySummary? _healthDay;
  Future<void>? _refreshing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHealthOnOpen();
    _tipsController = PageController();
    _phaseInfoController = PageController();
    
    _timelineScrollController = ScrollController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _timelinePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _timelinePulseAnimation = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _timelinePulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    _deerBreathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _deerScaleAnimation = Tween<double>(begin: 0.98, end: 1.03).animate(
      CurvedAnimation(parent: _deerBreathController, curve: Curves.easeInOut),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _heartsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _customInfluenceController.addListener(() {
      _customInfluenceNotifier.value = _customInfluenceController.text;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDay(_todayIndex, animated: false);
      _loadDayFromFirestore(_weeklyData[_todayIndex]['dateTime']);
    });
  }

  String _formatHoursToHoursAndMinutes(double hours) {
    if (hours <= 0) return '0 Min';
    int totalMinutes = (hours * 60).round();
    int h = totalMinutes ~/ 60;
    int m = totalMinutes % 60;
    if (h == 0) return '$m Min';
    if (m == 0) return '$h Std';
    return '$h Std $m Min';
  }

  void _scrollToSelectedDay(int index, {bool animated = true}) {
    if (!_timelineScrollController.hasClients) return;
    double targetOffset = (index * 104.0) - (MediaQuery.of(context).size.width / 2) + 52.0;
    targetOffset = targetOffset.clamp(0.0, _timelineScrollController.position.maxScrollExtent);
    if (animated) {
      _timelineScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _timelineScrollController.jumpTo(targetOffset);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _timelinePulseController.dispose();
    _fadeController.dispose();
    _deerBreathController.dispose();
    _sparkleController.dispose();
    _heartsController.dispose();
    _tipsController.dispose();
    _phaseInfoController.dispose();
    _timelineScrollController.dispose();
    _customInfluenceController.dispose();
    _customInfluenceNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshHealthSilently();
  }

  Future<void> _loadHealthOnOpen() async {
    final HealthDaySummary? cached = await HealthSyncService.cachedDay(
      DateTime.now(),
    );
    if (!mounted) return;
    _applyHealthDay(cached);
    await _refreshHealthSilently();
  }

  Future<void> _refreshHealthSilently() =>
      _refreshing ??= _refreshHealth().whenComplete(() => _refreshing = null);

  Future<void> _refreshHealth() async {
    final DateTime now = DateTime.now();
    final DateTime shownToday = _weeklyData[_todayIndex]['dateTime'];
    if (shownToday.day != now.day ||
        shownToday.month != now.month ||
        shownToday.year != now.year) {
      setState(() {
        _weeklyData = _buildWeek(now);
        _selectedDayIndex = _todayIndex;
      });
    }
    final HealthDaySummary? fresh = await HealthSyncService.refreshToday();
    if (!mounted) return;
    _applyHealthDay(fresh);
    await _loadSleepHistory();
  }

  Future<void> _loadSleepHistory() async {
    final List<({DateTime day, SleepSummary? sleep})> nights =
        await HealthSyncService.loadSleepHistory(_pastNights);
    if (!mounted) return;
    setState(() {
      for (final night in nights) {
        final int index = _indexOfDay(night.day);
        if (index >= 0 && index < _todayIndex) {
          _fillPastNight(_weeklyData[index], night.sleep);
        }
      }
    });
  }

  Future<void> _syncHealth() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final HealthSyncResult result = await HealthSyncService.connect();
    if (!mounted) return;
    setState(() => _isSyncing = false);
    _applyHealthDay(result.today);
    _showHealthMessage(result.outcome);
    if (result.isSuccess) {
      await _loadSleepHistory();
      await _saveDayToFirestore(_weeklyData[_selectedDayIndex]);
    }
  }

  List<Map<String, dynamic>> _buildWeek(DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    return List<Map<String, dynamic>>.generate(_pastNights + 1 + _futureDays, (
      int i,
    ) {
      final DateTime day = DateTime(
        today.year,
        today.month,
        today.day + i - _todayIndex,
      );
      return <String, dynamic>{
        'dateTime': day,
        'date':
            '${day.day.toString().padLeft(2, '0')}.'
            '${day.month.toString().padLeft(2, '0')}',
        'day': _weekdayShort[day.weekday - 1],
        'score': 0.0,
        'points': 0,
        'hours': 0.0,
        'deep': 0,
        'rem': 0,
        'awake': 0,
        'quality': i > _todayIndex ? 'Ausstehend' : 'Keine Aufzeichnung',
        'influences': <String>[],
        'sleep': null,
      };
    });
  }

  int _indexOfDay(DateTime day) => _weeklyData.indexWhere((entry) {
    final DateTime d = entry['dateTime'];
    return d.year == day.year && d.month == day.month && d.day == day.day;
  });

  void _fillPastNight(Map<String, dynamic> entry, SleepSummary? sleep) {
    if (sleep == null) return;
    final double hours = double.parse(sleep.asleepHours.toStringAsFixed(1));
    final int deep = sleep.deepMinutes ?? 0;
    final int rem = sleep.remMinutes ?? 0;
    final int awake = sleep.awakeMinutes ?? 0;
    final double rawScore = _sleepScore(hours, deep, rem, awake);
    final double score = rawScore > 0 ? (rawScore - 0).clamp(0, 98) : 0;
    final int points = _calculateGamificationPoints(score, []);
    entry
      ..['sleep'] = sleep
      ..['hours'] = hours
      ..['deep'] = deep
      ..['rem'] = rem
      ..['awake'] = awake
      ..['score'] = score
      ..['points'] = points
      ..['quality'] = _getQualityText(score);
    _saveDayToFirestore(entry);
  }

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
      bedtime = sleep.bedtime;
      wakeTime = sleep.wakeTime;
    });
  }

  Future<void> _saveDayToFirestore(Map<String, dynamic> dayData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final DateTime dt = dayData['dateTime'];
    final String dateKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sleep_days')
          .doc(dateKey)
          .set({
        'date': dateKey,
        'score': dayData['score'],
        'points': dayData['points'],
        'hours': dayData['hours'],
        'deep': dayData['deep'],
        'rem': dayData['rem'],
        'awake': dayData['awake'],
        'quality': dayData['quality'],
        'influences': dayData['influences'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _loadDayFromFirestore(DateTime dt) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final String dateKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sleep_days')
          .doc(dateKey)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            final idx = _indexOfDay(dt);
            if (idx != -1) {
              _weeklyData[idx]['score'] = (data['score'] ?? 0.0).toDouble();
              _weeklyData[idx]['points'] = data['points'] ?? 0;
              _weeklyData[idx]['hours'] = (data['hours'] ?? 0.0).toDouble();
              _weeklyData[idx]['deep'] = data['deep'] ?? 0;
              _weeklyData[idx]['rem'] = data['rem'] ?? 0;
              _weeklyData[idx]['awake'] = data['awake'] ?? 0;
              _weeklyData[idx]['quality'] = data['quality'] ?? 'Keine Aufzeichnung';
              _weeklyData[idx]['influences'] = List<String>.from(data['influences'] ?? []);
            }
            if (idx == _todayIndex) {
              sleepHours = (data['hours'] ?? sleepHours).toDouble();
              deepSleepMinutes = data['deep'] ?? deepSleepMinutes;
              remSleepMinutes = data['rem'] ?? remSleepMinutes;
              awakeMinutes = data['awake'] ?? awakeMinutes;
            }
          });
        }
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _generateRealTimelinePhases() {
    List<Map<String, dynamic>> phases = [];

    if (deepSleepMinutes > 0) {
      phases.add({
        'type': 'deep',
        'label': 'Tiefschlaf',
        'minutes': deepSleepMinutes,
        'durationText': '${deepSleepMinutes ~/ 60} Std ${deepSleepMinutes % 60} Min',
      });
    }

    if (remSleepMinutes > 0) {
      phases.add({
        'type': 'rem',
        'label': 'REM-Schlaf',
        'minutes': remSleepMinutes,
        'durationText': '${remSleepMinutes ~/ 60} Std ${remSleepMinutes % 60} Min',
      });
    }

    if (awakeMinutes > 0) {
      phases.add({
        'type': 'awake',
        'label': 'Wachphase',
        'minutes': awakeMinutes,
        'durationText': '$awakeMinutes Min',
      });
    }

    if (phases.isEmpty) {
      phases.add({
        'type': 'deep',
        'label': 'Schlafphase',
        'minutes': 60,
        'durationText': 'Keine Daten',
      });
    }

    return phases;
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
    final DateTime? at = bedtime;
    return at == null ? fallback : HealthTexts.clock(at);
  }

  String _wakeTimeText(String fallback) {
    final DateTime? at = wakeTime;
    return at == null ? fallback : HealthTexts.clock(at);
  }

  String _clockOrNoData(DateTime? at) =>
      at == null ? HealthTexts.noData : HealthTexts.clock(at);

  double _sleepScore(double hours, int deepMin, int remMin, int awakeMin) {
    double durationScore = 35.0;
    if (hours < 7.5) {
      durationScore = 35.0 - ((7.5 - hours) * 6.0);
    } else if (hours > 8.5) {
      durationScore = 35.0 - ((hours - 8.5) * 6.0);
    }
    if (durationScore < 0) durationScore = 0;

    double deepScore = (deepMin / 90.0) * 25.0;
    if (deepScore > 25.0) deepScore = 25.0;

    double remScore = (remMin / 90.0) * 20.0;
    if (remScore > 20.0) remScore = 20.0;

    double awakeScore = 18.0 - (awakeMin / 2.0);
    if (awakeScore < 0) awakeScore = 0;
    if (awakeScore > 18.0) awakeScore = 18.0;

    double finalScore = durationScore + deepScore + remScore + awakeScore;
    return finalScore > 98.0 ? 98.0 : finalScore;
  }

  int _calculateGamificationPoints(double baseScore, List<String> influences) {
    double points = (baseScore / 98.0) * 85.0;
    int penaltyCount = influences.length;
    double bonusOrPenalty = 15.0 - (penaltyCount * 2.5);
    if (bonusOrPenalty < 0) bonusOrPenalty = 0;

    points += bonusOrPenalty;
    if (points > 100.0) return 100;
    if (points < 0.0) return 0;
    return points.round();
  }

  String _getQualityText(double score) {
    if (score <= 0) return 'Keine Aufzeichnung';
    if (score >= 85) return '✨ Hervorragend & Tief';
    if (score >= 72) return '🌙 Gute Schlafqualität';
    if (score >= 55) return 'Solide & Ausreichend';
    return 'Eingeschränkt / Mangelhaft';
  }

  void _showMagicDeerMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFF7F2EC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
            side: const BorderSide(color: Color(0xFFC89B7B), width: 2.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 42.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFFC89B7B), size: 36),
                    SizedBox(width: 14),
                    Icon(Icons.favorite, color: Color(0xFFC89B7B), size: 36),
                    SizedBox(width: 14),
                    Icon(Icons.auto_awesome, color: Color(0xFFC89B7B), size: 36),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'Du bist städtischer als du selbst glaubst.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF4A3B32),
                    fontSize: 28,
                    fontFamily: 'NewFirst',
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Du bist wundervoll.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFC89B7B),
                    fontSize: 22,
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A3B32),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Schließen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDateFromCalendar() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFC89B7B),
              onPrimary: Colors.white,
              surface: Color(0xFFF7F2EC),
              onSurface: Color(0xFF4A3B32),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      int foundIndex = _indexOfDay(picked);
      if (foundIndex != -1) {
        setState(() {
          _selectedDayIndex = foundIndex;
        });
        _scrollToSelectedDay(foundIndex);
        await _loadDayFromFirestore(picked);
        if (mounted) _showDayDetailModal(context, _weeklyData[foundIndex]);
      } else {
        Map<String, dynamic> customDay = {
          'dateTime': picked,
          'date': '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}',
          'day': _weekdayShort[picked.weekday - 1],
          'score': 0.0,
          'points': 0,
          'hours': 0.0,
          'deep': 0,
          'rem': 0,
          'awake': 0,
          'quality': 'Keine Aufzeichnung',
          'influences': <String>[],
          'sleep': null,
        };
        setState(() {
          _weeklyData.add(customDay);
          _weeklyData.sort((a, b) => (a['dateTime'] as DateTime).compareTo(b['dateTime']));
          _selectedDayIndex = _indexOfDay(picked);
        });
        _scrollToSelectedDay(_selectedDayIndex);
        await _loadDayFromFirestore(picked);
        if (mounted) _showDayDetailModal(context, _weeklyData[_selectedDayIndex]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _customInfluenceNotifier,
      builder: (context, customInfVal, child) {
        List<String> currentInfluences = [];
        if (lateScreenTime) currentInfluences.add('Späte Bildschirmzeit');
        if (heavyMeal) currentInfluences.add('Schweres Essen');
        if (lateCaffeine) currentInfluences.add('Spätes Koffein');
        if (lateWorkout) currentInfluences.add('Spätes Workout');
        if (alcohol) currentInfluences.add('Alkoholgenuss');
        if (highStress) currentInfluences.add('Hohes Stresslevel');
        if (racingThoughts) currentInfluences.add('Gedankenkreisen');
        
        for (final custom in _confirmedCustomInfluences) {
          if (custom.trim().isNotEmpty) {
            currentInfluences.add(custom.trim());
          }
        }

        double rawScore = _sleepScore(
          sleepHours,
          deepSleepMinutes,
          remSleepMinutes,
          awakeMinutes,
        );

        double influenceDeduction = currentInfluences.length * 0.5;
        double calculatedScore = (rawScore - influenceDeduction).clamp(0.0, 98.0);

        int gamificationPoints = _calculateGamificationPoints(
          calculatedScore,
          currentInfluences,
        );

        _weeklyData[_selectedDayIndex]['score'] = calculatedScore;
        _weeklyData[_selectedDayIndex]['points'] = gamificationPoints;
        _weeklyData[_selectedDayIndex]['hours'] = sleepHours;
        _weeklyData[_selectedDayIndex]['deep'] = deepSleepMinutes;
        _weeklyData[_selectedDayIndex]['rem'] = remSleepMinutes;
        _weeklyData[_selectedDayIndex]['awake'] = awakeMinutes;
        _weeklyData[_selectedDayIndex]['quality'] = _getQualityText(calculatedScore);
        _weeklyData[_selectedDayIndex]['influences'] = currentInfluences;

        _saveDayToFirestore(_weeklyData[_selectedDayIndex]);

        final List<Map<String, dynamic>> realPhases = _generateRealTimelinePhases();

        return Scaffold(
          backgroundColor: const Color(0xFFF4EFEA),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFF4A3B32),
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Lutalia',
              style: TextStyle(
                color: Color(0xFF4A3B32),
                fontSize: 28,
                fontFamily: 'Cinzel',
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF4A3B32),
                  size: 28,
                ),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Schlaftracking &\nRegeneration',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4A3B32),
                      fontSize: 44,
                      fontFamily: 'NewFirst',
                      fontWeight: FontWeight.w300,
                      height: 1.25,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: GestureDetector(
                    onTap: () => _showScoreBreakdownModal(
                      context,
                      calculatedScore,
                      sleepHours,
                      deepSleepMinutes,
                      remSleepMinutes,
                      awakeMinutes,
                      currentInfluences,
                    ),
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: SizedBox(
                        width: 360,
                        height: 360,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(360, 360),
                              painter: _StarProgressPainter(
                                progress: calculatedScore / 98,
                                trackColor: const Color(0xFFE5DBD0),
                                activeColor: const Color(0xFFC89B7B),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  calculatedScore.toStringAsFixed(0),
                                  style: const TextStyle(
                                    color: Color(0xFF4A3B32),
                                    fontSize: 84,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Cinzel',
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'SCHLAF-SCORE',
                                  style: TextStyle(
                                    color: Color(0xFF8C7A70),
                                    fontSize: 14,
                                    fontFamily: 'Cinzel',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '(Details antippen ➔)',
                                  style: TextStyle(
                                    color: Color(0xFFC89B7B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Center(
                  child: Column(
                    children: [
                      Text(
                        _formatHoursToHoursAndMinutes(sleepHours),
                        style: const TextStyle(
                          color: Color(0xFF4A3B32),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cinzel',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'GESAMTSCHLAFDAUER (GETRACKT)',
                        style: TextStyle(
                          color: Color(0xFF8C7A70),
                          fontSize: 11,
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC89B7B),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC89B7B).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                _getQualityText(calculatedScore),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Cinzel',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _showMagicDeerMessage(context),
                          child: SizedBox(
                            height: 440,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ScaleTransition(
                                  scale: _deerScaleAnimation,
                                  child: Image.asset(
                                    'assets/sleeptracking/sleepdeer.png',
                                    height: 440,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.pets,
                                      size: 150,
                                      color: Color(0xFFC89B7B),
                                    ),
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _heartsController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      size: const Size(440, 440),
                                      painter: _ExhalingHeartsPainter(
                                        progress: _heartsController.value,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        
                        AnimatedBuilder(
                          animation: _sparkleController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _FairyDustPainter(progress: _sparkleController.value),
                              child: child,
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 1.2,
                                      color: const Color(0xFFC89B7B).withValues(alpha: 0.6),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 14.0),
                                      child: Icon(
                                        Icons.star,
                                        size: 18,
                                        color: Color(0xFFC89B7B),
                                      ),
                                    ),
                                    Container(
                                      width: 64,
                                      height: 1.2,
                                      color: const Color(0xFFC89B7B).withValues(alpha: 0.6),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 26),
                                const Text(
                                  'Wenn die Welt\nleiser wird,\nbeginnt die Seele\nzu atmen.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF4A3B32),
                                    fontSize: 42,
                                    fontFamily: 'NewFirst',
                                    fontWeight: FontWeight.w200,
                                    height: 1.25,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 26),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 1.2,
                                      color: const Color(0xFFC89B7B).withValues(alpha: 0.6),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 14.0),
                                      child: Icon(
                                        Icons.star,
                                        size: 18,
                                        color: Color(0xFFC89B7B),
                                      ),
                                    ),
                                    Container(
                                      width: 64,
                                      height: 1.2,
                                      color: const Color(0xFFC89B7B).withValues(alpha: 0.6),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F2EC),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFC89B7B), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A3B32).withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      '❤️ TIEFE & INNERE BALANCE',
                      style: TextStyle(
                        color: Color(0xFFC89B7B),
                        fontSize: 14,
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F2EC),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFFC89B7B),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A3B32).withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
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
                            size: 26,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'SCHLAFWERTE & PHASEN',
                              style: TextStyle(
                                color: Color(0xFF4A3B32),
                                fontSize: 18,
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildHealthSyncButton(),
                      _buildHealthSyncStatus(),
                      const Divider(height: 44, color: Color(0xFFD8CCBF)),
                      _buildPhaseDetailRow(
                        'Tiefschlaf (ca.)',
                        '${deepSleepMinutes ~/ 60} Std ${deepSleepMinutes % 60} Min',
                        const Color(0xFF4A3B32),
                      ),
                      const SizedBox(height: 14),
                      _buildPhaseDetailRow(
                        'REM-Schlaf (ca.)',
                        '${remSleepMinutes ~/ 60} Std ${remSleepMinutes % 60} Min',
                        const Color(0xFF8C7A70),
                      ),
                      const SizedBox(height: 14),
                      _buildPhaseDetailRow(
                        'Wachphase',
                        '$awakeMinutes Min',
                        const Color(0xFFC89B7B),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Schlafphasen im Detail (Nach links wischen ➔)',
                        style: TextStyle(
                          color: Color(0xFF8C7A70),
                          fontSize: 12,
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 130,
                        child: PageView(
                          controller: _phaseInfoController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPhaseInfoPage = index;
                            });
                          },
                          children: [
                            _buildPhaseInfoCard(
                              'Tiefschlaf-Phase',
                              'Wichtig für die körperliche Regeneration, Muskelreparatur und das Immunsystem. Hier erholt sich dein Körper am tiefsten.',
                            ),
                            _buildPhaseInfoCard(
                              'REM-Schlaf (Traumphase)',
                              'Unverzichtbar für das Gehirn, die emotionale Verarbeitung, das Gedächtnis und das Lernen. Augen bewegen sich schnell.',
                            ),
                            _buildPhaseInfoCard(
                              'Wachphase',
                              'Kurze natürliche Unterbrechungen in der Nacht. Zu viele Wachphasen stören jedoch den erholsamen Rhythmus.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPhaseInfoPage == index ? 12 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPhaseInfoPage == index
                                  ? const Color(0xFFC89B7B)
                                  : const Color(0xFFD8CCBF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const XpChallengeScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F2EC),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFC89B7B),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC89B7B).withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.emoji_events_outlined,
                              color: Color(0xFFC89B7B),
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Punkte-Challenge',
                                    style: TextStyle(
                                      color: Color(0xFF4A3B32),
                                      fontSize: 18,
                                      fontFamily: 'Cinzel',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '& XP Counting',
                                    style: TextStyle(
                                      color: Color(0xFFC89B7B),
                                      fontSize: 15,
                                      fontFamily: 'Cinzel',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC89B7B),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Öffnen ➔',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'XP (Experience Points) spiegeln deine gesammelten Erfahrungspunkte für Regeneration und Schlafqualität wider.',
                          style: TextStyle(
                            color: Color(0xFF6B5B52),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFE8E1),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFC89B7B),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Color(0xFFC89B7B),
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '$gamificationPoints / 100',
                                    style: const TextStyle(
                                      color: Color(0xFF4A3B32),
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cinzel',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'GESAMMELTE XP (DIESER TAG)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF8C7A70),
                                  fontSize: 11,
                                  fontFamily: 'Cinzel',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F2EC),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFC89B7B), width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A3B32).withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.bedtime_outlined,
                            color: Color(0xFFC89B7B),
                            size: 26,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'EINFLÜSSE VOR DER NACHTRUHE',
                              style: TextStyle(
                                color: Color(0xFF4A3B32),
                                fontSize: 18,
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Wähle alle zutreffenden Faktoren aus:',
                        style: TextStyle(
                          color: Color(0xFF6B5B52),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: _customInfluenceController,
                        style: const TextStyle(
                          color: Color(0xFF4A3B32),
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Sonstiges (z. B. spätes Meeting, Lärm)...',
                          labelStyle: const TextStyle(
                            color: Color(0xFF8C7A70),
                            fontSize: 13,
                            fontFamily: 'Cinzel',
                          ),
                          filled: true,
                          fillColor: const Color(0xFFEFE8E1),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFC89B7B),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFC89B7B),
                              width: 1.8,
                            ),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFFC89B7B),
                                  size: 24,
                                ),
                                tooltip: 'Eintrag hinzufügen',
                                onPressed: () {
                                  if (_customInfluenceController.text.trim().isNotEmpty) {
                                    setState(() {
                                      _confirmedCustomInfluences.add(_customInfluenceController.text.trim());
                                      _customInfluenceController.clear();
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Color(0xFF8C7A70),
                                  size: 20,
                                ),
                                onPressed: () {
                                  _customInfluenceController.clear();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_confirmedCustomInfluences.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Bestätigte eigene Einflüsse:',
                          style: TextStyle(
                            color: Color(0xFF8C7A70),
                            fontSize: 12,
                            fontFamily: 'Cinzel',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ..._confirmedCustomInfluences.asMap().entries.map((entry) {
                          int idx = entry.key;
                          String text = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFE8E1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFC89B7B)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check, color: Color(0xFFC89B7B), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      text,
                                      style: const TextStyle(
                                        color: Color(0xFF4A3B32),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _confirmedCustomInfluences.removeAt(idx);
                                      });
                                    },
                                    child: const Icon(Icons.close, color: Color(0xFF8C7A70), size: 18),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F2EC),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFC89B7B), width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A3B32).withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.timeline,
                              color: Color(0xFFC89B7B),
                              size: 26,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'SCHLAF-TIMELINE',
                                style: TextStyle(
                                  color: Color(0xFF4A3B32),
                                  fontSize: 18,
                                  fontFamily: 'Cinzel',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 26),
                        child: Text(
                          'Gesamtanteile der Schlafphasen im Überblick',
                          style: TextStyle(
                            color: Color(0xFF6B5B52),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        height: 95,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: realPhases.map((phase) {
                              Color segColor;
                              if (phase['type'] == 'deep') {
                                segColor = const Color(0xFF4A3B32);
                              } else if (phase['type'] == 'rem') {
                                segColor = const Color(0xFF8C7A70);
                              } else {
                                segColor = const Color(0xFFC89B7B);
                              }

                              final int mins = phase['minutes'] ?? 30;
                              double boxWidth = mins * 1.8 < 100 ? 100.0 : mins * 1.8;

                              return Container(
                                width: boxWidth,
                                decoration: BoxDecoration(
                                  color: segColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFF7F2EC), width: 2),
                                ),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Text(
                                      '${phase['label']}\n${phase['durationText']}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFE8E1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFC89B7B), width: 1.2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PHASEN-HIGHLIGHTS DER NACHT',
                                    style: TextStyle(
                                      color: Color(0xFF4A3B32),
                                      fontSize: 14,
                                      fontFamily: 'Cinzel',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _buildStructuredHighlightRow(
                                    const Color(0xFF4A3B32), 
                                    'Tiefschlaf-Anteil', 
                                    '${deepSleepMinutes ~/ 60} Std ${deepSleepMinutes % 60} Min Gesamt',
                                    'Körperliche Regeneration & Immunsystem'
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(color: Color(0xFFD8CCBF), height: 1),
                                  ),
                                  _buildStructuredHighlightRow(
                                    const Color(0xFF8C7A70), 
                                    'REM-Traumphasen', 
                                    '${remSleepMinutes ~/ 60} Std ${remSleepMinutes % 60} Min Gesamt',
                                    'Emotionale Verarbeitung & Gedächtnis'
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(color: Color(0xFFD8CCBF), height: 1),
                                  ),
                                  _buildStructuredHighlightRow(
                                    const Color(0xFFC89B7B), 
                                    'Wachphasen', 
                                    '$awakeMinutes Min Gesamt',
                                    'Natürliche Unterbrechungen'
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A3B32),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () => _showDetailedSleepModal(context, currentInfluences),
                                child: const Text(
                                  'UHR-DETAILANSICHT ÖFFNEN',
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Score-Zeitstrahl Kasten
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F2EC),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFC89B7B), width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A3B32).withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.insights,
                                  color: Color(0xFFC89B7B),
                                  size: 26,
                                ),
                                SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    'SCORE-ZEITSTRAHL',
                                    style: TextStyle(
                                      color: Color(0xFF4A3B32),
                                      fontSize: 18,
                                      fontFamily: 'Cinzel',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _pickDateFromCalendar,
                            icon: const Icon(
                              Icons.calendar_month,
                              color: Color(0xFFC89B7B),
                              size: 28,
                            ),
                            tooltip: 'Datum im Kalender auswählen',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Verlauf & vergangene Monate per Kalender prüfen',
                        style: TextStyle(
                          color: Color(0xFF6B5B52),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 320,
                        child: ListView.builder(
                          controller: _timelineScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: _weeklyData.length,
                          itemBuilder: (context, index) {
                            final dayData = _weeklyData[index];
                            bool isSelected = _selectedDayIndex == index;
                            bool isToday = index == _todayIndex;
                            double sval = dayData['score'];
                            double hval = dayData['hours'];

                            Widget dayColumn = GestureDetector(
                              onTap: () async {
                                setState(() {
                                  _selectedDayIndex = index;
                                });
                                await _loadDayFromFirestore(dayData['dateTime']);
                                if (mounted) _showDayDetailModal(context, dayData);
                              },
                              child: Container(
                                width: 96,
                                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFEFE8E1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFC89B7B)
                                        : Colors.transparent,
                                    width: 1.8,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      sval > 0 ? sval.toStringAsFixed(0) : '0',
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF4A3B32)
                                            : const Color(0xFF6B5B52),
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Cinzel',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      hval > 0 ? _formatHoursToHoursAndMinutes(hval) : '-',
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFFC89B7B)
                                            : const Color(0xFF8C7A70),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 115,
                                      child: Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          Container(
                                            width: 12,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE5DBD0),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            heightFactor: sval > 0 ? sval / 98.0 : 0.0,
                                            child: Container(
                                              width: 12,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? const Color(0xFF4A3B32)
                                                    : const Color(0xFFC89B7B),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      dayData['day'],
                                      style: TextStyle(
                                        color: isToday ? const Color(0xFFC89B7B) : const Color(0xFF4A3B32),
                                        fontSize: 16,
                                        fontFamily: 'Cinzel',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      dayData['date'],
                                      style: const TextStyle(
                                        color: Color(0xFF6B5B52),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (isToday) {
                              return ScaleTransition(
                                scale: _timelinePulseAnimation,
                                child: dayColumn,
                              );
                            }

                            return dayColumn;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Regenerations-Tipps',
                  style: TextStyle(
                    color: Color(0xFF4A3B32),
                    fontSize: 20,
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 185,
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentTipPage == index ? 14 : 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: _currentTipPage == index
                            ? const Color(0xFFC89B7B)
                            : const Color(0xFFD8CCBF),
                        borderRadius: BorderRadius.circular(4.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // VERLINKUNG ZUM NEUEN MEDITATIONEN SCREEN
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MeditationenScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F2EC),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFC89B7B),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC89B7B).withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFE8E1),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFC89B7B)),
                              ),
                              child: const Icon(
                                Icons.graphic_eq,
                                color: Color(0xFFC89B7B),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Geführte Meditationen',
                                    style: TextStyle(
                                      color: Color(0xFF4A3B32),
                                      fontSize: 18,
                                      fontFamily: 'Cinzel',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    '& Sanfte Atemübungen',
                                    style: TextStyle(
                                      color: Color(0xFFC89B7B),
                                      fontSize: 14,
                                      fontFamily: 'Cinzel',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tauche ein in gesprochene Phantasiereisen, beruhigende Atemtechniken und harmonische Hintergrundmusik zum Herunterkommen.',
                          style: TextStyle(
                            color: Color(0xFF6B5B52),
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A3B32),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.self_improvement,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Entdecken & Hineinhören ➔',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Cinzel',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStructuredHighlightRow(Color dotColor, String title, String timeRange, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF4A3B32),
                  fontSize: 14,
                  fontFamily: 'Cinzel',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeRange,
                style: const TextStyle(
                  color: Color(0xFFC89B7B),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cinzel',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  color: Color(0xFF6B5B52),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showScoreBreakdownModal(
    BuildContext context,
    double score,
    double hours,
    int deepMin,
    int remMin,
    int awakeMin,
    List<String> influences,
  ) {
    double durationScore = 35.0;
    if (hours < 7.5) {
      durationScore = 35.0 - ((7.5 - hours) * 6.0);
    } else if (hours > 8.5) {
      durationScore = 35.0 - ((hours - 8.5) * 6.0);
    }
    if (durationScore < 0) durationScore = 0;

    double deepScore = (deepMin / 90.0) * 25.0;
    if (deepScore > 25.0) deepScore = 25.0;

    double remScore = (remMin / 90.0) * 20.0;
    if (remScore > 20.0) remScore = 20.0;

    double awakeScore = 18.0 - (awakeMin / 2.0);
    if (awakeScore < 0) awakeScore = 0;
    if (awakeScore > 18.0) awakeScore = 18.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F2EC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            height: MediaQuery.of(context).size.height * 0.92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8CCBF),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Schlafscore-Analyse',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF4A3B32),
                          fontSize: 24,
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Score: ${score.toStringAsFixed(0)} / 98',
                        style: const TextStyle(
                          color: Color(0xFFC89B7B),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cinzel',
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Center(
                  child: Text(
                    'Wie sich dein Score im Detail zusammensetzt',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4A3B32),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cinzel',
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: ListView(
                    children: [
                      _buildMassiveBreakdownTile(
                        'Gesamtschlafdauer',
                        _formatHoursToHoursAndMinutes(hours),
                        '(Optimum: 7.5 - 8.5h)',
                        durationScore,
                        35.0,
                        Icons.hourglass_bottom,
                      ),
                      const SizedBox(height: 18),
                      _buildMassiveBreakdownTile(
                        'Tiefschlaf-Anteil',
                        '${deepMin ~/ 60} Std ${deepMin % 60} Min',
                        '(Ziel: 90+ Min)',
                        deepScore,
                        25.0,
                        Icons.nightlight,
                      ),
                      const SizedBox(height: 18),
                      _buildMassiveBreakdownTile(
                        'REM-Schlaf (Traumphase)',
                        '${remMin ~/ 60} Std ${remMin % 60} Min',
                        '(Ziel: 90+ Min)',
                        remScore,
                        20.0,
                        Icons.waves,
                      ),
                      const SizedBox(height: 18),
                      _buildMassiveBreakdownTile(
                        'Wachphasen-Kontinuität',
                        '$awakeMin Minuten',
                        '(Wachzeit in der Nacht)',
                        awakeScore,
                        18.0,
                        Icons.remove_red_eye_outlined,
                      ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFE8E1),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFC89B7B), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Einflüsse vor der Nachtruhe (inkl. Abzug)',
                              style: TextStyle(
                                color: Color(0xFF8C7A70),
                                fontSize: 14,
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            influences.isEmpty
                                ? const Text(
                                    'Keine Einflüsse vor der Nachtruhe',
                                    style: TextStyle(
                                      color: Color(0xFF4A3B32),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: influences
                                        .map(
                                          (inf) => Padding(
                                            padding: const EdgeInsets.only(bottom: 6),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.fiber_manual_record,
                                                  size: 10,
                                                  color: Color(0xFFC89B7B),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    inf,
                                                    style: const TextStyle(
                                                      color: Color(0xFF4A3B32),
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        '💡 Tipps zur Verbesserung',
                        style: TextStyle(
                          color: Color(0xFF4A3B32),
                          fontSize: 19,
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildMassiveTipItem(
                        '1. Schlafdauer optimieren',
                        'Versuche heute Abend etwa 15 Minuten früher ins Bett zu gehen, um die vollen 7,5 Stunden zu erreichen.',
                      ),
                      const SizedBox(height: 12),
                      _buildMassiveTipItem(
                        '2. Tiefschlaf fördern',
                        'Lüfte dein Schlafzimmer vor dem Schlafen gut durch (16-18 °C) und vermeide schwere Mahlzeiten direkt vor der Nachtruhe.',
                      ),
                      const SizedBox(height: 12),
                      _buildMassiveTipItem(
                        '3. Innere Ruhe finden',
                        'Nutze abends eine kurze Atemübung oder Meditation, um das Gedankenkreisen abzustellen und die Wachphase zu verkürzen.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A3B32),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'SCHLIESSEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetailedSleepModal(BuildContext context, List<String> influences) {
    bool hasNegativeInfluences = influences.isNotEmpty;
    String hrStatusText = hasNegativeInfluences
        ? 'Außergewöhnlich erhöht (Ø68 bpm)'
        : 'Normal & Stabil (Ø58 bpm)';

    final List<Map<String, dynamic>> phases = _generateRealTimelinePhases();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F2EC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(26, 26, 26, 32),
            height: MediaQuery.of(context).size.height * 0.88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8CCBF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'UHR-MESSDATEN & GESAMTSUMMEN',
                        style: TextStyle(
                          color: Color(0xFF4A3B32),
                          fontSize: 19,
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gesamtdauern der Schlafphasen dieser Nacht:',
                  style: TextStyle(
                    color: Color(0xFF6B5B52),
                    fontSize: 14,
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
                      const SizedBox(height: 14),
                      _buildModalDetailTile(
                        Icons.wb_sunny_outlined,
                        'Aufwachzeit',
                        _wakeTimeText('06:45 Uhr'),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFE8E1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFC89B7B)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Einflüsse vor der Nachtruhe',
                              style: TextStyle(
                                color: Color(0xFF8C7A70),
                                fontSize: 12,
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            influences.isEmpty
                                ? const Text(
                                    'Keine Einflüsse vor der Nachtruhe',
                                    style: TextStyle(
                                      color: Color(0xFF4A3B32),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: influences
                                        .map(
                                          (inf) => Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.fiber_manual_record,
                                                  size: 8,
                                                  color: Color(0xFFC89B7B),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    inf,
                                                    style: const TextStyle(
                                                      color: Color(0xFF4A3B32),
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Phasen-Gesamtsummen:',
                        style: TextStyle(
                          color: Color(0xFF4A3B32),
                          fontSize: 15,
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...phases.map((p) {
                        IconData icon;
                        Color iconColor;
                        if (p['type'] == 'deep') {
                          icon = Icons.nightlight;
                          iconColor = const Color(0xFF4A3B32);
                        } else if (p['type'] == 'rem') {
                          icon = Icons.waves;
                          iconColor = const Color(0xFF8C7A70);
                        } else {
                          icon = Icons.remove_red_eye_outlined;
                          iconColor = const Color(0xFFC89B7B);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildModalDetailTile(
                            icon,
                            p['label'],
                            'Gesamtdauer: ${p['durationText']}',
                            iconColor: iconColor,
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: _buildModalDetailTile(
                          Icons.favorite,
                          'Herzfrequenz im Schlaf',
                          hrStatusText,
                          iconColor: Colors.redAccent,
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                        fontSize: 15,
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
        );
      },
    );
  }

  Widget _buildMassiveBreakdownTile(
    String title,
    String valueText,
    String hintText,
    double achieved,
    double max,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE8E1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC89B7B), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4A3B32),
              fontSize: 16,
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFC89B7B), size: 34),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valueText,
                      style: const TextStyle(
                        color: Color(0xFF4A3B32),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hintText,
                      style: const TextStyle(
                        color: Color(0xFF8C7A70),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${achieved.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF4A3B32),
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cinzel',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMassiveTipItem(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE8E1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC89B7B), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4A3B32),
              fontSize: 16,
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              color: Color(0xFF5A4A42),
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSyncButton() {
    return Material(
      color: const Color(0xFFEFE8E1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isSyncing ? null : _syncHealth,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC89B7B)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF4A3B32),
                      ),
                    )
                  : const Icon(Icons.sync, color: Color(0xFFC89B7B), size: 20),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  _isSyncing ? HealthTexts.syncing : HealthTexts.syncButton,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4A3B32),
                    fontSize: 12,
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
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
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            HealthTexts.lastSynced(day.syncedAt),
            style: const TextStyle(color: Color(0xFF8C7A70), fontSize: 12),
          ),
          if (sleep == null) ...[
            const SizedBox(height: 4),
            Text(
              HealthTexts.noSleepLastNight,
              style: const TextStyle(color: Color(0xFF8C7A70), fontSize: 12),
            ),
          ],
          if (sleep != null && !sleep.hasStages) ...[
            const SizedBox(height: 4),
            const Text(
              HealthTexts.noStages,
              style: const TextStyle(color: Color(0xFF8C7A70), fontSize: 12),
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
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF4A3B32),
                fontSize: 15,
                fontFamily: 'Cinzel',
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF4A3B32),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cinzel',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseInfoCard(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE8E1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC89B7B), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4A3B32),
              fontSize: 15,
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF6B5B52),
              fontSize: 13,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Material(
      type: MaterialType.transparency,
      child: CheckboxListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF4A3B32),
            fontSize: 14,
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2EC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC89B7B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A3B32).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Regeneration',
            style: TextStyle(
              color: Color(0xFFC89B7B),
              fontSize: 12,
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4A3B32),
              fontSize: 17,
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF6B5B52),
              fontSize: 14.5,
              height: 1.4,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showDayDetailModal(BuildContext context, Map<String, dynamic> dayData) {
    List<dynamic> infs = dayData['influences'] ?? [];
    double score = dayData['score'];
    int points = dayData['points'] ?? 0;
    String quality = dayData['quality'];
    bool hasData = score > 0;
    final bool isToday = identical(dayData, _weeklyData[_todayIndex]);
    final SleepSummary? pastSleep = dayData['sleep'];
    final String bedtimeStr = isToday
        ? _bedtimeText('23:15 Uhr')
        : _clockOrNoData(pastSleep?.bedtime);
    final String wakeTimeStr = isToday
        ? _wakeTimeText('06:45 Uhr')
        : _clockOrNoData(pastSleep?.wakeTime);
    final DateTime date = dayData['dateTime'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F2EC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(26, 26, 26, 32),
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8CCBF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TAGES-DETAILS: ${dayData['date']}.${date.year}',
                      style: const TextStyle(
                        color: Color(0xFF4A3B32),
                        fontSize: 16,
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
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
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Gesammelte XP: $points / 100 Punkte',
                  style: const TextStyle(
                    color: Color(0xFF8C7A70),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cinzel',
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFE8E1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFC89B7B)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_outline,
                              color: Color(0xFFC89B7B),
                              size: 26,
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
                                      fontSize: 12,
                                      fontFamily: 'Cinzel',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    quality,
                                    style: const TextStyle(
                                      color: Color(0xFF4A3B32),
                                      fontSize: 16,
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
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFE8E1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFC89B7B)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Einflüsse vor der Nachtruhe',
                              style: TextStyle(
                                color: Color(0xFF8C7A70),
                                fontSize: 12,
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            infs.isEmpty
                                ? const Text(
                                    'Keine Einflüsse vor der Nachtruhe',
                                    style: TextStyle(
                                      color: Color(0xFF4A3B32),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: infs
                                        .map(
                                          (inf) => Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.fiber_manual_record,
                                                  size: 8,
                                                  color: Color(0xFFC89B7B),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    inf,
                                                    style: const TextStyle(
                                                      color: Color(0xFF4A3B32),
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildModalDetailTile(
                        Icons.bedtime_outlined,
                        'Einschlafzeit',
                        hasData ? bedtimeStr : HealthTexts.noData,
                      ),
                      const SizedBox(height: 14),
                      _buildModalDetailTile(
                        Icons.wb_sunny_outlined,
                        'Aufwachzeit',
                        hasData ? wakeTimeStr : HealthTexts.noData,
                      ),
                      const SizedBox(height: 14),
                      _buildModalDetailTile(
                        Icons.hourglass_bottom,
                        'Schlafdauer Gesamt',
                        hasData ? _formatHoursToHoursAndMinutes(dayData['hours']) : '0 Std',
                      ),
                      const SizedBox(height: 14),
                      _buildModalDetailTile(
                        Icons.nightlight,
                        'Tiefschlaf',
                        hasData ? '${dayData['deep']} Minuten' : '0 Minuten',
                      ),
                      const SizedBox(height: 14),
                      _buildModalDetailTile(
                        Icons.waves,
                        'REM-Schlaf',
                        hasData ? '${dayData['rem']} Minuten' : '0 Minuten',
                      ),
                      const SizedBox(height: 14),
                      _buildModalDetailTile(
                        Icons.remove_red_eye_outlined,
                        'Wachphase',
                        hasData ? '${dayData['awake']} Minuten' : '0 Minuten',
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Schließen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE8E1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC89B7B)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8C7A70),
                    fontSize: 12,
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF4A3B32),
                    fontSize: 15,
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

// ---------------------------------------------------------------------------
// VOLLSTÄNDIG AKTUALISIERTER MEDITATIONEN SCREEN (IM LUTALIA DESIGN)
// ---------------------------------------------------------------------------
class MeditationenScreen extends StatefulWidget {
  const MeditationenScreen({super.key});

  @override
  State<MeditationenScreen> createState() => _MeditationenScreenState();
}

class _MeditationenScreenState extends State<MeditationenScreen>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    'Alle',
    'Geführt',
    'Atemübungen',
    'Klangwelten',
  ];

  final List<Map<String, dynamic>> _meditations = [
    {
      'title': 'Gedankenstopp vor dem Schlafen',
      'subtitle': 'Gesprochene Führung um das Gedankenkreisen sanft zu lösen',
      'duration': '10 Min',
      'category': 'Geführt',
      'icon': Icons.mic_none_outlined,
    },
    {
      'title': '4-7-8 Beruhigungs-Atmung',
      'subtitle': 'Anleitung für eine tiefere, verlangsamte Atmung',
      'duration': '5 Min',
      'category': 'Atemübungen',
      'icon': Icons.air_outlined,
    },
    {
      'title': 'Innere Ruhe & Geborgenheit',
      'subtitle': 'Sanfte Phantasiereise zum Entspannen und Ankommen',
      'duration': '12 Min',
      'category': 'Geführt',
      'icon': Icons.self_improvement_outlined,
    },
    {
      'title': 'Sanfte Nacht-Naturklänge',
      'subtitle': 'Ruhige Hintergrundmusik mit warmen Entspannungsfrequenzen',
      'duration': '20 Min',
      'category': 'Klangwelten',
      'icon': Icons.music_note_outlined,
    },
  ];

  Map<String, dynamic>? _currentlyPlaying;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _selectedCategoryIndex == 0
        ? _meditations
        : _meditations
            .where((m) => m['category'] == _categories[_selectedCategoryIndex])
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4EFEA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A3B32), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MEDITATION & RUHE',
          style: TextStyle(
            color: Color(0xFF4A3B32),
            fontSize: 22,
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              children: [
                Center(
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: _breathAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F2EC),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFC89B7B),
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC89B7B).withValues(alpha: 0.18),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.graphic_eq,
                            color: Color(0xFFC89B7B),
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Geführte Meditationen',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF4A3B32),
                          fontSize: 32,
                          fontFamily: 'NewFirst',
                          fontWeight: FontWeight.w300,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'SPRECHENDE BEGLEITUNG, BERUHIGENDE KLÄNGE\nUND SANFTE ATEMÜBUNGEN ZUM HERUNTERKOMMEN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8C7A70),
                          fontSize: 11,
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedCategoryIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF4A3B32)
                                : const Color(0xFFF7F2EC),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFC89B7B),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _categories[index].toUpperCase(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF4A3B32),
                                fontSize: 12,
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _categories[_selectedCategoryIndex].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF8C7A70),
                        fontSize: 12,
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '${filteredList.length} Aufnahmen',
                      style: const TextStyle(
                        color: Color(0xFFC89B7B),
                        fontSize: 12,
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...filteredList.map((item) {
                  final bool isThisPlaying =
                      _currentlyPlaying == item && _isPlaying;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F2EC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isThisPlaying
                              ? const Color(0xFF4A3B32)
                              : const Color(0xFFC89B7B),
                          width: isThisPlaying ? 2.0 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A3B32).withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_currentlyPlaying == item) {
                                  _isPlaying = !_isPlaying;
                                } else {
                                  _currentlyPlaying = item;
                                  _isPlaying = true;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isThisPlaying
                                    ? const Color(0xFFC89B7B)
                                    : const Color(0xFFEFE8E1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFC89B7B),
                                ),
                              ),
                              child: Icon(
                                isThisPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: isThisPlaying
                                    ? Colors.white
                                    : const Color(0xFF4A3B32),
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  style: const TextStyle(
                                    color: Color(0xFF4A3B32),
                                    fontSize: 16,
                                    fontFamily: 'Cinzel',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['subtitle'],
                                  style: const TextStyle(
                                    color: Color(0xFF6B5B52),
                                    fontSize: 13,
                                    fontFamily: 'NewFirst',
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFE8E1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFC89B7B),
                              ),
                            ),
                            child: Text(
                              item['duration'],
                              style: const TextStyle(
                                color: Color(0xFFC89B7B),
                                fontSize: 11,
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 30),
              ],
            ),
          ),
          if (_currentlyPlaying != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF4A3B32),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    const Icon(
                      Icons.graphic_eq,
                      color: Color(0xFFC89B7B),
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentlyPlaying!['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Cinzel',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _isPlaying ? 'Wird abgespielt...' : 'Pausiert',
                            style: const TextStyle(
                              color: Color(0xFFC89B7B),
                              fontSize: 11,
                              fontFamily: 'Cinzel',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: const Color(0xFFC89B7B),
                        size: 38,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPlaying = !_isPlaying;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StarProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color activeColor;

  _StarProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.activeColor,
  });

  Path _createStarPath(Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    const points = 5;
    final outerRadius = size.width / 2 - 16;
    final innerRadius = outerRadius * 0.52;

    double angle = -math.pi / 2;
    const step = math.pi / points;

    for (int i = 0; i < 2 * points; i++) {
      final r = (i % 2 == 0) ? outerRadius : innerRadius;
      final x = cx + math.cos(angle) * r;
      final y = cy + math.sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      angle += step;
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final starPath = _createStarPath(size);

    canvas.drawPath(starPath, trackPaint);

    final metrics = starPath.computeMetrics();
    for (final metric in metrics) {
      final length = metric.length;
      final extractPath = metric.extractPath(0.0, length * progress.clamp(0.0, 1.0));
      canvas.drawPath(extractPath, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.activeColor != activeColor;
  }
}

class _FairyDustPainter extends CustomPainter {
  final double progress;

  _FairyDustPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(2026);
    const particleCount = 32;

    for (int i = 0; i < particleCount; i++) {
      double relativeX = random.nextDouble() * size.width;
      double relativeY = random.nextDouble() * size.height;

      double verticalFloat = math.sin(progress * math.pi * 2 + i) * 6.0;
      double py = relativeY + verticalFloat;
      double px = relativeX;

      double alpha = ((math.sin(progress * math.pi * 2 + i * 1.5) + 1) / 2) * 0.85;
      paint.color = const Color(0xFFC89B7B).withValues(alpha: alpha.clamp(0.15, 0.9));

      if (i % 4 == 0) {
        double starSize = 2.5 + (random.nextDouble() * 2.2);
        final path = Path();
        path.moveTo(px, py - starSize);
        path.quadraticBezierTo(px, py, px + starSize, py);
        path.quadraticBezierTo(px, py, px, py + starSize);
        path.quadraticBezierTo(px, py, px - starSize, py);
        path.quadraticBezierTo(px, py, px, py - starSize);
        canvas.drawPath(path, paint);
      } else {
        double radius = 0.8 + (random.nextDouble() * 1.8);
        canvas.drawCircle(Offset(px, py), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FairyDustPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ExhalingHeartsPainter extends CustomPainter {
  final double progress;

  const _ExhalingHeartsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC89B7B)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2 - 12;
    const startY = 120.0;

    for (int i = 0; i < 3; i++) {
      double p = (progress + (i * 0.33)) % 1.0;
      double currentY = startY - (p * 130.0);
      double currentX = centerX + (math.sin(p * math.pi * 2 + i) * 24.0) + (i == 1 ? 22 : -16);
      double opacity = (1.0 - p).clamp(0.0, 1.0);
      double scale = 0.6 + (p * 0.8);

      paint.color = const Color(0xFFC89B7B).withValues(alpha: opacity * 0.85);

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.scale(scale);

      final path = Path();
      path.moveTo(0, 5);
      path.cubicTo(-10, -5, -15, -12, -15, -18);
      path.cubicTo(-15, -25, -5, -27, 0, -18);
      path.cubicTo(5, -27, 15, -25, 15, -18);
      path.cubicTo(15, -12, 10, -5, 0, 5);
      path.close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ExhalingHeartsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}