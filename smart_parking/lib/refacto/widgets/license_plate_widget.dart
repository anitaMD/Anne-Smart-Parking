import 'package:flag/flag.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../models/vehicle_model.dart';

/// Plaque d'immatriculation — Option A (compact horizontal)
/// Design validé : bande bleue + drapeau + logo centré + numéro en grand
/// Réutilisable dans : Dashboard, Tab Véhicules, BookingScreen
class LicensePlateWidget extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isDefault;
  final bool isSelected;
  final bool compact;

  const LicensePlateWidget({
    super.key,
    required this.vehicle,
    this.isDefault = false,
    this.compact = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = compact ? AppSizes.plateCompactHeight : AppSizes.plateHeight;
    final bandWidth =
        compact ? AppSizes.plateCompactBandWidth : AppSizes.plateBandWidth;

    final plateFont =
        compact ? AppSizes.plateCompactFontSize : AppSizes.plateFontSize;

    final logoSize =
        compact ? AppSizes.plateCompactLogoSize : AppSizes.plateLogoSize;
    final flagSize =
        compact ? AppSizes.plateCompactFlagHeight : AppSizes.plateFlagHeight;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? AppColors.walletBackground.withValues(
                  alpha: 0.6) // Jaune/Or quand sélectionné (même si défaut)
              : isDefault
                  ? Colors.transparent.withValues(
                      alpha: 0.1) // Vert pour le défaut (non sélectionné)
                  : const Color(0xFF222222), // Noir pour les autres autres
          width: isDefault || isSelected ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDefault
                ? AppColors.success.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Bande bleue ───────────────────────────────
          Container(
            width: bandWidth,
            decoration: const BoxDecoration(
              color: Color(0xFF003F8A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Vrai drapeau via package flag
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Flag.fromString(
                    vehicle.countryIso.isEmpty
                        ? 'COUNTRY ISO'
                        : vehicle.countryIso,
                    height: flagSize,
                    width: flagSize * 1.4,
                    fit: BoxFit.cover,
                    replacement:
                        const Text('🌍', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 3), // Réduit de 59 à 3
                Text(
                  vehicle.countryIso.isEmpty
                      ? 'COUNTRY ISO'
                      : vehicle.countryIso,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 9 : 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // ── Contenu principal ─────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical: compact ? 4 : 6,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Logo marque + ville (city code)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Image.asset(
                            'assets/images/carLogos/${vehicle.brand.toLowerCase()}.png',
                            width: logoSize - 12,
                            height: logoSize - 12,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: logoSize - 12,
                              height: logoSize - 12,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  vehicle.brand.isNotEmpty
                                      ? vehicle.brand[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: compact ? 8 : 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Ville (city code)
                      Text(
                        vehicle.cityIso.isNotEmpty
                            ? vehicle.cityIso.toUpperCase()
                            : 'REGION ISO',
                        style: TextStyle(
                          fontSize: compact ? 9 : 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  // Numéro de plaque — centré, en grand
                  Text(
                    vehicle.licensePlate.isNotEmpty
                        ? vehicle.licensePlate.toUpperCase()
                        : 'NUMÉRO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: plateFont,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      letterSpacing: compact ? 1 : 1,
                    ),
                  ),

                  // Modèle + couleur + année
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Petit cercle de couleur
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: getColorFromString(vehicle.color),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.modelDetail.isNotEmpty
                                ? vehicle.modelDetail.toUpperCase()
                                : 'MODÈLE',
                            style: TextStyle(
                              fontSize: compact ? 9 : 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        vehicle.registrationYear.isNotEmpty
                            ? vehicle.registrationYear
                            : 'Année'.toUpperCase(),
                        style: TextStyle(
                          fontSize: compact ? 9 : 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Barre verte si sélectionné ────────────────
          if (isDefault)
            Container(
              width: 5,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Fonction utilitaire pour convertir le nom de couleur ──
Color getColorFromString(String colorName) {
  const colorMap = {
    'Blanc': Colors.white,
    'Noir': Colors.black,
    'Gris': Colors.grey,
    'Argent': Color(0xFFC0C0C0),
    'Rouge': Colors.red,
    'Bleu': Colors.blue,
    'Vert': Colors.green,
    'Jaune': Colors.yellow,
    'Beige': Color(0xFFF5F5DC),
    'Marron': Color(0xFF795548),
    'Orange': Colors.orange,
    'Violet': Colors.purple,
    'Rose': Colors.pink,
    'Or': Colors.amber,
  };
  return colorMap[colorName] ?? Colors.grey;
}
