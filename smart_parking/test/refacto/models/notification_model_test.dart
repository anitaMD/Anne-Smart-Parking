import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/models/notification_model.dart';

/// Tests unitaires — NotificationModel
///
/// Couvre l'état lu/non-lu utilisé pour le badge de notifications
/// et le fix de duplication (le state local doit refléter
/// correctement isRead après un swipe/tap — bug corrigé en session
/// où la même notification apparaissait plusieurs fois).

NotificationModel _makeNotification({
  bool isRead = false,
  String title = '✅ Réservation confirmée !',
}) {
  return NotificationModel(
    id: 'notif-1',
    title: title,
    body: 'Place A1 — ECPI Smart Parking',
    isRead: isRead,
    receivedAt: DateTime.now(),
  );
}

void main() {
  group('NotificationModel — copyWith (isRead)', () {
    test('marque une notification comme lue', () {
      final original = _makeNotification(isRead: false);
      final updated = original.copyWith(isRead: true);

      expect(updated.isRead, isTrue);
      expect(original.isRead, isFalse,
          reason: 'L\'original ne doit pas être modifié (immutabilité)');
    });

    test('conserve isRead si non spécifié', () {
      final original = _makeNotification(isRead: true);
      final updated = original.copyWith();

      expect(updated.isRead, isTrue);
    });

    test('conserve title et body après copyWith', () {
      final original = _makeNotification(
        title: '💰 Rechargement effectué !',
      );
      final updated = original.copyWith(isRead: true);

      expect(updated.title, '💰 Rechargement effectué !');
      expect(updated.body, original.body);
      expect(updated.id, original.id);
    });
  });

  group('NotificationModel — construction', () {
    test('crée une notification avec les bons champs', () {
      final notif = _makeNotification();

      expect(notif.id, 'notif-1');
      expect(notif.title, isNotEmpty);
      expect(notif.body, isNotEmpty);
      expect(notif.isRead, isFalse);
    });
  });

  group('NotificationModel — toString', () {
    test('inclut l\'id et le titre', () {
      final notif = _makeNotification(title: '✅ Réservation confirmée !');
      expect(notif.toString(), contains('notif-1'));
      expect(notif.toString(), contains('✅ Réservation confirmée !'));
    });
  });
}
