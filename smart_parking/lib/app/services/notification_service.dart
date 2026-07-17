import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/booking_model.dart';
import '../core/utils/booking_reminder_util.dart';
import 'firestore_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirestoreService _firestoreService;
  bool _isRequestingExactAlarm = false;
  bool _isRequestingNotif = false;

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
          icon:
              '@drawable/ic_notification', /*
          actions: const [
            AndroidNotificationAction('snooze_5', 'Reporter 5min'),
            AndroidNotificationAction('snooze_10', 'Reporter 10min'),
          ],*/
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

  Future<void> scheduleBookingReminders(
    BookingModel booking, {
    required Locale locale,
    bool remind30min = true,
    bool remind10min = true,
    bool remindStart = true,
    bool remindEnd15min = true,
  }) async {
    await cancelBookingReminders(booking.id);

    // Décision (logique pure, testable indépendamment) :
    final specs = computeBookingReminders(
      booking,
      now: DateTime.now(),
      locale: locale,
      remind30min: remind30min,
      remind10min: remind10min,
      remindStart: remindStart,
      remindEnd15min: remindEnd15min,
    );

    // Effet de bord — transmission au plugin natif :
    for (final spec in specs) {
      await _scheduleReminder(
        id: spec.id,
        title: spec.title,
        body: spec.body,
        scheduledDate: spec.scheduledDate,
      );
    }
  }

  Future<void> cancelBookingReminders(String bookingId) async {
    for (final suffix in ['_30', '_10', '_start', '_end15', '_ended']) {
      await _localNotifications.cancel(id: reminderIdFor(bookingId, suffix));
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

  Future<bool> areNotificationsEnabled() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.areNotificationsEnabled() ?? false;
  }

  Future<bool> requestPermission() async {
    if (_isRequestingNotif) return false;
    _isRequestingNotif = true;
    try {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestNotificationsPermission() ?? false;
    } catch (e) {
      debugPrint('[Notif] requestPermission error: $e');
      return false;
    } finally {
      _isRequestingNotif = false;
    }
  }

  Future<bool> requestExactAlarmPermission() async {
    if (_isRequestingExactAlarm) return false;
    _isRequestingExactAlarm = true;

    try {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestExactAlarmsPermission() ?? false;
    } catch (e) {
      debugPrint('[Notif] requestExactAlarmPermission error: $e');
      return false;
    } finally {
      _isRequestingExactAlarm = false;
    }
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

    final canScheduleExact =
        await androidPlugin?.canScheduleExactNotifications() ?? false;

    debugPrint('[Notif] canScheduleExact: $canScheduleExact');

    // vérifier que le canal existe bien
    final channels = await androidPlugin?.getNotificationChannels();
    debugPrint(
        '[Notif] Channels: ${channels?.map((c) => "${c.id}:${c.importance}").join(", ")}');

    try {
      await _localNotifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: _reminderDetails,
        androidScheduleMode: canScheduleExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '$title|$body',
      );
      debugPrint('[Notif] _scheduleReminder SUCCESS id=$id');
    } catch (e) {
      debugPrint('[Notif] _scheduleReminder ERROR id=$id: $e');
    }
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

  void _onNotificationTap(NotificationResponse response) {
    debugPrint(
        '[Notif] Tapped: actionId=${response.actionId}, payload=${response.payload}, id=${response.id}');

    if (response.actionId == 'snooze_5' || response.actionId == 'snooze_10') {
      final minutes = response.actionId == 'snooze_5' ? 5 : 10;
      final parts = response.payload?.split('|') ?? [];
      final title = parts.isNotEmpty ? parts[0] : 'Rappel';
      final body = parts.length > 1 ? parts[1] : '';

      snoozeReminder(
        title: title,
        body: body,
        minutes: minutes,
        bookingId: '',
      );
    }
  }

  // ── FCM Token ──────────────────────────────────────────────

  Future<void> saveFcmToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      debugPrint('[Notification] FCM token: $token');

      if (token != null) {
        await _firestoreService.updateUser(uid, {'fcmToken': token});
      }

      // Écouter le refresh du token (arrive parfois, ex: réinstall app)
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('[Notification] FCM token refreshed: $newToken');
        await _firestoreService.updateUser(uid, {'fcmToken': newToken});
      });
    } catch (e) {
      debugPrint('[Notification] saveFcmToken error: $e');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
