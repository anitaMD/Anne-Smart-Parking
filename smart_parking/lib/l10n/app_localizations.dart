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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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

  ///
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

  /// Register screen title - step 1
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get registerTitle;

  /// Register screen title - step 2
  ///
  /// In en, this message translates to:
  /// **'PMR Card'**
  String get registerCardStepTitle;

  /// Step indicator label - info step
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get registerStepInfo;

  /// Step indicator label - card step
  ///
  /// In en, this message translates to:
  /// **'PMR Card'**
  String get registerStepCard;

  /// Profile picture upload hint
  ///
  /// In en, this message translates to:
  /// **'Profile picture (optional)'**
  String get registerProfilePictureOptional;

  /// Full name validation error
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get registerNameRequired;

  /// Full name format validation error
  ///
  /// In en, this message translates to:
  /// **'Enter your first and last name'**
  String get registerNameFull;

  /// Phone number validation error
  ///
  /// In en, this message translates to:
  /// **'Phone number required'**
  String get registerPhoneRequired;

  /// Phone number length validation error
  ///
  /// In en, this message translates to:
  /// **'Number too short'**
  String get registerPhoneTooShort;

  /// Phone number validation failed (parsed but invalid)
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number.'**
  String get phoneInvalidNumber;

  /// Phone number could not be parsed (wrong format)
  ///
  /// In en, this message translates to:
  /// **'Invalid number format.'**
  String get phoneInvalidFormat;

  /// Password uppercase requirement
  ///
  /// In en, this message translates to:
  /// **'At least one uppercase letter'**
  String get registerPasswordUppercase;

  /// Password digit requirement
  ///
  /// In en, this message translates to:
  /// **'At least one digit'**
  String get registerPasswordDigit;

  /// Card upload section title
  ///
  /// In en, this message translates to:
  /// **'Upload your card'**
  String get registerUploadCardTitle;

  /// Card preview hint text
  ///
  /// In en, this message translates to:
  /// **'Your card should look like this:'**
  String get registerCardLooksLike;

  /// Card front side label
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get registerCardRecto;

  /// Card back side label
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get registerCardVerso;

  /// Final register submit button
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get registerSubmit;

  /// Email already taken error
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get registerEmailAlreadyUsed;

  /// Phone already taken error
  ///
  /// In en, this message translates to:
  /// **'This number is already linked to an account.'**
  String get registerPhoneAlreadyUsed;

  /// Card upload required error
  ///
  /// In en, this message translates to:
  /// **'Please upload both sides of your card.'**
  String get registerCardRequired;

  /// Ce parking est fermé. Choisissez une autre date.
  ///
  /// In en, this message translates to:
  /// **'This parking is closed. Please select another date.'**
  String get parkingClosedToday;

  /// Solde insuffisant pour effectuer ce rechargement
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance to complete this top up.'**
  String get agentInsufficientBalance;

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

  /// Login screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginWelcomeSubtitle;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Email required'**
  String get loginEmailRequired;

  /// Email format error
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get loginEmailInvalid;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get loginPasswordRequired;

  /// Password length error
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get loginPasswordMinLength;

  /// Google sign in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginWithGoogle;

  /// Password reset success
  ///
  /// In en, this message translates to:
  /// **'Reset email sent!'**
  String get loginResetEmailSent;

  /// Reset email required
  ///
  /// In en, this message translates to:
  /// **'Enter your email to reset your password.'**
  String get loginResetEmailRequired;

  /// Sign up link
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get loginSignUp;

  /// Offline banner
  ///
  /// In en, this message translates to:
  /// **'No Internet connection'**
  String get connectivityOffline;

  /// Separator between login methods
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// Dashboard section title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// Profile section
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get dashboardProfile;

  /// Wallet section
  ///
  /// In en, this message translates to:
  /// **'YSP Wallet'**
  String get dashboardWallet;

  /// Notifications section
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get dashboardNotifications;

  /// Settings section
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get dashboardSettings;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get dashboardLogout;

  /// Greeting on dashboard
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get dashboardHello;

  /// Dashboard subtitle
  ///
  /// In en, this message translates to:
  /// **'Find and book your parking spot'**
  String get dashboardSubtitle;

  /// Ongoing booking section
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get dashboardOngoingBooking;

  /// Nearby parkings section
  ///
  /// In en, this message translates to:
  /// **'Available parkings'**
  String get dashboardNearbyParkings;

  /// No parkings available
  ///
  /// In en, this message translates to:
  /// **'No parking available'**
  String get dashboardNoParkings;

  /// Navigate button
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get dashboardNavigate;

  /// My bookings section
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get dashboardMyBookings;

  /// Parking spot label
  ///
  /// In en, this message translates to:
  /// **'Spot'**
  String get dashboardSpot;

  /// Time left label
  ///
  /// In en, this message translates to:
  /// **'Time left'**
  String get dashboardTimeLeft;

  /// Wallet coin name
  ///
  /// In en, this message translates to:
  /// **'YSP Coin'**
  String get walletYspCoin;

  /// Wallet portfolio label
  ///
  /// In en, this message translates to:
  /// **'YSP Wallet'**
  String get walletPortfolio;

  /// Favorite parkings tab
  ///
  /// In en, this message translates to:
  /// **'My Favourites'**
  String get panelFavParkings;

  /// No favorite parkings
  ///
  /// In en, this message translates to:
  /// **'No favourite parking yet'**
  String get panelNoFavParkings;

  /// Default vehicle section
  ///
  /// In en, this message translates to:
  /// **'Default vehicle'**
  String get dashboardDefaultVehicle;

  /// Upcoming booking
  ///
  /// In en, this message translates to:
  /// **'Upcoming booking'**
  String get dashboardUpcomingBooking;

  /// No booking title
  ///
  /// In en, this message translates to:
  /// **'No booking yet'**
  String get dashboardNoBooking;

  /// No booking subtitle
  ///
  /// In en, this message translates to:
  /// **'Tap to see available parkings'**
  String get dashboardNoBookingSubtitle;

  /// Swipe hint on map
  ///
  /// In en, this message translates to:
  /// **'↑ Swipe up to see parkings'**
  String get dashboardSwipeForParkings;

  /// Bookings section title in drawer
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get dashboardBookings;

  /// Button to see all bookings/vehicles
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get dashboardVoirTout;

  /// Button to see parkings map
  ///
  /// In en, this message translates to:
  /// **'See map'**
  String get dashboardVoirCarte;

  /// Default vehicle section title on dashboard
  ///
  /// In en, this message translates to:
  /// **'Current vehicle'**
  String get dashboardCurrentVehicle;

  /// Message when no vehicle
  ///
  /// In en, this message translates to:
  /// **'No vehicle added'**
  String get dashboardNoVehicle;

  /// Subtitle when no vehicle
  ///
  /// In en, this message translates to:
  /// **'Add your vehicle to book.'**
  String get dashboardNoVehicleSubtitle;

  /// Favorite parkings section title
  ///
  /// In en, this message translates to:
  /// **'My favorite parkings'**
  String get dashboardFavorites;

  /// Message when no favorites
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get dashboardNoFavorite;

  /// Subtitle when no favorites
  ///
  /// In en, this message translates to:
  /// **'Make bookings to see your favorite parkings.'**
  String get dashboardNoFavoriteSubtitle;

  /// Vehicle selection modal title
  ///
  /// In en, this message translates to:
  /// **'My vehicles'**
  String get dashboardMyVehicles;

  /// Tap/swipe hint in vehicle list
  ///
  /// In en, this message translates to:
  /// **'Tap = select • Double tap = set as default'**
  String get dashboardVehicleHint;

  /// Add vehicle button
  ///
  /// In en, this message translates to:
  /// **'Add a vehicle'**
  String get dashboardAddVehicle;

  /// Parking full status
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get dashboardFull;

  /// Check availability button for favorite parking
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get dashboardCheckAvailability;

  /// Loader during availability check
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get dashboardChecking;

  /// Book button in favorites
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get dashboardBook;

  /// Cancel booking dialog title
  ///
  /// In en, this message translates to:
  /// **'Cancel booking?'**
  String get dashboardCancelBooking;

  /// Cancel booking confirmation message
  ///
  /// In en, this message translates to:
  /// **'Do you really want to cancel the booking for spot {spotId}?'**
  String dashboardCancelConfirm(String spotId);

  /// Generic confirmation button
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// Generic cancel button
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// Next step
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// Add vehicle screen title
  ///
  /// In en, this message translates to:
  /// **'Add a vehicle'**
  String get vehicleAddTitle;

  /// Edit vehicle screen title
  ///
  /// In en, this message translates to:
  /// **'Edit vehicle'**
  String get vehicleEditTitle;

  /// Vehicle add success message
  ///
  /// In en, this message translates to:
  /// **'Vehicle added successfully!'**
  String get vehicleAddSuccess;

  /// Vehicle edit success message
  ///
  /// In en, this message translates to:
  /// **'Vehicle updated successfully!'**
  String get vehicleEditSuccess;

  /// Plate preview section
  ///
  /// In en, this message translates to:
  /// **'Plate preview'**
  String get vehiclePlatePreview;

  /// Vehicle type section
  ///
  /// In en, this message translates to:
  /// **'Vehicle type'**
  String get vehicleType;

  /// Brand section
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get vehicleBrand;

  /// Vehicle information section
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get vehicleInfo;

  /// Model field
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get vehicleModel;

  /// Model field placeholder
  ///
  /// In en, this message translates to:
  /// **'Ex: C-Class, Corolla, Clio...'**
  String get vehicleModelHint;

  /// Model field empty error
  ///
  /// In en, this message translates to:
  /// **'Model required'**
  String get vehicleModelRequired;

  /// Vehicle color section
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get vehicleColor;

  /// License plate field
  ///
  /// In en, this message translates to:
  /// **'License plate'**
  String get vehiclePlate;

  /// Plate placeholder
  ///
  /// In en, this message translates to:
  /// **'Ex: DAK-1234-2024'**
  String get vehiclePlateHint;

  /// Plate empty error
  ///
  /// In en, this message translates to:
  /// **'Plate required'**
  String get vehiclePlateRequired;

  /// Invalid plate format error
  ///
  /// In en, this message translates to:
  /// **'Invalid format. Ex: DAK-1234-2024'**
  String get vehiclePlateInvalid;

  /// Vehicle year field
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get vehicleYear;

  /// Year placeholder
  ///
  /// In en, this message translates to:
  /// **'Ex: 2020'**
  String get vehicleYearHint;

  /// Year empty error
  ///
  /// In en, this message translates to:
  /// **'Year required'**
  String get vehicleYearRequired;

  /// Invalid year error
  ///
  /// In en, this message translates to:
  /// **'Invalid year'**
  String get vehicleYearInvalid;

  /// Registration country section
  ///
  /// In en, this message translates to:
  /// **'Registration country'**
  String get vehicleCountry;

  /// Country selection placeholder
  ///
  /// In en, this message translates to:
  /// **'Select a country'**
  String get vehicleCountryHint;

  /// Country not selected error
  ///
  /// In en, this message translates to:
  /// **'Country required'**
  String get vehicleCountryRequired;

  /// Registration city section
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get vehicleCity;

  /// City selection placeholder
  ///
  /// In en, this message translates to:
  /// **'Select a city'**
  String get vehicleCityHint;

  /// Save vehicle button
  ///
  /// In en, this message translates to:
  /// **'Save vehicle'**
  String get vehicleSave;

  /// Brand not selected error
  ///
  /// In en, this message translates to:
  /// **'Please select a brand.'**
  String get vehicleBrandRequired;

  /// Country not selected validation error
  ///
  /// In en, this message translates to:
  /// **'Please select a country.'**
  String get vehicleCountrySelectRequired;

  /// No spot selected error
  ///
  /// In en, this message translates to:
  /// **'Please select a spot'**
  String get bookingSelectSpotError;

  /// No date chosen error
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get bookingSelectDateError;

  /// No vehicle selected error
  ///
  /// In en, this message translates to:
  /// **'Please select a vehicle'**
  String get bookingSelectVehicleError;

  /// Step2 message without vehicle
  ///
  /// In en, this message translates to:
  /// **'Select a vehicle in the previous step'**
  String get bookingNoVehicleStep;

  /// Solde insuffisant. Rechargez votre wallet YSP.
  ///
  /// In en, this message translates to:
  /// **'Unsufficient balance. Recharge your YSP wallet.'**
  String get bookingInsufficientBalance;

  /// Confirm edit booking button
  ///
  /// In en, this message translates to:
  /// **'Confirm changes'**
  String get bookingConfirmEdit;

  /// Confirm new booking button
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get bookingConfirmNew;

  /// Step 1 label
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get bookingStepParking;

  /// Step 2 label
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get bookingStepSummary;

  /// Vehicle label in summary
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get bookingVehicle;

  /// Parking label in summary
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get bookingParking;

  /// Spot label in summary
  ///
  /// In en, this message translates to:
  /// **'Spot'**
  String get bookingSpot;

  /// Address label in summary
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get bookingAddress;

  /// Date label in summary
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get bookingDate;

  /// Booking start time label
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get bookingStart;

  /// Booking end time label
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get bookingEnd;

  /// Booking duration label
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get bookingDuration;

  /// Original cost label in edit mode
  ///
  /// In en, this message translates to:
  /// **'Original cost'**
  String get bookingOriginalCost;

  /// Supplement label in edit mode
  ///
  /// In en, this message translates to:
  /// **'Supplement'**
  String get bookingSupplement;

  /// Current wallet balance label
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get bookingCurrentBalance;

  /// Balance after debit label
  ///
  /// In en, this message translates to:
  /// **'Balance after'**
  String get bookingBalanceAfter;

  /// Total booking cost label
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get bookingCost;

  /// Reduced duration no refund message
  ///
  /// In en, this message translates to:
  /// **'Reduced duration — initial cost kept, no refund.'**
  String get bookingReducedDuration;

  /// Unchanged booking price
  ///
  /// In en, this message translates to:
  /// **'Unchanged '**
  String get bookingPriceUnchanged;

  /// Spots grid scroll hint
  ///
  /// In en, this message translates to:
  /// **'Scroll through the grid to see all available spots.'**
  String get bookingSlideHint;

  /// Dismiss hint button
  ///
  /// In en, this message translates to:
  /// **'DON\'T SHOW AGAIN'**
  String get bookingSlideHintDismiss;

  /// Glissez pour changer de véhicule
  ///
  /// In en, this message translates to:
  /// **'Swipe to scroll through vehicles'**
  String get bookingVehicleSwapSlideHint;

  /// Message before slot selection
  ///
  /// In en, this message translates to:
  /// **'Choose a time slot to see spot availability.'**
  String get bookingSelectTimeSlot;

  /// Titre time slot
  ///
  /// In en, this message translates to:
  /// **'Select time slot'**
  String get bookingSelectTimeSlotTitle;

  /// Titre spot
  ///
  /// In en, this message translates to:
  /// **'Select spot'**
  String get bookingSelectSpotTitle;

  /// Titre date
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get bookingSelectDateTitle;

  /// Titre vehicle
  ///
  /// In en, this message translates to:
  /// **'Select vehicle'**
  String get bookingSelectVehicleTitle;

  /// Titre vehicle
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get bookingSpotEntry;

  /// Titre vehicle
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get bookingSpotExit;

  /// Range picker start label
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get bookingFrom;

  /// Range picker end label
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get bookingTo;

  /// Occupied spot
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get bookingSpotOccupied;

  /// Occupied spot
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get bookingSpotFree;

  /// Range picker start label
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get bookingSpotReserved;

  /// Accessible parking for disabled ACC
  ///
  /// In en, this message translates to:
  /// **'Accessible'**
  String get bookingSpotForDisabled;

  /// When user has no registered vehicle
  ///
  /// In en, this message translates to:
  /// **'No registered vehicle — add one from your profil'**
  String get bookingUserHasNoVehicle;

  /// L'item sélectionné
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get bookingItemSelected;

  /// Ongoing status badge
  ///
  /// In en, this message translates to:
  /// **'ONGOING'**
  String get bookingStatusOngoing;

  /// Canceled status badge
  ///
  /// In en, this message translates to:
  /// **'CANCELED'**
  String get bookingStatusCanceled;

  /// Done status badge
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get bookingStatusDone;

  /// Upcoming edited status badge
  ///
  /// In en, this message translates to:
  /// **'UPCOMING · EDITED'**
  String get bookingStatusUpcomingEdited;

  /// Upcoming status badge
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get bookingStatusUpcoming;

  /// Edited badge on card
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get bookingEdited;

  /// Spot label with ID
  ///
  /// In en, this message translates to:
  /// **'Spot {spotId}'**
  String bookingSpotLabel(String spotId);

  /// Cancel dialog title
  ///
  /// In en, this message translates to:
  /// **'Cancel booking?'**
  String get bookingCancelTitle;

  /// Cancel dialog message
  ///
  /// In en, this message translates to:
  /// **'Spot {spotId} — {date}\n\nNo refund will be issued.'**
  String bookingCancelContent(String spotId, String date);

  /// All bookings filter
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get bookingFilterAll;

  /// Ongoing bookings filter
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get bookingFilterOngoing;

  /// Upcoming bookings filter
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get bookingFilterUpcoming;

  /// Past bookings filter
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get bookingFilterPast;

  /// Canceled bookings filter
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get bookingFilterCanceled;

  /// Edit booking button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get bookingEditAction;

  /// Cancel booking button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bookingCancelAction;

  /// Confirm cancel button
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get bookingConfirmCancelYes;

  /// New booking success message
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed successfully!'**
  String get bookingSuccessNew;

  /// Edit booking success message
  ///
  /// In en, this message translates to:
  /// **'Booking updated successfully!'**
  String get bookingSuccessEdit;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String bookingErrorGeneric(String message);

  /// Parkings screen title
  ///
  /// In en, this message translates to:
  /// **'Parkings'**
  String get parkingTitle;

  /// Parking search placeholder
  ///
  /// In en, this message translates to:
  /// **'Name or address...'**
  String get parkingSearchHint;

  /// Number of parkings found (singular)
  ///
  /// In en, this message translates to:
  /// **'{count} parking found'**
  String parkingFound(int count);

  /// Number of parkings found (plural)
  ///
  /// In en, this message translates to:
  /// **'{count} parkings found'**
  String parkingsFound(int count);

  /// No parking found message
  ///
  /// In en, this message translates to:
  /// **'No parking found'**
  String get parkingNoneFound;

  /// Regular spots label
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get parkingNormal;

  /// PMR spots label
  ///
  /// In en, this message translates to:
  /// **'PMR'**
  String get parkingPMR;

  /// Total spots label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get parkingTotal;

  /// Available spots label
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get parkingAvailable;

  /// Parking marker legend on map
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get parkingLegendParking;

  /// Selected parking marker legend
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get parkingLegendSelected;

  /// Légende marqueur parking sélectionné
  ///
  /// In en, this message translates to:
  /// **'My position'**
  String get parkingLegendMyPosition;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Language section
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// French language option
  ///
  /// In en, this message translates to:
  /// **'🇫🇷  Français'**
  String get settingsLangFr;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'🇬🇧  English'**
  String get settingsLangEn;

  /// Notifications section
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// All notifications toggle
  ///
  /// In en, this message translates to:
  /// **'All notifications'**
  String get settingsNotifAll;

  /// All notifications toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Enable or disable all reminders'**
  String get settingsNotifAllSubtitle;

  /// 30min before reminder toggle
  ///
  /// In en, this message translates to:
  /// **'30min before booking'**
  String get settingsNotif30min;

  /// 30min reminder subtitle
  ///
  /// In en, this message translates to:
  /// **'Early reminder'**
  String get settingsNotif30minSubtitle;

  /// 10min before reminder toggle
  ///
  /// In en, this message translates to:
  /// **'10min before booking start'**
  String get settingsNotif10min;

  /// 10min reminder subtitle
  ///
  /// In en, this message translates to:
  /// **'Urgent reminder'**
  String get settingsNotif10minSubtitle;

  /// Booking start notif toggle
  ///
  /// In en, this message translates to:
  /// **'!  Booking start'**
  String get settingsNotifStart;

  /// Booking start notif subtitle
  ///
  /// In en, this message translates to:
  /// **'When your slot begins'**
  String get settingsNotifStartSubtitle;

  /// 15min before end reminder toggle
  ///
  /// In en, this message translates to:
  /// **'15min before end'**
  String get settingsNotifEnd;

  /// End reminder subtitle
  ///
  /// In en, this message translates to:
  /// **'Imminent end reminder'**
  String get settingsNotifEndSubtitle;

  /// Notifications screen title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No notifications message
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmpty;

  /// Mark all notifications as read button
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// Snooze reminder label
  ///
  /// In en, this message translates to:
  /// **'Snooze reminder'**
  String get notificationsSnooze;

  /// Booking confirmed notification title
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed!'**
  String get notifBookingConfirmedTitle;

  /// Booking confirmed notification body
  ///
  /// In en, this message translates to:
  /// **'Spot {spotId} — {parkingName}'**
  String notifBookingConfirmedBody(String spotId, String parkingName);

  /// 30min before reminder title
  ///
  /// In en, this message translates to:
  /// **'⏰ Parking reminder'**
  String get notifReminder30min;

  /// 10min before reminder title
  ///
  /// In en, this message translates to:
  /// **'🚗 Almost time! Spot {spotId}'**
  String notifReminder10min(String spotId);

  /// Booking start notification title
  ///
  /// In en, this message translates to:
  /// **'✅ Active booking — Spot {spotId}'**
  String notifReminderStart(String spotId);

  /// 15min before end reminder title
  ///
  /// In en, this message translates to:
  /// **'⚠️ Ending in 15min — Spot {spotId}'**
  String notifReminderEnd(String spotId);

  /// Snooze option in minutes
  ///
  /// In en, this message translates to:
  /// **'In {minutes} minutes'**
  String notifSnoozeMinutes(int minutes);

  /// Snooze confirmation message
  ///
  /// In en, this message translates to:
  /// **'Reminder snoozed for {minutes} minutes'**
  String notifSnoozed(int minutes);

  /// No notifications subtitle
  ///
  /// In en, this message translates to:
  /// **'Your reminders and alerts will appear here'**
  String get notificationsEmptySubtitle;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// Save profile button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// Photo success message
  ///
  /// In en, this message translates to:
  /// **'Photo updated !'**
  String get profilePhotoUpdated;

  /// PMR card upload success message with side
  ///
  /// In en, this message translates to:
  /// **'{side} card uploaded !'**
  String profileCardUploaded(String side);

  /// Error message prefix
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String profileErrorPrefix(String message);

  /// Change email dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit email'**
  String get profileChangeEmail;

  /// New email field label
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get profileNewEmail;

  /// Email verification dialog title
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get profileVerifyEmail;

  /// Email verification dialog content
  ///
  /// In en, this message translates to:
  /// **'A verification link has been sent to {email}.\n\nClick the link BEFORE logging in again to confirm your new email.'**
  String profileVerifyEmailContent(String email);

  /// Sign out to verify email button
  ///
  /// In en, this message translates to:
  /// **'OK, sign out'**
  String get profileLogoutToVerify;

  /// Change phone dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit phone'**
  String get profileChangePhone;

  /// New phone number field label
  ///
  /// In en, this message translates to:
  /// **'New number'**
  String get profileNewPhone;

  /// Send OTP SMS button
  ///
  /// In en, this message translates to:
  /// **'Send SMS'**
  String get profileSendSms;

  /// SMS sending in progress message
  ///
  /// In en, this message translates to:
  /// **'Sending SMS...'**
  String get profileSendingSms;

  /// SMS code dialog title
  ///
  /// In en, this message translates to:
  /// **'SMS Code'**
  String get profileSmsCode;

  /// SMS code sent message
  ///
  /// In en, this message translates to:
  /// **'Code sent to {phone}'**
  String profileSmsCodeContent(String phone);

  /// Verify SMS code button
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get profileVerifySms;

  /// Personal information section
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get profilePersonalInfo;

  /// Full name label
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileFullName;

  /// Email label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// Phone label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhone;

  /// PMR card section
  ///
  /// In en, this message translates to:
  /// **'Disability Card (PMR)'**
  String get profilePmrCard;

  /// PMR section description
  ///
  /// In en, this message translates to:
  /// **'Upload your disability card to access PMR spots.'**
  String get profilePmrDescription;

  /// PMR enabled status
  ///
  /// In en, this message translates to:
  /// **'PMR access enabled !'**
  String get profilePmrEnabled;

  /// PMR disabled status
  ///
  /// In en, this message translates to:
  /// **'PMR access not enabled — upload your card'**
  String get profilePmrDisabled;

  /// PMR card front label
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get profilePmrRecto;

  /// PMR card back label
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get profilePmrVerso;

  /// Tap to change PMR card photo hint
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get profilePmrTapChange;

  /// Tap to upload PMR card hint
  ///
  /// In en, this message translates to:
  /// **'Tap to upload'**
  String get profilePmrTapUpload;

  /// Profile update success message
  ///
  /// In en, this message translates to:
  /// **'Profile updated !'**
  String get profileUpdated;

  /// Phone update success message
  ///
  /// In en, this message translates to:
  /// **'Phone updated !'**
  String get profilePhoneUpdated;

  /// Generic confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// Generic cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// SMS not sent error message
  ///
  /// In en, this message translates to:
  /// **'SMS not sent'**
  String get profileSmsNotSent;

  /// Phone automatically verified by Firebase message
  ///
  /// In en, this message translates to:
  /// **'Phone automatically verified !'**
  String get profilePhoneAutoVerified;

  /// OTP SMS code field label
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get profileSmsCodeLabel;

  /// Invalid OTP code error
  ///
  /// In en, this message translates to:
  /// **'Invalid code: {message}'**
  String profileInvalidCode(String message);

  /// Wallet screen title
  ///
  /// In en, this message translates to:
  /// **'My YSP Wallet'**
  String get walletTitle;

  /// QR code button in AppBar
  ///
  /// In en, this message translates to:
  /// **'My QR Code'**
  String get walletQrButton;

  /// Wallet balance label
  ///
  /// In en, this message translates to:
  /// **'YSP Coin Balance'**
  String get walletBalance;

  /// YSP portfolio label
  ///
  /// In en, this message translates to:
  /// **'YSP Portfolio'**
  String get walletPortfolioLabel;

  /// Transaction history section title
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get walletHistory;

  /// QR code bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'My recharge QR Code'**
  String get walletQrTitle;

  /// QR code bottom sheet subtitle
  ///
  /// In en, this message translates to:
  /// **'Show this code to a YSP agent to top up your wallet'**
  String get walletQrSubtitle;

  /// Label under QR code in wallet card
  ///
  /// In en, this message translates to:
  /// **'Scan to\nrecharge'**
  String get walletQrScanToRecharge;

  /// ID copied to clipboard message
  ///
  /// In en, this message translates to:
  /// **'ID copied!'**
  String get walletIdCopied;

  /// Booking transaction label
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get walletTransactionBooking;

  /// Top up transaction label
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get walletTransactionTopUp;

  /// Top up source agent
  ///
  /// In en, this message translates to:
  /// **' (Agent)'**
  String get walletTopUpAgent;

  /// Top up source QR code
  ///
  /// In en, this message translates to:
  /// **' (QR Code)'**
  String get walletTopUpQr;

  /// Top up source online
  ///
  /// In en, this message translates to:
  /// **' (Online)'**
  String get walletTopUpOnline;

  /// Balance after transaction label
  ///
  /// In en, this message translates to:
  /// **'Balance: {balance} SPM'**
  String walletBalanceLabel(int balance);

  /// No transactions message
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get walletNoTransactions;

  /// No transactions subtitle
  ///
  /// In en, this message translates to:
  /// **'Your debits and top ups will appear here'**
  String get walletNoTransactionsSubtitle;

  /// Agent dashboard title
  ///
  /// In en, this message translates to:
  /// **'YSP Agent'**
  String get agentDashboardTitle;

  /// Scanner AppBar title
  ///
  /// In en, this message translates to:
  /// **'Scan client'**
  String get agentScanTitle;

  /// Top up AppBar title
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get agentTopUpTitle;

  /// YSP Agent badge in header
  ///
  /// In en, this message translates to:
  /// **'YSP Agent'**
  String get agentBadge;

  /// New scan button tooltip
  ///
  /// In en, this message translates to:
  /// **'New scan'**
  String get agentNewScan;

  /// Agent wallet balance
  ///
  /// In en, this message translates to:
  /// **'My balance: {balance} SPM'**
  String agentMyBalance(int balance);

  /// Today stat label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get agentToday;

  /// Total stat label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get agentTotal;

  /// Scan client button
  ///
  /// In en, this message translates to:
  /// **'Scan a client'**
  String get agentScanClient;

  /// Recent top ups section title
  ///
  /// In en, this message translates to:
  /// **'Recent top ups'**
  String get agentRecentTopUps;

  /// No top ups message
  ///
  /// In en, this message translates to:
  /// **'No top ups yet'**
  String get agentNoTopUps;

  /// Client identified after scan
  ///
  /// In en, this message translates to:
  /// **'Client identified'**
  String get agentClientIdentified;

  /// Client current balance
  ///
  /// In en, this message translates to:
  /// **'Current balance: {balance} SPM'**
  String agentClientBalance(int balance);

  /// Top up amount field label
  ///
  /// In en, this message translates to:
  /// **'Amount to credit (SPM)'**
  String get agentAmountLabel;

  /// Scan another client button
  ///
  /// In en, this message translates to:
  /// **'Scan another client'**
  String get agentScanAnother;

  /// User not found error
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get agentUserNotFound;

  /// Invalid amount error
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get agentInvalidAmount;

  /// New balance after top up
  ///
  /// In en, this message translates to:
  /// **'New balance: {balance} SPM'**
  String agentNewBalance(int balance);

  /// Client label in details
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get agentClient;

  /// Client new balance label in details
  ///
  /// In en, this message translates to:
  /// **'Client new balance'**
  String get agentClientNewBalance;

  /// Generic agent name
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get agentTitle;

  /// Credited amount with + sign
  ///
  /// In en, this message translates to:
  /// **'+{amount} SPM'**
  String agentAmountCredited(int amount);

  /// Top up received notification body
  ///
  /// In en, this message translates to:
  /// **'You received {amount} SPM. New balance: {newBalance} SPM.'**
  String notifTopUpBody(int amount, int newBalance);

  /// Booking confirmed notification body
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed — Spot {spotId}'**
  String notifBookingConfirmed(String spotId);

  /// Message succès rechargement
  ///
  /// In en, this message translates to:
  /// **'Top up successful!'**
  String get agentSuccess;

  /// Message confirmer rechargement
  ///
  /// In en, this message translates to:
  /// **'Confirm top up !'**
  String get agentConfirm;

  /// Generic OK button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Message and action when no vehicle in stepper
  ///
  /// In en, this message translates to:
  /// **'No vehicle — tap to add one'**
  String get bookingNoVehicleAdd;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
