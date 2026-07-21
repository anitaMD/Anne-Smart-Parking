/// Résultat du calcul de facturation au dépassement — utilisé par
/// le script Raspberry Pi (logique équivalente en Python) et testé
/// ici côté Dart pour valider la formule avant portage.
class OverstayCharge {
  final int additionalMinutes;
  final int additionalCharge;
  final int newOverstayMinutes;
  final int newOverstayCharge;

  const OverstayCharge({
    required this.additionalMinutes,
    required this.additionalCharge,
    required this.newOverstayMinutes,
    required this.newOverstayCharge,
  });
}

/// Calcule le supplément à facturer pour un dépassement de créneau.
///
/// Facturation continue à la minute (décision produit) : chaque
/// minute écoulée depuis la dernière vérification est facturée au
/// tarif proportionnel dérivé du tarif par tranche de 30 minutes
/// (feePerSlot).
///
/// [now] et [lastCheck] permettent de ne facturer que les minutes
/// écoulées DEPUIS la dernière vérification — sans ce garde-fou,
/// chaque exécution du script Pi (toutes les 1-2 min) referacturerait
/// depuis le tout début du dépassement.
///
/// Retourne null si aucune minute supplémentaire n'est à facturer
/// (ex: vérifications trop rapprochées, ou véhicule pas encore en
/// dépassement réel).
OverstayCharge? computeOverstayCharge({
  required DateTime bookingEnd,
  required DateTime now,
  required DateTime? lastCheck,
  required int feePerSlot,
  required int currentOverstayMinutes,
  required int currentOverstayCharge,
}) {
  // Le point de départ du calcul est le plus tardif entre bookingEnd
  // (première fois qu'on dépasse) et lastCheck (dépassements suivants)
  final since = (lastCheck != null && lastCheck.isAfter(bookingEnd))
      ? lastCheck
      : bookingEnd;

  final additionalMinutes = now.difference(since).inMinutes;
  if (additionalMinutes <= 0) return null;

  // Tarif par minute dérivé du tarif par tranche de 30 minutes
  final ratePerMinute = feePerSlot / 30;
  final additionalCharge = (additionalMinutes * ratePerMinute).round();

  return OverstayCharge(
    additionalMinutes: additionalMinutes,
    additionalCharge: additionalCharge,
    newOverstayMinutes: currentOverstayMinutes + additionalMinutes,
    newOverstayCharge: currentOverstayCharge + additionalCharge,
  );
}
