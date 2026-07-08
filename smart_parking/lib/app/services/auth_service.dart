import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────
// INTERFACE
// ─────────────────────────────────────────────────────────────

abstract class AuthServiceBase {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  bool get isLoggedIn;

  Future<String?> signInWithEmail({
    required String email,
    required String password,
  });

  Future<({String? uid, String? error})> registerWithEmail({
    required String email,
    required String password,
  });

  Future<String?> sendOTP({required String phoneNumber});

  Future<({String? uid, String? error})> verifyOTP({
    required String verificationId,
    required String smsCode,
  });

  Future<String?> sendPasswordResetEmail(String email);
  Future<List<String>> fetchSignInMethodsForEmail(String email);
  Future<bool> emailExistsInAuth(String email);
  Future<void> signOut();
  Future<void> updateDisplayName(String name);
}

// ─────────────────────────────────────────────────────────────
// IMPLEMENTATION
// ─────────────────────────────────────────────────────────────

class AuthService implements AuthServiceBase {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  bool get isLoggedIn => _auth.currentUser != null;

  // ── Email / Mot de passe ──────────────────────────────────

  @override
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return 'Une erreur inattendue est survenue.';
    }
  }

  @override
  Future<({String? uid, String? error})> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return (uid: credential.user?.uid, error: null);
    } on FirebaseAuthException catch (e) {
      return (uid: null, error: _handleAuthError(e));
    } catch (e) {
      return (uid: null, error: 'Une erreur inattendue est survenue.');
    }
  }

  // ── Phone Auth ────────────────────────────────────────────

  /// Envoie un OTP au numéro donné
  /// Retourne le verificationId si succès
  /// Retourne 'ERROR:message' si erreur
  /// Retourne 'AUTO_VERIFIED' si Android a vérifié automatiquement
  ///
  /// BONNE PRATIQUE : Completer permet d'attendre un callback async
  /// sans polling ni Future.delayed arbitraire
  @override
  Future<String?> sendOTP({required String phoneNumber}) async {
    final completer = Completer<String?>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),

      // OTP envoyé avec succès — complète avec le verificationId
      codeSent: (String verificationId, int? resendToken) {
        debugPrint('[Auth] OTP envoyé — verificationId: $verificationId');
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },

      // Vérification automatique Android — Firebase lit le SMS seul
      verificationCompleted: (PhoneAuthCredential credential) async {
        debugPrint('[Auth] Vérification automatique Android');
        try {
          await _auth.signInWithCredential(credential);
          if (!completer.isCompleted) {
            completer.complete('AUTO_VERIFIED');
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.complete('ERROR:Erreur de vérification automatique.');
          }
        }
      },

      // Erreur — complète avec un message d'erreur préfixé ERROR:
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('[Auth] Erreur OTP: ${e.code} — ${e.message}');
        if (!completer.isCompleted) {
          completer.complete('ERROR:${_handleAuthError(e)}');
        }
      },

      // Timeout auto-retrieval — on complète quand même
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('[Auth] OTP auto-retrieval timeout');
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    return completer.future;
  }

  /// Vérifie le code OTP entré par l'utilisateur
  ///
  /// Deux cas :
  /// 1. INSCRIPTION — un user email/password est déjà connecté
  ///    → on LIE le numéro au compte existant (linkWithCredential)
  ///    → un seul compte Firebase avec email + téléphone
  ///
  /// 2. CONNEXION — pas de user connecté
  ///    → connexion directe par téléphone (signInWithCredential)
  ///    → le numéro étant lié au compte email, ça connecte le bon user
  @override
  Future<({String? uid, String? error})> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      if (_auth.currentUser != null) {
        // Cas 1 — INSCRIPTION : lier le téléphone au compte email
        debugPrint('[Auth] Liaison téléphone au compte existant');
        await _auth.currentUser!.linkWithCredential(credential);
        return (uid: _auth.currentUser!.uid, error: null);
      } else {
        // Cas 2 — CONNEXION : connexion par téléphone
        debugPrint('[Auth] Connexion par téléphone');
        final userCredential = await _auth.signInWithCredential(credential);
        return (uid: userCredential.user?.uid, error: null);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        return (uid: null, error: 'Ce numéro est déjà lié à un autre compte.');
      }
      if (e.code == 'provider-already-linked') {
        // Numéro déjà lié — pas une erreur bloquante
        debugPrint('[Auth] Numéro déjà lié au compte');
        return (uid: _auth.currentUser?.uid, error: null);
      }
      return (uid: null, error: _handleAuthError(e));
    } catch (e) {
      return (uid: null, error: 'Code invalide.');
    }
  }

  // ── Vérification email Firebase Auth ────────────────────────

  /// Vérifie si un email existe dans Firebase Auth
  /// en tentant une connexion avec un mauvais mot de passe.
  /// - 'wrong-password' / 'invalid-credential' → email EXISTS
  /// - 'user-not-found' → email FREE
  @override
  Future<bool> emailExistsInAuth(String email) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: '___TEMP_CHECK___',
      );
      // Connexion réussie (très improbable) → existe
      await _auth.signOut();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] emailExistsInAuth code: ${e.code}');
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'INVALID_LOGIN_CREDENTIALS') {
        return true; // email existe mais mauvais mot de passe
      }
      if (e.code == 'user-not-found') {
        return false; // email libre
      }
      return false;
    } catch (e) {
      debugPrint('[Auth] emailExistsInAuth error: $e');
      return false;
    }
  }

  // ── Réinitialisation mot de passe ─────────────────────────

  @override
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    }
  }

  @override
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    // NOTE : fetchSignInMethodsForEmail a été supprimé de Firebase Auth
    // récent pour des raisons de sécurité (énumération d'emails).
    // La vérification se fait maintenant via Firestore directement
    // dans FirestoreService.userExistsByEmail() — voir AuthNotifier.
    // Cette méthode reste pour compatibilité mais n'est plus utilisée.
    return [];
  }

  // ── Déconnexion ───────────────────────────────────────────

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  @override
  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  // ── Helpers ───────────────────────────────────────────────
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Identifiants incorrects.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'invalid-email':
        return 'Format email invalide.';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 8 caractères.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion.';
      case 'invalid-phone-number':
        return 'Numéro de téléphone invalide.';
      case 'invalid-verification-code':
        return 'Code de vérification incorrect.';
      case 'session-expired':
        return 'Le code a expiré. Veuillez en demander un nouveau.';
      default:
        return e.message ?? 'Une erreur est survenue.';
    }
  }
}
