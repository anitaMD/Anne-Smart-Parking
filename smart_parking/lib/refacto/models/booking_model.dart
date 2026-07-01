import 'package:cloud_firestore/cloud_firestore.dart';

/// État d'une réservation
enum BookingStatus { upcoming, ongoing, completed, canceled }

/// État physique du véhicule
enum VehicleStatus { notYetParked, parked, gone }

/// Modèle réservation YSP Smart Parking
///
/// Collection Firestore : slotsReservations/{bookingId}
/// Champs :
/// {
///   clientId: string
///   parkingId: string
///   spotId: string
///   vehicleId: string
///   bookingStart: timestamp
///   bookingEnd: timestamp
///   totalCost: int       (en SPM)
///   status: string       ("upcoming|ongoing|completed|canceled")
///   vehicleStatus: string ("notYetParked|parked|gone")
///   isArchived: bool
///   createdAt: timestamp
/// }
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

  const BookingModel({
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
      };

  BookingModel copyWith({
    BookingStatus? status,
    VehicleStatus? vehicleStatus,
    bool? isArchived,
  }) =>
      BookingModel(
        id: id,
        clientId: clientId,
        parkingId: parkingId,
        spotId: spotId,
        vehicleId: vehicleId,
        bookingStart: bookingStart,
        bookingEnd: bookingEnd,
        totalCost: totalCost,
        status: status ?? this.status,
        vehicleStatus: vehicleStatus ?? this.vehicleStatus,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt,
      );

  int get durationMinutes => bookingEnd.difference(bookingStart).inMinutes;
  int get secondsUntilStart =>
      bookingStart.difference(DateTime.now()).inSeconds;
  int get secondsUntilEnd => bookingEnd.difference(DateTime.now()).inSeconds;
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(bookingStart) && now.isBefore(bookingEnd);
  }
  bool get isExpired => DateTime.now().isAfter(bookingEnd);
  bool get hasNotStarted => DateTime.now().isBefore(bookingStart);

  @override
  String toString() =>
      'BookingModel(id: $id, spot: $spotId, status: ${status.name})';
}
