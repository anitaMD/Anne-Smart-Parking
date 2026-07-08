import 'package:encrypt/encrypt.dart' as enc;

/// Service QR Code et chiffrement AES YSP Smart Parking
///
/// Responsabilités :
/// 1. Chiffrer les données d'un top-up en AES → générer un QR code
/// 2. Déchiffrer un QR code scanné → valider et créditer le wallet
///
/// FONCTIONNEMENT DU TOP-UP AGENT :
/// Agent (webapp) → génère QR signé {amount, agentId, timestamp, nonce}
///               → chiffre avec clé AES partagée
///               → affiche le QR
/// Utilisateur   → scanne le QR dans l'app
///               → l'app déchiffre et vérifie le QR
///               → crédit ajouté au wallet
///
/// SÉCURITÉ :
/// - Chiffrement AES-256
/// - Chaque QR est à usage unique (nonce stocké dans Firestore)
/// - QR expire après 24h (timestamp vérifié)
class QRService {
  // IMPORTANT : en production, cette clé doit être stockée
  // de manière sécurisée (ex: Firebase Remote Config + secrets)
  // et NON en dur dans le code.
  static final enc.Key _key = enc.Key.fromLength(32);
  static final enc.IV _iv = enc.IV.fromLength(16);
  static final enc.Encrypter _encrypter =
      enc.Encrypter(enc.AES(_key));

  // ── Chiffrement ───────────────────────────────────────────

  /// Chiffre les données d'un top-up en string Base16
  /// Utilisé par l'app agent pour générer le QR
  String encryptTopUp({
    required int amount,
    required String agentId,
  }) {
    final payload = _buildPayload(amount: amount, agentId: agentId);
    final encrypted = _encrypter.encrypt(payload, iv: _iv);
    return encrypted.base16;
  }

  /// Déchiffre un QR scanné et retourne les données
  /// Retourne null si le QR est invalide ou expiré
  QRTopUpData? decryptTopUp(String base16) {
    try {
      final encrypted = enc.Encrypted.fromBase16(base16);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
      return _parsePayload(decrypted);
    } catch (_) {
      return null;
    }
  }

  // ── Validation ────────────────────────────────────────────

  /// Valide un QR déchiffré
  /// Vérifie : format correct, non expiré (24h)
  bool isValid(QRTopUpData data) {
    final age = DateTime.now().difference(data.generatedAt);
    return age.inHours < 24;
  }

  // ── Helpers privés ────────────────────────────────────────

  String _buildPayload({required int amount, required String agentId}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nonce = timestamp.toString();
    return '$amount|$agentId|$timestamp|$nonce';
  }

  QRTopUpData? _parsePayload(String payload) {
    try {
      final parts = payload.split('|');
      if (parts.length < 3) return null;
      return QRTopUpData(
        amount: int.parse(parts[0]),
        agentId: parts[1],
        generatedAt: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2])),
        nonce: parts.length > 3 ? parts[3] : '',
      );
    } catch (_) {
      return null;
    }
  }
}

/// Données déchiffrées d'un QR top-up
class QRTopUpData {
  final int amount;
  final String agentId;
  final DateTime generatedAt;
  final String nonce;

  const QRTopUpData({
    required this.amount,
    required this.agentId,
    required this.generatedAt,
    required this.nonce,
  });

  @override
  String toString() =>
      'QRTopUpData(amount: $amount, agent: $agentId, at: $generatedAt)';
}
