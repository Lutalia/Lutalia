import 'package:flutter/material.dart';

class CycleSkincareScreen extends StatefulWidget {
  const CycleSkincareScreen({super.key});

  @override
  State<CycleSkincareScreen> createState() => _CycleSkincareScreenState();
}

class _CycleSkincareScreenState extends State<CycleSkincareScreen>
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
          "Zyklusbasierte Hautpflege",
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
              "• Haut kann sensibler reagieren",
              "• Trockenheit oder Rötungen möglich",
              "• Weniger Toleranz für aktive Wirkstoffe",
            ],
            skincare: [
              "• Sanfte Reinigung",
              "• Beruhigende Pflege (z. B. Aloe, Kamille)",
              "• Viel Feuchtigkeit",
              "• Keine starken Peelings",
            ],
            affirmations: [
              "Ich gehe liebevoll mit mir um.",
              "Meine Haut darf zur Ruhe kommen.",
            ],
          ),
          _phase(
            title: "Follikelphase",
            color: roseMid,
            tendencies: [
              "• Haut regeneriert sich gut",
              "• Strahlender, frischer Teint",
              "• Gute Verträglichkeit für leichte Peelings",
            ],
            skincare: [
              "• Leichte AHA/BHA‑Peelings (sanft)",
              "• Aufbauende Seren",
              "• Feuchtigkeit + Glow",
            ],
            affirmations: [
              "Ich fühle mich leicht und klar.",
              "Meine Haut strahlt von innen.",
            ],
          ),
          _phase(
            title: "Ovulationsphase",
            color: roseDark,
            tendencies: [
              "• Glow‑Phase",
              "• Haut wirkt prall und ausgeglichen",
              "• Beste Zeit für Feuchtigkeit",
            ],
            skincare: [
              "• Hydration, Hydration, Hydration",
              "• Leichte Seren",
              "• Glow‑Pflege",
            ],
            affirmations: [
              "Ich strahle Kraft und Schönheit aus.",
              "Ich fühle mich verbunden mit meinem Körper.",
            ],
          ),
          _phase(
            title: "Lutealphase",
            color: roseDeep,
            tendencies: [
              "• Talgproduktion kann steigen",
              "• Unreinheiten möglich",
              "• Haut reagiert schneller",
            ],
            skincare: [
              "• Sanfte Reinigung (kein Austrocknen)",
              "• Porenfreundliche Pflege",
              "• Leichte, beruhigende Produkte",
              "• Kein aggressives Peeling",
            ],
            affirmations: [
              "Ich nehme meine Bedürfnisse ernst.",
              "Ich schenke mir Ruhe und Balance.",
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
    required List<String> skincare,
    required List<String> affirmations,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, color),
          const SizedBox(height: 20),

          _subTitle("Haut‑Tendenzen"),
          _card(tendencies),

          const SizedBox(height: 20),

          _subTitle("Pflegeideen"),
          _card(skincare),

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
