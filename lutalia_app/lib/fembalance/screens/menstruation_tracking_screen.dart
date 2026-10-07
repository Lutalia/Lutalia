import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    fln.FlutterLocalNotificationsPlugin();

class MenstruationTrackingScreen extends StatefulWidget {
  const MenstruationTrackingScreen({super.key});

  @override
  State<MenstruationTrackingScreen> createState() =>
      _MenstruationTrackingScreenState();
}

class _MenstruationTrackingScreenState
    extends State<MenstruationTrackingScreen> {
  // Exakte Lutalia Brand-Farben aus dem Dokument
  final Color bgCream = const Color(0xFFF7F3EF);
  final Color cardWarmBg = const Color(0xFFFDFCFA);
  final Color cardInnerBg = const Color(0xFFF0EBE3);
  final Color primaryEarth = const Color(0xFF6E5C4E);
  final Color lutaliaSand = const Color(0xFFD3C8BD);
  final Color lutaliaTerracotta = const Color(0xFFCAAF9F);
  final Color lutaliaGold = const Color(0xFFC29B61);
  final Color fertileColor = const Color(0xFF8C7365);

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<String, Map<String, dynamic>> _firebaseData = {};
  bool _takesPill = false;
  String _pillReminderTime = "08:00";
  int _avgCycleLength = 28;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadUserSettingsAndData();
  }

  Future<void> _initNotifications() async {
    tz.initializeTimeZones();
    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (fln.NotificationResponse response) {
        _triggerPillPopupSafe(DateTime.now());
      },
    );
  }

  void _triggerPillPopupSafe(DateTime day) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showPillReminderPopup(day);
      }
    });
  }

  Future<void> _schedulePillNotification(String timeStr) async {
    try {
      await _cancelPillNotification();
      final parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      const fln.AndroidNotificationDetails androidPlatformChannelSpecifics =
          fln.AndroidNotificationDetails(
        'lutalia_pill_channel',
        'Pillen-Erinnerung',
        channelDescription: 'Erinnert dich täglich daran, deine Pille zu nehmen',
        importance: fln.Importance.max,
        priority: fln.Priority.high,
      );
      const fln.NotificationDetails platformChannelSpecifics =
          fln.NotificationDetails(android: androidPlatformChannelSpecifics);
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Pillen-Zeit ✨',
        'Zeit für deine kleine Gesundheits-Routine. Schenk dir selbst einen Moment der Fürsorge! 🌸',
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            fln.UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: fln.DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint("Fehler beim Planen der Benachrichtigung: $e");
    }
  }

  Future<void> _cancelPillNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  String _formatDate(DateTime day) =>
      "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

  Future<void> _loadUserSettingsAndData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      setState(() {
        _takesPill = userDoc.data()?['takesPill'] ?? false;
        _pillReminderTime = userDoc.data()?['pillReminderTime'] ?? "08:00";
        _avgCycleLength = userDoc.data()?['avgCycleLength'] ?? 28;
      });
    }
    final querySnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cycle_entries')
        .get();
    Map<String, Map<String, dynamic>> loadedData = {};
    for (var doc in querySnapshot.docs) {
      loadedData[doc.id] = doc.data();
    }
    setState(() {
      _firebaseData = loadedData;
    });
    if (_takesPill) {
      final todayKey = _formatDate(DateTime.now());
      final todayData = loadedData[todayKey] ?? {};
      if (todayData['tookPill'] != true) {
        _triggerPillPopupSafe(DateTime.now());
      }
    }
  }

  bool _isCalculatedPeriod(DateTime day) {
    List<String> startkeys = _firebaseData.entries
        .where((e) => e.value['isStart'] == true)
        .map((e) => e.key)
        .toList()
      ..sort();
    if (startkeys.isEmpty) return false;
    DateTime lastStart = DateTime.parse(startkeys.last);
    for (int i = 0; i < 12; i++) {
      DateTime nextStart = lastStart.add(Duration(days: _avgCycleLength * i));
      for (int d = 0; d < 5; d++) {
        if (isSameDay(nextStart.add(Duration(days: d)), day)) return true;
      }
    }
    return false;
  }

  bool _isExactOvulation(DateTime day) {
    List<String> startkeys = _firebaseData.entries
        .where((e) => e.value['isStart'] == true)
        .map((e) => e.key)
        .toList()
      ..sort();
    if (startkeys.isEmpty) return false;
    DateTime lastStart = DateTime.parse(startkeys.last);
    for (int i = 0; i < 12; i++) {
      DateTime nextStart = lastStart.add(Duration(days: _avgCycleLength * i));
      DateTime ovulation = nextStart.add(Duration(days: (_avgCycleLength - 14)));
      if (isSameDay(ovulation, day)) return true;
    }
    return false;
  }

  bool _isFertileWindow(DateTime day) {
    List<String> startkeys = _firebaseData.entries
        .where((e) => e.value['isStart'] == true)
        .map((e) => e.key)
        .toList()
      ..sort();
    if (startkeys.isEmpty) return false;
    DateTime lastStart = DateTime.parse(startkeys.last);
    for (int i = 0; i < 12; i++) {
      DateTime nextStart = lastStart.add(Duration(days: _avgCycleLength * i));
      DateTime ovulation = nextStart.add(Duration(days: (_avgCycleLength - 14)));
      for (int f = 0; f <= 5; f++) {
        DateTime fertileDay = ovulation.subtract(Duration(days: f));
        if (isSameDay(fertileDay, day)) return true;
      }
    }
    return false;
  }

  void _showPillReminderPopup(DateTime day) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardWarmBg,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: lutaliaSand, width: 1.2),
          ),
          title: Row(
            children: [
              Icon(Icons.auto_awesome, color: lutaliaTerracotta, size: 24),
              const SizedBox(width: 12),
              Text(
                "Pillen-Zeit ✨",
                style: TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryEarth),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardInnerBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "„Zeit für deine kleine Gesundheits-Routine. Schenk dir selbst einen Moment der Fürsorge! 🌸“",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        color: primaryEarth,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Hast du heute deine Pille genommen?",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryEarth),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: lutaliaSand, width: 1.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text("Nein",
                  style: TextStyle(
                      color: primaryEarth,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: lutaliaTerracotta,
                foregroundColor: primaryEarth,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                final user = _auth.currentUser;
                final key = _formatDate(day);
                if (user != null) {
                  final existing = _firebaseData[key] ?? {};
                  final newData = {...existing, 'tookPill': true};
                  await _firestore
                      .collection('users')
                      .doc(user.uid)
                      .collection('cycle_entries')
                      .doc(key)
                      .set(newData, SetOptions(merge: true));
                  setState(() {
                    _firebaseData[key] = newData;
                  });
                }
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("Pille erfolgreich eingetragen! 💊✨",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                      backgroundColor: primaryEarth),
                );
              },
              child: const Text("Ja, genommen 💊",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openDayDialog(DateTime day) async {
    final key = _formatDate(day);
    final dayData = _firebaseData[key] ?? {};
    bool isStart = dayData['isStart'] ?? false;
    bool isEnd = dayData['isEnd'] ?? false;
    bool isManualPeriod = dayData['isManualPeriod'] ?? false;
    bool hadIntercourse = dayData['hadIntercourse'] ?? false;
    bool tookPillToday = dayData['tookPill'] ?? false;
    int? mood = dayData['mood'];
    int? energy = dayData['energy'];
    int? sleep = dayData['sleep'];
    int? stress = dayData['stress'];
    bool cramps = dayData['cramps'] ?? false;
    bool headache = dayData['headache'] ?? false;
    bool bloating = dayData['bloating'] ?? false;
    bool cravings = dayData['cravings'] ?? false;
    final TextEditingController otherSymptomsController =
        TextEditingController(text: dayData['otherSymptoms'] ?? "");
    String formattedDateStr = "${day.day}.${day.month}.${day.year}";

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardWarmBg,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: lutaliaSand, width: 1.2),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration:
                        BoxDecoration(color: cardInnerBg, shape: BoxShape.circle),
                    child: Icon(Icons.calendar_today,
                        size: 20, color: lutaliaTerracotta),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      "Tageseintrag: $formattedDateStr",
                      style: TextStyle(
                          fontFamily: "Cinzel",
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryEarth),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.95,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDialogSectionContainer(
                        icon: Icons.water_drop,
                        title: "ZYKLUS & INTIMITÄT",
                        children: [
                          CheckboxListTile(
                            title: Text("Beginn der Periode",
                                style: _itemTextStyle()),
                            value: isStart,
                            activeColor: lutaliaTerracotta,
                            checkColor: primaryEarth,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) =>
                                setDialogState(() => isStart = v ?? false),
                          ),
                          CheckboxListTile(
                            title: Text("Ende der Periode",
                                style: _itemTextStyle()),
                            value: isEnd,
                            activeColor: lutaliaTerracotta,
                            checkColor: primaryEarth,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) =>
                                setDialogState(() => isEnd = v ?? false),
                          ),
                          CheckboxListTile(
                            title: Text("Manueller Blutungstag",
                                style: _itemTextStyle()),
                            value: isManualPeriod,
                            activeColor: lutaliaTerracotta,
                            checkColor: primaryEarth,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) => setDialogState(
                                () => isManualPeriod = v ?? false),
                          ),
                          CheckboxListTile(
                            title: Row(
                              children: [
                                Text("Geschlechtsverkehr",
                                    style: _itemTextStyle()),
                                const SizedBox(width: 8),
                                Icon(Icons.favorite,
                                    size: 16, color: lutaliaTerracotta),
                              ],
                            ),
                            value: hadIntercourse,
                            activeColor: lutaliaTerracotta,
                            checkColor: primaryEarth,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) => setDialogState(
                                () => hadIntercourse = v ?? false),
                          ),
                        ],
                      ),
                      if (_takesPill) ...[
                        const SizedBox(height: 16),
                        _buildDialogSectionContainer(
                          icon: Icons.medication,
                          title: "PILLEN-ERINNERUNG ($_pillReminderTime)",
                          trailing: TextButton(
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(40, 30)),
                            onPressed: () {
                              Navigator.pop(context);
                              _showPillReminderPopup(day);
                            },
                            child: Text("Testen",
                                style: TextStyle(
                                    fontSize: 14,
                                    color: lutaliaTerracotta,
                                    fontWeight: FontWeight.bold)),
                          ),
                          children: [
                            CheckboxListTile(
                              title: Text("Heute eingenommen",
                                  style: _itemTextStyle()),
                              value: tookPillToday,
                              activeColor: lutaliaTerracotta,
                              checkColor: primaryEarth,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setDialogState(
                                  () => tookPillToday = v ?? false),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildDialogSectionContainer(
                        icon: Icons.spa,
                        title: "WOHLBEFINDEN",
                        children: [
                          const SizedBox(height: 8),
                          _dialogSlider("Stimmung", mood,
                              (v) => setDialogState(() => mood = v)),
                          const SizedBox(height: 10),
                          _dialogSlider("Energie", energy,
                              (v) => setDialogState(() => energy = v)),
                          const SizedBox(height: 10),
                          _dialogSlider("Schlafqualität", sleep,
                              (v) => setDialogState(() => sleep = v)),
                          const SizedBox(height: 10),
                          _dialogSlider("Stresslevel", stress,
                              (v) => setDialogState(() => stress = v)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDialogSectionContainer(
                        icon: Icons.healing,
                        title: "SYMPTOME",
                        children: [
                          CheckboxListTile(
                              title: Text("Krämpfe / Unterleib",
                                  style: _itemTextStyle()),
                              value: cramps,
                              activeColor: lutaliaTerracotta,
                              checkColor: primaryEarth,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) =>
                                  setDialogState(() => cramps = v ?? false)),
                          CheckboxListTile(
                              title: Text("Kopfschmerzen",
                                  style: _itemTextStyle()),
                              value: headache,
                              activeColor: lutaliaTerracotta,
                              checkColor: primaryEarth,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) =>
                                  setDialogState(() => headache = v ?? false)),
                          CheckboxListTile(
                              title: Text("Blähbauch", style: _itemTextStyle()),
                              value: bloating,
                              activeColor: lutaliaTerracotta,
                              checkColor: primaryEarth,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) =>
                                  setDialogState(() => bloating = v ?? false)),
                          CheckboxListTile(
                              title: Text("Heißhunger", style: _itemTextStyle()),
                              value: cravings,
                              activeColor: lutaliaTerracotta,
                              checkColor: primaryEarth,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) =>
                                  setDialogState(() => cravings = v ?? false)),
                          const SizedBox(height: 12),
                          Text("Sonstige Symptome",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: primaryEarth,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: otherSymptomsController,
                            style: TextStyle(color: primaryEarth, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: "z.B. Brustspannen...",
                              hintStyle: TextStyle(
                                  color: primaryEarth.withValues(alpha: 0.4)),
                              filled: true,
                              fillColor: cardWarmBg,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: lutaliaSand.withValues(alpha: 0.6))),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: lutaliaSand.withValues(alpha: 0.6))),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Abbrechen",
                      style: TextStyle(
                          color: primaryEarth,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lutaliaTerracotta,
                    foregroundColor: primaryEarth,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                  ),
                  onPressed: () async {
                    final user = _auth.currentUser;
                    if (user == null) return;
                    final existing = _firebaseData[key] ?? {};
                    final Map<String, dynamic> newData = {
                      ...existing,
                      'isStart': isStart,
                      'isEnd': isEnd,
                      'isManualPeriod': isManualPeriod,
                      'hadIntercourse': hadIntercourse,
                      'tookPill': tookPillToday,
                      'cramps': cramps,
                      'headache': headache,
                      'bloating': bloating,
                      'cravings': cravings,
                      'otherSymptoms': otherSymptomsController.text,
                    };
                    if (mood != null) newData['mood'] = mood;
                    if (energy != null) newData['energy'] = energy;
                    if (sleep != null) newData['sleep'] = sleep;
                    if (stress != null) newData['stress'] = stress;
                    await _firestore
                        .collection('users')
                        .doc(user.uid)
                        .collection('cycle_entries')
                        .doc(key)
                        .set(newData, SetOptions(merge: true));
                    setState(() {
                      _firebaseData[key] = newData;
                    });
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("Eintrag gespeichert ✨",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w500)),
                          backgroundColor: primaryEarth),
                    );
                  },
                  child: const Text("Speichern",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogSectionContainer({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardInnerBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lutaliaSand.withValues(alpha: 0.7), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: lutaliaTerracotta),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: "Cinzel",
                    fontWeight: FontWeight.bold,
                    color: primaryEarth,
                    fontSize: 14,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFDCCFC3)),
          ),
          ...children,
        ],
      ),
    );
  }

  void _openNoteDialog() async {
    final key = _formatDate(_selectedDay);
    final dayData = _firebaseData[key] ?? {};
    final TextEditingController noteController =
        TextEditingController(text: dayData['notes'] ?? "");

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardWarmBg,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: lutaliaSand, width: 1.2),
          ),
          title: Text(
            "Notiz hinzufügen",
            style: TextStyle(
                fontFamily: "Cinzel",
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryEarth),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: TextField(
              controller: noteController,
              maxLines: 4,
              style: TextStyle(color: primaryEarth, fontSize: 15),
              decoration: InputDecoration(
                hintText: "Gedanken, Notizen zum Tag...",
                hintStyle:
                    TextStyle(color: primaryEarth.withValues(alpha: 0.4)),
                filled: true,
                fillColor: cardInnerBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: lutaliaSand.withValues(alpha: 0.6))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: lutaliaSand.withValues(alpha: 0.6))),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Abbrechen",
                  style: TextStyle(
                      color: primaryEarth,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: lutaliaTerracotta,
                foregroundColor: primaryEarth,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              onPressed: () async {
                final user = _auth.currentUser;
                if (user == null) return;
                final existing = _firebaseData[key] ?? {};
                final newData = {
                  ...existing,
                  'notes': noteController.text,
                };
                await _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('cycle_entries')
                    .doc(key)
                    .set(newData, SetOptions(merge: true));
                setState(() {
                  _firebaseData[key] = newData;
                });
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text("Speichern",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openSettingsDialog() async {
    bool tempTakesPill = _takesPill;
    TimeOfDay tempTime = TimeOfDay(
      hour: int.parse(_pillReminderTime.split(':')[0]),
      minute: int.parse(_pillReminderTime.split(':')[1]),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardWarmBg,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: lutaliaSand, width: 1.2),
              ),
              title: Text(
                "Pillen-Einstellungen",
                style: TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryEarth),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: Text("Nimmst du die Pille?",
                          style: _itemTextStyle()),
                      value: tempTakesPill,
                      activeThumbColor: lutaliaTerracotta,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) =>
                          setDialogState(() => tempTakesPill = v),
                    ),
                    if (tempTakesPill) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Erinnerungszeit:", style: _itemTextStyle()),
                          TextButton(
                            onPressed: () async {
                              TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: tempTime,
                              );
                              if (picked != null) {
                                setDialogState(() => tempTime = picked);
                              }
                            },
                            child: Text(
                              "${tempTime.hour.toString().padLeft(2, '0')}:${tempTime.minute.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                  color: lutaliaTerracotta,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lutaliaTerracotta,
                    foregroundColor: primaryEarth,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: () async {
                    final user = _auth.currentUser;
                    if (user == null) return;
                    String formattedTime =
                        "${tempTime.hour.toString().padLeft(2, '0')}:${tempTime.minute.toString().padLeft(2, '0')}";
                    await _firestore.collection('users').doc(user.uid).set({
                      'takesPill': tempTakesPill,
                      'pillReminderTime': formattedTime,
                    }, SetOptions(merge: true));
                    setState(() {
                      _takesPill = tempTakesPill;
                      _pillReminderTime = formattedTime;
                    });
                    if (tempTakesPill) {
                      await _schedulePillNotification(formattedTime);
                    } else {
                      await _cancelPillNotification();
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text("Speichern",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  TextStyle _itemTextStyle() => TextStyle(
      fontSize: 15, color: primaryEarth, fontWeight: FontWeight.w600);

  Widget _dialogSlider(String title, int? value, Function(int) onChanged) {
    int displayVal = value ?? 3;
    bool hasValue = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: TextStyle(
                    color: primaryEarth,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            Text(
              hasValue ? "$displayVal / 5" : "Noch nicht eingetragen",
              style: TextStyle(
                color: hasValue
                    ? lutaliaTerracotta
                    : primaryEarth.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        Slider(
          value: displayVal.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: hasValue ? lutaliaTerracotta : lutaliaSand,
          inactiveColor: lutaliaSand.withValues(alpha: 0.4),
          onChanged: (v) => onChanged(v.toInt()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String selectedKey = _formatDate(_selectedDay);
    var d = _firebaseData[selectedKey] ?? {};
    bool isPeriod = d['isStart'] == true ||
        d['isManualPeriod'] == true ||
        _isCalculatedPeriod(_selectedDay);
    bool hadIntercourse = d['hadIntercourse'] ?? false;
    bool tookPill = d['tookPill'] ?? false;
    int? mood = d['mood'];
    int? energy = d['energy'];
    int? sleep = d['sleep'];
    int? stress = d['stress'];
    List<String> activeSymptoms = [];
    if (d['cramps'] == true) activeSymptoms.add("Krämpfe / Unterleib");
    if (d['headache'] == true) activeSymptoms.add("Kopfschmerzen");
    if (d['bloating'] == true) activeSymptoms.add("Blähbauch");
    if (d['cravings'] == true) activeSymptoms.add("Heißhunger");
    if ((d['otherSymptoms'] ?? "").toString().isNotEmpty) {
      activeSymptoms.add(d['otherSymptoms']);
    }
    String notes = d['notes'] ?? "";
    String wellbeingText = "Keine Angaben";
    List<String> wellBeingParts = [];
    if (mood != null) wellBeingParts.add("Stimmung $mood/5");
    if (energy != null) wellBeingParts.add("Energie $energy/5");
    if (sleep != null) wellBeingParts.add("Schlaf $sleep/5");
    if (stress != null) wellBeingParts.add("Stress $stress/5");
    if (wellBeingParts.isNotEmpty) {
      wellbeingText = wellBeingParts.join(" | ");
    }

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: cardWarmBg,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryEarth),
        title: Text(
          "FEMBALANCE & ZYKLUS",
          style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: primaryEarth,
              letterSpacing: 1),
        ),
        actions: [
          if (_takesPill)
            IconButton(
              icon: Icon(Icons.notifications_active, color: lutaliaTerracotta),
              onPressed: () => _showPillReminderPopup(_selectedDay),
              tooltip: "Pillen-Popup testen",
            ),
          IconButton(
            icon: Icon(Icons.settings, color: primaryEarth),
            onPressed: _openSettingsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            Text(
              "Tippe auf einen Tag im Kalender, um Daten einzutragen.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: primaryEarth.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                _legendItem(lutaliaTerracotta, "Menstruation"),
                _legendItem(fertileColor, "Fruchtbare Tage", icon: Icons.flare),
                _legendItem(lutaliaGold, "Eisprung", icon: Icons.auto_awesome),
                _legendItem(lutaliaTerracotta, "Intimität", icon: Icons.favorite),
                if (_takesPill)
                  _legendItem(lutaliaGold, "Pille", icon: Icons.medication),
              ],
            ),
            const SizedBox(height: 24),
            // Kalender-Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardWarmBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: lutaliaSand, width: 1.2),
                boxShadow: [
                  BoxShadow(
                      color: primaryEarth.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2022, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                rowHeight: 46.0,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                    _openDayDialog(selected);
                  });
                },
                eventLoader: (day) {
                  String key = _formatDate(day);
                  var data = _firebaseData[key] ?? {};
                  List<String> events = [];
                  if (data['isStart'] == true ||
                      data['isManualPeriod'] == true ||
                      _isCalculatedPeriod(day)) {
                    events.add("period");
                  }
                  if (_isExactOvulation(day)) {
                    events.add("ovulation");
                  } else if (_isFertileWindow(day)) {
                    events.add("fertile");
                  }
                  if (data['hadIntercourse'] == true) {
                    events.add("intercourse");
                  }
                  if (data['tookPill'] == true) {
                    events.add("pill");
                  }
                  return events;
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    String key = _formatDate(day);
                    var data = _firebaseData[key] ?? {};
                    bool hasEvent = (data['isStart'] == true ||
                        data['isManualPeriod'] == true ||
                        data['hadIntercourse'] == true ||
                        data['tookPill'] == true ||
                        (data['notes'] != null &&
                            (data['notes'] as String).isNotEmpty) ||
                        _isCalculatedPeriod(day) ||
                        _isExactOvulation(day) ||
                        _isFertileWindow(day));
                    if (!hasEvent) return null;
                    return Container(
                      margin: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: lutaliaTerracotta.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                            color: primaryEarth,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    return Positioned(
                      bottom: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: events.map((event) {
                          Color color = lutaliaTerracotta;
                          IconData iconData = Icons.water_drop;
                          if (event == "ovulation") {
                            color = lutaliaGold;
                            iconData = Icons.auto_awesome;
                          } else if (event == "fertile") {
                            color = fertileColor;
                            iconData = Icons.flare;
                          } else if (event == "intercourse") {
                            color = lutaliaTerracotta;
                            iconData = Icons.favorite;
                          } else if (event == "pill") {
                            color = lutaliaGold;
                            iconData = Icons.medication;
                          }
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            child: Icon(iconData, size: 11, color: color),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration:
                      BoxDecoration(color: cardInnerBg, shape: BoxShape.circle),
                  selectedDecoration:
                      BoxDecoration(color: primaryEarth, shape: BoxShape.circle),
                  defaultTextStyle: TextStyle(
                      color: primaryEarth,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  weekendTextStyle: TextStyle(
                      color: primaryEarth.withValues(alpha: 0.85),
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(
                      fontFamily: "Cinzel",
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: primaryEarth),
                  leftChevronIcon:
                      Icon(Icons.chevron_left, color: primaryEarth),
                  rightChevronIcon:
                      Icon(Icons.chevron_right, color: primaryEarth),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Übersichts-Card für den Tag
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardWarmBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: lutaliaSand, width: 1.2),
                boxShadow: [
                  BoxShadow(
                      color: primaryEarth.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Übersicht: ${_selectedDay.day}.${_selectedDay.month}.${_selectedDay.year}",
                        style: TextStyle(
                            fontFamily: "Cinzel",
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: primaryEarth),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, size: 20, color: lutaliaTerracotta),
                        onPressed: () => _openDayDialog(_selectedDay),
                        tooltip: "Tag bearbeiten",
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _summaryRow("Menstruation:", isPeriod ? "Ja" : "Nein"),
                  if (_takesPill)
                    _summaryRow(
                        "Pille genommen:", tookPill ? "Ja" : "Nein"),
                  _summaryRow(
                      "Intimität:", hadIntercourse ? "Ja ❤️" : "Keine"),
                  _summaryRow("Wohlbefinden:", wellbeingText),
                  _summaryRow(
                      "Symptome:",
                      activeSymptoms.isEmpty
                          ? "Keine eingetragen"
                          : activeSymptoms.join(", ")),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Notizen",
                          style: TextStyle(
                              fontFamily: "Cinzel",
                              fontWeight: FontWeight.bold,
                              color: primaryEarth,
                              fontSize: 15,
                              letterSpacing: 0.5)),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: cardInnerBg, shape: BoxShape.circle),
                          child: Icon(Icons.add, size: 16, color: primaryEarth),
                        ),
                        onPressed: _openNoteDialog,
                        tooltip: "Notiz hinzufügen",
                      ),
                    ],
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardInnerBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(notes,
                                style: TextStyle(
                                    color: primaryEarth,
                                    fontSize: 14,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500)),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 18, color: primaryEarth),
                            onPressed: () async {
                              final user = _auth.currentUser;
                              if (user == null) return;
                              final existing =
                                  _firebaseData[selectedKey] ?? {};
                              existing.remove('notes');
                              await _firestore
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('cycle_entries')
                                  .doc(selectedKey)
                                  .set(existing, SetOptions(merge: true));
                              setState(() {
                                _firebaseData[selectedKey] = existing;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryEarth)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 14,
                    color: primaryEarth,
                    fontWeight: FontWeight.w500,
                    height: 1.3)),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, {IconData? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon != null
            ? Icon(icon, size: 14, color: color)
            : Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: primaryEarth,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}