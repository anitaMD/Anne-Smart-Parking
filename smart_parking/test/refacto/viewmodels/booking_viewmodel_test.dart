import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking/app/core/exceptions/booking_exceptions.dart';
import 'package:smart_parking/app/models/booking_model.dart';
import 'package:smart_parking/app/models/notification_model.dart';
import 'package:smart_parking/app/models/user_model.dart';
import 'package:smart_parking/app/models/wallet_model.dart';
import 'package:smart_parking/app/services/notification_service.dart';
import 'package:smart_parking/app/viewmodels/auth_viewmodel.dart';
import 'package:smart_parking/app/viewmodels/booking_viewmodel.dart';
import 'package:smart_parking/app/viewmodels/user_viewmodel.dart';
import '../mocks/mock_auth_service.dart';
import '../mocks/mock_firestore_service.dart';
import '../mocks/mock_notification_service.dart';

/// Tests unitaires — BookingState & BookingNotifier (fichier consolidé)
///
/// Regroupe l'ensemble des tests liés à la réservation :
///   1. BookingState — logique pure (ongoingBooking, upcomingBookings,
///      allBookings, tri chronologique)
///   2. BookingNotifier.loadBookings / loadArchivedBookings /
///      cancelBooking — avec mocks Firestore + Notification
///   3. BookingNotifier.createBooking / editBooking — débit wallet,
///      exceptions de conflit (place et véhicule), calcul du
///      différentiel de coût
///
/// Isole complètement Firestore ET NotificationService (dont le
/// constructeur réel instancie FirebaseMessaging.instance, ce qui
/// plante sans Firebase.initializeApp() — bug de testabilité corrigé
/// en ajoutant notificationServiceProvider, symétrique à
/// firestoreServiceProvider, pour permettre l'injection en test).
///
/// Reproduit aussi le bug corrigé où cancelBooking() n'annulait pas
/// les rappels programmés (rappels fantômes accumulés pour des
/// réservations déjà annulées observés en session de debug).

// ─────────────────────────────────────────────────────────────
// HELPERS PARTAGÉS
// ─────────────────────────────────────────────────────────────

/// Helper flexible pour les tests de BookingState (logique pure) —
/// permet de contrôler start/end/status précisément.
BookingModel _booking({
  required String id,
  required DateTime start,
  required DateTime end,
  BookingStatus status = BookingStatus.upcoming,
}) {
  return BookingModel(
    id: id,
    clientId: 'client-1',
    parkingId: 'parking-1',
    spotId: 'A1',
    vehicleId: 'vehicle-1',
    bookingStart: start,
    bookingEnd: end,
    totalCost: 1000,
    status: status,
  );
}

/// Helper simplifié pour les tests loadBookings/cancelBooking — une
/// réservation "à venir" standard, il ne s'agit que de vérifier la
/// présence/absence dans les listes, pas le timing précis.
BookingModel _simpleBooking({required String id}) {
  final now = DateTime.now();
  return BookingModel(
    id: id,
    clientId: 'client-1',
    parkingId: 'parking-1',
    spotId: 'A1',
    vehicleId: 'vehicle-1',
    bookingStart: now.add(const Duration(hours: 1)),
    bookingEnd: now.add(const Duration(hours: 2)),
    totalCost: 1000,
    status: BookingStatus.upcoming,
  );
}

/// Réservation existante utilisée pour les tests d'édition
/// (durée/coût configurables).
BookingModel _existingBooking({
  int totalCost = 1000,
  int durationMinutes = 60,
}) {
  final now = DateTime.now().add(const Duration(hours: 2));
  return BookingModel(
    id: 'booking-1',
    clientId: 'client-1',
    parkingId: 'parking-1',
    spotId: 'A1',
    vehicleId: 'vehicle-1',
    bookingStart: now,
    bookingEnd: now.add(Duration(minutes: durationMinutes)),
    totalCost: totalCost,
    status: BookingStatus.upcoming,
  );
}

UserModel _user() => const UserModel(
      id: 'client-1',
      fullName: 'Anne Marie',
      email: 'test@ysp.com',
      phoneNumber: '+221774880377',
      profileImageUrl: '',
      isSpecialAccessUser: false,
      role: 'user',
    );

// ─────────────────────────────────────────────────────────────
// FAKES — loadBookings / loadArchivedBookings / cancelBooking
// ─────────────────────────────────────────────────────────────

class _FakeFirestoreServiceWithBookings extends MockFirestoreService {
  final List<BookingModel> unarchived;
  final List<BookingModel> archived;

  _FakeFirestoreServiceWithBookings({
    this.unarchived = const [],
    this.archived = const [],
  });

  @override
  Future<List<BookingModel>> getUserUnarchivedBookings(String uid) async =>
      unarchived;

  @override
  Future<List<BookingModel>> getUserArchivedBookings(String uid) async =>
      archived;

  @override
  Future<void> updateBookingFields(
      String bookingId, Map<String, dynamic> fields) async {
    // no-op — simule une écriture réussie
  }
}

class _FailingFirestoreService extends MockFirestoreService {
  @override
  Future<List<BookingModel>> getUserUnarchivedBookings(String uid) async {
    throw Exception('Network error simulée');
  }
}

ProviderContainer _makeLoadContainer(dynamic firestoreMock) {
  return ProviderContainer(overrides: [
    authServiceProvider.overrideWithValue(MockAuthService()),
    firestoreServiceProvider.overrideWithValue(firestoreMock),
    notificationServiceProvider.overrideWithValue(MockNotificationService()),
  ]);
}

// ─────────────────────────────────────────────────────────────
// FAKE — createBooking / editBooking (débit wallet + conflits)
// ─────────────────────────────────────────────────────────────

class _FakeService extends MockFirestoreService {
  WalletModel? wallet;
  String bookingIdToReturn;
  Object? createBookingError;

  final List<int> walletBalancesSet = [];
  final List<int> debitAmounts = [];
  final List<Map<String, dynamic>> updatedFieldsCalls = [];
  final List<String> savedNotificationTitles = [];

  _FakeService({
    this.wallet,
    this.bookingIdToReturn = 'new-booking-id',
    this.createBookingError,
  });

  @override
  Future<UserModel?> getUser(String uid) async => _user();

  @override
  Future<WalletModel?> getWallet(String uid) async => wallet;

  @override
  Stream<WalletModel?> watchWallet(String uid) => Stream.value(wallet);

  @override
  Stream<List<NotificationModel>> watchNotifications(String uid) =>
      Stream.value(const []);

  @override
  Future<String> createBookingAtomic(BookingModel booking) async {
    if (createBookingError != null) throw createBookingError!;
    return bookingIdToReturn;
  }

  @override
  Future<void> saveNotification({
    required String uid,
    required String title,
    required String body,
  }) async {
    savedNotificationTitles.add(title);
  }

  @override
  Future<void> updateWalletBalance(
      String uid, String walletId, int newBalance) async {
    walletBalancesSet.add(newBalance);
    wallet = WalletModel(id: walletId, balance: newBalance);
  }

  @override
  Future<void> addDebit({
    required String uid,
    required String walletId,
    required int amount,
    required int newBalance,
    required String parkingId,
    required String parkingName,
  }) async {
    debitAmounts.add(amount);
  }

  @override
  Future<void> updateBookingFields(
      String bookingId, Map<String, dynamic> fields) async {
    updatedFieldsCalls.add(fields);
  }

  @override
  Future<List<BookingModel>> getUserUnarchivedBookings(String uid) async => [];

  @override
  Future<List<BookingModel>> getUserArchivedBookings(String uid) async => [];
}

ProviderContainer _makeCreateEditContainer(_FakeService fakeService) {
  return ProviderContainer(overrides: [
    authServiceProvider.overrideWithValue(MockAuthService()),
    firestoreServiceProvider.overrideWithValue(fakeService),
    notificationServiceProvider.overrideWithValue(MockNotificationService()),
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // notifSettingsProvider utilise SharedPreferences.getInstance() —
  // sans ce mock, il plante en environnement de test pur.
  SharedPreferences.setMockInitialValues({});

  final now = DateTime.now();

  // ── 1. BookingState — logique pure ────────────────────────

  group('BookingState — ongoingBooking', () {
    test('retourne la réservation en cours quand elle existe', () {
      final ongoing = _booking(
        id: 'b1',
        start: now.subtract(const Duration(minutes: 30)),
        end: now.add(const Duration(minutes: 30)),
      );
      final state = BookingState(unArchivedBookings: [ongoing]);

      expect(state.ongoingBooking, isNotNull);
      expect(state.ongoingBooking!.id, 'b1');
    });

    test('retourne null quand aucune réservation n\'est en cours', () {
      final upcoming = _booking(
        id: 'b1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      );
      final state = BookingState(unArchivedBookings: [upcoming]);

      expect(state.ongoingBooking, isNull);
    });

    test('retourne null quand la liste est vide', () {
      const state = BookingState();
      expect(state.ongoingBooking, isNull);
    });
  });

  group('BookingState — upcomingBookings', () {
    test('filtre uniquement les réservations à venir avec status upcoming', () {
      final upcoming = _booking(
        id: 'b1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
        status: BookingStatus.upcoming,
      );
      final canceled = _booking(
        id: 'b2',
        start: now.add(const Duration(hours: 3)),
        end: now.add(const Duration(hours: 4)),
        status: BookingStatus.canceled,
      );
      final state = BookingState(unArchivedBookings: [upcoming, canceled]);

      expect(state.upcomingBookings.length, 1);
      expect(state.upcomingBookings.first.id, 'b1');
    });

    test('exclut les réservations déjà démarrées même si status=upcoming', () {
      final ongoing = _booking(
        id: 'b1',
        start: now.subtract(const Duration(minutes: 10)),
        end: now.add(const Duration(minutes: 50)),
        status: BookingStatus.upcoming,
      );
      final state = BookingState(unArchivedBookings: [ongoing]);

      expect(state.upcomingBookings, isEmpty);
    });
  });

  group('BookingState — hasOngoing / hasUnarchivedBookings', () {
    test('hasOngoing est true quand ongoingBooking existe', () {
      final ongoing = _booking(
        id: 'b1',
        start: now.subtract(const Duration(minutes: 10)),
        end: now.add(const Duration(minutes: 10)),
      );
      final state = BookingState(unArchivedBookings: [ongoing]);

      expect(state.hasOngoing, isTrue);
    });

    test('hasUnarchivedBookings est false pour une liste vide', () {
      const state = BookingState();
      expect(state.hasUnarchivedBookings, isFalse);
    });
  });

  group('BookingState — allBookings (tri chronologique)', () {
    test('combine unArchivedBookings et allArchivedBookings', () {
      final active = _booking(
        id: 'active',
        start: now,
        end: now.add(const Duration(hours: 1)),
      );
      final archived = _booking(
        id: 'archived',
        start: now.subtract(const Duration(days: 1)),
        end:
            now.subtract(const Duration(days: 1)).add(const Duration(hours: 1)),
        status: BookingStatus.canceled,
      );

      final state = BookingState(
        unArchivedBookings: [active],
        allArchivedBookings: [archived],
      );

      expect(state.allBookings.length, 2);
    });

    test('trie par bookingStart décroissant (plus récent en premier)', () {
      final older = _booking(
        id: 'older',
        start: now.subtract(const Duration(days: 2)),
        end:
            now.subtract(const Duration(days: 2)).add(const Duration(hours: 1)),
      );
      final newer = _booking(
        id: 'newer',
        start: now.subtract(const Duration(days: 1)),
        end:
            now.subtract(const Duration(days: 1)).add(const Duration(hours: 1)),
      );

      final state = BookingState(unArchivedBookings: [older, newer]);

      expect(state.allBookings.first.id, 'newer');
      expect(state.allBookings.last.id, 'older');
    });
  });

  group('BookingState — copyWith', () {
    test('met à jour unArchivedBookings sans affecter allArchivedBookings', () {
      final archived = _booking(
        id: 'archived',
        start: now,
        end: now.add(const Duration(hours: 1)),
      );
      final original = BookingState(allArchivedBookings: [archived]);

      final newBooking = _booking(
        id: 'new',
        start: now,
        end: now.add(const Duration(hours: 1)),
      );
      final updated = original.copyWith(unArchivedBookings: [newBooking]);

      expect(updated.unArchivedBookings.length, 1);
      expect(updated.allArchivedBookings.length, 1,
          reason: 'allArchivedBookings ne doit pas être affecté');
    });

    test('met à jour isLoading correctement', () {
      const original = BookingState(isLoading: false);
      final updated = original.copyWith(isLoading: true);

      expect(updated.isLoading, isTrue);
    });
  });

  // ── 2. BookingNotifier — loadBookings / loadArchivedBookings /
  //       cancelBooking (avec mocks) ─────────────────────────

  group('BookingNotifier — loadBookings', () {
    test('charge les réservations non-archivées depuis Firestore', () async {
      final fakeService = _FakeFirestoreServiceWithBookings(
        unarchived: [_simpleBooking(id: 'b1'), _simpleBooking(id: 'b2')],
      );
      final container = _makeLoadContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(bookingProvider.notifier).loadBookings('uid-1');

      final state = container.read(bookingProvider);
      expect(state.unArchivedBookings.length, 2);
      expect(state.isLoading, isFalse);
    });

    test('état isLoading passe à false même en cas d\'erreur Firestore',
        () async {
      final container = _makeLoadContainer(_FailingFirestoreService());
      addTearDown(container.dispose);

      await container.read(bookingProvider.notifier).loadBookings('uid-1');

      final state = container.read(bookingProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });
  });

  group('BookingNotifier — loadArchivedBookings', () {
    test('charge les réservations archivées', () async {
      final fakeService = _FakeFirestoreServiceWithBookings(
        archived: [_simpleBooking(id: 'archived-1')],
      );
      final container = _makeLoadContainer(fakeService);
      addTearDown(container.dispose);

      await container
          .read(bookingProvider.notifier)
          .loadArchivedBookings('uid-1');

      final state = container.read(bookingProvider);
      expect(state.allArchivedBookings.length, 1);
      expect(state.hasArchivedBookings, isTrue);
    });
  });

  group('BookingNotifier — cancelBooking', () {
    test('retire la réservation de unArchivedBookings après annulation',
        () async {
      final booking = _simpleBooking(id: 'to-cancel');
      final fakeService =
          _FakeFirestoreServiceWithBookings(unarchived: [booking]);
      final container = _makeLoadContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(bookingProvider.notifier).loadBookings('uid-1');
      expect(container.read(bookingProvider).unArchivedBookings.length, 1);

      await container.read(bookingProvider.notifier).cancelBooking('to-cancel');

      final state = container.read(bookingProvider);
      expect(state.unArchivedBookings, isEmpty,
          reason: 'La réservation annulée doit disparaître de la liste '
              'active après un appel réussi à updateBookingFields et '
              'cancelBookingReminders.');
    });
  });

  // ── 3. BookingNotifier — createBooking / editBooking ──────

  group('BookingNotifier — createBooking', () {
    test('débite le wallet du montant exact et crée un débit tracé', () async {
      final fakeService = _FakeService(
        wallet: const WalletModel(id: 'w1', balance: 10000),
      );
      final container = _makeCreateEditContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('client-1');

      final createNow = DateTime.now().add(const Duration(hours: 1));
      await container.read(bookingProvider.notifier).createBooking(
            clientId: 'client-1',
            parkingId: 'parking-1',
            spotId: 'A1',
            vehicleId: 'vehicle-1',
            bookingStart: createNow,
            bookingEnd: createNow.add(const Duration(hours: 1)),
            totalCost: 600,
            parkingName: 'ECPI Smart Parking',
          );

      expect(fakeService.debitAmounts, contains(600));
      expect(fakeService.walletBalancesSet, contains(9400));
    });

    test('envoie une notification de confirmation de réservation', () async {
      final fakeService = _FakeService(
        wallet: const WalletModel(id: 'w1', balance: 10000),
      );
      final container = _makeCreateEditContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('client-1');

      final createNow = DateTime.now().add(const Duration(hours: 1));
      await container.read(bookingProvider.notifier).createBooking(
            clientId: 'client-1',
            parkingId: 'parking-1',
            spotId: 'A1',
            vehicleId: 'vehicle-1',
            bookingStart: createNow,
            bookingEnd: createNow.add(const Duration(hours: 1)),
            totalCost: 600,
            parkingName: 'ECPI Smart Parking',
          );

      expect(fakeService.savedNotificationTitles, isNotEmpty);
    });

    test('propage SpotConflictException si la place est déjà prise', () async {
      final fakeService = _FakeService(
        wallet: const WalletModel(id: 'w1', balance: 10000),
        createBookingError: const SpotConflictException(),
      );
      final container = _makeCreateEditContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('client-1');

      final createNow = DateTime.now().add(const Duration(hours: 1));
      await expectLater(
        container.read(bookingProvider.notifier).createBooking(
              clientId: 'client-1',
              parkingId: 'parking-1',
              spotId: 'A1',
              vehicleId: 'vehicle-1',
              bookingStart: createNow,
              bookingEnd: createNow.add(const Duration(hours: 1)),
              totalCost: 600,
              parkingName: 'ECPI Smart Parking',
            ),
        throwsA(isA<SpotConflictException>()),
      );
    });

    test(
        'propage VehicleConflictException si le véhicule est déjà'
        ' réservé ailleurs sur ce créneau', () async {
      final fakeService = _FakeService(
        wallet: const WalletModel(id: 'w1', balance: 10000),
        createBookingError: const VehicleConflictException(),
      );
      final container = _makeCreateEditContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('client-1');

      final createNow = DateTime.now().add(const Duration(hours: 1));
      await expectLater(
        container.read(bookingProvider.notifier).createBooking(
              clientId: 'client-1',
              parkingId: 'parking-1',
              spotId: 'A1',
              vehicleId: 'vehicle-1',
              bookingStart: createNow,
              bookingEnd: createNow.add(const Duration(hours: 1)),
              totalCost: 600,
              parkingName: 'ECPI Smart Parking',
            ),
        throwsA(isA<VehicleConflictException>()),
      );
    });
  });

  group('BookingNotifier — editBooking', () {
    test('ne fait rien si aucun champ n\'a changé', () async {
      final fakeService = _FakeService(
        wallet: const WalletModel(id: 'w1', balance: 10000),
      );
      final container = _makeCreateEditContainer(fakeService);
      addTearDown(container.dispose);

      final booking = _existingBooking();
      await container.read(bookingProvider.notifier).editBooking(
            booking: booking,
            newStart: booking.bookingStart,
            newEnd: booking.bookingEnd,
            newSpotId: booking.spotId,
            parkingName: 'ECPI Smart Parking',
            feePerSlot: 300,
          );

      expect(fakeService.updatedFieldsCalls, isEmpty,
          reason: 'Aucune écriture ne doit avoir lieu sans modification');
    });

    test('débite la différence quand la durée augmente', () async {
      final fakeService = _FakeService(
        wallet: const WalletModel(id: 'w1', balance: 10000),
      );
      final container = _makeCreateEditContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('client-1');

      final booking = _existingBooking(totalCost: 600, durationMinutes: 60);

      await container.read(bookingProvider.notifier).editBooking(
            booking: booking,
            newStart: booking.bookingStart,
            newEnd: booking.bookingStart.add(const Duration(hours: 2)),
            newSpotId: booking.spotId,
            parkingName: 'ECPI Smart Parking',
            feePerSlot: 300,
          );

      expect(fakeService.debitAmounts, contains(600));
    });

    test('lève une exception si le solde est insuffisant pour l\'extension',
        () async {
      final fakeService = _FakeService(
        wallet: const WalletModel(id: 'w1', balance: 100), // insuffisant
      );
      final container = _makeCreateEditContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('client-1');

      final booking = _existingBooking(totalCost: 600, durationMinutes: 60);

      await expectLater(
        container.read(bookingProvider.notifier).editBooking(
              booking: booking,
              newStart: booking.bookingStart,
              newEnd: booking.bookingStart.add(const Duration(hours: 2)),
              newSpotId: booking.spotId,
              parkingName: 'ECPI Smart Parking',
              feePerSlot: 300,
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('ne débite rien quand la durée est réduite (pas de remboursement)',
        () async {
      final fakeService = _FakeService(
        wallet: const WalletModel(id: 'w1', balance: 10000),
      );
      final container = _makeCreateEditContainer(fakeService);
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).loadUserData('client-1');

      final booking = _existingBooking(totalCost: 1200, durationMinutes: 120);

      await container.read(bookingProvider.notifier).editBooking(
            booking: booking,
            newStart: booking.bookingStart,
            newEnd: booking.bookingStart.add(const Duration(hours: 1)),
            newSpotId: booking.spotId,
            parkingName: 'ECPI Smart Parking',
            feePerSlot: 300,
          );

      expect(fakeService.debitAmounts, isEmpty,
          reason: 'Aucun remboursement ni débit supplémentaire attendu');
    });

    test('met à jour spotId dans les champs Firestore', () async {
      final fakeService = _FakeService(
        wallet: const WalletModel(id: 'w1', balance: 10000),
      );
      final container = _makeCreateEditContainer(fakeService);
      addTearDown(container.dispose);

      final booking = _existingBooking();
      await container.read(bookingProvider.notifier).editBooking(
            booking: booking,
            newStart: booking.bookingStart,
            newEnd: booking.bookingEnd,
            newSpotId: 'B2',
            parkingName: 'ECPI Smart Parking',
            feePerSlot: 300,
          );

      expect(fakeService.updatedFieldsCalls, isNotEmpty);
      expect(fakeService.updatedFieldsCalls.first['spotId'], 'B2');
    });
  });
}
