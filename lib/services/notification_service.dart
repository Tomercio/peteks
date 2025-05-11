import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/note.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import '../ui/screens/note_screen.dart';
import '../main.dart';
import '../services/storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          // Fetch the note using StorageService singleton
          final storageService = StorageService();
          final note = storageService.getNote(payload);
          if (note != null) {
            // Use navigatorKey to push NoteScreen
            MyApp.navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => NoteScreen(note: note),
                settings: const RouteSettings(name: '/note'),
              ),
            );
          }
        }
      },
    );

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'note_reminder_channel',
      'Note Reminders',
      description: 'Reminders for your notes',
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request notification permissions
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> scheduleNoteReminder(Note note) async {
    if (note.reminderDateTime == null) return;

    final id = note.id.hashCode;
    final scheduledDate = tz.TZDateTime.from(note.reminderDateTime!, tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Note Reminder',
      note.title.isNotEmpty ? note.title : 'Reminder',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'note_reminder_channel',
          'Note Reminders',
          channelDescription: 'Reminders for your notes',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: note.id,
    );
  }

  Future<void> cancelNoteReminder(Note note) async {
    final id = note.id.hashCode;
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllReminders() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
