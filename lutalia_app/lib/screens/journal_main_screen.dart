import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import '../data/journal_repository.dart';
import '../models/journal_entry.dart';
import 'journal_new_entry_screen.dart';
import 'journal_audio_entry_screen.dart';
import 'journal_photo_entry_screen.dart';
import 'journal_entry_detail_screen.dart';
import 'lutalia_page.dart';
import '../theme/theme.dart';
import 'package:intl/intl.dart';
import 'dankbarkeit_screen.dart'; // ⭐ Wichtig

class JournalMainScreen extends StatefulWidget {
  final JournalRepository repository;

  const JournalMainScreen({
    super.key,
    required this.repository,
  });

  @override
  State<JournalMainScreen> createState() => _JournalMainScreenState();
}

class _JournalMainScreenState extends State<JournalMainScreen>
    with SingleTickerProviderStateMixin {
  final Color latteBase = const Color(0xFFF4EDE7);
  final Color latteSoft = const Color(0xFFF7F3EE);
  final Color latteShadow = const Color(0xFFE8DCD4);
  final Color darkBrown = const Color(0xFF5A3E36);
  final Color sand = const Color(0xFFD6CFC7);
  final Color accent = const Color(0xFFB58E6A);

  late VideoPlayerController _videoController;

  late AnimationController _textAnimController;
  late Animation<Offset> _slowSlide;
  late Animation<double> _slowFade;

  DateTime selectedDay = DateTime.now();
  late Future<List<JournalEntry>> _entriesForDay;

  @override
  void initState() {
    super.initState();

    _entriesForDay = widget.repository.entriesForDay(selectedDay);

    _videoController = VideoPlayerController.asset(
      "assets/videos/tagebuch_video.mp4",
    )
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(true);
        _videoController.setVolume(0);
        _videoController.play();
      });

    _textAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _slowSlide = Tween<Offset>(
      begin: const Offset(-1.4, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textAnimController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slowFade = CurvedAnimation(
      parent: _textAnimController,
      curve: Curves.easeOutExpo,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _textAnimController.forward();
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _textAnimController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _entriesForDay = widget.repository.entriesForDay(selectedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LutaliaPage(
      title: "",
      showBack: true,
      showCalendar: false,
      removePadding: true,
      child: Stack(
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Image.asset(
                "assets/fee/hintergrund.png",
                fit: BoxFit.cover,
              ),
            ),
          ),

          ListView(
            padding: EdgeInsets.zero,
            children: [
              if (_videoController.value.isInitialized)
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController),
                  ),
                ),

              const SizedBox(height: 18),

              AnimatedDefaultTextStyle(
                duration: Duration.zero,
                style: TextStyle(
                  fontFamily: "NewFirst",
                  fontSize: 56,
                  color: darkBrown,
                ),
                child: AnimatedTextKit(
                  isRepeatingAnimation: false,
                  animatedTexts: [
                    TypewriterAnimatedText(
                      "Tagebuch",
                      textAlign: TextAlign.center,
                      speed: Duration(milliseconds: 160),
                      cursor: "",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Image.asset(
                "assets/fee/sticker/lotus.png",
                width: 120,
                height: 120,
              ),

              const SizedBox(height: 20),

              RepaintBoundary(
                child: Column(
                  children: [
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-1.2, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _textAnimController,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: FadeTransition(
                        opacity: _slowFade,
                        child: Text(
                          "Dein Platz",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "Cinzel",
                            fontSize: 20,
                            color: darkBrown.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    FadeTransition(
                      opacity: _slowFade,
                      child: Text(
                        "zum",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Cinzel",
                          fontSize: 20,
                          color: darkBrown.withOpacity(0.85),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.2, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _textAnimController,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: FadeTransition(
                        opacity: _slowFade,
                        child: Text(
                          "Gedanken‑Freilassen",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "Cinzel",
                            fontSize: 20,
                            color: darkBrown.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 46),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _buildBlossoms(),
              ),

              const SizedBox(height: 34),

              _card(_buildReflection()),
              const SizedBox(height: 34),

              _card(_buildGratitude()), // ⭐ HIER IST DER BUTTON DRIN
              const SizedBox(height: 34),

              _card(_buildCalendar()),
              const SizedBox(height: 34),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _buildEntries(),
              ),

              const SizedBox(height: 44),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: latteSoft.withOpacity(0.92),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Colors.white,
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: latteShadow.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildBlossoms() {
    final days = List.generate(
      6,
      (i) => DateTime.now().subtract(Duration(days: 5 - i)),
    );

    return FutureBuilder<Map<DateTime, List<JournalEntry>>>(
      future: _loadLast6Days(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Meine Blüten",
              style: TextStyle(
                fontFamily: "NewFirst",
                fontSize: 30,
                color: darkBrown,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Deine Aktivität der letzten Tage",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Cinzel",
                fontSize: 15,
                color: Color(0xFF8C6F5A),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((day) {
                final key = DateTime(day.year, day.month, day.day);
                final entries = data[key] ?? [];
                final count = entries.length;

                final stage =
                    (count == 0) ? 1 : (count >= 4 ? 5 : count + 1);

                return Column(
                  children: [
                    Image.asset(
                      "assets/lotus/lotus_$stage.png",
                      width: 42,
                      height: 42,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${day.day}.",
                      style: TextStyle(
                        fontFamily: "Cinzel",
                        fontSize: 12,
                        color: LutaliaTheme.latte,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Future<Map<DateTime, List<JournalEntry>>> _loadLast6Days() async {
    final Map<DateTime, List<JournalEntry>> map = {};

    for (int i = 0; i < 6; i++) {
      final day = DateTime.now().subtract(Duration(days: 5 - i));
      final clean = DateTime(day.year, day.month, day.day);
      final entries = await widget.repository.entriesForDay(clean);
      map[clean] = entries;
    }

    return map;
  }

  Widget _buildReflection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_note, color: Color(0xFF5A3E36), size: 20),
            const SizedBox(width: 10),
            Text(
              "Tägliche Reflexion",
              style: TextStyle(
                fontFamily: "NewFirst",
                fontSize: 24,
                color: darkBrown,
                height: 1.1,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Text(
          "Was bewegt dich heute?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "Cinzel",
            fontSize: 14,
            color: Color(0xFF8C6F5A),
            height: 1.1,
          ),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            _reflectionButton(Icons.edit, "Schreiben", () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JournalNewEntryScreen(
                    repository: widget.repository,
                    selectedDate: selectedDay,
                  ),
                ),
              );
              _reload();
            }),
            const SizedBox(width: 12),
            _reflectionButton(Icons.mic, "Audio", () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JournalAudioEntryScreen(
                    repository: widget.repository,
                    selectedDate: selectedDay,
                  ),
                ),
              );
              _reload();
            }),
            const SizedBox(width: 12),
            _reflectionButton(Icons.photo_camera, "Foto", () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JournalPhotoEntryScreen(
                    repository: widget.repository,
                    selectedDate: selectedDay,
                  ),
                ),
              );
              _reload();
            }),
          ],
        ),
      ],
    );
  }

  Widget _reflectionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: latteBase.withOpacity(0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white,
              width: 1.4,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: accent),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: "Cinzel",
                  fontSize: 14,
                  color: darkBrown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ⭐⭐⭐⭐⭐ DANKBARKEIT – MIT BUTTON & NAVIGATION
  Widget _buildGratitude() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, color: Color(0xFF5A3E36), size: 20),
            const SizedBox(width: 6),
            Text(
              "Dankbarkeits‑Moment",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "NewFirst",
                fontSize: 24,
                color: darkBrown,
                height: 1.1,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          "Heute bin ich dankbar für…",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "Cinzel",
            fontSize: 14,
            color: Color(0xFF8C6F5A),
            height: 1.1,
          ),
        ),

        const SizedBox(height: 20),

        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DankbarkeitScreen(
                  repository: widget.repository,
                  selectedDate: selectedDay,
                ),
              ),
            );
            _reload();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: latteBase.withOpacity(0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white,
                width: 1.4,
              ),
            ),
            child: Text(
              "Dankbarkeit eintragen",
              style: TextStyle(
                fontFamily: "Cinzel",
                fontSize: 16,
                color: darkBrown,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final weekdays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];

    final firstDay = DateTime(selectedDay.year, selectedDay.month, 1);
    final firstWeekday = (firstDay.weekday + 6) % 7;
    final daysInMonth =
        DateTime(selectedDay.year, selectedDay.month + 1, 0).day;

    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Color(0xFF5A3E36)),
              onPressed: () {
                setState(() {
                  selectedDay = DateTime(
                    selectedDay.year,
                    selectedDay.month - 1,
                    selectedDay.day,
                  );
                  _entriesForDay = widget.repository.entriesForDay(selectedDay);
                });
              },
            ),
            Text(
              DateFormat("MMMM yyyy", "de_DE").format(selectedDay),
              style: TextStyle(
                fontFamily: "NewFirst",
                fontSize: 24,
                color: darkBrown,
                height: 1.1,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Color(0xFF5A3E36)),
              onPressed: () {
                setState(() {
                  selectedDay = DateTime(
                    selectedDay.year,
                    selectedDay.month + 1,
                    selectedDay.day,
                  );
                  _entriesForDay = widget.repository.entriesForDay(selectedDay);
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 20),

        Text(
          "Wähle einen Tag aus.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "Cinzel",
            fontSize: 14,
            color: Color(0xFF8C6F5A),
            height: 1.1,
          ),
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekdays.map((w) {
            return Expanded(
              child: Center(
                child: Text(
                  w,
                  style: TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 14,
                    color: darkBrown,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 18),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.2,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < firstWeekday) {
              return const SizedBox.shrink();
            }

            final dayNumber = index - firstWeekday + 1;
            final date = DateTime(selectedDay.year, selectedDay.month, dayNumber);

            final isToday =
                date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;

                        final isSelected =
                date.year == selectedDay.year &&
                date.month == selectedDay.month &&
                date.day == selectedDay.day;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedDay = date;
                  _entriesForDay = widget.repository.entriesForDay(date);
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday
                      ? darkBrown.withOpacity(0.18)
                      : Colors.transparent,
                  border: isSelected
                      ? Border.all(
                          color: darkBrown.withOpacity(0.85),
                          width: 1.6,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$dayNumber",
                  style: TextStyle(
                    fontFamily: "Cinzel",
                    fontSize: 14,
                    color: darkBrown,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ⭐ Meine Beiträge
  Widget _buildEntries() {
    return FutureBuilder<List<JournalEntry>>(
      future: _entriesForDay,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data!;
        if (entries.isEmpty) {
          return Text(
            "Keine Einträge für diesen Tag.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 15,
              color: sand,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.menu_book,
                    color: Color(0xFF5A3E36), size: 20),
                const SizedBox(width: 6),
                Text(
                  "Meine Beiträge",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "NewFirst",
                    fontSize: 26,
                    color: darkBrown,
                    height: 1.1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ...entries.asMap().entries.map((e) {
              final index = e.key;
              final entry = e.value;
              final isLast = index == entries.length - 1;

              return GestureDetector(
                onTap: () async {
                  final changed = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JournalEntryDetailScreen(entry: entry),
                    ),
                  );

                  if (changed == true) {
                    _reload();
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(
                    left: 10,
                    right: 10,
                    bottom: isLast ? 32 : 20,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: "NewFirst",
                                fontSize: 20,
                                color: darkBrown,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.sticker,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ⭐ AUDIO-EINTRAG
                      if (entry.audio != null) ...[
                        Row(
                          children: const [
                            Icon(Icons.mic, size: 20, color: Colors.black87),
                            SizedBox(width: 8),
                            Text(
                              "Audioaufnahme gespeichert",
                              style: TextStyle(
                                fontFamily: "Cinzel",
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        if (entry.text.isNotEmpty)
                          Text(
                            entry.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: "Cinzel",
                              fontSize: 13.5,
                              color: darkBrown.withOpacity(0.75),
                              height: 1.25,
                            ),
                          ),
                      ]

                      // ⭐ FOTO-EINTRAG
                      else if (entry.photo != null) ...[
                        Row(
                          children: const [
                            Icon(Icons.photo_camera,
                                size: 20, color: Colors.black87),
                            SizedBox(width: 8),
                            Text(
                              "Foto gespeichert",
                              style: TextStyle(
                                fontFamily: "Cinzel",
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(entry.photo!),
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                        const SizedBox(height: 6),

                        if (entry.text.isNotEmpty)
                          Text(
                            entry.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: "Cinzel",
                              fontSize: 13.5,
                              color: darkBrown.withOpacity(0.75),
                              height: 1.25,
                            ),
                          ),
                      ]

                      // ⭐ NORMALER TEXT-EINTRAG
                      else
                        Text(
                          entry.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: "Cinzel",
                            fontSize: 13.5,
                            color: darkBrown.withOpacity(0.75),
                            height: 1.25,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
