import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/models/time_slot_model.dart';

/// Tests unitaires — TimeSlotModel / generateTimeSlots
///
/// Couvre la génération des créneaux de 30 minutes utilisés dans le
/// stepper de réservation — remplace une logique auparavant plus
/// complexe (getTimeSlotsIntervals()), donc particulièrement
/// important de valider les cas limites (bornes exactes, créneaux
/// déjà réservés).

void main() {
  group('TimeSlotModel — durationMinutes', () {
    test('calcule 30 minutes pour un créneau standard', () {
      const slot = TimeSlotModel(
        startTime: TimeOfDay(hour: 8, minute: 0),
        endTime: TimeOfDay(hour: 8, minute: 30),
      );

      expect(slot.durationMinutes, 30);
    });

    test('calcule correctement à travers le changement d\'heure', () {
      const slot = TimeSlotModel(
        startTime: TimeOfDay(hour: 8, minute: 45),
        endTime: TimeOfDay(hour: 9, minute: 15),
      );

      expect(slot.durationMinutes, 30);
    });
  });

  group('TimeSlotModel — label', () {
    test('formate avec zéros de remplissage (padding)', () {
      const slot = TimeSlotModel(
        startTime: TimeOfDay(hour: 8, minute: 0),
        endTime: TimeOfDay(hour: 8, minute: 30),
      );

      expect(slot.label, '08:00 - 08:30');
    });

    test('formate correctement les heures à 2 chiffres', () {
      const slot = TimeSlotModel(
        startTime: TimeOfDay(hour: 14, minute: 30),
        endTime: TimeOfDay(hour: 15, minute: 0),
      );

      expect(slot.label, '14:30 - 15:00');
    });
  });

  group('TimeSlotModel — toDateTime', () {
    test('combine la date fournie avec l\'heure de début du créneau', () {
      const slot = TimeSlotModel(
        startTime: TimeOfDay(hour: 14, minute: 30),
        endTime: TimeOfDay(hour: 15, minute: 0),
      );

      final result = slot.toDateTime(DateTime(2026, 7, 16));

      expect(result, DateTime(2026, 7, 16, 14, 30));
    });
  });

  group('TimeSlotModel — copyWith', () {
    test('met à jour isAvailable et isSelected indépendamment', () {
      const original = TimeSlotModel(
        startTime: TimeOfDay(hour: 8, minute: 0),
        endTime: TimeOfDay(hour: 8, minute: 30),
      );

      final updated = original.copyWith(isAvailable: false, isSelected: true);

      expect(updated.isAvailable, isFalse);
      expect(updated.isSelected, isTrue);
      expect(original.isAvailable, isTrue,
          reason: 'Immutabilité — l\'original ne change pas');
    });

    test('conserve les valeurs non fournies', () {
      const original = TimeSlotModel(
        startTime: TimeOfDay(hour: 8, minute: 0),
        endTime: TimeOfDay(hour: 8, minute: 30),
        isSelected: true,
      );

      final updated = original.copyWith(isAvailable: false);

      expect(updated.isSelected, isTrue);
    });
  });

  group('TimeSlotModel — toString', () {
    test('inclut le label et la disponibilité', () {
      const slot = TimeSlotModel(
        startTime: TimeOfDay(hour: 8, minute: 0),
        endTime: TimeOfDay(hour: 8, minute: 30),
        isAvailable: false,
      );

      expect(slot.toString(), contains('08:00 - 08:30'));
      expect(slot.toString(), contains('false'));
    });
  });

  group('generateTimeSlots', () {
    test('génère le bon nombre de créneaux de 30min', () {
      final slots = generateTimeSlots('07:00', '09:00');

      expect(slots.length, 4); // 07:00-07:30, 07:30-08:00, 08:00-08:30, 08:30-09:00
    });

    test('le premier créneau commence à l\'heure d\'ouverture', () {
      final slots = generateTimeSlots('07:30', '09:00');

      expect(slots.first.startTime, const TimeOfDay(hour: 7, minute: 30));
    });

    test('le dernier créneau se termine exactement à l\'heure de'
        ' fermeture', () {
      final slots = generateTimeSlots('07:00', '08:00');

      expect(slots.last.endTime, const TimeOfDay(hour: 8, minute: 0));
    });

    test('n\'inclut pas de créneau qui dépasserait l\'heure de fermeture',
        () {
      // 07:00 à 08:15 → seul 07:00-07:30 et 07:30-08:00 tiennent,
      // un éventuel 08:00-08:30 dépasserait 08:15
      final slots = generateTimeSlots('07:00', '08:15');

      expect(slots.length, 2);
      expect(slots.last.endTime, const TimeOfDay(hour: 8, minute: 0));
    });

    test('tous les créneaux sont disponibles par défaut', () {
      final slots = generateTimeSlots('07:00', '08:00');

      expect(slots.every((s) => s.isAvailable), isTrue);
    });

    test('marque comme indisponible un créneau présent dans bookedSlots',
        () {
      final slots = generateTimeSlots(
        '07:00',
        '08:00',
        bookedSlots: [
          const TimeSlotModel(
            startTime: TimeOfDay(hour: 7, minute: 30),
            endTime: TimeOfDay(hour: 8, minute: 0),
          ),
        ],
      );

      final booked =
          slots.firstWhere((s) => s.startTime.hour == 7 && s.startTime.minute == 30);
      final free =
          slots.firstWhere((s) => s.startTime.hour == 7 && s.startTime.minute == 0);

      expect(booked.isAvailable, isFalse);
      expect(free.isAvailable, isTrue);
    });

    test('retourne une liste vide si ouverture égale fermeture', () {
      final slots = generateTimeSlots('07:00', '07:00');

      expect(slots, isEmpty);
    });

    test('gère correctement un créneau traversant une heure pleine'
        ' (ex: 07:45-08:15)', () {
      final slots = generateTimeSlots('07:45', '08:15');

      expect(slots.length, 1);
      expect(slots.first.startTime, const TimeOfDay(hour: 7, minute: 45));
      expect(slots.first.endTime, const TimeOfDay(hour: 8, minute: 15));
    });
  });
}
