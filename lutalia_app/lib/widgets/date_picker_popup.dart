import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

class DatePickerPopup extends StatelessWidget {
  final DateTime initial;
  final ValueChanged<DateTime> onSelected;

  const DatePickerPopup({
    super.key,
    required this.initial,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    DateTime temp = initial;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Datum auswählen",
                  style: TextStyle(
                    fontFamily: "NewFirst",
                    fontSize: 26,
                  ),
                ),

                const SizedBox(height: 20),

                CalendarDatePicker(
                  initialDate: initial,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  onDateChanged: (d) => temp = d,
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LutaliaTheme.latte,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onSelected(temp);
                  },
                  child: const Text(
                    "Übernehmen",
                    style: TextStyle(
                      fontFamily: "Cinzel",
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
