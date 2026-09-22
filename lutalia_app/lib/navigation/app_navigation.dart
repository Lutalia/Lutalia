import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/theme.dart';

// Screens
import '../screens/home_screen.dart';
import '../screens/achtsamkeit_screen.dart';
import '../screens/gesundheit_screen.dart';
import '../screens/kreativitaet_screen.dart';
import '../screens/alltag_screen.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;

  void goToHome() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final List<Widget> screens = [
      const HomeScreen(),
      AchtsamkeitScreen(onGoHome: goToHome),
      GesundheitScreen(onGoHome: goToHome),
      KreativitaetScreen(
        onGoHome: goToHome,
        userId: userId,
      ),
      AlltagScreen(
        onGoHome: goToHome,
        userId: userId, // ⭐ Hier wird userId jetzt korrekt übergeben!
      ),
    ];

    return Scaffold(
      backgroundColor: LutaliaTheme.creme,
      body: screens[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: LutaliaTheme.creme,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: LutaliaTheme.latte,
        unselectedItemColor: LutaliaTheme.latte.withValues(alpha: 0.4),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa),
            label: 'Balance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Gesundheit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Küche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Alltag',
          ),
        ],
      ),
    );
  }
}