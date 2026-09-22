import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final String title;
  final String text;
  final String mood;

  /// ⭐ Sticker kann PNG-Pfad ODER Emoji sein
  final String sticker;

  /// ⭐ Optional: Foto (Pfad oder URL)
  final String? photo;

  /// ⭐ Optional: Audio (Pfad oder URL)
  final String? audio;

  /// ⭐ Optional: Dankbarkeitstext
  final String? gratitude;

  /// ⭐ Optional: To-Do-Liste
  final List<String>? todos;

  final DateTime date;

  JournalEntry({
    required this.id,
    required this.title,
    required this.text,
    required this.mood,
    required this.sticker,
    required this.date,
    this.photo,
    this.audio,
    this.gratitude,
    this.todos,
  });

  // ⭐ Für Firestore speichern
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "text": text,
      "mood": mood,
      "sticker": sticker,
      "date": Timestamp.fromDate(date),

      // ⭐ optionale Felder
      "photo": photo,
      "audio": audio,
      "gratitude": gratitude,
      "todos": todos,
    };
  }

  // ⭐ Von Firestore laden
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map["id"] ?? "",
      title: map["title"] ?? "",
      text: map["text"] ?? "",
      mood: map["mood"] ?? "",
      sticker: map["sticker"] ?? "🕊️",

      // ⭐ optionale Felder
      photo: map["photo"],
      audio: map["audio"],
      gratitude: map["gratitude"],
      todos: map["todos"] != null
          ? List<String>.from(map["todos"])
          : null,

      date: (map["date"] as Timestamp).toDate(),
    );
  }
}
