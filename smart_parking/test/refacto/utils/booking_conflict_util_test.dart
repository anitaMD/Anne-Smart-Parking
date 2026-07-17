import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/core/utils/booking_conflict_util.dart';

/// Tests unitaires — doTimeSlotsOverlap
///
/// Cette fonction est au cœur de la prévention du double-booking
/// (conflit de place) et du conflit de véhicule (même véhicule ne
/// peut pas être réservé sur deux créneaux qui se chevauchent, même
/// dans des parkings différents — bug corrigé en session).
///
/// Convention : intervalle semi-ouvert [start, end) — une réservation
/// qui se termine exactement quand une autre commence n'est PAS
/// considérée en conflit (le créneau est libéré à l'instant bookingEnd).

void main() {
  final base = DateTime(2026, 7, 16, 14, 0); // 14h00 référence

  group('doTimeSlotsOverlap — cas de chevauchement', () {
    test('deux créneaux identiques se chevauchent', () {
      final result = doTimeSlotsOverlap(
        aStart: base,
        aEnd: base.add(const Duration(hours: 2)),
        bStart: base,
        bEnd: base.add(const Duration(hours: 2)),
      );

      expect(result, isTrue);
    });

    test('un créneau contenu entièrement dans un autre est en conflit', () {
      // A: 14h-18h, B: 15h-16h (B est dans A)
      final result = doTimeSlotsOverlap(
        aStart: base,
        aEnd: base.add(const Duration(hours: 4)),
        bStart: base.add(const Duration(hours: 1)),
        bEnd: base.add(const Duration(hours: 2)),
      );

      expect(result, isTrue);
    });

    test('un chevauchement partiel au milieu est détecté', () {
      // A: 14h-16h, B: 15h-17h (se chevauchent de 15h à 16h)
      final result = doTimeSlotsOverlap(
        aStart: base,
        aEnd: base.add(const Duration(hours: 2)),
        bStart: base.add(const Duration(hours: 1)),
        bEnd: base.add(const Duration(hours: 3)),
      );

      expect(result, isTrue);
    });

    test('un chevauchement de quelques minutes seulement est détecté', () {
      // A: 14h-15h, B: 14h55-16h (1 min de chevauchement)
      final result = doTimeSlotsOverlap(
        aStart: base,
        aEnd: base.add(const Duration(hours: 1)),
        bStart: base.add(const Duration(minutes: 55)),
        bEnd: base.add(const Duration(hours: 2)),
      );

      expect(result, isTrue);
    });
  });

  group('doTimeSlotsOverlap — cas sans chevauchement', () {
    test(
        'deux créneaux consécutifs (B commence exactement quand A finit)'
        ' ne sont pas en conflit', () {
      // A: 14h-15h, B: 15h-16h
      final result = doTimeSlotsOverlap(
        aStart: base,
        aEnd: base.add(const Duration(hours: 1)),
        bStart: base.add(const Duration(hours: 1)),
        bEnd: base.add(const Duration(hours: 2)),
      );

      expect(result, isFalse);
    });

    test('deux créneaux totalement séparés ne sont pas en conflit', () {
      // A: 14h-15h, B: 18h-19h
      final result = doTimeSlotsOverlap(
        aStart: base,
        aEnd: base.add(const Duration(hours: 1)),
        bStart: base.add(const Duration(hours: 4)),
        bEnd: base.add(const Duration(hours: 5)),
      );

      expect(result, isFalse);
    });

    test('B entièrement avant A n\'est pas en conflit', () {
      // A: 16h-18h, B: 14h-15h
      final result = doTimeSlotsOverlap(
        aStart: base.add(const Duration(hours: 2)),
        aEnd: base.add(const Duration(hours: 4)),
        bStart: base,
        bEnd: base.add(const Duration(hours: 1)),
      );

      expect(result, isFalse);
    });
  });

  group('doTimeSlotsOverlap — cas limites (edge cases)', () {
    test('A se termine exactement quand B commence — pas de conflit', () {
      final result = doTimeSlotsOverlap(
        aStart: base,
        aEnd: base.add(const Duration(minutes: 30)),
        bStart: base.add(const Duration(minutes: 30)),
        bEnd: base.add(const Duration(hours: 1)),
      );

      expect(result, isFalse);
    });

    test('créneaux d\'une seule minute qui se chevauchent', () {
      final result = doTimeSlotsOverlap(
        aStart: base,
        aEnd: base.add(const Duration(minutes: 1)),
        bStart: base.add(const Duration(seconds: 30)),
        bEnd: base.add(const Duration(minutes: 2)),
      );

      expect(result, isTrue);
    });
  });

  group('doTimeSlotsOverlap — scénario réel : conflit véhicule multi-parking',
      () {
    test(
        'même véhicule réservé sur deux parkings différents avec créneaux'
        ' qui se chevauchent → conflit détecté', () {
      // Réservation A : Parking ECPI, 14h-16h
      // Réservation B : Parking Anne Smart Parking, 15h-17h (même véhicule)
      // → doivent être détectées comme conflit même si spotId/parkingId diffèrent
      final reservationaStart = base;
      final reservationaEnd = base.add(const Duration(hours: 2));
      final reservationbStart = base.add(const Duration(hours: 1));
      final reservationbEnd = base.add(const Duration(hours: 3));

      final conflict = doTimeSlotsOverlap(
        aStart: reservationaStart,
        aEnd: reservationaEnd,
        bStart: reservationbStart,
        bEnd: reservationbEnd,
      );

      expect(conflict, isTrue,
          reason: 'Un même véhicule ne peut pas être garé à deux endroits '
              'simultanément, peu importe le parking.');
    });

    test(
        'même véhicule réservé sur deux parkings différents à des horaires'
        ' bien distincts → pas de conflit', () {
      final reservationaEnd = base.add(const Duration(hours: 2));
      final reservationbStart = base.add(const Duration(hours: 3));

      final conflict = doTimeSlotsOverlap(
        aStart: base,
        aEnd: reservationaEnd,
        bStart: reservationbStart,
        bEnd: reservationbStart.add(const Duration(hours: 1)),
      );

      expect(conflict, isFalse,
          reason: 'Le véhicule peut légitimement réserver un autre '
              'parking une fois la première réservation terminée.');
    });
  });
}
