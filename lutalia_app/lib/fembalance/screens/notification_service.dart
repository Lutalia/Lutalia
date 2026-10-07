import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialisierung des Services
  Future<void> init() async {
    tz.initializeTimeZones();

    // Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Settings (falls relevant)
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Hier kannst du definieren, was passiert, wenn auf die Benachrichtigung getippt wird
      },
    );

    // WICHTIG: Android Notification Channel für maximale Priorität (Popups außerhalb der App)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'pill_reminder_channel_id', // ID muss exakt übereinstimmen
      'Pillen-Erinnerung',
      description: 'Wichtiger Kanal für die tägliche Pillen-Erinnerung',
      importance: Importance.max, // Zwingend für Popups!
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Methode zum Einplanen der täglichen Pillen-Benachrichtigung
  Future<void> schedulePillNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Details für Android mit maximaler Priorität und Vollbild-Intent
    AndroidNotificationDetails androidDetails = const AndroidNotificationDetails(
      'pill_reminder_channel_id',
      'Pillen-Erinnerung',
      channelDescription: 'Wichtiger Kanal für die tägliche Pillen-Erinnerung',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Pillen-Erinnerung',
      fullScreenIntent: true, // Erlaubt das Aufwachen/Popup über dem Sperrbildschirm
      category: AndroidNotificationCategory.alarm,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // Zeit in Zeitzone umwandeln
    tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // Falls die Zeit in der Vergangenheit liegt, für den nächsten Tag ansetzen
    if (tzScheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      tzScheduledTime = tzScheduledTime.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Wiederholt sich täglich zur gleichen Uhrzeit
    );
  }

  // Methode zum Testen (schickt sofort ein Popup)
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pill_reminder_channel_id',
      'Pillen-Erinnerung',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      999,
      'Pillen-Test',
      'Zeit für deine Pille! (Test-Popup)',
      platformDetails,
    );
  }

  // Benachrichtigung abbrechen (z.B. in der Pause)
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}