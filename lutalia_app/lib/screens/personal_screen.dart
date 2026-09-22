import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/theme.dart';
import 'lutalia_page.dart';

// Unterseiten
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'privacy_screen.dart';
import 'logout_flow.dart';
import 'stats_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'delete_account_screen.dart';
import 'register_screen.dart';


// PIN-Unterseiten
import 'pin_change_screen.dart';
import 'pin_forgot_screen.dart';
// ❌ pin_remove_screen.dart entfernt

// ⭐ SCHREIBMASCHINEN-TEXT
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration speed;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.speed = const Duration(milliseconds: 70),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String visible = "";
  int index = 0;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    if (index < widget.text.length) {
      if (!mounted) return;
      setState(() {
        visible += widget.text[index];
        index++;
      });
      Future.delayed(widget.speed, _tick);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      visible,
      textAlign: TextAlign.center,
      style: widget.style,
    );
  }
}

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({super.key});

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  final user = FirebaseAuth.instance.currentUser;

  late Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    _reloadUser();
  }

  Future<void> _reloadUser() async {
    setState(() {
      _userFuture = FirebaseFirestore.instance
          .collection("users")
          .doc(user?.uid)
          .get();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final currentUser = snapshot.data;

        return LutaliaPage(
          title: "Persönlicher Bereich",
          child: currentUser == null
              ? _buildLoggedOut(context)
              : _buildLoggedIn(context),
        );
      },
    );
  }

  // ⭐ NICHT EINGELOGGT
  Widget _buildLoggedOut(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 40),
      children: [
        Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Opacity(opacity: value, child: child);
              },
              child: const Text(
                "Willkommen",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Cinzel",
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: LutaliaTheme.espresso,
                ),
              ),
            ),

            const SizedBox(height: 4),

            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Opacity(opacity: value, child: child);
              },
              child: const Text(
                "bei Lutalia",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Cinzel",
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: LutaliaTheme.espresso,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        Center(child: Image.asset("assets/images/olive.png", height: 70)),

        const SizedBox(height: 30),

        TypewriterText(
          text: "Schön, dass du da bist",
          style: const TextStyle(
            fontFamily: "NewFirst",
            fontSize: 28,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.2,
            color: LutaliaTheme.espresso,
          ),
        ),

        const SizedBox(height: 40),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LutaliaTheme.latte,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text(
              "Login",
              style: TextStyle(
                fontFamily: "Cinzel",
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8D6C8),
              foregroundColor: LutaliaTheme.espresso,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()));
            },
            child: const Text(
              "Registrieren",
              style: TextStyle(
                fontFamily: "Cinzel",
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ⭐ EINGELOGGT
  Widget _buildLoggedIn(BuildContext context) {
    return RefreshIndicator(
      color: LutaliaTheme.latte,
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      onRefresh: _reloadUser,

      child: FutureBuilder<DocumentSnapshot>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView(
              children: const [
                SizedBox(height: 200),
                Center(
                  child: CircularProgressIndicator(color: LutaliaTheme.espresso),
                ),
              ],
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final String displayName =
              data["nickname"] ??
              data["firstname"] ??
              "Benutzer";

          final String? profileImage = data["profileImage"];

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              const SizedBox(height: 20),

              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFD8C3B8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: profileImage == null
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: LutaliaTheme.espresso,
                        )
                      : Image.network(
                          profileImage,
                          fit: BoxFit.cover,
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: "NewFirst",
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: LutaliaTheme.espresso,
                ),
              ),

              const SizedBox(height: 30),

              _buildItem(context, "Profil bearbeiten", Icons.edit,
                  const EditProfileScreen()),

              _buildItem(context, "Einstellungen", Icons.settings,
                  const SettingsScreen()),

              _buildItem(context, "Favoriten", Icons.favorite_border,
                  const FavoritesScreen()),

              _buildItem(context, "Persönliche Statistiken", Icons.bar_chart,
                  const StatsScreen()),

              _buildItem(context, "Datenschutz", Icons.lock_outline,
                  const PrivacyScreen()),

              // ⭐ PIN-Optionen (nur diese beiden!)
              _buildItem(context, "PIN ändern", Icons.password,
                  const PinChangeScreen()),

              _buildItem(context, "PIN vergessen", Icons.help_outline,
                  const PinForgotScreen()),

              // ❌ PIN entfernen entfernt

              _buildItem(context, "Abmelden", Icons.logout,
                  const LogoutFlowScreen()),

              _buildItem(context, "Account löschen", Icons.delete_forever,
                  const DeleteAccountScreen()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    String label,
    IconData icon,
    Widget page,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page))
              .then((_) => _reloadUser());
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: LutaliaTheme.espresso, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: "Cinzel",
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: LutaliaTheme.espresso,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
