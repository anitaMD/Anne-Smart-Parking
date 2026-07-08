import 'package:flutter/material.dart';
import 'package:smart_parking/app/screens/dashboard/add_vehicle_screen.dart';
import 'package:smart_parking/app/screens/wallet/agent_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/dashboard/home_screen_drawer.dart';

/// Routeur centralisé YSP Smart Parking
///
/// BONNE PRATIQUE : toute la navigation est ici.
/// Les écrans n'utilisent jamais MaterialPageRoute directement —
/// ils appellent AppRouter.pushNamed(context, AppRoutes.home)
///
/// Avantages :
/// - Un seul endroit pour changer une destination
/// - Noms de routes constants → pas de fautes de frappe
/// - Transitions personnalisables au même endroit
class AppRouter {
  // Empêche l'instanciation
  AppRouter._();

  /// Génère la route selon le nom demandé
  /// Utilisé dans GetMaterialApp(onGenerateRoute: AppRouter.generateRoute)
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _slide(const LoginScreen());

      case AppRoutes.agent:
        return MaterialPageRoute(builder: (_) => const AgentScreen());

      case AppRoutes.register:
        return _slide(const RegisterScreen());

      case AppRoutes.otp:
        final args = settings.arguments as OTPArguments?;
        if (args == null) return _slide(const LoginScreen());
        return _slide(OTPScreen(
          verificationId: args.verificationId,
          phoneNumber: args.phoneNumber,
          isRegistration: args.isRegistration,
        ));

      case AppRoutes.home:
        return _fade(const HomeScreenDrawer());

      case AppRoutes.homeBottomNav:
        return _fade(const HomeScreenDrawer());

      case AppRoutes.addVehicle:
        return _slide(const AddVehicleScreen());

      default:
        return _slide(const LoginScreen());
    }
  }

  // ── Transitions ───────────────────────────────────────────

  /// Transition slide — pour les écrans d'auth (login → register)
  static PageRouteBuilder _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Transition fade — pour le dashboard (pas de retour arrière)
  static PageRouteBuilder _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  // ── Méthodes de navigation ────────────────────────────────

  /// Navigation simple
  static Future<void> push(BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  /// Navigation en remplaçant l'écran actuel
  static Future<void> replace(BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.pushReplacementNamed(context, routeName,
        arguments: arguments);
  }

  /// Navigation en vidant tout l'historique (après login)
  static Future<void> pushAndClearStack(BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
}

/// Noms des routes — constantes pour éviter les fautes de frappe
abstract class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String home = '/home';
  static const String homeBottomNav = '/home-drawer';
  static const String addVehicle = '/add-vehicle';
  static const String agent = '/agent';
}

/// Arguments pour l'écran OTP
/// On utilise une classe pour passer plusieurs paramètres proprement
class OTPArguments {
  final String verificationId;
  final String phoneNumber;
  final bool isRegistration;

  const OTPArguments({
    required this.verificationId,
    required this.phoneNumber,
    this.isRegistration = false,
  });
}
