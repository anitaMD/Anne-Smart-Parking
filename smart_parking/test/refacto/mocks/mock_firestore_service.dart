import 'package:smart_parking/app/models/booking_model.dart';
import 'package:smart_parking/app/models/notification_model.dart';
import 'package:smart_parking/app/models/parking_model.dart';
import 'package:smart_parking/app/models/user_model.dart';
import 'package:smart_parking/app/models/vehicle_model.dart';
import 'package:smart_parking/app/models/wallet_model.dart';
import 'package:smart_parking/app/services/firestore_service.dart';

/// Mock FirestoreService — zéro Firebase, zéro réseau
/// Réutilisable dans tous les tests qui ont besoin de Firestore
class MockFirestoreService implements FirestoreServiceBase {
  @override
  Future<void> createUser(UserModel user) async {}
  @override
  Future<UserModel?> getUser(String uid) async => null;
  @override
  Future<bool> userExistsByPhone(String phoneNumber) async =>
      phoneNumber == '+221774880377';
  @override
  Future<bool> userExistsByEmail(String email) async => email == 'test@ysp.com';
  @override
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {}
  @override
  Future<List<VehicleModel>> getVehicles(String uid) async => [];
  @override
  Stream<List<VehicleModel>> watchVehicles(String uid) => const Stream.empty();
  @override
  Future<String> addVehicle(String uid, VehicleModel vehicle) async => '';
  @override
  Future<void> updateVehicle(
      String uid, String vehicleId, Map<String, dynamic> fields) async {}
  @override
  Future<void> deleteVehicle(String uid, String vehicleId) async {}
  @override
  Future<void> setDefaultVehicle(String uid, String vehicleId) async {}
  @override
  Future<List<ParkingModel>> getParkings() async => [];
  @override
  Stream<List<ParkingModel>> watchParkings() => const Stream.empty();
  @override
  Future<ParkingSpotsInfo?> getParkingSpots(String parkingId) async => null;
  @override
  Stream<ParkingSpotsInfo?> watchParkingSpots(String parkingId) =>
      const Stream.empty();
  @override
  Future<void> updateParkingSpots(
      String parkingId, String spotsDocId, Map<String, dynamic> fields) async {}
  @override
  Future<String> createBookingAtomic(BookingModel booking) async => '';
  @override
  Future<List<BookingModel>> getUserUnarchivedBookings(String uid) async => [];
  @override
  Stream<List<BookingModel>> watchUserBookings(String uid) =>
      const Stream.empty();
  @override
  Future<void> updateBookingStatus(
      String bookingId, BookingStatus status) async {}
  @override
  Future<void> archiveBooking(String bookingId) async {}
  @override
  Future<void> updateVehicleStatus(
      String bookingId, VehicleStatus status) async {}
  @override
  Future<WalletModel?> getWallet(String uid) async => null;
  @override
  Stream<WalletModel?> watchWallet(String uid) => const Stream.empty();
  @override
  Future<void> createWallet(String uid) async {}
  @override
  Future<void> updateWalletBalance(
      String uid, String walletId, int newBalance) async {}
  @override
  Future<void> addDebit(
      {required String uid,
      required String walletId,
      required int amount,
      required int newBalance,
      required String parkingId,
      required String parkingName}) async {}
  @override
  Future<void> addTopUp(
      {required String uid,
      required String walletId,
      required int amount,
      required int newBalance,
      required String source,
      String? agentUid}) async {}
  @override
  Future<void> saveNotification(
      {required String uid,
      required String title,
      required String body}) async {}
  @override
  Stream<List<NotificationModel>> watchNotifications(String uid) =>
      const Stream.empty();
  @override
  Future<void> markNotificationRead(String uid, String notifId) async {}

  @override
  Future<Set<String>> getOccupiedSpotIds(
          {required String parkingId,
          required DateTime bookingStart,
          required DateTime bookingEnd}) async =>
      {};

  @override
  Future<void> updateBookingFields(
      String bookingId, Map<String, dynamic> fields) async {}

  @override
  Future<List<BookingModel>> getAllUserBookings(String uid) async => [];

  @override
  Future<List<BookingModel>> getUserArchivedBookings(String uid) async => [];

  @override
  Stream<List<TransactionModel>> watchTransactions(
          String uid, String walletId) =>
      const Stream.empty();

  @override
  Stream<Set<String>> watchOccupiedSpotIds(
          {required String parkingId,
          required DateTime bookingStart,
          required DateTime bookingEnd}) =>
      const Stream.empty();

  @override
  Stream<List<Map<String, dynamic>>> watchAgentTopUps(String agentUid) =>
      const Stream.empty();

  @override
  Stream<bool?> watchSensorStatus(String parkingId, String spotId) =>
      const Stream.empty();
}
