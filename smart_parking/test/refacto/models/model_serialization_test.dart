import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/models/booking_model.dart';
import 'package:smart_parking/app/models/user_model.dart';
import 'package:smart_parking/app/models/vehicle_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_parking/app/models/notification_model.dart';
import 'package:smart_parking/app/models/parking_model.dart';
import 'package:smart_parking/app/models/wallet_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

/// Tests unitaires — toFirestore()
///
/// Contrairement à fromFirestore (testé via fake_cloud_firestore),
/// toFirestore() est une fonction pure qui construit juste une
/// Map&ltString, dynamic&rt — aucun accès réseau ni Firestore simulé
/// n'est nécessaire pour la valider.

void main() {
  group('BookingModel — toFirestore', () {
    test('inclut tous les champs essentiels', () {
      final now = DateTime.now();
      final booking = BookingModel(
        id: 'b1',
        clientId: 'client-1',
        parkingId: 'parking-1',
        spotId: 'A1',
        vehicleId: 'vehicle-1',
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
        totalCost: 600,
        status: BookingStatus.upcoming,
      );

      final map = booking.toFirestore();

      expect(map['clientId'], 'client-1');
      expect(map['parkingId'], 'parking-1');
      expect(map['spotId'], 'A1');
      expect(map['totalCost'], 600);
      expect(map['status'], 'upcoming');
    });

    test('ne contient jamais l\'id (géré par Firestore lui-même)', () {
      final now = DateTime.now();
      final booking = BookingModel(
        id: 'b1',
        clientId: 'client-1',
        parkingId: 'parking-1',
        spotId: 'A1',
        vehicleId: 'vehicle-1',
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
        totalCost: 600,
      );

      final map = booking.toFirestore();

      expect(map.containsKey('id'), isFalse,
          reason: 'L\'ID du document est géré par Firestore, pas stocké '
              'comme champ dans le document lui-même');
    });

    test('sérialise le status canceled correctement', () {
      final now = DateTime.now();
      final booking = BookingModel(
        id: 'b1',
        clientId: 'client-1',
        parkingId: 'parking-1',
        spotId: 'A1',
        vehicleId: 'vehicle-1',
        bookingStart: now,
        bookingEnd: now.add(const Duration(hours: 1)),
        totalCost: 600,
        status: BookingStatus.canceled,
      );

      final map = booking.toFirestore();
      expect(map['status'], 'canceled');
    });
  });

  group('UserModel — toFirestore', () {
    test('inclut le role pour le routing agent/user', () {
      const user = UserModel(
        id: 'u1',
        fullName: 'Anne Marie',
        email: 'test@ysp.com',
        phoneNumber: '+221774880377',
        profileImageUrl: '',
        isSpecialAccessUser: false,
        role: 'agent',
      );

      final map = user.toFirestore();
      expect(map['role'], 'agent');
    });

    test('n\'inclut pas le champ location si null (utilisateur normal)', () {
      const user = UserModel(
        id: 'u1',
        fullName: 'Anne Marie',
        email: 'test@ysp.com',
        phoneNumber: '+221774880377',
        profileImageUrl: '',
        isSpecialAccessUser: false,
        role: 'user',
        // location non fourni — reste null
      );

      final map = user.toFirestore();
      expect(map.containsKey('location'), isFalse,
          reason: 'Seuls les agents ont une location — le champ ne '
              'doit pas polluer le document d\'un user normal');
    });

    test('inclut le champ location si fourni (agent)', () {
      const user = UserModel(
        id: 'u1',
        fullName: 'Agent YSP',
        email: 'agent@ysp.com',
        phoneNumber: '+221774880377',
        profileImageUrl: '',
        isSpecialAccessUser: false,
        role: 'agent',
        location: 'Agence Dakar Centre',
      );

      final map = user.toFirestore();
      expect(map['location'], 'Agence Dakar Centre');
    });

    test('inclut equalityCardPaths pour la carte PMR', () {
      const user = UserModel(
        id: 'u1',
        fullName: 'Anne Marie',
        email: 'test@ysp.com',
        phoneNumber: '+221774880377',
        profileImageUrl: '',
        isSpecialAccessUser: true,
        role: 'user',
        equalityCardPaths: ['recto.jpg', 'verso.jpg'],
      );

      final map = user.toFirestore();
      expect(map['equalityCardPaths'], ['recto.jpg', 'verso.jpg']);
      expect(map['isSpecialAccessUser'], isTrue);
    });
  });

  group('VehicleModel — toFirestore', () {
    test('inclut la plaque et le véhicule sélectionné', () {
      const vehicle = VehicleModel(
        id: 'v1',
        brand: 'Toyota',
        modelDetail: 'Corolla',
        color: 'Bleu',
        licensePlate: 'DK-1234-2024',
        registrationYear: '2024',
        registrationCountry: 'Sénégal',
        registrationCity: 'Dakar',
        countryIso: 'SN',
        cityIso: 'DK',
        isCurrentlySelected: true,
      );

      final map = vehicle.toFirestore();
      expect(map['licensePlate'], 'DK-1234-2024');
      expect(map['isCurrentlySelected'], isTrue);
      expect(map['brand'], 'Toyota');
    });
  });

  group('WalletModel — toFirestore', () {
    test('sérialise uniquement le solde (balance)', () {
      const wallet = WalletModel(id: 'w1', balance: 5000);
      final map = wallet.toFirestore();

      expect(map, {'balance': 5000});
      expect(map.containsKey('id'), isFalse,
          reason: 'L\'ID du wallet est géré par Firestore (nom du document)');
    });
  });

  group('TransactionModel — toFirestore (débit)', () {
    test('inclut parkingId et parkingName pour un débit', () {
      final transaction = TransactionModel(
        id: 't1',
        type: TransactionType.debit,
        amount: 600,
        newBalance: 4400,
        timestamp: DateTime.now(),
        parkingId: 'p1',
        parkingName: 'ECPI Smart Parking',
      );

      final map = transaction.toFirestore();

      expect(map['amount'], 600);
      expect(map['newBalance'], 4400);
      expect(map['parkingId'], 'p1');
      expect(map['parkingName'], 'ECPI Smart Parking');
      expect(map.containsKey('source'), isFalse,
          reason: 'Un débit n\'a pas de champ source (réservé aux top-ups)');
    });
  });

  group('TransactionModel — toFirestore (top-up)', () {
    test('inclut la source mais pas parkingId/parkingName', () {
      final transaction = TransactionModel(
        id: 't2',
        type: TransactionType.topUp,
        amount: 5000,
        newBalance: 9400,
        timestamp: DateTime.now(),
        topUpSource: TopUpSource.qrCode,
      );

      final map = transaction.toFirestore();

      expect(map['source'], 'qrCode');
      expect(map.containsKey('parkingId'), isFalse);
    });

    test('utilise "agent" comme source par défaut si non précisée', () {
      final transaction = TransactionModel(
        id: 't3',
        type: TransactionType.topUp,
        amount: 1000,
        newBalance: 1000,
        timestamp: DateTime.now(),
      );

      final map = transaction.toFirestore();
      expect(map['source'], 'agent');
    });
  });

  group('TransactionModel — toString', () {
    test('inclut le type et le montant', () {
      final transaction = TransactionModel(
        id: 't1',
        type: TransactionType.debit,
        amount: 600,
        newBalance: 4400,
        timestamp: DateTime.now(),
      );

      expect(transaction.toString(), contains('debit'));
      expect(transaction.toString(), contains('600'));
    });
  });

  group('ParkingModel — toFirestore', () {
    test('sérialise tous les champs y compris le GeoPoint', () {
      const parking = ParkingModel(
        id: 'p1',
        name: 'ECPI Smart Parking',
        streetAddress: 'Rue SC-184',
        city: 'Dakar',
        countryCode: 'SN',
        position: GeoPoint(14.7167, -17.4677),
        openingHour: '07:00',
        closingHour: '20:00',
        feePerSlot: 300,
      );

      final map = parking.toFirestore();

      expect(map['name'], 'ECPI Smart Parking');
      expect(map['position'], const GeoPoint(14.7167, -17.4677));
      expect(map['feePerSlot'], 300);
      expect(map.containsKey('id'), isFalse);
    });
  });

  group('ParkingSpotsInfo — toFirestore', () {
    test('sérialise toutes les listes de places', () {
      const spots = ParkingSpotsInfo(
        id: 'spots-1',
        regularIds: ['A0', 'A1'],
        specialIds: ['A2'],
        availableIds: ['A1'],
        occupiedFromBookingIds: ['A0'],
        occupiedFromWalkInIds: [],
      );

      final map = spots.toFirestore();

      expect(map['regularIds'], ['A0', 'A1']);
      expect(map['specialIds'], ['A2']);
      expect(map['availableIds'], ['A1']);
      expect(map['occupiedFromBookingIds'], ['A0']);
      expect(map['occupiedFromWalkInIds'], isEmpty);
    });
  });

  group('ParkingModel — toString', () {
    test('inclut id et name', () {
      const parking = ParkingModel(
        id: 'p1',
        name: 'ECPI Smart Parking',
        streetAddress: '',
        city: '',
        countryCode: 'SN',
        position: GeoPoint(0, 0),
        openingHour: '07:00',
        closingHour: '20:00',
        feePerSlot: 300,
      );

      expect(parking.toString(), contains('p1'));
      expect(parking.toString(), contains('ECPI Smart Parking'));
    });
  });

  group('NotificationModel — toFirestore', () {
    test('sérialise title, body et isRead', () {
      final notif = NotificationModel(
        id: 'n1',
        title: '✅ Réservation confirmée !',
        body: 'Place A1',
        isRead: false,
        receivedAt: DateTime.now(),
      );

      final map = notif.toFirestore();

      expect(map['title'], '✅ Réservation confirmée !');
      expect(map['body'], 'Place A1');
      expect(map['isRead'], isFalse);
    });

    test('sérialise isRead=true après lecture', () {
      final notif = NotificationModel(
        id: 'n1',
        title: 'Test',
        body: 'Test body',
        isRead: true,
        receivedAt: DateTime.now(),
      );

      final map = notif.toFirestore();
      expect(map['isRead'], isTrue);
    });
  });

  // ── fromFirestore (nécessite fake_cloud_firestore) ──────

  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  group('BookingModel.fromFirestore', () {
    test('parse un document complet correctement', () async {
      final ref = firestore.collection('bookings').doc('b1');
      await ref.set({
        'clientId': 'client-1',
        'parkingId': 'parking-1',
        'spotId': 'A1',
        'vehicleId': 'vehicle-1',
        'bookingStart': Timestamp.fromDate(DateTime(2026, 7, 16, 14, 0)),
        'bookingEnd': Timestamp.fromDate(DateTime(2026, 7, 16, 16, 0)),
        'totalCost': 1200,
        'status': 'upcoming',
        'vehicleStatus': 'notYetParked',
        'isArchived': false,
      });

      final snap = await ref.get();
      final booking = BookingModel.fromFirestore(snap);

      expect(booking.id, 'b1');
      expect(booking.clientId, 'client-1');
      expect(booking.spotId, 'A1');
      expect(booking.totalCost, 1200);
      expect(booking.status, BookingStatus.upcoming);
      expect(booking.durationMinutes, 120);
    });

    test(
        'applique des valeurs par défaut sûres pour un document'
        ' incomplet', () async {
      final ref = firestore.collection('bookings').doc('b2');
      await ref.set({'clientId': 'client-1'}); // document minimal

      final snap = await ref.get();
      final booking = BookingModel.fromFirestore(snap);

      expect(booking.spotId, '');
      expect(booking.totalCost, 0);
      expect(booking.status, BookingStatus.upcoming,
          reason: 'status manquant → upcoming par défaut');
      expect(booking.isArchived, isFalse);
    });

    test('parse editHistory correctement depuis un tableau', () async {
      final ref = firestore.collection('bookings').doc('b3');
      await ref.set({
        'clientId': 'client-1',
        'parkingId': 'p1',
        'spotId': 'A1',
        'vehicleId': 'v1',
        'bookingStart': Timestamp.now(),
        'bookingEnd': Timestamp.now(),
        'totalCost': 600,
        'editHistory': [
          {
            'editedAt': Timestamp.now(),
            'field': 'spotId',
            'oldValue': 'A1',
            'newValue': 'A2',
          }
        ],
      });

      final snap = await ref.get();
      final booking = BookingModel.fromFirestore(snap);

      expect(booking.wasEdited, isTrue);
      expect(booking.editHistory.first.field, 'spotId');
    });
  });

  group('WalletModel.fromFirestore', () {
    test('parse le solde correctement', () async {
      final ref = firestore.collection('wallets').doc('w1');
      await ref.set({'balance': 15000});

      final snap = await ref.get();
      final wallet = WalletModel.fromFirestore(snap);

      expect(wallet.id, 'w1');
      expect(wallet.balance, 15000);
    });

    test('balance par défaut à 0 si absente', () async {
      final ref = firestore.collection('wallets').doc('w2');
      await ref.set({});

      final snap = await ref.get();
      final wallet = WalletModel.fromFirestore(snap);

      expect(wallet.balance, 0);
    });
  });

  group('TransactionModel — debitFromFirestore / topUpFromFirestore', () {
    test('parse un débit correctement', () async {
      final ref = firestore.collection('debits').doc('d1');
      await ref.set({
        'amount': 600,
        'newBalance': 4400,
        'parkingId': 'p1',
        'parkingName': 'ECPI Smart Parking',
        'timestamp': Timestamp.now(),
      });

      final snap = await ref.get();
      final transaction = TransactionModel.debitFromFirestore(snap);

      expect(transaction.isDebit, isTrue);
      expect(transaction.amount, 600);
      expect(transaction.parkingName, 'ECPI Smart Parking');
    });

    test('parse un top-up avec source qrCode', () async {
      final ref = firestore.collection('topUps').doc('t1');
      await ref.set({
        'amount': 5000,
        'newBalance': 9400,
        'source': 'qrCode',
        'creditedBy': 'agent-uid-1',
        'timestamp': Timestamp.now(),
      });

      final snap = await ref.get();
      final transaction = TransactionModel.topUpFromFirestore(snap);

      expect(transaction.isTopUp, isTrue);
      expect(transaction.topUpSource, TopUpSource.qrCode);
      expect(transaction.agentId, 'agent-uid-1');
    });

    test('source inconnue retombe sur agent par défaut', () async {
      final ref = firestore.collection('topUps').doc('t2');
      await ref.set({
        'amount': 1000,
        'newBalance': 1000,
        'source': 'valeur_invalide',
      });

      final snap = await ref.get();
      final transaction = TransactionModel.topUpFromFirestore(snap);

      expect(transaction.topUpSource, TopUpSource.agent);
    });

    test('parse la source "online" correctement', () async {
      final ref = firestore.collection('topUps').doc('t3');
      await ref.set({
        'amount': 3000,
        'newBalance': 8000,
        'source': 'online',
      });

      final snap = await ref.get();
      final transaction = TransactionModel.topUpFromFirestore(snap);

      expect(transaction.topUpSource, TopUpSource.online);
    });
  });

  group('UserModel.fromFirestore', () {
    test('parse un profil complet avec carte PMR', () async {
      final ref = firestore.collection('users').doc('u1');
      await ref.set({
        'fullName': 'Anne Marie Diallo',
        'email': 'test@ysp.com',
        'phoneNumber': '+221774880377',
        'role': 'user',
        'isSpecialAccessUser': true,
        'equalityCardPaths': ['recto.jpg', 'verso.jpg'],
      });

      final snap = await ref.get();
      final user = UserModel.fromFirestore(snap);

      expect(user.fullName, 'Anne Marie Diallo');
      expect(user.isSpecialAccessUser, isTrue);
      expect(user.equalityCardPaths.length, 2);
      expect(user.initials, 'AM');
    });

    test('parse createdAt depuis un Timestamp', () async {
      final ref = firestore.collection('users').doc('u1b');
      final createdDate = DateTime(2026, 1, 15, 10, 30);
      await ref.set({
        'fullName': 'Test',
        'createdAt': Timestamp.fromDate(createdDate),
      });

      final snap = await ref.get();
      final user = UserModel.fromFirestore(snap);

      expect(user.createdAt, createdDate);
    });

    test('createdAt reste null si absent du document', () async {
      final ref = firestore.collection('users').doc('u1c');
      await ref.set({'fullName': 'Test'});

      final snap = await ref.get();
      final user = UserModel.fromFirestore(snap);

      expect(user.createdAt, isNull);
    });

    test('role par défaut "user" si absent', () async {
      final ref = firestore.collection('users').doc('u2');
      await ref.set({'fullName': 'Test'});

      final snap = await ref.get();
      final user = UserModel.fromFirestore(snap);

      expect(user.role, 'user');
    });

    test('parse un agent avec location', () async {
      final ref = firestore.collection('users').doc('agent1');
      await ref.set({
        'fullName': 'Agent YSP Dakar',
        'role': 'agent',
        'location': 'Agence Dakar Centre',
      });

      final snap = await ref.get();
      final user = UserModel.fromFirestore(snap);

      expect(user.role, 'agent');
      expect(user.location, 'Agence Dakar Centre');
    });
  });

  group('VehicleModel.fromFirestore', () {
    test('parse un véhicule complet', () async {
      final ref = firestore.collection('vehicles').doc('v1');
      await ref.set({
        'brand': 'Toyota',
        'modelDetail': 'Corolla',
        'licensePlate': 'DK-1234-2024',
        'isCurrentlySelected': true,
        'totalBookings': 5,
        'totalParkingHours': 12.5,
      });

      final snap = await ref.get();
      final vehicle = VehicleModel.fromFirestore(snap);

      expect(vehicle.fullName, 'Toyota Corolla');
      expect(vehicle.isCurrentlySelected, isTrue);
      expect(vehicle.totalBookings, 5);
      expect(vehicle.totalParkingHours, 12.5);
    });

    test('parse totalParkingHours stocké comme int (pas double)', () async {
      final ref = firestore.collection('vehicles').doc('v1b');
      await ref.set({
        'brand': 'Toyota',
        'totalParkingHours': 10, // int, pas double
      });

      final snap = await ref.get();
      final vehicle = VehicleModel.fromFirestore(snap);

      expect(vehicle.totalParkingHours, 10.0);
    });

    test('parse addedAt depuis un Timestamp', () async {
      final ref = firestore.collection('vehicles').doc('v1c');
      final addedDate = DateTime(2026, 3, 1);
      await ref.set({
        'brand': 'Toyota',
        'addedAt': Timestamp.fromDate(addedDate),
      });

      final snap = await ref.get();
      final vehicle = VehicleModel.fromFirestore(snap);

      expect(vehicle.addedAt, addedDate);
    });

    test('conserve un type personnalisé (ex: Moto)', () async {
      final ref = firestore.collection('vehicles').doc('v1d');
      await ref.set({'brand': 'Yamaha', 'type': 'Moto'});

      final snap = await ref.get();
      final vehicle = VehicleModel.fromFirestore(snap);

      expect(vehicle.type, 'Moto');
    });

    test('type par défaut "Car" si absent', () async {
      final ref = firestore.collection('vehicles').doc('v2');
      await ref.set({'brand': 'Honda'});

      final snap = await ref.get();
      final vehicle = VehicleModel.fromFirestore(snap);

      expect(vehicle.type, 'Car');
    });
  });

  group('ParkingModel.fromFirestore', () {
    test('parse un parking complet avec GeoPoint', () async {
      final ref = firestore.collection('parkings').doc('p1');
      await ref.set({
        'name': 'ECPI Smart Parking',
        'streetAddress': 'Rue SC-184',
        'city': 'Dakar',
        'position': const GeoPoint(14.7167, -17.4677),
        'openingHour': '07:00',
        'closingHour': '20:00',
        'feePerSlot': 300,
      });

      final snap = await ref.get();
      final parking = ParkingModel.fromFirestore(snap);

      expect(parking.name, 'ECPI Smart Parking');
      expect(parking.latitude, 14.7167);
      expect(parking.fullAddress, 'Rue SC-184, Dakar');
      expect(parking.hours, '07:00 - 20:00');
    });

    test('horaires par défaut si absents', () async {
      final ref = firestore.collection('parkings').doc('p2');
      await ref.set({'name': 'Test'});

      final snap = await ref.get();
      final parking = ParkingModel.fromFirestore(snap);

      expect(parking.openingHour, '00:00');
      expect(parking.closingHour, '23:59');
    });
  });

  group('ParkingSpotsInfo.fromFirestore', () {
    test('parse les listes de places correctement', () async {
      final ref = firestore.collection('spots').doc('s1');
      await ref.set({
        'regularIds': ['A0', 'A1', 'B0'],
        'specialIds': ['A2'],
        'availableIds': ['A1', 'B0'],
        'occupiedFromBookingIds': ['A0'],
        'occupiedFromWalkInIds': [],
      });

      final snap = await ref.get();
      final spots = ParkingSpotsInfo.fromFirestore(snap);

      expect(spots.totalSpots, 4);
      expect(spots.totalAvailable, 2);
      expect(spots.allIds, ['A0', 'A1', 'B0', 'A2']);
    });
  });

  group('NotificationModel.fromFirestore', () {
    test('parse une notification correctement', () async {
      final ref = firestore.collection('notifications').doc('n1');
      await ref.set({
        'title': '✅ Réservation confirmée !',
        'body': 'Place A1 — ECPI Smart Parking',
        'isRead': false,
        'receivedAt': Timestamp.now(),
      });

      final snap = await ref.get();
      final notif = NotificationModel.fromFirestore(snap);

      expect(notif.title, '✅ Réservation confirmée !');
      expect(notif.isRead, isFalse);
    });

    test('isRead par défaut à false si absent', () async {
      final ref = firestore.collection('notifications').doc('n2');
      await ref.set({'title': 'Test', 'body': 'Test body'});

      final snap = await ref.get();
      final notif = NotificationModel.fromFirestore(snap);

      expect(notif.isRead, isFalse);
    });
  });
}
