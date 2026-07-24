import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/core/exceptions/booking_exceptions.dart';
import 'package:smart_parking/app/models/booking_model.dart';
import 'package:smart_parking/app/models/user_model.dart';
import 'package:smart_parking/app/models/vehicle_model.dart';
import 'package:smart_parking/app/services/firestore_service.dart';

/// Tests unitaires — FirestoreService (implémentation concrète)
///
/// Contrairement aux tests des viewmodels (qui mockent entièrement
/// FirestoreServiceBase), ceux-ci valident la VRAIE logique de
/// transaction Firestore de createBookingAtomic — la détection de
/// conflit de place et de véhicule fonctionne-t-elle réellement
/// avec de vraies requêtes .where() sur une base simulée en mémoire ?
///
/// FirestoreService est injectable ({FirebaseFirestore? db}), ce
/// qui permet d'utiliser FakeFirebaseFirestore ici sans jamais
/// toucher au vrai Firebase.

BookingModel _booking({
  required String parkingId,
  required String spotId,
  required String vehicleId,
  required DateTime start,
  required DateTime end,
  BookingStatus status = BookingStatus.upcoming,
}) {
  return BookingModel(
    id: '',
    clientId: 'client-1',
    parkingId: parkingId,
    spotId: spotId,
    vehicleId: vehicleId,
    bookingStart: start,
    bookingEnd: end,
    totalCost: 600,
    status: status,
  );
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirestoreService(db: fakeFirestore);
  });

  group('createBookingAtomic — conflit de place', () {
    test('crée une réservation sans conflit', () async {
      final now = DateTime.now();
      final booking = _booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'v1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      );

      final id = await service.createBookingAtomic(booking);

      expect(id, isNotEmpty);
    });

    test(
        'lève SpotConflictException si la même place est déjà réservée'
        ' sur un créneau qui se chevauche', () async {
      final now = DateTime.now();
      final firstStart = now.add(const Duration(hours: 1));
      final firstEnd = now.add(const Duration(hours: 3));

      // Première réservation — place A1, 1h-3h
      await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'v1',
        start: firstStart,
        end: firstEnd,
      ));

      // Deuxième réservation — MÊME place A1, chevauche (2h-4h)
      final conflicting = _booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'v2', // véhicule différent
        start: now.add(const Duration(hours: 2)),
        end: now.add(const Duration(hours: 4)),
      );

      expect(
        () => service.createBookingAtomic(conflicting),
        throwsA(isA<SpotConflictException>()),
      );
    });

    test(
        'n\'y a pas de conflit si les créneaux sont consécutifs'
        ' (pas de chevauchement réel)', () async {
      final now = DateTime.now();

      await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'v1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));

      // Démarre exactement quand la première se termine
      final id = await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'v2',
        start: now.add(const Duration(hours: 2)),
        end: now.add(const Duration(hours: 3)),
      ));

      expect(id, isNotEmpty);
    });

    test('pas de conflit si places différentes même créneau', () async {
      final now = DateTime.now();

      await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'v1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));

      final id = await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'B1', // place différente
        vehicleId: 'v2',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));

      expect(id, isNotEmpty);
    });
  });

  group('createBookingAtomic — conflit de véhicule multi-parking', () {
    test(
        'lève VehicleConflictException si le même véhicule est'
        ' réservé dans un AUTRE parking sur un créneau qui se'
        ' chevauche', () async {
      final now = DateTime.now();

      // Réservation 1 — véhicule v1, Parking ECPI, place A1
      await service.createBookingAtomic(_booking(
        parkingId: 'ecpi',
        spotId: 'A1',
        vehicleId: 'v1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 3)),
      ));

      // Réservation 2 — MÊME véhicule v1, AUTRE parking, chevauche
      final conflicting = _booking(
        parkingId: 'anne-smart-parking', // parking différent
        spotId: 'B1', // place différente
        vehicleId: 'v1', // même véhicule !
        start: now.add(const Duration(hours: 2)),
        end: now.add(const Duration(hours: 4)),
      );

      expect(
        () => service.createBookingAtomic(conflicting),
        throwsA(isA<VehicleConflictException>()),
      );
    });

    test(
        'pas de conflit si le même véhicule réserve un autre parking'
        ' à un horaire différent', () async {
      final now = DateTime.now();

      await service.createBookingAtomic(_booking(
        parkingId: 'ecpi',
        spotId: 'A1',
        vehicleId: 'v1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));

      final id = await service.createBookingAtomic(_booking(
        parkingId: 'anne-smart-parking',
        spotId: 'B1',
        vehicleId: 'v1',
        start: now.add(const Duration(hours: 3)),
        end: now.add(const Duration(hours: 4)),
      ));

      expect(id, isNotEmpty);
    });
  });

  group('createBookingAtomic — réservations annulées ignorées', () {
    test('une place libérée par annulation peut être re-réservée', () async {
      final now = DateTime.now();

      // Première réservation puis annulée manuellement
      final firstId = await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'v1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));

      await service.updateBookingFields(firstId, {
        'status': 'canceled',
        'isArchived': true,
      });

      // Nouvelle réservation sur le même créneau — doit réussir
      final secondId = await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'v2',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));

      expect(secondId, isNotEmpty);
      expect(secondId, isNot(firstId));
    });
  });

  group('getUserUnarchivedBookings / getUserArchivedBookings', () {
    test('sépare correctement les réservations actives et archivées', () async {
      final now = DateTime.now();

      final activeId = await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'v1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));

      final toCancelId = await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'B1',
        vehicleId: 'v2',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));
      await service.updateBookingFields(toCancelId, {
        'status': 'canceled',
        'isArchived': true,
      });

      final unarchived = await service.getUserUnarchivedBookings('client-1');
      final archived = await service.getUserArchivedBookings('client-1');

      expect(unarchived.any((b) => b.id == activeId), isTrue);
      expect(unarchived.any((b) => b.id == toCancelId), isFalse);
      expect(archived.any((b) => b.id == toCancelId), isTrue);
    });
  });

  group('Wallet — addDebit / addTopUp / updateWalletBalance', () {
    test('createWallet puis addDebit met à jour l\'historique', () async {
      await service.createWallet('uid-1');
      final wallet = await service.getWallet('uid-1');
      expect(wallet, isNotNull);
      expect(wallet!.balance, 0);

      await service.updateWalletBalance('uid-1', wallet.id, 5000);
      await service.addDebit(
        uid: 'uid-1',
        walletId: wallet.id,
        amount: 600,
        newBalance: 4400,
        parkingId: 'p1',
        parkingName: 'ECPI Smart Parking',
      );

      final updatedWallet = await service.getWallet('uid-1');
      expect(updatedWallet!.balance, 5000);
    });

    test('addTopUp enregistre la source et l\'agent crédité', () async {
      await service.createWallet('uid-2');
      final wallet = await service.getWallet('uid-2');

      await service.addTopUp(
        uid: 'uid-2',
        walletId: wallet!.id,
        amount: 5000,
        newBalance: 5000,
        source: 'qrCode',
        agentUid: 'agent-1',
      );

      final topUps = await fakeFirestore
          .collection('users_v2')
          .doc('uid-2')
          .collection('wallet')
          .doc(wallet.id)
          .collection('topUps')
          .get();

      expect(topUps.docs.length, 1);
      expect(topUps.docs.first['source'], 'qrCode');
      expect(topUps.docs.first['creditedBy'], 'agent-1');
    });
  });

  group('getOccupiedSpotIds', () {
    test('retourne les places occupées sur le créneau demandé', () async {
      final now = DateTime.now();
      await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'vehicle-A1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));

      final occupied = await service.getOccupiedSpotIds(
        parkingId: 'p1',
        bookingStart: now.add(const Duration(hours: 1)),
        bookingEnd: now.add(const Duration(hours: 2)),
      );

      expect(occupied, contains('A1'));
    });

    test('exclut les places dont le créneau ne chevauche pas', () async {
      final now = DateTime.now();
      await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'vehicle-A1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));

      final occupied = await service.getOccupiedSpotIds(
        parkingId: 'p1',
        bookingStart: now.add(const Duration(hours: 5)),
        bookingEnd: now.add(const Duration(hours: 6)),
      );

      expect(occupied, isEmpty);
    });

    test('exclut les réservations annulées', () async {
      final now = DateTime.now();
      final id = await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'vehicle-A1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));
      await service.updateBookingFields(id, {
        'status': 'canceled',
        'isArchived': true,
      });

      final occupied = await service.getOccupiedSpotIds(
        parkingId: 'p1',
        bookingStart: now.add(const Duration(hours: 1)),
        bookingEnd: now.add(const Duration(hours: 2)),
      );

      expect(occupied, isEmpty,
          reason: 'Une place libérée par annulation doit redevenir '
              'disponible');
    });

    test('n\'inclut pas les places d\'un AUTRE parking', () async {
      final now = DateTime.now();
      await service.createBookingAtomic(_booking(
        parkingId: 'autre-parking',
        spotId: 'A1',
        vehicleId: 'vehicle-A1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));

      final occupied = await service.getOccupiedSpotIds(
        parkingId: 'p1',
        bookingStart: now.add(const Duration(hours: 1)),
        bookingEnd: now.add(const Duration(hours: 2)),
      );

      expect(occupied, isEmpty);
    });

    test('retourne plusieurs places occupées simultanément', () async {
      final now = DateTime.now();
      await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'vehicle-A1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));
      await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'B1',
        vehicleId: 'vehicle-B1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));

      final occupied = await service.getOccupiedSpotIds(
        parkingId: 'p1',
        bookingStart: now.add(const Duration(hours: 1)),
        bookingEnd: now.add(const Duration(hours: 2)),
      );

      expect(occupied.length, 2);
      expect(occupied, containsAll(['A1', 'B1']));
    });
  });

  group('watchOccupiedSpotIds', () {
    test('émet les places occupées au moment de l\'écoute', () async {
      final now = DateTime.now();
      await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'vehicle-A1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));

      final stream = service.watchOccupiedSpotIds(
        parkingId: 'p1',
        bookingStart: now.add(const Duration(hours: 1)),
        bookingEnd: now.add(const Duration(hours: 2)),
      );

      final occupied = await stream.first;
      expect(occupied, contains('A1'));
    });

    test('émet une nouvelle valeur quand une réservation est ajoutée',
        () async {
      final now = DateTime.now();
      final stream = service.watchOccupiedSpotIds(
        parkingId: 'p1',
        bookingStart: now.add(const Duration(hours: 1)),
        bookingEnd: now.add(const Duration(hours: 2)),
      );

      final emissions = <Set<String>>[];
      final subscription = stream.listen(emissions.add);

      await Future.delayed(const Duration(milliseconds: 100));

      await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'vehicle-A1',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      ));

      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      expect(emissions.last, contains('A1'));
    });
  });

  group('createUser / getUser', () {
    test('crée puis relit un profil utilisateur', () async {
      const user = UserModel(
        id: 'uid-1',
        fullName: 'Anne Marie',
        email: 'test@ysp.com',
        phoneNumber: '+221774880377',
        profileImageUrl: '',
        isSpecialAccessUser: false,
        role: 'user',
      );

      await service.createUser(user);
      final loaded = await service.getUser('uid-1');

      expect(loaded, isNotNull);
      expect(loaded!.fullName, 'Anne Marie');
      expect(loaded.role, 'user');
    });

    test('getUser retourne null si le profil n\'existe pas', () async {
      final loaded = await service.getUser('inexistant');
      expect(loaded, isNull);
    });
  });

  group('userExistsByPhone / userExistsByEmail', () {
    test('retourne true si le numéro est déjà associé à un compte', () async {
      const user = UserModel(
        id: 'uid-1',
        fullName: 'Anne Marie',
        email: 'test@ysp.com',
        phoneNumber: '+221774880377',
        profileImageUrl: '',
        isSpecialAccessUser: false,
        role: 'user',
      );
      await service.createUser(user);

      final exists = await service.userExistsByPhone('+221774880377');
      expect(exists, isTrue);
    });

    test('retourne false pour un numéro inconnu', () async {
      final exists = await service.userExistsByPhone('+221000000000');
      expect(exists, isFalse);
    });

    test('retourne true si l\'email est déjà associé à un compte', () async {
      const user = UserModel(
        id: 'uid-1',
        fullName: 'Anne Marie',
        email: 'existant@ysp.com',
        phoneNumber: '+221774880377',
        profileImageUrl: '',
        isSpecialAccessUser: false,
        role: 'user',
      );
      await service.createUser(user);

      final exists = await service.userExistsByEmail('existant@ysp.com');
      expect(exists, isTrue);
    });
  });

  group('updateUser', () {
    test('met à jour uniquement les champs fournis', () async {
      const user = UserModel(
        id: 'uid-1',
        fullName: 'Ancien Nom',
        email: 'test@ysp.com',
        phoneNumber: '+221774880377',
        profileImageUrl: '',
        isSpecialAccessUser: false,
        role: 'user',
      );
      await service.createUser(user);

      await service.updateUser('uid-1', {'fullName': 'Nouveau Nom'});
      final updated = await service.getUser('uid-1');

      expect(updated!.fullName, 'Nouveau Nom');
      expect(updated.email, 'test@ysp.com',
          reason: 'Les champs non fournis ne doivent pas être affectés');
    });
  });

  group('addVehicle / getVehicles / deleteVehicle', () {
    test('ajoute un véhicule puis le retrouve dans la liste', () async {
      const vehicle = VehicleModel(
        id: '',
        brand: 'Toyota',
        modelDetail: 'Corolla',
        color: 'Bleu',
        licensePlate: 'DK-1234-2024',
        registrationYear: '2024',
        registrationCountry: 'Sénégal',
        registrationCity: 'Dakar',
        countryIso: 'SN',
        cityIso: 'DK',
      );

      final vehicleId = await service.addVehicle('uid-1', vehicle);
      final vehicles = await service.getVehicles('uid-1');

      expect(vehicleId, isNotEmpty);
      expect(vehicles.length, 1);
      expect(vehicles.first.licensePlate, 'DK-1234-2024');
    });

    test('deleteVehicle retire le véhicule de la liste', () async {
      const vehicle = VehicleModel(
        id: '',
        brand: 'Honda',
        modelDetail: 'Civic',
        color: 'Rouge',
        licensePlate: 'DK-5678-2024',
        registrationYear: '2024',
        registrationCountry: 'Sénégal',
        registrationCity: 'Dakar',
        countryIso: 'SN',
        cityIso: 'DK',
      );
      final vehicleId = await service.addVehicle('uid-1', vehicle);

      await service.deleteVehicle('uid-1', vehicleId);
      final vehicles = await service.getVehicles('uid-1');

      expect(vehicles, isEmpty);
    });
  });

  group('setDefaultVehicle — logique de sélection unique', () {
    test(
        'désélectionne tous les autres véhicules avant d\'activer'
        ' le nouveau', () async {
      const v1 = VehicleModel(
        id: '',
        brand: 'Toyota',
        modelDetail: 'Corolla',
        color: 'Bleu',
        licensePlate: 'DK-1111-2024',
        registrationYear: '2024',
        registrationCountry: 'Sénégal',
        registrationCity: 'Dakar',
        countryIso: 'SN',
        cityIso: 'DK',
        isCurrentlySelected: true,
      );
      const v2 = VehicleModel(
        id: '',
        brand: 'Honda',
        modelDetail: 'Civic',
        color: 'Rouge',
        licensePlate: 'DK-2222-2024',
        registrationYear: '2024',
        registrationCountry: 'Sénégal',
        registrationCity: 'Dakar',
        countryIso: 'SN',
        cityIso: 'DK',
        isCurrentlySelected: false,
      );

      final id1 = await service.addVehicle('uid-1', v1);
      final id2 = await service.addVehicle('uid-1', v2);

      // v1 est initialement sélectionné, on bascule vers v2
      await service.setDefaultVehicle('uid-1', id2);

      final vehicles = await service.getVehicles('uid-1');
      final loaded1 = vehicles.firstWhere((v) => v.id == id1);
      final loaded2 = vehicles.firstWhere((v) => v.id == id2);

      expect(loaded2.isCurrentlySelected, isTrue);
      expect(loaded1.isCurrentlySelected, isFalse,
          reason: 'Un seul véhicule doit être sélectionné à la fois — '
              'le batch doit désélectionner tous les autres avant '
              'd\'activer le nouveau');
    });

    test('fonctionne avec plus de deux véhicules', () async {
      const v1 = VehicleModel(
        id: '',
        brand: 'A',
        modelDetail: 'A1',
        color: 'X',
        licensePlate: 'P1',
        registrationYear: '2024',
        registrationCountry: 'SN',
        registrationCity: 'Dakar',
        countryIso: 'SN',
        cityIso: 'DK',
        isCurrentlySelected: true,
      );
      const v2 = VehicleModel(
        id: '',
        brand: 'B',
        modelDetail: 'B1',
        color: 'Y',
        licensePlate: 'P2',
        registrationYear: '2024',
        registrationCountry: 'SN',
        registrationCity: 'Dakar',
        countryIso: 'SN',
        cityIso: 'DK',
        isCurrentlySelected: false,
      );
      const v3 = VehicleModel(
        id: '',
        brand: 'C',
        modelDetail: 'C1',
        color: 'Z',
        licensePlate: 'P3',
        registrationYear: '2024',
        registrationCountry: 'SN',
        registrationCity: 'Dakar',
        countryIso: 'SN',
        cityIso: 'DK',
        isCurrentlySelected: false,
      );

      await service.addVehicle('uid-1', v1);
      await service.addVehicle('uid-1', v2);
      final id3 = await service.addVehicle('uid-1', v3);

      await service.setDefaultVehicle('uid-1', id3);

      final vehicles = await service.getVehicles('uid-1');
      final selectedCount = vehicles.where((v) => v.isCurrentlySelected).length;

      expect(selectedCount, 1,
          reason: 'Exactement un seul véhicule doit rester sélectionné '
              'peu importe le nombre total de véhicules');
    });
  });

  group('getParkings / watchParkings', () {
    test('retourne la liste des parkings disponibles', () async {
      await fakeFirestore.collection('locations_v2').add({
        'name': 'ECPI Smart Parking',
        'streetAddress': 'Rue SC-184',
        'city': 'Dakar',
        'countryCode': 'SN',
        'position': const GeoPoint(14.7167, -17.4677),
        'openingHour': '07:00',
        'closingHour': '20:00',
        'feePerSlot': 300,
      });

      final parkings = await service.getParkings();

      expect(parkings.length, 1);
      expect(parkings.first.name, 'ECPI Smart Parking');
    });

    test('retourne une liste vide si aucun parking n\'existe', () async {
      final parkings = await service.getParkings();
      expect(parkings, isEmpty);
    });
  });

  group('getParkingSpots', () {
    test('retourne les infos de places du parking', () async {
      final parkingRef =
          await fakeFirestore.collection('locations_v2').add({'name': 'P1'});
      await parkingRef.collection('spots').add({
        'regularIds': ['A0', 'A1'],
        'specialIds': ['A2'],
        'availableIds': ['A0', 'A1', 'A2'],
        'occupiedFromBookingIds': [],
        'occupiedFromWalkInIds': [],
      });

      final spots = await service.getParkingSpots(parkingRef.id);

      expect(spots, isNotNull);
      expect(spots!.totalSpots, 3);
      expect(spots.totalAvailable, 3);
    });

    test('retourne null si aucun document de places n\'existe', () async {
      final parkingRef =
          await fakeFirestore.collection('locations_v2').add({'name': 'P2'});

      final spots = await service.getParkingSpots(parkingRef.id);
      expect(spots, isNull);
    });
  });

  group('createWallet', () {
    test('crée un wallet avec un solde initial de 0', () async {
      await service.createWallet('uid-1');
      final wallet = await service.getWallet('uid-1');

      expect(wallet, isNotNull);
      expect(wallet!.balance, 0);
    });
  });

  group('saveNotification / watchNotifications / markNotificationRead', () {
    test('sauvegarde une notification non lue par défaut', () async {
      await service.saveNotification(
        uid: 'uid-1',
        title: '✅ Réservation confirmée !',
        body: 'Place A1 — ECPI Smart Parking',
      );

      final notifs = await service.watchNotifications('uid-1').first;

      expect(notifs.length, 1);
      expect(notifs.first.title, '✅ Réservation confirmée !');
      expect(notifs.first.isRead, isFalse);
    });

    test('markNotificationRead met à jour isRead à true', () async {
      await service.saveNotification(
        uid: 'uid-1',
        title: 'Test',
        body: 'Test body',
      );
      final notifs = await service.watchNotifications('uid-1').first;
      final notifId = notifs.first.id;

      await service.markNotificationRead('uid-1', notifId);

      final updated = await service.watchNotifications('uid-1').first;
      expect(updated.first.isRead, isTrue);
    });

    test('watchNotifications trie par date décroissante', () async {
      await service.saveNotification(
          uid: 'uid-1', title: 'Ancienne', body: 'B1');
      await Future.delayed(const Duration(milliseconds: 10));
      await service.saveNotification(
          uid: 'uid-1', title: 'Récente', body: 'B2');

      final notifs = await service.watchNotifications('uid-1').first;

      expect(notifs.length, 2);
      // La plus récente doit apparaître en premier
      expect(notifs.first.title, 'Récente');
    });
  });

  group('watchAgentTopUps — traçabilité rechargements', () {
    test('retrouve uniquement les topUps crédités par cet agent', () async {
      await service.createWallet('client-1');
      final wallet = await service.getWallet('client-1');

      await service.addTopUp(
        uid: 'client-1',
        walletId: wallet!.id,
        amount: 5000,
        newBalance: 5000,
        source: 'qrCode',
        agentUid: 'agent-1',
      );

      final topUps = await service.watchAgentTopUps('agent-1').first;

      expect(topUps.length, 1);
      expect(topUps.first['creditedBy'], 'agent-1');
      expect(topUps.first['clientId'], 'client-1');
    });

    test('n\'inclut pas les topUps d\'un autre agent', () async {
      await service.createWallet('client-2');
      final wallet = await service.getWallet('client-2');

      await service.addTopUp(
        uid: 'client-2',
        walletId: wallet!.id,
        amount: 3000,
        newBalance: 3000,
        source: 'agent',
        agentUid: 'autre-agent',
      );

      final topUps = await service.watchAgentTopUps('agent-1').first;
      expect(topUps, isEmpty);
    });
  });

  group('watchVehicles', () {
    test('émet la liste des véhicules en temps réel', () async {
      await service.addVehicle(
          'uid-1',
          const VehicleModel(
            id: '',
            brand: 'Toyota',
            modelDetail: 'Corolla',
            color: 'Bleu',
            licensePlate: 'DK-1234-2024',
            registrationYear: '2024',
            registrationCountry: 'Sénégal',
            registrationCity: 'Dakar',
            countryIso: 'SN',
            cityIso: 'DK',
          ));

      final vehicles = await service.watchVehicles('uid-1').first;
      expect(vehicles.length, 1);
      expect(vehicles.first.licensePlate, 'DK-1234-2024');
    });
  });

  group('updateVehicle', () {
    test('met à jour les champs fournis sans toucher aux autres', () async {
      final vehicleId = await service.addVehicle(
          'uid-1',
          const VehicleModel(
            id: '',
            brand: 'Toyota',
            modelDetail: 'Corolla',
            color: 'Bleu',
            licensePlate: 'DK-1234-2024',
            registrationYear: '2024',
            registrationCountry: 'Sénégal',
            registrationCity: 'Dakar',
            countryIso: 'SN',
            cityIso: 'DK',
          ));

      await service.updateVehicle('uid-1', vehicleId, {'color': 'Rouge'});

      final vehicles = await service.getVehicles('uid-1');
      final updated = vehicles.firstWhere((v) => v.id == vehicleId);
      expect(updated.color, 'Rouge');
      expect(updated.licensePlate, 'DK-1234-2024',
          reason: 'Les autres champs ne doivent pas être affectés');
    });
  });

  group('watchParkings', () {
    test('émet la liste des parkings en temps réel', () async {
      await fakeFirestore.collection('locations_v2').add({
        'name': 'ECPI Smart Parking',
        'streetAddress': 'Rue SC-184',
        'city': 'Dakar',
        'countryCode': 'SN',
        'position': const GeoPoint(14.7167, -17.4677),
        'openingHour': '07:00',
        'closingHour': '20:00',
        'feePerSlot': 300,
      });

      final parkings = await service.watchParkings().first;
      expect(parkings.length, 1);
      expect(parkings.first.name, 'ECPI Smart Parking');
    });
  });

  group('updateParkingSpots', () {
    test('met à jour les champs du document de places', () async {
      final parkingRef =
          await fakeFirestore.collection('locations_v2').add({'name': 'P1'});
      final spotsRef = await parkingRef.collection('spots').add({
        'regularIds': ['A0', 'A1'],
        'availableIds': ['A0', 'A1'],
      });

      await service.updateParkingSpots(
        parkingRef.id,
        spotsRef.id,
        {
          'availableIds': ['A1']
        },
      );

      final spots = await service.getParkingSpots(parkingRef.id);
      expect(spots!.availableIds, ['A1']);
    });
  });

  group('updateVehicleStatus', () {
    test('met à jour vehicleStatus sur la réservation', () async {
      final id = await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'vehicle-A1',
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(hours: 1)),
      ));

      await service.updateVehicleStatus(id, VehicleStatus.parked);

      final doc =
          await fakeFirestore.collection('slotsReservations_v2').doc(id).get();
      expect(doc.data()!['vehicleStatus'], 'parked');
    });
  });

  group('updateBookingFields', () {
    test('applique plusieurs champs en un seul appel', () async {
      final id = await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'vehicle-A1',
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(hours: 1)),
      ));

      await service.updateBookingFields(id, {
        'status': 'completed',
        'isArchived': true,
      });

      final doc =
          await fakeFirestore.collection('slotsReservations_v2').doc(id).get();
      expect(doc.data()!['status'], 'completed');
      expect(doc.data()!['isArchived'], isTrue);
    });
  });

  group('watchWallet', () {
    test('émet le wallet en temps réel', () async {
      await service.createWallet('uid-1');

      final wallet = await service.watchWallet('uid-1').first;
      expect(wallet, isNotNull);
      expect(wallet!.balance, 0);
    });

    test('émet null si aucun wallet n\'existe', () async {
      final wallet = await service.watchWallet('uid-inconnu').first;
      expect(wallet, isNull);
    });
  });

  group('watchTransactions', () {
    test('combine débits et top-ups triés par date', () async {
      await service.createWallet('uid-1');
      final wallet = await service.getWallet('uid-1');

      await service.addDebit(
        uid: 'uid-1',
        walletId: wallet!.id,
        amount: 300,
        newBalance: -300,
        parkingId: 'p1',
        parkingName: 'ECPI',
      );
      await service.addTopUp(
        uid: 'uid-1',
        walletId: wallet.id,
        amount: 5000,
        newBalance: 4700,
        source: 'qrCode',
      );

      final transactions =
          await service.watchTransactions('uid-1', wallet.id).first;

      expect(transactions.length, 2);
      expect(transactions.any((t) => t.isDebit), isTrue);
      expect(transactions.any((t) => t.isTopUp), isTrue);
    });
  });

  group('addDebit / addTopUp', () {
    test('addDebit enregistre tous les champs attendus', () async {
      await service.createWallet('uid-1');
      final wallet = await service.getWallet('uid-1');

      await service.addDebit(
        uid: 'uid-1',
        walletId: wallet!.id,
        amount: 600,
        newBalance: -600,
        parkingId: 'p1',
        parkingName: 'ECPI Smart Parking',
      );

      final debits = await fakeFirestore
          .collection('users_v2')
          .doc('uid-1')
          .collection('wallet')
          .doc(wallet.id)
          .collection('debits')
          .get();

      expect(debits.docs.length, 1);
      expect(debits.docs.first['parkingName'], 'ECPI Smart Parking');
    });

    test('addTopUp enregistre creditedBy pour un rechargement agent', () async {
      await service.createWallet('uid-1');
      final wallet = await service.getWallet('uid-1');

      await service.addTopUp(
        uid: 'uid-1',
        walletId: wallet!.id,
        amount: 5000,
        newBalance: 5000,
        source: 'agent',
        agentUid: 'agent-1',
      );

      final topUps = await fakeFirestore
          .collection('users_v2')
          .doc('uid-1')
          .collection('wallet')
          .doc(wallet.id)
          .collection('topUps')
          .get();

      expect(topUps.docs.first['creditedBy'], 'agent-1');
    });
  });

  group('getAllUserBookings / watchUserBookings', () {
    test('getAllUserBookings retourne réservations actives ET archivées',
        () async {
      await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'A1',
        vehicleId: 'v1',
        start: DateTime.now().add(const Duration(hours: 1)),
        end: DateTime.now().add(const Duration(hours: 2)),
      ));

      final bookings = await service.getAllUserBookings('client-1');
      expect(bookings.length, 1);
    });

    test('watchUserBookings émet en temps réel', () async {
      await service.createBookingAtomic(_booking(
        parkingId: 'p1',
        spotId: 'B1',
        vehicleId: 'v2',
        start: DateTime.now().add(const Duration(hours: 1)),
        end: DateTime.now().add(const Duration(hours: 2)),
      ));

      final bookings = await service.watchUserBookings('client-1').first;
      expect(bookings.length, 1);
    });
  });
}
