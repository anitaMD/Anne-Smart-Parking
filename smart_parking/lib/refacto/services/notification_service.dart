import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firestore_service.dart';

/// Service de notifications YSP Smart Parking
///
/// Gère deux types de notifications :
/// 1. Notifications locales (flutter_local_notifications)
///    → affichées immédiatement sur l'appareil
/// 2. Notifications Firebase (FCM)
///    → reçues depuis le serveur, sauvegardées dans Firestore
///
/// BONNE PRATIQUE : on utilise navigatorKey (défini dans main.dart)
/// pour afficher des dialogs sans BuildContext
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
    // 1. Paramètres Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 2. Créer le canal Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Écouter les messages FCM en premier plan
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 4. Écouter les taps sur notifications en arrière-plan
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  // ── Token FCM ─────────────────────────────────────────────

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // ── Envoyer une notification locale ──────────────────────

  /// Affiche une notification locale immédiatement
  /// et la sauvegarde dans Firestore
  Future<void> show({
    required String title,
    required String body,
    String? uid,
  }) async {
    // Afficher la notification locale
    await _localNotifications.show(
      id: DateTime.now().millisecond, // ID unique
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );

    // Sauvegarder dans Firestore si l'utilisateur est connecté
    if (uid != null) {
      await _firestoreService.saveNotification(
        uid: uid,
        title: title,
        body: body,
      );
    }
  }

  // ── Handlers privés ───────────────────────────────────────

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await show(
      title: notification.title ?? '',
      body: notification.body ?? '',
      uid: FirebaseAuth.instance.currentUser?.uid,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navigation lors du tap sur une notification
    // Ex: aller sur l'écran des réservations
    // navigatorKey.currentState?.pushNamed('/bookings');
  }

  void _onNotificationTap(NotificationResponse response) {
    // Tap sur notification locale
  }
}
