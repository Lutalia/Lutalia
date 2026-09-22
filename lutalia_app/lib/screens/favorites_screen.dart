import 'package:flutter/material.dart';
import 'lutalia_page.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LutaliaPage(
      title: "Favoriten",
      child: Center(
        child: Text("Noch keine Favoriten gespeichert."),
      ),
    );
  }
}
