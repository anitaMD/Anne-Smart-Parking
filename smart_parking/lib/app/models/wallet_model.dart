import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle portefeuille YSP Coin
///
/// Collection Firestore : users/{uid}/wallet/{walletId}
/// Champs :
/// {
///   balance: int   (en SPM)
/// }
/// Sous-collections : /debits/{debitId}, /topUps/{topUpId}
class WalletModel {
  final String id;
  final int balance;

  const WalletModel({required this.id, required this.balance});

  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletModel(
      id: doc.id,
      balance: data['balance'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {'balance': balance};

  WalletModel copyWith({int? balance}) =>
      WalletModel(id: id, balance: balance ?? this.balance);

  bool canAfford(int cost) => balance >= cost;

  @override
  String toString() => 'WalletModel(balance: $balance SPM)';
}

/// Type de transaction
enum TransactionType { debit, topUp }

/// Source d'un top-up
enum TopUpSource { agent, qrCode, online }

/// Modèle transaction YSP Coin
///
/// Débit  → users/{uid}/wallet/{wId}/debits/{id}
/// Top-up → users/{uid}/wallet/{wId}/topUps/{id}
///
/// Champs débit :
/// {
///   amount: int
///   newBalance: int
///   parkingId: string
///   parkingName: string
///   timestamp: timestamp
/// }
///
/// Champs top-up :
/// {
///   amount: int
///   newBalance: int
///   source: string  ("agent|qrCode|online")
///   timestamp: timestamp
/// }
class TransactionModel {
  final String id;
  final TransactionType type;
  final int amount;
  final int newBalance;
  final DateTime timestamp;
  final String? parkingId;
  final String? parkingName;
  final TopUpSource? topUpSource;
  final String? agentId;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.newBalance,
    required this.timestamp,
    this.parkingId,
    this.parkingName,
    this.topUpSource,
    this.agentId,
  });

  factory TransactionModel.debitFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      type: TransactionType.debit,
      amount: data['amount'] as int? ?? 0,
      newBalance: data['newBalance'] as int? ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parkingId: data['parkingId'] as String?,
      parkingName: data['parkingName'] as String?,
    );
  }

  factory TransactionModel.topUpFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final sourceStr = data['source'] as String? ?? 'agent';
    return TransactionModel(
      id: doc.id,
      type: TransactionType.topUp,
      amount: data['amount'] as int? ?? 0,
      newBalance: data['newBalance'] as int? ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      agentId: data['creditedBy'] as String?,
      topUpSource: TopUpSource.values.firstWhere(
        (e) => e.name == sourceStr,
        orElse: () => TopUpSource.agent,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    if (type == TransactionType.debit) {
      return {
        'amount': amount,
        'newBalance': newBalance,
        'parkingId': parkingId,
        'parkingName': parkingName,
        'timestamp': FieldValue.serverTimestamp(),
      };
    }
    return {
      'amount': amount,
      'newBalance': newBalance,
      'source': topUpSource?.name ?? 'agent',
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  bool get isDebit => type == TransactionType.debit;
  bool get isTopUp => type == TransactionType.topUp;
  String get signedAmount => isDebit ? '-$amount SPM' : '+$amount SPM';

  @override
  String toString() => 'TransactionModel(${type.name}, amount: $amount)';
}
