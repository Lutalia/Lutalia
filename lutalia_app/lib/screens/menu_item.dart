import 'package:flutter/material.dart';
import '../theme/theme.dart';

class MenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool centered; // ← WICHTIG: dieser Parameter hat gefehlt!

  const MenuItem({
    super.key,
    required this.label,
    required this.onTap,
    this.centered = false, // ← Standardwert
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            textAlign: centered ? TextAlign.center : TextAlign.left,
            style: const TextStyle(
              fontFamily: "Cinzel",
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: LutaliaTheme.espresso,
            ),
          ),
        ),
      ),
    );
  }
}
