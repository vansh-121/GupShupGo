// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonOk => 'OK';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonGotIt => 'J\'ai compris';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsLanguageSubtitle => 'Choisissez votre langue préférée';

  @override
  String get languagePickerTitle => 'Langue';

  @override
  String get languageSystemDefault => 'Par défaut du système';

  @override
  String get languageSystemDefaultSubtitle =>
      'Utilise la langue de votre appareil';

  @override
  String get loginContinueWithPhone => 'Continuer avec le téléphone';

  @override
  String get loginContinueWithGoogle => 'Continuer avec Google';

  @override
  String get loginUseEmailPassword => 'Utiliser l\'e-mail et le mot de passe';

  @override
  String get loginSignIn => 'Se connecter';

  @override
  String get loginSignUp => 'S\'inscrire';

  @override
  String get loginCreateAccount => 'Créer un compte';

  @override
  String get loginForgotPassword => 'Mot de passe oublié ?';

  @override
  String get loginOfflineChat => 'Chat hors ligne';

  @override
  String get loginHintName => 'Votre nom';

  @override
  String get loginHintEmail => 'E-mail';

  @override
  String get loginHintPassword => 'Mot de passe';

  @override
  String get loginPasswordHelper =>
      'Au moins 8 caractères, avec une lettre et un chiffre';

  @override
  String loginResetEmailSent(String email) {
    return 'E-mail de réinitialisation envoyé à $email';
  }

  @override
  String get loginErrorEnterEmail => 'Veuillez entrer votre e-mail';

  @override
  String get loginErrorValidEmail => 'Veuillez entrer un e-mail valide';

  @override
  String get loginErrorEnterPassword => 'Veuillez entrer votre mot de passe';

  @override
  String get loginErrorPasswordMin6 =>
      'Le mot de passe doit comporter au moins 6 caractères';

  @override
  String get loginErrorEnterPasswordSignup => 'Veuillez entrer un mot de passe';

  @override
  String get loginErrorPasswordMin8 =>
      'Le mot de passe doit comporter au moins 8 caractères';

  @override
  String get loginErrorPasswordLetter =>
      'Le mot de passe doit inclure une lettre';

  @override
  String get loginErrorPasswordNumber =>
      'Le mot de passe doit inclure un chiffre';

  @override
  String get loginErrorEnterName => 'Veuillez entrer votre nom';

  @override
  String get loginErrorGoogleCancelled => 'La connexion Google a été annulée.';

  @override
  String get loginErrorProfileLoad =>
      'Impossible de charger votre profil. Vérifiez votre connexion et réessayez.';

  @override
  String get loginErrorGoogleFailed =>
      'Échec de la connexion Google. Veuillez réessayer.';

  @override
  String get loginErrorSignInFailed =>
      'Échec de la connexion. Veuillez réessayer.';

  @override
  String get loginErrorSignUpFailed =>
      'Échec de l\'inscription. Veuillez réessayer.';

  @override
  String get loginErrorGeneric =>
      'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get loginErrorResetFailed =>
      'Échec de l\'envoi de l\'e-mail de réinitialisation. Veuillez réessayer.';

  @override
  String get loginErrorUserNotFound =>
      'Aucun compte trouvé avec cet e-mail. Veuillez vous inscrire.';

  @override
  String get loginErrorWrongPassword =>
      'Mot de passe incorrect. Veuillez réessayer.';

  @override
  String get loginErrorEmailInUse =>
      'Un compte existe déjà avec cet e-mail. Veuillez vous connecter.';

  @override
  String get loginErrorInvalidEmail =>
      'Veuillez entrer une adresse e-mail valide.';

  @override
  String get loginErrorWeakPassword =>
      'Mot de passe trop faible. Utilisez au moins 6 caractères.';

  @override
  String get loginErrorInvalidCredential =>
      'E-mail ou mot de passe invalide. Veuillez vérifier et réessayer.';

  @override
  String get loginErrorTooManyRequests =>
      'Trop de tentatives. Veuillez réessayer plus tard.';

  @override
  String get homeNavChats => 'Discussions';

  @override
  String get homeNavMoments => 'Moments';

  @override
  String get homeNavCalls => 'Appels';

  @override
  String get homeNavProfile => 'Profil';

  @override
  String get homeTooltipOfflineChat =>
      'Chat hors ligne — discutez avec des personnes à proximité';

  @override
  String get homeTooltipSearch => 'Rechercher';

  @override
  String get homeMenuProfile => 'Profil';

  @override
  String get homeMenuSettings => 'Paramètres';

  @override
  String get homeMenuRateUs => 'Évaluez-nous';

  @override
  String get homeMenuReportIssue => 'Signaler un problème';

  @override
  String get homeMenuWhatsNew => 'Nouveautés';

  @override
  String get homeMenuLogOut => 'Déconnexion';

  @override
  String get homeEmptyChatsTitle => 'Aucune discussion';

  @override
  String get homeEmptyChatsSubtitle =>
      'Démarrez une conversation en appuyant sur le bouton ci-dessous';

  @override
  String get homeNewChatButton => 'Nouvelle discussion';

  @override
  String get homeAiAssistantTitle => 'GupAI';

  @override
  String get homeAiAssistantSubtitle =>
      'Rédigez, traduisez, résumez et plus encore';

  @override
  String get homeStrangerMatchTitle => 'Discuter avec un inconnu';

  @override
  String get homeStrangerMatchSubtitle =>
      'Chat anonyme — touchez pour matcher !';

  @override
  String get homeMyMoment => 'Mon moment';

  @override
  String get homeRecentMoments => 'Moments récents';

  @override
  String get homeEmptyMomentsTitle => 'Aucune mise à jour pour le moment.';

  @override
  String get homeEmptyMomentsSubtitle =>
      'Touchez l\'appareil photo pour partager.';

  @override
  String get homeTapToAddMoment => 'Touchez pour ajouter une mise à jour';

  @override
  String get homeEmptyCallsTitle => 'Aucun historique d\'appels';

  @override
  String get homeEmptyCallsSubtitle => 'Vos appels récents apparaîtront ici';

  @override
  String get chatInputHint => 'Message...';

  @override
  String get chatSearchHint => 'Rechercher des messages...';

  @override
  String get chatStatusTyping => 'écrit...';

  @override
  String get chatStatusOnline => 'En ligne';

  @override
  String get chatStatusOffline => 'Hors ligne';

  @override
  String chatStatusLastSeen(String time) {
    return 'Vu $time';
  }

  @override
  String get chatEndToEndEncrypted => 'Chiffré de bout en bout';

  @override
  String get chatNoInternetOfflineTitle =>
      'Pas d\'internet ? Discutez hors ligne avec les appareils à proximité';

  @override
  String get chatEnableOfflineButton => 'Activer';

  @override
  String get chatSlideToCancel => 'Glisser pour annuler';

  @override
  String get chatTooltipVoiceCall => 'Appel vocal';

  @override
  String get chatTooltipVideoCall => 'Appel vidéo';

  @override
  String get chatMenuContactInfo => 'Infos du contact';

  @override
  String get chatMenuSearch => 'Rechercher';

  @override
  String get chatMenuChatTheme => 'Thème du chat';

  @override
  String get chatMenuExportChat => 'Exporter la discussion';

  @override
  String get chatMenuMuteNotifications => 'Mettre en sourdine';

  @override
  String get chatMenuUnmuteNotifications => 'Réactiver les notifications';

  @override
  String get chatMenuBlockContact => 'Bloquer le contact';

  @override
  String get chatActionReply => 'Répondre';

  @override
  String get chatActionCopy => 'Copier';

  @override
  String get chatActionForward => 'Transférer';

  @override
  String get chatActionTranslate => 'Traduire';

  @override
  String get chatActionSummarise => 'Résumer';

  @override
  String get chatActionAskGupAi => 'Demander à GupAI';

  @override
  String get chatActionEdit => 'Modifier';

  @override
  String get chatActionDelete => 'Supprimer';

  @override
  String get chatDeleteMessageTitle => 'Supprimer le message ?';

  @override
  String get chatDeleteMessageForEveryonePrompt =>
      'Supprimer uniquement pour vous ou pour tout le monde ?';

  @override
  String chatDeleteMessageForMeOnlyPrompt(String name) {
    return 'Ceci le supprime uniquement de vos appareils. $name le verra toujours.';
  }

  @override
  String get chatDeleteForMe => 'Supprimer pour moi';

  @override
  String get chatDeleteForEveryone => 'Supprimer pour tous';

  @override
  String chatBlockContactTitle(String name) {
    return 'Bloquer $name ?';
  }

  @override
  String get chatBlockContactPrompt =>
      'Les contacts bloqués ne peuvent pas vous envoyer de messages ni vous appeler. Vous pouvez les débloquer dans Paramètres → Confidentialité.';

  @override
  String get chatBlockButton => 'Bloquer';

  @override
  String get chatForwardTo => 'Transférer à';

  @override
  String get chatNoForwardChats => 'Aucune autre discussion pour le transfert';

  @override
  String get chatCannotSendMediaBlocked =>
      'Impossible d\'envoyer des médias à ce contact';

  @override
  String get attachmentShareTitle => 'Partager';

  @override
  String get attachmentPhoto => 'Photo';

  @override
  String get attachmentPhotoSubtitle => 'Choisir une image dans votre galerie';

  @override
  String get attachmentVideo => 'Vidéo';

  @override
  String get attachmentVideoSubtitle => 'Choisir une vidéo dans votre galerie';

  @override
  String get attachmentDocument => 'Document';

  @override
  String get attachmentDocumentSubtitle =>
      'PDF, fichier Office, archive — envoyé tel quel';

  @override
  String get attachmentLocation => 'Position';

  @override
  String get attachmentLocationSubtitle => 'Partager votre position actuelle';

  @override
  String get attachmentViewOnce => 'Vue unique';

  @override
  String get attachmentViewOnceSubtitle =>
      'La photo ou la vidéo disparaît après ouverture';

  @override
  String get contactsTitle => 'Contacts et Découvrir';

  @override
  String get contactsTabFriends => 'Amis';

  @override
  String get contactsTabRequests => 'Demandes';

  @override
  String get contactsTabDiscover => 'Découvrir';

  @override
  String get contactsScanQrTooltip => 'Scanner le code QR';

  @override
  String get contactsMyHandleTooltip => 'Mon identifiant';

  @override
  String get contactsSetUsernamePrompt =>
      'Définissez d\'abord un @identifiant dans votre profil — c\'est ce que votre code QR partage.';

  @override
  String get contactsMyQrCodeTitle => 'Mon code QR de profil';

  @override
  String get contactsMyQrCodeSubtitle =>
      'Vos amis peuvent scanner ce code QR pour se connecter instantanément avec vous';

  @override
  String get contactsCopyProfileLink => 'Copier le lien du profil';

  @override
  String contactsProfileLinkCopied(String username) {
    return 'Lien de profil pour @$username copié !';
  }

  @override
  String get contactsScanSomeonesCode => 'Scanner le code de quelqu\'un';

  @override
  String get contactsPermissionDenied =>
      'L\'autorisation d\'accéder aux contacts a été refusée.';

  @override
  String get contactsNoUsersFound =>
      'Aucun utilisateur GupShupGo trouvé dans vos contacts pour le moment.';

  @override
  String contactsFailedToSync(String error) {
    return 'Échec de la synchronisation des contacts : $error';
  }

  @override
  String contactsMatchedCount(int count) {
    return '$count contacts sur GupShupGo';
  }

  @override
  String get contactsFromDeviceContacts =>
      'Depuis les contacts de votre appareil';

  @override
  String get contactsLoadFriendsError => 'Impossible de charger vos amis.';

  @override
  String get contactsNoFriendsTitle => 'Aucun ami ajouté pour l\'instant';

  @override
  String get contactsNoFriendsPrompt =>
      'Utilisez l\'onglet Découvrir pour rechercher des utilisateurs par @identifiant, téléphone ou e-mail et envoyez-leur une demande !';

  @override
  String get contactsDiscoverPeopleButton => 'Découvrir des personnes';

  @override
  String get contactsQuickConnectHeader => 'CONNEXION RAPIDE';

  @override
  String get contactsNoSuggestions =>
      'Aucune suggestion disponible pour le moment.';

  @override
  String get contactsLoadRequestsError => 'Impossible de charger vos demandes.';

  @override
  String contactsPendingRequestsHeader(int count) {
    return 'DEMANDES EN ATTENTE ($count)';
  }

  @override
  String get contactsNoPendingRequestsTitle => 'Aucune demande en attente';

  @override
  String get contactsNoPendingRequestsSubtitle =>
      'Lorsque des utilisateurs vous envoient des demandes, elles apparaîtront ici.';

  @override
  String get contactsWantsToConnect => 'Souhaite se connecter';

  @override
  String get contactsAcceptButton => 'ACCEPTER';

  @override
  String get contactsAcceptFailed =>
      'Impossible d\'accepter la demande. Veuillez réessayer.';

  @override
  String contactsConnectedWith(String name) {
    return 'Connecté avec $name !';
  }

  @override
  String get contactsDeclineFailed =>
      'Impossible de refuser la demande. Veuillez réessayer.';

  @override
  String get contactsYouMightKnowHeader => 'VOUS CONNAISSEZ PEUT-ÊTRE';

  @override
  String get contactsSeeAll => 'TOUT AFFICHER';

  @override
  String get contactsSearchHint =>
      'Rechercher par nom, @identifiant, téléphone ou e-mail...';

  @override
  String get contactsTurnOnDiscoverability =>
      'Activez la découvrabilité pour apparaître dans les recherches et suggestions.';

  @override
  String get contactsNoMatchingUsersTitle =>
      'Aucun utilisateur correspondant trouvé';

  @override
  String get contactsNoMatchingUsersSubtitle =>
      'Vérifiez l\'@identifiant, le numéro de téléphone ou l\'e-mail et réessayez.';

  @override
  String get contactsDiscoverHeroTitle => 'Découvrez du monde sur GupShupGo';

  @override
  String get contactsDiscoverHeroSubtitle =>
      'Élargissez votre cercle avec des connexions haute fidélité à travers le monde.';

  @override
  String get contactsSyncDeviceContacts =>
      'Synchroniser les contacts du téléphone';

  @override
  String get contactsSyncingContacts => 'Synchronisation des contacts...';

  @override
  String get contactsSyncDeviceSubtitle =>
      'Retrouvez vos amis instantanément depuis vos contacts';

  @override
  String get contactsSuggestedUsersHeader => 'UTILISATEURS SUGGÉRÉS';

  @override
  String get contactsAddFriendButton => 'AJOUTER UN AMI';

  @override
  String get contactsRequestedButton => 'Demandé';

  @override
  String contactsRequestSent(String name) {
    return 'Demande d\'ami envoyée à $name !';
  }

  @override
  String get contactsRequestFailed =>
      'La demande est déjà en attente ou a échoué.';

  @override
  String get contactsRequestUnavailable =>
      'Cette demande n\'est plus disponible.';

  @override
  String get profileEditTitle => 'Modifier le profil';

  @override
  String get profileSaveButton => 'Enregistrer';

  @override
  String get profileTapToChangePhoto => 'Appuyez pour changer la photo';

  @override
  String get profileUpgradeToPro => 'Passer à Pro';

  @override
  String get profileSectionName => 'VOTRE NOM';

  @override
  String get profileNameHint => 'Entrez votre nom';

  @override
  String get profileSectionHandle => 'IDENTIFIANT UNIQUE';

  @override
  String get profileHandleNotSet => 'Pas encore défini';

  @override
  String get profileChangeHandle => 'Modifier';

  @override
  String get profileSectionAbout => 'À PROPOS';

  @override
  String get profileAboutHint => 'Qu\'avez-vous en tête ?';

  @override
  String get profileDefaultAbout => 'Salut ! J\'utilise GupShupGo.';

  @override
  String get profileSectionPhone => 'TÉLÉPHONE';

  @override
  String get profileSectionEmail => 'E-MAIL';

  @override
  String get profileSectionLinkedMethods => 'MÉTHODES DE CONNEXION LIÉES';

  @override
  String get profileNotLinked => 'Non lié';

  @override
  String get profileNameEmpty => 'Le nom ne peut pas être vide.';

  @override
  String get profileUpdatedSuccess => 'Profil mis à jour';

  @override
  String profileUploadPhotoFailed(String error) {
    return 'Échec du téléversement de la photo : $error';
  }

  @override
  String profileSaveFailed(String error) {
    return 'Échec de l\'enregistrement du profil : $error';
  }

  @override
  String get profilePoints => 'Points';

  @override
  String get profileBadges => 'Badges';

  @override
  String get profileBestBond => 'Meilleure Série';

  @override
  String get settingsAccountCard => 'Compte';

  @override
  String get settingsProfileTile => 'Profil';

  @override
  String get settingsLinkedMethodsTile => 'Méthodes de connexion associées';

  @override
  String get settingsPhoneTile => 'Numéro de téléphone';

  @override
  String get settingsEmailTile => 'E-mail';

  @override
  String get settingsPrivacyCard => 'Confidentialité';

  @override
  String get settingsDiscoverability => 'Découvrabilité';

  @override
  String get settingsLastSeen => 'Vu à';

  @override
  String get settingsReadReceipts => 'Confirmations de lecture';

  @override
  String get settingsAdPreferences => 'Préférences d\'annonces';

  @override
  String get settingsManage => 'Gérer';

  @override
  String get settingsAppearanceCard => 'Apparence';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsChatTheme => 'Thème du chat';

  @override
  String get settingsHelpSecurityCard => 'Aide et sécurité';

  @override
  String get settingsHelpCenter => 'Centre d\'aide';

  @override
  String get settingsReportProblem => 'Signaler un problème';

  @override
  String get settingsE2EEShield => 'Chiffrement de bout en bout (Coffre)';

  @override
  String get settingsVerifySafetyNumber => 'Vérifier le numéro de sécurité';

  @override
  String get settingsBlockedContacts => 'Contacts bloqués';

  @override
  String get settingsClearAllGupHistory =>
      'Effacer tout l\'historique des discussions';

  @override
  String get settingsRateUs => 'Évaluez-nous';

  @override
  String get settingsWhatsNew => 'Nouveautés';

  @override
  String get settingsCheckForUpdates => 'Vérifier les mises à jour';

  @override
  String get settingsAppInfo => 'Infos sur l\'application';

  @override
  String get settingsLogOut => 'Déconnexion';

  @override
  String get settingsLogOutConfirmTitle => 'Se déconnecter';

  @override
  String get settingsLogOutConfirmPrompt =>
      'Voulez-vous vraiment vous déconnecter de GupShupGo ?';

  @override
  String get settingsSigningOut => 'Déconnexion en cours…';

  @override
  String get settingsClearChatsConfirmTitle => 'Effacer toutes les discussions';

  @override
  String get settingsClearChatsConfirmPrompt =>
      'Cela supprimera définitivement tout votre historique de messages. Cette action est irréversible.';

  @override
  String get settingsDeleteAll => 'Tout supprimer';

  @override
  String get settingsClearingChats => 'Effacement des discussions...';

  @override
  String get settingsAllChatsCleared =>
      'Toutes les discussions ont été effacées';

  @override
  String settingsClearChatsFailed(String error) {
    return 'Échec de l\'effacement des discussions : $error';
  }

  @override
  String get settingsChooseThemeTitle => 'Choisir un thème';

  @override
  String get settingsUnlockPremiumFeatures =>
      'Débloquez les fonctionnalités Pro';

  @override
  String settingsProDaysLeft(String planLabel, int daysRemaining) {
    return '$planLabel · $daysRemaining jours restants';
  }

  @override
  String get settingsCheckingForUpdates => 'Recherche de mises à jour…';

  @override
  String settingsUpToDate(String version) {
    return 'Vous utilisez la dernière version (v$version).';
  }

  @override
  String get settingsUpdateCheckUnavailable =>
      'Impossible de vérifier les mises à jour. Assurez-vous d\'avoir installé GupShupGo depuis le Google Play Store.';

  @override
  String get settingsNoBlockedContacts => 'Aucun contact bloqué';

  @override
  String get settingsUnblock => 'Débloquer';

  @override
  String settingsUserUnblocked(String name) {
    return '$name débloqué';
  }

  @override
  String get settingsVerifyContactTitle => 'Vérifier un contact';

  @override
  String get settingsVerifyContactSubtitle =>
      'Sélectionnez un contact pour afficher votre numéro de sécurité partagé.';

  @override
  String get settingsComputingSafetyNumber => 'Calcul du numéro de sécurité…';

  @override
  String settingsSafetyNumberExplanation(String name) {
    return 'Si le numéro ci-dessous correspond sur l\'appareil de $name, votre chiffrement de bout en bout est vérifié.';
  }

  @override
  String get settingsSafetyNumberNoBundle =>
      'Ce contact n\'a pas encore publié de clé de chiffrement.';

  @override
  String get settingsSafetyNumberCompareHint =>
      'Comparez ce numéro en personne ou lors d\'un appel sécurisé.';

  @override
  String get callEndToEndEncrypted => 'Chiffré de bout en bout';

  @override
  String get callSecuring => 'Sécurisation de l\'appel…';

  @override
  String get callNotEncrypted => 'Non chiffré';

  @override
  String get callIncomingVoice => 'Appel vocal entrant';

  @override
  String get callIncomingVideo => 'Appel vidéo entrant';

  @override
  String get callVoiceCall => 'Appel vocal';

  @override
  String get callVideoCall => 'Appel vidéo';

  @override
  String get callDecline => 'Refuser';

  @override
  String get callAccept => 'Accepter';

  @override
  String get callConnecting => 'Connexion...';

  @override
  String get callSettingUp => 'Configuration de l\'appel...';

  @override
  String callNotifying(String name) {
    return 'Notification de $name...';
  }

  @override
  String get callRinging => 'Sonnerie...';

  @override
  String get callConnected => 'Connecté';

  @override
  String get callOnHold => 'En attente';

  @override
  String get callCalling => 'Appel en cours...';

  @override
  String get callWaitingForUser => 'En attente du correspondant...';

  @override
  String get callEnded => 'Appel terminé';

  @override
  String get callDeclined => 'Appel refusé';

  @override
  String get callNoAnswer => 'Pas de réponse';

  @override
  String get callFailedToConnect => 'Échec de connexion';

  @override
  String callFailedToStart(String error) {
    return 'Échec du démarrage de l\'appel : $error';
  }

  @override
  String get callTokenExpired =>
      'Jeton expiré ou invalide. Veuillez relancer l\'appel.';

  @override
  String callFailedToInit(String type, String error) {
    return 'Échec de l\'initialisation de l\'appel $type : $error';
  }

  @override
  String get callTurnOffSpeaker => 'Désactiver le haut-parleur';

  @override
  String get callTurnOnSpeaker => 'Activer le haut-parleur';

  @override
  String get callMuteMic => 'Couper le micro';

  @override
  String get callUnmuteMic => 'Activer le micro';

  @override
  String get callEndCall => 'Raccrocher';

  @override
  String get callSwitchCamera => 'Changer de caméra';

  @override
  String get callTurnOffCamera => 'Désactiver la caméra';

  @override
  String get callTurnOnCamera => 'Activer la caméra';

  @override
  String statusViewedByCount(int count) {
    return 'Vu par $count';
  }

  @override
  String get statusNoViewsYet => 'Aucune vue pour l\'instant';

  @override
  String statusViewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vues',
      one: '1 vue',
    );
    return '$_temp0';
  }

  @override
  String get statusDeleteTitle => 'Supprimer le statut';

  @override
  String get statusDeleteConfirm =>
      'Voulez-vous vraiment supprimer ce statut ?';

  @override
  String get statusDeleteButton => 'Supprimer';

  @override
  String get statusReplySent => 'Réponse envoyée';

  @override
  String statusReplyFailed(String error) {
    return 'Échec de l\'envoi de la réponse : $error';
  }

  @override
  String get statusNoActive => 'Aucun statut actif';

  @override
  String get statusCouldNotLoad => 'Impossible de charger cette mise à jour';

  @override
  String get statusTapToRetry => 'Appuyez pour réessayer';

  @override
  String get statusFailedToLoadImage => 'Échec du chargement de l\'image';

  @override
  String get statusLoadingVideo => 'Chargement de la vidéo...';

  @override
  String get statusEnterTextPrompt => 'Veuillez saisir un texte';

  @override
  String get statusNoContactsNotice =>
      'Aucun contact — lancez une conversation avant de publier un statut.';

  @override
  String statusPostFailed(String error) {
    return 'Échec de la publication du statut : $error';
  }

  @override
  String get statusTypeHint => 'Écrivez un statut...';

  @override
  String get statusCamera => 'Appareil photo';

  @override
  String get statusTakePhoto => 'Prendre une photo';

  @override
  String get statusGalleryPhoto => 'Photo de la galerie';

  @override
  String get statusChooseImageGallery => 'Choisir une photo dans la galerie';

  @override
  String get statusRecordVideo => 'Enregistrer une vidéo';

  @override
  String get statusRecordShortVideo => 'Enregistrer une courte vidéo';

  @override
  String get statusGalleryVideo => 'Vidéo de la galerie';

  @override
  String get statusChooseVideoGallery => 'Choisir une vidéo dans la galerie';

  @override
  String statusFailedPickImage(String error) {
    return 'Échec de la sélection de photo : $error';
  }

  @override
  String statusFailedPickVideo(String error) {
    return 'Échec de la sélection de vidéo : $error';
  }

  @override
  String get statusChangeBgColorTooltip => 'Changer la couleur d\'arrière-plan';

  @override
  String aiMessagesRemaining(int count) {
    return '$count restants';
  }

  @override
  String get aiQuotaDialogTitle => 'Messages GupAI';

  @override
  String aiQuotaRemainingOfTotal(int remaining, int total) {
    return '$remaining sur $total restants aujourd\'hui';
  }

  @override
  String aiQuotaUsedResetNote(int used) {
    return '$used utilisés aujourd\'hui · réinitialisation demain. Regardez une publicité ou passez à Pro.';
  }

  @override
  String get aiQuotaGotIt => 'Compris';

  @override
  String get aiTitle => 'GupAI';

  @override
  String get aiSubtitle => 'Votre assistant intégré';

  @override
  String get aiEmptyHelpTitle => 'Comment puis-je vous aider ?';

  @override
  String get aiEmptyHelpSubtitle =>
      'Rédigez des réponses, traduisez, résumez ou posez une question.';

  @override
  String get meshOfflineChatConnected => 'Discussion hors-ligne · connectée';

  @override
  String get meshConnecting => 'Connexion…';

  @override
  String get meshBannerNotice =>
      'Discussion hors-ligne — sans internet ni serveurs';

  @override
  String meshSayHiTo(String name) {
    return 'Dites bonjour à $name';
  }

  @override
  String meshOfflineDescription(String name) {
    return 'Vous êtes en discussion hors-ligne. Les messages restent entre vous et $name.';
  }

  @override
  String get meshMediaUnavailable => 'Ce média n\'est plus disponible.';

  @override
  String get meshViewOnceTitle => 'Vue unique';

  @override
  String meshViewOncePrompt(String type) {
    return 'Vous ne pouvez ouvrir ce $type qu\'une seule fois.';
  }

  @override
  String get arcadeTabOverview => 'Aperçu';

  @override
  String get arcadeTabChallenges => 'Défis';

  @override
  String get arcadeTabLeaderboard => 'Classement';

  @override
  String get arcadeFailedLoadStats => 'Échec du chargement des statistiques.';

  @override
  String get aiAskHint => 'Demandez n\'importe quoi à GupAI…';
}
