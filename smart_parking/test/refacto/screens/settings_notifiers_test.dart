import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking/app/screens/settings/settings_screen.dart';

/// Tests unitaires — ThemeModeNotifier & NotifSettingsNotifier
///
/// Couvre la persistance des préférences (SharedPreferences) pour le
/// thème et les réglages de notifications individuels — la logique
/// derrière chaque toggle de l'écran Paramètres, y compris la règle
/// "allEnabled devient false seulement si TOUS les rappels sont
/// désactivés" (comportement du master switch).
///
/// LocaleNotifier n'est volontairement pas testé ici : il appelle
/// Get.updateLocale() (package GetX) qui nécessite un contexte
/// d'application initialisé, hors périmètre d'un test unitaire pur.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeNotifier', () {
    test('démarre avec ThemeMode.system par défaut (avant chargement)', () {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeModeNotifier();
      expect(notifier.state, ThemeMode.system);
    });

    test('charge le thème sombre depuis les préférences sauvegardées',
        () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final notifier = ThemeModeNotifier();

      // Laisse le temps à _load() (async) de s'exécuter
      await Future.delayed(Duration.zero);

      expect(notifier.state, ThemeMode.dark);
    });

    test('setTheme met à jour l\'état et persiste le choix', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeModeNotifier();

      await notifier.setTheme(ThemeMode.light);

      expect(notifier.state, ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });
  });

  group('NotifSettingsNotifier — chargement initial', () {
    test('tous les rappels activés par défaut si aucune préférence'
        ' sauvegardée', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = NotifSettingsNotifier();
      await Future.delayed(Duration.zero);

      expect(notifier.state.allEnabled, isTrue);
      expect(notifier.state.remind30min, isTrue);
      expect(notifier.state.remind10min, isTrue);
      expect(notifier.state.remindStart, isTrue);
      expect(notifier.state.remindEnd15min, isTrue);
    });

    test('charge des préférences personnalisées sauvegardées', () async {
      SharedPreferences.setMockInitialValues({
        'notif_all': true,
        'notif_30min': false,
        'notif_10min': true,
        'notif_start': false,
        'notif_end15': true,
      });
      final notifier = NotifSettingsNotifier();
      await Future.delayed(Duration.zero);

      expect(notifier.state.remind30min, isFalse);
      expect(notifier.state.remind10min, isTrue);
      expect(notifier.state.remindStart, isFalse);
    });
  });

  group('NotifSettingsNotifier — setAll (master switch)', () {
    test('setAll(false) désactive tous les rappels individuels', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = NotifSettingsNotifier();
      await Future.delayed(Duration.zero);

      await notifier.setAll(false);

      expect(notifier.state.allEnabled, isFalse);
      expect(notifier.state.remind30min, isFalse);
      expect(notifier.state.remind10min, isFalse);
      expect(notifier.state.remindStart, isFalse);
      expect(notifier.state.remindEnd15min, isFalse);
    });

    test('setAll(true) réactive tous les rappels', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = NotifSettingsNotifier();
      await Future.delayed(Duration.zero);

      await notifier.setAll(false);
      await notifier.setAll(true);

      expect(notifier.state.allEnabled, isTrue);
      expect(notifier.state.remind30min, isTrue);
    });

    test('setAll persiste le choix dans SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = NotifSettingsNotifier();
      await Future.delayed(Duration.zero);

      await notifier.setAll(false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notif_all'), isFalse);
      expect(prefs.getBool('notif_30min'), isFalse);
    });
  });

  group('NotifSettingsNotifier — toggle (réglages individuels)', () {
    test('désactive uniquement le rappel 30min sans affecter les autres',
        () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = NotifSettingsNotifier();
      await Future.delayed(Duration.zero);

      await notifier.toggle(remind30min: false);

      expect(notifier.state.remind30min, isFalse);
      expect(notifier.state.remind10min, isTrue);
      expect(notifier.state.remindStart, isTrue);
      expect(notifier.state.remindEnd15min, isTrue);
    });

    test('allEnabled reste true tant qu\'au moins un rappel est activé',
        () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = NotifSettingsNotifier();
      await Future.delayed(Duration.zero);

      await notifier.toggle(remind30min: false);
      await notifier.toggle(remind10min: false);
      await notifier.toggle(remindStart: false);
      // remindEnd15min reste true

      expect(notifier.state.allEnabled, isTrue,
          reason: 'Au moins un rappel (remindEnd15min) est encore actif');
    });

    test('allEnabled devient false uniquement quand TOUS les rappels'
        ' sont désactivés un par un', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = NotifSettingsNotifier();
      await Future.delayed(Duration.zero);

      await notifier.toggle(remind30min: false);
      await notifier.toggle(remind10min: false);
      await notifier.toggle(remindStart: false);
      await notifier.toggle(remindEnd15min: false);

      expect(notifier.state.allEnabled, isFalse,
          reason: 'Reproduit le comportement attendu du master switch: '
              'il se désactive automatiquement si plus aucun rappel '
              'individuel n\'est actif');
    });

    test('réactiver un seul rappel après tout avoir désactivé remet'
        ' allEnabled à true', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = NotifSettingsNotifier();
      await Future.delayed(Duration.zero);

      await notifier.setAll(false);
      await notifier.toggle(remind30min: true);

      expect(notifier.state.allEnabled, isTrue);
      expect(notifier.state.remind30min, isTrue);
      expect(notifier.state.remind10min, isFalse);
    });
  });

  group('NotifSettings — copyWith (logique pure)', () {
    test('conserve les valeurs non modifiées', () {
      const original = NotifSettings(remind30min: false);
      final updated = original.copyWith(remind10min: false);

      expect(updated.remind30min, isFalse);
      expect(updated.remind10min, isFalse);
      expect(updated.remindStart, isTrue);
    });
  });
}
