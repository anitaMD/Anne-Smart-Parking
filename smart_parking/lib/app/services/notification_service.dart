import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/booking_model.dart';
import 'firestore_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirestoreService _firestoreService;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Canal pour les notifications importantes YSP',
    importance: Importance.high,
    playSound: true,
  );

  NotificationDetails get _defaultDetails => NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
      );

  NotificationDetails get _reminderDetails => NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'drawable/ic_notification',
          actions: const [
            AndroidNotificationAction('snooze_5', 'Reporter 5min'),
            AndroidNotificationAction('snooze_10', 'Reporter 10min'),
          ],
        ),
      );

  NotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    FirestoreService? firestoreService,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin(),
        _firestoreService = firestoreService ?? FirestoreService();

  // ── Initialisation ────────────────────────────────────────

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    // Android — afficher les notifications en foreground
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  // ── Token FCM ─────────────────────────────────────────────

  Future<String?> getToken() async => await _messaging.getToken();

  // ── Notification immédiate ────────────────────────────────

  Future<void> show({
    required String title,
    required String body,
    String? uid,
  }) async {
    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: _defaultDetails,
    );

    if (uid != null) {
      await _firestoreService.saveNotification(
        uid: uid,
        title: title,
        body: body,
      );
    }
  }

  // ── Rappels réservation ───────────────────────────────────

  Future<void> scheduleBookingReminders(BookingModel booking) async {
    final now = DateTime.now();
    await cancelBookingReminders(booking.id);

    final before30 = booking.bookingStart.subtract(const Duration(minutes: 30));
    if (before30.isAfter(now)) {
      await _scheduleReminder(
        id: '${booking.id}_30'.hashCode.abs() % 100000,
        title: '⏰ Rappel parking',
        body: 'Place ${booking.spotId} commence dans 30 minutes.',
        scheduledDate: before30,
      );
    }

    final before10 = booking.bookingStart.subtract(const Duration(minutes: 10));
    if (before10.isAfter(now)) {
      await _scheduleReminder(
        id: '${booking.id}_10'.hashCode.abs() % 100000,
        title: '🚗 Bientôt ! Place ${booking.spotId}',
        body: 'Votre réservation commence dans 10 minutes.',
        scheduledDate: before10,
      );
    }

    if (booking.bookingStart.isAfter(now)) {
      final h = booking.bookingEnd.hour.toString().padLeft(2, '0');
      final m = booking.bookingEnd.minute.toString().padLeft(2, '0');
      await _scheduleReminder(
        id: '${booking.id}_start'.hashCode.abs() % 100000,
        title: '! Réservation active — Place ${booking.spotId}',
        body: 'Fin prévue à $h:$m.',
        scheduledDate: booking.bookingStart,
      );
    }

    final before15End =
        booking.bookingEnd.subtract(const Duration(minutes: 15));
    if (before15End.isAfter(now)) {
      await _scheduleReminder(
        id: '${booking.id}_end'.hashCode.abs() % 100000,
        title: '⚠️ Fin dans 15min — Place ${booking.spotId}',
        body: 'Votre réservation se termine bientôt.',
        scheduledDate: before15End,
      );
    }
  }

  Future<void> cancelBookingReminders(String bookingId) async {
    for (final suffix in ['_30', '_10', '_start', '_end']) {
      await _localNotifications.cancel(
          id: '$bookingId$suffix'.hashCode.abs() % 100000);
    }
  }

  Future<void> snoozeReminder({
    required String title,
    required String body,
    required int minutes,
    required String bookingId,
  }) async {
    await _scheduleReminder(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: body,
      scheduledDate: DateTime.now().add(Duration(minutes: minutes)),
    );
  }

  Future<void> _scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final canSchedule =
        await androidPlugin?.canScheduleExactNotifications() ?? false;

    await _localNotifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: _reminderDetails,
      androidScheduleMode: canSchedule
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexact,
    );
  }

  // ── Handlers ─────────────────────────────────────────────

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await show(
      title: notification.title ?? '',
      body: notification.body ?? '',
      uid: FirebaseAuth.instance.currentUser?.uid,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {}

  void _onNotificationTap(NotificationResponse response) {}
}
