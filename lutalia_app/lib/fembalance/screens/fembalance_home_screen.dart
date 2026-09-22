import 'package:flutter/material.dart';

import 'cycle_phases_screen.dart';
import 'menstruation_tracking_screen.dart';
import 'pms_screen.dart';
import 'cycle_workouts_screen.dart';
import 'cycle_skincare_screen.dart';
import 'cycle_emotions_screen.dart';
import 'fembalance_community_screen.dart';

class FemBalanceHomeScreen extends StatelessWidget {
  const FemBalanceHomeScreen({super.key});

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
          "FemBalance",
          style: TextStyle(
            fontFamily: "Cinzel",
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _homeCard(
            context,
            title: "Die 4 Zyklusphasen",
            description: "Verstehe deinen Körper in jeder Phase.",
            color: roseLight,
            screen: const CyclePhasesScreen(),
          ),
          const SizedBox(height: 18),

          _homeCard(
            context,
            title: "Menstruation Tracking",
            description: "Kalender, Stimmung, Energie & Notizen.",
            color: roseMid,
            screen: const MenstruationTrackingScreen(),
          ),
          const SizedBox(height: 18),

          _homeCard(
            context,
            title: "PMS verstehen",
            description: "Selfcare, Ernährung & Wohlbefinden.",
            color: roseDark,
            screen: const PmsScreen(),
          ),
          const SizedBox(height: 18),

          _homeCard(
            context,
            title: "Zyklusbasierte Workouts",
            description: "Bewegung im Einklang mit deinem Körper.",
            color: roseDeep,
            screen: const CycleWorkoutsScreen(),
          ),
          const SizedBox(height: 18),

          _homeCard(
            context,
            title: "Zyklusbasierte Hautpflege",
            description: "Pflege passend zu deiner Phase.",
            color: roseLight,
            screen: const CycleSkincareScreen(),
          ),
          const SizedBox(height: 18),

          _homeCard(
            context,
            title: "Zyklusbasierte Emotionen",
            description: "Verstehen, fühlen, annehmen.",
            color: roseMid,
            screen: const CycleEmotionsScreen(),
          ),
          const SizedBox(height: 18),

          _homeCard(
            context,
            title: "Community",
            description: "Austausch, Fragen & Unterstützung.",
            color: roseDark,
            screen: const FemBalanceCommunityScreen(),
          ),
        ],
      ),
    );
  }

  Widget _homeCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color color,
    required Widget screen,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left color bar
            Container(
              width: 10,
              height: 70,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),

            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: "Cinzel",
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: latteText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: "NewFirst",
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
