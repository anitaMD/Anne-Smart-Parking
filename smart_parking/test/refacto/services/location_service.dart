import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/services/location_service.dart';

/// Tests unitaires — LocationService.distanceBetween / formattedDistance
///
/// Contrairement à getCurrentPosition/requestPermission/getPositionStream
/// (qui touchent le vrai GPS via des platform channels), distanceBetween
/// délègue à Geolocator.distanceBetween — une formule mathématique pure
/// (Haversine) qui ne nécessite aucun matériel ni permission. Ces deux
/// méthodes sont donc testables directement, sans mock.
///
/// Utilisé pour afficher la distance jusqu'à un parking sur la carte.

void main() {
  final service = LocationService();

  group('LocationService — distanceBetween', () {
    test('retourne 0 pour deux points identiques', () {
      final distance = service.distanceBetween(
        startLat: 14.7167,
        startLng: -17.4677,
        endLat: 14.7167,
        endLng: -17.4677,
      );

      expect(distance, closeTo(0, 0.01));
    });

    test('calcule une distance positive entre deux points distincts', () {
      // Dakar (14.7167, -17.4677) → Thiès (14.7910, -16.9359)
      final distance = service.distanceBetween(
        startLat: 14.7167,
        startLng: -17.4677,
        endLat: 14.7910,
        endLng: -16.9359,
      );

      expect(distance, greaterThan(0));
      // Distance réelle Dakar-Thiès ≈ 55-60 km — vérifie l'ordre de
      // grandeur sans être trop strict sur la précision exacte
      expect(distance, greaterThan(50000));
      expect(distance, lessThan(70000));
    });
  });

  group('LocationService — formattedDistance', () {
    test('affiche en mètres si la distance est inférieure à 1km', () {
      // Deux points très proches (quelques centaines de mètres)
      final result = service.formattedDistance(
        startLat: 14.7167,
        startLng: -17.4677,
        endLat: 14.7180,
        endLng: -17.4677,
      );

      expect(result, endsWith(' m'));
    });

    test('affiche en kilomètres si la distance dépasse 1km', () {
      final result = service.formattedDistance(
        startLat: 14.7167,
        startLng: -17.4677,
        endLat: 14.7910,
        endLng: -16.9359,
      );

      expect(result, endsWith(' km'));
    });

    test('formate avec une décimale pour les kilomètres', () {
      final result = service.formattedDistance(
        startLat: 14.7167,
        startLng: -17.4677,
        endLat: 14.7910,
        endLng: -16.9359,
      );

      // Doit ressembler à "XX.X km" — un seul chiffre après la virgule
      final numberPart = result.replaceAll(' km', '');
      expect(numberPart.split('.').length, 2,
          reason: 'La distance en km doit avoir exactement une décimale');
    });

    test('formate sans décimale pour les mètres', () {
      final result = service.formattedDistance(
        startLat: 14.7167,
        startLng: -17.4677,
        endLat: 14.7175,
        endLng: -17.4677,
      );

      final numberPart = result.replaceAll(' m', '');
      expect(numberPart.contains('.'), isFalse,
          reason: 'La distance en mètres ne doit pas avoir de décimale');
    });
  });
}
