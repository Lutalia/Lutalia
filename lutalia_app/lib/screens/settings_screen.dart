import 'package:flutter/material.dart';
import 'lutalia_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LutaliaPage(
      title: "Einstellungen",
      child: Center(
        child: Text("Dark Mode & weitere Optionen folgen."),
      ),
    );
  }
}
