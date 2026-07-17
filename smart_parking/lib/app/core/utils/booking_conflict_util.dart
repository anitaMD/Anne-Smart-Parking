/// Utilitaire pur — détection de chevauchement de créneaux
///
/// Extrait de la logique utilisée dans FirestoreService.createBookingAtomic
/// pour la rendre testable indépendamment de Firestore.
///
/// Deux créneaux [aStart, aEnd) et [bStart, bEnd) se chevauchent si
/// aStart < bEnd ET bStart < aEnd (règle standard d'intersection
/// d'intervalles semi-ouverts).
bool doTimeSlotsOverlap({
  required DateTime aStart,
  required DateTime aEnd,
  required DateTime bStart,
  required DateTime bEnd,
}) {
  return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
}
