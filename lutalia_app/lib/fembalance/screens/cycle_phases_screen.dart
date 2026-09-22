import 'package:flutter/material.dart';

class CyclePhasesScreen extends StatelessWidget {
  const CyclePhasesScreen({super.key});

  final Color roseLight = const Color(0xFFF3C9D8);
  final Color roseMid   = const Color(0xFFE8AFC4);
  final Color roseDark  = const Color(0xFFD9A2B8);
  final Color roseDeep  = const Color(0xFFC98FA8);
  final Color latteBg   = const Color(0xFFF4E6DE);
  final Color latteText = const Color(0xFFD19884);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: latteBg,
      appBar: AppBar(
        backgroundColor: roseLight,
        elevation: 0,
        title: const Text(
          "Die 4 Zyklusphasen",
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
          _phaseCard(
            context,
            title: "Menstruationsphase",
            color: roseLight,
            description:
                "Ruhe, Rückzug, Sensibilität. Dein Körper arbeitet intensiv – gönne dir Wärme, Entspannung und Sanftheit.",
          ),
          const SizedBox(height: 18),
          _phaseCard(
            context,
            title: "Follikelphase",
            color: roseMid,
            description:
                "Aufbruch, Energie, Kreativität. Dein Körper baut auf – Motivation und Leichtigkeit begleiten dich.",
          ),
          const SizedBox(height: 18),
          _phaseCard(
            context,
            title: "Ovulationsphase",
            color: roseDark,
            description:
                "Strahlkraft, Selbstbewusstsein, soziale Energie. Du fühlst dich klar, stark und verbunden.",
          ),
          const SizedBox(height: 18),
          _phaseCard(
            context,
            title: "Lutealphase",
            color: roseDeep,
            description:
                "Intuition, Tiefe, Bedürfnis nach Struktur. Dein Körper bereitet sich vor – mehr Ruhe tut gut.",
          ),
        ],
      ),
    );
  }

  Widget _phaseCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: "Cinzel",
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: const TextStyle(
              fontFamily: "NewFirst",
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Mehr erfahren →",
              style: TextStyle(
                fontFamily: "Cinzel",
                fontSize: 15,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
