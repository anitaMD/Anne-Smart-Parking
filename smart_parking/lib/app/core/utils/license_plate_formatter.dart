// lib/utils/license_plate_formatter.dart

import 'package:flutter/services.dart';

/// Formateur automatique pour les plaques d'immatriculation sénégalaises
class LicensePlateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Nettoyer: garder LETTRES et CHIFFRES, mettre en majuscules
    String text =
        newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Limiter à 12 caractères (ex: DAK-1234-AB)
    if (text.length > 12) {
      text = text.substring(0, 12);
    }

    // Extraire la région (2-3 lettres au début)
    String region = '';
    String numbers = '';
    String suffix = '';
    bool regionDone = false;
    bool numberDone = false;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (!regionDone && RegExp(r'[A-Z]').hasMatch(char) && region.length < 3) {
        region += char;
      } else if (!numberDone && RegExp(r'[0-9]').hasMatch(char)) {
        regionDone = true;
        numbers += char;
      } else if (regionDone &&
          numbers.isNotEmpty &&
          RegExp(r'[A-Z]').hasMatch(char)) {
        // Lettres après les chiffres = suffixe (ex: DK-1234-AB)
        numberDone = true;
        suffix += char;
      } else if (RegExp(r'[0-9]').hasMatch(char) && numberDone) {
        // Si des chiffres après le suffixe, les ignorer
        continue;
      }
    }

    // Si la région a moins de 2 lettres, retourner juste ce qu'on a
    if (region.length < 2) {
      return newValue.copyWith(text: region);
    }

    // Formatage
    String formatted = region;

    if (numbers.isNotEmpty) {
      // Séparer le numéro de l'année
      if (numbers.length <= 5) {
        formatted += '-$numbers';
      } else {
        // Numéro: 3-5 chiffres
        final number =
            numbers.substring(0, numbers.length > 5 ? 5 : numbers.length);
        final year = numbers.length > 5
            ? numbers.substring(5, numbers.length > 9 ? 9 : numbers.length)
            : '';
        formatted += '-$number';
        if (year.isNotEmpty) formatted += '-$year';
      }
    }

    // Ajouter le suffixe (1-2 lettres à la fin)
    if (suffix.isNotEmpty && suffix.length <= 2) {
      formatted += '-$suffix';
    }

    int newCursorPosition = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }
}

/// Utilitaire pour les plaques
class LicensePlateUtils {
  /// Extrait le code région (cityIso) d'une plaque d'immatriculation
  static String extractCityCode(String licensePlate) {
    String cleanPlate = licensePlate.toUpperCase().trim();
    cleanPlate = cleanPlate.replaceAll('-', '');

    // Extraire uniquement les lettres au début (2-3)
    String region = '';
    for (int i = 0; i < cleanPlate.length; i++) {
      final char = cleanPlate[i];
      if (RegExp(r'[A-Z]').hasMatch(char) && region.length < 3) {
        region += char;
      } else {
        break;
      }
    }

    return region;
  }

  /// Extrait le numéro de plaque (sans région)
  static String extractPlateNumber(String licensePlate) {
    String cleanPlate = licensePlate.toUpperCase().trim();
    cleanPlate = cleanPlate.replaceAll('-', '');

    String region = extractCityCode(cleanPlate);
    String rest = cleanPlate.substring(region.length);

    String number = '';
    bool numberDone = false;

    for (int i = 0; i < rest.length; i++) {
      final char = rest[i];
      // ← SUPPRIMER: String suffix = '';

      if (!numberDone && RegExp(r'[0-9]').hasMatch(char)) {
        number += char;
      } else if (number.isNotEmpty && RegExp(r'[A-Z]').hasMatch(char)) {
        numberDone = true;
        // ← SUPPRIMER: suffix += char;
      }
    }

    return number;
  }

  /// Valide le format de la plaque
  /// Valide le format de la plaque
  static bool validatePlate(String licensePlate) {
    String cleanPlate = licensePlate.toUpperCase().trim();

    if (cleanPlate.isEmpty) return false;

    // Enlever les tirets pour validation
    String withoutHyphen = cleanPlate.replaceAll('-', '');

    // Extraire la région (2-3 lettres au début)
    String region = '';
    String rest = '';
    bool regionDone = false;

    for (int i = 0; i < withoutHyphen.length; i++) {
      final char = withoutHyphen[i];
      if (!regionDone && RegExp(r'[A-Z]').hasMatch(char) && region.length < 3) {
        region += char;
      } else {
        regionDone = true;
        rest += char;
      }
    }

    // Valider région: 2-3 lettres
    if (!RegExp(r'^[A-Z]{2,3}$').hasMatch(region)) return false;
    if (rest.isEmpty) return false;

    // Analyser le reste (numéro + suffixe optionnel)
    String number = '';
    String suffix = '';
    bool numberDone = false;

    for (int i = 0; i < rest.length; i++) {
      final char = rest[i];
      if (!numberDone && RegExp(r'[0-9]').hasMatch(char)) {
        number += char;
      } else if (number.isNotEmpty && RegExp(r'[A-Z]').hasMatch(char)) {
        numberDone = true;
        suffix += char;
      } else if (RegExp(r'[A-Z]').hasMatch(char) && number.isEmpty) {
        // Lettre avant les chiffres = invalide
        return false;
      } else if (RegExp(r'[0-9]').hasMatch(char) && numberDone) {
        // Chiffre après le suffixe = invalide
        return false;
      }
    }

    // Valider numéro: au moins 3 chiffres
    if (number.length < 3) return false;

    // Valider suffixe: 0, 1 ou 2 lettres
    if (suffix.isNotEmpty && !RegExp(r'^[A-Z]{1,2}$').hasMatch(suffix)) {
      return false;
    }

    // Vérifier le format avec tirets si présent
    if (cleanPlate.contains('-')) {
      final parts = cleanPlate.split('-');
      if (parts.length >= 2) {
        if (parts[0] != region) return false;
        if (!RegExp(r'^[0-9]+$').hasMatch(parts[1])) return false;
        if (parts[1].length < 3) return false;

        if (parts.length == 3) {
          // Soit année (4 chiffres) soit suffixe (1-2 lettres)
          if (RegExp(r'^[0-9]{4}$').hasMatch(parts[2])) {
            // Année valide
            return true;
          } else if (RegExp(r'^[A-Z]{1,2}$').hasMatch(parts[2])) {
            // Suffixe valide (1-2 lettres)
            return true;
          } else {
            return false;
          }
        }
        return true;
      }
      return false;
    }

    return true;
  }
}
