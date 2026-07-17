import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/viewmodels/auth_viewmodel.dart';
import '../mocks/mock_auth_service.dart';
import '../mocks/mock_firestore_service.dart';

/// Tests unitaires — AuthNotifier.registerWithEmailAndPhone
///
/// Couvre le flow d'inscription complet (sans photo ni carte PMR,
/// pour éviter tout appel réel à StorageService/Cloudinary) : création
/// du compte Firebase Auth, création du profil + wallet Firestore,
/// puis envoi de l'OTP de vérification du numéro.

class _FakeRegisterAuthService extends MockAuthService {
  final bool shouldFailRegister;
  final bool shouldFailOtp;

  _FakeRegisterAuthService({
    this.shouldFailRegister = false,
    this.shouldFailOtp = false,
  });

  @override
  Future<({String? uid, String? error})> registerWithEmail({
    required String email,
    required String password,
  }) async {
    if (shouldFailRegister) {
      return (uid: null, error: 'Cet email est déjà utilisé.');
    }
    return (uid: 'new-user-uid', error: null);
  }

  @override
  Future<String?> sendOTP({required String phoneNumber}) async {
    if (shouldFailOtp) return 'ERROR:Numéro invalide.';
    return 'mock-verification-id';
  }
}

class _FakeRegisterFirestoreService extends MockFirestoreService {
  final List<String> createdUserIds = [];
  final List<String> createdWalletIds = [];

  @override
  Future<void> createUser(user) async {
    createdUserIds.add(user.id);
  }

  @override
  Future<void> createWallet(String uid) async {
    createdWalletIds.add(uid);
  }
}

ProviderContainer _makeContainer({
  required _FakeRegisterAuthService authService,
  required _FakeRegisterFirestoreService firestoreService,
}) {
  return ProviderContainer(overrides: [
    authServiceProvider.overrideWithValue(authService),
    firestoreServiceProvider.overrideWithValue(firestoreService),
  ]);
}

void main() {
  group('AuthNotifier — registerWithEmailAndPhone (succès)', () {
    test('crée le profil, le wallet, puis envoie l\'OTP → AuthOTPSent',
        () async {
      final authService = _FakeRegisterAuthService();
      final firestoreService = _FakeRegisterFirestoreService();
      final container = _makeContainer(
        authService: authService,
        firestoreService: firestoreService,
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).registerWithEmailAndPhone(
            fullName: 'Anne Marie',
            email: 'nouvelle@ysp.com',
            password: 'Password1!',
            phoneNumber: '+221770000002',
            hasEqualityCard: false,
          );

      final state = container.read(authProvider);
      expect(state, isA<AuthOTPSent>());
      expect((state as AuthOTPSent).phoneNumber, '+221770000002');
      expect(firestoreService.createdUserIds, contains('new-user-uid'));
      expect(firestoreService.createdWalletIds, contains('new-user-uid'));
    });

    test(
        'le profil créé a role="user" et isSpecialAccessUser=false'
        ' sans carte PMR', () async {
      final authService = _FakeRegisterAuthService();
      final firestoreService = _FakeRegisterFirestoreService();
      final container = _makeContainer(
        authService: authService,
        firestoreService: firestoreService,
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).registerWithEmailAndPhone(
            fullName: 'Test User',
            email: 'test2@ysp.com',
            password: 'Password1!',
            phoneNumber: '+221770000003',
            hasEqualityCard: false,
          );

      expect(container.read(authProvider), isA<AuthOTPSent>());
    });
  });

  group('AuthNotifier — registerWithEmailAndPhone (erreurs)', () {
    test('email déjà utilisé → AuthError sans créer de profil', () async {
      final authService = _FakeRegisterAuthService(shouldFailRegister: true);
      final firestoreService = _FakeRegisterFirestoreService();
      final container = _makeContainer(
        authService: authService,
        firestoreService: firestoreService,
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).registerWithEmailAndPhone(
            fullName: 'Test',
            email: 'existant@ysp.com',
            password: 'Password1!',
            phoneNumber: '+221770000004',
            hasEqualityCard: false,
          );

      final state = container.read(authProvider);
      expect(state, isA<AuthError>());
      expect(firestoreService.createdUserIds, isEmpty,
          reason: 'Aucun profil ne doit être créé si l\'inscription '
              'Firebase Auth échoue');
    });

    test('échec envoi OTP après création réussie → AuthError', () async {
      final authService = _FakeRegisterAuthService(shouldFailOtp: true);
      final firestoreService = _FakeRegisterFirestoreService();
      final container = _makeContainer(
        authService: authService,
        firestoreService: firestoreService,
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).registerWithEmailAndPhone(
            fullName: 'Test',
            email: 'test3@ysp.com',
            password: 'Password1!',
            phoneNumber: '+221000000000',
            hasEqualityCard: false,
          );

      final state = container.read(authProvider);
      expect(state, isA<AuthError>());
      // Le profil ET le wallet ont déjà été créés avant l'échec OTP
      expect(firestoreService.createdUserIds, isNotEmpty);
    });
  });
}
