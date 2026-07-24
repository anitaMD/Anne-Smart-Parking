import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking/app/models/notification_model.dart';
import 'package:smart_parking/app/models/user_model.dart';
import 'package:smart_parking/app/models/vehicle_model.dart';
import 'package:smart_parking/app/models/wallet_model.dart';
import 'package:smart_parking/app/services/storage_service.dart';
import 'package:smart_parking/app/viewmodels/auth_viewmodel.dart';
import 'package:smart_parking/app/viewmodels/user_viewmodel.dart';
import '../mocks/mock_auth_service.dart';
import '../mocks/mock_firestore_service.dart';
import '../mocks/mock_storage_service.dart';

/// Tests unitaires — UserState & UserNotifier (fichier consolidé)
///
/// Regroupe l'ensemble des tests liés au profil utilisateur :
///   1. UserState — logique pure (badge notifications non lues,
///      sélection du véhicule par défaut)
///   2. UserNotifier.loadUserData / addVehicle / deleteVehicle /
///      setDefaultVehicle / markNotificationRead — avec mocks
///
/// Point d'attention : watchNotifications(uid) est appelé DEUX fois
/// dans le vrai code (une fois via `.first`, une fois via `.listen()`).
/// Chaque appel doit retourner une NOUVELLE instance de Stream — un
/// Stream à écoute unique (Stream.value) ne peut être écouté qu'une
/// seule fois, d'où la fabrique de stream fraîche à chaque appel
/// ci-dessous.

// ─────────────────────────────────────────────────────────────
// HELPERS PARTAGÉS
// ─────────────────────────────────────────────────────────────

UserModel _user({String id = 'uid-1', String fullName = 'Anne Marie'}) {
  return UserModel(
    id: id,
    fullName: fullName,
    email: 'test@ysp.com',
    phoneNumber: '+221774880377',
    profileImageUrl: '',
    isSpecialAccessUser: false,
    role: 'user',
  );
}

VehicleModel _vehicle({required String id, bool isCurrentlySelected = false}) {
  return VehicleModel(
    id: id,
    brand: 'Toyota',
    modelDetail: 'Corolla',
    color: 'Bleu',
    licensePlate: 'DK-1234-2024',
    registrationYear: '2024',
    registrationCountry: 'Sénégal',
    registrationCity: 'Dakar',
    countryIso: 'SN',
    cityIso: 'DK',
    isCurrentlySelected: isCurrentlySelected,
  );
}

NotificationModel _notif({required String id, bool isRead = false}) {
  return NotificationModel(
    id: id,
    title: 'Test',
    body: 'Test body',
    isRead: isRead,
    receivedAt: DateTime.now(),
  );
}

// ─────────────────────────────────────────────────────────────
// FAKE — UserNotifier
// ─────────────────────────────────────────────────────────────

class _FakeUserFirestoreService extends MockFirestoreService {
  UserModel? userToReturn;
  WalletModel? walletToReturn;
  List<VehicleModel> vehiclesToReturn;
  List<NotificationModel> notificationsToReturn;

  final List<String> deletedVehicleIds = [];
  final List<String> defaultVehicleIds = [];
  final List<String> markedReadNotifIds = [];
  final List<Map<String, dynamic>> updatedFieldsCalls = [];

  _FakeUserFirestoreService({
    this.userToReturn,
    this.walletToReturn,
    this.vehiclesToReturn = const [],
    this.notificationsToReturn = const [],
  });

  @override
  Future<UserModel?> getUser(String uid) async => userToReturn;

  @override
  Future<WalletModel?> getWallet(String uid) async => walletToReturn;

  @override
  Future<List<VehicleModel>> getVehicles(String uid) async => vehiclesToReturn;

  @override
  Stream<List<NotificationModel>> watchNotifications(String uid) =>
      // Nouvelle instance de stream à chaque appel — nécessaire car
      // ce stream est écouté deux fois séparément dans loadUserData
      // (.first puis .listen()), et un stream à écoute unique ne
      // peut être consommé qu'une fois.
      Stream.value(notificationsToReturn);

  @override
  Stream<WalletModel?> watchWallet(String uid) => Stream.value(walletToReturn);

  @override
  Future<String> addVehicle(String uid, VehicleModel vehicle) async {
    vehiclesToReturn = [...vehiclesToReturn, vehicle];
    return vehicle.id;
  }

  @override
  Future<void> deleteVehicle(String uid, String vehicleId) async {
    deletedVehicleIds.add(vehicleId);
  }

  @override
  Future<void> setDefaultVehicle(String uid, String vehicleId) async {
    defaultVehicleIds.add(vehicleId);
  }

  @override
  Future<void> markNotificationRead(String uid, String notifId) async {
    markedReadNotifIds.add(notifId);
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    updatedFieldsCalls.add(fields);
  }
}

ProviderContainer _makeContainer(
  _FakeUserFirestoreService fakeService, {
  MockStorageService? storageService,
}) {
  return ProviderContainer(overrides: [
    authServiceProvider.overrideWithValue(MockAuthService()),
    firestoreServiceProvider.overrideWithValue(fakeService),
    storageServiceProvider
        .overrideWithValue(storageService ?? MockStorageService()),
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // ── 1. UserState — logique pure ───────────────────────────

  group('UserState — hasVehicles', () {
    test('false pour une liste vide', () {
      const state = UserState();
      expect(state.hasVehicles, isFalse);
    });

    test('true quand au moins un véhicule existe', () {
      final state = UserState(vehicles: [_vehicle(id: 'v1')]);
      expect(state.hasVehicles, isTrue);
    });
  });

  group('UserState — unreadNotificationsCount', () {
    test('compte uniquement les notifications non lues', () {
      final state = UserState(notifications: [
        _notif(id: 'n1', isRead: true),
        _notif(id: 'n2', isRead: false),
        _notif(id: 'n3', isRead: false),
      ]);

      expect(state.unreadNotificationsCount, 2);
    });

    test('retourne 0 quand toutes les notifications sont lues', () {
      final state = UserState(notifications: [
        _notif(id: 'n1', isRead: true),
        _notif(id: 'n2', isRead: true),
      ]);

      expect(state.unreadNotificationsCount, 0);
    });

    test('retourne 0 pour une liste vide', () {
      const state = UserState();
      expect(state.unreadNotificationsCount, 0);
    });
  });

  group('UserState — defaultVehicle', () {
    test('retourne le véhicule marqué isCurrentlySelected en priorité', () {
      final state = UserState(vehicles: [
        _vehicle(id: 'v1', isCurrentlySelected: false),
        _vehicle(id: 'v2', isCurrentlySelected: true),
      ]);

      expect(state.defaultVehicle?.id, 'v2');
    });

    test('retourne le premier véhicule si aucun n\'est sélectionné', () {
      final state = UserState(vehicles: [
        _vehicle(id: 'v1', isCurrentlySelected: false),
        _vehicle(id: 'v2', isCurrentlySelected: false),
      ]);

      expect(state.defaultVehicle?.id, 'v1');
    });

    test('retourne null quand la liste est vide', () {
      const state = UserState();
      expect(state.defaultVehicle, isNull);
    });
  });

  group('UserState — copyWith', () {
    test('met à jour wallet sans affecter vehicles', () {
      final vehicles = [_vehicle(id: 'v1')];
      final original = UserState(vehicles: vehicles);
      final updated = original.copyWith();

      expect(updated.vehicles.length, 1);
    });
  });

  // ── 2. UserNotifier — avec mocks ──────────────────────────

  group('UserNotifier — loadUserData', () {
    test('charge user, wallet, vehicles et notifications', () async {
      final fakeService = _FakeUserFirestoreService(
        userToReturn: _user(),
        walletToReturn: const WalletModel(id: 'w1', balance: 5000),
        vehiclesToReturn: [_vehicle(id: 'v1')],
      );
      final container = _makeContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('uid-1');

      final state = container.read(userProvider);
      expect(state.user?.id, 'uid-1');
      expect(state.wallet?.balance, 5000);
      expect(state.vehicles.length, 1);
      expect(state.isLoading, isFalse);
    });

    test('état isLoading passe à false même sans utilisateur trouvé', () async {
      final fakeService = _FakeUserFirestoreService(userToReturn: null);
      final container = _makeContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('uid-1');

      final state = container.read(userProvider);
      expect(state.isLoading, isFalse);
      expect(state.user, isNull);
    });
  });

  group('UserNotifier — addVehicle', () {
    test('ajoute le véhicule puis recharge les données utilisateur', () async {
      final fakeService = _FakeUserFirestoreService(userToReturn: _user());
      final container = _makeContainer(fakeService);
      addTearDown(container.dispose);

      await container
          .read(userProvider.notifier)
          .addVehicle('uid-1', _vehicle(id: 'new-vehicle'));

      final state = container.read(userProvider);
      expect(state.vehicles.any((v) => v.id == 'new-vehicle'), isTrue);
    });
  });

  group('UserNotifier — deleteVehicle', () {
    test('retire le véhicule de la liste locale immédiatement', () async {
      final fakeService = _FakeUserFirestoreService(
        userToReturn: _user(),
        vehiclesToReturn: [_vehicle(id: 'v1'), _vehicle(id: 'v2')],
      );
      final container = _makeContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('uid-1');
      expect(container.read(userProvider).vehicles.length, 2);

      await container.read(userProvider.notifier).deleteVehicle('uid-1', 'v1');

      final state = container.read(userProvider);
      expect(state.vehicles.length, 1);
      expect(state.vehicles.any((v) => v.id == 'v1'), isFalse);
      expect(fakeService.deletedVehicleIds, contains('v1'));
    });
  });

  group('UserNotifier — setDefaultVehicle', () {
    test(
        'marque le bon véhicule comme sélectionné et désélectionne'
        ' les autres', () async {
      final fakeService = _FakeUserFirestoreService(
        userToReturn: _user(),
        vehiclesToReturn: [
          _vehicle(id: 'v1', isCurrentlySelected: true),
          _vehicle(id: 'v2', isCurrentlySelected: false),
        ],
      );
      final container = _makeContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('uid-1');

      await container
          .read(userProvider.notifier)
          .setDefaultVehicle('uid-1', 'v2');

      final state = container.read(userProvider);
      final v1 = state.vehicles.firstWhere((v) => v.id == 'v1');
      final v2 = state.vehicles.firstWhere((v) => v.id == 'v2');

      expect(v2.isCurrentlySelected, isTrue);
      expect(v1.isCurrentlySelected, isFalse,
          reason: 'Un seul véhicule doit être sélectionné à la fois');
    });
  });

  group('UserNotifier — markNotificationRead', () {
    test('marque la notification comme lue de façon optimiste', () async {
      final notif = NotificationModel(
        id: 'notif-1',
        title: 'Test',
        body: 'Test body',
        isRead: false,
        receivedAt: DateTime.now(),
      );
      final fakeService = _FakeUserFirestoreService(
        userToReturn: _user(),
        notificationsToReturn: [notif],
      );
      final container = _makeContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('uid-1');
      expect(container.read(userProvider).unreadNotificationsCount, 1);

      await container
          .read(userProvider.notifier)
          .markNotificationRead('uid-1', 'notif-1');

      final state = container.read(userProvider);
      expect(state.unreadNotificationsCount, 0);
      expect(fakeService.markedReadNotifIds, contains('notif-1'));
    });
  });

  group('UserNotifier — markAllNotificationsRead', () {
    test(
        'marque toutes les notifications non lues comme lues en un'
        ' seul appel', () async {
      final notifs = [
        NotificationModel(
          id: 'n1',
          title: 'A',
          body: 'A',
          isRead: false,
          receivedAt: DateTime.now(),
        ),
        NotificationModel(
          id: 'n2',
          title: 'B',
          body: 'B',
          isRead: false,
          receivedAt: DateTime.now(),
        ),
        NotificationModel(
          id: 'n3',
          title: 'C',
          body: 'C',
          isRead: true,
          receivedAt: DateTime.now(),
        ),
      ];
      final fakeService = _FakeUserFirestoreService(
        userToReturn: _user(),
        notificationsToReturn: notifs,
      );
      final container = _makeContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('uid-1');
      expect(container.read(userProvider).unreadNotificationsCount, 2);

      await container
          .read(userProvider.notifier)
          .markAllNotificationsRead('uid-1');

      final state = container.read(userProvider);
      expect(state.unreadNotificationsCount, 0);
      expect(fakeService.markedReadNotifIds, containsAll(['n1', 'n2']));
      expect(fakeService.markedReadNotifIds, isNot(contains('n3')),
          reason: 'Une notification déjà lue ne doit pas être re-marquée '
              'inutilement');
    });

    test('ne fait rien s\'il n\'y a aucune notification non lue', () async {
      final fakeService = _FakeUserFirestoreService(
        userToReturn: _user(),
        notificationsToReturn: [
          NotificationModel(
            id: 'n1',
            title: 'A',
            body: 'A',
            isRead: true,
            receivedAt: DateTime.now(),
          ),
        ],
      );
      final container = _makeContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('uid-1');

      await container
          .read(userProvider.notifier)
          .markAllNotificationsRead('uid-1');

      expect(fakeService.markedReadNotifIds, isEmpty);
    });
  });

  group('UserNotifier — updateProfilePicture', () {
    test('upload réussi → met à jour Firestore et le state local', () async {
      final fakeService = _FakeUserFirestoreService(userToReturn: _user());
      final container = _makeContainer(
        fakeService,
        storageService: MockStorageService(
          urlToReturn: 'https://cloudinary.com/new-photo.jpg',
        ),
      );
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('uid-1');

      // Vide les appels accumulés par loadUserData (le backfill
      // preferredLanguage peut avoir déclenché updateUser ici) — on
      // ne veut vérifier QUE ce que updateProfilePicture fait.
      fakeService.updatedFieldsCalls.clear();

      await container
          .read(userProvider.notifier)
          .updateProfilePicture(File('fake_path.jpg'), 'uid-1');

      final state = container.read(userProvider);
      expect(
          state.user?.profileImageUrl, 'https://cloudinary.com/new-photo.jpg');
      expect(fakeService.updatedFieldsCalls, isNotEmpty);
      expect(fakeService.updatedFieldsCalls.first['profileImageUrl'],
          'https://cloudinary.com/new-photo.jpg');
    });

    test('upload échoué (url null) → n\'écrit rien dans Firestore', () async {
      final fakeService = _FakeUserFirestoreService(userToReturn: _user());
      final container = _makeContainer(
        fakeService,
        storageService: MockStorageService(urlToReturn: null),
      );
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('uid-1');

      // Vide les appels accumulés par loadUserData (le backfill
      // preferredLanguage peut avoir déclenché updateUser ici) —
      // on ne veut vérifier QUE ce que updateProfilePicture fait.
      fakeService.updatedFieldsCalls.clear();

      await container
          .read(userProvider.notifier)
          .updateProfilePicture(File('fake_path.jpg'), 'uid-1');

      expect(fakeService.updatedFieldsCalls, isEmpty,
          reason: 'Si Cloudinary échoue (url null), aucune mise à jour '
              'ne doit être tentée côté Firestore');
    });
  });
}
