import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lutalia/screens/food_tracking_screen.dart';
import '../theme/theme.dart';
import 'shop_screen.dart';
import 'personal_screen.dart';
import 'wasser_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, RouteAware {
  String? uid;

  late AnimationController butterflyController;
  late AnimationController leftTextController;
  late Animation<Offset> leftTextOffset;
  late AnimationController rightTextController;
  late Animation<Offset> rightTextOffset;
  late VideoPlayerController videoController;
  late AnimationController videoFadeController;
  late Animation<double> videoFade;
  late AnimationController titleFadeController;
  late Animation<double> titleFade;

  final Random random = Random();
  final int butterflyCount = 22;

  double waterLiters = 0.0;
  double waterGoal = 2.0;

  double kcal = 0;
  double carbs = 0;
  double fat = 0;
  double protein = 0;

  int steps = 0;
  double sleepHours = 0;

  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();

    uid = FirebaseAuth.instance.currentUser?.uid;

    videoFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    videoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: videoFadeController, curve: Curves.easeInOut),
    );

    titleFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: titleFadeController, curve: Curves.easeInOut),
    );

    videoController = VideoPlayerController.asset(
      'assets/videos/Weil-es-gluecklich-macht.mp4',
    )..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        videoController.setLooping(true);
        videoController.play();
        videoFadeController.forward();
      });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      titleFadeController.forward();
    });

    butterflyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    leftTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    leftTextOffset = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: leftTextController, curve: Curves.easeOut),
    );

    rightTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    rightTextOffset = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: rightTextController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      leftTextController.forward();
      rightTextController.forward();
    });

    if (uid != null) {
      _loadWaterToday();
      _loadNutritionToday();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void didPopNext() {
    if (uid != null) {
      _loadNutritionToday();
      _loadWaterToday();
    }
    setState(() {});
  }

  Future<void> _loadWaterToday() async {
    if (uid == null) return;

    final now = DateTime.now();
    final key =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("water")
        .doc(key)
        .collection("data")
        .doc("entry")
        .get();

    if (doc.exists) {
      final count = (doc.data()?["count"] ?? 0) as int;
      const glassMl = 200;

      setState(() {
        waterLiters = (count * glassMl) / 1000;
      });
    } else {
      setState(() => waterLiters = 0);
    }
  }

  /// 🔥 Holt die Tages-Nährwerte aus Firestore, basierend auf den Mahlzeiten-Listen
  Future<void> _loadNutritionToday() async {
    if (uid == null) return;

    final now = DateTime.now();
    final key =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("meals")
        .doc(key)
        .get();

    if (!doc.exists) {
      setState(() {
        kcal = 0;
        carbs = 0;
        fat = 0;
        protein = 0;
      });
      return;
    }

    final data = doc.data() ?? {};

    double totalKcal = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalProtein = 0;

    for (final meal in ["breakfast", "lunch", "dinner", "snacks"]) {
      final list = List<Map<String, dynamic>>.from(data[meal] ?? []);

      for (final item in list) {
        totalKcal += (item["kcal"] ?? 0).toDouble();
        totalCarbs += (item["carbs"] ?? 0).toDouble();
        totalFat += (item["fat"] ?? 0).toDouble();
        totalProtein += (item["protein"] ?? 0).toDouble();
      }
    }

    setState(() {
      kcal = totalKcal;
      carbs = totalCarbs;
      fat = totalFat;
      protein = totalProtein;
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    butterflyController.dispose();
    leftTextController.dispose();
    rightTextController.dispose();
    videoController.dispose();
    videoFadeController.dispose();
    titleFadeController.dispose();
    super.dispose();
  }

  Widget tinyButterfly(String asset, double screenWidth, double screenHeight) {
    final double startX = random.nextDouble() * screenWidth;
    final double endX = random.nextDouble() * screenWidth;

    final double startY = random.nextDouble() * screenHeight;
    final double endY = random.nextDouble() * screenHeight;

    final double size = random.nextDouble() * 6 + 4;

    return AnimatedBuilder(
      animation: butterflyController,
      builder: (context, child) {
        final t = butterflyController.value;

        return Transform.translate(
          offset: Offset(
            lerpDouble(startX, endX, t)!,
            lerpDouble(startY, endY, t)! + sin(t * 2 * pi) * 8,
          ),
          child: Opacity(
            opacity: 0.45 + sin(t * 2 * pi) * 0.25,
            child: Image.asset(asset, width: size, height: size),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final now = DateTime.now();
    final weekday = [
      "Montag",
      "Dienstag",
      "Mittwoch",
      "Donnerstag",
      "Freitag",
      "Samstag",
      "Sonntag"
    ][now.weekday - 1];

    final monthNames = [
      "Januar",
      "Februar",
      "März",
      "April",
      "Mai",
      "Juni",
      "Juli",
      "August",
      "September",
      "Oktober",
      "November",
      "Dezember"
    ];

    final formattedDate =
        "${now.day}. ${monthNames[now.month - 1]} ${now.year}";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EFE6),
        elevation: 0,
        toolbarHeight: 85,
        centerTitle: true,
        title: SizedBox(
          height: 60,
          child: Image.asset(
            'assets/logo/logoheader.png',
            fit: BoxFit.contain,
          ),
        ),
        leadingWidth: 90,
        leading: Row(
          children: [
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.shopping_bag_rounded,
                size: 28,
                color: Color(0xFFD49A84),
              ),
              onPressed: () {
                if (!isLoggedIn) {
                  Navigator.pushNamed(context, "/login");
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShopScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_rounded,
              size: 28,
              color: Color(0xFFD49A84),
            ),
            onPressed: () {
              if (!isLoggedIn) {
                Navigator.pushNamed(context, "/login");
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PersonalScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          ...List.generate(
            butterflyCount,
            (index) => tinyButterfly(
              index.isEven
                  ? "assets/images/butterfly_pink.png"
                  : "assets/images/butterfly_green.png",
              screenWidth,
              screenHeight,
            ),
          ),
          Column(
            children: [
              SizedBox(
                width: screenWidth,
                height: screenHeight * 0.34,
                child: videoController.value.isInitialized
                    ? FadeTransition(
                        opacity: videoFade,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: videoController.value.size.width,
                            height: videoController.value.size.height,
                            child: VideoPlayer(videoController),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: titleFade,
                        child: Text(
                          'Selfcare & Inspirationen',
                          style: TextStyle(
                            fontFamily: "NewFirst",
                            fontSize: 36,
                            color: LutaliaTheme.espresso,
                          ),
                        ),
                      ),
                      const SizedBox(height: 38),
                      SlideTransition(
                        position: leftTextOffset,
                        child: Text(
                          'Ein Raum für dich.',
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 20,
                            color: LutaliaTheme.espresso,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SlideTransition(
                        position: rightTextOffset,
                        child: Text(
                          'Ein Moment zum Atmen.',
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 20,
                            color: LutaliaTheme.espresso,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            weekday,
                            style: TextStyle(
                              fontFamily: "NewFirst",
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: LutaliaTheme.latte,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontFamily: "NewFirst",
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: LutaliaTheme.latte,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 120),
                      GestureDetector(
                        onTap: () {
                          if (!isLoggedIn) {
                            Navigator.pushNamed(context, "/login");
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WasserScreen(
                                selectedDate: DateTime.now(),
                              ),
                            ),
                          );
                        },
                        child: _waterCard(),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          if (!isLoggedIn) {
                            Navigator.pushNamed(context, "/login");
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FoodTrackingScreen(),
                            ),
                          );
                        },
                        child: _nutritionCard(),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          if (!isLoggedIn) {
                            Navigator.pushNamed(context, "/login");
                            return;
                          }
                        },
                        child: _stepsCard(),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          if (!isLoggedIn) {
                            Navigator.pushNamed(context, "/login");
                            return;
                          }
                        },
                        child: _sleepCard(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _waterCard() {
    final double percent =
        (waterGoal == 0) ? 0.0 : (waterLiters / waterGoal).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Wasser heute",
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${waterLiters.toStringAsFixed(1)} L von ${waterGoal.toStringAsFixed(1)} L",
            style: const TextStyle(
              fontFamily: "Cinzel",
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB3AA97),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent.toDouble(),
              minHeight: 10,
              backgroundColor:
                  const Color(0xFFFAF8F4).withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFB3AA97),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Tippen, um zum Wasser‑Screen zu wechseln",
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutritionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Nährwerte des Tages",
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _nutriItem("Kalorien", kcal.toStringAsFixed(0)),
              _nutriItem("KH", carbs.toStringAsFixed(0)),
              _nutriItem("Fett", fat.toStringAsFixed(0)),
              _nutriItem("Eiweiß", protein.toStringAsFixed(0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nutriItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: "Cinzel",
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB3AA97),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Cinzel",
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _stepsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Schritte heute",
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "$steps Schritte",
            style: const TextStyle(
              fontFamily: "Cinzel",
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB3AA97),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Schrittdaten werden später verbunden",
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sleepCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Schlaftracking",
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${sleepHours.toStringAsFixed(1)} Stunden",
            style: const TextStyle(
              fontFamily: "Cinzel",
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB3AA97),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Schlafdaten werden später verbunden",
            style: TextStyle(
              fontFamily: "Cinzel",
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
