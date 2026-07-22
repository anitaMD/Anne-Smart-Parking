import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/models/booking_model.dart';

/// Tests unitaires — BookingModel
///
/// Couvre la logique métier critique : détection du statut temporel
/// (à venir / en cours / expirée), calcul de durée, et historique
/// d'édition. Ces getters pilotent l'affichage du dashboard et de
/// l'historique des réservations — un bug ici impacte directement
/// l'expérience utilisateur (ex: bug rencontré où isOngoing ne se
/// réévaluait pas automatiquement dans le countdown).

BookingModel _makeBooking({
  required DateTime bookingStart,
  required DateTime bookingEnd,
  BookingStatus status = BookingStatus.upcoming,
  List<BookingEdit> editHistory = const [],
}) {
  return BookingModel(
    id: 'test-id',
    clientId: 'client-1',
    parkingId: 'parking-1',
    spotId: 'A1',
    vehicleId: 'vehicle-1',
    bookingStart: bookingStart,
    bookingEnd: bookingEnd,
    totalCost: 1000,
    status: status,
    editHistory: editHistory,
  );
}

void main() {
  group('BookingModel — durationMinutes', () {
    test('calcule correctement une durée de 2h', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 2)),
      );

      expect(booking.durationMinutes, 120);
    });

    test('calcule correctement une durée de 30min', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(minutes: 30)),
      );

      expect(booking.durationMinutes, 30);
    });

    test('calcule correctement une durée avec heures et minutes (2h45)', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 2, minutes: 45)),
      );

      expect(booking.durationMinutes, 165);
    });
  });

  group('BookingModel — isOngoing', () {
    test('retourne true quand maintenant est entre start et end', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now.subtract(const Duration(minutes: 30)),
        bookingEnd: now.add(const Duration(minutes: 30)),
      );

      expect(booking.isOngoing, isTrue);
    });

    test('retourne false quand la réservation est dans le futur', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now.add(const Duration(hours: 1)),
        bookingEnd: now.add(const Duration(hours: 2)),
      );

      expect(booking.isOngoing, isFalse);
    });

    test('retourne false quand la réservation est déjà terminée', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now.subtract(const Duration(hours: 2)),
        bookingEnd: now.subtract(const Duration(hours: 1)),
      );

      expect(booking.isOngoing, isFalse);
    });

    test('retourne false exactement au moment de bookingEnd', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now.subtract(const Duration(minutes: 30)),
        bookingEnd: now.subtract(const Duration(milliseconds: 1)),
      );

      expect(booking.isOngoing, isFalse);
    });

    test(
        'retourne false si isArchived est true, même si dans la fenêtre'
        ' active', () {
      final now = DateTime.now();
      final booking = BookingModel(
        id: 'b1',
        clientId: 'client-1',
        parkingId: 'parking-1',
        spotId: 'A1',
        vehicleId: 'vehicle-1',
        bookingStart: now.subtract(const Duration(minutes: 10)),
        bookingEnd: now.add(const Duration(minutes: 10)),
        totalCost: 1000,
        isArchived: true,
      );

      expect(booking.isOngoing, isFalse,
          reason: 'Une réservation archivée (annulée/terminée tôt) ne '
              'doit jamais être considérée "en cours", peu importe si '
              'son créneau horaire original chevauche encore maintenant.');
    });
  });

  group('BookingModel — hasNotStarted', () {
    test('retourne true quand bookingStart est dans le futur', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now.add(const Duration(hours: 1)),
        bookingEnd: now.add(const Duration(hours: 2)),
      );

      expect(booking.hasNotStarted, isTrue);
    });

    test('retourne false quand bookingStart est dans le passé', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now.subtract(const Duration(minutes: 5)),
        bookingEnd: now.add(const Duration(hours: 1)),
      );

      expect(booking.hasNotStarted, isFalse);
    });
  });

  group('BookingModel — isExpired', () {
    test('retourne true quand bookingEnd est dans le passé', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now.subtract(const Duration(hours: 3)),
        bookingEnd: now.subtract(const Duration(hours: 1)),
      );

      expect(booking.isExpired, isTrue);
    });

    test('retourne false quand la réservation est en cours', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now.subtract(const Duration(minutes: 10)),
        bookingEnd: now.add(const Duration(minutes: 10)),
      );

      expect(booking.isExpired, isFalse);
    });

    test('retourne false quand la réservation est future', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now.add(const Duration(hours: 1)),
        bookingEnd: now.add(const Duration(hours: 2)),
      );

      expect(booking.isExpired, isFalse);
    });
  });

  group('BookingModel — isOverstaying (facturation dépassement)', () {
    test(
        'false si le véhicule n\'a jamais été garé (vehicleArrivedAt'
        ' null) — régression: une résa jamais utilisée affichait à'
        ' tort "EN DÉPASSEMENT" dès bookingEnd dépassé', () {
      final now = DateTime.now();
      final booking = BookingModel(
        id: 'b1',
        clientId: 'client-1',
        parkingId: 'parking-1',
        spotId: 'A1',
        vehicleId: 'vehicle-1',
        bookingStart: now.subtract(const Duration(hours: 2)),
        bookingEnd: now.subtract(const Duration(minutes: 10)),
        totalCost: 1000,
        // vehicleArrivedAt volontairement absent (jamais garé)
      );

      expect(booking.isOverstaying, isFalse,
          reason: 'Jamais garé ne veut pas dire "pas encore parti" — '
              'sans vérifier vehicleArrivedAt, cette résa non utilisée '
              'était à tort marquée en dépassement.');
    });

    test(
        'true si garé (vehicleArrivedAt renseigné) et bookingEnd dépassé'
        ' sans confirmation de départ', () {
      final now = DateTime.now();
      final booking = BookingModel(
        id: 'b1',
        clientId: 'client-1',
        parkingId: 'parking-1',
        spotId: 'A1',
        vehicleId: 'vehicle-1',
        bookingStart: now.subtract(const Duration(hours: 2)),
        bookingEnd: now.subtract(const Duration(minutes: 10)),
        totalCost: 1000,
        vehicleArrivedAt: now.subtract(const Duration(hours: 1, minutes: 50)),
      );

      expect(booking.isOverstaying, isTrue);
    });

    test(
        'false si le véhicule est confirmé parti (vehicleDepartedAt'
        ' renseigné), même si bookingEnd est dépassé', () {
      final now = DateTime.now();
      final booking = BookingModel(
        id: 'b1',
        clientId: 'client-1',
        parkingId: 'parking-1',
        spotId: 'A1',
        vehicleId: 'vehicle-1',
        bookingStart: now.subtract(const Duration(hours: 2)),
        bookingEnd: now.subtract(const Duration(minutes: 10)),
        totalCost: 1000,
        vehicleArrivedAt: now.subtract(const Duration(hours: 1, minutes: 50)),
        vehicleDepartedAt: now.subtract(const Duration(minutes: 5)),
      );

      expect(booking.isOverstaying, isFalse);
    });

    test('false si bookingEnd n\'est pas encore dépassé, même si garé', () {
      final now = DateTime.now();
      final booking = BookingModel(
        id: 'b1',
        clientId: 'client-1',
        parkingId: 'parking-1',
        spotId: 'A1',
        vehicleId: 'vehicle-1',
        bookingStart: now.subtract(const Duration(minutes: 10)),
        bookingEnd: now.add(const Duration(minutes: 20)),
        totalCost: 1000,
        vehicleArrivedAt: now.subtract(const Duration(minutes: 5)),
      );

      expect(booking.isOverstaying, isFalse);
    });

    test(
        'false si la réservation est annulée, même avec les autres'
        ' conditions réunies', () {
      final now = DateTime.now();
      final booking = BookingModel(
        id: 'b1',
        clientId: 'client-1',
        parkingId: 'parking-1',
        spotId: 'A1',
        vehicleId: 'vehicle-1',
        bookingStart: now.subtract(const Duration(hours: 2)),
        bookingEnd: now.subtract(const Duration(minutes: 10)),
        totalCost: 1000,
        status: BookingStatus.canceled,
        vehicleArrivedAt: now.subtract(const Duration(hours: 1, minutes: 50)),
      );

      expect(booking.isOverstaying, isFalse);
    });

    test(
        'false si isArchived est true, même avec les autres conditions'
        ' réunies', () {
      final now = DateTime.now();
      final booking = BookingModel(
        id: 'b1',
        clientId: 'client-1',
        parkingId: 'parking-1',
        spotId: 'A1',
        vehicleId: 'vehicle-1',
        bookingStart: now.subtract(const Duration(hours: 2)),
        bookingEnd: now.subtract(const Duration(minutes: 10)),
        totalCost: 1000,
        isArchived: true,
        vehicleArrivedAt: now.subtract(const Duration(hours: 1, minutes: 50)),
      );

      expect(booking.isOverstaying, isFalse);
    });
  });

  group('BookingModel — wasEdited', () {
    test('retourne false quand editHistory est vide', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
      );

      expect(booking.wasEdited, isFalse);
    });

    test('retourne true quand editHistory contient au moins une entrée', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
        editHistory: [
          BookingEdit(
            editedAt: now,
            field: 'spotId',
            oldValue: 'A1',
            newValue: 'A2',
          ),
        ],
      );

      expect(booking.wasEdited, isTrue);
    });
  });

  group('BookingModel — secondsUntilStart / secondsUntilEnd', () {
    test('secondsUntilStart est positif pour une réservation future', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now.add(const Duration(minutes: 10)),
        bookingEnd: now.add(const Duration(hours: 1)),
      );

      expect(booking.secondsUntilStart, greaterThan(0));
      // Tolérance de quelques secondes pour le temps d'exécution du test
      expect(booking.secondsUntilStart, closeTo(600, 5));
    });

    test('secondsUntilStart est négatif pour une réservation déjà démarrée',
        () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now.subtract(const Duration(minutes: 10)),
        bookingEnd: now.add(const Duration(hours: 1)),
      );

      expect(booking.secondsUntilStart, lessThan(0));
    });

    test(
        'secondsUntilEnd est positif tant que la réservation n\'est pas terminée',
        () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now.subtract(const Duration(minutes: 10)),
        bookingEnd: now.add(const Duration(minutes: 20)),
      );

      expect(booking.secondsUntilEnd, greaterThan(0));
      expect(booking.secondsUntilEnd, closeTo(1200, 5));
    });
  });

  group('BookingModel — copyWith', () {
    test('conserve les champs non modifiés', () {
      final now = DateTime.now();
      final original = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
      );

      final updated = original.copyWith(spotId: 'B2');

      expect(updated.id, original.id);
      expect(updated.clientId, original.clientId);
      expect(updated.spotId, 'B2');
      expect(updated.bookingStart, original.bookingStart);
    });

    test('met à jour bookingStart et bookingEnd correctement', () {
      final now = DateTime.now();
      final original = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
      );

      final newStart = now.add(const Duration(days: 1));
      final newEnd = now.add(const Duration(days: 1, hours: 2));

      final updated = original.copyWith(
        bookingStart: newStart,
        bookingEnd: newEnd,
      );

      expect(updated.bookingStart, newStart);
      expect(updated.bookingEnd, newEnd);
      expect(updated.durationMinutes, 120);
    });

    test('accumule editHistory sans écraser les entrées précédentes', () {
      final now = DateTime.now();
      final firstEdit = BookingEdit(
        editedAt: now,
        field: 'spotId',
        oldValue: 'A1',
        newValue: 'A2',
      );
      final original = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
        editHistory: [firstEdit],
      );

      final secondEdit = BookingEdit(
        editedAt: now,
        field: 'bookingStart',
        oldValue: now.toIso8601String(),
        newValue: now.add(const Duration(hours: 1)).toIso8601String(),
      );

      final updated = original.copyWith(
        editHistory: [...original.editHistory, secondEdit],
      );

      expect(updated.editHistory.length, 2);
      expect(updated.wasEdited, isTrue);
    });

    test(
        'met à jour totalCost — régression: paramètre manquant'
        ' historiquement, découvert via editBooking()', () {
      final now = DateTime.now();
      final original = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
      );

      final updated = original.copyWith(totalCost: 1200);

      expect(updated.totalCost, 1200);
      expect(original.totalCost, 1000,
          reason: 'L\'original ne doit pas être modifié (immutabilité)');
    });

    test('conserve totalCost si non fourni', () {
      final now = DateTime.now();
      final original = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
      );

      final updated = original.copyWith(spotId: 'B2');

      expect(updated.totalCost, original.totalCost);
    });

    test('met à jour status et vehicleStatus', () {
      final now = DateTime.now();
      final original = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
      );

      final updated = original.copyWith(
        status: BookingStatus.completed,
        vehicleStatus: VehicleStatus.gone,
      );

      expect(updated.status, BookingStatus.completed);
      expect(updated.vehicleStatus, VehicleStatus.gone);
    });

    test('met à jour isArchived', () {
      final now = DateTime.now();
      final original = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
      );

      final updated = original.copyWith(isArchived: true);

      expect(updated.isArchived, isTrue);
      expect(original.isArchived, isFalse);
    });

    test('met à jour canceledAt', () {
      final now = DateTime.now();
      final original = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
      );

      final updated = original.copyWith(canceledAt: now);

      expect(updated.canceledAt, now);
      expect(original.canceledAt, isNull);
    });

    test('met à jour completedAt', () {
      final now = DateTime.now();
      final original = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
      );

      final updated = original.copyWith(completedAt: now);

      expect(updated.completedAt, now);
    });

    test('met à jour vehicleArrivedAt et vehicleDepartedAt', () {
      final now = DateTime.now();
      final original = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
      );

      final updated = original.copyWith(
        vehicleArrivedAt: now,
        vehicleDepartedAt: now.add(const Duration(minutes: 30)),
      );

      expect(updated.vehicleArrivedAt, now);
      expect(updated.vehicleDepartedAt, now.add(const Duration(minutes: 30)));
      expect(original.vehicleArrivedAt, isNull);
    });
  });

  group('BookingModel — toString', () {
    test('inclut id, spotId et status', () {
      final now = DateTime.now();
      final booking = _makeBooking(
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
        status: BookingStatus.ongoing,
      );

      expect(booking.toString(), contains('test-id'));
      expect(booking.toString(), contains('A1'));
      expect(booking.toString(), contains('ongoing'));
    });
  });

  group('BookingModel — fromFirestore / toFirestore', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('toFirestore puis fromFirestore conserve les champs de base',
        () async {
      final now = DateTime.now();
      final booking = BookingModel(
        id: '',
        clientId: 'client-1',
        parkingId: 'parking-1',
        spotId: 'A1',
        vehicleId: 'vehicle-1',
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
        totalCost: 600,
        status: BookingStatus.ongoing,
        vehicleStatus: VehicleStatus.parked,
        overstayMinutes: 5,
        overstayCharge: 50,
      );

      final ref = await firestore
          .collection('slotsReservations_v2')
          .add(booking.toFirestore());
      final snap = await ref.get();
      final loaded = BookingModel.fromFirestore(snap);

      expect(loaded.clientId, 'client-1');
      expect(loaded.spotId, 'A1');
      expect(loaded.totalCost, 600);
      expect(loaded.status, BookingStatus.ongoing);
      expect(loaded.vehicleStatus, VehicleStatus.parked);
      expect(loaded.overstayMinutes, 5);
      expect(loaded.overstayCharge, 50);
    });

    test(
        'fromFirestore utilise des valeurs par défaut si les champs'
        ' sont absents', () async {
      final ref = await firestore
          .collection('slotsReservations_v2')
          .add({'clientId': 'client-1'});
      final snap = await ref.get();
      final loaded = BookingModel.fromFirestore(snap);

      expect(loaded.status, BookingStatus.upcoming);
      expect(loaded.vehicleStatus, VehicleStatus.notYetParked);
      expect(loaded.isArchived, isFalse);
      expect(loaded.totalCost, 0);
      expect(loaded.overstayMinutes, 0);
      expect(loaded.overstayCharge, 0);
      expect(loaded.editHistory, isEmpty);
    });

    test('fromFirestore parse correctement editHistory', () async {
      final now = DateTime.now();
      final ref = await firestore.collection('slotsReservations_v2').add({
        'clientId': 'client-1',
        'editHistory': [
          {
            'editedAt': Timestamp.fromDate(now),
            'field': 'spotId',
            'oldValue': 'A1',
            'newValue': 'A2',
          }
        ],
      });
      final snap = await ref.get();
      final loaded = BookingModel.fromFirestore(snap);

      expect(loaded.editHistory.length, 1);
      expect(loaded.editHistory.first.field, 'spotId');
      expect(loaded.wasEdited, isTrue);
    });

    test('toFirestore n\'inclut lastOverstayCheckAt que s\'il est renseigné',
        () {
      final now = DateTime.now();
      final withoutCheck = BookingModel(
        id: '',
        clientId: 'client-1',
        parkingId: 'parking-1',
        spotId: 'A1',
        vehicleId: 'vehicle-1',
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
        totalCost: 600,
      );

      expect(withoutCheck.toFirestore().containsKey('lastOverstayCheckAt'),
          isFalse);

      final withCheck = withoutCheck.copyWith(lastOverstayCheckAt: now);
      expect(
          withCheck.toFirestore().containsKey('lastOverstayCheckAt'), isTrue);
    });
  });

  group('BookingEdit — fromMap / toMap', () {
    test('toMap puis fromMap conserve les données', () {
      final now = DateTime.now();
      final edit = BookingEdit(
        editedAt: now,
        field: 'spotId',
        oldValue: 'A1',
        newValue: 'A2',
      );

      final map = edit.toMap();

      expect(map['field'], 'spotId');
      expect(map['oldValue'], 'A1');
      expect(map['newValue'], 'A2');
    });

    test('fromMap utilise des valeurs par défaut si les champs sont absents',
        () {
      final edit = BookingEdit.fromMap({});

      expect(edit.field, '');
      expect(edit.oldValue, '');
      expect(edit.newValue, '');
    });
  });
}
