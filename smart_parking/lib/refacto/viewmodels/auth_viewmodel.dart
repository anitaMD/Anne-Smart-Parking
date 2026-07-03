import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../services/storage_service.dart';

// ─────────────────────────────────────────────────────────────
// AUTH STATE
// ─────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthOTPSent extends AuthState {
  final String verificationId;
  final String phoneNumber;
  const AuthOTPSent({required this.verificationId, required this.phoneNumber});
}

// ─────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthServiceBase>(
  (ref) => AuthService(),
);

final firestoreServiceProvider = Provider<FirestoreServiceBase>(
  (ref) => FirestoreService() as FirestoreServiceBase,
);

// ─────────────────────────────────────────────────────────────
// AUTH VIEWMODEL
// ─────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  late AuthServiceBase _authService;
  late FirestoreServiceBase _firestoreService;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    _firestoreService = ref.read(firestoreServiceProvider);
    // Si user déjà connecté au démarrage, charger le profil
    if (_authService.currentUser != null) {
      Future.microtask(() => _loadCurrentUser());
    }
    return const AuthInitial();
  }

  // ── Email / Mot de passe ──────────────────────────────────

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    debugPrint('[Auth] signInWithEmail: $email');
    state = const AuthLoading();
    try {
      final error = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      if (error != null) {
        state = AuthError(error);
        return;
      }
      await _loadCurrentUser();
    } catch (e) {
      debugPrint('[Auth] Exception: $e');
      state = AuthError(e.toString());
    }
  }

  // ── Phone Auth — Étape 1 : envoyer OTP ───────────────────

  Future<void> sendOTP({required String phoneNumber}) async {
    debugPrint('[Auth] sendOTP: $phoneNumber');
    state = const AuthLoading();
    try {
      // 1. Vérifier si le numéro est associé à un compte existant
      final userExists = await _firestoreService.userExistsByPhone(phoneNumber);
      debugPrint('[Auth] userExistsByPhone($phoneNumber): $userExists');

      if (!userExists) {
        state = const AuthError(
          'Aucun compte associé à ce numéro. Veuillez vous inscrire.',
        );
        return;
      }

      // 2. Envoyer l'OTP seulement si le compte existe
      final result = await _authService.sendOTP(phoneNumber: phoneNumber);

      if (result == null) {
        state = const AuthError('Impossible d\'envoyer le code.');
        return;
      }

      // Si résultat commence par ERROR: c'est un message d'erreur
      if (result.startsWith('ERROR:')) {
        state = AuthError(result.substring(6));
        return;
      }

      // AUTO_VERIFIED — Android a vérifié automatiquement
      if (result == 'AUTO_VERIFIED') {
        await _loadCurrentUser();
        return;
      }

      // Succès — on passe à l'écran OTP
      state = AuthOTPSent(
        verificationId: result,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      debugPrint('[Auth] sendOTP error: $e');
      state = AuthError(e.toString());
    }
  }

  // ── Phone Auth — Étape 2 : vérifier OTP ──────────────────

  Future<void> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    debugPrint('[Auth] verifyOTP');
    state = const AuthLoading();
    try {
      final result = await _authService.verifyOTP(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      if (result.error != null) {
        state = AuthError(result.error!);
        return;
      }
      await _loadCurrentUser();
    } catch (e) {
      debugPrint('[Auth] verifyOTP error: $e');
      state = AuthError(e.toString());
    }
  }

  // ── Inscription complète ─────────────────────────────────

  Future<void> registerWithEmailAndPhone({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    File? profileImage,
    required bool hasEqualityCard,
    File? cardRecto,
    File? cardVerso,
  }) async {
    debugPrint('[Auth] registerWithEmailAndPhone: $email');
    state = const AuthLoading();
    try {
      // 1. Créer le compte Firebase Auth
      final result = await _authService.registerWithEmail(
        email: email,
        password: password,
      );
      if (result.error != null) {
        state = AuthError(result.error!);
        return;
      }

      final uid = result.uid!;
      final storageService = StorageService();
      String profileImageUrl = '';
      List<String> equalityCardPaths = [];

      // 2. Upload photo de profil si fournie
      if (profileImage != null) {
        final url = await storageService.uploadProfilePicture(
          file: profileImage,
          uid: uid,
        );
        if (url != null) profileImageUrl = url;
      }

      // 3. Upload carte PMR si fournie
      if (hasEqualityCard && cardRecto != null && cardVerso != null) {
        final rectoUrl = await storageService.uploadEqualityCard(
          file: cardRecto,
          uid: uid,
          side: 'recto',
        );
        final versoUrl = await storageService.uploadEqualityCard(
          file: cardVerso,
          uid: uid,
          side: 'verso',
        );
        if (rectoUrl != null) equalityCardPaths.add(rectoUrl);
        if (versoUrl != null) equalityCardPaths.add(versoUrl);
      }

      // 4. Créer le profil dans Firestore
      final newUser = UserModel(
        id: uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
        isSpecialAccessUser: hasEqualityCard,
        equalityCardPaths: equalityCardPaths,
      );
      await _firestoreService.createUser(newUser);
      await _firestoreService.createWallet(uid);
      debugPrint('[Auth] Profil créé — envoi OTP');

      // 5. Envoyer OTP pour vérifier le numéro
      final otpResult = await _authService.sendOTP(phoneNumber: phoneNumber);
      if (otpResult == null || otpResult.startsWith('ERROR:')) {
        state = AuthError(otpResult?.substring(6) ?? 'Erreur OTP');
        return;
      }

      state = AuthOTPSent(
        verificationId: otpResult,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      debugPrint('[Auth] registerWithEmailAndPhone error: $e');
      state = AuthError(e.toString());
    }
  }

  // ── Vérification disponibilité ───────────────────────────

  /// Vérifie si un email est déjà utilisé
  /// Utilisé dans RegisterScreen avant de passer à l'étape 2
  /// Vérification via Firestore (users_v2) — fiable et sans
  /// création de compte temporaire
  Future<bool> checkEmailExists(String email) async {
    try {
      // Vérification directe dans Firebase Auth
      // userExistsByEmail() ne vérifie que Firestore users_v2
      // ce qui peut manquer les comptes Auth sans document Firestore
      return await _authService.emailExistsInAuth(email);
    } catch (e) {
      debugPrint('[Auth] checkEmailExists error: $e');
      return false;
    }
  }

  /// Vérifie si un numéro est déjà associé à un compte
  Future<bool> checkPhoneExists(String phoneNumber) async {
    try {
      return await _firestoreService.userExistsByPhone(phoneNumber);
    } catch (e) {
      debugPrint('[Auth] checkPhoneExists error: $e');
      return false;
    }
  }

  // ── Mot de passe oublié ───────────────────────────────────

  Future<String?> sendPasswordReset(String email) async {
    return await _authService.sendPasswordResetEmail(email);
  }

  // ── Déconnexion ───────────────────────────────────────────

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthUnauthenticated();
  }

  // ── Chargement du profil ──────────────────────────────────

  Future<void> _loadCurrentUser() async {
    final currentUser = _authService.currentUser;
    debugPrint('[Auth] currentUser uid: ${currentUser?.uid}');

    if (currentUser == null) {
      state = const AuthUnauthenticated();
      return;
    }

    try {
      // Chargement parallèle user + wallet pour réduire le délai
      final results = await Future.wait([
        _firestoreService.getUser(currentUser.uid),
        _firestoreService.getWallet(currentUser.uid),
      ]);

      final user = results[0] as UserModel?;
      final wallet = results[1] as WalletModel?;
      debugPrint('[Auth] user: $user, wallet: $wallet');

      if (user != null) {
        // Créer wallet si absent (en arrière-plan, pas bloquant)
        if (wallet == null) {
          _firestoreService
              .createWallet(currentUser.uid)
              .then((_) => debugPrint('[Auth] Wallet créé en arrière-plan'));
        }
        state = AuthAuthenticated(user);
      } else {
        // Nouvel utilisateur — profil minimal
        final newUser = UserModel(
          id: currentUser.uid,
          fullName: currentUser.displayName ?? '',
          email: currentUser.email ?? '',
          phoneNumber: currentUser.phoneNumber ?? '',
          profileImageUrl: currentUser.photoURL ?? '',
          isSpecialAccessUser: false,
        );
        // Créer profil + wallet en parallèle
        await Future.wait([
          _firestoreService.createUser(newUser),
          _firestoreService.createWallet(currentUser.uid),
        ]);
        debugPrint('[Auth] Nouveau profil + wallet créés');
        state = AuthAuthenticated(newUser);
      }
    } catch (e) {
      debugPrint('[Auth] _loadCurrentUser error: $e');
      state = AuthError(e.toString());
    }
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDERS DÉRIVÉS
// ─────────────────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) return authState.user;
  return null;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthAuthenticated;
});
