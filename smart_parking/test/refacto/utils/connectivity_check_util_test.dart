import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/core/utils/connectivity_check_util.dart';

/// Tests unitaires — checkRealInternet
///
/// Logique extraite de ConnectivityNotifier pour être testable sans
/// toucher au plugin connectivity_plus ni au réseau réel — même
/// principe que booking_conflict_util.dart et
/// booking_reminder_util.dart. Le [lookup] DNS est injecté, ce qui
/// permet de simuler succès, échec et timeout de façon déterministe.

Future<List<InternetAddress>> _fakeSuccessLookup(String host) async {
  return [InternetAddress('142.250.180.14')]; // IP factice de google.com
}

Future<List<InternetAddress>> _fakeEmptyLookup(String host) async {
  return [];
}

Future<List<InternetAddress>> _fakeFailingLookup(String host) async {
  throw const SocketException('Aucune connexion Internet');
}

Future<List<InternetAddress>> _fakeSlowLookup(String host) async {
  await Future.delayed(const Duration(seconds: 10));
  return [InternetAddress('142.250.180.14')];
}

void main() {
  group('checkRealInternet — pas de connexion système', () {
    test('retourne false immédiatement sans tenter de résolution DNS'
        ' si status=none', () async {
      var lookupCalled = false;
      final result = await checkRealInternet(
        ConnectivityResult.none,
        lookup: (host) async {
          lookupCalled = true;
          return _fakeSuccessLookup(host);
        },
      );

      expect(result, isFalse);
      expect(lookupCalled, isFalse,
          reason: 'Aucune tentative DNS n\'est nécessaire si le système '
              'signale déjà une absence totale de connexion');
    });
  });

  group('checkRealInternet — WiFi avec vraie connexion', () {
    test('retourne true quand la résolution DNS réussit', () async {
      final result = await checkRealInternet(
        ConnectivityResult.wifi,
        lookup: _fakeSuccessLookup,
      );

      expect(result, isTrue);
    });
  });

  group('checkRealInternet — WiFi sans vraie connexion (portail captif)',
      () {
    test('retourne false si la résolution DNS échoue (SocketException)',
        () async {
      final result = await checkRealInternet(
        ConnectivityResult.wifi,
        lookup: _fakeFailingLookup,
      );

      expect(result, isFalse,
          reason: 'Reproduit le cas WiFi connecté à un routeur mais '
              'sans accès Internet réel (portail captif, forfait '
              'épuisé, etc.)');
    });

    test('retourne false si la résolution DNS renvoie une liste vide',
        () async {
      final result = await checkRealInternet(
        ConnectivityResult.wifi,
        lookup: _fakeEmptyLookup,
      );

      expect(result, isFalse);
    });
  });

  group('checkRealInternet — données mobiles', () {
    test('fonctionne identiquement pour ConnectivityResult.mobile',
        () async {
      final result = await checkRealInternet(
        ConnectivityResult.mobile,
        lookup: _fakeSuccessLookup,
      );

      expect(result, isTrue);
    });
  });

  group('checkRealInternet — timeout', () {
    test('retourne false si la résolution DNS dépasse le délai imparti',
        () async {
      final result = await checkRealInternet(
        ConnectivityResult.wifi,
        lookup: _fakeSlowLookup,
        timeout: const Duration(milliseconds: 100),
      );

      expect(result, isFalse,
          reason: 'Une résolution DNS trop lente doit être considérée '
              'comme un échec de connexion, pas bloquer l\'app '
              'indéfiniment');
    });

    test('réussit si la résolution DNS est plus rapide que le délai',
        () async {
      final result = await checkRealInternet(
        ConnectivityResult.wifi,
        lookup: _fakeSuccessLookup,
        timeout: const Duration(seconds: 5),
      );

      expect(result, isTrue);
    });
  });

  group('checkRealInternet — délai par défaut', () {
    test('utilise 5 secondes si aucun timeout n\'est précisé', () async {
      // Vérifie juste que l'appel fonctionne sans erreur avec les
      // valeurs par défaut (lookup réel non utilisé ici — on override
      // quand même pour rester 100% déterministe et rapide)
      final result = await checkRealInternet(
        ConnectivityResult.wifi,
        lookup: _fakeSuccessLookup,
      );

      expect(result, isTrue);
    });
  });
}
