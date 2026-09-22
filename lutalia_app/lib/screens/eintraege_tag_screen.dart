import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:intl/intl.dart';

import '../screens/lutalia_page.dart';
import 'eintrag_detail_screen.dart';

class EintraegeTagScreen extends StatefulWidget {
  final DateTime date;

  const EintraegeTagScreen({super.key, required this.date});

  @override
  State<EintraegeTagScreen> createState() => _EintraegeTagScreenState();
}

class _EintraegeTagScreenState extends State<EintraegeTagScreen> {
  final storage = const FlutterSecureStorage();

  late encrypt.Encrypter encrypter;
  late encrypt.IV iv;

  List<Map<String, dynamic>> entries = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initEncryption();
  }

  Future<void> _initEncryption() async {
    String? keyString = await storage.read(key: "journal_key");

    if (keyString == null) {
      final newKey = encrypt.Key.fromSecureRandom(32);
      await storage.write(key: "journal_key", value: newKey.base64);
      keyString = newKey.base64;
    }

    final key = encrypt.Key.fromBase64(keyString);
    iv = encrypt.IV.fromLength(16);
    encrypter = encrypt.Encrypter(encrypt.AES(key));

    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    final raw = await storage.read(key: "journal_entries");

    if (raw == null || raw.isEmpty) {
      setState(() => loading = false);
      return;
    }

    // ⭐ JSON korrekt parsen
    final List<dynamic> list = jsonDecode(raw);

    // ⭐ Nur Einträge dieses Tages
    final filtered = list.where((entry) {
      final date = DateTime.parse(entry["date"]);
      return DateUtils.isSameDay(date, widget.date);
    }).toList();

    // ⭐ entschlüsseln
    entries = filtered.map((entry) {
      final decryptedTitle = encrypter.decrypt64(entry["title"], iv: iv);
      final decryptedText = encrypter.decrypt64(entry["text"], iv: iv);

      return {
        "date": entry["date"],
        "title": decryptedTitle,
        "text": decryptedText,
        "image": entry["image"],
        "raw": entry, // wichtig für Löschen
      };
    }).toList();

    setState(() => loading = false);
  }

  Future<void> _deleteEntry(Map<String, dynamic> rawEntry) async {
    final raw = await storage.read(key: "journal_entries");
    if (raw == null) return;

    final List<dynamic> list = jsonDecode(raw);

    list.removeWhere((e) =>
        e["date"] == rawEntry["date"] &&
        e["title"] == rawEntry["title"] &&
        e["text"] == rawEntry["text"]);

    await storage.write(key: "journal_entries", value: jsonEncode(list));

    await _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat("EEEE, d. MMMM yyyy", "de_DE").format(widget.date);

    return LutaliaPage(
      title: formattedDate,
      showBack: true,
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
              ? Center(
                  child: Text(
                    "Keine Einträge an diesem Tag",
                    style: TextStyle(
                      fontFamily: "Cinzel",
                      fontSize: 18,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];

                    return GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EintragDetailScreen(entry: entry),
                          ),
                        );

                        // ⭐ Wenn gelöscht wurde
                        if (result != null && result["delete"] != null) {
                          await _deleteEntry(entry["raw"]);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
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
                        child: Row(
                          children: [
                            // ⭐ Bild
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: entry["image"] == null
                                  ? Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported),
                                    )
                                  : Image.file(
                                      File(entry["image"]),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                            ),

                            const SizedBox(width: 16),

                            // ⭐ Titel + Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry["title"],
                                    style: const TextStyle(
                                      fontFamily: "Cinzel",
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    entry["text"],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
