import 'package:flutter/material.dart';

/// Palette de couleurs YSP Smart Parking
///
/// BONNE PRATIQUE : toutes les couleurs sont ici.
/// On n'écrit jamais Colors.red ou Color(0xFF...) directement
/// dans un widget — on utilise toujours AppColors.xxx
abstract class AppColors {
  // ── Couleurs principales ──────────────────────────────────
  static const Color primary = Color(0xFF3F51B5); // Indigo
  static const Color secondary = Color(0xFF7986CB); // Indigo clair
  static const Color accent = Color(0xFF536DFE); // Indigo vif

  // ── Gradient principal ────────────────────────────────────
  // Utilisé sur l'AppBar, les boutons principaux, les en-têtes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  // ── Fond et surfaces ──────────────────────────────────────
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFEEEEEE);

  // ── Textes ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;

  // ── États des places de parking ───────────────────────────
  // Ces couleurs correspondent directement aux LEDs de la maquette
  static const Color spotFree = Color(0xFF4CAF50); // Vert  — libre standard
  static const Color spotSpecial = Color(0xFF2196F3); // Bleu  — libre handicapé
  static const Color spotReserved =
      Color(0xFFFF9800); // Orange — réservée via app
  static const Color spotOccupied =
      Color(0xFFF44336); // Rouge  — occupée physiquement

  // ── Feedback utilisateur ──────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // ── Bordures et ombres ────────────────────────────────────
  static const Color border = Color(0xFFBDBDBD);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x29000000); // noir 16% opacité

  // ── Wallet YSP Coin ───────────────────────────────────────
  static const Color walletGold = Color(0xFFFFD700);
  static const Color walletBackground = Color(0xFF1A237E);
  static const Color walletText = Colors.white;

  // ── Connectivité ─────────────────────────────────────────
  static const Color offline = Color(0xFFC62828); // rouge foncé
  static const Color online = Color(0xFF2E7D32); // vert foncé
}
