import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../theme/theme.dart';
import '../data/journal_repository.dart';
import '../models/journal_entry.dart';

class JournalAudioEntryScreen extends StatefulWidget {
  final JournalRepository repository;
  final DateTime selectedDate;

  const JournalAudioEntryScreen({
    super.key,
    required this.repository,
    required this.selectedDate,
  });

  @override
  State<JournalAudioEntryScreen> createState() =>
      _JournalAudioEntryScreenState();
}

class _JournalAudioEntryScreenState extends State<JournalAudioEntryScreen>
    with SingleTickerProviderStateMixin {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  bool isRecording = false;
  bool isPaused = false;
  bool isPlaying = false;
  String? audioPath;

  String selectedMood = "Liebe";
  late TimeOfDay selectedTime;

  final TextEditingController noteController = TextEditingController();

  late AnimationController glowController;
  late Animation<double> glowAnimation;

  // ⭐ Deine 13 Mood-Herzen
  final Map<String, String> moodIcons = {
    "Liebe": "❤️",
    "Traurigkeit": "🖤",
    "Sehnsucht": "💜",
    "Zärtlichkeit": "💗",
    "Ruhe": "💙",
    "Hoffnung": "💚",
    "Neutral": "🤍",
    "Licht": "💛",
    "Erdung": "🤎",
    "Verspieltheit": "🩷",
    "Frieden": "🩵",
    "Müdigkeit": "🩶",
    "Mut": "🧡",
  };

  @override
  void initState() {
    super.initState();
    selectedTime = TimeOfDay.now();
    _initAudio();

    glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    glowAnimation = Tween<double>(begin: 0, end: 18).animate(
      CurvedAnimation(parent: glowController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initAudio() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    glowController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<bool> _ensurePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String> _generateFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return "${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a";
  }

  Future<void> startRecording() async {
    if (!await _ensurePermission()) return;

    final path = await _generateFilePath();

    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacMP4,
    );

    setState(() {
      isRecording = true;
      isPaused = false;
      audioPath = path;
    });

    glowController.repeat(reverse: true);
  }

  Future<void> pauseRecording() async {
    await _recorder.pauseRecorder();
    setState(() => isPaused = true);
  }

  Future<void> resumeRecording() async {
    await _recorder.resumeRecorder();
    setState(() => isPaused = false);
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();

    setState(() {
      isRecording = false;
      isPaused = false;
    });

    glowController.stop();
  }

  Future<void> togglePlay() async {
    if (audioPath == null) return;

    if (!isPlaying) {
      await _player.startPlayer(
        fromURI: audioPath!,
        codec: Codec.aacMP4,
        whenFinished: () {
          setState(() => isPlaying = false);
        },
      );
      setState(() => isPlaying = true);
    } else {
      await _player.pausePlayer();
      setState(() => isPlaying = false);
    }
  }

  Future<void> _saveEntry() async {
    if (audioPath == null) return;

    final d = widget.selectedDate;

    final entry = JournalEntry(
      id: const Uuid().v4(),
      title: "Audio‑Eintrag",
      text: noteController.text,
      mood: selectedMood,
      sticker: moodIcons[selectedMood]!,
      date: DateTime(
        d.year,
        d.month,
        d.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
      audio: audioPath,
      photo: null,
      gratitude: null,
      todos: null,
    );

    await widget.repository.addEntry(entry);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6), // warmes Beige

      body: Column(
        children: [
          const SizedBox(height: 40),

          // ⭐ LUTALIA HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
                ),
                const Text(
                  "Lutalia",
                  style: TextStyle(
                    fontFamily: "NewFirst",
                    fontSize: 32,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 28),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ⭐ LOTUS BILD (funktioniert jetzt!)
          Image.asset(
            "assets/fee/sticker/lotus.png",
            height: 150,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Audio‑Eintrag",
                    style: TextStyle(
                      fontFamily: "NewFirst",
                      fontSize: 38,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ⭐ MOOD DROPDOWN
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMood,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                        onChanged: (value) {
                          setState(() => selectedMood = value!);
                        },
                        items: moodIcons.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Row(
                              children: [
                                Text(entry.value, style: const TextStyle(fontSize: 26)),
                                const SizedBox(width: 12),
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontFamily: "Cinzel",
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ⭐ AUFNAHME BUTTON
                  AnimatedBuilder(
                    animation: glowAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          boxShadow: isRecording
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.4),
                                    blurRadius: glowAnimation.value,
                                    spreadRadius: glowAnimation.value,
                                  )
                                ]
                              : [],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(90),
                          onTap: () {
                            if (!isRecording && audioPath == null) {
                              startRecording();
                            } else if (isRecording && !isPaused) {
                              pauseRecording();
                            } else if (isRecording && isPaused) {
                              resumeRecording();
                            } else if (!isRecording && audioPath != null) {
                              togglePlay();
                            }
                          },
                          child: Center(
                            child: Icon(
                              isRecording
                                  ? (isPaused ? Icons.play_arrow : Icons.pause)
                                  : (audioPath == null
                                      ? Icons.mic
                                      : (isPlaying ? Icons.pause : Icons.play_arrow)),
                              size: 70,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  if (isRecording)
                    ElevatedButton(
                      onPressed: stopRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        "Stop",
                        style: TextStyle(
                          fontFamily: "Cinzel",
                          fontSize: 20,
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // ⭐ NOTIZ
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Notiz hinzufügen…",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ⭐ SPEICHERN
                  ElevatedButton(
                    onPressed: audioPath != null ? _saveEntry : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LutaliaTheme.latte,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 60, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "Speichern",
                      style: TextStyle(
                        fontFamily: "NewFirst",
                        fontSize: 26,
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
