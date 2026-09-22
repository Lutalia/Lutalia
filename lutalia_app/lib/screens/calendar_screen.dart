import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'daily_overview_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late DateTime currentMonth;
  late AnimationController pulseController;

  @override
  void initState() {
    super.initState();
    currentMonth = DateTime.now();

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    pulseController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // 🔥 Firestore: Kalorien für einen Tag laden
  // ------------------------------------------------------------
  Future<int> _loadCaloriesForDay(String key) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("meals")
        .doc(key)
        .get();

    if (!doc.exists) return 0;

    final data = doc.data() ?? {};
    int total = 0;

    for (final meal in ["breakfast", "lunch", "dinner", "snacks"]) {
      final list = List<Map<String, dynamic>>.from(data[meal] ?? []);
      for (var item in list) {
        total += int.tryParse(item["kcal"].toString()) ?? 0;
      }
    }

    return total;
  }

  // ------------------------------------------------------------
  // 🔥 Heatmap-Farben
  // ------------------------------------------------------------
  Color _heatColor(int kcal) {
    if (kcal == 0) return const Color(0xFFF7F3ED);
    if (kcal < 400) return const Color(0xFFE8E0D6);
    if (kcal < 800) return const Color(0xFFD6C8BA);
    return const Color(0xFFB8A999);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);

    final todayKey = "${now.year}-${now.month}-${now.day}";

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF9F4FF),
              Color(0xFFCFE8D6),
              Color(0xFFF4E6DE),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Column(
          children: [
            const SizedBox(height: 50),

            // HEADER
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    "Tracking",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Cinzel",
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),

            const SizedBox(height: 20),

            // MONAT
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      currentMonth =
                          DateTime(currentMonth.year, currentMonth.month - 1, 1);
                    });
                  },
                ),
                Text(
                  "${_monthName(currentMonth.month)} ${currentMonth.year}",
                  style: const TextStyle(
                    fontFamily: "NewFirst",
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      currentMonth =
                          DateTime(currentMonth.year, currentMonth.month + 1, 1);
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 80),

            // BOX
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EFE7),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB8A999).withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: FutureBuilder(
                future: _buildCalendar(todayKey, firstDay, lastDay),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    );
                  }
                  return snapshot.data!;
                },
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "⋆⁺₊⋆ ☾⋆⁺₊⋆ ✧⋆⁺₊⋆ ☾⋆⁺₊⋆",
              style: TextStyle(
                fontFamily: "Cinzel",
                fontSize: 26,
                color: Color(0xFFCFE8D6),
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 🔥 Kalender-Grid mit Firestore-Daten
  // ------------------------------------------------------------
  Future<Widget> _buildCalendar(
      String todayKey, DateTime firstDay, DateTime lastDay) async {
    final daysInMonth = lastDay.day;

    List<int> kcalList = [];
    for (int day = 1; day <= daysInMonth; day++) {
      final key = "${currentMonth.year}-${currentMonth.month}-$day";
      kcalList.add(await _loadCaloriesForDay(key));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _WeekdayWithIcon("Mo", "✦"),
            _WeekdayWithIcon("Di", "❀"),
            _WeekdayWithIcon("Mi", "✧"),
            _WeekdayWithIcon("Do", "•"),
            _WeekdayWithIcon("Fr", "✦"),
            _WeekdayWithIcon("Sa", "✨"),
            _WeekdayWithIcon("So", "☾"),
          ],
        ),

        const SizedBox(height: 20),

        SizedBox(
          height: 300,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final day = index + 1;
              final dateKey =
                  "${currentMonth.year}-${currentMonth.month}-$day";

              final isToday = dateKey == todayKey;
              final kcal = kcalList[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DailyOverviewScreen(dateKey: dateKey),
                    ),
                  );
                },
                child: ScaleTransition(
                  scale: isToday
                      ? pulseController
                      : const AlwaysStoppedAnimation(1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _heatColor(kcal),
                      borderRadius: BorderRadius.circular(14),
                      border: isToday
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isToday ? "❤\n$day" : "$day",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Cinzel",
                        fontSize: isToday ? 15 : 18,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w500,
                        color: Colors.black,
                        height: 1.05,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _monthName(int m) {
    const months = [
      "",
      "Januar",
      "Februar",
      "März",
      "April",
      "Mai",
      "Juni",
      "Juli",
      "August",
      "September",
      "Oktober",
      "November",
      "Dezember"
    ];
    return months[m];
  }
}

class _WeekdayWithIcon extends StatelessWidget {
  final String label;
  final String icon;
  const _WeekdayWithIcon(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Cinzel",
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          icon,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
