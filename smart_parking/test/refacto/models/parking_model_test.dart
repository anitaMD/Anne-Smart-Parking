import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/models/parking_model.dart';

/// Tests unitaires — ParkingModel & ParkingSpotsInfo
///
/// Couvre l'affichage parking (adresse, horaires, coordonnées) et
/// le calcul de disponibilité des places, utilisé sur la carte des
/// parkings et dans le stepper de réservation (fix "parking fermé
/// aujourd'hui" corrigé en session).

ParkingModel _makeParking({
  String name = 'ECPI Smart Parking',
  String openingHour = '07:00',
  String closingHour = '20:00',
  int feePerSlot = 300,
}) {
  return ParkingModel(
    id: 'parking-1',
    name: name,
    streetAddress: 'Rue SC-184',
    city: 'Dakar',
    countryCode: 'SN',
    position: const GeoPoint(14.7167, -17.4677),
    openingHour: openingHour,
    closingHour: closingHour,
    feePerSlot: feePerSlot,
  );
}

void main() {
  group('ParkingModel — fullAddress', () {
    test('concatène adresse et ville', () {
      final parking = _makeParking();
      expect(parking.fullAddress, 'Rue SC-184, Dakar');
    });
  });

  group('ParkingModel — hours', () {
    test('formate les horaires ouverture-fermeture', () {
      final parking =
          _makeParking(openingHour: '07:00', closingHour: '20:00');
      expect(parking.hours, '07:00 - 20:00');
    });
  });

  group('ParkingModel — latitude / longitude', () {
    test('expose les coordonnées du GeoPoint', () {
      final parking = _makeParking();
      expect(parking.latitude, 14.7167);
      expect(parking.longitude, -17.4677);
    });
  });

  group('ParkingModel.empty — fallback sécurisé', () {
    test('fournit un parking par défaut sans planter', () {
      final empty = ParkingModel.empty();

      expect(empty.id, '');
      expect(empty.name, isNotEmpty);
      expect(empty.feePerSlot, 0);
    });

    test('empty a des horaires larges (00:00-23:59) pour éviter les faux'
        ' "parking fermé"', () {
      final empty = ParkingModel.empty();

      expect(empty.openingHour, '00:00');
      expect(empty.closingHour, '23:59');
    });
  });

  group('ParkingSpotsInfo — totalAvailable / totalSpots', () {
    test('calcule le nombre de places disponibles', () {
      const info = ParkingSpotsInfo(
        id: 'spots-1',
        regularIds: ['A0', 'A1', 'A2', 'B0', 'B1'],
        specialIds: ['A3'],
        availableIds: ['A1', 'B1'],
        occupiedFromBookingIds: ['A0', 'A2'],
        occupiedFromWalkInIds: ['B0'],
      );

      expect(info.totalAvailable, 2);
    });

    test('calcule le nombre total de places (normales + spéciales)', () {
      const info = ParkingSpotsInfo(
        id: 'spots-1',
        regularIds: ['A0', 'A1', 'A2', 'B0', 'B1'],
        specialIds: ['A3'],
        availableIds: [],
        occupiedFromBookingIds: [],
        occupiedFromWalkInIds: [],
      );

      expect(info.totalSpots, 6);
    });

    test('retourne 0 places disponibles quand tout est occupé', () {
      const info = ParkingSpotsInfo(
        id: 'spots-1',
        regularIds: ['A0'],
        specialIds: [],
        availableIds: [],
        occupiedFromBookingIds: ['A0'],
        occupiedFromWalkInIds: [],
      );

      expect(info.totalAvailable, 0);
    });
  });

  group('ParkingSpotsInfo — allIds', () {
    test('combine les places normales et spéciales (PMR)', () {
      const info = ParkingSpotsInfo(
        id: 'spots-1',
        regularIds: ['A0', 'A1'],
        specialIds: ['A2'],
        availableIds: [],
        occupiedFromBookingIds: [],
        occupiedFromWalkInIds: [],
      );

      expect(info.allIds, ['A0', 'A1', 'A2']);
      expect(info.allIds.length, 3);
    });

    test('retourne une liste vide quand aucune place n\'existe', () {
      const info = ParkingSpotsInfo(
        id: 'spots-1',
        regularIds: [],
        specialIds: [],
        availableIds: [],
        occupiedFromBookingIds: [],
        occupiedFromWalkInIds: [],
      );

      expect(info.allIds, isEmpty);
    });
  });
}
