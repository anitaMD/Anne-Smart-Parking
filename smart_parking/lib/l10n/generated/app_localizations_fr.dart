// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get language => 'Français';

  @override
  String get noInternetError => 'Vérifiez votre connexion internet!';

  @override
  String get welcomeToApp =>
      'Bienvenu dans votre application Your Smart Parking!';

  @override
  String get login => 'Connectez-vous à votre compte.';

  @override
  String get loginEmailLabel => 'E-mail';

  @override
  String get loginEmailPlaceholder => 'Saisissez votre email';

  @override
  String get loginPasswordLabel => 'Mot de passe';

  @override
  String get loginPasswordPlaceholder => 'Saisissez votre mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié?';

  @override
  String get signin => 'Se connecter';

  @override
  String get noAccount => 'Pas encore de compte? ';

  @override
  String get createAccount => 'Créez-en un!';

  @override
  String get logErrorBadEmailFormat => 'L\'email est mal formaté.';

  @override
  String get logIncorrectEmailOrPass => 'Email ou mot de passe incorrect!';

  @override
  String get regFullNameLabel => 'Prénom & Nom';

  @override
  String get regFullNamePlaceholder => 'Votre nom complet';

  @override
  String get regEmailLabel => 'E-mail';

  @override
  String get regEmailPlaceholder => 'Votre email';

  @override
  String get regNumberLabel => 'Téléphone';

  @override
  String get regNumberPlaceholder => 'Votre numéro de téléphone';

  @override
  String get regNumberError => 'Format incorrect.';

  @override
  String get regPasswordLabel => 'Mot de passe';

  @override
  String get regPasswordPlaceholder => 'Votre mot de passe';

  @override
  String get regPasswordHelper =>
      '*Au moins 8 char. [majuscule, chiffre, symbol]';

  @override
  String get regConfirmPassLabel => 'Confirmation';

  @override
  String get regConfirmPassError => 'Le mot de passe est mal formaté.';

  @override
  String get regConfirmPassPlaceholder => 'Confirmez mot de password';

  @override
  String get regPasswordsNoMatch => 'Les mots de passe ne correspondent pas.';

  @override
  String get regEgaliteDesChances =>
      'Possédez-vous la Carte d\'Egalité des Chances?';

  @override
  String get regRadioYes => 'Oui';

  @override
  String get regRadioNo => 'Non';

  @override
  String get regEgaliteChancesDescription =>
      'Cette carte vous concerne si vous avez une perte d\'autonomie importante (handicap) et vous permet de bénéficier de droits et avantages en matière de transport, d’accès aux soins de santé, de réadaptation, d’aide technique et financière, d’éducation, etc.Elle est délivrée par le Ministère chargé de l’Action sociale sur proposition des commissions techniques départementales.';

  @override
  String get regNextButton => 'Suivant';

  @override
  String get alreadyHaveAccount => 'Déjà inscrit? ';

  @override
  String get regGoToLogInLink => 'Connectez-vous!';

  @override
  String get otpAuthCompleted => 'Authentification réussie!';

  @override
  String get otpAuthFailed => 'L\'authentification a échoué';

  @override
  String get otpCodeSent => 'Code OTP envoyé!';

  @override
  String get otpCodeRetrievalTimeout => 'Timeout!';

  @override
  String get numVerifHeader => 'Vérification';

  @override
  String get numVerifBody => 'Saisissez le code de vérification envoyé au';

  @override
  String get numVerifDidntReceiveCode => 'Pas reçu de code? ';

  @override
  String get numVerifResendCode => 'Renvoyer code';

  @override
  String get numVerifButtonLabel => 'Vérifier';

  @override
  String get scanCECrectoError =>
      'Veuillez soumettre de nouveau la partie \'recto\' de votre carte!';

  @override
  String get scanCECversoError =>
      'Veuillez soumettre de nouveau la partie \'verso\' de votre carte!';

  @override
  String get scanCECbothRectoVersoError =>
      'Veuillez soumettre de nouveau les parties recto et verso de votre carte!';

  @override
  String get noParkingSpotSelected =>
      'Il semble que vous n\'avez pas sélectionné une place de parking. Il vous sera donc attribué une parmi celles présentement disponibles.';

  @override
  String get creatingBooking => 'Validation de votre réservation...';

  @override
  String get selectLanguage => 'Selectionner la langue par défaut.';
}
