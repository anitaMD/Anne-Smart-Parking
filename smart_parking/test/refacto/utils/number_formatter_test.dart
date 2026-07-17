import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/core/utils/number_formatter.dart';

/// Tests unitaires — formatSPM
///
/// Vérifie le formatage des montants SPM avec séparateur de milliers
/// (espace), utilisé dans wallet, dashboard, agent et historique
/// de réservations pour la lisibilité des grands nombres.

void main() {
  group('formatSPM', () {
    test('formate un nombre sans milliers sans séparateur', () {
      expect(formatSPM(500), '500');
    });

    test('formate un nombre à 4 chiffres avec un séparateur', () {
      expect(formatSPM(1000), '1 000');
    });

    test('formate un nombre à 5 chiffres', () {
      expect(formatSPM(12500), '12 500');
    });

    test('formate un nombre à 6 chiffres avec deux séparateurs', () {
      expect(formatSPM(1000000), '1 000 000');
    });

    test('formate un très grand nombre (solde agent cumulé)', () {
      expect(formatSPM(2896930), '2 896 930');
    });

    test('formate zéro correctement', () {
      expect(formatSPM(0), '0');
    });

    test('formate un nombre négatif (cas théorique, ne devrait pas arriver)',
        () {
      // Un solde ne devrait jamais être négatif dans l'app, mais on
      // vérifie que la fonction ne plante pas si jamais un bug amène ce cas.
      expect(() => formatSPM(-100), returnsNormally);
    });
  });
}
