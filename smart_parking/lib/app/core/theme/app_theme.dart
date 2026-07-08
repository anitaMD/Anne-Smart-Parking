import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

abstract class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
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
                color: AppColors.error, width: AppSizes.inputErrorBorderWidth),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            borderSide: const BorderSide(
                color: AppColors.error, width: AppSizes.inputErrorBorderWidth),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: const TextStyle(color: AppColors.textHint),
          errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
          prefixIconColor: AppColors.textSecondary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize:
                const Size(AppSizes.buttonMinWidth, AppSizes.buttonHeight),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 3,
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize:
                const Size(AppSizes.buttonMinWidth, AppSizes.buttonHeight),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: AppSizes.cardElevation,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
          shadowColor: AppColors.shadow,
        ),
        dividerTheme: const DividerThemeData(
            color: AppColors.divider, thickness: 1, space: 1),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM)),
        ),
      );

  // ── Dark Theme ────────────────────────────────────────────

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          secondary: AppColors.secondary,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E2E),
          error: AppColors.error,
        ),
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: const Color(0xFF12121E),
        appBarTheme: const AppBarTheme(
          elevation: AppSizes.appBarElevation,
          centerTitle: true,
          backgroundColor: Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E2E),
          contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            borderSide: const BorderSide(color: Color(0xFF3A3A5C)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            borderSide: const BorderSide(color: Color(0xFF3A3A5C)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          labelStyle: const TextStyle(color: Color(0xFF9090A0)),
          hintStyle: const TextStyle(color: Color(0xFF6060A0)),
          errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
          prefixIconColor: const Color(0xFF9090A0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize:
                const Size(AppSizes.buttonMinWidth, AppSizes.buttonHeight),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 3,
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize:
                const Size(AppSizes.buttonMinWidth, AppSizes.buttonHeight),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: AppSizes.cardElevation,
          color: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
        ),
        dividerTheme: const DividerThemeData(
            color: Color(0xFF3A3A5C), thickness: 1, space: 1),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2E2E4E),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// DÉCORATIONS RÉUTILISABLES
// ─────────────────────────────────────────────────────────────

abstract class AppDecorations {
  static BoxDecoration get inputShadow => BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 5)),
        ],
      );

  static BoxDecoration gradientButton(
          {Color from = AppColors.primary, Color to = AppColors.secondary}) =>
      BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [from, to]),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, offset: Offset(0, 3), blurRadius: 6)
        ],
      );

  static const BoxDecoration gradientAppBar =
      BoxDecoration(gradient: AppColors.primaryGradient);

  static BoxDecoration card({double radius = AppSizes.radiusL}) =>
      BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))
        ],
      );
}

// ─────────────────────────────────────────────────────────────
// DIALOGS RÉUTILISABLES
// ─────────────────────────────────────────────────────────────

abstract class AppDialogs {
  static Future<void> info(BuildContext context,
          {required String title, required String content}) =>
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'))
          ],
        ),
      );

  static Future<void> loading(BuildContext context,
          {String message = 'Veuillez patienter...'}) =>
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (ctx) => AlertDialog(
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(message, style: const TextStyle(fontSize: 14))),
            ]),
          ),
        ),
      );

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
              child: Text(cancelLabel)),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirmLabel)),
        ],
      ),
    );
    return result ?? false;
  }
}
