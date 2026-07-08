import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:smart_parking/l10n/generated/app_localizations.dart';
import 'package:smart_parking/l10n/l10n.dart';
import 'package:smart_parking/app/core/theme/app_theme.dart';
import 'package:smart_parking/app/screens/settings/settings_screen.dart';
import 'package:smart_parking/app/viewmodels/booking_viewmodel.dart';
import 'package:smart_parking/app/viewmodels/parking_viewmodel.dart';
import 'package:smart_parking/app/viewmodels/user_viewmodel.dart';
import 'package:smart_parking/app/widgets/connectivity_wrapper.dart';
import 'package:smart_parking/app/router/app_router.dart';
import 'package:timezone/data/latest.dart' as tz;

// ── Screens (à décommenter au fur et à mesure) ─────────────
// import 'package:smart_parking/refacto/screens/auth/login_screen.dart';
// import 'package:smart_parking/refacto/screens/dashboard/home_screen.dart';

// ─────────────────────────────────────────────────────────────
// GLOBALS
// ─────────────────────────────────────────────────────────────

/// Clé de navigation globale — accès sans BuildContext
/// Utilisé par NotificationService pour naviguer depuis un service
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final _firebaseInit = Firebase.initializeApp();

const AndroidNotificationChannel _notificationChannel =
    AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Canal pour les notifications importantes YSP',
  importance: Importance.high,
  playSound: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ─────────────────────────────────────────────────────────────
// BACKGROUND MESSAGE HANDLER
// ─────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _firebaseInit;
  debugPrint('📬 Background message: ${message.notification?.body}');
}

// ─────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await _firebaseInit;

  final user = await FirebaseAuth.instance.authStateChanges().first;
  final bool mustLogin = user == null;

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_notificationChannel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(
    // ProviderScope remplace MultiProvider
    // BONNE PRATIQUE Riverpod : ProviderScope est le seul
    // widget nécessaire — tous les providers sont déclarés
    // dans leurs propres fichiers, pas ici
    ProviderScope(
      child: YSPApp(mustLogin: mustLogin),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// ROOT WIDGET
// ─────────────────────────────────────────────────────────────

// BONNE PRATIQUE Riverpod : le widget root hérite de
// ConsumerWidget (pas StatelessWidget) pour avoir accès à ref
class YSPApp extends ConsumerWidget {
  final bool mustLogin;
  const YSPApp({super.key, required this.mustLogin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userProvider); //DO NOT EVER DELETE THESE
    ref.watch(parkingProvider);
    ref.watch(bookingProvider);
    final locale = ref.watch(localeProvider);

    return GetMaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: L10n.all,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FormBuilderLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: mustLogin ? AppRoutes.login : AppRoutes.home,
      builder: (context, child) => ConnectivityWrapper(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
