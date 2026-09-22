import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/theme.dart';
import '../screens/lutalia_page.dart';

class KalenderScreen extends StatefulWidget {
  const KalenderScreen({super.key});

  @override
  State<KalenderScreen> createState() => _KalenderScreenState();
}

class _KalenderScreenState extends State<KalenderScreen>
    with SingleTickerProviderStateMixin {
  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  void changeMonth(int offset) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + offset);
      _controller.forward(from: 0);
    });
  }

  List<DateTime> _generateDays() {
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);

    final daysBefore = firstDay.weekday - 1;
    final daysAfter = 7 - lastDay.weekday;

    final totalDays = (lastDay.day + daysBefore + daysAfter);

    return List.generate(totalDays, (index) {
      return DateTime(
        currentMonth.year,
        currentMonth.month,
        index - daysBefore + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _generateDays();
    final monthName = DateFormat.MMMM("de_DE").format(currentMonth);

    return LutaliaPage(
      title: "Kalender",
      showBack: true,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ⭐ Monatsnavigation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left,
                      size: 32, color: LutaliaTheme.latte),
                  onPressed: () => changeMonth(-1),
                ),
                Text(
                  monthName,
                  style: const TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right,
                      size: 32, color: LutaliaTheme.latte),
                  onPressed: () => changeMonth(1),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ⭐ Wochentage
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _Weekday("Mo"),
                  _Weekday("Di"),
                  _Weekday("Mi"),
                  _Weekday("Do"),
                  _Weekday("Fr"),
                  _Weekday("Sa"),
                  _Weekday("So"),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ⭐ Kalendergrid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final isCurrentMonth = day.month == currentMonth.month;
                  final isToday = DateUtils.isSameDay(day, DateTime.now());

                  return GestureDetector(
                    onTap: isCurrentMonth
                        ? () {
                            // später: Einträge dieses Tages anzeigen
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: isToday
                            ? LutaliaTheme.latte.withOpacity(0.25)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isCurrentMonth
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          "${day.day}",
                          style: TextStyle(
                            fontFamily: "Cinzel",
                            fontSize: 16,
                            color: isCurrentMonth
                                ? Colors.black
                                : Colors.black.withOpacity(0.25),
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Weekday extends StatelessWidget {
  final String label;
  const _Weekday(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: "Cinzel",
        fontSize: 14,
        color: Colors.black.withOpacity(0.6),
      ),
    );
  }
}
