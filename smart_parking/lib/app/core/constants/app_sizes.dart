/// Espacements, tailles et rayons YSP Smart Parking
///
/// BONNE PRATIQUE : système d'espacement en multiples de 4
/// xs=4, s=8, m=16, l=24, xl=32, xxl=48
/// Cela donne une cohérence visuelle à toute l'app
abstract class AppSizes {
  // ── Espacements (padding / margin) ───────────────────────
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // ── Border Radius ─────────────────────────────────────────
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 100.0; // champs texte et boutons arrondis

  // ── Icônes ───────────────────────────────────────────────
  static const double iconXS = 12.0;
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // ── Boutons ───────────────────────────────────────────────
  static const double buttonHeight = 52.0;
  static const double buttonMinWidth = 120.0;

  // ── Champs texte ──────────────────────────────────────────
  static const double inputHeight = 52.0;
  static const double inputBorderWidth = 1.0;
  static const double inputErrorBorderWidth = 2.0;

  // ── AppBar ────────────────────────────────────────────────
  static const double appBarHeight = 56.0;
  static const double appBarElevation = 0.5;

  // ── Cards ────────────────────────────────────────────────
  static const double cardElevation = 4.0;
  static const double cardRadius = radiusL;

  // ── Avatar / Photo de profil ──────────────────────────────
  static const double avatarS = 40.0;
  static const double avatarM = 80.0;
  static const double avatarL = 120.0;

  // ── Places de parking (grille visuelle dans l'app) ────────
  static const double spotCardHeight = 90.0;
  static const double spotCardWidth = 130.0;
  static const double spotLedSize = 16.0;

  // ── Bottom Navigation Bar ─────────────────────────────────
  static const double bottomNavHeight = 60.0;

  // ── Bannière connectivité ─────────────────────────────────
  static const double connectivityBannerHeight = 32.0;

  // ── License Plate ─────────────────────────────────
  // Standard
  static const double plateHeight = 110.0;
  static const double plateBandWidth = 58.0;
  static const double plateFontSize = 34.0;
  static const double plateSmallFontSize = 14.0;
  static const double plateLogoSize = 30.0;
  static const double plateFlagHeight = 18.0;
  static const double plateBorderRadius = 10.0;
  static const double plateSelectionBarWidth = 5.0;

// Compact
  static const double plateCompactHeight = 80.0;
  static const double plateCompactBandWidth = 44.0;
  static const double plateCompactFontSize = 22.0;
  static const double plateCompactSmallFontSize = 10.0;
  static const double plateCompactLogoSize = 18.0;
  static const double plateCompactFlagHeight = 16.0;
}
