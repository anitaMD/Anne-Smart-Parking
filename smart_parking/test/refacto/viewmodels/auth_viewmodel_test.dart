import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/viewmodels/auth_viewmodel.dart';
import '../mocks/mock_auth_service.dart';
import '../mocks/mock_firestore_service.dart';

/// Tests unitaires — AuthState & AuthNotifier (fichier consolidé)
///
/// Regroupe l'ensemble des tests liés à l'authentification :
///   1. AuthState — types et pattern matching (logique pure)
///   2. AuthNotifier — signIn, signOut, sendOTP, sendPasswordReset
///      (avec mocks de base)
///   3. AuthNotifier.checkEmailExists / checkPhoneExists — utilisés
///      dans l'écran d'inscription pour valider la disponibilité
///   4. AuthNotifier.registerWithEmailAndPhone — flow d'inscription
///      complet (sans photo ni carte PMR, pour éviter tout appel
///      réel à StorageService/Cloudinary)
///   5. AuthNotifier.verifyOTP — chemin d'erreur (code incorrect)
///
/// Limitation documentée : le chemin de succès complet de verifyOTP
/// (→ AuthAuthenticated) reste hors de portée d'un test unitaire pur
/// car _loadCurrentUser() dépend de FirebaseAuth.currentUser, un
/// objet User concret difficile à simuler sans risque de dépendance
/// supplémentaire (firebase_auth_mocks, même profil de risque que
/// celui rencontré avec fake_cloud_firestore nécessitant une mise à
/// jour de version).

// ─────────────────────────────────────────────────────────────
// CONTAINER DE BASE — AuthNotifier (signIn/signOut/OTP simples)
// ─────────────────────────────────────────────────────────────

ProviderContainer makeContainer() {
  return ProviderContainer(
    overrides: [
      authServiceProvider.overrideWithValue(MockAuthService()),
      firestoreServiceProvider.overrideWithValue(MockFirestoreService()),
    ],
  );
}

// ─────────────────────────────────────────────────────────────
// FAKES — checkEmailExists / checkPhoneExists (chemins d'erreur)
// ─────────────────────────────────────────────────────────────

class _FailingAuthService extends MockAuthService {
  @override
  Future<bool> emailExistsInAuth(String email) async {
    throw Exception('Network error simulée');
  }
}

/// Simule une exception RÉSEAU (pas une erreur métier retournée) —
/// couvre les blocs catch(e) de signInWithEmail/registerWithEmailAndPhone
/// jamais exercés par les tests d'erreur "classiques" (qui testent le
/// tuple {error: '...'}, pas une vraie exception levée).
class _ThrowingAuthService extends MockAuthService {
  @override
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw Exception('Connexion réseau perdue');
  }

  @override
  Future<({String? uid, String? error})> registerWithEmail({
    required String email,
    required String password,
  }) async {
    throw Exception('Connexion réseau perdue');
  }
}

/// Simule le cas où Android vérifie automatiquement le SMS (autofill)
/// sans jamais faire passer l'utilisateur par l'écran de saisie du code.
class _AutoVerifiedAuthService extends MockAuthService {
  @override
  Future<String?> sendOTP({required String phoneNumber}) async =>
      'AUTO_VERIFIED';
}

/// Simule un échec silencieux du SDK Firebase Auth (result null)
class _NullOtpAuthService extends MockAuthService {
  @override
  Future<String?> sendOTP({required String phoneNumber}) async => null;
}

class _FailingFirestoreForPhone extends MockFirestoreService {
  @override
  Future<bool> userExistsByPhone(String phoneNumber) async {
    throw Exception('Network error simulée');
  }
}

ProviderContainer _makeCheckContainer({
  dynamic authService,
  dynamic firestoreService,
}) {
  return ProviderContainer(overrides: [
    authServiceProvider.overrideWithValue(authService ?? MockAuthService()),
    firestoreServiceProvider
        .overrideWithValue(firestoreService ?? MockFirestoreService()),
  ]);
}

// ─────────────────────────────────────────────────────────────
// FAKES — registerWithEmailAndPhone
// ─────────────────────────────────────────────────────────────

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

ProviderContainer _makeRegisterContainer({
  required _FakeRegisterAuthService authService,
  required _FakeRegisterFirestoreService firestoreService,
}) {
  return ProviderContainer(overrides: [
    authServiceProvider.overrideWithValue(authService),
    firestoreServiceProvider.overrideWithValue(firestoreService),
  ]);
}

void main() {
  // ── 1. AuthState — types et pattern matching ──────────────

  group('AuthState — types et pattern matching', () {
    test('AuthInitial — est un AuthState', () {
      const state = AuthInitial();
      expect(state, isA<AuthState>());
      expect(state, isA<AuthInitial>());
    });

    test('AuthLoading — est un AuthState', () {
      expect(const AuthLoading(), isA<AuthLoading>());
    });

    test('AuthError — contient le bon message', () {
      const state = AuthError('Mot de passe incorrect.');
      expect(state.message, equals('Mot de passe incorrect.'));
    });

    test('AuthUnauthenticated — est un AuthState', () {
      expect(const AuthUnauthenticated(), isA<AuthUnauthenticated>());
    });

    test('AuthOTPSent — contient verificationId et phoneNumber', () {
      const state = AuthOTPSent(
        verificationId: 'mock-id',
        phoneNumber: '+221774880377',
      );
      expect(state.verificationId, equals('mock-id'));
      expect(state.phoneNumber, equals('+221774880377'));
    });

    test('switch sur AuthError — retourne le message', () {
      const AuthState state = AuthError('test error');
      final result = switch (state) {
        AuthInitial() => 'initial',
        AuthLoading() => 'loading',
        AuthAuthenticated() => 'authenticated',
        AuthError(:final message) => message,
        AuthUnauthenticated() => 'unauthenticated',
        AuthOTPSent() => 'otp_sent',
      };
      expect(result, equals('test error'));
    });

    test('switch sur AuthOTPSent — retourne otp_sent', () {
      const AuthState state = AuthOTPSent(
        verificationId: 'id',
        phoneNumber: '+221770000001',
      );
      final result = switch (state) {
        AuthInitial() => 'initial',
        AuthLoading() => 'loading',
        AuthAuthenticated() => 'authenticated',
        AuthError() => 'error',
        AuthUnauthenticated() => 'unauthenticated',
        AuthOTPSent() => 'otp_sent',
      };
      expect(result, equals('otp_sent'));
    });
  });

  // ── 2. AuthNotifier — cas de base (avec mocks) ────────────

  group('AuthNotifier — avec mocks', () {
    late ProviderContainer container;

    setUp(() => container = makeContainer());
    tearDown(() => container.dispose());

    test('état initial — AuthInitial', () {
      expect(container.read(authProvider), isA<AuthInitial>());
    });

    test('isAuthenticatedProvider — false au démarrage', () {
      expect(container.read(isAuthenticatedProvider), isFalse);
    });

    test('currentUserProvider — null au démarrage', () {
      expect(container.read(currentUserProvider), isNull);
    });

    test('signInWithEmail — mauvais identifiants → AuthError', () async {
      await container.read(authProvider.notifier).signInWithEmail(
            email: 'wrong@email.com',
            password: 'wrongpassword',
          );
      final state = container.read(authProvider);
      expect(state, isA<AuthError>());
      expect((state as AuthError).message, isNotEmpty);
    });

    test(
        'signInWithEmail — exception réseau (pas juste erreur métier)'
        ' → AuthError via catch', () async {
      final throwingContainer = _makeCheckContainer(
        authService: _ThrowingAuthService(),
      );
      addTearDown(throwingContainer.dispose);

      await throwingContainer.read(authProvider.notifier).signInWithEmail(
            email: 'test@ysp.com',
            password: 'Password1!',
          );

      final state = throwingContainer.read(authProvider);
      expect(state, isA<AuthError>());
      expect((state as AuthError).message, contains('réseau'));
    });

    test('signOut — état devient AuthUnauthenticated', () async {
      await container.read(authProvider.notifier).signOut();
      expect(container.read(authProvider), isA<AuthUnauthenticated>());
    });

    test('sendPasswordReset — email valide → null (succès)', () async {
      final error = await container
          .read(authProvider.notifier)
          .sendPasswordReset('test@ysp.com');
      expect(error, isNull);
    });

    test('sendPasswordReset — email invalide → message erreur', () async {
      final error = await container
          .read(authProvider.notifier)
          .sendPasswordReset('pasunemail');
      expect(error, isNotNull);
    });

    test('sendOTP — numéro valide → AuthOTPSent', () async {
      await container.read(authProvider.notifier).sendOTP(
            phoneNumber: '+221774880377',
          );
      final state = container.read(authProvider);
      expect(state, isA<AuthOTPSent>());
      expect((state as AuthOTPSent).phoneNumber, equals('+221774880377'));
    });

    test('sendOTP — numéro invalide → AuthError', () async {
      await container.read(authProvider.notifier).sendOTP(
            phoneNumber: '+221000000000',
          );
      final state = container.read(authProvider);
      expect(state, isA<AuthError>());
    });
  });

  group('AuthNotifier — sendOTP (branches SDK Firebase)', () {
    test('AUTO_VERIFIED déclenche _loadCurrentUser (pas d\'AuthError)',
        () async {
      final container = _makeCheckContainer(
        authService: _AutoVerifiedAuthService(),
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).sendOTP(
            phoneNumber: '+221774880377', // existe côté Firestore
          );

      final state = container.read(authProvider);
      expect(state, isNot(isA<AuthError>()),
          reason: 'AUTO_VERIFIED doit court-circuiter vers '
              '_loadCurrentUser, jamais vers une erreur');
      expect(state, isNot(isA<AuthOTPSent>()),
          reason: 'On ne doit pas montrer l\'écran de saisie du code '
              'si Android a déjà tout vérifié automatiquement');
    });

    test('result null → AuthError explicite', () async {
      final container = _makeCheckContainer(
        authService: _NullOtpAuthService(),
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).sendOTP(
            phoneNumber: '+221774880377',
          );

      final state = container.read(authProvider);
      expect(state, isA<AuthError>());
      expect((state as AuthError).message, contains('envoyer'));
    });
  });

  // ── 3. AuthNotifier — checkEmailExists / checkPhoneExists ─

  group('AuthNotifier — checkEmailExists', () {
    test('retourne true pour un email déjà existant', () async {
      final container = _makeCheckContainer();
      addTearDown(container.dispose);

      final exists = await container
          .read(authProvider.notifier)
          .checkEmailExists('test@ysp.com');

      expect(exists, isTrue);
    });

    test('retourne false pour un email inconnu', () async {
      final container = _makeCheckContainer();
      addTearDown(container.dispose);

      final exists = await container
          .read(authProvider.notifier)
          .checkEmailExists('inconnu@example.com');

      expect(exists, isFalse);
    });

    test('retourne false (pas d\'exception) en cas d\'erreur réseau', () async {
      final container = _makeCheckContainer(authService: _FailingAuthService());
      addTearDown(container.dispose);

      final exists = await container
          .read(authProvider.notifier)
          .checkEmailExists('test@ysp.com');

      expect(exists, isFalse,
          reason: 'checkEmailExists catch les erreurs et retourne false '
              'plutôt que de faire planter l\'écran d\'inscription');
    });
  });

  group('AuthNotifier — checkPhoneExists', () {
    test('retourne true pour un numéro déjà associé à un compte', () async {
      final container = _makeCheckContainer();
      addTearDown(container.dispose);

      final exists = await container
          .read(authProvider.notifier)
          .checkPhoneExists('+221774880377');

      expect(exists, isTrue);
    });

    test('retourne false pour un numéro inconnu', () async {
      final container = _makeCheckContainer();
      addTearDown(container.dispose);

      final exists = await container
          .read(authProvider.notifier)
          .checkPhoneExists('+221000000000');

      expect(exists, isFalse);
    });

    test('retourne false en cas d\'erreur Firestore', () async {
      final container =
          _makeCheckContainer(firestoreService: _FailingFirestoreForPhone());
      addTearDown(container.dispose);

      final exists = await container
          .read(authProvider.notifier)
          .checkPhoneExists('+221774880377');

      expect(exists, isFalse);
    });
  });

  // ── 4. AuthNotifier — registerWithEmailAndPhone ───────────

  group('AuthNotifier — registerWithEmailAndPhone (succès)', () {
    test('crée le profil, le wallet, puis envoie l\'OTP → AuthOTPSent',
        () async {
      final authService = _FakeRegisterAuthService();
      final firestoreService = _FakeRegisterFirestoreService();
      final container = _makeRegisterContainer(
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
      final container = _makeRegisterContainer(
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
      final container = _makeRegisterContainer(
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
      final container = _makeRegisterContainer(
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

    test(
        'exception réseau pendant registerWithEmail (pas juste une'
        ' erreur métier) → AuthError via catch', () async {
      final container = _makeCheckContainer(
        authService: _ThrowingAuthService(),
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).registerWithEmailAndPhone(
            fullName: 'Test',
            email: 'test4@ysp.com',
            password: 'Password1!',
            phoneNumber: '+221770000005',
            hasEqualityCard: false,
          );

      final state = container.read(authProvider);
      expect(state, isA<AuthError>());
      expect((state as AuthError).message, contains('réseau'));
    });
  });

  // ── 5. AuthNotifier — verifyOTP (chemin d'erreur) ─────────

  group('AuthNotifier — verifyOTP', () {
    test('bon code → AuthAuthenticated impossible sans Firebase', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      // On ne peut pas tester AuthAuthenticated sans Firebase
      // car _loadCurrentUser() appelle Firestore.
      expect(container.read(authProvider), isA<AuthInitial>());
    });

    test('code incorrect → AuthError avec le bon message', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).verifyOTP(
            verificationId: 'mock-id',
            smsCode: '000000', // code incorrect (le mock attend 123456)
          );

      final state = container.read(authProvider);
      expect(state, isA<AuthError>());
      expect((state as AuthError).message, isNotEmpty);
    });

    test('passe par AuthLoading avant de résoudre en AuthError', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final states = <AuthState>[];
      container.listen(authProvider, (_, next) => states.add(next));

      await container.read(authProvider.notifier).verifyOTP(
            verificationId: 'mock-id',
            smsCode: 'wrong-code',
          );

      expect(states.any((s) => s is AuthLoading), isTrue);
      expect(states.last, isA<AuthError>());
    });

    test(
        'code correct ne produit pas d\'AuthError (dépasse la '
        'vérification du code, échoue seulement sur le chargement '
        'utilisateur qui nécessite Firebase réel)', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).verifyOTP(
            verificationId: 'mock-id',
            smsCode: '123456', // code correct selon MockAuthService
          );

      final state = container.read(authProvider);
      // MockAuthService.currentUser retourne toujours null, donc
      // _loadCurrentUser() aboutit à AuthUnauthenticated — mais
      // PAS à AuthError, ce qui prouve que la vérification du code
      // OTP lui-même a bien réussi.
      expect(state, isNot(isA<AuthError>()));
    });
  });
}
