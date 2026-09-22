import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/journal_repository.dart';
import '../models/journal_entry.dart';
import '../theme/theme.dart';

class JournalNewEntryScreen extends StatefulWidget {
  final JournalRepository repository;
  final DateTime selectedDate; // ⭐ vom Kalender übergeben

  const JournalNewEntryScreen({
    super.key,
    required this.repository,
    required this.selectedDate,
  });

  @override
  State<JournalNewEntryScreen> createState() => _JournalNewEntryScreenState();
}

class _JournalNewEntryScreenState extends State<JournalNewEntryScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController textController = TextEditingController();

  TimeOfDay? selectedTime;
  bool hasChanges = false;

  // ⭐ Neue Herz-Stimmungen
  String selectedMood = "❤️";

  final List<Map<String, String>> moodHearts = [
    {"icon": "❤️", "label": "Liebe"},
    {"icon": "🖤", "label": "Traurigkeit"},
    {"icon": "💜", "label": "Sehnsucht"},
    {"icon": "💗", "label": "Zärtlichkeit"},
    {"icon": "💙", "label": "Ruhe"},
    {"icon": "💚", "label": "Hoffnung"},
    {"icon": "🤍", "label": "Neutral"},
    {"icon": "💛", "label": "Licht"},
    {"icon": "🤎", "label": "Erdung"},
    {"icon": "🩷", "label": "Verspieltheit"},
    {"icon": "🩵", "label": "Frieden"},
    {"icon": "🩶", "label": "Müdigkeit"},
    {"icon": "🧡", "label": "Mut"},
  ];

  // ⭐ Popup
  Future<bool> _showLeaveDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Nicht gespeichert"),
            content: const Text("Willst du die Seite wirklich verlassen, ohne zu speichern?"),
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
                  foregroundColor: LutaliaTheme.latte,
                ),
                child: const Text("Verlassen"),
                onPressed: () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _onWillPop() async {
    if (!hasChanges) return true;
    return await _showLeaveDialog();
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? now,
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
        hasChanges = true;
      });
    }
  }

  // ⭐ Speichern – jetzt mit KORREKTEM DATUM
  Future<void> _saveEntry() async {
    final base = widget.selectedDate; // ⭐ Datum vom Kalender

    final entry = JournalEntry(
      id: const Uuid().v4(),
      title: titleController.text.trim().isEmpty
          ? "Ohne Titel"
          : titleController.text.trim(),
      text: textController.text.trim(),
      mood: selectedMood,
      sticker: selectedMood,
      date: DateTime(
        base.year,
        base.month,
        base.day,
        selectedTime?.hour ?? 12,
        selectedTime?.minute ?? 0,
      ),
    );

    await widget.repository.addEntry(entry);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final leave = await _onWillPop();
        if (leave && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: LutaliaTheme.creme,

        appBar: AppBar(
          backgroundColor: LutaliaTheme.creme,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            "Neuer Eintrag",
            style: TextStyle(
              fontFamily: "NewFirst",
              color: Colors.black,
              fontSize: 32,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (!hasChanges) {
                Navigator.pop(context);
                return;
              }

              final leave = await _showLeaveDialog();
              if (leave && mounted) Navigator.pop(context);
            },
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ⭐ Titel
              const Text(
                "Titel",
                style: TextStyle(
                  fontFamily: "NewFirst",
                  fontSize: 28,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: titleController,
                onChanged: (_) => setState(() => hasChanges = true),
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: "Cinzel", fontSize: 20),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Wie soll dein Eintrag heißen?",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ⭐ Stimmung (Herz + Bedeutung)
              const Text(
                "Stimmung",
                style: TextStyle(
                  fontFamily: "NewFirst",
                  fontSize: 28,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedMood,
                    icon: const Icon(Icons.arrow_drop_down),
                    onChanged: (value) {
                      setState(() {
                        selectedMood = value!;
                        hasChanges = true;
                      });
                    },
                    items: moodHearts.map((m) {
                      return DropdownMenuItem<String>(
                        value: m["icon"]!,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(m["icon"]!, style: const TextStyle(fontSize: 30)),
                            const SizedBox(width: 12),
                            Text(
                              m["label"]!,
                              style: const TextStyle(
                                fontFamily: "Cinzel",
                                fontSize: 20,
                                color: Colors.black87,
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
                  fontSize: 28,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Center(
                    child: Text(
                      selectedTime == null
                          ? "Uhrzeit wählen"
                          : "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontFamily: "Cinzel", fontSize: 20),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ⭐ Textfeld
              const Text(
                "Dein Text",
                style: TextStyle(
                  fontFamily: "NewFirst",
                  fontSize: 28,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: textController,
                onChanged: (_) => setState(() => hasChanges = true),
                maxLines: 12,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: "Cinzel", fontSize: 18, height: 1.4),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Was möchtest du festhalten?",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ⭐ Speichern
              Center(
                child: ElevatedButton(
                  onPressed: _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LutaliaTheme.latte,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Speichern",
                    style: TextStyle(fontFamily: "NewFirst", fontSize: 26),
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
