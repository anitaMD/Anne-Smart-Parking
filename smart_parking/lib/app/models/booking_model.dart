import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_parking/app/viewmodels/booking_viewmodel.dart';

/// État d'une réservation
enum BookingStatus { upcoming, ongoing, completed, canceled }

/// État physique du véhicule
enum VehicleStatus { notYetParked, parked, gone }

/// Entrée dans l'historique des modifications
class BookingEdit {
  final DateTime editedAt;
  final String field;
  final String oldValue;
  final String newValue;

  const BookingEdit({
    required this.editedAt,
    required this.field,
    required this.oldValue,
    required this.newValue,
  });

  factory BookingEdit.fromMap(Map<String, dynamic> map) => BookingEdit(
        editedAt: (map['editedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        field: map['field'] as String? ?? '',
        oldValue: map['oldValue'] as String? ?? '',
        newValue: map['newValue'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'editedAt': Timestamp.fromDate(editedAt),
        'field': field,
        'oldValue': oldValue,
        'newValue': newValue,
      };
}

/// Modèle réservation YSP Smart Parking
///
/// Collection Firestore : slotsReservations_v2/{bookingId}
class BookingModel {
  final String id;
  final String clientId;
  final String parkingId;
  final String spotId;
  final String vehicleId;
  final DateTime bookingStart;
  final DateTime bookingEnd;
  final int totalCost;
  final BookingStatus status;
  final VehicleStatus vehicleStatus;
  final bool isArchived;
  final DateTime? createdAt;

  // Nouveaux champs
  final DateTime? canceledAt;
  final DateTime? completedAt;
  final DateTime? vehicleArrivedAt;
  final DateTime? vehicleDepartedAt;
  final List<BookingEdit> editHistory;

  // ── Dépassement (facturation ESP32/Raspberry Pi) ──────────
  final int overstayMinutes;
  final int overstayCharge;
  final DateTime? lastOverstayCheckAt;

  BookingModel({
    required this.id,
    required this.clientId,
    required this.parkingId,
    required this.spotId,
    required this.vehicleId,
    required this.bookingStart,
    required this.bookingEnd,
    required this.totalCost,
    this.status = BookingStatus.upcoming,
    this.vehicleStatus = VehicleStatus.notYetParked,
    this.isArchived = false,
    this.createdAt,
    this.canceledAt,
    this.completedAt,
    this.vehicleArrivedAt,
    this.vehicleDepartedAt,
    this.editHistory = const [],
    this.overstayMinutes = 0,
    this.overstayCharge = 0,
    this.lastOverstayCheckAt,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      clientId: data['clientId'] as String? ?? '',
      parkingId: data['parkingId'] as String? ?? '',
      spotId: data['spotId'] as String? ?? '',
      vehicleId: data['vehicleId'] as String? ?? '',
      bookingStart:
          (data['bookingStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bookingEnd:
          (data['bookingEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalCost: data['totalCost'] as int? ?? 0,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.upcoming,
      ),
      vehicleStatus: VehicleStatus.values.firstWhere(
        (e) => e.name == data['vehicleStatus'],
        orElse: () => VehicleStatus.notYetParked,
      ),
      isArchived: data['isArchived'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      canceledAt: (data['canceledAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      vehicleArrivedAt: (data['vehicleArrivedAt'] as Timestamp?)?.toDate(),
      vehicleDepartedAt: (data['vehicleDepartedAt'] as Timestamp?)?.toDate(),
      editHistory: (data['editHistory'] as List<dynamic>? ?? [])
          .map((e) => BookingEdit.fromMap(e as Map<String, dynamic>))
          .toList(),
      overstayMinutes: data['overstayMinutes'] as int? ?? 0,
      overstayCharge: data['overstayCharge'] as int? ?? 0,
      lastOverstayCheckAt:
          (data['lastOverstayCheckAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'clientId': clientId,
        'parkingId': parkingId,
        'spotId': spotId,
        'vehicleId': vehicleId,
        'bookingStart': Timestamp.fromDate(bookingStart),
        'bookingEnd': Timestamp.fromDate(bookingEnd),
        'totalCost': totalCost,
        'status': status.name,
        'vehicleStatus': vehicleStatus.name,
        'isArchived': isArchived,
        'createdAt': FieldValue.serverTimestamp(),
        'editHistory': editHistory.map((e) => e.toMap()).toList(),
        'overstayMinutes': overstayMinutes,
        'overstayCharge': overstayCharge,
        if (lastOverstayCheckAt != null)
          'lastOverstayCheckAt': Timestamp.fromDate(lastOverstayCheckAt!),
      };

  BookingModel copyWith({
    String? spotId,
    DateTime? bookingStart,
    DateTime? bookingEnd,
    int? totalCost,
    BookingStatus? status,
    VehicleStatus? vehicleStatus,
    bool? isArchived,
    DateTime? canceledAt,
    DateTime? completedAt,
    DateTime? vehicleArrivedAt,
    DateTime? vehicleDepartedAt,
    List<BookingEdit>? editHistory,
    int? overstayMinutes,
    int? overstayCharge,
    DateTime? lastOverstayCheckAt,
  }) =>
      BookingModel(
        id: id,
        clientId: clientId,
        parkingId: parkingId,
        spotId: spotId ?? this.spotId,
        vehicleId: vehicleId,
        bookingStart: bookingStart ?? this.bookingStart,
        bookingEnd: bookingEnd ?? this.bookingEnd,
        totalCost: totalCost ?? this.totalCost,
        status: status ?? this.status,
        vehicleStatus: vehicleStatus ?? this.vehicleStatus,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt,
        canceledAt: canceledAt ?? this.canceledAt,
        completedAt: completedAt ?? this.completedAt,
        vehicleArrivedAt: vehicleArrivedAt ?? this.vehicleArrivedAt,
        vehicleDepartedAt: vehicleDepartedAt ?? this.vehicleDepartedAt,
        editHistory: editHistory ?? this.editHistory,
        overstayMinutes: overstayMinutes ?? this.overstayMinutes,
        overstayCharge: overstayCharge ?? this.overstayCharge,
        lastOverstayCheckAt: lastOverstayCheckAt ?? this.lastOverstayCheckAt,
      );

  // Computed
  int get durationMinutes => bookingEnd.difference(bookingStart).inMinutes;
  int get secondsUntilStart =>
      bookingStart.difference(DateTime.now()).inSeconds;
  int get secondsUntilEnd => bookingEnd.difference(DateTime.now()).inSeconds;
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(bookingStart) && now.isBefore(bookingEnd) && !isArchived;
  }

  bool get isExpired => DateTime.now().isAfter(bookingEnd);
  bool get hasNotStarted => DateTime.now().isBefore(bookingStart);
  bool get wasEdited => editHistory.isNotEmpty;

  /// Le véhicule dépasse son créneau réservé — bookingEnd est passé,
  /// le véhicule a bien été confirmé garé au moins une fois
  /// (vehicleArrivedAt non null), mais le capteur physique n'a pas
  /// confirmé le départ (vehicleDepartedAt encore null). Utilisé
  /// pour le badge dashboard "EN DÉPASSEMENT" et le déclenchement de
  /// la facturation côté Raspberry Pi.
  ///
  /// Une réservation JAMAIS utilisée (vehicleArrivedAt toujours null)
  /// ne doit jamais être considérée en dépassement — sans la
  /// condition vehicleArrivedAt != null, une résa oubliée/jamais
  /// utilisée affichait à tort "EN DÉPASSEMENT" dès bookingEnd
  /// dépassé, uniquement parce que vehicleDepartedAt était aussi
  /// null par défaut (jamais garé ≠ pas encore parti).
  bool get isOverstaying =>
      DateTime.now().isAfter(bookingEnd) &&
      vehicleArrivedAt != null &&
      vehicleDepartedAt == null &&
      status != BookingStatus.canceled &&
      !isArchived;

  @override
  String toString() =>
      'BookingModel(id: $id, spot: $spotId, status: ${status.name})';
}

final ongoingBookingProvider = Provider<BookingModel?>((ref) {
  return ref.watch(bookingProvider).ongoingBooking;
});

// ── Ticker pour rafraîchir l'UI périodiquement (countdown, isOngoing) ──
final dashboardTickerProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 5), (i) => i);
});
