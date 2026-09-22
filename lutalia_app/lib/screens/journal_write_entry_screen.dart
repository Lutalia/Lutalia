import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/theme.dart';
import '../data/journal_repository.dart';
import '../models/journal_entry.dart';

class JournalWriteEntryScreen extends StatefulWidget {
  final JournalRepository repository;

  const JournalWriteEntryScreen({super.key, required this.repository});

  @override
  State<JournalWriteEntryScreen> createState() => _JournalWriteEntryScreenState();
}

class _JournalWriteEntryScreenState extends State<JournalWriteEntryScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController textController = TextEditingController();

  late TimeOfDay selectedTime;
  bool hasChanges = false;

  String selectedMood = "Beflügelt";

  final Map<String, String> moodIcons = {
    "Glücklich": "🙂",
    "Ruhig": "😌",
    "Dankbar": "✨",
    "Traurig": "😢",
    "Überfordert": "😵",
    "Neutral": "🌿",
    "Beflügelt": "🕊️",
    "Verliebt": "💕",
    "Geliebt": "❤️",
    "Unruhig": "😟",
    "Wütend": "😡",
    "Sauer": "😠",
    "Enttäuscht": "😞",
    "Unsicher": "😬",
    "Nachdenklich": "🤔",
  };

  @override
  void initState() {
    super.initState();
    selectedTime = TimeOfDay.now();
  }

  Future<void> _saveEntry() async {
    final now = DateTime.now();

    final entry = JournalEntry(
      id: const Uuid().v4(),
      title: titleController.text.trim().isEmpty
          ? "Ohne Titel"
          : titleController.text.trim(),
      text: textController.text.trim(),
      mood: selectedMood,
      sticker: moodIcons[selectedMood]!,
      date: DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
    );

    await widget.repository.addEntry(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ⭐ Hintergrund + Blur
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Image.asset(
              "assets/fee/hintergrund.png",
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),

        // ⭐ Zurück-Pfeil oben links
        Positioned(
          top: 40,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),

        // ⭐ Inhalt
        Positioned.fill(
          top: 100,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ⭐ Titel
                const Text(
                  "Titel",
                  style: TextStyle(
                    fontFamily: "NewFirst",
                    fontSize: 30,
                    color: Color(0xFFEFE7D8), // warmes Beige
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: titleController,
                    onChanged: (_) => setState(() => hasChanges = true),
                    style: const TextStyle(
                      fontFamily: "Cinzel",
                      fontSize: 20,
                      color: Color(0xFFEFE7D8),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Wie soll dein Eintrag heißen?",
                      hintStyle: TextStyle(
                        fontFamily: "Cinzel",
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ⭐ Stimmung
                const Text(
                  "Stimmung",
                  style: TextStyle(
                    fontFamily: "NewFirst",
                    fontSize: 30,
                    color: Color(0xFFEFE7D8),
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: Colors.black.withOpacity(0.6),
                      value: selectedMood,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          selectedMood = value!;
                          hasChanges = true;
                        });
                      },
                      items: moodIcons.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Row(
                            children: [
                              Text(entry.value,
                                  style: const TextStyle(fontSize: 26)),
                              const SizedBox(width: 12),
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontFamily: "Cinzel",
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ⭐ Uhrzeit
                const Text(
                  "Uhrzeit",
                  style: TextStyle(
                    fontFamily: "NewFirst",
                    fontSize: 30,
                    color: Color(0xFFEFE7D8),
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontFamily: "Cinzel",
                      fontSize: 20,
                      color: Color(0xFFEFE7D8),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ⭐ Beitrag
                const Text(
                  "Beitrag",
                  style: TextStyle(
                    fontFamily: "NewFirst",
                    fontSize: 30,
                    color: Color(0xFFEFE7D8),
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: textController,
                    onChanged: (_) => setState(() => hasChanges = true),
                    maxLines: 12,
                    style: const TextStyle(
                      fontFamily: "Cinzel",
                      fontSize: 18,
                      height: 1.4,
                      color: Color(0xFFEFE7D8),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Was möchtest du festhalten?",
                      hintStyle: TextStyle(
                        fontFamily: "Cinzel",
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ⭐ To-Do Liste Button
                Center(
                  child: TextButton(
                    onPressed: () {
                      // später To-Do Screen
                    },
                    child: const Text(
                      "To‑Do Liste hinzufügen",
                      style: TextStyle(
                        fontFamily: "Cinzel",
                        fontSize: 18,
                        color: Color(0xFFEFE7D8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ⭐ Speichern Button
                Center(
                  child: ElevatedButton(
                    onPressed: _saveEntry,
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
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
