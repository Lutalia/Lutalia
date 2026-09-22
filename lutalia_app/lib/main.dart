import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/theme.dart';
import 'navigation/app_navigation.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ⭐ OpenFoodFacts import
import 'package:openfoodfacts/openfoodfacts.dart';

// ⭐ ProductStorage import
import 'services/product_storage.dart';

// ⭐ Tagebuch import
import 'screens/journal_shell.dart';

// ⭐ Locale Fix für TimePicker / DateFormat
import 'package:intl/date_symbol_data_local.dart';

// ⭐ RouteObserver für HomeScreen Refresh
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⭐ Locale initialisieren
  await initializeDateFormatting('de_DE', null);

  // 🔥 Firebase initialisieren
  await Firebase.initializeApp();

  // ⭐ OpenFoodFacts User-Agent setzen
  OpenFoodAPIConfiguration.userAgent = UserAgent(
    name: 'Lutalia',
    version: '1.0.0',
    system: 'Flutter',
  );

  // ⭐ ProductStorage initialisieren
  await ProductStorage.init();

  // ⭐ SharedPreferences laden
  final prefs = await SharedPreferences.getInstance();
  final stayLoggedIn = prefs.getBool("stayLoggedIn") ?? false;

  // ⭐ Prüfen, ob ein User eingeloggt ist
  final user = FirebaseAuth.instance.currentUser;

  // ⭐ Entscheiden, welche Route gestartet wird
  String initialRoute;

  if (stayLoggedIn && user != null && user.emailVerified) {
    initialRoute = '/home'; // direkt rein
  } else {
    initialRoute = '/'; // Splash → Login
  }

  runApp(LutaliaApp(initialRoute: initialRoute));
}

class LutaliaApp extends StatelessWidget {
  final String initialRoute;

  const LutaliaApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lutalia',
      debugShowCheckedModeBanner: false,
      theme: LutaliaTheme.theme,

      // ⭐ RouteObserver aktivieren
      navigatorObservers: [routeObserver],

      // ⭐ Dynamische Start-Route
      initialRoute: initialRoute,

      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const AppNavigation(),

        // ⭐ Tagebuch
        '/journal': (context) => const JournalShell(),
      },
    );
  }
}
