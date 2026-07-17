import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/core/utils/booking_reminder_util.dart';
import 'package:smart_parking/app/models/booking_model.dart';

/// Tests unitaires — computeBookingReminders / reminderIdFor
///
/// Logique extraite de NotificationService.scheduleBookingReminders
/// pour être testable sans FirebaseMessaging ni plugin natif — même
/// principe que booking_conflict_util.dart. Couvre les 5 types de
/// rappels (30min, 10min, début, 15min avant fin, fin), le respect
/// des réglages utilisateur, et les cas limites de timing qui ont
/// causé plusieurs bugs de notifications manquantes en session.

BookingModel _booking({
  required DateTime start,
  required DateTime end,
  String spotId = 'A1',
}) {
  return BookingModel(
    id: 'booking-1',
    clientId: 'client-1',
    parkingId: 'parking-1',
    spotId: spotId,
    vehicleId: 'vehicle-1',
    bookingStart: start,
    bookingEnd: end,
    totalCost: 600,
    status: BookingStatus.upcoming,
  );
}

const _locale = Locale('fr');

void main() {
  group('reminderIdFor — génération d\'ID stable', () {
    test('génère le même ID pour le même bookingId et suffixe', () {
      final id1 = reminderIdFor('booking-1', '_30');
      final id2 = reminderIdFor('booking-1', '_30');

      expect(id1, id2);
    });

    test('génère des IDs différents pour des suffixes différents', () {
      final id30 = reminderIdFor('booking-1', '_30');
      final id10 = reminderIdFor('booking-1', '_10');

      expect(id30, isNot(id10));
    });

    test('génère des IDs différents pour des réservations différentes', () {
      final idA = reminderIdFor('booking-A', '_30');
      final idB = reminderIdFor('booking-B', '_30');

      expect(idA, isNot(idB));
    });

    test('l\'ID généré est toujours positif (compatible plugin natif)',
        () {
      final id = reminderIdFor('booking-1', '_ended');
      expect(id, greaterThanOrEqualTo(0));
      expect(id, lessThan(100000));
    });
  });

  group('computeBookingReminders — réservation largement dans le futur', () {
    test('retourne les 5 rappels quand tout est activé', () {
      final now = DateTime(2026, 7, 16, 10, 0);
      final booking = _booking(
        start: DateTime(2026, 7, 16, 14, 0),
        end: DateTime(2026, 7, 16, 16, 0),
      );

      final specs = computeBookingReminders(
        booking,
        now: now,
        locale: _locale,
      );

      expect(specs.length, 5,
          reason: '30min, 10min, début, 15min-avant-fin, fin');
    });

    test('les rappels sont programmés aux bonnes heures', () {
      final now = DateTime(2026, 7, 16, 10, 0);
      final start = DateTime(2026, 7, 16, 14, 0);
      final end = DateTime(2026, 7, 16, 16, 0);
      final booking = _booking(start: start, end: end);

      final specs = computeBookingReminders(
        booking,
        now: now,
        locale: _locale,
      );

      final dates = specs.map((s) => s.scheduledDate).toList();

      expect(dates, contains(start.subtract(const Duration(minutes: 30))));
      expect(dates, contains(start.subtract(const Duration(minutes: 10))));
      expect(dates, contains(start));
      expect(dates, contains(end.subtract(const Duration(minutes: 15))));
      expect(dates, contains(end));
    });
  });

  group('computeBookingReminders — respect des réglages utilisateur', () {
    test('exclut le rappel 30min si remind30min=false', () {
      final now = DateTime(2026, 7, 16, 10, 0);
      final booking = _booking(
        start: DateTime(2026, 7, 16, 14, 0),
        end: DateTime(2026, 7, 16, 16, 0),
      );

      final specs = computeBookingReminders(
        booking,
        now: now,
        locale: _locale,
        remind30min: false,
      );

      expect(specs.length, 4);
      expect(specs.any((s) => s.id == reminderIdFor('booking-1', '_30')),
          isFalse);
    });

    test('exclut le rappel 10min si remind10min=false', () {
      final now = DateTime(2026, 7, 16, 10, 0);
      final booking = _booking(
        start: DateTime(2026, 7, 16, 14, 0),
        end: DateTime(2026, 7, 16, 16, 0),
      );

      final specs = computeBookingReminders(
        booking,
        now: now,
        locale: _locale,
        remind10min: false,
      );

      expect(specs.any((s) => s.id == reminderIdFor('booking-1', '_10')),
          isFalse);
    });

    test('exclut le rappel de début si remindStart=false', () {
      final now = DateTime(2026, 7, 16, 10, 0);
      final booking = _booking(
        start: DateTime(2026, 7, 16, 14, 0),
        end: DateTime(2026, 7, 16, 16, 0),
      );

      final specs = computeBookingReminders(
        booking,
        now: now,
        locale: _locale,
        remindStart: false,
      );

      expect(specs.any((s) => s.id == reminderIdFor('booking-1', '_start')),
          isFalse);
    });

    test('exclut le rappel 15min-avant-fin si remindEnd15min=false', () {
      final now = DateTime(2026, 7, 16, 10, 0);
      final booking = _booking(
        start: DateTime(2026, 7, 16, 14, 0),
        end: DateTime(2026, 7, 16, 16, 0),
      );

      final specs = computeBookingReminders(
        booking,
        now: now,
        locale: _locale,
        remindEnd15min: false,
      );

      expect(
          specs.any((s) => s.id == reminderIdFor('booking-1', '_end15')),
          isFalse);
    });

    test('le rappel de fin n\'a pas de toggle dédié — toujours inclus'
        ' si dans le futur', () {
      final now = DateTime(2026, 7, 16, 10, 0);
      final booking = _booking(
        start: DateTime(2026, 7, 16, 14, 0),
        end: DateTime(2026, 7, 16, 16, 0),
      );

      final specs = computeBookingReminders(
        booking,
        now: now,
        locale: _locale,
        remind30min: false,
        remind10min: false,
        remindStart: false,
        remindEnd15min: false,
      );

      expect(specs.length, 1,
          reason: 'seul le rappel de fin reste, sans toggle possible');
      expect(specs.first.id, reminderIdFor('booking-1', '_ended'));
    });
  });

  group('computeBookingReminders — cas limites de timing (bugs corrigés)',
      () {
    test('exclut le rappel 30min si la réservation démarre dans moins'
        ' de 30min', () {
      final now = DateTime(2026, 7, 16, 13, 45);
      final booking = _booking(
        start: DateTime(2026, 7, 16, 14, 0), // dans 15min
        end: DateTime(2026, 7, 16, 16, 0),
      );

      final specs = computeBookingReminders(
        booking,
        now: now,
        locale: _locale,
      );

      expect(specs.any((s) => s.id == reminderIdFor('booking-1', '_30')),
          isFalse);
    });

    test('exclut le rappel de début si la réservation a déjà commencé'
        ' (réservation en cours)', () {
      final now = DateTime(2026, 7, 16, 14, 30);
      final booking = _booking(
        start: DateTime(2026, 7, 16, 14, 0), // déjà démarrée
        end: DateTime(2026, 7, 16, 16, 0),
      );

      final specs = computeBookingReminders(
        booking,
        now: now,
        locale: _locale,
      );

      expect(specs.any((s) => s.id == reminderIdFor('booking-1', '_start')),
          isFalse);
      // Mais end15 et ended doivent rester présents
      expect(specs.any((s) => s.id == reminderIdFor('booking-1', '_end15')),
          isTrue);
    });

    test('ne retourne aucun rappel pour une réservation entièrement'
        ' terminée', () {
      final now = DateTime(2026, 7, 16, 17, 0);
      final booking = _booking(
        start: DateTime(2026, 7, 16, 14, 0),
        end: DateTime(2026, 7, 16, 16, 0), // déjà terminée
      );

      final specs = computeBookingReminders(
        booking,
        now: now,
        locale: _locale,
      );

      expect(specs, isEmpty,
          reason: 'Reproduit le bug corrigé: pas de rappels fantômes '
              'pour des réservations déjà passées');
    });

    test('inclut uniquement end15+ended pour une réservation en cours'
        ' proche de sa fin', () {
      final now = DateTime(2026, 7, 16, 15, 50);
      final booking = _booking(
        start: DateTime(2026, 7, 16, 14, 0),
        end: DateTime(2026, 7, 16, 16, 0), // se termine dans 10min
      );

      final specs = computeBookingReminders(
        booking,
        now: now,
        locale: _locale,
      );

      // end15 (16h - 15min = 15h45) est déjà passé à 15h50 → exclu
      expect(specs.any((s) => s.id == reminderIdFor('booking-1', '_end15')),
          isFalse);
      // ended (16h00) est encore dans le futur → inclus
      expect(specs.any((s) => s.id == reminderIdFor('booking-1', '_ended')),
          isTrue);
    });
  });

  group('computeBookingReminders — contenu des titres/corps', () {
    test('le titre du rappel 10min contient l\'ID de la place', () {
      final now = DateTime(2026, 7, 16, 10, 0);
      final booking = _booking(
        start: DateTime(2026, 7, 16, 14, 0),
        end: DateTime(2026, 7, 16, 16, 0),
        spotId: 'B2',
      );

      final specs = computeBookingReminders(
        booking,
        now: now,
        locale: _locale,
      );

      final tenMinSpec =
          specs.firstWhere((s) => s.id == reminderIdFor('booking-1', '_10'));
      expect(tenMinSpec.title, contains('B2'));
    });

    test('le corps du rappel de début contient l\'heure de fin formatée',
        () {
      final now = DateTime(2026, 7, 16, 10, 0);
      final booking = _booking(
        start: DateTime(2026, 7, 16, 14, 0),
        end: DateTime(2026, 7, 16, 16, 30),
      );

      final specs = computeBookingReminders(
        booking,
        now: now,
        locale: _locale,
      );

      final startSpec = specs
          .firstWhere((s) => s.id == reminderIdFor('booking-1', '_start'));
      expect(startSpec.body, contains('16:30'));
    });
  });

  group('ReminderSpec — égalité', () {
    test('deux specs avec les mêmes valeurs sont égales', () {
      final date = DateTime(2026, 7, 16, 14, 0);
      final a =
          ReminderSpec(id: 1, title: 'T', body: 'B', scheduledDate: date);
      final b =
          ReminderSpec(id: 1, title: 'T', body: 'B', scheduledDate: date);

      expect(a, equals(b));
    });

    test('deux specs avec un ID différent ne sont pas égales', () {
      final date = DateTime(2026, 7, 16, 14, 0);
      final a =
          ReminderSpec(id: 1, title: 'T', body: 'B', scheduledDate: date);
      final b =
          ReminderSpec(id: 2, title: 'T', body: 'B', scheduledDate: date);

      expect(a, isNot(equals(b)));
    });

    test('deux specs avec un titre différent ne sont pas égales', () {
      final date = DateTime(2026, 7, 16, 14, 0);
      final a =
          ReminderSpec(id: 1, title: 'A', body: 'B', scheduledDate: date);
      final b =
          ReminderSpec(id: 1, title: 'C', body: 'B', scheduledDate: date);

      expect(a, isNot(equals(b)));
    });

    test('deux specs avec une date différente ne sont pas égales', () {
      final a = ReminderSpec(
        id: 1,
        title: 'T',
        body: 'B',
        scheduledDate: DateTime(2026, 7, 16, 14, 0),
      );
      final b = ReminderSpec(
        id: 1,
        title: 'T',
        body: 'B',
        scheduledDate: DateTime(2026, 7, 16, 15, 0),
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('ReminderSpec — hashCode', () {
    test('deux specs égales ont le même hashCode', () {
      final date = DateTime(2026, 7, 16, 14, 0);
      final a =
          ReminderSpec(id: 1, title: 'T', body: 'B', scheduledDate: date);
      final b =
          ReminderSpec(id: 1, title: 'T', body: 'B', scheduledDate: date);

      expect(a.hashCode, b.hashCode);
    });
  });

  group('ReminderSpec — toString', () {
    test('contient l\'id et la date programmée', () {
      final spec = ReminderSpec(
        id: 42,
        title: 'Test',
        body: 'Body',
        scheduledDate: DateTime(2026, 7, 16, 14, 0),
      );

      expect(spec.toString(), contains('42'));
      expect(spec.toString(), contains('2026'));
    });
  });
}
