/// Modèle marque de voiture YSP Smart Parking
///
/// DÉCISION : suppression de la collection Firestore carBrandLogos/
/// Les logos sont des assets locaux → liste locale = zéro réseau
class CarBrandModel {
  final String name;

  const CarBrandModel({required this.name});

  String get logoPath => 'assets/images/carLogos/${name.toLowerCase()}.png';
  String get carImagePath => 'assets/images/carRep/${name.toLowerCase()}.png';
  String get displayName => name[0] + name.substring(1).toLowerCase();
}

/// Liste complète des marques disponibles
const List<CarBrandModel> kCarBrands = [
  CarBrandModel(name: 'MERCEDES'),
  CarBrandModel(name: 'HONDA'),
  CarBrandModel(name: 'ISUZU'),
  CarBrandModel(name: 'FORD'),
  CarBrandModel(name: 'TOYOTA'),
  CarBrandModel(name: 'NISSAN'),
  CarBrandModel(name: 'VOLKSWAGEN'),
  CarBrandModel(name: 'FERRARI'),
  CarBrandModel(name: 'HYUNDAI'),
  CarBrandModel(name: 'OPEL'),
  CarBrandModel(name: 'PEUGEOT'),
  CarBrandModel(name: 'ACURA'),
  CarBrandModel(name: 'BMW'),
  CarBrandModel(name: 'KIA'),
  CarBrandModel(name: 'CHEVROLET'),
  CarBrandModel(name: 'DACIA'),
];

CarBrandModel? findBrand(String name) {
  try {
    return kCarBrands.firstWhere(
      (b) => b.name.toLowerCase() == name.toLowerCase(),
    );
  } catch (_) {
    return null;
  }
}
