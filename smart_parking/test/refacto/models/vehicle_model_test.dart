import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/models/vehicle_model.dart';

/// Tests unitaires — VehicleModel
///
/// Couvre l'affichage véhicule (plaque, nom complet) utilisé dans
/// le dashboard, le stepper de réservation et l'historique — y
/// compris le champ maintenant affiché dans "Mes Réservations"
/// (plaque d'immatriculation ajoutée en session).

VehicleModel _makeVehicle({
  String brand = 'Toyota',
  String modelDetail = 'Corolla',
  String licensePlate = 'DK-1234-2024',
  bool isCurrentlySelected = false,
  int totalBookings = 0,
}) {
  return VehicleModel(
    id: 'vehicle-1',
    brand: brand,
    modelDetail: modelDetail,
    color: 'Bleu',
    licensePlate: licensePlate,
    registrationYear: '2024',
    registrationCountry: 'Sénégal',
    registrationCity: 'Dakar',
    countryIso: 'SN',
    cityIso: 'DK',
    isCurrentlySelected: isCurrentlySelected,
    totalBookings: totalBookings,
  );
}

void main() {
  group('VehicleModel — fullName', () {
    test('concatène la marque et le modèle', () {
      final vehicle = _makeVehicle(brand: 'Toyota', modelDetail: 'Corolla');
      expect(vehicle.fullName, 'Toyota Corolla');
    });

    test('fonctionne avec une marque à un mot', () {
      final vehicle = _makeVehicle(brand: 'Honda', modelDetail: 'Civic');
      expect(vehicle.fullName, 'Honda Civic');
    });
  });

  group('VehicleModel — assetImagePath / logoImagePath', () {
    test('génère le chemin en minuscules pour l\'image du véhicule', () {
      final vehicle = _makeVehicle(brand: 'Toyota');
      expect(vehicle.assetImagePath, 'assets/images/carRep/toyota.png');
    });

    test('génère le chemin en minuscules pour le logo', () {
      final vehicle = _makeVehicle(brand: 'Honda');
      expect(vehicle.logoImagePath, 'assets/images/carLogos/honda.png');
    });

    test('convertit correctement une marque en majuscules', () {
      final vehicle = _makeVehicle(brand: 'BMW');
      expect(vehicle.assetImagePath, 'assets/images/carRep/bmw.png');
    });
  });

  group('VehicleModel — copyWith', () {
    test('met à jour isCurrentlySelected (sélection véhicule par défaut)', () {
      final original = _makeVehicle(isCurrentlySelected: false);
      final updated = original.copyWith(isCurrentlySelected: true);

      expect(updated.isCurrentlySelected, isTrue);
      expect(original.isCurrentlySelected, isFalse,
          reason: 'L\'original ne doit pas être modifié (immutabilité)');
    });

    test('conserve la plaque et la marque si non modifiées', () {
      final original = _makeVehicle(licensePlate: 'DK-1234-2024');
      final updated = original.copyWith(color: 'Rouge');

      expect(updated.licensePlate, 'DK-1234-2024');
      expect(updated.brand, original.brand);
      expect(updated.color, 'Rouge');
    });

    test('incrémente totalBookings correctement', () {
      final original = _makeVehicle(totalBookings: 3);
      final updated = original.copyWith(totalBookings: 4);

      expect(updated.totalBookings, 4);
    });
  });

  group('VehicleModel — licensePlate (affichage historique réservations)', () {
    test('conserve le format de plaque tel quel', () {
      final vehicle = _makeVehicle(licensePlate: 'DK-9998-AM');
      expect(vehicle.licensePlate, 'DK-9998-AM');
    });
  });

  group('VehicleModel — toString', () {
    test('inclut l\'id et le nom complet', () {
      final vehicle = _makeVehicle(brand: 'Toyota', modelDetail: 'Corolla');
      expect(vehicle.toString(), contains('vehicle-1'));
      expect(vehicle.toString(), contains('Toyota Corolla'));
    });
  });

  group('VehicleModel — copyWith (totalParkingHours)', () {
    test('met à jour les heures de stationnement cumulées', () {
      const original = VehicleModel(
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
        totalParkingHours: 5.0,
      );
      final updated = original.copyWith(totalParkingHours: 7.5);

      expect(updated.totalParkingHours, 7.5);
      expect(original.totalParkingHours, 5.0,
          reason: 'L\'original ne doit pas être modifié (immutabilité)');
    });
  });
}
