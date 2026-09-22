import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../theme/theme.dart';
import '../data/journal_repository.dart';
import '../models/journal_entry.dart';

class JournalPhotoEntryScreen extends StatefulWidget {
  final JournalRepository repository;
  final DateTime selectedDate;

  const JournalPhotoEntryScreen({
    super.key,
    required this.repository,
    required this.selectedDate,
  });

  @override
  State<JournalPhotoEntryScreen> createState() =>
      _JournalPhotoEntryScreenState();
}

class _JournalPhotoEntryScreenState extends State<JournalPhotoEntryScreen>
    with SingleTickerProviderStateMixin {
  File? selectedPhoto;
  String selectedMood = "Liebe";
  late TimeOfDay selectedTime;

  final TextEditingController noteController = TextEditingController();

  // ⭐ 13 Herz‑Stimmungen – exakt wie im Audio‑Screen
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
  }

  Future<void> pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() => selectedPhoto = File(picked.path));
    }
  }

  Future<void> pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => selectedPhoto = File(picked.path));
    }
  }

  Future<void> _saveEntry() async {
    if (selectedPhoto == null) return;

    final d = widget.selectedDate;

    final entry = JournalEntry(
      id: const Uuid().v4(),
      title: "Foto‑Eintrag",
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
      photo: selectedPhoto!.path,
      audio: null,
      gratitude: null,
      todos: null,
    );

    await widget.repository.addEntry(entry);

    if (!mounted) return;
    Navigator.pop(context, true); // ⭐ meldet „geändert“
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),

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
                  onTap: () => Navigator.pop(context, false),
                  child: const Icon(Icons.arrow_back,
                      size: 28, color: Colors.black),
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

          // ⭐ LOTUS
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
                    "Foto‑Eintrag",
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
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.black),
                        onChanged: (value) {
                          setState(() => selectedMood = value!);
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

                  // ⭐ FOTO-BEREICH
                  GestureDetector(
                    onTap: pickPhoto,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: selectedPhoto == null
                          ? const Icon(Icons.photo_camera,
                              size: 70, color: Colors.black)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.file(
                                selectedPhoto!,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextButton(
                    onPressed: pickFromGallery,
                    child: const Text(
                      "Aus Galerie wählen",
                      style: TextStyle(
                        fontFamily: "Cinzel",
                        fontSize: 16,
                        color: Colors.black87,
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
                    onPressed: selectedPhoto != null ? _saveEntry : null,
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
