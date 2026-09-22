import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/lutalia_page.dart';

class EintragDetailScreen extends StatelessWidget {
  final Map<String, dynamic> entry;

  const EintragDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(entry["date"]);
    final formattedDate =
        DateFormat("EEEE, d. MMMM yyyy", "de_DE").format(date);

    return LutaliaPage(
      title: "Eintrag",
      showBack: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⭐ Datum
            Text(
              formattedDate,
              style: TextStyle(
                fontFamily: "Cinzel",
                fontSize: 18,
                color: Colors.black.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 20),

            // ⭐ Titel
            Text(
              entry["title"],
              style: const TextStyle(
                fontFamily: "Cinzel",
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 20),

            // ⭐ Bild (falls vorhanden)
            if (entry["image"] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(entry["image"]),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            if (entry["image"] != null) const SizedBox(height: 20),

            // ⭐ Text
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                entry["text"],
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ⭐ Löschen-Button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade300,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Eintrag löschen?"),
                      content: const Text(
                          "Dieser Eintrag wird dauerhaft entfernt."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Abbrechen"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Löschen",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    Navigator.pop(context, {"delete": entry});
                  }
                },
                child: const Text(
                  "Löschen",
                  style: TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
