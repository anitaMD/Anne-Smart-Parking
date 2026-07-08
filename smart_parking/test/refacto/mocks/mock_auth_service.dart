import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_parking/app/services/auth_service.dart';

/// Mock AuthService — zéro Firebase, zéro réseau
class MockAuthService implements AuthServiceBase {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  bool get isLoggedIn => false;

  @override
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (email == 'test@ysp.com' && password == 'Password1!') return null;
    return 'Email ou mot de passe incorrect.';
  }

  @override
  Future<({String? uid, String? error})> registerWithEmail({
    required String email,
    required String password,
  }) async =>
      (uid: 'mock-uid-123', error: null);

  @override
  Future<String?> sendOTP({required String phoneNumber}) async {
    if (phoneNumber == '+221774880377') return 'mock-verification-id';
    return 'ERROR:Numéro invalide.';
  }

  @override
  Future<({String? uid, String? error})> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    if (smsCode == '123456') return (uid: 'mock-uid-phone', error: null);
    return (uid: null, error: 'Code de vérification incorrect.');
  }

  @override
  Future<String?> sendPasswordResetEmail(String email) async {
    if (email.contains('@')) return null;
    return 'Format email invalide.';
  }

  @override
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    if (email == 'test@ysp.com') return ['password'];
    return [];
  }

  @override
  Future<bool> emailExistsInAuth(String email) async {
    // Simule : test@ysp.com existe dans Firebase Auth
    return email == 'test@ysp.com';
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateDisplayName(String name) async {}
}
