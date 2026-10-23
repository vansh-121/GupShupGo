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
  String get homeNavChats => 'Messages';

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
  String get homeMenuPrivateVault => 'Coffre privé';

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
  String get attachmentScreenShare => 'Partager l\'écran';

  @override
  String get attachmentScreenShareSubtitle =>
      'Affichez votre écran en direct pendant la discussion';

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

  @override
  String get settingsNotificationsTile => 'Notifications';

  @override
  String get settingsNotificationsStatusOn => 'Activé';

  @override
  String get settingsNotificationsStatusOff => 'Désactivé';

  @override
  String get settingsNotificationsEnabledToast =>
      'Les notifications sont activées.';

  @override
  String get settingsEnableNotificationsTitle => 'Activer les notifications';

  @override
  String get settingsEnableNotificationsBody =>
      'Les notifications sont désactivées. Ouvrez les paramètres système pour permettre à GupShupGo de vous avertir des nouveaux messages et appels.';

  @override
  String get settingsOpenSystemSettings => 'Ouvrir les paramètres';

  @override
  String get loginTagline =>
      'Messagerie privée qui fonctionne même sans internet.';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsTerms => 'Conditions d\'utilisation';

  @override
  String get settingsDeleteAccount => 'Supprimer le compte';

  @override
  String get inviteSheetTitle => 'Inviter des amis';

  @override
  String get inviteSheetSubtitle => 'Faites passer le mot — partagez GupShupGo';

  @override
  String get inviteShareImageBtn => 'Partager l\'image';

  @override
  String get inviteShareLinkBtn => 'Partager le lien';

  @override
  String get inviteCopyLinkBtn => 'Copier le lien';

  @override
  String get inviteLinkCopied => 'Lien d\'invitation copié';

  @override
  String inviteMessage(String link) {
    return 'Discute avec moi sur GupShupGo — cela fonctionne même sans internet 👋 $link';
  }

  @override
  String get inviteCardTagline => 'Chat privé qui fonctionne même hors ligne';

  @override
  String get inviteCardScan => 'Scannez pour télécharger';

  @override
  String get inviteCardDownload => 'Télécharger sur Google Play';

  @override
  String get homeMenuInvite => 'Inviter des amis';

  @override
  String get invitePromptTitle => 'Vous appréciez GupShupGo ?';

  @override
  String get invitePromptBody =>
      'C\'est mieux avec des amis — et cela fonctionne même sans internet. Inviter quelqu\'un ?';

  @override
  String get invitePromptInvite => 'Inviter des amis';

  @override
  String get invitePromptLater => 'Peut-être plus tard';

  @override
  String get homeOfflineBannerTitle => 'Pas d\'internet ? Aucun problème';

  @override
  String get homeOfflineBannerSubtitle =>
      'Vous pouvez toujours envoyer des messages aux personnes proches via Bluetooth.';

  @override
  String homeNearbyBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes à proximité',
      one: '1 personne à proximité',
    );
    return '$_temp0';
  }

  @override
  String get homeNearbyBannerSubtitle =>
      'Discutez par Bluetooth — pas besoin d\'internet.';

  @override
  String get linkBackupTitle => 'Ajouter une méthode de connexion de secours';

  @override
  String get linkBackupSubtitle =>
      'Liez Google ou un e-mail pour vous reconnecter même sans SIM.';

  @override
  String get linkGoogleTitle => 'Lier un compte Google';

  @override
  String get linkGoogleSubtitleLinked => 'Lié ✓';

  @override
  String get linkGoogleSubtitleUnlinked => 'Connexion en un clic sans SIM';

  @override
  String get linkGoogleAction => 'Lier';

  @override
  String get linkGoogleSuccess => 'Compte Google lié avec succès !';

  @override
  String get linkGoogleAlreadyUsed =>
      'Ce compte Google est déjà enregistré sur un autre compte GupShupGo.';

  @override
  String get linkGoogleFailed => 'Échec de la liaison Google. Réessayez.';

  @override
  String get linkSessionExpired =>
      'Session expirée. Veuillez vous reconnecter.';

  @override
  String get linkEmailTitle => 'Lier e-mail et mot de passe';

  @override
  String get linkEmailSubtitleLinked => 'Lié ✓';

  @override
  String get linkEmailSubtitleUnlinked =>
      'Connectez-vous par e-mail sans SIM ni Google';

  @override
  String get linkEmailActionAdd => 'Ajouter';

  @override
  String get linkEmailActionCancel => 'Annuler';

  @override
  String get linkEmailFieldLabel => 'E-mail';

  @override
  String get linkPasswordFieldLabel => 'Créer un mot de passe';

  @override
  String get linkPasswordHelper => '6 caractères minimum';

  @override
  String get linkEmailButton => 'Lier l\'e-mail';

  @override
  String get linkEmailSuccess => 'E-mail lié avec succès !';

  @override
  String get linkEmailInvalid => 'Entrez une adresse e-mail valide.';

  @override
  String get linkPasswordTooShort =>
      'Le mot de passe doit comporter au moins 6 caractères.';

  @override
  String get linkEmailAlreadyInUse =>
      'Cet e-mail est déjà utilisé sur GupShupGo.';

  @override
  String get linkEmailAlreadyLinked =>
      'Un e-mail est déjà associé à votre compte.';

  @override
  String get linkEmailFailed => 'Échec de la liaison de l\'e-mail.';

  @override
  String get linkContinueToApp => 'Continuer vers l\'application';

  @override
  String get linkSkipForNow => 'Ignorer pour le moment';

  @override
  String get linkSkip => 'Ignorer';

  @override
  String get phoneAuthTitleEntry =>
      'Connectez-vous avec votre numéro de téléphone.';

  @override
  String get phoneAuthTitleOtp => 'Entrez le code reçu.';

  @override
  String get phoneAuthNameHint => 'Votre nom';

  @override
  String get phoneAuthPhoneHint => 'Numéro de téléphone';

  @override
  String get phoneAuthUseSim => 'Utiliser SIM';

  @override
  String get phoneAuthSendOtp => 'Envoyer le code';

  @override
  String phoneAuthOtpPrompt(String phone) {
    return 'Entrez le code à 6 chiffres envoyé au $phone';
  }

  @override
  String get phoneAuthOtpPromptGeneric =>
      'Entrez le code à 6 chiffres que nous vous avons envoyé';

  @override
  String get phoneAuthOtpHint => 'Entrer le code';

  @override
  String get phoneAuthVerify => 'Vérifier';

  @override
  String get phoneAuthGoBack => 'Retour';

  @override
  String get phoneAuthResendCode => 'Renvoyer le code';

  @override
  String get phoneAuthEnterName => 'Veuillez entrer votre nom';

  @override
  String get phoneAuthEnterValidPhone => 'Veuillez entrer un numéro valide';

  @override
  String get phoneAuthEnterCode => 'Veuillez entrer le code';

  @override
  String get phoneAuthRequestNewCode => 'Veuillez demander un nouveau code.';

  @override
  String get phoneAuthCodeIncorrect => 'Ce code est incorrect. Réessayez.';

  @override
  String get phoneAuthErrCodeIncorrect =>
      'Code incorrect. Veuillez vérifier et réessayer.';

  @override
  String get phoneAuthErrCodeExpired =>
      'Code expiré. Appuyez sur \"Renvoyer le code\".';

  @override
  String get phoneAuthErrTooManyRequests =>
      'Trop de tentatives. Veuillez patienter.';

  @override
  String get phoneAuthErrInvalidPhone => 'Numéro de téléphone invalide.';

  @override
  String get phoneAuthErrQuotaExceeded => 'Limite de SMS atteinte.';

  @override
  String get phoneAuthErrFailed => 'Échec de la vérification.';

  @override
  String get usernameSetupAppBarTitle => 'Choisissez votre pseudo';

  @override
  String get usernameSetupHeaderTitle => 'Sécurisez votre identité';

  @override
  String get usernameSetupHeaderDesc =>
      'Votre @handle est votre clé unique sur GupShupGo. Les autres peuvent vous trouver sans votre numéro ni e-mail.';

  @override
  String get usernameSetupInputHint => 'votre_pseudo';

  @override
  String get usernameSetupChecking => 'Vérification de la disponibilité...';

  @override
  String usernameSetupAvailable(String handle) {
    return '@$handle est disponible !';
  }

  @override
  String usernameSetupTaken(String handle) {
    return '@$handle est déjà pris.';
  }

  @override
  String get usernameSetupCharRules => '3 à 20 caractères (a-z, 0-9, _)';

  @override
  String get usernameSetupTooShort => 'Au moins 3 caractères requis.';

  @override
  String get usernameSetupTooLong => '20 caractères maximum.';

  @override
  String get usernameSetupInvalidChars =>
      'Lettres, chiffres et traits de soulignement uniquement.';

  @override
  String get usernameSetupRecommended => 'RECOMMANDÉ POUR VOUS';

  @override
  String get usernameSetupSaveBtn => 'Enregistrer et continuer';

  @override
  String get usernameSetupSkipBtn => 'Ignorer pour le moment';

  @override
  String usernameSetupFailed(String error) {
    return 'Échec de l\'enregistrement du pseudo : $error';
  }

  @override
  String get vaultProtectTitle => 'Protéger le coffre';

  @override
  String get vaultUnlockTitle => 'Déverrouiller le coffre';

  @override
  String get vaultSetupDesc =>
      'Choisissez un code PIN pour chiffrer votre historique. Vous en aurez besoin sur un nouveau téléphone.';

  @override
  String get vaultUnlockDescBio =>
      'Entrez votre PIN ou touchez l\'empreinte pour déchiffrer.';

  @override
  String get vaultUnlockDescPin =>
      'Entrez votre code PIN pour déchiffrer votre historique.';

  @override
  String get vaultReinstallHint =>
      'Entrez votre PIN pour restaurer votre historique sur cet appareil.';

  @override
  String get vaultUnlockWithFingerprint => 'Déverrouiller avec l\'empreinte';

  @override
  String get vaultOrDivider => 'OU';

  @override
  String get vaultNewPin => 'Nouveau PIN';

  @override
  String get vaultConfirmPin => 'Confirmer le PIN';

  @override
  String get vaultEnterPin => 'Entrer le PIN';

  @override
  String get vaultKeyboardUseLetters => 'Utiliser des lettres';

  @override
  String get vaultKeyboardUseNumbers => 'Utiliser des chiffres';

  @override
  String get vaultRestoreLater => 'Restaurer plus tard';

  @override
  String get vaultForgotPin => 'PIN oublié ?';

  @override
  String get vaultSetPinBtn => 'Définir le PIN';

  @override
  String get vaultDecryptBtn => 'Déchiffrer';

  @override
  String get vaultPinMinLength =>
      'Le PIN doit comporter au moins 6 caractères.';

  @override
  String get vaultPinsDoNotMatch => 'Les codes PIN ne correspondent pas.';

  @override
  String get vaultSetupFailed => 'Échec de la configuration.';

  @override
  String get vaultIncorrectPin => 'PIN incorrect. Réessayez.';

  @override
  String get vaultFingerprintOutOfDate =>
      'Empreinte obsolète. Entrez votre PIN.';

  @override
  String get vaultBiometricError =>
      'Erreur biométrique. Entrez le PIN manuellement.';

  @override
  String get vaultBioReasonUnlock =>
      'Authentifiez-vous pour déverrouiller votre coffre';

  @override
  String get vaultBioReasonEnrol =>
      'Confirmez votre empreinte pour activer le déverrouillage rapide';

  @override
  String get vaultAskBioTitle => 'Déverrouiller avec l\'empreinte ?';

  @override
  String get vaultAskBioDesc =>
      'Évitez de taper votre PIN ici. Gardez précieusement votre PIN pour vos futurs appareils.';

  @override
  String get vaultAskBioNotNow => 'Pas maintenant';

  @override
  String get vaultAskBioEnable => 'Activer';

  @override
  String get vaultDeleteMessagesTitle => 'Supprimer tous les messages ?';

  @override
  String get vaultDeleteMessagesDesc =>
      'Sans votre PIN, l\'historique ne peut pas être déchiffré. Tout réinitialiser effacera tout. Irréversible.';

  @override
  String get vaultDeleteMessagesCancel => 'Annuler';

  @override
  String get vaultDeleteMessagesConfirm => 'Tout supprimer';

  @override
  String get vaultCustodyConfirmTitle => 'Confirmez le PIN de votre coffre';

  @override
  String get vaultCustodyChooseTitle => 'Choisissez un PIN';

  @override
  String get vaultCustodyConfirmDesc =>
      'Votre historique est chiffré par un PIN. Confirmez-le.';

  @override
  String get vaultCustodyChooseDesc =>
      'Choisissez un PIN mémorable. Vos messages seront rechiffrés avec ce nouveau code.';

  @override
  String get vaultCustodyDontKnow => 'Je ne connais pas mon PIN';

  @override
  String get vaultCustodyConfirmBtn => 'Confirmer';

  @override
  String get vaultCustodySaveBtn => 'Enregistrer le PIN';

  @override
  String get vaultCustodyMismatchError => 'Ce PIN ne correspond pas.';

  @override
  String get vaultCustodyAutoUpdateFailed =>
      'Mise à jour automatique du PIN impossible.';

  @override
  String vaultCustodyReencrypting(int done, int total) {
    return 'Rechiffrement de $done sur $total… laissez l\'application ouverte.';
  }

  @override
  String get vaultCustodyPreparing =>
      'Préparation… laissez l\'application ouverte.';

  @override
  String get vaultSettingsTitle => 'Coffre-fort';

  @override
  String get vaultSettingsAboutTitle => 'À propos du coffre';

  @override
  String get vaultSettingsAboutDesc =>
      'Sauvegarde privée verrouillée par votre PIN. Seul votre PIN peut l\'ouvrir.';

  @override
  String get vaultSettingsBulletMessages => 'Vos messages';

  @override
  String get vaultSettingsBulletStatuses => 'Les statuts visibles';

  @override
  String get vaultSettingsNeverKept =>
      'Jamais stocké ici : journal d\'appels, contacts ou photos partagées.';

  @override
  String get vaultSettingsSectionPrivacy => 'CONFIDENTIALITÉ';

  @override
  String get vaultSettingsAutoDelete => 'Suppression auto des anciens messages';

  @override
  String get vaultSettingsKeepForever => 'Garder pour toujours';

  @override
  String vaultSettingsDeleteAfter(String label) {
    return 'Supprimer après $label';
  }

  @override
  String get vaultSettingsSectionPin => 'PIN';

  @override
  String get vaultSettingsChangePin => 'Modifier le PIN';

  @override
  String get vaultSettingsChangePinSubtitle =>
      'Rechiffre toutes les données du coffre';

  @override
  String get vaultSettingsBioTitle => 'Déverrouiller par empreinte';

  @override
  String get vaultSettingsBioSubOn => 'Activé sur cet appareil';

  @override
  String get vaultSettingsBioSubOff =>
      'Éviter de taper le PIN sur cet appareil';

  @override
  String get vaultSettingsSectionDanger => 'ZONE DE DANGER';

  @override
  String get vaultSettingsDeleteData => 'Supprimer les données du coffre';

  @override
  String get vaultSettingsDeleteDataSubtitle =>
      'Efface l\'historique chiffré, garde le PIN';

  @override
  String get vaultSettingsResetVault => 'Réinitialiser le coffre';

  @override
  String get vaultSettingsResetVaultSubtitle => 'Oublie le PIN et efface tout';

  @override
  String get vaultSettingsPinChanged => 'PIN modifié.';

  @override
  String get vaultSettingsBioTurnedOff =>
      'Déverrouillage par empreinte désactivé.';

  @override
  String get vaultSettingsBioTurnedOn => 'Déverrouillage par empreinte activé.';

  @override
  String get vaultSettingsClearDataTitle => 'Supprimer les données du coffre ?';

  @override
  String get vaultSettingsClearDataDesc =>
      'Supprime les messages chiffrés du cloud. Votre PIN est conservé.';

  @override
  String get vaultSettingsClearDataCancel => 'Annuler';

  @override
  String get vaultSettingsClearDataConfirm => 'Supprimer les données';

  @override
  String get vaultSettingsDataDeleted => 'Données du coffre supprimées.';

  @override
  String get vaultSettingsResetTitle => 'Réinitialiser le coffre ?';

  @override
  String get vaultSettingsResetDesc =>
      'Supprime le PIN et toutes les données. Vous devrez définir un nouveau PIN.';

  @override
  String get vaultSettingsResetConfirm => 'Réinitialiser';

  @override
  String get vaultSettingsChangeDialogDesc =>
      'Toutes les entrées seront rechiffrées avec le nouveau PIN.';

  @override
  String get vaultSettingsCurrentPin => 'PIN actuel';

  @override
  String get vaultSettingsNewPin => 'Nouveau PIN';

  @override
  String get vaultSettingsConfirmNewPin => 'Confirmer le nouveau PIN';

  @override
  String get vaultSettingsEnterCurrentPin => 'Entrez votre PIN actuel.';

  @override
  String get vaultSettingsNewPinMinLength => 'Au moins 6 caractères requis.';

  @override
  String get vaultSettingsNewPinMismatch =>
      'Les nouveaux codes PIN ne correspondent pas.';

  @override
  String get vaultSettingsCurrentPinIncorrect => 'Le PIN actuel est incorrect.';

  @override
  String vaultSettingsReencryptingCount(int done, int total) {
    return 'Rechiffrement de $done sur $total…';
  }

  @override
  String get vaultSettingsChangeBtn => 'Modifier';

  @override
  String get vaultSettingsBioPinDialogTitle => 'Entrez votre PIN';

  @override
  String get vaultSettingsBioPinDialogDesc =>
      'Votre PIN est requis pour activer l\'empreinte.';

  @override
  String get vaultSettingsContinueBtn => 'Continuer';

  @override
  String get premiumTitle => 'GupShupGo Pro';

  @override
  String get premiumSubtitleMember => 'Vous êtes membre Pro ! 🎉';

  @override
  String get premiumSubtitleUnlock => 'Débloquez l\'expérience complète';

  @override
  String premiumActiveDaysRemaining(int days) {
    return '$days jours restants';
  }

  @override
  String get premiumFeaturesHeader => 'Ce que vous obtenez avec Pro';

  @override
  String get premiumPlansHeader => 'Choisissez votre forfait';

  @override
  String get premiumSubscribeBtn => 'S\'abonner maintenant';

  @override
  String get premiumCancelAnytime => 'Annulable à tout moment sur Google Play.';

  @override
  String get premiumRestoreBtn => 'Restaurer l\'achat';

  @override
  String get premiumRestoring => 'Restauration…';

  @override
  String get premiumRestoredSuccess => 'Abonnement Pro restauré ! 🎉';

  @override
  String get premiumNoActiveSub => 'Aucun abonnement actif trouvé.';

  @override
  String get premiumProductUnavailable => 'Produit non disponible.';

  @override
  String get premiumFeatureMediaTitle => 'Moments Multimédias';

  @override
  String get premiumFeatureMediaDesc =>
      'Partagez des photos et vidéos en statuts';

  @override
  String get premiumFeatureMediaFree => 'Texte uniquement';

  @override
  String get premiumFeatureMediaPro => 'Photos + Vidéos';

  @override
  String get premiumFeatureScreenShareTitle => 'Partage d\'écran';

  @override
  String get premiumFeatureScreenShareDesc =>
      'Partagez votre écran en direct pendant les chats';

  @override
  String get premiumFeatureScreenShareFree => 'Verrouillé';

  @override
  String get premiumFeatureScreenSharePro => 'Accès complet';

  @override
  String get premiumFeatureThemesTitle => 'Thèmes de chat';

  @override
  String get premiumFeatureThemesDesc =>
      'Fonds et bulles personnalisés par chat';

  @override
  String get premiumFeatureThemesFree => '6 thèmes';

  @override
  String get premiumFeatureThemesPro => 'Les 12 + votre propre photo';

  @override
  String get premiumFeatureVoiceTitle => 'Messages vocaux plus longs';

  @override
  String get premiumFeatureVoiceDesc =>
      'Enregistrez des notes vocales prolongées';

  @override
  String get premiumFeatureVoiceFree => '2 minutes';

  @override
  String get premiumFeatureVoicePro => 'Illimité';

  @override
  String get premiumFeatureQualityTitle => 'Qualité média supérieure';

  @override
  String get premiumFeatureQualityDesc =>
      'Photos plus nettes et vidéos de statut de 90s';

  @override
  String get premiumFeatureQualityFree => 'Qualité standard';

  @override
  String get premiumFeatureQualityPro => 'Haute qualité + vidéos 90s';

  @override
  String get premiumFeatureBondTitle => 'Restauration de lien';

  @override
  String get premiumFeatureBondDesc =>
      'Restaurez vos liens brisés gratuitement';

  @override
  String get premiumFeatureBondFree => 'Points ou regarder une pub';

  @override
  String get premiumFeatureBondPro => '1 restauration gratuite/semaine';

  @override
  String get premiumFeatureBadgeTitle => 'Badge Pro';

  @override
  String get premiumFeatureBadgeDesc => 'Affichez votre statut Pro';

  @override
  String get premiumFeatureBadgeFree => 'Pas de badge';

  @override
  String get premiumFeatureBadgePro => 'Badge Pro exclusif';

  @override
  String get premiumFeatureExportTitle => 'Exportation de chat';

  @override
  String get premiumFeatureExportDesc =>
      'Enregistrez vos chats en PDF ou texte brut';

  @override
  String get premiumFeatureExportFree => 'Non disponible';

  @override
  String get premiumFeatureExportPro => 'Export PDF et TXT';

  @override
  String get premiumFeatureAdFreeTitle => 'Sans publicité';

  @override
  String get premiumFeatureAdFreeDesc =>
      'Aucune bannière publicitaire dans l\'application';

  @override
  String get premiumFeatureAdFreeFree => 'Bannières affichées';

  @override
  String get premiumFeatureAdFreePro => 'Aucune bannière';

  @override
  String get premiumPlanMonthly => 'Mensuel';

  @override
  String get premiumPlanYearly => 'Annuel';

  @override
  String get premiumPlanSavings => 'Économisez ~33%';

  @override
  String get premiumPeriodMonth => '/mois';

  @override
  String get premiumPeriodYear => '/an';

  @override
  String get nearbyOfflineChatTitle => 'Chat hors-ligne';

  @override
  String get nearbySearchingDevices => 'Recherche d\'appareils à proximité…';

  @override
  String get nearbyTooltipStop => 'Arrêter le chat hors-ligne';

  @override
  String get nearbyTooltipStart => 'Démarrer le chat hors-ligne';

  @override
  String get nearbyDevicesSection => 'Appareils à proximité';

  @override
  String get nearbyDiscoveryOn => 'DÉCOUVERTE ACTIVÉE';

  @override
  String get nearbyDiscoveryOff => 'DÉCOUVERTE DÉSACTIVÉE';

  @override
  String get nearbyHeroTitle => 'Mode hors-ligne';

  @override
  String nearbyHeroNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count à proximité',
      one: '1 à proximité',
    );
    return '$_temp0';
  }

  @override
  String get nearbyHeroOff => 'Chat hors-ligne désactivé';

  @override
  String get nearbyHeroDesc =>
      'Recherche dans un rayon de 100 mètres. Chiffré et de pair à pair.';

  @override
  String get nearbyYourNameHint => 'Votre nom';

  @override
  String get nearbyEmptySearching => 'Recherche d\'appareils à proximité…';

  @override
  String get nearbyEmptyOff => 'Le chat hors-ligne est désactivé';

  @override
  String get nearbyEmptySearchingDesc =>
      'Vérifiez que GupShupGo est ouvert avec le Bluetooth activé.';

  @override
  String get nearbyEmptyOffDesc =>
      'Touchez l\'icône de démarrage en haut à droite.';

  @override
  String get nearbyPeerConnected => 'Connecté · Touchez pour discuter';

  @override
  String get nearbyPeerConnecting => 'Connexion…';

  @override
  String get nearbyPeerTapToConnect => 'Touchez pour connecter';

  @override
  String get nearbyActionChat => 'Chat';

  @override
  String get nearbyActionConnecting => 'Connexion';

  @override
  String get nearbyActionConnect => 'Connecter';

  @override
  String get nearbyPermNeededTitle => 'Autorisations requises';

  @override
  String get nearbyPermNeededDesc =>
      'Nécessite le Bluetooth et l\'accès aux appareils à proximité.';

  @override
  String get nearbyTryAgainBtn => 'Réessayer';

  @override
  String get nearbySettingsBtn => 'Paramètres';

  @override
  String get nearbyHelpTip =>
      'Vous ne voyez pas votre ami ? Activez le Bluetooth sur les deux appareils.';

  @override
  String get anonLobbyTitle => 'Chat anonyme';

  @override
  String get anonLobbyFinding => 'Recherche d\'un correspondant…';

  @override
  String get anonLobbyHangTight =>
      'Patientez — vous serez mis en relation avec un inconnu.';

  @override
  String get anonLobbyCancelBtn => 'Annuler la recherche';

  @override
  String get anonLobbyPrivacyNote => 'Votre identité reste masquée.';

  @override
  String get anonLobbyConnecting => 'Connexion…';

  @override
  String get anonLobbyWaitingOthers => 'En attente d\'autres utilisateurs…';

  @override
  String anonLobbyOnlineCount(int count) {
    return '$count en ligne actuellement';
  }

  @override
  String get anonChatNotEncrypted =>
      'Les messages ne sont pas chiffrés de bout en bout';

  @override
  String get anonChatRequestSentTooltip => 'Demande envoyée';

  @override
  String get anonChatAddFriendTooltip => 'Ajouter en ami';

  @override
  String get anonChatNextStrangerTooltip => 'Inconnu suivant';

  @override
  String get anonChatReportTooltip => 'Signaler';

  @override
  String get anonChatSayHi => 'Dites bonjour à l\'inconnu ! 👋';

  @override
  String get anonChatFriendsTransition =>
      'Vous êtes maintenant amis ! Ouverture du chat sécurisé…';

  @override
  String get anonChatStrangerDisconnected => 'L\'inconnu s\'est déconnecté 👋';

  @override
  String get anonChatFindNextBtn => 'Trouver un autre inconnu';

  @override
  String get anonChatFriendReqTitle => 'L\'inconnu souhaite se connecter !';

  @override
  String get anonChatFriendReqDesc =>
      'Accepter révélera vos profils réels et lancera un chat chiffré.';

  @override
  String get anonChatDecline => 'Refuser';

  @override
  String get anonChatAccept => 'Accepter';

  @override
  String get anonChatWaitingReqTitle => 'Demande d\'ami envoyée';

  @override
  String get anonChatWaitingReqDesc => 'En attente de la réponse…';

  @override
  String get anonChatReportTitle => 'Signaler l\'inconnu';

  @override
  String get anonChatReportQuestion =>
      'Pourquoi signalez-vous cet utilisateur ?';

  @override
  String get anonChatReportReasonInappropriate => 'Contenu inapproprié';

  @override
  String get anonChatReportReasonHarassment => 'Harcèlement';

  @override
  String get anonChatReportReasonSpam => 'Spam ou arnaque';

  @override
  String get anonChatReportReasonThreatening => 'Comportement menaçant';

  @override
  String get anonChatReportReasonOther => 'Autre';

  @override
  String get anonChatReportCancel => 'Annuler';

  @override
  String get anonChatReportSubmit => 'Signaler et quitter';

  @override
  String get anonChatReportSubmitted =>
      'Signalement envoyé. Merci de protéger GupShupGo.';

  @override
  String get anonChatViewOnceVideoTitle => 'Lire une fois ?';

  @override
  String get anonChatViewOncePhotoTitle => 'Ouvrir une fois ?';

  @override
  String get anonChatViewOnceVideoDesc =>
      'Vous ne pouvez ouvrir cette vidéo qu\'une seule fois.';

  @override
  String get anonChatViewOncePhotoDesc =>
      'Vous ne pouvez ouvrir cette photo qu\'une seule fois.';

  @override
  String get anonChatViewOnceCancel => 'Annuler';

  @override
  String get anonChatViewOnceOpen => 'Ouvrir';

  @override
  String get unsupportedVersionTitle => 'Mettez à jour GupShupGo';

  @override
  String get unsupportedVersionDesc =>
      'Cette version n\'est plus prise en charge. Mettez à jour pour continuer.';

  @override
  String get unsupportedVersionUpdateNow => 'Mettre à jour';

  @override
  String get unsupportedVersionOpenPlayStore => 'Ouvrir Play Store';

  @override
  String publicProfileNotFound(String username) {
    return '@$username introuvable';
  }

  @override
  String get publicProfileUserNotFound => 'Utilisateur introuvable';

  @override
  String get publicProfileNotFoundDesc =>
      'Ce pseudo n\'existe pas ou le lien est cassé.';

  @override
  String get publicProfileTitle => 'Profil';

  @override
  String get publicProfileOnline => 'En ligne';

  @override
  String publicProfileLastSeen(String time) {
    return 'Vu $time';
  }

  @override
  String get publicProfileJustNow => 'à l\'instant';

  @override
  String publicProfileMinutesAgo(int minutes) {
    return 'il y a $minutes min';
  }

  @override
  String publicProfileHoursAgo(int hours) {
    return 'il y a $hours h';
  }

  @override
  String publicProfileDaysAgo(int days) {
    return 'il y a $days j';
  }

  @override
  String publicProfileJoined(String date) {
    return 'Inscrit en $date';
  }

  @override
  String get publicProfileOwnLink =>
      'Il s\'agit de votre propre lien de profil.';

  @override
  String publicProfileGupPoints(int points) {
    return '$points Points Gup';
  }

  @override
  String publicProfileLevel(int level) {
    return 'Niveau $level';
  }

  @override
  String get publicProfileStatPoints => 'Points';

  @override
  String get publicProfileStatBadges => 'Badges';

  @override
  String get publicProfileStatBestBond => 'Meilleur lien';

  @override
  String get publicProfileBadges => 'BADGES';

  @override
  String get qrScannerTitle => 'Scanner code QR';

  @override
  String get qrScannerFlashOnTooltip => 'Activer le flash';

  @override
  String get qrScannerFlashOffTooltip => 'Désactiver le flash';

  @override
  String get qrScannerPrompt =>
      'Pointez votre appareil vers un code QR GupShupGo';

  @override
  String get qrScannerNotProfileCode =>
      'Ce n\'est pas un code de profil GupShupGo.';

  @override
  String get qrScannerCameraErrorTitle => 'Impossible de démarrer la caméra.';

  @override
  String get qrScannerCameraErrorRetry => 'Veuillez réessayer.';

  @override
  String get qrScannerPermissionMsg =>
      'Autorisation de la caméra requise pour scanner.';

  @override
  String get qrScannerPermissionAllow => 'Autoriser la caméra';

  @override
  String get qrScannerBlockedMsg =>
      'Caméra bloquée. Activez-la dans les Paramètres.';

  @override
  String get qrScannerBlockedSettings => 'Ouvrir les paramètres';

  @override
  String get screenShareIncomingTitle => 'Partage d\'écran entrant';

  @override
  String get screenShareWantsToShare => 'souhaite partager son écran';

  @override
  String get screenShareReject => 'Refuser';

  @override
  String get screenShareAccept => 'Accepter';

  @override
  String get screenShareCantAccept =>
      'Impossible d\'accepter. Vérifiez votre connexion.';

  @override
  String screenShareDeclined(String name) {
    return '$name a refusé le partage d\'écran';
  }

  @override
  String get screenShareNoAnswer => 'Pas de réponse';

  @override
  String get screenShareStartError => 'Impossible de démarrer le partage';

  @override
  String get screenShareStatusRequesting => 'Demande d\'autorisation';

  @override
  String get screenShareStatusInitializing => 'Initialisation du flux';

  @override
  String get screenShareStatusWaitingParticipant => 'En attente du participant';

  @override
  String get screenShareStatusActive => 'Partage d\'écran en direct';

  @override
  String screenShareSubWaitingAccept(String name) {
    return 'En attente de l\'acceptation de $name…';
  }

  @override
  String get screenShareSubEstablishing => 'Connexion sécurisée en cours...';

  @override
  String screenShareSubWaitingJoin(String name) {
    return 'En attente de $name...';
  }

  @override
  String get screenShareSubActive =>
      'Votre écran complet est visible en haute définition.';

  @override
  String get screenShareBadgeRequesting => 'DEMANDE';

  @override
  String get screenShareBadgeConnecting => 'CONNEXION';

  @override
  String get screenShareSharedWith => 'Partagé avec ';

  @override
  String get screenShareRequestingFrom => 'Demande à ';

  @override
  String get screenShareMinimizeTip =>
      'Vous pouvez réduire cet écran pour continuer à utiliser l\'application.';

  @override
  String get screenShareStop => 'Arrêter le partage';

  @override
  String get screenShareCancelRequest => 'Annuler la demande';

  @override
  String screenShareViewerTitle(String name) {
    return '$name partage son écran';
  }

  @override
  String get screenShareViewerLive => 'EN DIRECT';

  @override
  String get screenShareViewerMinimize => 'Réduire';

  @override
  String get screenShareViewerLeave => 'Quitter';

  @override
  String screenShareViewerWaitingStream(String name) {
    return 'En attente de l\'écran de $name...';
  }

  @override
  String get screenShareViewerConnecting => 'Connexion au flux...';

  @override
  String get viewOnceVideoTitle => 'Vidéo · Vue unique';

  @override
  String get viewOncePhotoTitle => 'Photo · Vue unique';

  @override
  String get viewOnceCantOpen => 'Impossible d\'ouvrir ce média.';

  @override
  String get viewOnceUnavailable => 'Ce média n\'est plus disponible.';

  @override
  String get viewOnceBlockedFooter => 'Captures d\'écran bloquées.';

  @override
  String get anonRestoreBanner => 'Afficher la bannière du chat anonyme';

  @override
  String get contactsInviteFriends => 'Inviter des amis sur GupShupGo';

  @override
  String get inviteImageShareFailed =>
      'Impossible de partager l’image. Réessayez ou partagez le lien.';

  @override
  String get viewOnceUnblockedFooter =>
      'Ouverture unique. Impossible de bloquer les captures sur iOS.';

  @override
  String get tabMessages => 'Messages';
}
