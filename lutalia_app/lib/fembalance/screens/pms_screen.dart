import 'package:flutter/material.dart';

class PmsScreen extends StatefulWidget {
  const PmsScreen({super.key});

  @override
  State<PmsScreen> createState() => _PmsScreenState();
}

class _PmsScreenState extends State<PmsScreen>
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: latteBg,
      appBar: AppBar(
        backgroundColor: roseLight,
        elevation: 0,
        title: const Text(
          "PMS Bereich",
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
            Tab(text: "Was ist PMS?"),
            Tab(text: "Was hilft?"),
            Tab(text: "Ernährung"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _tabContent(
            title: "Was ist PMS?",
            color: roseLight,
            items: [
              "• PMS beschreibt körperliche und emotionale Veränderungen vor der Menstruation.",
              "• Viele Frauen erleben Stimmungsschwankungen, Sensibilität oder innere Unruhe.",
              "• Auch körperliche Veränderungen wie Müdigkeit oder Spannungsgefühle sind möglich.",
              "• PMS ist individuell – jede Frau erlebt es anders.",
            ],
          ),
          _tabContent(
            title: "Was kann helfen?",
            color: roseMid,
            items: [
              "• Wärme & Entspannung",
              "• Sanfte Bewegung (Spaziergänge, Yoga)",
              "• Ausreichend Schlaf",
              "• Stressreduktion & Achtsamkeit",
              "• Journaling & Emotionen ausdrücken",
              "• Tee & warme Getränke",
            ],
          ),
          _tabContent(
            title: "Ernährung & Wohlbefinden",
            color: roseDark,
            items: [
              "• Ausgewogene, regelmäßige Mahlzeiten",
              "• Magnesiumreiche Lebensmittel (z. B. Nüsse, Hafer, Bananen)",
              "• Viel Wasser trinken",
              "• Leichte, warme Gerichte",
              "• Weniger stark verarbeitete Lebensmittel",
              "• Bewusster Umgang mit Zucker & Koffein",
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabContent({
    required String title,
    required Color color,
    required List<String> items,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, color),
          const SizedBox(height: 20),
          _card(items),
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

  Widget _card(List<String> items) {
    return Container(
      width: double.infinity,
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
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  e,
                  style: const TextStyle(
                    fontFamily: "NewFirst",
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
