import 'package:flutter/material.dart';

class AddFoodPopup extends StatefulWidget {
  const AddFoodPopup({super.key});

  @override
  State<AddFoodPopup> createState() => _AddFoodPopupState();
}

class _AddFoodPopupState extends State<AddFoodPopup> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF7F2EC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Titel
            const Text(
              "Lebensmittel hinzufügen",
              style: TextStyle(
                fontFamily: "Cinzel",
                fontSize: 20,
                color: Color(0xFF8C6F5A),
              ),
            ),

            const SizedBox(height: 20),

            // Suchfeld
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                style: const TextStyle(fontFamily: "Cinzel"),
                decoration: const InputDecoration(
                  hintText: "Lebensmittel suchen…",
                  hintStyle: TextStyle(fontFamily: "Cinzel"),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Menge
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontFamily: "Cinzel"),
                decoration: const InputDecoration(
                  hintText: "Menge in Gramm",
                  hintStyle: TextStyle(fontFamily: "Cinzel"),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Hinzufügen Button
            GestureDetector(
              onTap: () {
                Navigator.pop(context, {
                  "name": searchController.text,
                  "amount": amountController.text,
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF7F2EC),
                      Color(0xFFF3D7D2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF3D7D2).withOpacity(0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "Hinzufügen",
                    style: TextStyle(
                      fontFamily: "Cinzel",
                      fontSize: 18,
                      color: Color(0xFF8C6F5A),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
