import 'package:flutter/material.dart';

class LutaliaTheme {
  // Farben – warm, feminin, Lutalia
  static const Color creme = Color(0xFFF7F3EE);
  static const Color espresso = Color(0xFF3E2F2F);
  static const Color rose = Color(0xFFE8D4C8);
  static const Color gold = Color(0xFFC9A86A);
  static const Color latte = Color(0xFFD49A84);


  // Haupt-Theme
  static ThemeData theme = ThemeData(
    useMaterial3: true,

    // Hintergrund
    scaffoldBackgroundColor: creme,

    // Primärfarbe
    primaryColor: rose,

    // Modernes ColorScheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: rose,
      primary: rose,
      secondary: gold,
      surface: creme,
      onSurface: espresso,
      onPrimary: espresso,
    ),

    // Typografie – angepasst nach deinen Wünschen
    textTheme: const TextTheme(
      // ⭐ Überschriften jeder Seite → NewFirst
      headlineLarge: TextStyle(
        fontFamily: 'NewFirst',
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: espresso,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'NewFirst',
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: espresso,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'NewFirst',
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: espresso,
      ),

      // ⭐ Unterpunkte / Inhalte → Cinzel
      bodyLarge: TextStyle(
        fontFamily: 'Cinzel',
        fontSize: 18,
        color: espresso,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Cinzel',
        fontSize: 16,
        color: espresso,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Cinzel',
        fontSize: 14,
        color: espresso,
      ),
    ),

    // Buttons im Lutalia-Look
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: rose,
        foregroundColor: espresso,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Cinzel',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),

    // ⭐ AppBarTheme wurde ENTFERNT, damit deine Farben NICHT überschrieben werden ⭐

    // Navigation Bar (unten)
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: creme,
      selectedItemColor: espresso,
      unselectedItemColor: Color(0x883E2F2F),
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Cinzel',
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(fontFamily: 'Cinzel'),
    ),
  );
}
