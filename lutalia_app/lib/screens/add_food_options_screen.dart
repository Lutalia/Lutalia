import 'package:flutter/material.dart';
import 'add_food_manual_screen.dart';
import 'search_results_screen.dart';
import 'barcode_scanner_screen.dart';

class AddFoodOptionsScreen extends StatelessWidget {
  const AddFoodOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Lebensmittel hinzufügen",
              style: TextStyle(
                fontFamily: "Cinzel",
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 22),

            // ⭐ Manuell eingeben
            _option(
              context,
              "Lebensmittel manuell eingeben",
              Icons.edit_note,
              () async {
                final result = await showDialog(
                  context: context,
                  builder: (_) => const AddFoodManualScreen(),
                );
                Navigator.pop(context, result);
              },
            ),

            const SizedBox(height: 14),

            // ⭐ Suchen
            _option(
              context,
              "Lebensmittel suchen",
              Icons.search,
              () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchResultsScreen(query: ""),
                  ),
                );
                Navigator.pop(context, result);
              },
            ),

            const SizedBox(height: 14),

            // ⭐ Scannen
            _option(
              context,
              "Lebensmittel scannen",
              Icons.qr_code_scanner,
              () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BarcodeScannerScreen(),
                  ),
                );
                Navigator.pop(context, result);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 🔥 WICHTIG: async Callback erlauben
  // ------------------------------------------------------------
  Widget _option(
    BuildContext context,
    String text,
    IconData icon,
    Future<void> Function() onTap,
  ) {
    return InkWell(
      onTap: () async => await onTap(),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8C6F5A), size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
