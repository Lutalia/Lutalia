import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../theme/theme.dart';
import '../screens/lutalia_page.dart';

class WasserScreen extends StatefulWidget {
  final DateTime selectedDate;

  const WasserScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<WasserScreen> createState() => _WasserScreenState();
}

class _WasserScreenState extends State<WasserScreen> {
  late DateTime _currentDate;

  int waterCount = 0;
  int glassMl = 200;
  int dailyGoalMl = 2000;

  late List<bool> isPopping;

  Color get dropBlue => const Color(0xFFB7DDF5);
  Color get deepBlue => const Color(0xFF4A90E2);

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // Reminder
  bool reminderEnabled = false;
  String reminderMode = "hourly";
  int intervalMinutes = 60;
  String morningTime = "08:00";
  String noonTime = "12:00";
  String eveningTime = "18:00";

  // Reminder soll IMMER eingeklappt starten
  bool _showReminderDetails = false;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
    isPopping = List.generate(200, (_) => false);

    tz.initializeTimeZones();
    _initNotifications();

    _loadGoal();
    _loadReminderSettings();
    _loadWaterFor(_currentDate);
  }

  String _dateKey(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String _formatDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);
  }

  Future<void> _loadWaterFor(DateTime date) async {
    final dateKey = _dateKey(date);

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("water")
        .doc(dateKey)
        .collection("data")
        .doc("entry")
        .get();

    setState(() {
      _currentDate = date;
      waterCount = (doc.data()?["count"] ?? 0) as int;
    });
  }

  Future<int> _loadDayValue(DateTime date) async {
    final dateKey = _dateKey(date);

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("water")
        .doc(dateKey)
        .collection("data")
        .doc("entry")
        .get();

    return (doc.data()?["count"] ?? 0) as int;
  }

  Future<void> _saveWaterFor(DateTime date) async {
    final dateKey = _dateKey(date);

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("water")
        .doc(dateKey)
        .collection("data")
        .doc("entry")
        .set({
      "count": waterCount,
      "updatedAt": DateTime.now(),
    }, SetOptions(merge: true));

    await _scheduleReminders();
  }

  Future<void> _loadGoal() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("settings")
        .doc("water_goal")
        .get();

    setState(() {
      dailyGoalMl = (doc.data()?["dailyGoalMl"] ?? 2000) as int;
    });
  }

  Future<void> _saveGoal() async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("settings")
        .doc("water_goal")
        .set({
      "dailyGoalMl": dailyGoalMl,
      "updatedAt": DateTime.now(),
    }, SetOptions(merge: true));

    await _scheduleReminders();
  }

  Future<void> _loadReminderSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("settings")
        .doc("water_reminder")
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    setState(() {
      reminderEnabled = data["enabled"] ?? false;
      reminderMode = data["mode"] ?? "hourly";
      intervalMinutes = data["intervalMinutes"] ?? 60;
      morningTime = data["morningTime"] ?? "08:00";
      noonTime = data["noonTime"] ?? "12:00";
      eveningTime = data["eveningTime"] ?? "18:00";

      // Reminder bleibt IMMER eingeklappt
      _showReminderDetails = false;
    });

    await _scheduleReminders();
  }

  Future<void> _saveReminderSettings() async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("settings")
        .doc("water_reminder")
        .set({
      "enabled": reminderEnabled,
      "mode": reminderMode,
      "intervalMinutes": intervalMinutes,
      "morningTime": morningTime,
      "noonTime": noonTime,
      "eveningTime": eveningTime,
    }, SetOptions(merge: true));

    await _scheduleReminders();
  }

  Future<void> _scheduleReminders() async {
    await _notifications.cancelAll();

    if (!reminderEnabled) return;

    final remaining =
        (dailyGoalMl / 1000 - litersToday).clamp(0, 100).toStringAsFixed(1);
    final current = litersToday.toStringAsFixed(1);

    if (reminderMode == "hourly") {
      final now = tz.TZDateTime.now(tz.local);
      final first = now.add(Duration(minutes: intervalMinutes));

      await _notifications.zonedSchedule(
        100,
        "Wasser trinken",
        "Du hast heute $current L getrunken. Es fehlen noch $remaining L.",
        first,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_channel',
            'Wasser Reminder',
            importance: Importance.high,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      await _scheduleDaily(morningTime, 101);
      await _scheduleDaily(noonTime, 102);
      await _scheduleDaily(eveningTime, 103);
    }
  }

  Future<void> _scheduleDaily(String time, int id) async {
    final parts = time.split(":");
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final remaining =
        (dailyGoalMl / 1000 - litersToday).clamp(0, 100).toStringAsFixed(1);
    final current = litersToday.toStringAsFixed(1);

    await _notifications.zonedSchedule(
      id,
      "Wasser trinken",
      "Du hast heute $current L getrunken. Es fehlen noch $remaining L.",
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_channel',
          'Wasser Reminder',
          importance: Importance.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Prozentanzeige darf über 100% gehen
  double get litersToday => (waterCount * glassMl) / 1000;
  double get percentDisplay =>
      (litersToday / (dailyGoalMl / 1000)) * 100; // kann >100 sein
  double get progressBar =>
      (litersToday / (dailyGoalMl / 1000)).clamp(0, 1).toDouble();

  Future<void> _showGoalReachedDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Ziel erreicht!",
                    style: TextStyle(
                      fontFamily: "NewFirst",
                      fontSize: 26,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Du hast dein heutiges Wasser‑Ziel erfüllt.\nDein Körper dankt dir.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Cinzel",
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dropBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Wundervoll",
                      style: TextStyle(
                        fontFamily: "Cinzel",
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleGlass(int index) {
    final oldPercent = percentDisplay;

    setState(() {
      isPopping[index] = true;

      if (index < waterCount) {
        waterCount = index;
      } else {
        waterCount = index + 1;
      }
    });

    final newPercent = percentDisplay;
    if (oldPercent < 100 && newPercent >= 100) {
      _showGoalReachedDialog();
    }

    _saveWaterFor(_currentDate);

    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() => isPopping[index] = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LutaliaPage(
      title: "Dein Wasser‑Tag",
      showBack: true,
      removePadding: true,
      onBackPressed: () => Navigator.pop(context),
      child: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _headerSection(),
              const SizedBox(height: 30),
              _glassesSection(),
              const SizedBox(height: 24),
              _reminderBox(),
              const SizedBox(height: 24),
              _waterCurve(),
              const SizedBox(height: 24),
              _historyAndWeek(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER
  Widget _headerSection() {
    return Column(
      children: [
        Image.asset(
          "assets/fee/wasser.png",
          height: 180,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Text(
            "Wasser schenkt deinem Körper Klarheit, Energie und Balance.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: "Cinzel",
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _formatDate(_currentDate),
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "${litersToday.toStringAsFixed(1)} L",
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "von ${(dailyGoalMl / 1000).toStringAsFixed(1)} L Tagesziel",
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progressBar,
                    minHeight: 10,
                    backgroundColor: dropBlue.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(deepBlue),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${percentDisplay.toStringAsFixed(0)}% erreicht",
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _goalButton(Icons.remove, () {
                if (dailyGoalMl > 400) {
                  setState(() => dailyGoalMl -= 200);
                  _saveGoal();
                }
              }),
              const SizedBox(width: 12),
              Text(
                "${(dailyGoalMl / 1000).toStringAsFixed(1)} L Ziel",
                style: const TextStyle(
                  fontFamily: "Cinzel",
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              _goalButton(Icons.add, () {
                setState(() => dailyGoalMl += 200);
                _saveGoal();
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _goalButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.black87,
        ),
      ),
    );
  }

  // HERZEN
  Widget _glassesSection() {
    final itemCount = waterCount + 5 < 20 ? 20 : waterCount + 5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Gläser heute",
            style: TextStyle(
              fontFamily: "NewFirst",
              fontSize: 24,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "$waterCount Gläser (à $glassMl ml)",
            style: const TextStyle(
              fontFamily: "Cinzel",
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
            ),
            itemBuilder: (context, i) {
              final filled = i < waterCount;
              return GestureDetector(
                onTap: () => _toggleGlass(i),
                child: AnimatedScale(
                  scale: isPopping[i] ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(
                      color: filled ? dropBlue.withOpacity(0.5) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: filled ? deepBlue : Colors.black12,
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        filled ? "💙" : "🤍",
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // REMINDER
  Widget _reminderBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!reminderEnabled) return;
              setState(() => _showReminderDetails = !_showReminderDetails);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Wasser‑Reminder",
                  style: TextStyle(
                    fontFamily: "NewFirst",
                    fontSize: 22,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    if (reminderEnabled)
                      Icon(
                        _showReminderDetails
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.black54,
                      ),
                    Switch(
                      value: reminderEnabled,
                      activeColor: dropBlue,
                      onChanged: (v) {
                        setState(() {
                          reminderEnabled = v;
                          _showReminderDetails = false;
                        });
                        _saveReminderSettings();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: (reminderEnabled && _showReminderDetails)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "Modus",
                        style: TextStyle(
                          fontFamily: "Cinzel",
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text("Stündlich"),
                            selected: reminderMode == "hourly",
                            onSelected: (_) {
                              setState(() {
                                reminderMode = "hourly";
                                _showReminderDetails = false;
                              });
                              _saveReminderSettings();
                            },
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: const Text("Früh / Mittag / Abend"),
                            selected: reminderMode == "times",
                            onSelected: (_) {
                              setState(() {
                                reminderMode = "times";
                                _showReminderDetails = false;
                              });
                              _saveReminderSettings();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (reminderMode == "hourly") ...[
                        Text(
                          "Intervall: $intervalMinutes Minuten",
                          style: const TextStyle(
                            fontFamily: "Cinzel",
                            fontSize: 15,
                          ),
                        ),
                        Slider(
                          value: intervalMinutes.toDouble(),
                          min: 30,
                          max: 180,
                          divisions: 5,
                          label: "$intervalMinutes min",
                          onChanged: (v) {
                            setState(() => intervalMinutes = v.toInt());
                            _saveReminderSettings();
                          },
                        ),
                      ],
                      if (reminderMode == "times") ...[
                        _timePickerRow("Morgens", morningTime, (v) {
                          setState(() => morningTime = v);
                          _saveReminderSettings();
                        }),
                        _timePickerRow("Mittags", noonTime, (v) {
                          setState(() => noonTime = v);
                          _saveReminderSettings();
                        }),
                        _timePickerRow("Abends", eveningTime, (v) {
                          setState(() => eveningTime = v);
                          _saveReminderSettings();
                        }),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _timePickerRow(
      String label, String time, Function(String) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Cinzel",
            fontSize: 15,
          ),
        ),
        TextButton(
          onPressed: () async {
            final parts = time.split(":");
            final initial = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );

            final picked = await showTimePicker(
              context: context,
              initialTime: initial,
            );

            if (picked != null) {
              final newTime =
                  "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
              onChanged(newTime);
            }
          },
          child: Text(
            time,
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 15,
              color: deepBlue,
            ),
          ),
        ),
      ],
    );
  }

  // WASSERKURVE
  Widget _waterCurve() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Wasserkurve",
            style: TextStyle(
              fontFamily: "NewFirst",
              fontSize: 22,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<FlSpot>>(
            future: _buildWaterCurve(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final spots = snapshot.data!;
              if (spots.isEmpty) {
                return const SizedBox(
                  height: 160,
                  child: Center(
                    child: Text(
                      "Noch keine Daten für die letzten Tage.",
                      style: TextStyle(
                        fontFamily: "Cinzel",
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: spots.length.toDouble() - 1,
                    minY: 0,
                    maxY: (dailyGoalMl / 1000) + 1,
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 0.5,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= 7) {
                              return const SizedBox.shrink();
                            }
                            final day =
                                _currentDate.subtract(Duration(days: 6 - index));
                            return Text(
                              "${day.day}.${day.month}",
                              style: const TextStyle(
                                fontFamily: "Cinzel",
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: deepBlue,
                        barWidth: 4,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<List<FlSpot>> _buildWaterCurve() async {
    List<FlSpot> spots = [];

    for (int i = 6; i >= 0; i--) {
      final day = _currentDate.subtract(Duration(days: i));
      final count = await _loadDayValue(day);
      final liters = (count * glassMl) / 1000;
      spots.add(FlSpot((6 - i).toDouble(), liters));
    }

    return spots;
  }

  // WOCHENÜBERSICHT
  Widget _historyAndWeek() {
    final now = _currentDate;
    final start = now.subtract(const Duration(days: 3));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Deine letzten Tage",
            style: TextStyle(
              fontFamily: "NewFirst",
              fontSize: 22,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(7, (i) {
                final day = start.add(Duration(days: i));
                final isSelected = day.day == now.day &&
                    day.month == now.month &&
                    day.year == now.year;

                return GestureDetector(
                  onTap: () async {
                    await _loadWaterFor(day);
                  },
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? dropBlue.withOpacity(0.4)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? deepBlue : Colors.black12,
                          ),
                        ),
                        child: Text(
                          "${day.day}",
                          style: const TextStyle(
                            fontFamily: "Cinzel",
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<int>(
                        future: _loadDayValue(day),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          final liters = (count * glassMl) / 1000;
                          return Text(
                            "${liters.toStringAsFixed(1)} L",
                            style: const TextStyle(
                              fontFamily: "Cinzel",
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Wochenauswertung",
            style: TextStyle(
              fontFamily: "NewFirst",
              fontSize: 22,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final day = now.subtract(Duration(days: 6 - i));

              return GestureDetector(
                onTap: () async {
                  await _loadWaterFor(day);
                },
                child: FutureBuilder<int>(
                  future: _loadDayValue(day),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    final liters = (count * glassMl) / 1000;

                    final isSelected = day.day == now.day &&
                        day.month == now.month &&
                        day.year == now.year;

                    return Column(
                      children: [
                        Text(
                          "${day.day}.${day.month}",
                          style: const TextStyle(
                            fontFamily: "Cinzel",
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: (liters * 40).clamp(4, 80),
                          width: 12,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? deepBlue.withOpacity(0.9)
                                : dropBlue.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${liters.toStringAsFixed(1)} L",
                          style: const TextStyle(
                            fontFamily: "Cinzel",
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
