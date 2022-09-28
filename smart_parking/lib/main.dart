import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/localization/l10n.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking/notifiers/location_notifier.dart';
import 'package:smart_parking/notifiers/state_management.dart';
import 'package:smart_parking/screens/inside_app/home.dart';
import 'screens/authenticate/login_register.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var status = prefs.getBool('isLoggedIn') ??
      true; //true means user logged OUT and false means he's already logged in. could rename to 'userHasToLogIn
  debugPrint("PREF STATUS $status");
  await Firebase.initializeApp();
  runApp(MyApp(status: status));
}

class MyApp extends StatefulWidget {
  final bool status;
  const MyApp({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CurrentLocationNotifier(),
        ),
        ChangeNotifierProvider(
          create: (_) => StateManagement(),
        )
      ],
      builder: (context, child) {
        return MaterialApp(
          supportedLocales: FormBuilderLocalizations.delegate.supportedLocales,
          localizationsDelegates: const [
            FormBuilderLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            // Define the default brightness and colors.
            brightness: Brightness.light,
            primaryColor: Colors.indigo,
            // Define the default font family.
          ),
          home: widget.status == true
              ? const LoginRegister()
              : const Home(fromLoginView: true),
        );
      },
    );
  }
}
