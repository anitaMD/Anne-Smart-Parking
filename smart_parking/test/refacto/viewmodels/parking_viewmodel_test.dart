import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/models/parking_model.dart';
import 'package:smart_parking/app/viewmodels/auth_viewmodel.dart';
import 'package:smart_parking/app/viewmodels/parking_viewmodel.dart';
import '../mocks/mock_auth_service.dart';
import '../mocks/mock_firestore_service.dart';

/// Tests unitaires — ParkingState & ParkingNotifier
///
/// Couvre le chargement des parkings et la sélection d'un parking
/// avec ses places associées, utilisés sur la carte des parkings
/// et dans le stepper de réservation.

ParkingModel _parking({String id = 'p1', String name = 'ECPI Smart Parking'}) {
  return ParkingModel(
    id: id,
    name: name,
    streetAddress: 'Rue SC-184',
    city: 'Dakar',
    countryCode: 'SN',
    position: const GeoPoint(14.7167, -17.4677),
    openingHour: '07:00',
    closingHour: '20:00',
    feePerSlot: 300,
  );
}

class _FakeParkingFirestoreService extends MockFirestoreService {
  List<ParkingModel> parkingsToReturn;
  ParkingSpotsInfo? spotsToReturn;

  _FakeParkingFirestoreService({
    this.parkingsToReturn = const [],
    this.spotsToReturn,
  });

  @override
  Future<List<ParkingModel>> getParkings() async => parkingsToReturn;

  @override
  Future<ParkingSpotsInfo?> getParkingSpots(String parkingId) async =>
      spotsToReturn;
}

ProviderContainer _makeContainer(MockFirestoreService fakeService) {
  return ProviderContainer(overrides: [
    authServiceProvider.overrideWithValue(MockAuthService()),
    firestoreServiceProvider.overrideWithValue(fakeService),
  ]);
}

void main() {
  group('ParkingState — hasParkings', () {
    test('false pour une liste vide', () {
      const state = ParkingState();
      expect(state.hasParkings, isFalse);
    });

    test('true quand au moins un parking existe', () {
      final state = ParkingState(parkings: [_parking()]);
      expect(state.hasParkings, isTrue);
    });
  });

  group('ParkingNotifier — loadParkings', () {
    test('charge la liste des parkings depuis Firestore', () async {
      final fakeService = _FakeParkingFirestoreService(
        parkingsToReturn: [_parking(id: 'p1'), _parking(id: 'p2')],
      );
      final container = _makeContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(parkingProvider.notifier).loadParkings();

      final state = container.read(parkingProvider);
      expect(state.parkings.length, 2);
      expect(state.isLoading, isFalse);
      expect(state.hasParkings, isTrue);
    });

    test('gère une erreur Firestore sans planter', () async {
      final fakeService = _FailingParkingFirestoreService();
      final container = _makeContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(parkingProvider.notifier).loadParkings();

      final state = container.read(parkingProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });
  });

  group('ParkingNotifier — selectParking', () {
    test('met à jour selectedParking et charge ses places', () async {
      const spots = ParkingSpotsInfo(
        id: 'spots-1',
        regularIds: ['A0', 'A1'],
        specialIds: ['A2'],
        availableIds: ['A0', 'A1', 'A2'],
        occupiedFromBookingIds: [],
        occupiedFromWalkInIds: [],
      );
      final fakeService = _FakeParkingFirestoreService(spotsToReturn: spots);
      final container = _makeContainer(fakeService);
      addTearDown(container.dispose);

      final parking = _parking(id: 'p1');
      await container.read(parkingProvider.notifier).selectParking(parking);

      final state = container.read(parkingProvider);
      expect(state.selectedParking?.id, 'p1');
      expect(state.selectedParkingSpots?.totalAvailable, 3);
    });
  });

  group('ParkingNotifier — selectParking (erreur)', () {
    test('conserve selectedParking même si getParkingSpots échoue', () async {
      final fakeService = _FailingSpotsFirestoreService();
      final container = _makeContainer(fakeService);
      addTearDown(container.dispose);

      final parking = _parking(id: 'p1');
      await container.read(parkingProvider.notifier).selectParking(parking);

      final state = container.read(parkingProvider);
      expect(state.selectedParking?.id, 'p1',
          reason: 'Le parking sélectionné doit rester affiché même si '
              'le chargement de ses places échoue (erreur réseau '
              'ponctuelle), pour ne pas casser la navigation');
      expect(state.selectedParkingSpots, isNull);
    });
  });
}

class _FailingParkingFirestoreService extends MockFirestoreService {
  @override
  Future<List<ParkingModel>> getParkings() async {
    throw Exception('Network error simulée');
  }
}

class _FailingSpotsFirestoreService extends MockFirestoreService {
  @override
  Future<ParkingSpotsInfo?> getParkingSpots(String parkingId) async {
    throw Exception('Network error simulée');
  }
}
