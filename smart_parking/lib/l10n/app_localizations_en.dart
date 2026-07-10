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
  String get regEgaliteChancesDescription => 'This card concerns you if you have a significant loss of autonomy (disability) and allows you to benefit from rights and advantages in terms of transportation, access to health care, rehabilitation, technical and financial assistance, education, etc. It is issued by the Ministry of Social Action on the proposal of departmental technical commissions.';

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
  String get scanCECrectoError => 'Please re-submit the recto part of your card!';

  @override
  String get scanCECversoError => 'Please re-submit the verso part of your card!';

  @override
  String get scanCECbothRectoVersoError => 'Please re-submit both recto and verso parts of your card!';

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
  String get registerPhoneAlreadyUsed => 'This number is already linked to an account.';

  @override
  String get registerCardRequired => 'Please upload both sides of your card.';

  @override
  String get noParkingSpotSelected => 'As you have not selected a specific parking spot, you will be assigned a random available one.';

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
  String get loginResetEmailRequired => 'Enter your email to reset your password.';

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

  @override
  String get dashboardBookings => 'My Bookings';

  @override
  String get dashboardVoirTout => 'See all';

  @override
  String get dashboardVoirCarte => 'See map';

  @override
  String get dashboardCurrentVehicle => 'Current vehicle';

  @override
  String get dashboardNoVehicle => 'No vehicle added';

  @override
  String get dashboardNoVehicleSubtitle => 'Add your vehicle to book.';

  @override
  String get dashboardFavorites => 'My favorite parkings';

  @override
  String get dashboardNoFavorite => 'No favorites yet';

  @override
  String get dashboardNoFavoriteSubtitle => 'Make bookings to see your favorite parkings.';

  @override
  String get dashboardMyVehicles => 'My vehicles';

  @override
  String get dashboardVehicleHint => 'Tap = select • Double tap = set as default';

  @override
  String get dashboardAddVehicle => 'Add a vehicle';

  @override
  String get dashboardFull => 'Full';

  @override
  String get dashboardCheckAvailability => 'Availability';

  @override
  String get dashboardChecking => 'Checking...';

  @override
  String get dashboardBook => 'Book';

  @override
  String get dashboardCancelBooking => 'Cancel booking?';

  @override
  String dashboardCancelConfirm(String spotId) {
    return 'Do you really want to cancel the booking for spot $spotId?';
  }

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonNext => 'Next';

  @override
  String get vehicleAddTitle => 'Add a vehicle';

  @override
  String get vehicleEditTitle => 'Edit vehicle';

  @override
  String get vehicleAddSuccess => 'Vehicle added successfully!';

  @override
  String get vehicleEditSuccess => 'Vehicle updated successfully!';

  @override
  String get vehiclePlatePreview => 'Plate preview';

  @override
  String get vehicleType => 'Vehicle type';

  @override
  String get vehicleBrand => 'Brand';

  @override
  String get vehicleInfo => 'Information';

  @override
  String get vehicleModel => 'Model';

  @override
  String get vehicleModelHint => 'Ex: C-Class, Corolla, Clio...';

  @override
  String get vehicleModelRequired => 'Model required';

  @override
  String get vehicleColor => 'Color';

  @override
  String get vehiclePlate => 'License plate';

  @override
  String get vehiclePlateHint => 'Ex: DAK-1234-2024';

  @override
  String get vehiclePlateRequired => 'Plate required';

  @override
  String get vehiclePlateInvalid => 'Invalid format. Ex: DAK-1234-2024';

  @override
  String get vehicleYear => 'Year';

  @override
  String get vehicleYearHint => 'Ex: 2020';

  @override
  String get vehicleYearRequired => 'Year required';

  @override
  String get vehicleYearInvalid => 'Invalid year';

  @override
  String get vehicleCountry => 'Registration country';

  @override
  String get vehicleCountryHint => 'Select a country';

  @override
  String get vehicleCountryRequired => 'Country required';

  @override
  String get vehicleCity => 'City';

  @override
  String get vehicleCityHint => 'Select a city';

  @override
  String get vehicleSave => 'Save vehicle';

  @override
  String get vehicleBrandRequired => 'Please select a brand.';

  @override
  String get vehicleCountrySelectRequired => 'Please select a country.';

  @override
  String get bookingSelectSpotError => 'Please select a spot';

  @override
  String get bookingSelectDateError => 'Please select a date';

  @override
  String get bookingSelectVehicleError => 'Please select a vehicle';

  @override
  String get bookingNoVehicleStep => 'Select a vehicle in the previous step';

  @override
  String get bookingInsufficientBalance => 'Unsufficient balance. Recharge your YSP wallet.';

  @override
  String get bookingConfirmEdit => 'Confirm changes';

  @override
  String get bookingConfirmNew => 'Confirm booking';

  @override
  String get bookingStepParking => 'Parking';

  @override
  String get bookingStepSummary => 'Summary';

  @override
  String get bookingVehicle => 'Vehicle';

  @override
  String get bookingParking => 'Parking';

  @override
  String get bookingSpot => 'Spot';

  @override
  String get bookingAddress => 'Address';

  @override
  String get bookingDate => 'Date';

  @override
  String get bookingStart => 'Start';

  @override
  String get bookingEnd => 'End';

  @override
  String get bookingDuration => 'Duration';

  @override
  String get bookingOriginalCost => 'Original cost';

  @override
  String get bookingSupplement => 'Supplement';

  @override
  String get bookingCurrentBalance => 'Current balance';

  @override
  String get bookingBalanceAfter => 'Balance after';

  @override
  String get bookingCost => 'Cost';

  @override
  String get bookingReducedDuration => 'Reduced duration — initial cost kept, no refund.';

  @override
  String get bookingPriceUnchanged => 'Unchanged ';

  @override
  String get bookingSlideHint => 'Scroll through the grid to see all available spots.';

  @override
  String get bookingSlideHintDismiss => 'DON\'T SHOW AGAIN';

  @override
  String get bookingVehicleSwapSlideHint => 'Swipe to scroll through vehicles';

  @override
  String get bookingSelectTimeSlot => 'Choose a time slot to see spot availability.';

  @override
  String get bookingSelectTimeSlotTitle => 'Select time slot';

  @override
  String get bookingSelectSpotTitle => 'Select spot';

  @override
  String get bookingSelectDateTitle => 'Select date';

  @override
  String get bookingSelectVehicleTitle => 'Select vehicle';

  @override
  String get bookingSpotEntry => 'Entry';

  @override
  String get bookingSpotExit => 'Exit';

  @override
  String get bookingFrom => 'Start';

  @override
  String get bookingTo => 'End';

  @override
  String get bookingSpotOccupied => 'Occupied';

  @override
  String get bookingSpotFree => 'Free';

  @override
  String get bookingSpotReserved => 'Booked';

  @override
  String get bookingSpotForDisabled => 'Accessible';

  @override
  String get bookingUserHasNoVehicle => 'No registered vehicle — add one from your profil';

  @override
  String get bookingItemSelected => 'Selected';

  @override
  String get bookingStatusOngoing => 'ONGOING';

  @override
  String get bookingStatusCanceled => 'CANCELED';

  @override
  String get bookingStatusDone => 'DONE';

  @override
  String get bookingStatusUpcomingEdited => 'UPCOMING · EDITED';

  @override
  String get bookingStatusUpcoming => 'UPCOMING';

  @override
  String get bookingEdited => 'Edited';

  @override
  String bookingSpotLabel(String spotId) {
    return 'Spot $spotId';
  }

  @override
  String get bookingCancelTitle => 'Cancel booking?';

  @override
  String bookingCancelContent(String spotId, String date) {
    return 'Spot $spotId — $date\n\nNo refund will be issued.';
  }

  @override
  String get bookingFilterAll => 'All';

  @override
  String get bookingFilterOngoing => 'Ongoing';

  @override
  String get bookingFilterUpcoming => 'Upcoming';

  @override
  String get bookingFilterPast => 'Past';

  @override
  String get bookingFilterCanceled => 'Canceled';

  @override
  String get bookingEditAction => 'Edit';

  @override
  String get bookingCancelAction => 'Cancel';

  @override
  String get bookingConfirmCancelYes => 'Yes, cancel';

  @override
  String get bookingSuccessNew => 'Booking confirmed successfully!';

  @override
  String get bookingSuccessEdit => 'Booking updated successfully!';

  @override
  String bookingErrorGeneric(String message) {
    return 'Error: $message';
  }

  @override
  String get parkingTitle => 'Parkings';

  @override
  String get parkingSearchHint => 'Name or address...';

  @override
  String parkingFound(int count) {
    return '$count parking found';
  }

  @override
  String parkingsFound(int count) {
    return '$count parkings found';
  }

  @override
  String get parkingNoneFound => 'No parking found';

  @override
  String get parkingNormal => 'Regular';

  @override
  String get parkingPMR => 'PMR';

  @override
  String get parkingTotal => 'Total';

  @override
  String get parkingAvailable => 'Available';

  @override
  String get parkingLegendParking => 'Parking';

  @override
  String get parkingLegendSelected => 'Selected';

  @override
  String get parkingLegendMyPosition => 'My position';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLangFr => '🇫🇷  Français';

  @override
  String get settingsLangEn => '🇬🇧  English';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotifAll => 'All notifications';

  @override
  String get settingsNotifAllSubtitle => 'Enable or disable all reminders';

  @override
  String get settingsNotif30min => '30min before booking';

  @override
  String get settingsNotif30minSubtitle => 'Early reminder';

  @override
  String get settingsNotif10min => '10min before booking start';

  @override
  String get settingsNotif10minSubtitle => 'Urgent reminder';

  @override
  String get settingsNotifStart => '!  Booking start';

  @override
  String get settingsNotifStartSubtitle => 'When your slot begins';

  @override
  String get settingsNotifEnd => '15min before end';

  @override
  String get settingsNotifEndSubtitle => 'Imminent end reminder';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get profileSave => 'Save';

  @override
  String get profilePhotoUpdated => 'Photo updated !';

  @override
  String profileCardUploaded(String side) {
    return '$side card uploaded !';
  }

  @override
  String profileErrorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get profileChangeEmail => 'Edit email';

  @override
  String get profileNewEmail => 'New email';

  @override
  String get profileVerifyEmail => 'Verify your email';

  @override
  String profileVerifyEmailContent(String email) {
    return 'A verification link has been sent to $email.\n\nClick the link BEFORE logging in again to confirm your new email.';
  }

  @override
  String get profileLogoutToVerify => 'OK, sign out';

  @override
  String get profileChangePhone => 'Edit phone';

  @override
  String get profileNewPhone => 'New number';

  @override
  String get profileSendSms => 'Send SMS';

  @override
  String get profileSendingSms => 'Sending SMS...';

  @override
  String get profileSmsCode => 'SMS Code';

  @override
  String profileSmsCodeContent(String phone) {
    return 'Code sent to $phone';
  }

  @override
  String get profileVerifySms => 'Verify';

  @override
  String get profilePersonalInfo => 'Personal information';

  @override
  String get profileFullName => 'Full name';

  @override
  String get profileEmail => 'Email';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profilePmrCard => 'Disability Card (PMR)';

  @override
  String get profilePmrDescription => 'Upload your disability card to access PMR spots.';

  @override
  String get profilePmrEnabled => 'PMR access enabled !';

  @override
  String get profilePmrDisabled => 'PMR access not enabled — upload your card';

  @override
  String get profilePmrRecto => 'Front';

  @override
  String get profilePmrVerso => 'Back';

  @override
  String get profilePmrTapChange => 'Tap to change';

  @override
  String get profilePmrTapUpload => 'Tap to upload';

  @override
  String get profileUpdated => 'Profile updated !';

  @override
  String get profilePhoneUpdated => 'Phone updated !';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get profileSmsNotSent => 'SMS not sent';

  @override
  String get profilePhoneAutoVerified => 'Phone automatically verified !';

  @override
  String get profileSmsCodeLabel => '6-digit code';

  @override
  String profileInvalidCode(String message) {
    return 'Invalid code: $message';
  }

  @override
  String get walletTitle => 'My YSP Wallet';

  @override
  String get walletQrButton => 'My QR Code';

  @override
  String get walletBalance => 'YSP Coin Balance';

  @override
  String get walletPortfolioLabel => 'YSP Portfolio';

  @override
  String get walletHistory => 'Transaction history';

  @override
  String get walletQrTitle => 'My recharge QR Code';

  @override
  String get walletQrSubtitle => 'Show this code to a YSP agent to top up your wallet';

  @override
  String get walletQrScanToRecharge => 'Scan to\nrecharge';

  @override
  String get walletIdCopied => 'ID copied!';

  @override
  String get walletTransactionBooking => 'Booking';

  @override
  String get walletTransactionTopUp => 'Top up';

  @override
  String get walletTopUpAgent => ' (Agent)';

  @override
  String get walletTopUpQr => ' (QR Code)';

  @override
  String get walletTopUpOnline => ' (Online)';

  @override
  String walletBalanceLabel(int balance) {
    return 'Balance: $balance SPM';
  }

  @override
  String get walletNoTransactions => 'No transactions';

  @override
  String get walletNoTransactionsSubtitle => 'Your debits and top ups will appear here';
}
