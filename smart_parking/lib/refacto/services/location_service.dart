import 'package:geolocator/geolocator.dart';

/// Service de localisation YSP Smart Parking
///
/// Responsabilité : obtenir la position GPS de l'utilisateur
/// et gérer les permissions de localisation.
///
/// Remplace la logique éparpillée dans CurrentLocationNotifier
class LocationService {

  // ── Permission ────────────────────────────────────────────

  /// Vérifie et demande la permission de localisation
  /// Retourne true si la permission est accordée
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  // ── Position courante ─────────────────────────────────────

  /// Retourne la position actuelle de l'utilisateur
  /// Retourne null si la permission est refusée ou si une erreur survient
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  // ── Distance ──────────────────────────────────────────────

  /// Calcule la distance en mètres entre deux points
  double distanceBetween({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Distance en km formatée (ex: "1.2 km" ou "800 m")
  String formattedDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    final meters = distanceBetween(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );

    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  // ── Stream position ───────────────────────────────────────

  /// Stream de mises à jour de position en temps réel
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // mise à jour tous les 10 mètres
      ),
    );
  }
}
