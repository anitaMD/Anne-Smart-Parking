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
  String get welcomeToApp => 'Bienvenu dans votre application Your Smart Parking!';

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
  String get regPasswordHelper => '*Au moins 8 char. [majuscule, chiffre, symbol]';

  @override
  String get regConfirmPassLabel => 'Confirmation';

  @override
  String get regConfirmPassError => 'Le mot de passe est mal formaté.';

  @override
  String get regConfirmPassPlaceholder => 'Confirmez mot de password';

  @override
  String get regPasswordsNoMatch => 'Les mots de passe ne correspondent pas.';

  @override
  String get regEgaliteDesChances => 'Possédez-vous la Carte d\'Egalité des Chances?';

  @override
  String get regRadioYes => 'Oui';

  @override
  String get regRadioNo => 'Non';

  @override
  String get regEgaliteChancesDescription => 'Cette carte vous concerne si vous avez une perte d\'autonomie importante (handicap) et vous permet de bénéficier de droits et avantages en matière de transport, d\'accès aux soins de santé, de réadaptation, d\'aide technique et financière, d\'éducation, etc. Elle est délivrée par le Ministère chargé de l\'Action sociale sur proposition des commissions techniques départementales.';

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
  String get scanCECrectoError => 'Veuillez soumettre de nouveau la partie \'recto\' de votre carte!';

  @override
  String get scanCECversoError => 'Veuillez soumettre de nouveau la partie \'verso\' de votre carte!';

  @override
  String get scanCECbothRectoVersoError => 'Veuillez soumettre de nouveau les parties recto et verso de votre carte!';

  @override
  String get registerTitle => 'Créer un compte';

  @override
  String get registerCardStepTitle => 'Carte PMR';

  @override
  String get registerStepInfo => 'Infos';

  @override
  String get registerStepCard => 'Carte PMR';

  @override
  String get registerProfilePictureOptional => 'Photo de profil (optionnelle)';

  @override
  String get registerNameRequired => 'Nom requis';

  @override
  String get registerNameFull => 'Entrez votre prénom et nom';

  @override
  String get registerPhoneRequired => 'Numéro requis';

  @override
  String get registerPhoneTooShort => 'Numéro trop court';

  @override
  String get phoneInvalidNumber => 'Numéro de téléphone invalide.';

  @override
  String get phoneInvalidFormat => 'Format de numéro invalide.';

  @override
  String get registerPasswordUppercase => 'Au moins une majuscule';

  @override
  String get registerPasswordDigit => 'Au moins un chiffre';

  @override
  String get registerUploadCardTitle => 'Téléchargez votre carte';

  @override
  String get registerCardLooksLike => 'Votre carte ressemble à ceci :';

  @override
  String get registerCardRecto => 'Recto';

  @override
  String get registerCardVerso => 'Verso';

  @override
  String get registerSubmit => 'S\'inscrire';

  @override
  String get registerEmailAlreadyUsed => 'Cet email est déjà utilisé.';

  @override
  String get registerPhoneAlreadyUsed => 'Ce numéro est déjà associé à un compte.';

  @override
  String get registerCardRequired => 'Veuillez uploader le recto et le verso de votre carte.';

  @override
  String get parkingClosedToday => 'Ce parking est fermé. Choisissez une autre date.';

  @override
  String get agentInsufficientBalance => 'Solde insuffisant pour effectuer ce rechargement.';

  @override
  String get noParkingSpotSelected => 'Il semble que vous n\'avez pas sélectionné une place de parking. Il vous sera donc attribué une parmi celles présentement disponibles.';

  @override
  String get creatingBooking => 'Validation de votre réservation...';

  @override
  String get selectLanguage => 'Selectionner la langue par défaut.';

  @override
  String get loginWelcomeSubtitle => 'Connectez-vous pour continuer';

  @override
  String get loginEmailRequired => 'Email requis';

  @override
  String get loginEmailInvalid => 'Format email invalide';

  @override
  String get loginPasswordRequired => 'Mot de passe requis';

  @override
  String get loginPasswordMinLength => 'Minimum 8 caractères';

  @override
  String get loginWithGoogle => 'Continuer avec Google';

  @override
  String get loginResetEmailSent => 'Email de réinitialisation envoyé !';

  @override
  String get loginResetEmailRequired => 'Entrez votre email pour réinitialiser votre mot de passe.';

  @override
  String get loginSignUp => 'S\'inscrire';

  @override
  String get connectivityOffline => 'Pas de connexion Internet';

  @override
  String get or => 'ou';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardProfile => 'Profil';

  @override
  String get dashboardWallet => 'Wallet YSP';

  @override
  String get dashboardNotifications => 'Notifications';

  @override
  String get dashboardSettings => 'Paramètres';

  @override
  String get dashboardLogout => 'Déconnexion';

  @override
  String get dashboardHello => 'Bonjour';

  @override
  String get dashboardSubtitle => 'Trouvez et réservez votre place de parking';

  @override
  String get dashboardOngoingBooking => 'Réservations';

  @override
  String get dashboardNearbyParkings => 'Parkings disponibles';

  @override
  String get dashboardLate => 'LATE';

  @override
  String get dashboardNoParkings => 'Aucun parking disponible';

  @override
  String get dashboardNavigate => 'Naviguer';

  @override
  String get dashboardMyBookings => 'Mes réservations';

  @override
  String get dashboardSpot => 'Place';

  @override
  String get dashboardTimeLeft => 'Temps restant';

  @override
  String get walletYspCoin => 'YSP Coin';

  @override
  String get walletPortfolio => 'Portefeuille YSP';

  @override
  String get panelFavParkings => 'Mes Favoris';

  @override
  String get panelNoFavParkings => 'Aucun parking favori';

  @override
  String get dashboardDefaultVehicle => 'Véhicule par défaut';

  @override
  String get dashboardUpcomingBooking => 'Réservation à venir';

  @override
  String get dashboardNoBooking => 'Aucune réservation';

  @override
  String get dashboardNoBookingSubtitle => 'Appuyez pour naviguer vers un parking.';

  @override
  String get dashboardSwipeForParkings => '↑ Glissez pour voir les parkings';

  @override
  String get dashboardBookings => 'Mes Réservations';

  @override
  String get dashboardVoirTout => 'Voir tout';

  @override
  String get dashboardVoirCarte => 'Voir la carte';

  @override
  String get dashboardCurrentVehicle => 'Véhicule actuel';

  @override
  String get dashboardNoVehicle => 'Aucun véhicule ajouté';

  @override
  String get dashboardNoVehicleSubtitle => 'Ajoutez votre véhicule pour réserver.';

  @override
  String get dashboardFavorites => 'Mes parkings favoris';

  @override
  String get dashboardNoFavorite => 'Aucun favori encore';

  @override
  String get dashboardNoFavoriteSubtitle => 'Faites des réservations pour voir vos parkings préférés.';

  @override
  String get dashboardMyVehicles => 'Mes véhicules';

  @override
  String get dashboardVehicleHint => 'Tap = sélectionner • Double tap = définir par défaut';

  @override
  String get dashboardAddVehicle => 'Ajouter un véhicule';

  @override
  String get dashboardFull => 'Complet';

  @override
  String get dashboardCheckAvailability => 'Disponibilité';

  @override
  String get dashboardChecking => 'Vérification...';

  @override
  String get dashboardBook => 'Réserver';

  @override
  String get dashboardCancelBooking => 'Annuler la réservation ?';

  @override
  String dashboardCancelConfirm(String spotId) {
    return 'Voulez-vous vraiment annuler la réservation pour la place $spotId ?';
  }

  @override
  String get commonYes => 'Oui';

  @override
  String get commonNo => 'Non';

  @override
  String get commonNext => 'Suivant';

  @override
  String get vehicleAddTitle => 'Ajouter un véhicule';

  @override
  String get vehicleEditTitle => 'Modifier le véhicule';

  @override
  String get vehicleAddSuccess => 'Véhicule ajouté avec succès !';

  @override
  String get vehicleEditSuccess => 'Véhicule modifié avec succès !';

  @override
  String get vehiclePlatePreview => 'Aperçu de la plaque';

  @override
  String get vehicleType => 'Type de véhicule';

  @override
  String get vehicleBrand => 'Marque';

  @override
  String get vehicleInfo => 'Informations';

  @override
  String get vehicleModel => 'Modèle';

  @override
  String get vehicleModelHint => 'Ex: Classe C, Corolla, Clio...';

  @override
  String get vehicleModelRequired => 'Modèle requis';

  @override
  String get vehicleColor => 'Couleur';

  @override
  String get vehiclePlate => 'Plaque d\'immatriculation';

  @override
  String get vehiclePlateHint => 'Ex: DAK-1234-2024';

  @override
  String get vehiclePlateRequired => 'Plaque requise';

  @override
  String get vehiclePlateInvalid => 'Format invalide. Ex: DAK-1234-2024';

  @override
  String get vehicleYear => 'Année';

  @override
  String get vehicleYearHint => 'Ex: 2020';

  @override
  String get vehicleYearRequired => 'Année requise';

  @override
  String get vehicleYearInvalid => 'Année invalide';

  @override
  String get vehicleCountry => 'Pays d\'immatriculation';

  @override
  String get vehicleCountryHint => 'Sélectionner un pays';

  @override
  String get vehicleCountryRequired => 'Pays requis';

  @override
  String get vehicleCity => 'Ville';

  @override
  String get vehicleCityHint => 'Sélectionner une ville';

  @override
  String get vehicleSave => 'Enregistrer le véhicule';

  @override
  String get vehicleBrandRequired => 'Veuillez sélectionner une marque.';

  @override
  String get vehicleCountrySelectRequired => 'Veuillez sélectionner un pays.';

  @override
  String get bookingSelectSpotError => 'Veuillez sélectionner une place';

  @override
  String get bookingSelectDateError => 'Veuillez choisir une date';

  @override
  String get bookingSelectVehicleError => 'Veuillez sélectionner un véhicule';

  @override
  String get bookingNoVehicleStep => 'Sélectionnez un véhicule à l\'étape précédente';

  @override
  String get bookingInsufficientBalance => 'Solde insuffisant. Rechargez votre wallet YSP.';

  @override
  String get bookingConfirmEdit => 'Confirmer la modification';

  @override
  String get bookingConfirmNew => 'Confirmer la réservation';

  @override
  String get bookingStepParking => 'Parking';

  @override
  String get bookingStepSummary => 'Récapitulatif';

  @override
  String get bookingVehicle => 'Véhicule';

  @override
  String get bookingParking => 'Parking';

  @override
  String get bookingSpot => 'Place';

  @override
  String get bookingAddress => 'Adresse';

  @override
  String get bookingDate => 'Date';

  @override
  String get bookingStart => 'Début';

  @override
  String get bookingEnd => 'Fin';

  @override
  String get bookingDuration => 'Durée';

  @override
  String get bookingOriginalCost => 'Coût original';

  @override
  String get bookingSupplement => 'Supplément';

  @override
  String get bookingCurrentBalance => 'Solde actuel';

  @override
  String get bookingBalanceAfter => 'Solde après';

  @override
  String get bookingCost => 'Coût';

  @override
  String get bookingReducedDuration => 'Durée réduite — coût initial conservé, pas de remboursement.';

  @override
  String get bookingPriceUnchanged => 'Inchangé ';

  @override
  String get bookingSlideHint => 'Faites défiler la grille pour voir toutes les places disponibles.';

  @override
  String get bookingSlideHintDismiss => 'NE PLUS AFFICHER';

  @override
  String get bookingVehicleSwapSlideHint => 'Glissez pour changer de véhicule';

  @override
  String get bookingSelectTimeSlot => 'Choisissez un créneau pour voir la disponibilité des places.';

  @override
  String get bookingSelectTimeSlotTitle => 'Choisir un créneau';

  @override
  String get bookingSelectSpotTitle => 'Choisir une place';

  @override
  String get bookingSelectDateTitle => 'Choisir une date';

  @override
  String get bookingSelectVehicleTitle => 'Choisir un véhicule';

  @override
  String get bookingSpotEntry => 'Entrée';

  @override
  String get bookingSpotExit => 'Sortie';

  @override
  String get bookingFrom => 'Début';

  @override
  String get bookingTo => 'Fin';

  @override
  String get bookingSpotOccupied => 'Occupée';

  @override
  String get bookingSpotFree => 'Libre';

  @override
  String get bookingSpotReserved => 'Réservée';

  @override
  String get bookingSpotForDisabled => 'PMR';

  @override
  String get bookingUserHasNoVehicle => 'Aucun véhicule — ajoutez-en depuis votre profil';

  @override
  String get bookingItemSelected => 'Sélectionnée';

  @override
  String get bookingStatusOngoing => 'EN COURS';

  @override
  String get bookingStatusCanceled => 'ANNULÉE';

  @override
  String get bookingStatusDone => 'TERMINÉE';

  @override
  String get bookingStatusUpcomingEdited => 'À VENIR · MODIFIÉE';

  @override
  String get bookingStatusUpcoming => 'À VENIR';

  @override
  String get bookingEdited => 'Modifiée';

  @override
  String bookingSpotLabel(String spotId) {
    return 'Place $spotId';
  }

  @override
  String get bookingCancelTitle => 'Annuler la réservation ?';

  @override
  String bookingCancelContent(String spotId, String date) {
    return 'Place $spotId — $date\n\nAucun remboursement ne sera effectué.';
  }

  @override
  String get bookingFilterAll => 'Toutes';

  @override
  String get bookingFilterOngoing => 'En cours';

  @override
  String get bookingFilterUpcoming => 'À venir';

  @override
  String get bookingFilterPast => 'Passées';

  @override
  String get bookingFilterCanceled => 'Annulées';

  @override
  String get bookingEditAction => 'Modifier';

  @override
  String get bookingCancelAction => 'Annuler';

  @override
  String get bookingConfirmCancelYes => 'Oui, annuler';

  @override
  String get bookingSuccessNew => 'Réservation confirmée avec succès !';

  @override
  String get bookingSuccessEdit => 'Réservation modifiée avec succès !';

  @override
  String bookingErrorGeneric(String message) {
    return 'Erreur : $message';
  }

  @override
  String get parkingTitle => 'Parkings';

  @override
  String get parkingSearchHint => 'Nom ou adresse...';

  @override
  String parkingFound(int count) {
    return '$count parking trouvé';
  }

  @override
  String parkingsFound(int count) {
    return '$count parkings trouvés';
  }

  @override
  String get parkingNoneFound => 'Aucun parking trouvé';

  @override
  String get parkingNormal => 'Normales';

  @override
  String get parkingPMR => 'PMR';

  @override
  String get parkingTotal => 'Total';

  @override
  String get parkingAvailable => 'Disponibles';

  @override
  String get parkingLegendParking => 'Parking';

  @override
  String get parkingLegendSelected => 'Sélectionné';

  @override
  String get parkingLegendMyPosition => 'Ma position';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLangFr => '🇫🇷  Français';

  @override
  String get settingsLangEn => '🇬🇧  English';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotifAll => 'Toutes les notifications';

  @override
  String get settingsNotifAllSubtitle => 'Activer ou désactiver tous les rappels';

  @override
  String get settingsNotif30min => '30min avant la réservation';

  @override
  String get settingsNotif30minSubtitle => 'Rappel anticipé';

  @override
  String get settingsNotif10min => '10min avant le début de la réservation';

  @override
  String get settingsNotif10minSubtitle => 'Rappel urgent';

  @override
  String get settingsNotifStart => 'Début de réservation';

  @override
  String get settingsNotifStartSubtitle => 'Quand votre créneau commence';

  @override
  String get settingsNotifEnd => '15min avant la fin';

  @override
  String get settingsNotifEndSubtitle => 'Rappel de fin imminente';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'Aucune notification';

  @override
  String get notificationsMarkAllRead => 'Tout lire';

  @override
  String get notificationsSnooze => 'Reporter le rappel';

  @override
  String get notifBookingConfirmedTitle => 'Réservation confirmée !';

  @override
  String notifBookingConfirmedBody(String spotId, String parkingName) {
    return 'Place $spotId — $parkingName';
  }

  @override
  String get notifReminder30min => '⏰ Rappel parking';

  @override
  String notifReminder10min(String spotId) {
    return '🚗 Bientôt ! Place $spotId';
  }

  @override
  String notifReminderStart(String spotId) {
    return '✅ Réservation active — Place $spotId';
  }

  @override
  String notifReminderEnd(String spotId) {
    return '⚠️ Fin dans 15min — Place $spotId';
  }

  @override
  String notifSnoozeMinutes(int minutes) {
    return 'Dans $minutes minutes';
  }

  @override
  String notifSnoozed(int minutes) {
    return 'Rappel reporté de $minutes minutes';
  }

  @override
  String get notificationsEmptySubtitle => 'Vos rappels et alertes apparaîtront ici';

  @override
  String get profileTitle => 'Mon Profil';

  @override
  String get profileSave => 'Sauvegarder';

  @override
  String get profilePhotoUpdated => 'Photo mise à jour !';

  @override
  String profileCardUploaded(String side) {
    return 'Carte $side uploadée !';
  }

  @override
  String profileErrorPrefix(String message) {
    return 'Erreur: $message';
  }

  @override
  String get profileChangeEmail => 'Modifier l\'email';

  @override
  String get profileNewEmail => 'Nouvel email';

  @override
  String get profileVerifyEmail => 'Vérifiez votre email';

  @override
  String profileVerifyEmailContent(String email) {
    return 'Un lien de vérification a été envoyé à $email.\n\nCliquez sur le lien AVANT de vous reconnecter pour confirmer votre nouvel email.';
  }

  @override
  String get profileLogoutToVerify => 'OK, me déconnecter';

  @override
  String get profileChangePhone => 'Modifier le téléphone';

  @override
  String get profileNewPhone => 'Nouveau numéro';

  @override
  String get profileSendSms => 'Envoyer SMS';

  @override
  String get profileSendingSms => 'Envoi du SMS...';

  @override
  String get profileSmsCode => 'Code SMS';

  @override
  String profileSmsCodeContent(String phone) {
    return 'Code envoyé au $phone';
  }

  @override
  String get profileVerifySms => 'Vérifier';

  @override
  String get profilePersonalInfo => 'Informations personnelles';

  @override
  String get profileFullName => 'Nom complet';

  @override
  String get profileEmail => 'Email';

  @override
  String get profilePhone => 'Téléphone';

  @override
  String get profilePmrCard => 'Carte PMR (Mobilité Réduite)';

  @override
  String get profilePmrDescription => 'Uploadez votre carte d\'invalidité pour accéder aux places PMR.';

  @override
  String get profilePmrEnabled => 'Accès PMR activé !';

  @override
  String get profilePmrDisabled => 'Accès PMR non activé — uploadez votre carte';

  @override
  String get profilePmrRecto => 'Recto';

  @override
  String get profilePmrVerso => 'Verso';

  @override
  String get profilePmrTapChange => 'Tap pour changer';

  @override
  String get profilePmrTapUpload => 'Tap pour uploader';

  @override
  String get profileUpdated => 'Profil mis à jour !';

  @override
  String get profilePhoneUpdated => 'Téléphone mis à jour !';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get profileSmsNotSent => 'SMS non envoyé';

  @override
  String get profilePhoneAutoVerified => 'Téléphone vérifié automatiquement !';

  @override
  String get profileSmsCodeLabel => 'Code à 6 chiffres';

  @override
  String profileInvalidCode(String message) {
    return 'Code invalide: $message';
  }

  @override
  String get walletTitle => 'Mon Wallet YSP';

  @override
  String get walletQrButton => 'Mon QR Code';

  @override
  String get walletBalance => 'Solde YSP Coin';

  @override
  String get walletPortfolioLabel => 'Portefeuille YSP';

  @override
  String get walletHistory => 'Historique des transactions';

  @override
  String get walletQrTitle => 'Mon QR Code de rechargement';

  @override
  String get walletQrSubtitle => 'Montrez ce code à l\'agent YSP pour recharger votre wallet';

  @override
  String get walletQrScanToRecharge => 'Scanner pour\nrecharger';

  @override
  String get walletIdCopied => 'ID copié !';

  @override
  String get walletTransactionBooking => 'Réservation';

  @override
  String get walletTransactionTopUp => 'Rechargement';

  @override
  String get walletTopUpAgent => ' (Agent)';

  @override
  String get walletTopUpQr => ' (QR Code)';

  @override
  String get walletTopUpOnline => ' (En ligne)';

  @override
  String walletBalanceLabel(int balance) {
    return 'Solde : $balance SPM';
  }

  @override
  String get walletNoTransactions => 'Aucune transaction';

  @override
  String get walletNoTransactionsSubtitle => 'Vos débits et rechargements apparaîtront ici';

  @override
  String get agentDashboardTitle => 'Agent YSP';

  @override
  String get agentScanTitle => 'Scanner client';

  @override
  String get agentTopUpTitle => 'Rechargement';

  @override
  String get agentBadge => 'Agent YSP';

  @override
  String get agentNewScan => 'Nouveau scan';

  @override
  String agentMyBalance(int balance) {
    return 'Mon solde : $balance SPM';
  }

  @override
  String get agentToday => 'Aujourd\'hui';

  @override
  String get agentTotal => 'Total';

  @override
  String get agentScanClient => 'Scanner un client';

  @override
  String get agentRecentTopUps => 'Rechargements récents';

  @override
  String get agentNoTopUps => 'Aucun rechargement effectué';

  @override
  String get agentClientIdentified => 'Client identifié';

  @override
  String agentClientBalance(int balance) {
    return 'Solde actuel : $balance SPM';
  }

  @override
  String get agentAmountLabel => 'Montant à créditer (SPM)';

  @override
  String get agentScanAnother => 'Scanner un autre client';

  @override
  String get agentUserNotFound => 'Utilisateur non trouvé';

  @override
  String get agentInvalidAmount => 'Entrez un montant valide';

  @override
  String agentNewBalance(int balance) {
    return 'Nouveau solde : $balance SPM';
  }

  @override
  String get agentClient => 'Client';

  @override
  String get agentClientNewBalance => 'Nouveau solde client';

  @override
  String get agentTitle => 'Agent';

  @override
  String agentAmountCredited(int amount) {
    return '+$amount SPM';
  }

  @override
  String notifTopUpBody(int amount, int newBalance) {
    return 'Vous avez reçu $amount SPM. Nouveau solde : $newBalance SPM.';
  }

  @override
  String notifBookingConfirmed(String spotId) {
    return 'Réservation confirmée — Place $spotId';
  }

  @override
  String get agentSuccess => 'Rechargement effectué !';

  @override
  String get agentConfirm => 'Confirmer le rechargement !';

  @override
  String get commonOk => 'OK';

  @override
  String get bookingNoVehicleAdd => 'Aucun véhicule — appuyez pour en ajouter un';

  @override
  String get bookingSpotConflict => 'Cette place vient d\'être réservée. Veuillez en choisir une autre.';

  @override
  String get bookingVehicleConflict => 'Ce véhicule a déjà une réservation active sur ce créneau, potentiellement dans un autre parking. Annulez ou modifiez cette réservation, ou choisissez un créneau qui ne chevauche pas.';

  @override
  String get bookingHistoryNoUpcoming => 'Aucune réservation à venir';

  @override
  String get bookingHistoryNoPast => 'Aucune réservation passée';

  @override
  String get bookingHistoryNoCanceled => 'Aucune réservation annulée';

  @override
  String get bookingHistoryNoBookings => 'Aucune réservation';

  @override
  String notif30MinFullBody(String spotId) {
    return 'Place $spotId commence dans 30 minutes.';
  }

  @override
  String get notif10MinBody => 'Votre réservation commence dans 10 minutes.';

  @override
  String notifStartBody(String time) {
    return 'Fin prévue à $time.';
  }

  @override
  String get notifEnd15Body => 'Votre réservation se termine bientôt.';

  @override
  String get notifBookingEndedTitle => '🏁 Réservation terminée';

  @override
  String notifBookingEndedBody(String spotId) {
    return 'Votre réservation Place $spotId est terminée. Merci d\'avoir utilisé YSP !';
  }
}
