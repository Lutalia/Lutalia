import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class MenstruationTrackingScreen extends StatefulWidget {
  const MenstruationTrackingScreen({super.key});

  @override
  State<MenstruationTrackingScreen> createState() =>
      _MenstruationTrackingScreenState();
}

class _MenstruationTrackingScreenState
    extends State<MenstruationTrackingScreen> {
  final Color roseLight = const Color(0xFFF3C9D8);
  final Color roseMid = const Color(0xFFE8AFC4);
  final Color roseDark = const Color(0xFFD9A2B8);
  final Color roseDeep = const Color(0xFFC98FA8);
  final Color latteBg = const Color(0xFFF4E6DE);
  final Color latteText = const Color(0xFFD19884);

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool isPeriod = false;
  int mood = 3; // 1–5
  int energy = 3; // 1–5
  TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDayData(DateTime.now());
  }

  Future<void> _loadDayData(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(day);

    setState(() {
      isPeriod = prefs.getBool("${key}_period") ?? false;
      mood = prefs.getInt("${key}_mood") ?? 3;
      energy = prefs.getInt("${key}_energy") ?? 3;
      notesController.text = prefs.getString("${key}_notes") ?? "";
    });
  }

  Future<void> _saveDayData() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(_selectedDay ?? DateTime.now());

    await prefs.setBool("${key}_period", isPeriod);
    await prefs.setInt("${key}_mood", mood);
    await prefs.setInt("${key}_energy", energy);
    await prefs.setString("${key}_notes", notesController.text);
  }

  String _key(DateTime day) =>
      "${day.year}-${day.month}-${day.day}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: latteBg,
      appBar: AppBar(
        backgroundColor: roseLight,
        elevation: 0,
        title: const Text(
          "Menstruation Tracking",
          style: TextStyle(
            fontFamily: "Cinzel",
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _buildCalendar(),
          const SizedBox(height: 20),
          _buildPeriodToggle(),
          const SizedBox(height: 20),
          _buildSlider("Stimmung", mood, (v) => setState(() => mood = v)),
          const SizedBox(height: 20),
          _buildSlider("Energie", energy, (v) => setState(() => energy = v)),
          const SizedBox(height: 20),
          _buildNotes(),
          const SizedBox(height: 30),
          _saveButton(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ⭐ KALENDER
  // ------------------------------------------------------------
  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: roseLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) =>
            isSameDay(_selectedDay, day),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
          _loadDayData(selected);
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: roseMid,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: roseDark,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: roseDeep,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(
            fontFamily: "Cinzel",
            fontSize: 18,
            color: latteText,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ⭐ PERIODE STARTEN / BEENDEN
  // ------------------------------------------------------------
  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: roseMid, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Periode",
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 18,
              color: latteText,
            ),
          ),
          const SizedBox(height: 10),
          Switch(
            activeColor: roseDark,
            value: isPeriod,
            onChanged: (v) {
              setState(() => isPeriod = v);
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ⭐ SLIDER (Stimmung & Energie)
  // ------------------------------------------------------------
  Widget _buildSlider(String title, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: roseMid, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 18,
              color: latteText,
            ),
          ),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: roseDark,
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ⭐ NOTIZEN
  // ------------------------------------------------------------
  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: roseMid, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Notizen",
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 18,
              color: latteText,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Wie fühlst du dich heute?",
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ⭐ SPEICHERN BUTTON
  // ------------------------------------------------------------
  Widget _saveButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: roseDark,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: () async {
        await _saveDayData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Gespeichert"),
            backgroundColor: roseDark,
          ),
        );
      },
      child: const Text(
        "Speichern",
        style: TextStyle(
          fontFamily: "Cinzel",
          fontSize: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}
