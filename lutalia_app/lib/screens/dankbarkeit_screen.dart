import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/journal_repository.dart';
import '../models/journal_entry.dart';
import '../theme/theme.dart';

class DankbarkeitScreen extends StatefulWidget {
  final JournalRepository repository;
  final DateTime selectedDate;

  const DankbarkeitScreen({
    super.key,
    required this.repository,
    required this.selectedDate,
  });

  @override
  State<DankbarkeitScreen> createState() => _DankbarkeitScreenState();
}

class _DankbarkeitScreenState extends State<DankbarkeitScreen> {
  final TextEditingController one = TextEditingController();
  final TextEditingController two = TextEditingController();
  final TextEditingController three = TextEditingController();

  TimeOfDay? selectedTime;
  bool hasChanges = false;

  // ⭐ Dankbarkeits‑Stimmung
  String selectedMood = "✨";

  final List<Map<String, String>> gratitudeMoods = [
    {"icon": "✨", "label": "Dankbar"},
    {"icon": "🌿", "label": "Frieden"},
    {"icon": "🕊️", "label": "Leichtigkeit"},
    {"icon": "💛", "label": "Wärme"},
    {"icon": "🤍", "label": "Klarheit"},
  ];

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

  Future<void> _saveEntry() async {
    final base = widget.selectedDate;

    final text = [
      one.text.trim(),
      two.text.trim(),
      three.text.trim(),
    ].where((e) => e.isNotEmpty).join("\n");

    final entry = JournalEntry(
      id: const Uuid().v4(),
      title: "Dankbarkeit",
      text: text.isEmpty ? "Heute bin ich dankbar." : text,
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
            "Dankbarkeit",
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
              // ⭐ Stimmung
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
                    items: gratitudeMoods.map((m) {
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

              // ⭐ Dankbarkeitsfelder
              const Text(
                "Wofür bist du heute dankbar?",
                style: TextStyle(
                  fontFamily: "NewFirst",
                  fontSize: 28,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              _field("1. Etwas Schönes heute", one),
              const SizedBox(height: 16),

              _field("2. Etwas Klenes, das dich berührt hat", two),
              const SizedBox(height: 16),

              _field("3. Etwas, das du wertschätzt", three),

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

  Widget _field(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() => hasChanges = true),
      maxLines: 3,
      textAlign: TextAlign.center,
      style: const TextStyle(fontFamily: "Cinzel", fontSize: 18, height: 1.4),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
