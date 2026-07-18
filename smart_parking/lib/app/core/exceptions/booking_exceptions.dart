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

/// Exception levée quand la place demandée est actuellement occupée
/// par un véhicule en dépassement (bookingEnd dépassé, départ pas
/// encore confirmé par le capteur) — la nouvelle réservation
/// souhaite démarrer immédiatement/très prochainement, mais la
/// place n'est physiquement pas libre en ce moment.
///
/// Limitation connue : ceci ne protège que contre le cas où le
/// dépassement est DÉJÀ en cours au moment de la création de la
/// nouvelle réservation. Si un dépassement survient APRÈS qu'une
/// réservation future a déjà été validée sans conflit à l'époque,
/// aucune protection automatique n'existe (voir mémoire, section
/// limitations connues, pour les pistes de mitigation : délai
/// tampon, notification proactive, intervention agent).
class SpotOverstayConflictException implements Exception {
  const SpotOverstayConflictException();
}
