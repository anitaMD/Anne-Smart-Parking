// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'English';

  @override
  String get noInternetError => 'Please check your network connectivity!';

  @override
  String get welcomeToApp => 'Welcome to Your Smart Parking!';

  @override
  String get login => 'Sign in to your account.';

  @override
  String get loginEmailLabel => 'Your Email';

  @override
  String get loginEmailPlaceholder => 'Enter your email';

  @override
  String get loginPasswordLabel => 'Your Password';

  @override
  String get loginPasswordPlaceholder => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get signin => 'Sign in';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get createAccount => 'Create now!';

  @override
  String get logErrorBadEmailFormat => 'Please check email format.';

  @override
  String get logIncorrectEmailOrPass => 'Email or password incorrect!';

  @override
  String get regFullNameLabel => 'Full Name';

  @override
  String get regFullNamePlaceholder => 'Enter your full name';

  @override
  String get regEmailLabel => 'E-mail';

  @override
  String get regEmailPlaceholder => 'Enter your email';

  @override
  String get regNumberLabel => 'Phone Number';

  @override
  String get regNumberPlaceholder => 'Enter your number';

  @override
  String get regNumberError => 'Invalid number format.';

  @override
  String get regPasswordLabel => 'Password';

  @override
  String get regPasswordPlaceholder => 'Enter your password';

  @override
  String get regPasswordHelper => 'At least 8 [uppercase, number, symbol].';

  @override
  String get regConfirmPassLabel => 'Confirm Password';

  @override
  String get regConfirmPassError => 'Check password format';

  @override
  String get regConfirmPassPlaceholder => 'Re-enter your password';

  @override
  String get regPasswordsNoMatch => 'Passwords don\'t match.';

  @override
  String get regEgaliteDesChances => 'De you have an Equality Of Chances card?';

  @override
  String get regRadioYes => 'Yes';

  @override
  String get regRadioNo => 'No';

  @override
  String get regEgaliteChancesDescription =>
      'This card concerns you if you have a significant loss of autonomy (disability) and allows you to benefit from rights and advantages in terms of transportation, access to health care, rehabilitation, technical and financial assistance, education, etc. It is issued by the Ministry of Social Action on the proposal of departmental technical commissions.';

  @override
  String get regNextButton => 'Next';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get regGoToLogInLink => 'Sign In';

  @override
  String get otpAuthCompleted => 'Auth Completed!';

  @override
  String get otpAuthFailed => 'Auth Failed';

  @override
  String get otpCodeSent => 'OTP Sent!';

  @override
  String get otpCodeRetrievalTimeout => 'Timeout!';

  @override
  String get numVerifHeader => 'Verification';

  @override
  String get numVerifBody => 'Enter the verification code we just sent to';

  @override
  String get numVerifDidntReceiveCode => 'If you didn\'t receive a code, ';

  @override
  String get numVerifResendCode => 'Resend!';

  @override
  String get numVerifButtonLabel => 'Verify';

  @override
  String get scanCECrectoError =>
      'Please re-submit the recto part of your card!';

  @override
  String get scanCECversoError =>
      'Please re-submit the verso part of your card!';

  @override
  String get scanCECbothRectoVersoError =>
      'Please re-submit both recto and verso parts of your card!';

  @override
  String get noParkingSpotSelected =>
      'As you have not selected a specific parking spot, you will be assigned a random available one.';

  @override
  String get creatingBooking => 'Registering Your Booking ...';

  @override
  String get selectLanguage => 'Select the app language';
}
