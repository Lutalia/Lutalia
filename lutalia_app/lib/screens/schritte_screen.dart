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
  final ScrollController _scrollController = ScrollController();

  static const int _historyDays = 90;
  static final NumberFormat _stepsFormat = NumberFormat.decimalPattern('de_DE');

  int todaySteps = 0;
  List<({DateTime day, int? steps})> _days = const [];
  HealthSyncOutcome? _problem;
  bool _isLoading = false;

  int _dailyGoal = 8000;
  String _selectedView = 'Tage';
  bool _challenge7DaysJoined = false;
  bool _challenge10kJoined = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _loadSteps();
  }

  void _initVideo() {
    _videoController =
        VideoPlayerController.asset("assets/videos/gesundheitsscreen.mp4")
          ..initialize().then((_) {
            if (mounted) {
              setState(() {});
            }
            _videoController
              ..setLooping(true)
              ..setVolume(0)
              ..play();
          });
  }

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
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

  List<({String label, int totalSteps, int dailyAvg, DateTime startDate, DateTime endDate})> get _realWeeksList {
    if (_days.isEmpty) return [];
    List<({String label, int totalSteps, int dailyAvg, DateTime startDate, DateTime endDate})> weeks = [];
    
    for (int i = 0; i < _days.length; i += 7) {
      var chunk = _days.skip(i).take(7).toList();
      if (chunk.isEmpty) continue;
      int sum = chunk.map((d) => d.steps ?? 0).fold(0, (a, b) => a + b);
      int avg = (sum / chunk.length).round();
      
      DateTime start = chunk.first.day;
      DateTime end = chunk.last.day;
      String label = "${DateFormat('dd.MM.', 'de_DE').format(start)} - ${DateFormat('dd.MM.', 'de_DE').format(end)}";
      
      weeks.add((label: label, totalSteps: sum, dailyAvg: avg, startDate: start, endDate: end));
    }
    return weeks;
  }

  List<({String label, int totalSteps, int dailyAvg, int totalDays})> get _realMonthsList {
    if (_days.isEmpty) return [];
    Map<String, List<int>> monthMap = {};
    
    for (var d in _days) {
      if (d.steps != null && d.steps! > 0) {
        String monthKey = DateFormat('MMMM yyyy', 'de_DE').format(d.day);
        monthMap.putIfAbsent(monthKey, () => []).add(d.steps!);
      }
    }

    List<({String label, int totalSteps, int dailyAvg, int totalDays})> months = [];
    monthMap.forEach((monthName, stepsList) {
      int sum = stepsList.reduce((a, b) => a + b);
      int avg = (sum / stepsList.length).round();
      months.add((label: monthName, totalSteps: sum, dailyAvg: avg, totalDays: stepsList.length));
    });

    return months;
  }

  int? get _monthlyAverage {
    final recorded = _days
        .map((d) => d.steps)
        .whereType<int>()
        .where((s) => s > 0)
        .toList();
    if (recorded.isEmpty) return null;
    return (recorded.reduce((a, b) => a + b) / recorded.length).round();
  }

  int get _goalsReachedCount {
    return _days.where((d) => (d.steps ?? 0) >= _dailyGoal).length;
  }

  @override
  void dispose() {
    _videoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _editDailyGoalModal() {
    final TextEditingController controller =
        TextEditingController(text: _dailyGoal.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF5F0EB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Tagesziel anpassen',
            style: TextStyle(
              fontFamily: 'Cinzel',
              color: Color(0xFF4A3B32),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Color(0xFF4A3B32), fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Ziel in Schritten',
              labelStyle: const TextStyle(color: Color(0xFF8C7A70)),
              filled: true,
              fillColor: const Color(0xFFEAE3DD),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD6CBC1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFC89B7B)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen', style: TextStyle(color: Color(0xFF8C7A70), fontSize: 15)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A3B32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final parsed = int.tryParse(controller.text);
                if (parsed != null && parsed > 0) {
                  setState(() => _dailyGoal = parsed);
                }
                Navigator.pop(context);
              },
              child: const Text('Speichern', style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
          ],
        );
      },
    );
  }

  void _openCalendarPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF5F0EB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Tag auswählen',
            style: TextStyle(
              fontFamily: 'Cinzel',
              color: Color(0xFF4A3B32),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SizedBox(
            width: 300,
            height: 350,
            child: CalendarDatePicker(
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 90)),
              lastDate: DateTime.now(),
              onDateChanged: (picked) {
                Navigator.pop(context);
                final match = _days.cast<({DateTime day, int? steps})?>().firstWhere(
                      (d) => d?.day.year == picked.year && d?.day.month == picked.month && d?.day.day == picked.day,
                      orElse: () => null,
                    );
                int stepsFound = match?.steps ?? 0;
                _showDayDetails(picked, stepsFound);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen', style: TextStyle(color: Color(0xFF8C7A70), fontSize: 15)),
            ),
          ],
        );
      },
    );
  }

  void _showDayDetails(DateTime day, int steps) {
    final double km = steps * 0.00078;
    final int kcal = (steps * 0.04).round();
    final int floors = (steps / 300).round();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5F0EB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      DateFormat('EEEE, dd. MMMM yyyy', 'de_DE').format(day),
                      style: const TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A3B32),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF4A3B32), size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFD6CBC1), height: 24),
              const SizedBox(height: 8),
              Text(
                '${_stepsFormat.format(steps)} Schritte',
                style: const TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC89B7B),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _modalStatItem(Icons.map_outlined, '${km.toStringAsFixed(2)} km', 'Strecke'),
                  _modalStatItem(Icons.local_fire_department, '$kcal kcal', 'Verbrauch'),
                  _modalStatItem(Icons.stairs, '$floors Etagen', 'Aufstieg'),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _modalStatItem(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4A3B32), size: 28),
        const SizedBox(height: 8),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A3B32))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8C7A70))),
      ],
    );
  }

  void _showDetailedInsightModal({
    required String title,
    required IconData icon,
    required List<Widget> contentWidgets,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5F0EB),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6CBC1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC89B7B),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(icon, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A3B32),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF4A3B32), size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFD6CBC1), height: 36),
                  ...contentWidgets,
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double kilometers = (todaySteps * 0.00078);
    final int calories = (todaySteps * 0.04).round();
    final int floors = (todaySteps / 300).round();
    final double goalProgress = (todaySteps / _dailyGoal).clamp(0.0, 1.0);

    return LutaliaPage(
      title: "Schritte & Bewegung",
      showBack: true,
      onBackPressed: widget.onGoHome,
      child: RefreshIndicator(
        color: const Color(0xFFC89B7B),
        onRefresh: _loadSteps,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                if (_videoController.value.isInitialized)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: VideoPlayer(_videoController),
                    ),
                  ),

                const SizedBox(height: 18),

                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE3DD),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFD6CBC1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['Stunden', 'Tage', 'Wochen', 'Monate'].map((view) {
                        bool isSelected = _selectedView == view;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedView = view);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_scrollController.hasClients) {
                                _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF4A3B32) : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              view,
                              style: TextStyle(
                                fontFamily: 'Cinzel',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF8C7A70),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE3DD),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFD6CBC1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "HEUTE",
                            style: TextStyle(
                              fontFamily: "Cinzel",
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8C7A70),
                              letterSpacing: 1.2,
                            ),
                          ),
                          GestureDetector(
                            onTap: _editDailyGoalModal,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F0EB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFD6CBC1)),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    "Ziel: ${_stepsFormat.format(_dailyGoal)}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4A3B32),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.edit, size: 14, color: Color(0xFFC89B7B)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _stepsFormat.format(todaySteps),
                            style: const TextStyle(
                              fontFamily: "Cinzel",
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A3B32),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Schritte",
                            style: TextStyle(
                              fontSize: 17,
                              color: Color(0xFF6B5B52),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: goalProgress,
                          minHeight: 12,
                          backgroundColor: const Color(0xFFD6CBC1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFC89B7B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _metricItem(Icons.map_outlined, "${kilometers.toStringAsFixed(2)} km", "Entfernung"),
                          Container(height: 30, width: 1, color: const Color(0xFFD6CBC1)),
                          _metricItem(Icons.local_fire_department_outlined, "$calories kcal", "Verbrauch"),
                          Container(height: 30, width: 1, color: const Color(0xFFD6CBC1)),
                          _metricItem(Icons.stairs_outlined, "$floors Etagen", "Aufstieg"),
                        ],
                      ),
                    ],
                  ),
                ),

                _healthProblemHint(),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE3DD),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFD6CBC1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _selectedView == 'Stunden'
                                  ? 'AKTIVITÄT NACH TAGESZEIT'
                                  : _selectedView == 'Monate'
                                      ? 'MONATLICHE ENTWICKLUNG'
                                      : _selectedView == 'Wochen'
                                          ? 'WOCHENVERGLEICH'
                                          : 'LETZTE 7 TAGE',
                              style: const TextStyle(
                                fontFamily: "Cinzel",
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A3B32),
                                letterSpacing: 1.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.calendar_month, color: Color(0xFFC89B7B), size: 26),
                            onPressed: _openCalendarPicker,
                            tooltip: "Tag im Kalender auswählen",
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildHorizontalDynamicChart(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE3DD),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFD6CBC1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "AUSWERTUNG & STATISTIK",
                        style: TextStyle(
                          fontFamily: "Cinzel",
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A3B32),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        "Monatsdurchschnitt",
                        style: TextStyle(
                          fontFamily: "Cinzel",
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8C7A70),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _monthlyAverage == null
                            ? '–'
                            : "${_stepsFormat.format(_monthlyAverage)} Schritte / Tag",
                        style: const TextStyle(
                          fontFamily: "Cinzel",
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A3B32),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Divider(color: Color(0xFFD6CBC1)),
                      ),
                      const Text(
                        "Tagesziel erreicht",
                        style: TextStyle(
                          fontFamily: "Cinzel",
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8C7A70),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _days.isEmpty
                            ? '–'
                            : "$_goalsReachedCount von ${_days.length} Tagen",
                        style: const TextStyle(
                          fontFamily: "Cinzel",
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC89B7B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _sectionTitle("Aktivitäts-Einblicke"),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showDetailedInsightModal(
                    title: "Bewegungs-Analyse",
                    icon: Icons.directions_walk,
                    contentWidgets: [
                      const Text(
                        "Deine Gangdynamik & Rhythmik",
                        style: TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4A3B32)),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Eine gleichmäßige Schrittfrequenz im Alltag schont die Gelenke und fördert die cardiorespiratorische Ausdauer. Deine aufgezeichneten Werte zeigen eine stabile Verteilung über den Tagesverlauf.",
                        style: TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF6B5B52)),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Empfehlung für morgen:",
                        style: TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A3B32)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "• Versuche, nach dem Mittagessen einen kurzen 15-minütigen Spaziergang einzubauen.\n• Achte auf eine aufrechte Haltung bei längeren Strecken.",
                        style: TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF6B5B52)),
                      ),
                    ],
                  ),
                  child: _insightTile("Bewegungs-Analyse", "Auswertung deiner Gangfrequenz & Alltagsbalance", Icons.directions_walk),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _showDetailedInsightModal(
                    title: "Stoffwechsel & Energie",
                    icon: Icons.local_fire_department,
                    contentWidgets: [
                      const Text(
                        "Kalorienverbrennung & Grundumsatz",
                        style: TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4A3B32)),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Dein aktiver Kalorienverbrauch passt sich dynamisch an deine zurückgelegten Schritte an. Dies unterstützt deinen Energiestoffwechsel und sorgt für einen stabilen Blutzuckerspiegel über den Tag.",
                        style: TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF6B5B52)),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Stoffwechsel-Tipp:",
                        style: TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A3B32)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "• Ausreichende Flüssigkeitszufuhr bei aktiven Phasen optimiert die Fettverbrennung.\n• Kombiniere Bewegung mit proteinreicher Kost.",
                        style: TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF6B5B52)),
                      ),
                    ],
                  ),
                  child: _insightTile("Stoffwechsel & Energie", "Einblick in deinen aktiven Kalorienhaushalt", Icons.local_fire_department),
                ),

                const SizedBox(height: 24),

                _sectionTitle("Aktivitäts-Challenges"),
                const SizedBox(height: 12),
                _challengeActionTile(
                  title: "7‑Tage‑Schritte‑Challenge",
                  subtitle: "Halte deinen Schnitt 7 Tage über dem Ziel",
                  isJoined: _challenge7DaysJoined,
                  onJoin: () => setState(() => _challenge7DaysJoined = !_challenge7DaysJoined),
                ),
                const SizedBox(height: 14),
                _challengeActionTile(
                  title: "10.000‑Schritte‑Meilenstein",
                  subtitle: "Knacke die 10k-Marke an 3 Wochentagen",
                  isJoined: _challenge10kJoined,
                  onJoin: () => setState(() => _challenge10kJoined = !_challenge10kJoined),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalDynamicChart() {
    if (_selectedView == 'Stunden') {
      return _horizontalHourlyChart();
    } else if (_selectedView == 'Wochen') {
      return _horizontalWeeksChart();
    } else if (_selectedView == 'Monate') {
      return _horizontalMonthsChart();
    } else {
      return _horizontalDaysChart();
    }
  }

  Widget _metricItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFC89B7B), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF4A3B32),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8C7A70)),
        ),
      ],
    );
  }

  Widget _healthProblemHint() {
    final HealthSyncOutcome? problem = _problem;
    if (problem == null) return const SizedBox.shrink();
    final String? action = HealthTexts.actionLabel(problem);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: GestureDetector(
        onTap: action == null ? null : () => _resolveProblem(problem),
        child: Text(
          action == null
              ? HealthTexts.message(problem)
              : '${HealthTexts.message(problem)}\n$action ›',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.35,
            color: Color(0xFF8C7A70),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: "Cinzel",
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4A3B32),
      ),
    );
  }

  Widget _horizontalDaysChart() {
    final week = _lastWeek;
    final int best = week.map((d) => d.steps ?? 0).fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 320,
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: week.length,
        itemBuilder: (context, i) {
          final entry = week[i];
          final int steps = entry.steps ?? 0;
          final bool isToday = i == week.length - 1;
          final double progress = best == 0 ? 0.0 : (steps / best).clamp(0.0, 1.0);
          final String dayLabel = DateFormat('EEEE, dd.MM.', 'de_DE').format(entry.day);

          return GestureDetector(
            onTap: () => _showDayDetails(entry.day, steps),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0EB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6CBC1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dayLabel,
                        style: TextStyle(
                          fontFamily: "Cinzel",
                          fontSize: 14,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                          color: const Color(0xFF4A3B32),
                        ),
                      ),
                      Text(
                        '${_stepsFormat.format(steps)} Schr.',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC89B7B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFEAE3DD),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isToday ? const Color(0xFF4A3B32) : const Color(0xFFC89B7B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _horizontalWeeksChart() {
    final realWeeks = _realWeeksList;

    if (realWeeks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: Text("Keine Wochen-Daten verfügbar", style: TextStyle(color: Color(0xFF8C7A70)))),
      );
    }

    final int best = realWeeks.map((w) => w.totalSteps).fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 340,
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: realWeeks.length,
        itemBuilder: (context, i) {
          final w = realWeeks[i];
          final double progress = best == 0 ? 0.0 : (w.totalSteps / best).clamp(0.0, 1.0);

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0EB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6CBC1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      w.label,
                      style: const TextStyle(
                        fontFamily: "Cinzel",
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A3B32),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_stepsFormat.format(w.totalSteps)} Ges.',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4A3B32)),
                        ),
                        Text(
                          '(${_stepsFormat.format(w.dailyAvg)} Ø / Tag)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8C7A70)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 14,
                    backgroundColor: const Color(0xFFEAE3DD),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC89B7B)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _horizontalMonthsChart() {
    final realMonths = _realMonthsList;

    if (realMonths.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: Text("Keine Monats-Daten verfügbar", style: TextStyle(color: Color(0xFF8C7A70)))),
      );
    }

    final int best = realMonths.map((m) => m.totalSteps).fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 340,
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: realMonths.length,
        itemBuilder: (context, i) {
          final m = realMonths[i];
          final double progress = best == 0 ? 0.0 : (m.totalSteps / best).clamp(0.0, 1.0);

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0EB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6CBC1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m.label,
                      style: const TextStyle(
                        fontFamily: "Cinzel",
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A3B32),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_stepsFormat.format(m.totalSteps)} Ges.',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4A3B32)),
                        ),
                        Text(
                          '(${_stepsFormat.format(m.dailyAvg)} Ø / Tag)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8C7A70)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 14,
                    backgroundColor: const Color(0xFFEAE3DD),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A3B32)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _horizontalHourlyChart() {
    final List<MapEntry<String, double>> hours = [
      const MapEntry('08:00 - 10:00', 0.1),
      const MapEntry('10:00 - 12:00', 0.3),
      const MapEntry('12:00 - 14:00', 0.6),
      const MapEntry('14:00 - 16:00', 0.9),
      const MapEntry('16:00 - 18:00', 0.7),
      const MapEntry('18:00 - 20:00', 0.4),
    ];

    return SizedBox(
      height: 300,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: hours.length,
        itemBuilder: (context, i) {
          final h = hours[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0EB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6CBC1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.key,
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A3B32),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: h.value,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFEAE3DD),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC89B7B)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _insightTile(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAE3DD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6CBC1), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC89B7B), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A3B32),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B5B52)),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 15, color: Color(0xFF8C7A70)),
        ],
      ),
    );
  }

  Widget _challengeActionTile({
    required String title,
    required String subtitle,
    required bool isJoined,
    required VoidCallback onJoin,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAE3DD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6CBC1), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined, color: Color(0xFFC89B7B), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A3B32),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B5B52)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isJoined ? const Color(0xFF4A3B32) : const Color(0xFFC89B7B),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: onJoin,
            child: Text(
              isJoined ? "Aktiv ✓" : "Teilnehmen",
              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}