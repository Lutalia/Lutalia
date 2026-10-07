import 'package:flutter/material.dart';

class CyclePhasesScreen extends StatelessWidget {
  const CyclePhasesScreen({super.key});

  // ⭐ Lutalia-Farbwelt & edle Erdtöne
  final Color primaryColor = const Color(0xFFB3AA97);
  final Color backgroundColor = const Color(0xFFF9F8F6);
  final Color cardBgColor = Colors.white;
  final Color textColor = const Color(0xFF332E26);
  final Color quoteBgColor = const Color(0xFFF4F0EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          "Die 4 Zyklusphasen",
          style: TextStyle(
            fontFamily: "Cinzel", // ⭐ Hauptüberschrift in Cinzel
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _phaseCard(
            context,
            title: "Menstruationsphase",
            subtitle: "Innehalten & Loslassen",
            description:
                "Ruhe, Rückzug und Sensibilität. Dein Körper arbeitet intensiv – gönne dir Wärme, Entspannung und Sanftheit.",
            quote: "„In der Stille liegt die größte Kraft zur Erneuerung.“",
            icon: Icons.water_drop_outlined,
          ),
          const SizedBox(height: 16),

          _phaseCard(
            context,
            title: "Follikelphase",
            subtitle: "Aufbau & neue Energie",
            description:
                "Aufbruch, Kreativität und Frische. Dein Körper baut sich neu auf – Motivation und Leichtigkeit begleiten dich.",
            quote: "„Jeder Neuanfang beginnt mit einem sanften Funken.“",
            icon: Icons.eco_outlined,
          ),
          const SizedBox(height: 16),

          _phaseCard(
            context,
            title: "Ovulationsphase",
            subtitle: "Blütezeit & Verbindung",
            description:
                "Strahlkraft, Selbstbewusstsein und soziale Energie. Du fühlst dich klar, stark und tief verbunden.",
            quote: "„Erstrahle in deinem ureigenen Licht.“",
            icon: Icons.wb_sunny_outlined,
          ),
          const SizedBox(height: 16),

          _phaseCard(
            context,
            title: "Lutealphase",
            subtitle: "Reflexion & Innenschau",
            description:
                "Intuition, Tiefe und das Bedürfnis nach Struktur. Dein Körper bereitet sich vor – mehr Ruhe tut dir jetzt gut.",
            quote: "„Hör auf die Weisheit deiner inneren Stimme.“",
            icon: Icons.nightlight_outlined,
          ),
        ],
      ),
    );
  }

  Widget _phaseCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required String quote,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor,
          width: 1.4,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kopfzeile mit Icon und Titeln
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: quoteBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: "Cinzel", // ⭐ Phasentitel in Cinzel, aber...
                          fontSize: 20,
                          fontWeight: FontWeight.w400, // ⭐ ...wichtig: nicht fett! (schlank & edel)
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: "Lato", // Klarer, gut lesbarer Subtitel
                          fontSize: 13.5,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Beschreibungstext in einer sehr sauberen, modernen Schrift (z.B. Lato)
            Text(
              description,
              style: const TextStyle(
                fontFamily: "Lato", // ⭐ Gut lesbare Alternative für den Fließtext
                fontSize: 15.5, 
                color: Color(0xFF4A443B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Zitatbox mit klarer, eleganter Schrift
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: quoteBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                quote,
                style: const TextStyle(
                  fontFamily: "Lato", // ⭐ Perfekt lesbar auch in Kursiv
                  fontSize: 14.5,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF5A5247),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}