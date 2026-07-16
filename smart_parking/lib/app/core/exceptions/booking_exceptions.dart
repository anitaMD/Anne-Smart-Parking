/// Exception levée quand une place est déjà réservée sur ce créneau
class SpotConflictException implements Exception {
  const SpotConflictException();
}

/// Exception levée quand le même véhicule a déjà une réservation
/// active sur un créneau qui chevauche celui demandé, potentiellement
/// dans un autre parking.
class VehicleConflictException implements Exception {
  const VehicleConflictException();
}
