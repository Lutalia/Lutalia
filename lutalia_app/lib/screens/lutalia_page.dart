import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../screens/personal_screen.dart';
import '../screens/journal_shell.dart';

class LutaliaPage extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBack;
  final bool showCalendar;

  final VoidCallback? onBackPressed;
  final VoidCallback? onCalendarPressed;

  final Widget? floatingActionButton;

  // ⭐ Padding abschaltbar
  final bool removePadding;

  const LutaliaPage({
    super.key,
    required this.title,
    required this.child,
    this.showBack = true,
    this.showCalendar = false,
    this.onBackPressed,
    this.onCalendarPressed,
    this.floatingActionButton,
    this.removePadding = false, // Standard: Padding bleibt
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LutaliaTheme.creme,
      floatingActionButton: floatingActionButton,

      appBar: AppBar(
        backgroundColor: LutaliaTheme.creme,
        elevation: 0,
        centerTitle: true,

        leading: showBack
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: const Color.from(alpha: 1, red: 0.831, green: 0.604, blue: 0.518),
                ),
                onPressed: () {
                  if (onBackPressed != null) {
                    onBackPressed!();
                    return;
                  }

                  final args = ModalRoute.of(context)?.settings.arguments;

                  if (args == "journalRoot") {
                    Navigator.of(context, rootNavigator: true).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const JournalShell(),
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).pop();
                },
              )
            : null,

        title: Text(
          "Lutalia",
          style: TextStyle(
            fontFamily: "NewFirst",
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: LutaliaTheme.latte,
          ),
        ),

        actions: [
          if (showCalendar)
            IconButton(
              icon: Icon(
                Icons.calendar_month,
                color: LutaliaTheme.latte,
                size: 28,
              ),
              onPressed: onCalendarPressed,
            ),

          IconButton(
            icon: Icon(
              Icons.person,
              color: LutaliaTheme.latte,
              size: 28,
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => const PersonalScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // ⭐ BODY – Wenn removePadding true ist, wird das Child direkt ohne Column/Padding übergeben
      body: removePadding
          ? child
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  title.isEmpty
                      ? const SizedBox.shrink()
                      : Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: "NewFirst",
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                  const SizedBox(height: 20),
                  Expanded(child: child),
                ],
              ),
            ),
    );
  }
}