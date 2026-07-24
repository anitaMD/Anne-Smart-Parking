import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/services/ml_kit_service.dart';

/// Tests unitaires — MLKitService.validateEqualityCard
///
/// scanQRCode/recognizeCardText dépendent du vrai moteur ML Kit
/// (natif, hors périmètre d'un test unitaire pur). En revanche,
/// validateEqualityCard() est une fonction PURE (texte en entrée,
/// résultat déterministe) — la vraie logique anti-fraude de
/// validation de la carte d'égalité des chances DGAS, testable
/// sans aucune dépendance native.

void main() {
  late MLKitService service;

  setUp(() {
    service = MLKitService();
  });

  group('validateEqualityCard — texte absent/vide', () {
    test('invalide si le texte reconnu est null', () {
      final result = service.validateEqualityCard(null);
      expect(result.isValid, isFalse);
      expect(result.error, isNotNull);
    });

    test('invalide si le texte reconnu est une chaîne vide', () {
      final result = service.validateEqualityCard('');
      expect(result.isValid, isFalse);
    });
  });

  group('validateEqualityCard — carte DGAS valide (≥2 mots-clés)', () {
    test('valide avec "DGAS" et "République du Sénégal"', () {
      final result = service.validateEqualityCard(
        'République du Sénégal\nDGAS\nCarte de certification',
      );

      expect(result.isValid, isTrue);
      expect(result.error, isNull);
    });

    test('valide avec "Action Sociale" et "handicap"', () {
      final result = service.validateEqualityCard(
        'Direction de l\'Action Sociale — Certification handicap',
      );

      expect(result.isValid, isTrue);
    });

    test('insensible à la casse (majuscules/minuscules)', () {
      final result = service.validateEqualityCard(
        'REPUBLIQUE DU SENEGAL - DGAS',
      );

      expect(result.isValid, isTrue);
    });

    test('valide même avec des mots-clés accentués ou non', () {
      final result = service.validateEqualityCard(
        'Republique du Senegal - Direction Generale',
      );

      expect(result.isValid, isTrue);
    });
  });

  group('validateEqualityCard — texte non pertinent (< 2 mots-clés)', () {
    test('invalide avec un seul mot-clé trouvé', () {
      final result = service.validateEqualityCard('Juste le mot DGAS');

      expect(result.isValid, isFalse,
          reason: 'Un seul mot-clé ne suffit pas — règle "au moins 2" '
              'pour éviter les faux positifs sur un texte quelconque '
              'contenant accidentellement un des mots-clés.');
      expect(result.error, isNotNull);
    });

    test('invalide avec un texte totalement hors-sujet', () {
      final result = service.validateEqualityCard(
        'Ceci est un ticket de caisse pour des courses au supermarché',
      );

      expect(result.isValid, isFalse);
    });
  });

  group('CardValidationResult', () {
    test('isValid true ne nécessite pas de message d\'erreur', () {
      const result = CardValidationResult(isValid: true);
      expect(result.error, isNull);
    });

    test('isValid false peut porter un message d\'erreur explicite', () {
      const result = CardValidationResult(
        isValid: false,
        error: 'Carte non reconnue',
      );
      expect(result.error, 'Carte non reconnue');
    });
  });
}
