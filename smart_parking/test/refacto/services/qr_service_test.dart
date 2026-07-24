import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/services/qr_service.dart';

/// Tests unitaires — QRService (chiffrement AES top-up)
///
/// Le chiffrement AES lui-même est du Dart pur (package `encrypt`,
/// aucun canal natif) — testable sans mock, contrairement à la
/// plupart des autres services qui touchent des plugins natifs.
///
/// Ces tests verrouillent aussi le fix appliqué : la clé/IV étaient
/// auparavant générées ALÉATOIREMENT à chaque démarrage d'app
/// (Key.fromLength/IV.fromLength), rendant le déchiffrement
/// structurellement impossible entre l'app Agent (qui chiffre) et
/// l'app Utilisateur (qui déchiffre) — deux instances distinctes,
/// deux clés aléatoires différentes.

void main() {
  late QRService service;

  setUp(() {
    service = QRService();
  });

  group('QRService — chiffrement/déchiffrement (round-trip)', () {
    test('un QR chiffré peut être déchiffré et redonne les mêmes'
        ' données', () {
      final encrypted = service.encryptTopUp(amount: 5000, agentId: 'agent-1');
      final decrypted = service.decryptTopUp(encrypted);

      expect(decrypted, isNotNull);
      expect(decrypted!.amount, 5000);
      expect(decrypted.agentId, 'agent-1');
    });

    test('deux instances SÉPARÉES de QRService peuvent se comprendre'
        ' — régression: la clé aléatoire par instance rendait ça'
        ' impossible', () {
      // Simule l'app Agent (chiffre) et l'app Utilisateur (déchiffre)
      // comme deux instances de service complètement indépendantes.
      final agentService = QRService();
      final userService = QRService();

      final encrypted =
          agentService.encryptTopUp(amount: 3000, agentId: 'agent-2');
      final decrypted = userService.decryptTopUp(encrypted);

      expect(decrypted, isNotNull,
          reason: 'Avec une clé fixe partagée, n\'importe quelle '
              'instance doit pouvoir déchiffrer ce qu\'une autre a '
              'chiffré — condition indispensable au fonctionnement '
              'réel agent/utilisateur.');
      expect(decrypted!.amount, 3000);
    });

    test('génère un chiffré différent à chaque appel (même avec les'
        ' mêmes données) grâce au nonce/timestamp', () {
      final first = service.encryptTopUp(amount: 1000, agentId: 'agent-1');
      final second = service.encryptTopUp(amount: 1000, agentId: 'agent-1');

      expect(first, isNot(equals(second)),
          reason: 'Le timestamp/nonce doit varier — sinon un QR '
              'pourrait être rejoué indéfiniment de façon identique.');
    });
  });

  group('QRService — decryptTopUp (données invalides)', () {
    test('retourne null pour une chaîne qui n\'est pas un QR chiffré'
        ' valide', () {
      final result = service.decryptTopUp('ceci-nest-pas-un-qr-valide');
      expect(result, isNull);
    });

    test('retourne null pour une chaîne vide', () {
      final result = service.decryptTopUp('');
      expect(result, isNull);
    });
  });

  group('QRService — isValid (expiration 24h)', () {
    test('un QR généré maintenant est valide', () {
      final data = QRTopUpData(
        amount: 1000,
        agentId: 'agent-1',
        generatedAt: DateTime.now(),
        nonce: '123',
      );

      expect(service.isValid(data), isTrue);
    });

    test('un QR généré il y a 23h est encore valide', () {
      final data = QRTopUpData(
        amount: 1000,
        agentId: 'agent-1',
        generatedAt: DateTime.now().subtract(const Duration(hours: 23)),
        nonce: '123',
      );

      expect(service.isValid(data), isTrue);
    });

    test('un QR généré il y a 25h est expiré', () {
      final data = QRTopUpData(
        amount: 1000,
        agentId: 'agent-1',
        generatedAt: DateTime.now().subtract(const Duration(hours: 25)),
        nonce: '123',
      );

      expect(service.isValid(data), isFalse);
    });
  });

  group('QRTopUpData — toString', () {
    test('inclut amount et agentId', () {
      final data = QRTopUpData(
        amount: 5000,
        agentId: 'agent-1',
        generatedAt: DateTime.now(),
        nonce: '123',
      );

      expect(data.toString(), contains('5000'));
      expect(data.toString(), contains('agent-1'));
    });
  });
}
