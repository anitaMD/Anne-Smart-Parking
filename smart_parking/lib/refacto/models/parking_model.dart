import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle parking YSP Smart Parking
///
/// Collection Firestore : locations/{parkingId}
/// Champs :
/// {
///   name: string
///   streetAddress: string
///   city: string
///   countryCode: string
///   position: GeoPoint
///   openingHour: string  (ex: "07:30")
///   closingHour: string  (ex: "18:00")
///   feePerSlot: int      (en SPM par 30 min)
/// }
/// Sous-collection : /spots/{spotDocId}
class ParkingModel {
  final String id;
  final String name;
  final String streetAddress;
  final String city;
  final String countryCode;
  final GeoPoint position;
  final String openingHour;
  final String closingHour;
  final int feePerSlot;

  const ParkingModel({
    required this.id,
    required this.name,
    required this.streetAddress,
    required this.city,
    required this.countryCode,
    required this.position,
    required this.openingHour,
    required this.closingHour,
    required this.feePerSlot,
  });

  factory ParkingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParkingModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      streetAddress: data['streetAddress'] as String? ?? '',
      city: data['city'] as String? ?? '',
      countryCode: data['countryCode'] as String? ?? '',
      position: data['position'] as GeoPoint? ?? const GeoPoint(0, 0),
      openingHour: data['openingHour'] as String? ?? '00:00',
      closingHour: data['closingHour'] as String? ?? '23:59',
      feePerSlot: data['feePerSlot'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'streetAddress': streetAddress,
        'city': city,
        'countryCode': countryCode,
        'position': position,
        'openingHour': openingHour,
        'closingHour': closingHour,
        'feePerSlot': feePerSlot,
      };

  String get fullAddress => '$streetAddress, $city';
  double get latitude => position.latitude;
  double get longitude => position.longitude;
  String get hours => '$openingHour - $closingHour';

  @override
  String toString() => 'ParkingModel(id: $id, name: $name)';
}

/// Informations sur les places à l'intérieur d'un parking
///
/// Collection Firestore : locations_v2/{parkingId}/spots/{docId}
/// Champs :
/// {
///   regularIds: string[]
///   specialIds: string[]
///   availableIds: string[]
///   bookedIds: string[]
///   occupiedFromBookingIds: string[]
///   occupiedFromWalkInIds: string[]
/// }
class ParkingSpotsInfo {
  final String id;
  final List<String> regularIds;
  final List<String> specialIds;
  final List<String> availableIds;
  final List<String> bookedIds;
  final List<String> occupiedFromBookingIds;
  final List<String> occupiedFromWalkInIds;

  const ParkingSpotsInfo({
    required this.id,
    required this.regularIds,
    required this.specialIds,
    required this.availableIds,
    required this.bookedIds,
    required this.occupiedFromBookingIds,
    required this.occupiedFromWalkInIds,
  });

  factory ParkingSpotsInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParkingSpotsInfo(
      id: doc.id,
      regularIds: List<String>.from(data['regularIds'] as List? ?? []),
      specialIds: List<String>.from(data['specialIds'] as List? ?? []),
      availableIds: List<String>.from(data['availableIds'] as List? ?? []),
      bookedIds: List<String>.from(data['bookedIds'] as List? ?? []),
      occupiedFromBookingIds:
          List<String>.from(data['occupiedFromBookingIds'] as List? ?? []),
      occupiedFromWalkInIds:
          List<String>.from(data['occupiedFromWalkInIds'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'regularIds': regularIds,
        'specialIds': specialIds,
        'availableIds': availableIds,
        'bookedIds': bookedIds,
        'occupiedFromBookingIds': occupiedFromBookingIds,
        'occupiedFromWalkInIds': occupiedFromWalkInIds,
      };

  int get totalAvailable => availableIds.length;
  int get totalSpots => regularIds.length + specialIds.length;

  List<String> get allIds => [...regularIds, ...specialIds];
}
