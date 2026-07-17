import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/models/wallet_model.dart';

/// Tests unitaires — WalletModel & TransactionModel
///
/// Couvre la logique métier du portefeuille YSP Coin : vérification
/// de solde suffisant (canAfford), et la distinction débit/crédit
/// utilisée dans tout l'affichage de l'historique des transactions
/// (wallet, agent, dashboard).

void main() {
  group('WalletModel — canAfford', () {
    test('retourne true quand le solde est suffisant', () {
      const wallet = WalletModel(id: 'w1', balance: 5000);

      expect(wallet.canAfford(3000), isTrue);
    });

    test('retourne true quand le solde est exactement égal au coût', () {
      const wallet = WalletModel(id: 'w1', balance: 5000);

      expect(wallet.canAfford(5000), isTrue);
    });

    test('retourne false quand le solde est insuffisant', () {
      const wallet = WalletModel(id: 'w1', balance: 1000);

      expect(wallet.canAfford(5000), isFalse);
    });

    test('retourne true pour un coût de 0', () {
      const wallet = WalletModel(id: 'w1', balance: 0);

      expect(wallet.canAfford(0), isTrue);
    });
  });

  group('WalletModel — copyWith', () {
    test('met à jour uniquement le solde', () {
      const original = WalletModel(id: 'w1', balance: 1000);
      final updated = original.copyWith(balance: 2500);

      expect(updated.id, 'w1');
      expect(updated.balance, 2500);
    });

    test('conserve le solde original si aucun argument fourni', () {
      const original = WalletModel(id: 'w1', balance: 1000);
      final updated = original.copyWith();

      expect(updated.balance, 1000);
    });
  });

  group('TransactionModel — isDebit / isTopUp', () {
    test('un débit est identifié correctement', () {
      final transaction = TransactionModel(
        id: 't1',
        type: TransactionType.debit,
        amount: 600,
        newBalance: 4400,
        timestamp: DateTime.now(),
        parkingId: 'p1',
        parkingName: 'ECPI Smart Parking',
      );

      expect(transaction.isDebit, isTrue);
      expect(transaction.isTopUp, isFalse);
    });

    test('un top-up est identifié correctement', () {
      final transaction = TransactionModel(
        id: 't2',
        type: TransactionType.topUp,
        amount: 5000,
        newBalance: 9400,
        timestamp: DateTime.now(),
        topUpSource: TopUpSource.agent,
      );

      expect(transaction.isTopUp, isTrue);
      expect(transaction.isDebit, isFalse);
    });
  });

  group('TransactionModel — signedAmount', () {
    test('un débit affiche un montant négatif', () {
      final transaction = TransactionModel(
        id: 't1',
        type: TransactionType.debit,
        amount: 600,
        newBalance: 4400,
        timestamp: DateTime.now(),
      );

      expect(transaction.signedAmount, '-600 SPM');
    });

    test('un top-up affiche un montant positif', () {
      final transaction = TransactionModel(
        id: 't2',
        type: TransactionType.topUp,
        amount: 5000,
        newBalance: 9400,
        timestamp: DateTime.now(),
      );

      expect(transaction.signedAmount, '+5000 SPM');
    });
  });

  group('TransactionModel — agentId (traçabilité rechargement)', () {
    test('un top-up crédité par un agent conserve son ID', () {
      final transaction = TransactionModel(
        id: 't3',
        type: TransactionType.topUp,
        amount: 10000,
        newBalance: 15000,
        timestamp: DateTime.now(),
        topUpSource: TopUpSource.qrCode,
        agentId: 'agent-uid-123',
      );

      expect(transaction.agentId, 'agent-uid-123');
      expect(transaction.topUpSource, TopUpSource.qrCode);
    });

    test('un débit n\'a pas d\'agentId', () {
      final transaction = TransactionModel(
        id: 't4',
        type: TransactionType.debit,
        amount: 600,
        newBalance: 4400,
        timestamp: DateTime.now(),
      );

      expect(transaction.agentId, isNull);
    });
  });

  group('WalletModel — toString', () {
    test('inclut le solde formaté avec séparateur de milliers', () {
      const wallet = WalletModel(id: 'w1', balance: 12500);
      expect(wallet.toString(), contains('12 500'));
      expect(wallet.toString(), contains('SPM'));
    });
  });
}
