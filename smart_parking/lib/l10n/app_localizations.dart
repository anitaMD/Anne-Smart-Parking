import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// The currrent Language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please check your network connectivity!'**
  String get noInternetError;

  /// Login Welcome Text
  ///
  /// In en, this message translates to:
  /// **'Welcome to Your Smart Parking!'**
  String get welcomeToApp;

  /// Login to account text
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account.'**
  String get login;

  /// User email field label
  ///
  /// In en, this message translates to:
  /// **'Your Email'**
  String get loginEmailLabel;

  /// Email field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get loginEmailPlaceholder;

  /// Password field placeholder
  ///
  /// In en, this message translates to:
  /// **'Your Password'**
  String get loginPasswordLabel;

  /// Password placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordPlaceholder;

  /// Password forgotten
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// Sign in button label
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signin;

  /// No account label text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccount;

  /// Create account button label
  ///
  /// In en, this message translates to:
  /// **'Create now!'**
  String get createAccount;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please check email format.'**
  String get logErrorBadEmailFormat;

  ///
  ///
  /// In en, this message translates to:
  /// **'Email or password incorrect!'**
  String get logIncorrectEmailOrPass;

  /// Register form full name label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get regFullNameLabel;

  /// Register form full name placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get regFullNamePlaceholder;

  /// Register form email label
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get regEmailLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get regEmailPlaceholder;

  ///
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get regNumberLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Enter your number'**
  String get regNumberPlaceholder;

  ///
  ///
  /// In en, this message translates to:
  /// **'Invalid number format.'**
  String get regNumberError;

  ///
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get regPasswordLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get regPasswordPlaceholder;

  ///
  ///
  /// In en, this message translates to:
  /// **'At least 8 [uppercase, number, symbol].'**
  String get regPasswordHelper;

  ///
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get regConfirmPassLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Check password format'**
  String get regConfirmPassError;

  ///
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get regConfirmPassPlaceholder;

  ///
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get regPasswordsNoMatch;

  ///
  ///
  /// In en, this message translates to:
  /// **'De you have an Equality Of Chances card?'**
  String get regEgaliteDesChances;

  ///
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get regRadioYes;

  /// No description provided for @regRadioNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get regRadioNo;

  ///
  ///
  /// In en, this message translates to:
  /// **'This card concerns you if you have a significant loss of autonomy (disability) and allows you to benefit from rights and advantages in terms of transportation, access to health care, rehabilitation, technical and financial assistance, education, etc. It is issued by the Ministry of Social Action on the proposal of departmental technical commissions.'**
  String get regEgaliteChancesDescription;

  ///
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get regNextButton;

  ///
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  ///
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get regGoToLogInLink;

  ///
  ///
  /// In en, this message translates to:
  /// **'Auth Completed!'**
  String get otpAuthCompleted;

  ///
  ///
  /// In en, this message translates to:
  /// **'Auth Failed'**
  String get otpAuthFailed;

  ///
  ///
  /// In en, this message translates to:
  /// **'OTP Sent!'**
  String get otpCodeSent;

  ///
  ///
  /// In en, this message translates to:
  /// **'Timeout!'**
  String get otpCodeRetrievalTimeout;

  ///
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get numVerifHeader;

  ///
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code we just sent to'**
  String get numVerifBody;

  ///
  ///
  /// In en, this message translates to:
  /// **'If you didn\'t receive a code, '**
  String get numVerifDidntReceiveCode;

  ///
  ///
  /// In en, this message translates to:
  /// **'Resend!'**
  String get numVerifResendCode;

  ///
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get numVerifButtonLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please re-submit the recto part of your card!'**
  String get scanCECrectoError;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please re-submit the verso part of your card!'**
  String get scanCECversoError;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please re-submit both recto and verso parts of your card!'**
  String get scanCECbothRectoVersoError;

  /// The user is asked if he wants to continue the booking without selecting a parking spot.
  ///
  /// In en, this message translates to:
  /// **'As you have not selected a specific parking spot, you will be assigned a random available one.'**
  String get noParkingSpotSelected;

  /// The user's booking is being processed.
  ///
  /// In en, this message translates to:
  /// **'Registering Your Booking ...'**
  String get creatingBooking;

  /// Select App Language
  ///
  /// In en, this message translates to:
  /// **'Select the app language'**
  String get selectLanguage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
