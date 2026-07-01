import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Thème centralisé YSP Smart Parking
///
/// BONNE PRATIQUE : on configure le thème UNE FOIS dans main.dart
/// via theme: AppTheme.light
/// Flutter applique automatiquement ces styles à tous les widgets.
/// Plus besoin d'instancier ThemeHelper() dans chaque fichier.
abstract class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // ── Palette de couleurs ─────────────────────────────
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,

        // ── AppBar ──────────────────────────────────────────
        // Toutes les AppBar de l'app auront ce style par défaut
        appBarTheme: const AppBarTheme(
          elevation: AppSizes.appBarElevation,
          centerTitle: true,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          iconTheme: IconThemeData(color: AppColors.textOnPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textOnPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),

        // ── Champs texte ────────────────────────────────────
        // Tous les TextFormField et TextField auront ce style
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: AppSizes.inputErrorBorderWidth,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: AppSizes.inputErrorBorderWidth,
            ),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: const TextStyle(color: AppColors.textHint),
          errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
          prefixIconColor: AppColors.textSecondary,
        ),

        // ── Boutons principaux ──────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(
              AppSizes.buttonMinWidth,
              AppSizes.buttonHeight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 3,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // ── Boutons texte ───────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // ── Boutons outline ─────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(
              AppSizes.buttonMinWidth,
              AppSizes.buttonHeight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
        ),

        // ── Cards ───────────────────────────────────────────
        cardTheme: CardThemeData(
          elevation: AppSizes.cardElevation,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          ),
          shadowColor: AppColors.shadow,
        ),

        // ── Dividers ────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),

        // ── SnackBar ────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// DÉCORATIONS RÉUTILISABLES
// Remplace les méthodes de ThemeHelper
// ─────────────────────────────────────────────────────────────

/// Décorations communes — s'utilisent comme des constantes
/// Ex: decoration: AppDecorations.inputShadow
abstract class AppDecorations {
  /// Ombre douce sous les champs texte
  static BoxDecoration get inputShadow => BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      );

  /// Bouton avec gradient (AppBar, bouton principal)
  static BoxDecoration gradientButton({
    Color from = AppColors.primary,
    Color to = AppColors.secondary,
  }) =>
      BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [from, to],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      );

  /// AppBar avec gradient
  static const BoxDecoration gradientAppBar = BoxDecoration(
    gradient: AppColors.primaryGradient,
  );

  /// Card standard avec ombre
  static BoxDecoration card({double radius = AppSizes.radiusL}) =>
      BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────
// DIALOGS RÉUTILISABLES
// Remplace alartDialog() et waitingBackgoundProcessDialog()
// ─────────────────────────────────────────────────────────────

abstract class AppDialogs {
  /// Dialog d'information simple
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String content,
  }) =>
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

  /// Dialog de chargement — bloque l'UI pendant une opération async
  /// IMPORTANT : toujours appeler Navigator.of(context).pop()
  /// quand l'opération est terminée
  static Future<void> loading(
    BuildContext context, {
    String message = 'Veuillez patienter...',
  }) =>
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (ctx) => AlertDialog(
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  /// Dialog de confirmation Oui/Non
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
