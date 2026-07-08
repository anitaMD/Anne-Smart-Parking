import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/localization/l10n.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'package:smart_parking/l10n/generated/app_localizations.dart';
import 'package:smart_parking/l10n/l10n.dart';
import 'package:smart_parking/old/notifiers/booking_state_management.dart';
import 'package:smart_parking/old/notifiers/location_notifier.dart';
import 'package:smart_parking/old/screens/authenticate/testlogin.dart';
import 'package:smart_parking/old/screens/inside_app/testhome.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await init;
  debugPrint("Handling a background message...: ${message.notification!.body}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final init = Firebase.initializeApp();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
    playSound: true);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var status = prefs.getBool('isLoggedIn') ??
      true; //true means user logged OUT and false means he's already logged in. could rename to 'userHasToLogIn
  debugPrint("PREF STATUS $status");
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

// Firebase local notification plugin
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

//Firebase messaging
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(MyApp(status: status));
}

class MyApp extends StatefulWidget {
  final bool status;
  const MyApp({
    super.key,
    required this.status,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CurrentLocationNotifier(),
        ),
        ChangeNotifierProvider(
          create: (_) => BookingStateManagement(),
        ),
      ],
      builder: (context, child) {
        return GetMaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('fr', 'FR'),
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: Colors.indigo,
          ),
          supportedLocales: L10n.all,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            FormBuilderLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          home: widget.status == true
              ? const TestLogin()
              : const TestHome(
                  timeUntilReservationStarts: 0,
                  newMoreUrgentBooking: {},
                ),
          /* widget.status == true
              ? const LoginRegister()
              : const Home(
                  fromLoginView: true,
                  parkingToNavigateTo: {},
                  newIndex: 0,
                  timeUntilResStarts: 0,
                ), */
        );
      },
    );
  }
}
