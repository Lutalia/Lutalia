import 'package:flutter/material.dart';

class CycleWorkoutsScreen extends StatefulWidget {
  const CycleWorkoutsScreen({super.key});

  @override
  State<CycleWorkoutsScreen> createState() => _CycleWorkoutsScreenState();
}

class _CycleWorkoutsScreenState extends State<CycleWorkoutsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color roseLight = const Color(0xFFF3C9D8);
  final Color roseMid   = const Color(0xFFE8AFC4);
  final Color roseDark  = const Color(0xFFD9A2B8);
  final Color roseDeep  = const Color(0xFFC98FA8);
  final Color latteBg   = const Color(0xFFF4E6DE);
  final Color latteText = const Color(0xFFD19884);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: latteBg,
      appBar: AppBar(
        backgroundColor: roseLight,
        elevation: 0,
        title: const Text(
          "Zyklusbasierte Workouts",
          style: TextStyle(
            fontFamily: "Cinzel",
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Menstruation"),
            Tab(text: "Follikel"),
            Tab(text: "Ovulation"),
            Tab(text: "Luteal"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _phase(
            title: "Menstruationsphase",
            color: roseLight,
            tendencies: [
              "• Energie kann niedriger sein",
              "• Körper braucht Wärme & Ruhe",
              "• Sanfte Bewegung tut gut",
            ],
            workouts: [
              "• Spaziergänge",
              "• Yin Yoga",
              "• Stretching",
              "• Atemübungen",
            ],
            affirmations: [
              "Ich bewege mich sanft und achtsam.",
              "Mein Körper darf sich erholen.",
            ],
          ),
          _phase(
            title: "Follikelphase",
            color: roseMid,
            tendencies: [
              "• Energie steigt",
              "• Motivation & Leichtigkeit",
              "• Gute Zeit für Aufbau",
            ],
            workouts: [
              "• Krafttraining (leicht–mittel)",
              "• Pilates",
              "• Cardio moderat",
              "• Mobility",
            ],
            affirmations: [
              "Ich wachse über mich hinaus.",
              "Ich fühle mich stark und klar.",
            ],
          ),
          _phase(
            title: "Ovulationsphase",
            color: roseDark,
            tendencies: [
              "• Peak‑Energie",
              "• Kraft & Ausdauer hoch",
              "• Gute Zeit für intensivere Einheiten",
            ],
            workouts: [
              "• Intensiveres Krafttraining",
              "• HIIT (wenn es sich gut anfühlt)",
              "• Power‑Pilates",
              "• Cardio stärker",
            ],
            affirmations: [
              "Ich strahle Kraft aus.",
              "Ich nutze meine Energie bewusst.",
            ],
          ),
          _phase(
            title: "Lutealphase",
            color: roseDeep,
            tendencies: [
              "• Energie sinkt langsam",
              "• Bedürfnis nach Ruhe & Struktur",
              "• Sanftere Workouts passen gut",
            ],
            workouts: [
              "• Walking",
              "• Leichtes Krafttraining",
              "• Yoga & Mobility",
              "• Entspannende Bewegung",
            ],
            affirmations: [
              "Ich höre auf meinen Körper.",
              "Ich schenke mir Balance und Ruhe.",
            ],
          ),
        ],
      ),
    );
  }

  Widget _phase({
    required String title,
    required Color color,
    required List<String> tendencies,
    required List<String> workouts,
    required List<String> affirmations,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, color),
          const SizedBox(height: 20),

          _subTitle("Körperliche Tendenzen"),
          _card(tendencies),

          const SizedBox(height: 20),

          _subTitle("Workout‑Ideen"),
          _card(workouts),

          const SizedBox(height: 20),

          _subTitle("Affirmationen"),
          _card(affirmations),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: "Cinzel",
          fontSize: 22,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _subTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: "Cinzel",
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: latteText,
      ),
    );
  }

  Widget _card(List<String> items) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  e,
                  style: const TextStyle(
                    fontFamily: "NewFirst",
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
