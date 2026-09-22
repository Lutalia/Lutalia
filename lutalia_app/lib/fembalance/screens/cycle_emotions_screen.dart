import 'package:flutter/material.dart';

class CycleEmotionsScreen extends StatefulWidget {
  const CycleEmotionsScreen({super.key});

  @override
  State<CycleEmotionsScreen> createState() => _CycleEmotionsScreenState();
}

class _CycleEmotionsScreenState extends State<CycleEmotionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color roseLight = const Color(0xFFF3C9D8);
  final Color roseMid = const Color(0xFFE8AFC4);
  final Color roseDark = const Color(0xFFD9A2B8);
  final Color roseDeep = const Color(0xFFC98FA8);
  final Color latteBg = const Color(0xFFF4E6DE);
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
          "Zyklusbasierte Emotionen",
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
          _emotionPhase(
            title: "Menstruationsphase",
            color: roseLight,
            emotions: [
              "• Rückzug & Ruhebedürfnis",
              "• Emotionale Sensibilität",
              "• Wunsch nach Geborgenheit",
              "• Klarheit über Grenzen",
            ],
            affirmations: [
              "Ich darf mich ausruhen.",
              "Mein Körper arbeitet für mich.",
              "Ich bin sanft zu mir.",
            ],
            journaling: [
              "Was brauche ich heute wirklich?",
              "Was kann ich loslassen?",
            ],
          ),
          _emotionPhase(
            title: "Follikelphase",
            color: roseMid,
            emotions: [
              "• Motivation & Aufbruch",
              "• Kreativität & Leichtigkeit",
              "• Optimismus",
              "• Neugier & Offenheit",
            ],
            affirmations: [
              "Ich wachse jeden Tag.",
              "Ich bin voller Energie.",
              "Ich vertraue meinem Weg.",
            ],
            journaling: [
              "Welche Ziele möchte ich diese Woche angehen?",
              "Was inspiriert mich gerade?",
            ],
          ),
          _emotionPhase(
            title: "Ovulationsphase",
            color: roseDark,
            emotions: [
              "• Selbstbewusstsein",
              "• Soziale Energie",
              "• Kommunikationsfreude",
              "• Klarheit & Stärke",
            ],
            affirmations: [
              "Ich strahle von innen.",
              "Ich bin kraftvoll und klar.",
              "Ich darf gesehen werden.",
            ],
            journaling: [
              "Was möchte ich heute ausdrücken?",
              "Wofür bin ich dankbar?",
            ],
          ),
          _emotionPhase(
            title: "Lutealphase",
            color: roseDeep,
            emotions: [
              "• Bedürfnis nach Struktur",
              "• Reizbarkeit möglich",
              "• Wunsch nach Rückzug",
              "• Intuition & Tiefe",
            ],
            affirmations: [
              "Ich nehme meine Gefühle ernst.",
              "Ich darf langsamer werden.",
              "Ich vertraue meiner Intuition.",
            ],
            journaling: [
              "Was belastet mich gerade?",
              "Was kann ich mir Gutes tun?",
            ],
          ),
        ],
      ),
    );
  }

  Widget _emotionPhase({
    required String title,
    required Color color,
    required List<String> emotions,
    required List<String> affirmations,
    required List<String> journaling,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, color),
          const SizedBox(height: 20),

          _subTitle("Emotionale Tendenzen"),
          _card(emotions),

          const SizedBox(height: 20),

          _subTitle("Affirmationen"),
          _card(affirmations),

          const SizedBox(height: 20),

          _subTitle("Journaling‑Impulse"),
          _card(journaling),

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
