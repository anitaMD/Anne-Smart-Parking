import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:smart_parking/app/core/exceptions/booking_exceptions.dart';
import 'package:smart_parking/app/core/utils/booking_conflict_util.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../models/parking_model.dart';
import '../models/booking_model.dart';
import '../models/wallet_model.dart';
import '../models/notification_model.dart';

// ─────────────────────────────────────────────────────────────
// INTERFACE ABSTRAITE
// ─────────────────────────────────────────────────────────────

abstract class FirestoreServiceBase {
  // Users
  Future<void> createUser(UserModel user);
  Future<UserModel?> getUser(String uid);
  Future<bool> userExistsByPhone(String phoneNumber);
  Future<bool> userExistsByEmail(String email);
  Future<void> updateUser(String uid, Map<String, dynamic> fields);

  // Vehicles
  Future<List<VehicleModel>> getVehicles(String uid);
  Stream<List<VehicleModel>> watchVehicles(String uid);
  Future<String> addVehicle(String uid, VehicleModel vehicle);
  Future<void> updateVehicle(
      String uid, String vehicleId, Map<String, dynamic> fields);
  Future<void> deleteVehicle(String uid, String vehicleId);
  Future<void> setDefaultVehicle(String uid, String vehicleId);

  // Parkings
  Future<List<ParkingModel>> getParkings();
  Stream<List<ParkingModel>> watchParkings();
  Future<ParkingSpotsInfo?> getParkingSpots(String parkingId);
  Stream<ParkingSpotsInfo?> watchParkingSpots(String parkingId);
  Future<void> updateParkingSpots(
      String parkingId, String spotsDocId, Map<String, dynamic> fields);
  Future<Set<String>> getOccupiedSpotIds({
    required String parkingId,
    required DateTime bookingStart,
    required DateTime bookingEnd,
  });
  Stream<Set<String>> watchOccupiedSpotIds({
    required String parkingId,
    required DateTime bookingStart,
    required DateTime bookingEnd,
  });

  // Bookings
  Future<String> createBookingAtomic(BookingModel booking);
  Future<List<BookingModel>> getUserUnarchivedBookings(String uid);
  Future<List<BookingModel>> getUserArchivedBookings(String uid);
  Stream<List<BookingModel>> watchUserUnarchivedBookings(String uid);
  Stream<List<BookingModel>> watchUserArchivedBookings(String uid);
  Future<List<BookingModel>> getAllUserBookings(String uid);
  Stream<List<BookingModel>> watchUserBookings(String uid);
  Future<void> updateBookingStatus(String bookingId, BookingStatus status);
  Future<void> archiveBooking(String bookingId);
  Future<void> updateVehicleStatus(String bookingId, VehicleStatus status);
  Future<void> updateBookingFields(
      String bookingId, Map<String, dynamic> fields);

  // Wallet
  Future<WalletModel?> getWallet(String uid);
  Stream<WalletModel?> watchWallet(String uid);

  Stream<bool?> watchSensorStatus(String parkingId, String spotId);
  Stream<List<TransactionModel>> watchTransactions(String uid, String walletId);
  Future<void> createWallet(String uid);
  Future<void> updateWalletBalance(String uid, String walletId, int newBalance);
  Future<void> addDebit(
      {required String uid,
      required String walletId,
      required int amount,
      required int newBalance,
      required String parkingId,
      required String parkingName});
  Future<void> addTopUp(
      {required String uid,
      required String walletId,
      required int amount,
      required int newBalance,
      required String source,
      String? agentUid});

  // Agent
  Stream<List<Map<String, dynamic>>> watchAgentTopUps(String agentUid);

  // Notifications
  Future<void> saveNotification(
      {required String uid, required String title, required String body});
  Stream<List<NotificationModel>> watchNotifications(String uid);
  Future<void> markNotificationRead(String uid, String notifId);
}

// ─────────────────────────────────────────────────────────────
// IMPLÉMENTATION RÉELLE
// ─────────────────────────────────────────────────────────────

class FirestoreService implements FirestoreServiceBase {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users_v2');
  CollectionReference<Map<String, dynamic>> get _locations =>
      _db.collection('locations_v2');
  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('slotsReservations_v2');

  // ── Requête centralisée — réservations "actives" ─────────────
  //
  // isArchived==false est LE filtre définitif pour "cette réservation
  // compte-t-elle encore" (couvre canceled ET completed, peu importe
  // la raison — départ anticipé volontaire ou clôture normale). Une
  // réservation archivée ne doit JAMAIS bloquer une place ou un
  // véhicule, peu importe son bookingEnd original.
  //
  // Centralise ce qui était dupliqué (avec des bugs d'incohérence
  // entre les copies) dans createBookingAtomic, getOccupiedSpotIds
  // et watchOccupiedSpotIds.
  Query<Map<String, dynamic>> _activeBookingsQuery({
    String? parkingId,
    String? spotId,
    String? vehicleId,
    DateTime? startBefore,
  }) {
    Query<Map<String, dynamic>> query =
        _bookings.where('isArchived', isEqualTo: false);

    if (parkingId != null) {
      query = query.where('parkingId', isEqualTo: parkingId);
    }
    if (spotId != null) {
      query = query.where('spotId', isEqualTo: spotId);
    }
    if (vehicleId != null) {
      query = query.where('vehicleId', isEqualTo: vehicleId);
    }
    if (startBefore != null) {
      query = query.where('bookingStart',
          isLessThan: Timestamp.fromDate(startBefore));
    }
    return query;
  }

  // ── Users ─────────────────────────────────────────────────
  @override
  Future<void> createUser(UserModel user) async =>
      await _users.doc(user.id).set(user.toFirestore());

  @override
  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  @override
  Future<bool> userExistsByPhone(String phoneNumber) async {
    final snapshot = await _users
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<bool> userExistsByEmail(String email) async {
    final snapshot =
        await _users.where('email', isEqualTo: email.trim()).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async =>
      await _users.doc(uid).update(fields);

  // ── Vehicles ──────────────────────────────────────────────
  @override
  Future<List<VehicleModel>> getVehicles(String uid) async {
    final snapshot = await _users.doc(uid).collection('vehicles').get();
    return snapshot.docs.map(VehicleModel.fromFirestore).toList();
  }

  @override
  Stream<List<VehicleModel>> watchVehicles(String uid) {
    return _users.doc(uid).collection('vehicles').snapshots().map(
        (snap) => snap.docs.map((d) => VehicleModel.fromFirestore(d)).toList());
  }

  @override
  Future<String> addVehicle(String uid, VehicleModel vehicle) async {
    final ref =
        await _users.doc(uid).collection('vehicles').add(vehicle.toFirestore());
    return ref.id;
  }

  @override
  Future<void> updateVehicle(
          String uid, String vehicleId, Map<String, dynamic> fields) async =>
      await _users
          .doc(uid)
          .collection('vehicles')
          .doc(vehicleId)
          .update(fields);

  @override
  Future<void> deleteVehicle(String uid, String vehicleId) async =>
      await _users.doc(uid).collection('vehicles').doc(vehicleId).delete();

  @override
  Future<void> setDefaultVehicle(String uid, String vehicleId) async {
    final batch = _db.batch();
    final all = await _users.doc(uid).collection('vehicles').get();
    for (final doc in all.docs) {
      batch.update(doc.reference, {'isCurrentlySelected': false});
    }
    batch.update(
      _users.doc(uid).collection('vehicles').doc(vehicleId),
      {'isCurrentlySelected': true},
    );
    await batch.commit();
  }

  // ── Parkings ──────────────────────────────────────────────
  @override
  Future<List<ParkingModel>> getParkings() async {
    final snapshot = await _locations.get();
    return snapshot.docs.map(ParkingModel.fromFirestore).toList();
  }

  @override
  Stream<List<ParkingModel>> watchParkings() => _locations
      .snapshots()
      .map((s) => s.docs.map(ParkingModel.fromFirestore).toList());

  @override
  Future<ParkingSpotsInfo?> getParkingSpots(String parkingId) async {
    final snapshot =
        await _locations.doc(parkingId).collection('spots').limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return ParkingSpotsInfo.fromFirestore(snapshot.docs.first);
  }

  @override
  Stream<ParkingSpotsInfo?> watchParkingSpots(String parkingId) => _locations
      .doc(parkingId)
      .collection('spots')
      .limit(1)
      .snapshots()
      .map((s) =>
          s.docs.isEmpty ? null : ParkingSpotsInfo.fromFirestore(s.docs.first));

  @override
  Future<void> updateParkingSpots(String parkingId, String spotsDocId,
          Map<String, dynamic> fields) async =>
      await _locations
          .doc(parkingId)
          .collection('spots')
          .doc(spotsDocId)
          .update(fields);

  @override
  Future<Set<String>> getOccupiedSpotIds({
    required String parkingId,
    required DateTime bookingStart,
    required DateTime bookingEnd,
  }) async {
    final snap = await _activeBookingsQuery(
      parkingId: parkingId,
      startBefore: bookingEnd,
    ).get();

    // Chevauchement — réutilise la même logique testée que pour les
    // conflits de création (une seule source de vérité).
    return snap.docs
        .where((doc) {
          final data = doc.data();
          final start = (data['bookingStart'] as Timestamp).toDate();
          final end = (data['bookingEnd'] as Timestamp).toDate();
          return doTimeSlotsOverlap(
            aStart: start,
            aEnd: end,
            bStart: bookingStart,
            bEnd: bookingEnd,
          );
        })
        .map((doc) => (doc.data())['spotId'] as String)
        .toSet();
  }

  @override
  Stream<Set<String>> watchOccupiedSpotIds({
    required String parkingId,
    required DateTime bookingStart,
    required DateTime bookingEnd,
  }) {
    return _activeBookingsQuery(
      parkingId: parkingId,
      startBefore: bookingEnd,
    ).snapshots().map((snap) => snap.docs
        .where((doc) {
          final data = doc.data();
          final start = (data['bookingStart'] as Timestamp).toDate();
          final end = (data['bookingEnd'] as Timestamp).toDate();
          return doTimeSlotsOverlap(
            aStart: start,
            aEnd: end,
            bStart: bookingStart,
            bEnd: bookingEnd,
          );
        })
        .map((doc) => (doc.data())['spotId'] as String)
        .toSet());
  }
  // ── Bookings ──────────────────────────────────────────────

  @override
  Future<String> createBookingAtomic(BookingModel booking) async {
    String bookingId = '';
    final now = DateTime.now();

    await _db.runTransaction((transaction) async {
      // 1. Vérifier absence de conflit liés aux places
      //
      // isArchived == false est LE filtre définitif — couvre à la
      // fois les réservations annulées (canceled) ET terminées
      // (completed, que ce soit un départ anticipé volontaire via
      // "Terminer maintenant" ou une clôture normale au capteur).
      // Une réservation archivée ne bloque jamais un nouveau créneau,
      // peu importe son bookingEnd original.
      final snap = await _activeBookingsQuery(
        parkingId: booking.parkingId,
        spotId: booking.spotId,
        startBefore: booking.bookingEnd,
      ).get();

      final conflict = snap.docs.any((doc) {
        final data = doc.data();
        final docStart = (data['bookingStart'] as Timestamp).toDate();
        final docEnd = (data['bookingEnd'] as Timestamp).toDate();
        return doTimeSlotsOverlap(
          aStart: docStart,
          aEnd: docEnd,
          bStart: booking.bookingStart,
          bEnd: booking.bookingEnd,
        );
      });

      if (conflict) {
        throw const SpotConflictException();
      }

      // 1bis. Vérifier qu'aucun véhicule en DÉPASSEMENT ACTIF (donc
      // physiquement toujours présent) n'occupe déjà cette place au
      // moment où la nouvelle réservation souhaite démarrer.
      //
      // Limitation connue : ne protège que contre un dépassement
      // DÉJÀ en cours au moment de cette création — pas contre un
      // dépassement qui surviendrait plus tard sur une réservation
      // future déjà validée sans conflit (voir booking_exceptions.dart
      // pour la note complète).
      if (!booking.bookingStart.isAfter(now)) {
        final overstaySnap = await _activeBookingsQuery(
          parkingId: booking.parkingId,
          spotId: booking.spotId,
        ).get();

        final activeOverstay = overstaySnap.docs.any((doc) {
          final data = doc.data();
          final end = (data['bookingEnd'] as Timestamp).toDate();
          final departed = data['vehicleDepartedAt'] as Timestamp?;
          return end.isBefore(now) && departed == null;
        });

        if (activeOverstay) {
          throw const SpotOverstayConflictException();
        }
      }

      // 2. Vérifier conflit de VÉHICULE (même véhicule, n'importe quel parking)
      final vehicleSnap = await _activeBookingsQuery(
        vehicleId: booking.vehicleId,
        startBefore: booking.bookingEnd,
      ).get();

      final vehicleConflict = vehicleSnap.docs.any((doc) {
        final data = doc.data();
        final end = (data['bookingEnd'] as Timestamp).toDate();
        return end.isAfter(booking.bookingStart);
      });

      if (vehicleConflict) {
        throw const VehicleConflictException();
      }

      // 3. Créer atomiquement
      final ref = _bookings.doc();
      bookingId = ref.id;
      transaction.set(ref, booking.toFirestore());
    });

    return bookingId;
  }

  @override
  Future<List<BookingModel>> getUserUnarchivedBookings(String uid) async {
    final snapshot = await _bookings
        .where('clientId', isEqualTo: uid)
        .where('isArchived', isEqualTo: false)
        .orderBy('bookingStart')
        .get();
    return snapshot.docs.map(BookingModel.fromFirestore).toList();
  }

  @override
  Future<List<BookingModel>> getUserArchivedBookings(String uid) async {
    final snapshot = await _bookings
        .where('clientId', isEqualTo: uid)
        .where('isArchived', isEqualTo: true)
        .orderBy('createdAt')
        .get();
    return snapshot.docs.map(BookingModel.fromFirestore).toList();
  }

  // ── Versions "stream" — mises à jour en temps réel, notamment
  // pour refléter les écritures du script Raspberry Pi (arrivée,
  // dépassement, départ) sans nécessiter de rafraîchissement manuel
  // ni de redémarrage de l'app côté utilisateur. ────────────────

  @override
  Stream<List<BookingModel>> watchUserUnarchivedBookings(String uid) {
    return _bookings
        .where('clientId', isEqualTo: uid)
        .where('isArchived', isEqualTo: false)
        .orderBy('bookingStart')
        .snapshots()
        .map((snap) => snap.docs.map(BookingModel.fromFirestore).toList());
  }

  @override
  Stream<List<BookingModel>> watchUserArchivedBookings(String uid) {
    return _bookings
        .where('clientId', isEqualTo: uid)
        .where('isArchived', isEqualTo: true)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(BookingModel.fromFirestore).toList());
  }

  @override
  Future<List<BookingModel>> getAllUserBookings(String uid) async {
    final snapshot = await _bookings
        .where('clientId', isEqualTo: uid)
        .orderBy('createdAt')
        .get();
    return snapshot.docs.map(BookingModel.fromFirestore).toList();
  }

  @override
  Stream<List<BookingModel>> watchUserBookings(String uid) => _bookings
      .where('clientId', isEqualTo: uid)
      .where('isArchived', isEqualTo: false)
      .orderBy('bookingStart')
      .snapshots()
      .map((s) => s.docs.map(BookingModel.fromFirestore).toList());

  @override
  Future<void> updateBookingStatus(
          String bookingId, BookingStatus status) async =>
      await _bookings.doc(bookingId).update({'status': status.name});

  @override
  Future<void> archiveBooking(String bookingId) async =>
      await _bookings.doc(bookingId).update({'isArchived': true});

  @override
  Future<void> updateVehicleStatus(
          String bookingId, VehicleStatus status) async =>
      await _bookings.doc(bookingId).update({'vehicleStatus': status.name});

  @override
  Future<void> updateBookingFields(
      String bookingId, Map<String, dynamic> fields) async {
    await _bookings.doc(bookingId).update(fields);
  }

  // ── Wallet ────────────────────────────────────────────────
  @override
  Future<WalletModel?> getWallet(String uid) async {
    final snapshot = await _users.doc(uid).collection('wallet').limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return WalletModel.fromFirestore(snapshot.docs.first);
  }

  @override
  Stream<WalletModel?> watchWallet(String uid) =>
      _users.doc(uid).collection('wallet').limit(1).snapshots().map((s) =>
          s.docs.isEmpty ? null : WalletModel.fromFirestore(s.docs.first));

  @override
  Stream<bool?> watchSensorStatus(String parkingId, String spotId) {
    return _db
        .collection('locations_v2')
        .doc(parkingId)
        .collection('sensors')
        .doc(spotId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      return snap.data()?['occupied'] as bool?;
    });
  }

  @override
  Stream<List<TransactionModel>> watchTransactions(
      String uid, String walletId) {
    final walletRef = _users.doc(uid).collection('wallet').doc(walletId);

    // Écouter debits + topUps en parallèle
    final debitsStream = walletRef
        .collection('debits')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => TransactionModel.debitFromFirestore(d)).toList());

    final topUpsStream = walletRef
        .collection('topUps')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => TransactionModel.topUpFromFirestore(d)).toList());

    // Combiner et trier
    return Rx.combineLatest2(debitsStream, topUpsStream, (debits, topUps) {
      final all = [...debits, ...topUps];
      all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return all;
    });
  }

  @override
  Future<void> createWallet(String uid) async =>
      await _users.doc(uid).collection('wallet').add({'balance': 0});

  @override
  Future<void> updateWalletBalance(
          String uid, String walletId, int newBalance) async =>
      await _users
          .doc(uid)
          .collection('wallet')
          .doc(walletId)
          .update({'balance': newBalance});

  @override
  Future<void> addDebit({
    required String uid,
    required String walletId,
    required int amount,
    required int newBalance,
    required String parkingId,
    required String parkingName,
  }) async =>
      await _users
          .doc(uid)
          .collection('wallet')
          .doc(walletId)
          .collection('debits')
          .add({
        'amount': amount,
        'newBalance': newBalance,
        'parkingId': parkingId,
        'parkingName': parkingName,
        'timestamp': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> addTopUp({
    required String uid,
    required String walletId,
    required int amount,
    required int newBalance,
    required String source,
    String? agentUid,
  }) async =>
      await _users
          .doc(uid)
          .collection('wallet')
          .doc(walletId)
          .collection('topUps')
          .add({
        'amount': amount,
        'newBalance': newBalance,
        'source': source,
        'clientId': uid,
        'creditedBy': agentUid,
        'timestamp': FieldValue.serverTimestamp(),
      });

  // ── Agent ─────────────────────────────────────────────────

  @override
  Stream<List<Map<String, dynamic>>> watchAgentTopUps(String agentUid) {
    return _db
        .collectionGroup('topUps')
        .where('creditedBy', isEqualTo: agentUid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => {
                  ...d.data(),
                  'clientId':
                      d.reference.parent.parent?.parent.parent?.id ?? '',
                })
            .toList());
  }

  // ── Notifications ─────────────────────────────────────────
  @override
  Future<void> saveNotification({
    required String uid,
    required String title,
    required String body,
  }) async =>
      await _users.doc(uid).collection('notifications').add({
        'title': title,
        'body': body,
        'isRead': false,
        'receivedAt': FieldValue.serverTimestamp(),
      });

  @override
  Stream<List<NotificationModel>> watchNotifications(String uid) => _users
      .doc(uid)
      .collection('notifications')
      .orderBy('receivedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(NotificationModel.fromFirestore).toList());

  @override
  Future<void> markNotificationRead(String uid, String notifId) async =>
      await _users
          .doc(uid)
          .collection('notifications')
          .doc(notifId)
          .update({'isRead': true});
}
