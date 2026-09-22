import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../data/journal_repository.dart';
import '../theme/theme.dart';

class JournalEditEntryScreen extends StatefulWidget {
  final JournalEntry entry;
  final JournalRepository repository;

  const JournalEditEntryScreen({
    super.key,
    required this.entry,
    required this.repository,
  });

  @override
  State<JournalEditEntryScreen> createState() => _JournalEditEntryScreenState();
}

class _JournalEditEntryScreenState extends State<JournalEditEntryScreen> {
  late TextEditingController titleController;
  late TextEditingController textController;

  late String selectedMood;
  late String selectedSticker;

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

    titleController = TextEditingController(text: widget.entry.title);
    textController = TextEditingController(text: widget.entry.text);

    // ⭐ Falls Mood nicht in der Liste ist → fallback
    if (moodIcons.containsKey(widget.entry.mood)) {
      selectedMood = widget.entry.mood;
      selectedSticker = moodIcons[widget.entry.mood]!;
    } else {
      selectedMood = "Neutral";
      selectedSticker = moodIcons["Neutral"]!;
    }
  }

  void _save() async {
    final updated = JournalEntry(
      id: widget.entry.id,
      title: titleController.text.trim(),
      text: textController.text.trim(),
      mood: selectedMood,
      sticker: selectedSticker,
      date: widget.entry.date,

      // ⭐ WICHTIG: ALLE FELDER übernehmen, sonst CRASH
      audio: widget.entry.audio,
      photo: widget.entry.photo,
      gratitude: widget.entry.gratitude,
      todos: widget.entry.todos,
    );

    await widget.repository.updateEntry(updated);

    if (mounted) Navigator.pop(context, true); // ⭐ sagt MainScreen: reload
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LutaliaTheme.creme,

      appBar: AppBar(
        backgroundColor: LutaliaTheme.creme,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Bearbeiten",
          style: TextStyle(
            fontFamily: "NewFirst",
            fontSize: 32,
            color: Colors.black,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⭐ Titel
            const Text(
              "Titel",
              style: TextStyle(
                fontFamily: "NewFirst",
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              style: const TextStyle(fontFamily: "Cinzel", fontSize: 20),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ⭐ Stimmung
            const Text(
              "Stimmung",
              style: TextStyle(
                fontFamily: "NewFirst",
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedMood,
                  onChanged: (value) {
                    setState(() {
                      selectedMood = value!;
                      selectedSticker = moodIcons[value]!;
                    });
                  },
                  items: moodIcons.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Row(
                        children: [
                          Text(entry.value, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 12),
                          Text(
                            entry.key,
                            style: const TextStyle(fontFamily: "Cinzel"),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ⭐ Text
            const Text(
              "Dein Text",
              style: TextStyle(
                fontFamily: "NewFirst",
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: textController,
              maxLines: 12,
              style: const TextStyle(fontFamily: "Cinzel", fontSize: 18),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 40),

            Center(
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LutaliaTheme.latte,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 20,
                  ),
                ),
                child: const Text(
                  "Speichern",
                  style: TextStyle(
                    fontFamily: "NewFirst",
                    fontSize: 26,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
