import 'package:flutter/material.dart';

class XpChallengeScreen extends StatefulWidget {
  final int todaySleepPoints; // Optionaler Parameter für die Punkte der letzten Nacht

  const XpChallengeScreen({super.key, this.todaySleepPoints = 0});

  @override
  State<XpChallengeScreen> createState() => _XpChallengeScreenState();
}

class _XpChallengeScreenState extends State<XpChallengeScreen> {
  // Start bei Level 1
  final int currentLevel = 1;
  final String currentRankTitle = 'Sanfter Morgenstern';
  final int xpForNextLevel = 250;

  // Challenges mit Start-Status (noch nicht aktiviert / bei 0)
  final List<Map<String, dynamic>> challenges = [
    {
      'title': '7 Tage Schlaf-Rhythmus',
      'description': 'Gehe an 7 aufeinanderfolgenden Tagen vor 23:00 Uhr schlafen.',
      'progress': 0,
      'total': 7,
      'xpReward': 150,
      'icon': Icons.bedtime_outlined,
      'isActive': false,
      'completed': false,
    },
    {
      'title': 'Abendliche Bildschirmruhe',
      'description': 'Verzichte 5 Tage lang 1 Stunde vor dem Schlafen auf Displays.',
      'progress': 0,
      'total': 5,
      'xpReward': 100,
      'icon': Icons.phonelink_off_outlined,
      'isActive': false,
      'completed': false,
    },
    {
      'title': 'Tiefschlaf-Pionier',
      'description': 'Ereiche an 3 Nächten einen Tiefschlaf-Wert von über 90 Minuten.',
      'progress': 0,
      'total': 3,
      'xpReward': 200,
      'icon': Icons.stars_outlined,
      'isActive': false,
      'completed': false,
    },
  ];

  // Alle Trophäen anfangs gesperrt
  final List<Map<String, dynamic>> trophies = [
    {
      'title': 'Erster Schritt',
      'desc': 'Ersten Schlaf-Score in Lutalia getrackt.',
      'icon': Icons.explore_outlined,
      'unlocked': false,
      'date': 'Noch gesperrt',
    },
    {
      'title': 'Schlaf-Meister',
      'desc': 'Einen Schlaf-Score von über 90 Punkten erreicht.',
      'icon': Icons.emoji_events_outlined,
      'unlocked': false,
      'date': 'Noch gesperrt',
    },
    {
      'title': 'Konsequenter Geist',
      'desc': '7 Tage am Stück deinen Schlaf & Einflüsse dokumentiert.',
      'icon': Icons.verified_outlined,
      'unlocked': false,
      'date': 'Noch gesperrt',
    },
    {
      'title': 'Traumwelten-Wanderer',
      'desc': 'Über 2 Stunden REM-Schlaf in einer einzelnen Nacht erzielt.',
      'icon': Icons.nights_stay_outlined,
      'unlocked': false,
      'date': 'Noch gesperrt',
    },
    {
      'title': 'Balance-Gott',
      'desc': 'Alle 7 negativen Abend-Einflüsse an einem Tag vermieden.',
      'icon': Icons.spa_outlined,
      'unlocked': false,
      'date': 'Noch gesperrt',
    },
    {
      'title': 'Lutalia Legende',
      'desc': 'Erreiche Level 10 im Lutalia-Regenerationssystem.',
      'icon': Icons.workspace_premium_outlined,
      'unlocked': false,
      'date': 'Noch gesperrt',
    },
  ];

  void _startChallenge(int index) {
    setState(() {
      challenges[index]['isActive'] = true;
      challenges[index]['progress'] = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Challenge "${challenges[index]['title']}" gestartet!'),
        backgroundColor: const Color(0xFF4A3B32),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int currentXP = widget.todaySleepPoints;
    double levelProgress = (currentXP / xpForNextLevel).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A3B32), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lutalia',
          style: TextStyle(
            color: Color(0xFF4A3B32),
            fontSize: 28,
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'XP, Challenges &\nTrophäen',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF4A3B32),
                  fontSize: 32,
                  fontFamily: 'Cinzel',
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 1. KASTEN: LEVEL 1 & XP FORTSCHRITT (Sicherer Layout-Container gegen Pixelüberlauf)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEAE3DD),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFD6CBC1), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LEVEL $currentLevel',
                              style: const TextStyle(
                                color: Color(0xFFC89B7B),
                                fontSize: 13,
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentRankTitle,
                              style: const TextStyle(
                                color: Color(0xFF4A3B32),
                                fontSize: 18,
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F0EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Color(0xFFC89B7B),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: levelProgress,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFD6CBC1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC89B7B)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$currentXP XP (Letzte Nacht)',
                        style: const TextStyle(
                          color: Color(0xFF4A3B32),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ziel: $xpForNextLevel XP',
                        style: const TextStyle(
                          color: Color(0xFF8C7A70),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. WAS BEDEUTET XP?
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0EB),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFD6CBC1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFC89B7B), size: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Was sind XP in Lutalia?',
                          style: TextStyle(
                            color: Color(0xFF4A3B32),
                            fontSize: 16,
                            fontFamily: 'Cinzel',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'XP steht für Experience Points (Erfahrungspunkte). Du startest als „Sanfter Morgenstern“ auf Level 1. Aktiviere unten Challenges, um durch konsequente Regeneration aufzusteigen und exklusive Trophäen freizuschalten!',
                          style: TextStyle(
                            color: Color(0xFF6B5B52),
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. CHALLENGE SYSTEM
            const Text(
              'Verfügbare Challenges',
              style: TextStyle(
                color: Color(0xFF4A3B32),
                fontSize: 22,
                fontFamily: 'Cinzel',
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Aktiviere eine Challenge, um mit dem Sammeln zu beginnen:',
              style: TextStyle(
                color: Color(0xFF6B5B52),
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 16),

            ...challenges.asMap().entries.map((entry) {
              int index = entry.key;
              var c = entry.value;
              return _buildChallengeCard(c, index);
            }),

            const SizedBox(height: 32),

            // 4. TROPHÄEN-KABINETT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Deine Trophäen',
                  style: TextStyle(
                    color: Color(0xFF4A3B32),
                    fontSize: 22,
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '${trophies.where((t) => t['unlocked'] == true).length} / ${trophies.length}',
                  style: const TextStyle(
                    color: Color(0xFFC89B7B),
                    fontSize: 16,
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: trophies.length,
              itemBuilder: (context, index) {
                final trophy = trophies[index];
                return _buildTrophyBadge(trophy);
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge, int index) {
    bool isActive = challenge['isActive'];
    bool completed = challenge['completed'];
    double progressRatio = isActive ? (challenge['progress'] / challenge['total']).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAE3DD),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isActive ? const Color(0xFFC89B7B) : const Color(0xFFD6CBC1),
          width: isActive ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                challenge['icon'],
                color: isActive ? const Color(0xFFC89B7B) : const Color(0xFF4A3B32),
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge['title'],
                      style: const TextStyle(
                        color: Color(0xFF4A3B32),
                        fontSize: 16,
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+${challenge['xpReward']} XP Belohnung',
                      style: const TextStyle(
                        color: Color(0xFFC89B7B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cinzel',
                      ),
                    ),
                  ],
                ),
              ),
              if (!isActive)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A3B32),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () => _startChallenge(index),
                  child: const Text(
                    'Starten',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Cinzel'),
                  ),
                ),
              if (isActive && !completed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC89B7B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Aktiv',
                    style: TextStyle(color: Color(0xFFC89B7B), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              if (completed)
                const Icon(Icons.check_circle, color: Color(0xFFC89B7B), size: 26),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            challenge['description'],
            style: const TextStyle(
              color: Color(0xFF6B5B52),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressRatio,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFD6CBC1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC89B7B)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '${challenge['progress']} / ${challenge['total']}',
                  style: const TextStyle(
                    color: Color(0xFF4A3B32),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrophyBadge(Map<String, dynamic> trophy) {
    bool unlocked = trophy['unlocked'];

    return GestureDetector(
      onTap: () => _showTrophyDetailModal(trophy),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unlocked ? const Color(0xFFEAE3DD) : const Color(0xFFE2DAD2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unlocked ? const Color(0xFFC89B7B) : const Color(0xFFD6CBC1),
            width: unlocked ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              trophy['icon'],
              color: unlocked ? const Color(0xFFC89B7B) : const Color(0xFF9E8E85),
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              trophy['title'],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: unlocked ? const Color(0xFF4A3B32) : const Color(0xFF8C7A70),
                fontSize: 12,
                fontFamily: 'Cinzel',
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showTrophyDetailModal(Map<String, dynamic> trophy) {
    bool unlocked = trophy['unlocked'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5F0EB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(26.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6CBC1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE3DD),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: unlocked ? const Color(0xFFC89B7B) : const Color(0xFFD6CBC1),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    trophy['icon'],
                    color: unlocked ? const Color(0xFFC89B7B) : const Color(0xFF8C7A70),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  trophy['title'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4A3B32),
                    fontSize: 22,
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  unlocked ? 'Freigeschaltet' : 'Noch gesperrt',
                  style: TextStyle(
                    color: unlocked ? const Color(0xFFC89B7B) : const Color(0xFF8C7A70),
                    fontSize: 13,
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  trophy['desc'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B5B52),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A3B32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'SCHLIESSEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}