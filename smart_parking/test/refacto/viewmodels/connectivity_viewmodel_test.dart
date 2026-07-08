import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/viewmodels/connectivity_viewmodel.dart';

void main() {
  group('ConnectivityState', () {
    test('état initial — pas de connexion', () {
      const state = ConnectivityState();
      expect(state.isConnected, false);
      expect(state.isInitialized, false);
    });

    test('copyWith — met à jour correctement', () {
      const state = ConnectivityState();
      final updated = state.copyWith(
        hasRealInternet: true,
        isInitialized: true,
      );
      expect(updated.isConnected, true);
      expect(updated.isInitialized, true);
      // L'original reste inchangé (immutabilité)
      expect(state.isConnected, false);
    });

    test('isWifi — vrai seulement si WiFi', () {
      const wifiState = ConnectivityState(
        status: ConnectivityResult.wifi,
        hasRealInternet: true,
        isInitialized: true,
      );
      expect(wifiState.isWifi, true);
      expect(wifiState.isMobile, false);
    });

    test('isMobile — vrai seulement si données mobiles', () {
      const mobileState = ConnectivityState(
        status: ConnectivityResult.mobile,
        hasRealInternet: true,
        isInitialized: true,
      );
      expect(mobileState.isMobile, true);
      expect(mobileState.isWifi, false);
    });

    test('isConnected — false même si mobile sans données réelles', () {
      const state = ConnectivityState(
        status: ConnectivityResult.mobile,
        hasRealInternet: false, // mobile activé mais pas de forfait
        isInitialized: true,
      );
      expect(state.isConnected, false);
    });
  });
}
