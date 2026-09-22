import 'package:flutter/material.dart';
import 'lutalia_page.dart';

class MoodTrackerScreen extends StatelessWidget {
  const MoodTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LutaliaPage(
      title: "Mood Tracker",
      child: Center(
        child: Text("Mood Tracker – Inhalt folgt"),
      ),
    );
  }
}
