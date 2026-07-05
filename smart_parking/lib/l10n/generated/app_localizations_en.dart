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
  String get registerTitle => 'Create an account';

  @override
  String get registerCardStepTitle => 'PMR Card';

  @override
  String get registerStepInfo => 'Info';

  @override
  String get registerStepCard => 'PMR Card';

  @override
  String get registerProfilePictureOptional => 'Profile picture (optional)';

  @override
  String get registerNameRequired => 'Name required';

  @override
  String get registerNameFull => 'Enter your first and last name';

  @override
  String get registerPhoneRequired => 'Phone number required';

  @override
  String get registerPhoneTooShort => 'Number too short';

  @override
  String get phoneInvalidNumber => 'Invalid phone number.';

  @override
  String get phoneInvalidFormat => 'Invalid number format.';

  @override
  String get registerPasswordUppercase => 'At least one uppercase letter';

  @override
  String get registerPasswordDigit => 'At least one digit';

  @override
  String get registerUploadCardTitle => 'Upload your card';

  @override
  String get registerCardLooksLike => 'Your card should look like this:';

  @override
  String get registerCardRecto => 'Front';

  @override
  String get registerCardVerso => 'Back';

  @override
  String get registerSubmit => 'Sign up';

  @override
  String get registerEmailAlreadyUsed => 'This email is already in use.';

  @override
  String get registerPhoneAlreadyUsed =>
      'This number is already linked to an account.';

  @override
  String get registerCardRequired => 'Please upload both sides of your card.';

  @override
  String get noParkingSpotSelected =>
      'As you have not selected a specific parking spot, you will be assigned a random available one.';

  @override
  String get creatingBooking => 'Registering Your Booking ...';

  @override
  String get selectLanguage => 'Select the app language';

  @override
  String get loginWelcomeSubtitle => 'Sign in to continue';

  @override
  String get loginEmailRequired => 'Email required';

  @override
  String get loginEmailInvalid => 'Invalid email format';

  @override
  String get loginPasswordRequired => 'Password required';

  @override
  String get loginPasswordMinLength => 'Minimum 8 characters';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get loginResetEmailSent => 'Reset email sent!';

  @override
  String get loginResetEmailRequired =>
      'Enter your email to reset your password.';

  @override
  String get loginSignUp => 'Sign up';

  @override
  String get connectivityOffline => 'No Internet connection';

  @override
  String get or => 'or';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardProfile => 'Profile';

  @override
  String get dashboardWallet => 'YSP Wallet';

  @override
  String get dashboardNotifications => 'Notifications';

  @override
  String get dashboardSettings => 'Settings';

  @override
  String get dashboardLogout => 'Logout';

  @override
  String get dashboardHello => 'Hello';

  @override
  String get dashboardSubtitle => 'Find and book your parking spot';

  @override
  String get dashboardOngoingBooking => 'Bookings';

  @override
  String get dashboardNearbyParkings => 'Available parkings';

  @override
  String get dashboardNoParkings => 'No parking available';

  @override
  String get dashboardNavigate => 'Navigate';

  @override
  String get dashboardMyBookings => 'My bookings';

  @override
  String get dashboardSpot => 'Spot';

  @override
  String get dashboardTimeLeft => 'Time left';

  @override
  String get walletYspCoin => 'YSP Coin';

  @override
  String get walletPortfolio => 'YSP Wallet';

  @override
  String get panelFavParkings => 'My Favourites';

  @override
  String get panelNoFavParkings => 'No favourite parking yet';

  @override
  String get dashboardDefaultVehicle => 'Default vehicle';

  @override
  String get dashboardUpcomingBooking => 'Upcoming booking';

  @override
  String get dashboardNoBooking => 'No booking yet';

  @override
  String get dashboardNoBookingSubtitle => 'Tap to see available parkings';

  @override
  String get dashboardSwipeForParkings => '↑ Swipe up to see parkings';
}
