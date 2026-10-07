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

  final Color primaryColor = const Color(0xFFB3AA97);
  final Color backgroundColor = const Color(0xFFF9F8F6);
  final Color textColor = const Color(0xFF4A443B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          "FemBalance",
          style: TextStyle(
            fontFamily: "Cinzel",
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        // ⭐ Großzügiger unterer Abstand (100), damit man garantiert bis ganz nach unten scrollen kann
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _homeCard(
            context,
            title: "Die 4 Zyklusphasen",
            description: "Verstehe deinen Körper in jeder Phase.",
            icon: Icons.track_changes_outlined,
            screen: const CyclePhasesScreen(),
          ),
          const SizedBox(height: 12),

          _homeCard(
            context,
            title: "Menstruation Tracking",
            description: "Kalender, Stimmung, Energie & Notizen.",
            icon: Icons.calendar_month_outlined,
            screen: const MenstruationTrackingScreen(),
          ),
          const SizedBox(height: 12),

          _homeCard(
            context,
            title: "PMS verstehen",
            description: "Selfcare, Ernährung & Wohlbefinden.",
            icon: Icons.spa_outlined,
            screen: const PmsScreen(),
          ),
          const SizedBox(height: 12),

          _homeCard(
            context,
            title: "Zyklusbasierte Workouts",
            description: "Bewegung im Einklang mit deinem Körper.",
            icon: Icons.fitness_center_outlined,
            screen: const CycleWorkoutsScreen(),
          ),
          const SizedBox(height: 12),

          _homeCard(
            context,
            title: "Zyklusbasierte Hautpflege",
            description: "Pflege passend zu deiner Phase.",
            icon: Icons.face_outlined,
            screen: const CycleSkincareScreen(),
          ),
          const SizedBox(height: 12),

          _homeCard(
            context,
            title: "Zyklusbasierte Emotionen",
            description: "Verstehen, fühlen, annehmen.",
            icon: Icons.favorite_border,
            screen: const CycleEmotionsScreen(),
          ),
          const SizedBox(height: 12),

          _homeCard(
            context,
            title: "Community",
            description: "Austausch, Fragen & Unterstützung.",
            icon: Icons.people_outline,
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
    required IconData icon,
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor,
            width: 1.4,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white,
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F0EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: "Cinzel",
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: primaryColor.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}