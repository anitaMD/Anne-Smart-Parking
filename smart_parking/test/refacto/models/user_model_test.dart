import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/app/models/user_model.dart';

/// Tests unitaires — UserModel
///
/// Couvre la logique métier utilisée dans le dashboard (firstName,
/// initials avatar) et le routing agent/user (role) qui a causé
/// plusieurs bugs corrigés en session (agent redirigé vers
/// AgentScreen dès le premier build).

UserModel _makeUser({
  String fullName = 'Anne Marie Diallo',
  String role = 'user',
  bool isSpecialAccessUser = false,
  List<String> equalityCardPaths = const [],
  String profileImageUrl = '',
}) {
  return UserModel(
    id: 'uid-1',
    fullName: fullName,
    email: 'test@ysp.com',
    phoneNumber: '+221774880377',
    profileImageUrl: profileImageUrl,
    isSpecialAccessUser: isSpecialAccessUser,
    role: role,
    equalityCardPaths: equalityCardPaths,
  );
}

void main() {
  group('UserModel — firstName', () {
    test('extrait le premier mot d\'un nom complet', () {
      final user = _makeUser(fullName: 'Anne Marie Diallo');
      expect(user.firstName, 'Anne');
    });

    test('fonctionne avec un nom composé d\'un seul mot', () {
      final user = _makeUser(fullName: 'Anita');
      expect(user.firstName, 'Anita');
    });
  });

  group('UserModel — initials', () {
    test('prend la première lettre des deux premiers mots', () {
      final user = _makeUser(fullName: 'Anne Marie Diallo');
      expect(user.initials, 'AM');
    });

    test('gère un nom composé d\'un seul mot — une seule lettre', () {
      final user = _makeUser(fullName: 'Anita');
      expect(user.initials, 'A');
    });

    test('retourne "?" quand le nom est vide', () {
      final user = _makeUser(fullName: '');
      expect(user.initials, '?');
    });

    test('met les initiales en majuscules même si saisi en minuscules', () {
      final user = _makeUser(fullName: 'anne marie');
      expect(user.initials, 'AM');
    });
  });

  group('UserModel — hasProfileImage', () {
    test('retourne false quand profileImageUrl est vide', () {
      final user = _makeUser(profileImageUrl: '');
      expect(user.hasProfileImage, isFalse);
    });

    test('retourne true quand profileImageUrl est renseignée', () {
      final user =
          _makeUser(profileImageUrl: 'https://cloudinary.com/photo.jpg');
      expect(user.hasProfileImage, isTrue);
    });
  });

  group('UserModel — role (routing agent/user)', () {
    test('un utilisateur normal a le role "user"', () {
      final user = _makeUser(role: 'user');
      expect(user.role, 'user');
    });

    test('un agent a le role "agent"', () {
      final user = _makeUser(role: 'agent');
      expect(user.role, 'agent');
    });
  });

  group('UserModel — copyWith', () {
    test('met à jour fullName sans affecter les autres champs', () {
      final original = _makeUser(fullName: 'Ancien Nom');
      final updated = original.copyWith(fullName: 'Nouveau Nom');

      expect(updated.fullName, 'Nouveau Nom');
      expect(updated.id, original.id);
      expect(updated.email, original.email);
      expect(updated.role, original.role);
    });

    test('conserve isSpecialAccessUser si non modifié', () {
      final original = _makeUser(isSpecialAccessUser: true);
      final updated = original.copyWith(fullName: 'Test');

      expect(updated.isSpecialAccessUser, isTrue);
    });

    test('met à jour equalityCardPaths (upload carte PMR)', () {
      final original = _makeUser(equalityCardPaths: []);
      final updated = original.copyWith(
        equalityCardPaths: ['recto.jpg', 'verso.jpg'],
        isSpecialAccessUser: true,
      );

      expect(updated.equalityCardPaths.length, 2);
      expect(updated.isSpecialAccessUser, isTrue);
    });
  });

  group('UserModel — toString', () {
    test('inclut l\'id et le nom complet', () {
      final user = _makeUser(fullName: 'Anne Marie Diallo');
      expect(user.toString(), contains('uid-1'));
      expect(user.toString(), contains('Anne Marie Diallo'));
    });
  });
}
