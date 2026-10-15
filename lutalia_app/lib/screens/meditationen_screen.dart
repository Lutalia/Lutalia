import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MeditationenScreen extends StatefulWidget {
  const MeditationenScreen({super.key});

  @override
  State<MeditationenScreen> createState() => _MeditationenScreenState();
}

class _MeditationenScreenState extends State<MeditationenScreen>
    with SingleTickerProviderStateMixin {
  
  late final AnimationController _breathController;
  late final Animation<double> _breathAnimation;
  late final AudioPlayer _audioPlayer;

  int _selectedCategoryIndex = 0;
  
  final List<String> _categories = [
    'Alle',
    'Geführt',
    'Atemübungen',
    'Klangwelten',
  ];

  final List<Map<String, dynamic>> _meditations = [
    {
      'title': 'Gedankenstopp vor dem Schlafen',
      'subtitle': 'Gesprochene Führung um das Gedankenkreisen sanft zu lösen',
      'duration': '10 Min',
      'category': 'Geführt',
      'icon': Icons.mic_none_outlined,
      'assetPath': 'audio/gedankenstopp.mp3',
    },
    {
      'title': '4-7-8 Beruhigungs-Atmung',
      'subtitle': 'Anleitung für eine tiefere, verlangsamte Atmung',
      'duration': '5 Min',
      'category': 'Atemübungen',
      'icon': Icons.air_outlined,
    },
    {
      'title': 'Innere Ruhe & Geborgenheit',
      'subtitle': 'Sanfte Phantasiereise zum Entspannen und Ankommen',
      'duration': '12 Min',
      'category': 'Geführt',
      'icon': Icons.self_improvement_outlined,
    },
    {
      'title': 'Sanfte Nacht-Naturklänge',
      'subtitle': 'Ruhige Hintergrundmusik mit warmen Entspannungsfrequenzen',
      'duration': '20 Min',
      'category': 'Klangwelten',
      'icon': Icons.music_note_outlined,
    },
  ];

  Map<String, dynamic>? _currentTrack;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    
    _audioPlayer = AudioPlayer();

    // WICHTIG: Erzwinge maximale Lautstärke und Audio-Routing direkt am Player
    _audioPlayer.setVolume(1.0);

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _currentTrack = null;
            _isPlaying = false;
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.stop();
          }
        });
      }
    });

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handlePlayPause(Map<String, dynamic> track) async {
    final String? assetPath = track['assetPath'];
    
    if (assetPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Für diesen Eintrag ist noch kein Audio verfügbar.')),
      );
      return;
    }

    try {
      if (_currentTrack == track) {
        if (_isPlaying) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
      } else {
        await _audioPlayer.stop();
        setState(() {
          _currentTrack = track;
        });
        
        // Asset laden, Lautstärke explizit setzen und abspielen
        await _audioPlayer.setAsset('assets/$assetPath');
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Wiedergabefehler mit just_audio Asset: $e');
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentTrack = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('FEHLER: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _audioPlayer.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentTrack = null;
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Stoppen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeList = _selectedCategoryIndex == 0
        ? _meditations
        : _meditations.where((m) => m['category'] == _categories[_selectedCategoryIndex]).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4EFEA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A3B32), size: 20),
          onPressed: () {
            _stopPlayback();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'MEDITATION & RUHE',
          style: TextStyle(
            color: Color(0xFF4A3B32),
            fontSize: 20,
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.6,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                Center(
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: _breathAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F2EC),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFC89B7B), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC89B7B).withValues(alpha: 0.15),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.graphic_eq,
                            color: Color(0xFFC89B7B),
                            size: 42,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Geführte Meditationen',
                        style: TextStyle(
                          color: Color(0xFF4A3B32),
                          fontSize: 26,
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'INNERE RUHE, ACHTSAMKEIT UND KLARHEIT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8C7A70),
                          fontSize: 10,
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedCategoryIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategoryIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF4A3B32) : const Color(0xFFF7F2EC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFC89B7B), width: 1.2),
                          ),
                          child: Center(
                            child: Text(
                              _categories[index].toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF4A3B32),
                                fontSize: 11,
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ...activeList.map((track) {
                  final bool isCurrent = _currentTrack == track && _isPlaying;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F2EC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCurrent ? const Color(0xFF4A3B32) : const Color(0xFFC89B7B),
                        width: isCurrent ? 2.0 : 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _handlePlayPause(track),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCurrent ? const Color(0xFFC89B7B) : const Color(0xFFEFE8E1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCurrent ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: isCurrent ? Colors.white : const Color(0xFF4A3B32),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track['title'],
                                style: const TextStyle(
                                  color: Color(0xFF4A3B32),
                                  fontSize: 15,
                                  fontFamily: 'Cinzel',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                track['subtitle'],
                                style: const TextStyle(
                                  color: Color(0xFF6B5B52),
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          track['duration'],
                          style: const TextStyle(
                            color: Color(0xFFC89B7B),
                            fontSize: 11,
                            fontFamily: 'Cinzel',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          if (_currentTrack != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A3B32),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    const Icon(Icons.graphic_eq, color: Color(0xFFC89B7B), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentTrack!['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Cinzel',
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isPlaying ? 'Wird abgespielt...' : 'Pausiert',
                            style: const TextStyle(
                              color: Color(0xFFC89B7B),
                              fontSize: 10,
                              fontFamily: 'Cinzel',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: const Color(0xFFC89B7B),
                        size: 34,
                      ),
                      onPressed: () => _handlePlayPause(_currentTrack!),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.stop_circle_outlined,
                        color: Colors.white70,
                        size: 28,
                      ),
                      onPressed: _stopPlayback,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}