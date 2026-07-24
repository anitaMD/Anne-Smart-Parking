import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/models/parking_spot_model.dart';

/// Tests unitaires — ParkingSpotModel / buildSpotList
///
/// Couvre la logique de dérivation de l'état visuel de chaque place
/// (libre/spéciale/réservée/occupée) à partir des listes brutes
/// ParkingSpotsInfo — cette logique pilote directement les 4 couleurs
/// LED de la maquette physique et le grid du stepper de réservation.

void main() {
  group('ParkingSpotModel.fromSpotsInfo — dérivation de l\'état', () {
    test('occupée si présente dans occupiedFromBookingIds', () {
      final spot = ParkingSpotModel.fromSpotsInfo(
        spotId: 'A0',
        availableIds: [],
        bookedIds: [],
        occupiedFromWalkInIds: [],
        occupiedFromBookingIds: ['A0'],
        specialIds: [],
      );

      expect(spot.state, SpotState.occupied);
    });

    test('occupée si présente dans occupiedFromWalkInIds', () {
      final spot = ParkingSpotModel.fromSpotsInfo(
        spotId: 'A0',
        availableIds: [],
        bookedIds: [],
        occupiedFromWalkInIds: ['A0'],
        occupiedFromBookingIds: [],
        specialIds: [],
      );

      expect(spot.state, SpotState.occupied);
    });

    test('réservée si dans bookedIds mais pas physiquement occupée', () {
      final spot = ParkingSpotModel.fromSpotsInfo(
        spotId: 'A0',
        availableIds: [],
        bookedIds: ['A0'],
        occupiedFromWalkInIds: [],
        occupiedFromBookingIds: [],
        specialIds: [],
      );

      expect(spot.state, SpotState.reserved);
    });

    test('libre (verte) si disponible et pas spéciale', () {
      final spot = ParkingSpotModel.fromSpotsInfo(
        spotId: 'A0',
        availableIds: ['A0'],
        bookedIds: [],
        occupiedFromWalkInIds: [],
        occupiedFromBookingIds: [],
        specialIds: [],
      );

      expect(spot.state, SpotState.free);
      expect(spot.isSpecial, isFalse);
    });

    test('libre spéciale (bleue) si disponible et PMR', () {
      final spot = ParkingSpotModel.fromSpotsInfo(
        spotId: 'B2',
        availableIds: ['B2'],
        bookedIds: [],
        occupiedFromWalkInIds: [],
        occupiedFromBookingIds: [],
        specialIds: ['B2'],
      );

      expect(spot.state, SpotState.special);
      expect(spot.isSpecial, isTrue);
    });

    test('occupée par défaut si absente de toutes les listes (fallback'
        ' sûr)', () {
      final spot = ParkingSpotModel.fromSpotsInfo(
        spotId: 'Z9',
        availableIds: [],
        bookedIds: [],
        occupiedFromWalkInIds: [],
        occupiedFromBookingIds: [],
        specialIds: [],
      );

      expect(spot.state, SpotState.occupied,
          reason: 'Une place dans un état inconnu doit être traitée '
              'comme occupée par précaution, jamais comme libre.');
    });

    test('occupation physique prime sur une réservation existante', () {
      // Une place à la fois réservée ET physiquement occupée doit
      // afficher "occupée" (l'état le plus important pour l'usager)
      final spot = ParkingSpotModel.fromSpotsInfo(
        spotId: 'A0',
        availableIds: [],
        bookedIds: ['A0'],
        occupiedFromWalkInIds: [],
        occupiedFromBookingIds: ['A0'],
        specialIds: [],
      );

      expect(spot.state, SpotState.occupied);
    });

    test('extrait la première lettre comme allée', () {
      final spot = ParkingSpotModel.fromSpotsInfo(
        spotId: 'B2',
        availableIds: ['B2'],
        bookedIds: [],
        occupiedFromWalkInIds: [],
        occupiedFromBookingIds: [],
        specialIds: [],
      );

      expect(spot.alley, 'B');
    });

    test('allée vide si spotId est vide', () {
      final spot = ParkingSpotModel.fromSpotsInfo(
        spotId: '',
        availableIds: [],
        bookedIds: [],
        occupiedFromWalkInIds: [],
        occupiedFromBookingIds: [],
        specialIds: [],
      );

      expect(spot.alley, '');
    });
  });

  group('ParkingSpotModel — getters d\'affichage', () {
    const free = ParkingSpotModel(
        id: 'A0', alley: 'A', isSpecial: false, state: SpotState.free);
    const special = ParkingSpotModel(
        id: 'B0', alley: 'B', isSpecial: true, state: SpotState.special);
    const reserved = ParkingSpotModel(
        id: 'A1', alley: 'A', isSpecial: false, state: SpotState.reserved);
    const occupied = ParkingSpotModel(
        id: 'A2', alley: 'A', isSpecial: false, state: SpotState.occupied);

    test('stateLabel correspond à chaque état', () {
      expect(free.stateLabel, 'Libre');
      expect(special.stateLabel, 'Libre (PMR)');
      expect(reserved.stateLabel, 'Réservée');
      expect(occupied.stateLabel, 'Occupée');
    });

    test('isAvailable est true pour free et special uniquement', () {
      expect(free.isAvailable, isTrue);
      expect(special.isAvailable, isTrue);
      expect(reserved.isAvailable, isFalse);
      expect(occupied.isAvailable, isFalse);
    });

    test('ledColor retourne une couleur distincte par état', () {
      final colors = {
        free.ledColor,
        special.ledColor,
        reserved.ledColor,
        occupied.ledColor,
      };
      expect(colors.length, 4,
          reason: 'Les 4 états doivent avoir 4 couleurs LED distinctes '
              '(correspondance avec la maquette physique)');
    });

    test('stateIcon retourne une icône par état', () {
      expect(free.stateIcon, isNotNull);
      expect(special.stateIcon, isNotNull);
      expect(reserved.stateIcon, isNotNull);
      expect(occupied.stateIcon, isNotNull);
    });
  });

  group('ParkingSpotModel — copyWith', () {
    test('met à jour uniquement le state', () {
      const original = ParkingSpotModel(
          id: 'A0', alley: 'A', isSpecial: false, state: SpotState.free);

      final updated = original.copyWith(state: SpotState.occupied);

      expect(updated.state, SpotState.occupied);
      expect(updated.id, original.id);
      expect(original.state, SpotState.free,
          reason: 'Immutabilité — l\'original ne change pas');
    });
  });

  group('ParkingSpotModel — toString', () {
    test('inclut id et state', () {
      const spot = ParkingSpotModel(
          id: 'A0', alley: 'A', isSpecial: false, state: SpotState.free);

      expect(spot.toString(), contains('A0'));
      expect(spot.toString(), contains('free'));
    });
  });

  group('buildSpotList', () {
    test('combine regularIds et specialIds', () {
      final spots = buildSpotList(
        regularIds: ['A0', 'A1'],
        specialIds: ['A2'],
        availableIds: ['A0', 'A1', 'A2'],
        bookedIds: [],
        occupiedFromWalkInIds: [],
        occupiedFromBookingIds: [],
      );

      expect(spots.length, 3);
    });

    test('trie les places par id', () {
      final spots = buildSpotList(
        regularIds: ['A2', 'A0', 'A1'],
        specialIds: [],
        availableIds: ['A0', 'A1', 'A2'],
        bookedIds: [],
        occupiedFromWalkInIds: [],
        occupiedFromBookingIds: [],
      );

      expect(spots.map((s) => s.id).toList(), ['A0', 'A1', 'A2']);
    });

    test('affecte correctement l\'état de chaque place dans la liste',
        () {
      final spots = buildSpotList(
        regularIds: ['A0', 'A1'],
        specialIds: ['B0'],
        availableIds: ['A0', 'B0'],
        bookedIds: ['A1'],
        occupiedFromWalkInIds: [],
        occupiedFromBookingIds: [],
      );

      final a0 = spots.firstWhere((s) => s.id == 'A0');
      final a1 = spots.firstWhere((s) => s.id == 'A1');
      final b0 = spots.firstWhere((s) => s.id == 'B0');

      expect(a0.state, SpotState.free);
      expect(a1.state, SpotState.reserved);
      expect(b0.state, SpotState.special);
    });

    test('retourne une liste vide si aucun id fourni', () {
      final spots = buildSpotList(
        regularIds: [],
        specialIds: [],
        availableIds: [],
        bookedIds: [],
        occupiedFromWalkInIds: [],
        occupiedFromBookingIds: [],
      );

      expect(spots, isEmpty);
    });
  });
}
