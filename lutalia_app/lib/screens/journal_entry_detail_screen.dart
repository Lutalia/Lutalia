import 'dart:io';
import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../theme/theme.dart';
import '../data/journal_repository.dart';
import 'journal_edit_entry_screen.dart';
import 'package:flutter_sound/flutter_sound.dart';

class JournalEntryDetailScreen extends StatelessWidget {
  final JournalEntry entry;

  const JournalEntryDetailScreen({super.key, required this.entry});

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  @override
  Widget build(BuildContext context) {
    final repo = JournalRepository();

    return Scaffold(
      backgroundColor: LutaliaTheme.creme,

      appBar: AppBar(
        backgroundColor: LutaliaTheme.creme,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Eintrag",
          style: TextStyle(
            fontFamily: "NewFirst",
            fontSize: 32,
            color: Colors.black,
          ),
        ),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () async {
              final changed = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JournalEditEntryScreen(
                    entry: entry,
                    repository: repo,
                  ),
                ),
              );

              if (changed == true) {
                Navigator.pop(context, true);
              }
            },
          ),

          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.black),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text("Eintrag löschen?"),
                  content: const Text(
                      "Willst du diesen Eintrag wirklich löschen?"),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: LutaliaTheme.latte,
                      ),
                      child: const Text("Abbrechen"),
                      onPressed: () => Navigator.pop(dialogContext, false),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: LutaliaTheme.latte),
                      child: const Text("Löschen"),
                      onPressed: () => Navigator.pop(dialogContext, true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await repo.deleteEntry(entry.id);
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                entry.sticker,
                style: const TextStyle(fontSize: 70),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              entry.title,
              style: const TextStyle(
                fontFamily: "NewFirst",
                fontSize: 34,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Text(
                  entry.mood,
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  _formatTime(entry.date),
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 20,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ⭐ FOTO-ANZEIGE
            if (entry.photo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(entry.photo!),
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 30),
            ],

            // ⭐ TEXT
            if (entry.text.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  entry.text,
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 18,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // ⭐ AUDIO
            if (entry.audio != null)
              _AudioPlayerWidget(audioPath: entry.audio!),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _AudioPlayerWidget extends StatefulWidget {
  final String audioPath;

  const _AudioPlayerWidget({required this.audioPath});

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player.openPlayer();
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<void> togglePlay() async {
    if (!isPlaying) {
      await _player.startPlayer(
        fromURI: widget.audioPath,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: togglePlay,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: LutaliaTheme.latte,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 20),

          const Text(
            "Audio abspielen",
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
