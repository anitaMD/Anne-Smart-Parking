import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service ML Kit YSP Smart Parking
///
/// Deux fonctionnalités :
/// 1. Scanner un QR code (top-up wallet)
/// 2. Lire et valider une carte d'égalité des chances DGAS
class MLKitService {
  // ── QR Code ───────────────────────────────────────────────

  Future<String?> scanQRCode(File imageFile) async {
    final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final barcodes = await scanner.processImage(inputImage);
      if (barcodes.isEmpty) return null;
      return barcodes.first.rawValue;
    } catch (e) {
      debugPrint('[MLKit] scanQRCode error: $e');
      return null;
    } finally {
      await scanner.close();
    }
  }

  // ── Reconnaissance texte carte DGAS ───────────────────────

  /// Extrait le texte d'une image de carte PMR
  Future<String?> recognizeCardText(File imageFile) async {
    final recognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognized = await recognizer.processImage(inputImage);
      debugPrint('[MLKit] Texte reconnu: ${recognized.text}');
      return recognized.text.isNotEmpty ? recognized.text : null;
    } catch (e) {
      debugPrint('[MLKit] recognizeCardText error: $e');
      return null;
    } finally {
      await recognizer.close();
    }
  }

  /// Valide si l'image est bien une carte DGAS sénégalaise
  ///
  /// Mots-clés basés sur la vraie carte DGAS :
  /// - "DGAS" — Direction Générale de l'Action Sociale
  /// - "République du Sénégal" — en-tête de la carte
  /// - "Certification de handicap" — bande verticale droite
  /// - "Action Sociale" — nom de la direction
  ///
  /// BONNE PRATIQUE : on requiert AU MOINS 2 mots-clés
  /// pour éviter les faux positifs
  CardValidationResult validateEqualityCard(String? recognizedText) {
    if (recognizedText == null || recognizedText.isEmpty) {
      return CardValidationResult(
        isValid: false,
        error: 'Impossible de lire le texte de la carte.',
      );
    }

    final lower = recognizedText.toLowerCase();

    // Mots-clés de la carte DGAS sénégalaise
    final keywords = [
      'dgas',
      'sénégal',
      'senegal',
      'action sociale',
      'certification',
      'handicap',
      'direction générale',
      'republique',
      'république',
    ];

    final foundKeywords = keywords.where((kw) => lower.contains(kw)).toList();
    debugPrint('[MLKit] Mots-clés trouvés: $foundKeywords');

    // Au moins 2 mots-clés pour valider
    if (foundKeywords.length >= 2) {
      return CardValidationResult(isValid: true);
    }

    return CardValidationResult(
      isValid: false,
      error:
          'La carte ne semble pas être une carte d\'égalité des chances valide. Veuillez soumettre à nouveau.',
    );
  }

  /// Analyse complète — reconnait le texte ET valide
  Future<CardValidationResult> analyzeCard(File imageFile) async {
    final text = await recognizeCardText(imageFile);
    return validateEqualityCard(text);
  }
}

/// Résultat de la validation d'une carte
class CardValidationResult {
  final bool isValid;
  final String? error;

  const CardValidationResult({
    required this.isValid,
    this.error,
  });
}
