import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle véhicule YSP Smart Parking
///
/// Collection Firestore : users/{uid}/vehicles/{vehicleId}
/// Champs :
/// {
///   brand: string
///   modelDetail: string
///   color: string
///   licensePlate: string
///   registrationYear: string
///   registrationCountry: string
///   registrationCity: string
///   countryIso: string
///   cityIso: string
///   isCurrentlySelected: bool
///   totalBookings: int
///   totalParkingHours: double
///   type: string
///   addedAt: timestamp
/// }
class VehicleModel {
  final String id;
  final String brand;
  final String modelDetail;
  final String color;
  final String licensePlate;
  final String registrationYear;
  final String registrationCountry;
  final String registrationCity;
  final String countryIso;
  final String cityIso;
  final bool isCurrentlySelected;
  final int totalBookings;
  final double totalParkingHours;
  final String type;
  final DateTime? addedAt;

  const VehicleModel({
    required this.id,
    required this.brand,
    required this.modelDetail,
    required this.color,
    required this.licensePlate,
    required this.registrationYear,
    required this.registrationCountry,
    required this.registrationCity,
    required this.countryIso,
    required this.cityIso,
    this.isCurrentlySelected = false,
    this.totalBookings = 0,
    this.totalParkingHours = 0,
    this.type = 'Car',
    this.addedAt,
  });

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      brand: data['brand'] as String? ?? '',
      modelDetail: data['modelDetail'] as String? ?? '',
      color: data['color'] as String? ?? '',
      licensePlate: data['licensePlate'] as String? ?? '',
      registrationYear: data['registrationYear'] as String? ?? '',
      registrationCountry: data['registrationCountry'] as String? ?? '',
      registrationCity: data['registrationCity'] as String? ?? '',
      countryIso: data['countryIso'] as String? ?? '',
      cityIso: data['cityIso'] as String? ?? '',
      isCurrentlySelected: data['isCurrentlySelected'] as bool? ?? false,
      totalBookings: data['totalBookings'] as int? ?? 0,
      totalParkingHours:
          (data['totalParkingHours'] as num?)?.toDouble() ?? 0,
      type: data['type'] as String? ?? 'Car',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'brand': brand,
        'modelDetail': modelDetail,
        'color': color,
        'licensePlate': licensePlate,
        'registrationYear': registrationYear,
        'registrationCountry': registrationCountry,
        'registrationCity': registrationCity,
        'countryIso': countryIso,
        'cityIso': cityIso,
        'isCurrentlySelected': isCurrentlySelected,
        'totalBookings': totalBookings,
        'totalParkingHours': totalParkingHours,
        'type': type,
        'addedAt': FieldValue.serverTimestamp(),
      };

  VehicleModel copyWith({
    String? modelDetail,
    String? color,
    String? licensePlate,
    bool? isCurrentlySelected,
    int? totalBookings,
    double? totalParkingHours,
  }) =>
      VehicleModel(
        id: id,
        brand: brand,
        modelDetail: modelDetail ?? this.modelDetail,
        color: color ?? this.color,
        licensePlate: licensePlate ?? this.licensePlate,
        registrationYear: registrationYear,
        registrationCountry: registrationCountry,
        registrationCity: registrationCity,
        countryIso: countryIso,
        cityIso: cityIso,
        isCurrentlySelected: isCurrentlySelected ?? this.isCurrentlySelected,
        totalBookings: totalBookings ?? this.totalBookings,
        totalParkingHours: totalParkingHours ?? this.totalParkingHours,
        type: type,
        addedAt: addedAt,
      );

  String get fullName => '$brand $modelDetail';
  String get assetImagePath =>
      'assets/images/carRep/${brand.toLowerCase()}.png';
  String get logoImagePath =>
      'assets/images/carLogos/${brand.toLowerCase()}.png';

  @override
  String toString() => 'VehicleModel(id: $id, name: $fullName)';
}
