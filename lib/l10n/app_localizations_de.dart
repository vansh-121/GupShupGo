// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonOk => 'OK';

  @override
  String get commonContinue => 'Weiter';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonGotIt => 'Verstanden';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageSubtitle => 'Wähle deine bevorzugte Sprache';

  @override
  String get languagePickerTitle => 'Sprache';

  @override
  String get languageSystemDefault => 'Systemstandard';

  @override
  String get languageSystemDefaultSubtitle => 'Der Gerätesprache folgen';

  @override
  String get loginContinueWithPhone => 'Mit Telefon fortfahren';

  @override
  String get loginContinueWithGoogle => 'Mit Google fortfahren';

  @override
  String get loginUseEmailPassword => 'E-Mail & Passwort verwenden';

  @override
  String get loginSignIn => 'Anmelden';

  @override
  String get loginSignUp => 'Registrieren';

  @override
  String get loginCreateAccount => 'Konto erstellen';

  @override
  String get loginForgotPassword => 'Passwort vergessen?';

  @override
  String get loginOfflineChat => 'Offline-Chat';

  @override
  String get loginHintName => 'Dein Name';

  @override
  String get loginHintEmail => 'E-Mail';

  @override
  String get loginHintPassword => 'Passwort';

  @override
  String get loginPasswordHelper =>
      'Mindestens 8 Zeichen, mit Buchstabe und Zahl';

  @override
  String loginResetEmailSent(String email) {
    return 'E-Mail zum Zurücksetzen des Passworts an $email gesendet';
  }

  @override
  String get loginErrorEnterEmail => 'Bitte gib deine E-Mail-Adresse ein';

  @override
  String get loginErrorValidEmail =>
      'Bitte gib eine gültige E-Mail-Adresse ein';

  @override
  String get loginErrorEnterPassword => 'Bitte gib dein Passwort ein';

  @override
  String get loginErrorPasswordMin6 =>
      'Das Passwort muss mindestens 6 Zeichen lang sein';

  @override
  String get loginErrorEnterPasswordSignup => 'Bitte gib ein Passwort ein';

  @override
  String get loginErrorPasswordMin8 =>
      'Das Passwort muss mindestens 8 Zeichen lang sein';

  @override
  String get loginErrorPasswordLetter =>
      'Das Passwort muss mindestens einen Buchstaben enthalten';

  @override
  String get loginErrorPasswordNumber =>
      'Das Passwort muss mindestens eine Zahl enthalten';

  @override
  String get loginErrorEnterName => 'Bitte gib deinen Namen ein';

  @override
  String get loginErrorGoogleCancelled => 'Google-Anmeldung wurde abgebrochen.';

  @override
  String get loginErrorProfileLoad =>
      'Profil konnte nicht geladen werden. Verbindung prüfen und erneut versuchen.';

  @override
  String get loginErrorGoogleFailed =>
      'Google-Anmeldung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get loginErrorSignInFailed =>
      'Anmeldung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get loginErrorSignUpFailed =>
      'Registrierung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get loginErrorGeneric =>
      'Ein Fehler ist aufgetreten. Bitte erneut versuchen.';

  @override
  String get loginErrorResetFailed =>
      'E-Mail zum Zurücksetzen konnte nicht gesendet werden. Bitte erneut versuchen.';

  @override
  String get loginErrorUserNotFound =>
      'Kein Konto mit dieser E-Mail gefunden. Bitte registrieren.';

  @override
  String get loginErrorWrongPassword =>
      'Falsches Passwort. Bitte erneut versuchen.';

  @override
  String get loginErrorEmailInUse =>
      'Ein Konto mit dieser E-Mail existiert bereits. Bitte anmelden.';

  @override
  String get loginErrorInvalidEmail =>
      'Bitte gib eine gültige E-Mail-Adresse ein.';

  @override
  String get loginErrorWeakPassword =>
      'Passwort ist zu schwach. Mindestens 6 Zeichen verwenden.';

  @override
  String get loginErrorInvalidCredential =>
      'Ungültige E-Mail oder Passwort. Bitte überprüfen und erneut versuchen.';

  @override
  String get loginErrorTooManyRequests =>
      'Zu viele Versuche. Bitte versuche es später noch einmal.';

  @override
  String get homeNavChats => 'Nachrichten';

  @override
  String get homeNavMoments => 'Momente';

  @override
  String get homeNavCalls => 'Anrufe';

  @override
  String get homeNavProfile => 'Profil';

  @override
  String get homeTooltipOfflineChat =>
      'Offline-Chat — mit Personen in der Nähe sprechen';

  @override
  String get homeTooltipSearch => 'Suchen';

  @override
  String get homeMenuProfile => 'Profil';

  @override
  String get homeMenuPrivateVault => 'Privater Tresor';

  @override
  String get homeMenuSettings => 'Einstellungen';

  @override
  String get homeMenuRateUs => 'Bewerte uns';

  @override
  String get homeMenuReportIssue => 'Problem melden';

  @override
  String get homeMenuWhatsNew => 'Was gibt\'s Neues';

  @override
  String get homeMenuLogOut => 'Abmelden';

  @override
  String get homeEmptyChatsTitle => 'Noch keine Chats';

  @override
  String get homeEmptyChatsSubtitle =>
      'Starte ein Gespräch über die Schaltfläche unten';

  @override
  String get homeNewChatButton => 'Neuer Chat';

  @override
  String get homeAiAssistantTitle => 'GupAI';

  @override
  String get homeAiAssistantSubtitle =>
      'Verfassen, übersetzen, zusammenfassen und mehr';

  @override
  String get homeStrangerMatchTitle => 'Mit Fremden verbinden';

  @override
  String get homeStrangerMatchSubtitle =>
      'Anonymer Chat — tippen zum Verbinden!';

  @override
  String get homeMyMoment => 'Mein Moment';

  @override
  String get homeRecentMoments => 'Aktuelle Momente';

  @override
  String get homeEmptyMomentsTitle => 'Noch keine Updates.';

  @override
  String get homeEmptyMomentsSubtitle => 'Tippe auf die Kamera zum Teilen.';

  @override
  String get homeTapToAddMoment => 'Tippen, um ein Update hinzuzufügen';

  @override
  String get homeEmptyCallsTitle => 'Kein Anrufverlauf';

  @override
  String get homeEmptyCallsSubtitle =>
      'Deine letzten Anrufe werden hier angezeigt';

  @override
  String get chatInputHint => 'Nachricht...';

  @override
  String get chatSearchHint => 'Nachrichten durchsuchen...';

  @override
  String get chatStatusTyping => 'tippt...';

  @override
  String get chatStatusOnline => 'Online';

  @override
  String get chatStatusOffline => 'Offline';

  @override
  String chatStatusLastSeen(String time) {
    return 'Zuletzt online $time';
  }

  @override
  String get chatEndToEndEncrypted => 'Ende-zu-Ende-verschlüsselt';

  @override
  String get chatNoInternetOfflineTitle =>
      'Kein Internet? Offline mit Geräten in der Nähe chatten';

  @override
  String get chatEnableOfflineButton => 'Aktivieren';

  @override
  String get chatSlideToCancel => 'Zum Abbrechen wischen';

  @override
  String get chatTooltipVoiceCall => 'Sprachanruf';

  @override
  String get chatTooltipVideoCall => 'Videoanruf';

  @override
  String get chatMenuContactInfo => 'Kontaktinfo';

  @override
  String get chatMenuSearch => 'Suchen';

  @override
  String get chatMenuChatTheme => 'Chat-Design';

  @override
  String get chatMenuExportChat => 'Chat exportieren';

  @override
  String get chatMenuMuteNotifications => 'Stummschalten';

  @override
  String get chatMenuUnmuteNotifications => 'Stummschaltung aufheben';

  @override
  String get chatMenuBlockContact => 'Kontakt blockieren';

  @override
  String get chatActionReply => 'Antworten';

  @override
  String get chatActionCopy => 'Kopieren';

  @override
  String get chatActionForward => 'Weiterleiten';

  @override
  String get chatActionTranslate => 'Übersetzen';

  @override
  String get chatActionSummarise => 'Zusammenfassen';

  @override
  String get chatActionAskGupAi => 'GupAI fragen';

  @override
  String get chatActionEdit => 'Bearbeiten';

  @override
  String get chatActionDelete => 'Löschen';

  @override
  String get chatDeleteMessageTitle => 'Nachricht löschen?';

  @override
  String get chatDeleteMessageForEveryonePrompt =>
      'Nur für dich oder für alle in diesem Chat löschen?';

  @override
  String chatDeleteMessageForMeOnlyPrompt(String name) {
    return 'Wird nur von deinen Geräten entfernt. $name kann sie weiterhin sehen.';
  }

  @override
  String get chatDeleteForMe => 'Für mich löschen';

  @override
  String get chatDeleteForEveryone => 'Für alle löschen';

  @override
  String chatBlockContactTitle(String name) {
    return '$name blockieren?';
  }

  @override
  String get chatBlockContactPrompt =>
      'Blockierte Kontakte können dir keine Nachrichten senden oder anrufen. Du kannst sie unter Einstellungen → Datenschutz freigeben.';

  @override
  String get chatBlockButton => 'Blockieren';

  @override
  String get chatForwardTo => 'Weiterleiten an';

  @override
  String get chatNoForwardChats => 'Keine anderen Chats zum Weiterleiten';

  @override
  String get chatCannotSendMediaBlocked =>
      'An diesen Kontakt können keine Medien gesendet werden';

  @override
  String get attachmentShareTitle => 'Teilen';

  @override
  String get attachmentPhoto => 'Foto';

  @override
  String get attachmentPhotoSubtitle => 'Wähle ein Bild aus deiner Galerie';

  @override
  String get attachmentVideo => 'Video';

  @override
  String get attachmentVideoSubtitle => 'Wähle ein Video aus deiner Galerie';

  @override
  String get attachmentDocument => 'Dokument';

  @override
  String get attachmentDocumentSubtitle =>
      'PDF, Office-Datei, Archiv — unverändert gesendet';

  @override
  String get attachmentLocation => 'Standort';

  @override
  String get attachmentLocationSubtitle => 'Teile deinen aktuellen Standort';

  @override
  String get attachmentScreenShare => 'Bildschirm teilen';

  @override
  String get attachmentScreenShareSubtitle =>
      'Zeigen Sie Ihren Bildschirm live während des Chats';

  @override
  String get attachmentViewOnce => 'Einmal ansehen';

  @override
  String get attachmentViewOnceSubtitle =>
      'Foto oder Video verschwindet nach dem Öffnen';

  @override
  String get contactsTitle => 'Kontakte & Entdecken';

  @override
  String get contactsTabFriends => 'Freunde';

  @override
  String get contactsTabRequests => 'Anfragen';

  @override
  String get contactsTabDiscover => 'Entdecken';

  @override
  String get contactsScanQrTooltip => 'QR-Code scannen';

  @override
  String get contactsMyHandleTooltip => 'Mein Benutzername';

  @override
  String get contactsSetUsernamePrompt =>
      'Lege zuerst einen @benutzernamen in deinem Profil fest — dieser wird per QR-Code geteilt.';

  @override
  String get contactsMyQrCodeTitle => 'Mein Profil-QR-Code';

  @override
  String get contactsMyQrCodeSubtitle =>
      'Freunde können diesen QR-Code scannen, um sich sofort zu verbinden';

  @override
  String get contactsCopyProfileLink => 'Profillink kopieren';

  @override
  String contactsProfileLinkCopied(String username) {
    return 'Profillink für @$username kopiert!';
  }

  @override
  String get contactsScanSomeonesCode => 'Fremden Code scannen';

  @override
  String get contactsPermissionDenied =>
      'Zugriff auf Kontakte wurde verweigert.';

  @override
  String get contactsNoUsersFound =>
      'Bisher keine GupShupGo-Nutzer in deinen Kontakten gefunden.';

  @override
  String contactsFailedToSync(String error) {
    return 'Kontakte konnten nicht synchronisiert werden: $error';
  }

  @override
  String contactsMatchedCount(int count) {
    return '$count Kontakte auf GupShupGo';
  }

  @override
  String get contactsFromDeviceContacts => 'Aus deinen Telefonkontakten';

  @override
  String get contactsLoadFriendsError =>
      'Freunde konnten nicht geladen werden.';

  @override
  String get contactsNoFriendsTitle => 'Noch keine Freunde hinzugefügt';

  @override
  String get contactsNoFriendsPrompt =>
      'Nutze den Reiter Entdecken, um Nutzer per @benutzername, Telefon oder E-Mail zu finden!';

  @override
  String get contactsDiscoverPeopleButton => 'Personen entdecken';

  @override
  String get contactsQuickConnectHeader => 'SCHNELLVERBINDUNG';

  @override
  String get contactsNoSuggestions => 'Zurzeit keine Vorschläge verfügbar.';

  @override
  String get contactsLoadRequestsError =>
      'Anfragen konnten nicht geladen werden.';

  @override
  String contactsPendingRequestsHeader(int count) {
    return 'OFFENE ANFRAGEN ($count)';
  }

  @override
  String get contactsNoPendingRequestsTitle => 'Keine offenen Anfragen';

  @override
  String get contactsNoPendingRequestsSubtitle =>
      'Wenn dir jemand eine Anfrage sendet, erscheint sie hier.';

  @override
  String get contactsWantsToConnect => 'Möchte sich verbinden';

  @override
  String get contactsAcceptButton => 'ANNEHMEN';

  @override
  String get contactsAcceptFailed =>
      'Anfrage konnte nicht angenommen werden. Bitte erneut versuchen.';

  @override
  String contactsConnectedWith(String name) {
    return 'Mit $name verbunden!';
  }

  @override
  String get contactsDeclineFailed =>
      'Anfrage konnte nicht abgelehnt werden. Bitte erneut versuchen.';

  @override
  String get contactsYouMightKnowHeader => 'VIELLEICHT KENNST DU';

  @override
  String get contactsSeeAll => 'ALLE ANZEIGEN';

  @override
  String get contactsSearchHint =>
      'Name, @benutzername, Telefon oder E-Mail suchen...';

  @override
  String get contactsTurnOnDiscoverability =>
      'Aktiviere die Auffindbarkeit, um in der Suche zu erscheinen.';

  @override
  String get contactsNoMatchingUsersTitle => 'Keine passenden Nutzer gefunden';

  @override
  String get contactsNoMatchingUsersSubtitle =>
      'Prüfe @benutzernamen, Telefonnummer oder E-Mail und versuche es erneut.';

  @override
  String get contactsDiscoverHeroTitle => 'Entdecke Leute auf GupShupGo';

  @override
  String get contactsDiscoverHeroSubtitle =>
      'Erweitere dein Netzwerk mit weltweiten Kontakten.';

  @override
  String get contactsSyncDeviceContacts => 'Gerätekontakte synchronisieren';

  @override
  String get contactsSyncingContacts => 'Kontakte werden synchronisiert...';

  @override
  String get contactsSyncDeviceSubtitle =>
      'Finde Freunde direkt aus deinem Adressbuch';

  @override
  String get contactsSuggestedUsersHeader => 'VORGESCHLAGENE NUTZER';

  @override
  String get contactsAddFriendButton => 'FREUND HINZUFÜGEN';

  @override
  String get contactsRequestedButton => 'Angefragt';

  @override
  String contactsRequestSent(String name) {
    return 'Freundschaftsanfrage an $name gesendet!';
  }

  @override
  String get contactsRequestFailed =>
      'Anfrage steht bereits aus oder ist fehlgeschlagen.';

  @override
  String get contactsRequestUnavailable =>
      'Diese Anfrage ist nicht mehr verfügbar.';

  @override
  String get profileEditTitle => 'Profil bearbeiten';

  @override
  String get profileSaveButton => 'Speichern';

  @override
  String get profileTapToChangePhoto => 'Tippen, um Foto zu ändern';

  @override
  String get profileUpgradeToPro => 'Auf Pro upgraden';

  @override
  String get profileSectionName => 'DEIN NAME';

  @override
  String get profileNameHint => 'Gib deinen Namen ein';

  @override
  String get profileSectionHandle => 'EINDEUTIGER BENUTZERNAME';

  @override
  String get profileHandleNotSet => 'Noch nicht festgelegt';

  @override
  String get profileChangeHandle => 'Ändern';

  @override
  String get profileSectionAbout => 'INFO';

  @override
  String get profileAboutHint => 'Was gibt\'s Neues?';

  @override
  String get profileDefaultAbout => 'Hallo! Ich nutze GupShupGo.';

  @override
  String get profileSectionPhone => 'TELEFON';

  @override
  String get profileSectionEmail => 'E-MAIL';

  @override
  String get profileSectionLinkedMethods => 'VERKNÜPFTE ANMELDEVERFAHREN';

  @override
  String get profileNotLinked => 'Nicht verknüpft';

  @override
  String get profileNameEmpty => 'Name darf nicht leer sein.';

  @override
  String get profileUpdatedSuccess => 'Profil aktualisiert';

  @override
  String profileUploadPhotoFailed(String error) {
    return 'Foto-Upload fehlgeschlagen: $error';
  }

  @override
  String profileSaveFailed(String error) {
    return 'Profil konnte nicht gespeichert werden: $error';
  }

  @override
  String get profilePoints => 'Punkte';

  @override
  String get profileBadges => 'Abzeichen';

  @override
  String get profileBestBond => 'Beste Serie';

  @override
  String get settingsAccountCard => 'Konto';

  @override
  String get settingsProfileTile => 'Profil';

  @override
  String get settingsLinkedMethodsTile => 'Verknüpfte Anmeldemethoden';

  @override
  String get settingsPhoneTile => 'Telefonnummer';

  @override
  String get settingsEmailTile => 'E-Mail';

  @override
  String get settingsPrivacyCard => 'Datenschutz';

  @override
  String get settingsDiscoverability => 'Auffindbarkeit';

  @override
  String get settingsLastSeen => 'Zuletzt online';

  @override
  String get settingsReadReceipts => 'Lesebestätigungen';

  @override
  String get settingsAdPreferences => 'Werbeeinstellungen';

  @override
  String get settingsManage => 'Verwalten';

  @override
  String get settingsAppearanceCard => 'Erscheinungsbild';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsChatTheme => 'Chat-Design';

  @override
  String get settingsHelpSecurityCard => 'Hilfe & Sicherheit';

  @override
  String get settingsHelpCenter => 'Hilfebereich';

  @override
  String get settingsReportProblem => 'Problem melden';

  @override
  String get settingsE2EEShield => 'Ende-zu-Ende-Verschlüsselung (Tresor)';

  @override
  String get settingsVerifySafetyNumber => 'Sicherheitsnummer überprüfen';

  @override
  String get settingsBlockedContacts => 'Blockierte Kontakte';

  @override
  String get settingsClearAllGupHistory => 'Gesamten Chatverlauf löschen';

  @override
  String get settingsRateUs => 'App bewerten';

  @override
  String get settingsWhatsNew => 'Was ist neu';

  @override
  String get settingsCheckForUpdates => 'Nach Updates suchen';

  @override
  String get settingsAppInfo => 'App-Info';

  @override
  String get settingsLogOut => 'Abmelden';

  @override
  String get settingsLogOutConfirmTitle => 'Abmelden';

  @override
  String get settingsLogOutConfirmPrompt =>
      'Möchtest du dich wirklich von GupShupGo abmelden?';

  @override
  String get settingsSigningOut => 'Wird abgemeldet…';

  @override
  String get settingsClearChatsConfirmTitle => 'Alle Chats leeren';

  @override
  String get settingsClearChatsConfirmPrompt =>
      'Dies löscht deinen gesamten Nachrichtenverlauf dauerhaft. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get settingsDeleteAll => 'Alles löschen';

  @override
  String get settingsClearingChats => 'Chats werden geleert...';

  @override
  String get settingsAllChatsCleared => 'Alle Chats wurden geleert';

  @override
  String settingsClearChatsFailed(String error) {
    return 'Chats konnten nicht geleert werden: $error';
  }

  @override
  String get settingsChooseThemeTitle => 'Design wählen';

  @override
  String get settingsUnlockPremiumFeatures => 'Premium-Funktionen freischalten';

  @override
  String settingsProDaysLeft(String planLabel, int daysRemaining) {
    return '$planLabel · Noch $daysRemaining Tage';
  }

  @override
  String get settingsCheckingForUpdates => 'Suche nach Updates…';

  @override
  String settingsUpToDate(String version) {
    return 'Du hast die neueste Version (v$version).';
  }

  @override
  String get settingsUpdateCheckUnavailable =>
      'Updates konnten nicht geprüft werden. Bitte stelle sicher, dass die App aus dem Google Play Store stammt.';

  @override
  String get settingsNoBlockedContacts => 'Keine blockierten Kontakte';

  @override
  String get settingsUnblock => 'Freigeben';

  @override
  String settingsUserUnblocked(String name) {
    return '$name freigegeben';
  }

  @override
  String get settingsVerifyContactTitle => 'Kontakt verifizieren';

  @override
  String get settingsVerifyContactSubtitle =>
      'Wähle einen Kontakt, um die gemeinsame Sicherheitsnummer anzuzeigen.';

  @override
  String get settingsComputingSafetyNumber =>
      'Sicherheitsnummer wird berechnet…';

  @override
  String settingsSafetyNumberExplanation(String name) {
    return 'Wenn die Nummer mit dem Gerät von $name übereinstimmt, ist die Verschlüsselung verifiziert.';
  }

  @override
  String get settingsSafetyNumberNoBundle =>
      'Dieser Kontakt hat noch kein Verschlüsselungs-Schlüsselpaket veröffentlicht.';

  @override
  String get settingsSafetyNumberCompareHint =>
      'Vergleiche diese Nummer persönlich oder bei einem gesicherten Anruf.';

  @override
  String get callEndToEndEncrypted => 'Ende-zu-Ende-verschlüsselt';

  @override
  String get callSecuring => 'Anruf wird gesichert…';

  @override
  String get callNotEncrypted => 'Nicht verschlüsselt';

  @override
  String get callIncomingVoice => 'Eingehender Sprachanruf';

  @override
  String get callIncomingVideo => 'Eingehender Videoanruf';

  @override
  String get callVoiceCall => 'Sprachanruf';

  @override
  String get callVideoCall => 'Videoanruf';

  @override
  String get callDecline => 'Ablehnen';

  @override
  String get callAccept => 'Annehmen';

  @override
  String get callConnecting => 'Verbinden...';

  @override
  String get callSettingUp => 'Anruf wird eingerichtet...';

  @override
  String callNotifying(String name) {
    return '$name wird benachrichtigt...';
  }

  @override
  String get callRinging => 'Klingelt...';

  @override
  String get callConnected => 'Verbunden';

  @override
  String get callOnHold => 'Gehalten';

  @override
  String get callCalling => 'Wählt...';

  @override
  String get callWaitingForUser => 'Warten auf Gesprächspartner...';

  @override
  String get callEnded => 'Anruf beendet';

  @override
  String get callDeclined => 'Anruf abgelehnt';

  @override
  String get callNoAnswer => 'Keine Antwort';

  @override
  String get callFailedToConnect => 'Verbindung fehlgeschlagen';

  @override
  String callFailedToStart(String error) {
    return 'Anruf konnte nicht gestartet werden: $error';
  }

  @override
  String get callTokenExpired =>
      'Token abgelaufen oder ungültig. Bitte Anruf neu starten.';

  @override
  String callFailedToInit(String type, String error) {
    return '$type-Anruf konnte nicht initialisiert werden: $error';
  }

  @override
  String get callTurnOffSpeaker => 'Lautsprecher ausschalten';

  @override
  String get callTurnOnSpeaker => 'Lautsprecher einschalten';

  @override
  String get callMuteMic => 'Mikrofon stummschalten';

  @override
  String get callUnmuteMic => 'Mikrofon einschalten';

  @override
  String get callEndCall => 'Anruf beenden';

  @override
  String get callSwitchCamera => 'Kamera wechseln';

  @override
  String get callTurnOffCamera => 'Kamera ausschalten';

  @override
  String get callTurnOnCamera => 'Kamera einschalten';

  @override
  String statusViewedByCount(int count) {
    return 'Gesehen von $count';
  }

  @override
  String get statusNoViewsYet => 'Noch keine Aufrufe';

  @override
  String statusViewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufrufe',
      one: '1 Aufruf',
    );
    return '$_temp0';
  }

  @override
  String get statusDeleteTitle => 'Status löschen';

  @override
  String get statusDeleteConfirm =>
      'Möchten Sie diesen Status wirklich löschen?';

  @override
  String get statusDeleteButton => 'Löschen';

  @override
  String get statusReplySent => 'Antwort gesendet';

  @override
  String statusReplyFailed(String error) {
    return 'Antwort konnte nicht gesendet werden: $error';
  }

  @override
  String get statusNoActive => 'Kein aktiver Status';

  @override
  String get statusCouldNotLoad => 'Aktualisierung konnte nicht geladen werden';

  @override
  String get statusTapToRetry => 'Tippen zum Wiederholen';

  @override
  String get statusFailedToLoadImage => 'Bild konnte nicht geladen werden';

  @override
  String get statusLoadingVideo => 'Video wird geladen...';

  @override
  String get statusEnterTextPrompt => 'Bitte Text eingeben';

  @override
  String get statusNoContactsNotice =>
      'Noch keine Kontakte — starten Sie einen Chat, bevor Sie posten.';

  @override
  String statusPostFailed(String error) {
    return 'Status konnte nicht gepostet werden: $error';
  }

  @override
  String get statusTypeHint => 'Schreibe einen Status...';

  @override
  String get statusCamera => 'Kamera';

  @override
  String get statusTakePhoto => 'Foto aufnehmen';

  @override
  String get statusGalleryPhoto => 'Galeriefoto';

  @override
  String get statusChooseImageGallery => 'Bild aus Galerie wählen';

  @override
  String get statusRecordVideo => 'Video aufnehmen';

  @override
  String get statusRecordShortVideo => 'Kurzes Video aufnehmen';

  @override
  String get statusGalleryVideo => 'Galerievideo';

  @override
  String get statusChooseVideoGallery => 'Video aus Galerie wählen';

  @override
  String statusFailedPickImage(String error) {
    return 'Bildauswahl fehlgeschlagen: $error';
  }

  @override
  String statusFailedPickVideo(String error) {
    return 'Videoauswahl fehlgeschlagen: $error';
  }

  @override
  String get statusChangeBgColorTooltip => 'Hintergrundfarbe ändern';

  @override
  String aiMessagesRemaining(int count) {
    return '$count übrig';
  }

  @override
  String get aiQuotaDialogTitle => 'GupAI-Nachrichten';

  @override
  String aiQuotaRemainingOfTotal(int remaining, int total) {
    return 'Heute $remaining von $total übrig';
  }

  @override
  String aiQuotaUsedResetNote(int used) {
    return 'Heute $used verbraucht · wird morgen zurückgesetzt. Schauen Sie Werbung oder holen Sie Pro.';
  }

  @override
  String get aiQuotaGotIt => 'Verstanden';

  @override
  String get aiTitle => 'GupAI';

  @override
  String get aiSubtitle => 'Ihr In-App-Assistent';

  @override
  String get aiEmptyHelpTitle => 'Wie kann ich helfen?';

  @override
  String get aiEmptyHelpSubtitle =>
      'Antworten entwerfen, übersetzen, zusammenfassen oder Fragen stellen.';

  @override
  String get meshOfflineChatConnected => 'Offline-Chat · verbunden';

  @override
  String get meshConnecting => 'Verbinden…';

  @override
  String get meshBannerNotice => 'Offline-Chat — kein Internet, keine Server';

  @override
  String meshSayHiTo(String name) {
    return 'Sag Hallo zu $name';
  }

  @override
  String meshOfflineDescription(String name) {
    return 'Sie sind im Offline-Chat. Nachrichten bleiben zwischen Ihnen und $name.';
  }

  @override
  String get meshMediaUnavailable => 'Dieses Medium ist nicht mehr verfügbar.';

  @override
  String get meshViewOnceTitle => 'Einmal ansehen';

  @override
  String meshViewOncePrompt(String type) {
    return 'Sie können dieses $type nur einmal öffnen.';
  }

  @override
  String get arcadeTabOverview => 'Übersicht';

  @override
  String get arcadeTabChallenges => 'Herausforderungen';

  @override
  String get arcadeTabLeaderboard => 'Bestenliste';

  @override
  String get arcadeFailedLoadStats =>
      'Statistiken konnten nicht geladen werden.';

  @override
  String get aiAskHint => 'Frage GupAI irgendetwas…';

  @override
  String get settingsNotificationsTile => 'Benachrichtigungen';

  @override
  String get settingsNotificationsStatusOn => 'Ein';

  @override
  String get settingsNotificationsStatusOff => 'Aus';

  @override
  String get settingsNotificationsEnabledToast =>
      'Benachrichtigungen sind aktiviert.';

  @override
  String get settingsEnableNotificationsTitle =>
      'Benachrichtigungen aktivieren';

  @override
  String get settingsEnableNotificationsBody =>
      'Benachrichtigungen sind deaktiviert. Öffne die Systemeinstellungen, damit GupShupGo dich über neue Nachrichten und Anrufe informieren kann.';

  @override
  String get settingsOpenSystemSettings => 'Einstellungen öffnen';

  @override
  String get loginTagline =>
      'Privates Messaging, das sogar ohne Internet funktioniert.';

  @override
  String get settingsPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get settingsTerms => 'Nutzungsbedingungen';

  @override
  String get settingsDeleteAccount => 'Konto löschen';

  @override
  String get inviteSheetTitle => 'Freunde einladen';

  @override
  String get inviteSheetSubtitle => 'Erzähle es weiter — teile GupShupGo';

  @override
  String get inviteShareImageBtn => 'Bild teilen';

  @override
  String get inviteShareLinkBtn => 'Link teilen';

  @override
  String get inviteCopyLinkBtn => 'Link kopieren';

  @override
  String get inviteLinkCopied => 'Einladungslink kopiert';

  @override
  String inviteMessage(String link) {
    return 'Chatte mit mir auf GupShupGo — es funktioniert sogar ohne Internet 👋 $link';
  }

  @override
  String get inviteCardTagline =>
      'Privater Chat, der sogar offline funktioniert';

  @override
  String get inviteCardScan => 'Zum Herunterladen scannen';

  @override
  String get inviteCardDownload => 'Auf Google Play herunterladen';

  @override
  String get homeMenuInvite => 'Freunde einladen';

  @override
  String get invitePromptTitle => 'Gefällt dir GupShupGo?';

  @override
  String get invitePromptBody =>
      'Mit Freunden ist es besser — und es funktioniert sogar ohne Internet. Jemanden einladen?';

  @override
  String get invitePromptInvite => 'Freunde einladen';

  @override
  String get invitePromptLater => 'Vielleicht später';

  @override
  String get homeOfflineBannerTitle => 'Kein Internet? Kein Problem';

  @override
  String get homeOfflineBannerSubtitle =>
      'Du kannst Personen in der Nähe immer noch über Bluetooth Nachrichten senden.';

  @override
  String homeNearbyBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen in der Nähe',
      one: '1 Person in der Nähe',
    );
    return '$_temp0';
  }

  @override
  String get homeNearbyBannerSubtitle =>
      'Über Bluetooth chatten — kein Internet erforderlich.';

  @override
  String get linkBackupTitle => 'Backup-Anmeldemethode hinzufügen';

  @override
  String get linkBackupSubtitle =>
      'Google oder E-Mail verknüpfen, um sich auch ohne SIM anzumelden.';

  @override
  String get linkGoogleTitle => 'Google-Konto verknüpfen';

  @override
  String get linkGoogleSubtitleLinked => 'Verknüpft ✓';

  @override
  String get linkGoogleSubtitleUnlinked => 'One-Tap-Anmeldung ohne SIM';

  @override
  String get linkGoogleAction => 'Verknüpfen';

  @override
  String get linkGoogleSuccess => 'Google-Konto erfolgreich verknüpft!';

  @override
  String get linkGoogleAlreadyUsed =>
      'Dieses Google-Konto ist bereits registriert.';

  @override
  String get linkGoogleFailed =>
      'Verknüpfung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get linkSessionExpired => 'Sitzung abgelaufen. Bitte erneut anmelden.';

  @override
  String get linkEmailTitle => 'E-Mail & Passwort verknüpfen';

  @override
  String get linkEmailSubtitleLinked => 'Verknüpft ✓';

  @override
  String get linkEmailSubtitleUnlinked =>
      'Mit E-Mail anmelden ohne SIM oder Google';

  @override
  String get linkEmailActionAdd => 'Hinzufügen';

  @override
  String get linkEmailActionCancel => 'Abbrechen';

  @override
  String get linkEmailFieldLabel => 'E-Mail';

  @override
  String get linkPasswordFieldLabel => 'Passwort erstellen';

  @override
  String get linkPasswordHelper => 'Mindestens 6 Zeichen';

  @override
  String get linkEmailButton => 'E-Mail verknüpfen';

  @override
  String get linkEmailSuccess => 'E-Mail erfolgreich verknüpft!';

  @override
  String get linkEmailInvalid => 'Gültige E-Mail-Adresse eingeben.';

  @override
  String get linkPasswordTooShort =>
      'Passwort muss mindestens 6 Zeichen lang sein.';

  @override
  String get linkEmailAlreadyInUse => 'Diese E-Mail ist bereits registriert.';

  @override
  String get linkEmailAlreadyLinked => 'Ein Konto ist bereits verknüpft.';

  @override
  String get linkEmailFailed => 'E-Mail-Verknüpfung fehlgeschlagen.';

  @override
  String get linkContinueToApp => 'Weiter zur App';

  @override
  String get linkSkipForNow => 'Vorläufig überspringen';

  @override
  String get linkSkip => 'Überspringen';

  @override
  String get phoneAuthTitleEntry => 'Mit Handynummer anmelden.';

  @override
  String get phoneAuthTitleOtp => 'Code eingeben.';

  @override
  String get phoneAuthNameHint => 'Ihr Name';

  @override
  String get phoneAuthPhoneHint => 'Telefonnummer';

  @override
  String get phoneAuthUseSim => 'SIM nutzen';

  @override
  String get phoneAuthSendOtp => 'Code senden';

  @override
  String phoneAuthOtpPrompt(String phone) {
    return '6-stelligen Code eingeben, der an $phone gesendet wurde';
  }

  @override
  String get phoneAuthOtpPromptGeneric => 'Geben Sie den 6-stelligen Code ein';

  @override
  String get phoneAuthOtpHint => 'Code eingeben';

  @override
  String get phoneAuthVerify => 'Bestätigen';

  @override
  String get phoneAuthGoBack => 'Zurück';

  @override
  String get phoneAuthResendCode => 'Code erneut senden';

  @override
  String get phoneAuthEnterName => 'Bitte Namen eingeben';

  @override
  String get phoneAuthEnterValidPhone => 'Bitte gültige Telefonnummer eingeben';

  @override
  String get phoneAuthEnterCode => 'Bitte Code eingeben';

  @override
  String get phoneAuthRequestNewCode => 'Bitte neuen Code anfordern.';

  @override
  String get phoneAuthCodeIncorrect => 'Falscher Code. Bitte erneut versuchen.';

  @override
  String get phoneAuthErrCodeIncorrect => 'Code ist falsch. Bitte überprüfen.';

  @override
  String get phoneAuthErrCodeExpired => 'Code abgelaufen. Neuen anfordern.';

  @override
  String get phoneAuthErrTooManyRequests => 'Zu viele Versuche. Bitte warten.';

  @override
  String get phoneAuthErrInvalidPhone => 'Ungültige Telefonnummer.';

  @override
  String get phoneAuthErrQuotaExceeded => 'SMS-Limit erreicht.';

  @override
  String get phoneAuthErrFailed => 'Verifizierung fehlgeschlagen.';

  @override
  String get usernameSetupAppBarTitle => 'Benutzernamen wählen';

  @override
  String get usernameSetupHeaderTitle => 'Identität sichern';

  @override
  String get usernameSetupHeaderDesc =>
      'Ihr @handle ist Ihr eindeutiger Schlüssel auf GupShupGo. Andere können Sie ohne Telefonnummer oder E-Mail finden.';

  @override
  String get usernameSetupInputHint => 'dein_name';

  @override
  String get usernameSetupChecking => 'Verfügbarkeit wird geprüft...';

  @override
  String usernameSetupAvailable(String handle) {
    return '@$handle ist verfügbar!';
  }

  @override
  String usernameSetupTaken(String handle) {
    return '@$handle ist bereits vergeben.';
  }

  @override
  String get usernameSetupCharRules => '3–20 Zeichen (a-z, 0-9, _)';

  @override
  String get usernameSetupTooShort => 'Mindestens 3 Zeichen erforderlich.';

  @override
  String get usernameSetupTooLong => 'Maximal 20 Zeichen erlaubt.';

  @override
  String get usernameSetupInvalidChars =>
      'Nur Buchstaben, Zahlen und Unterstriche erlaubt.';

  @override
  String get usernameSetupRecommended => 'FÜR DICH EMPFOHLEN';

  @override
  String get usernameSetupSaveBtn => 'Speichern & Weiter';

  @override
  String get usernameSetupSkipBtn => 'Vorläufig überspringen';

  @override
  String usernameSetupFailed(String error) {
    return 'Fehler beim Festlegen des Benutzernamens: $error';
  }

  @override
  String get vaultProtectTitle => 'Tresor schützen';

  @override
  String get vaultUnlockTitle => 'Tresor entsperren';

  @override
  String get vaultSetupDesc =>
      'Wählen Sie eine PIN, um Ihren Nachrichtenverlauf zu verschlüsseln.';

  @override
  String get vaultUnlockDescBio => 'PIN eingeben oder Fingerabdruck scannen.';

  @override
  String get vaultUnlockDescPin => 'PIN eingeben, um Verlauf zu entschlüsseln.';

  @override
  String get vaultReinstallHint =>
      'PIN eingeben, um Verlauf wiederherzustellen.';

  @override
  String get vaultUnlockWithFingerprint => 'Mit Fingerabdruck entsperren';

  @override
  String get vaultOrDivider => 'ODER';

  @override
  String get vaultNewPin => 'Neue PIN';

  @override
  String get vaultConfirmPin => 'PIN bestätigen';

  @override
  String get vaultEnterPin => 'PIN eingeben';

  @override
  String get vaultKeyboardUseLetters => 'Buchstaben verwenden';

  @override
  String get vaultKeyboardUseNumbers => 'Zahlen verwenden';

  @override
  String get vaultRestoreLater => 'Später wiederherstellen';

  @override
  String get vaultForgotPin => 'PIN vergessen?';

  @override
  String get vaultSetPinBtn => 'PIN festlegen';

  @override
  String get vaultDecryptBtn => 'Entschlüsseln';

  @override
  String get vaultPinMinLength => 'PIN muss mindestens 6 Zeichen lang sein.';

  @override
  String get vaultPinsDoNotMatch => 'PINs stimmen nicht überein.';

  @override
  String get vaultSetupFailed => 'Einrichtung fehlgeschlagen.';

  @override
  String get vaultIncorrectPin => 'Falsche PIN. Erneut versuchen.';

  @override
  String get vaultFingerprintOutOfDate =>
      'Fingerabdruck veraltet. PIN eingeben.';

  @override
  String get vaultBiometricError => 'Biometriefehler. PIN manuell eingeben.';

  @override
  String get vaultBioReasonUnlock => 'Mit Biometrie Tresor entsperren';

  @override
  String get vaultBioReasonEnrol =>
      'Fingerabdruck bestätigen für Schnellzugriff';

  @override
  String get vaultAskBioTitle => 'Mit Fingerabdruck entsperren?';

  @override
  String get vaultAskBioDesc =>
      'PIN-Eingabe auf diesem Gerät überspringen. PIN für Neugeräte sicher aufbewahren.';

  @override
  String get vaultAskBioNotNow => 'Nicht jetzt';

  @override
  String get vaultAskBioEnable => 'Aktivieren';

  @override
  String get vaultDeleteMessagesTitle => 'Alle Nachrichten löschen?';

  @override
  String get vaultDeleteMessagesDesc =>
      'Ohne PIN kann der Verlauf nicht entschlüsselt werden. Beim Zurücksetzen wird alles gelöscht.';

  @override
  String get vaultDeleteMessagesCancel => 'Abbrechen';

  @override
  String get vaultDeleteMessagesConfirm => 'Alles löschen';

  @override
  String get vaultCustodyConfirmTitle => 'Tresor-PIN bestätigen';

  @override
  String get vaultCustodyChooseTitle => 'PIN wählen';

  @override
  String get vaultCustodyConfirmDesc =>
      'Ihr Verlauf ist mit einer PIN geschützt. Einmal bestätigen.';

  @override
  String get vaultCustodyChooseDesc =>
      'Merken Sie sich die PIN gut. Alle Nachrichten werden neu verschlüsselt.';

  @override
  String get vaultCustodyDontKnow => 'Ich kenne meine PIN nicht';

  @override
  String get vaultCustodyConfirmBtn => 'Bestätigen';

  @override
  String get vaultCustodySaveBtn => 'PIN speichern';

  @override
  String get vaultCustodyMismatchError => 'PIN stimmt nicht überein.';

  @override
  String get vaultCustodyAutoUpdateFailed =>
      'Automatische Aktualisierung fehlgeschlagen.';

  @override
  String vaultCustodyReencrypting(int done, int total) {
    return '$done von $total werden neu verschlüsselt… App geöffnet lassen.';
  }

  @override
  String get vaultCustodyPreparing => 'Vorbereitung… App geöffnet lassen.';

  @override
  String get vaultSettingsTitle => 'Tresor';

  @override
  String get vaultSettingsAboutTitle => 'Über den Tresor';

  @override
  String get vaultSettingsAboutDesc =>
      'Privates Backup Ihrer Chats, mit PIN gesichert. Nur Ihre PIN kann es öffnen.';

  @override
  String get vaultSettingsBulletMessages => 'Ihre Nachrichten';

  @override
  String get vaultSettingsBulletStatuses => 'Sichtbare Statusmeldungen';

  @override
  String get vaultSettingsNeverKept =>
      'Wird nie gespeichert: Anrufverlauf, Kontakte oder geteilte Fotos.';

  @override
  String get vaultSettingsSectionPrivacy => 'DATENSCHUTZ';

  @override
  String get vaultSettingsAutoDelete => 'Alte Nachrichten automatisch löschen';

  @override
  String get vaultSettingsKeepForever => 'Für immer behalten';

  @override
  String vaultSettingsDeleteAfter(String label) {
    return 'Löschen nach $label';
  }

  @override
  String get vaultSettingsSectionPin => 'PIN';

  @override
  String get vaultSettingsChangePin => 'PIN ändern';

  @override
  String get vaultSettingsChangePinSubtitle =>
      'Verschlüsselt alle Einträge neu';

  @override
  String get vaultSettingsBioTitle => 'Mit Fingerabdruck entsperren';

  @override
  String get vaultSettingsBioSubOn => 'Auf diesem Gerät aktiviert';

  @override
  String get vaultSettingsBioSubOff =>
      'PIN-Eingabe auf diesem Gerät überspringen';

  @override
  String get vaultSettingsSectionDanger => 'GEFAHRENZONE';

  @override
  String get vaultSettingsDeleteData => 'Tresordaten löschen';

  @override
  String get vaultSettingsDeleteDataSubtitle => 'Löscht Verlauf, behält PIN';

  @override
  String get vaultSettingsResetVault => 'Tresor zurücksetzen';

  @override
  String get vaultSettingsResetVaultSubtitle => 'Vergisst PIN und löscht alles';

  @override
  String get vaultSettingsPinChanged => 'PIN geändert.';

  @override
  String get vaultSettingsBioTurnedOff => 'Fingerabdruck deaktiviert.';

  @override
  String get vaultSettingsBioTurnedOn => 'Fingerabdruck aktiviert.';

  @override
  String get vaultSettingsClearDataTitle => 'Tresordaten löschen?';

  @override
  String get vaultSettingsClearDataDesc =>
      'Löscht verschlüsselte Nachrichten aus der Cloud. PIN bleibt erhalten.';

  @override
  String get vaultSettingsClearDataCancel => 'Abbrechen';

  @override
  String get vaultSettingsClearDataConfirm => 'Daten löschen';

  @override
  String get vaultSettingsDataDeleted => 'Tresordaten gelöscht.';

  @override
  String get vaultSettingsResetTitle => 'Tresor zurücksetzen?';

  @override
  String get vaultSettingsResetDesc =>
      'Löscht PIN und alle Daten unwiderruflich.';

  @override
  String get vaultSettingsResetConfirm => 'Zurücksetzen';

  @override
  String get vaultSettingsChangeDialogDesc =>
      'Alle Einträge werden neu verschlüsselt.';

  @override
  String get vaultSettingsCurrentPin => 'Aktuelle PIN';

  @override
  String get vaultSettingsNewPin => 'Neue PIN';

  @override
  String get vaultSettingsConfirmNewPin => 'Neue PIN bestätigen';

  @override
  String get vaultSettingsEnterCurrentPin => 'Aktuelle PIN eingeben.';

  @override
  String get vaultSettingsNewPinMinLength =>
      'Mindestens 6 Zeichen erforderlich.';

  @override
  String get vaultSettingsNewPinMismatch => 'Neue PINs stimmen nicht überein.';

  @override
  String get vaultSettingsCurrentPinIncorrect => 'Aktuelle PIN ist falsch.';

  @override
  String vaultSettingsReencryptingCount(int done, int total) {
    return '$done von $total werden neu verschlüsselt…';
  }

  @override
  String get vaultSettingsChangeBtn => 'Ändern';

  @override
  String get vaultSettingsBioPinDialogTitle => 'PIN eingeben';

  @override
  String get vaultSettingsBioPinDialogDesc =>
      'PIN wird benötigt, um Fingerabdruck zu aktivieren.';

  @override
  String get vaultSettingsContinueBtn => 'Weiter';

  @override
  String get premiumTitle => 'GupShupGo Pro';

  @override
  String get premiumSubtitleMember => 'Du bist Pro-Mitglied! 🎉';

  @override
  String get premiumSubtitleUnlock => 'Das volle Erlebnis freischalten';

  @override
  String premiumActiveDaysRemaining(int days) {
    return '$days Tage verbleibend';
  }

  @override
  String get premiumFeaturesHeader => 'Deine Pro-Vorteile';

  @override
  String get premiumPlansHeader => 'Wähle deinen Tarif';

  @override
  String get premiumSubscribeBtn => 'Jetzt abonnieren';

  @override
  String get premiumCancelAnytime => 'Jederzeit über Google Play kündbar.';

  @override
  String get premiumRestoreBtn => 'Kauf wiederherstellen';

  @override
  String get premiumRestoring => 'Wiederherstellung…';

  @override
  String get premiumRestoredSuccess => 'Pro-Abo wiederhergestellt! 🎉';

  @override
  String get premiumNoActiveSub => 'Kein aktives Abo gefunden.';

  @override
  String get premiumProductUnavailable => 'Produkt nicht verfügbar.';

  @override
  String get premiumFeatureMediaTitle => 'Medien-Momente';

  @override
  String get premiumFeatureMediaDesc => 'Fotos und Videos als Status teilen';

  @override
  String get premiumFeatureMediaFree => 'Nur Text';

  @override
  String get premiumFeatureMediaPro => 'Fotos + Videos';

  @override
  String get premiumFeatureScreenShareTitle => 'Bildschirmfreigabe';

  @override
  String get premiumFeatureScreenShareDesc => 'Bildschirm live im Chat teilen';

  @override
  String get premiumFeatureScreenShareFree => 'Gesperrt';

  @override
  String get premiumFeatureScreenSharePro => 'Voller Zugriff';

  @override
  String get premiumFeatureThemesTitle => 'Chat-Designs';

  @override
  String get premiumFeatureThemesDesc => 'Muster und Verläufe pro Chat';

  @override
  String get premiumFeatureThemesFree => '6 Designs';

  @override
  String get premiumFeatureThemesPro => 'Alle 12 + eigenes Foto';

  @override
  String get premiumFeatureVoiceTitle => 'Längere Sprachnachrichten';

  @override
  String get premiumFeatureVoiceDesc => 'Längere Sprachnotizen aufnehmen';

  @override
  String get premiumFeatureVoiceFree => '2 Minuten';

  @override
  String get premiumFeatureVoicePro => 'Unbegrenzt';

  @override
  String get premiumFeatureQualityTitle => 'Höhere Medienqualität';

  @override
  String get premiumFeatureQualityDesc => 'Schärfere Fotos & 90s Statusvideos';

  @override
  String get premiumFeatureQualityFree => 'Standardqualität';

  @override
  String get premiumFeatureQualityPro => 'Hohe Qualität + 90s Videos';

  @override
  String get premiumFeatureBondTitle => 'Band wiederherstellen';

  @override
  String get premiumFeatureBondDesc => 'Verlorene Bänder kostenlos retten';

  @override
  String get premiumFeatureBondFree => 'Punkte oder Werbung';

  @override
  String get premiumFeatureBondPro => '1 Gratis-Rettung/Woche';

  @override
  String get premiumFeatureBadgeTitle => 'Pro-Abzeichen';

  @override
  String get premiumFeatureBadgeDesc => 'Zeige deinen Pro-Status';

  @override
  String get premiumFeatureBadgeFree => 'Kein Abzeichen';

  @override
  String get premiumFeatureBadgePro => 'Exklusives Pro-Abzeichen';

  @override
  String get premiumFeatureExportTitle => 'Chat-Export';

  @override
  String get premiumFeatureExportDesc =>
      'Chats als PDF oder Textdatei speichern';

  @override
  String get premiumFeatureExportFree => 'Nicht verfügbar';

  @override
  String get premiumFeatureExportPro => 'PDF- & TXT-Export';

  @override
  String get premiumFeatureAdFreeTitle => 'Werbefreiheit';

  @override
  String get premiumFeatureAdFreeDesc => 'Keine Bannerwerbung in der App';

  @override
  String get premiumFeatureAdFreeFree => 'Banner enthalten';

  @override
  String get premiumFeatureAdFreePro => 'Keine Banner';

  @override
  String get premiumPlanMonthly => 'Monatlich';

  @override
  String get premiumPlanYearly => 'Jährlich';

  @override
  String get premiumPlanSavings => '~33% sparen';

  @override
  String get premiumPeriodMonth => '/Monat';

  @override
  String get premiumPeriodYear => '/Jahr';

  @override
  String get nearbyOfflineChatTitle => 'Offline-Chat';

  @override
  String get nearbySearchingDevices => 'Suche nach Geräten in der Nähe…';

  @override
  String get nearbyTooltipStop => 'Offline-Chat beenden';

  @override
  String get nearbyTooltipStart => 'Offline-Chat starten';

  @override
  String get nearbyDevicesSection => 'Geräte in der Nähe';

  @override
  String get nearbyDiscoveryOn => 'SUCHE AN';

  @override
  String get nearbyDiscoveryOff => 'SUCHE AUS';

  @override
  String get nearbyHeroTitle => 'Offline-Modus';

  @override
  String nearbyHeroNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count in der Nähe',
      one: '1 in der Nähe',
    );
    return '$_temp0';
  }

  @override
  String get nearbyHeroOff => 'Offline-Chat ist aus';

  @override
  String get nearbyHeroDesc =>
      'Sucht im Umkreis von 100 m. Verschlüsselt von Gerät zu Gerät.';

  @override
  String get nearbyYourNameHint => 'Dein Name';

  @override
  String get nearbyEmptySearching => 'Suche nach Geräten in der Nähe…';

  @override
  String get nearbyEmptyOff => 'Offline-Chat ist deaktiviert';

  @override
  String get nearbyEmptySearchingDesc =>
      'GupShupGo mit aktivem Bluetooth auf anderen Geräten öffnen.';

  @override
  String get nearbyEmptyOffDesc => 'Auf das Start-Symbol oben rechts tippen.';

  @override
  String get nearbyPeerConnected => 'Verbunden · Tippen zum Chatten';

  @override
  String get nearbyPeerConnecting => 'Verbinde…';

  @override
  String get nearbyPeerTapToConnect => 'Tippen zum Verbinden';

  @override
  String get nearbyActionChat => 'Chat';

  @override
  String get nearbyActionConnecting => 'Verbinde';

  @override
  String get nearbyActionConnect => 'Verbinden';

  @override
  String get nearbyPermNeededTitle => 'Berechtigungen erforderlich';

  @override
  String get nearbyPermNeededDesc =>
      'Benötigt Bluetooth- und Gerätezugriff in der Nähe.';

  @override
  String get nearbyTryAgainBtn => 'Erneut versuchen';

  @override
  String get nearbySettingsBtn => 'Einstellungen';

  @override
  String get nearbyHelpTip =>
      'Freund nicht sichtbar? Bluetooth auf beiden Geräten prüfen.';

  @override
  String get anonLobbyTitle => 'Anonymer Chat';

  @override
  String get anonLobbyFinding => 'Suche Gesprächspartner…';

  @override
  String get anonLobbyHangTight =>
      'Einen Moment — Verbindung mit Fremden wird hergestellt.';

  @override
  String get anonLobbyCancelBtn => 'Suche abbrechen';

  @override
  String get anonLobbyPrivacyNote => 'Deine Identität bleibt geheim.';

  @override
  String get anonLobbyConnecting => 'Verbinde…';

  @override
  String get anonLobbyWaitingOthers => 'Warte auf andere Online-Nutzer…';

  @override
  String anonLobbyOnlineCount(int count) {
    return '$count gerade online';
  }

  @override
  String get anonChatNotEncrypted =>
      'Nachrichten sind nicht Ende-zu-Ende verschlüsselt';

  @override
  String get anonChatRequestSentTooltip => 'Anfrage gesendet';

  @override
  String get anonChatAddFriendTooltip => 'Freund hinzufügen';

  @override
  String get anonChatNextStrangerTooltip => 'Nächster Fremder';

  @override
  String get anonChatReportTooltip => 'Melden';

  @override
  String get anonChatSayHi => 'Sag Hallo! 👋';

  @override
  String get anonChatFriendsTransition =>
      'Ihr seid jetzt befreundet! Sicherer Chat öffnet sich…';

  @override
  String get anonChatStrangerDisconnected =>
      'Gesprächspartner hat den Chat verlassen 👋';

  @override
  String get anonChatFindNextBtn => 'Nächsten Fremden suchen';

  @override
  String get anonChatFriendReqTitle =>
      'Gesprächspartner möchte sich verbinden!';

  @override
  String get anonChatFriendReqDesc =>
      'Bei Annahme wird das echte Profil geteilt und ein sicherer Chat gestartet.';

  @override
  String get anonChatDecline => 'Ablehnen';

  @override
  String get anonChatAccept => 'Annehmen';

  @override
  String get anonChatWaitingReqTitle => 'Freundschaftsanfrage gesendet';

  @override
  String get anonChatWaitingReqDesc => 'Warte auf Antwort…';

  @override
  String get anonChatReportTitle => 'Nutzer melden';

  @override
  String get anonChatReportQuestion => 'Warum meldest du diesen Nutzer?';

  @override
  String get anonChatReportReasonInappropriate => 'Unangemessener Inhalt';

  @override
  String get anonChatReportReasonHarassment => 'Belästigung';

  @override
  String get anonChatReportReasonSpam => 'Spam oder Betrug';

  @override
  String get anonChatReportReasonThreatening => 'Bedrohliches Verhalten';

  @override
  String get anonChatReportReasonOther => 'Sonstiges';

  @override
  String get anonChatReportCancel => 'Abbrechen';

  @override
  String get anonChatReportSubmit => 'Melden & Verlassen';

  @override
  String get anonChatReportSubmitted =>
      'Meldung gesendet. Danke für deine Mithilfe.';

  @override
  String get anonChatViewOnceVideoTitle => 'Einmal abspielen?';

  @override
  String get anonChatViewOncePhotoTitle => 'Einmal ansehen?';

  @override
  String get anonChatViewOnceVideoDesc =>
      'Dieses Video kann nur einmal geöffnet werden.';

  @override
  String get anonChatViewOncePhotoDesc =>
      'Dieses Foto kann nur einmal geöffnet werden.';

  @override
  String get anonChatViewOnceCancel => 'Abbrechen';

  @override
  String get anonChatViewOnceOpen => 'Öffnen';

  @override
  String get unsupportedVersionTitle => 'GupShupGo aktualisieren';

  @override
  String get unsupportedVersionDesc =>
      'Diese Version wird nicht mehr unterstützt. Bitte aktualisieren.';

  @override
  String get unsupportedVersionUpdateNow => 'Jetzt aktualisieren';

  @override
  String get unsupportedVersionOpenPlayStore => 'Play Store öffnen';

  @override
  String publicProfileNotFound(String username) {
    return '@$username nicht gefunden';
  }

  @override
  String get publicProfileUserNotFound => 'Benutzer nicht gefunden';

  @override
  String get publicProfileNotFoundDesc =>
      'Dieser Benutzername existiert nicht.';

  @override
  String get publicProfileTitle => 'Profil';

  @override
  String get publicProfileOnline => 'Online';

  @override
  String publicProfileLastSeen(String time) {
    return 'Zuletzt online $time';
  }

  @override
  String get publicProfileJustNow => 'gerade eben';

  @override
  String publicProfileMinutesAgo(int minutes) {
    return 'vor $minutes Min.';
  }

  @override
  String publicProfileHoursAgo(int hours) {
    return 'vor $hours Std.';
  }

  @override
  String publicProfileDaysAgo(int days) {
    return 'vor $days Tg.';
  }

  @override
  String publicProfileJoined(String date) {
    return 'Dabei seit $date';
  }

  @override
  String get publicProfileOwnLink => 'Das ist dein eigener Profillink.';

  @override
  String publicProfileGupPoints(int points) {
    return '$points Gup-Punkte';
  }

  @override
  String publicProfileLevel(int level) {
    return 'Level $level';
  }

  @override
  String get publicProfileStatPoints => 'Punkte';

  @override
  String get publicProfileStatBadges => 'Abzeichen';

  @override
  String get publicProfileStatBestBond => 'Bester Streak';

  @override
  String get publicProfileBadges => 'ABZEICHEN';

  @override
  String get qrScannerTitle => 'QR-Code scannen';

  @override
  String get qrScannerFlashOnTooltip => 'Blitz ein';

  @override
  String get qrScannerFlashOffTooltip => 'Blitz aus';

  @override
  String get qrScannerPrompt => 'Kamera auf einen GupShupGo QR-Code richten';

  @override
  String get qrScannerNotProfileCode => 'Kein gültiger GupShupGo-Code.';

  @override
  String get qrScannerCameraErrorTitle =>
      'Kamera konnte nicht gestartet werden.';

  @override
  String get qrScannerCameraErrorRetry => 'Bitte erneut versuchen.';

  @override
  String get qrScannerPermissionMsg =>
      'Kamerazugriff zum Scannen erforderlich.';

  @override
  String get qrScannerPermissionAllow => 'Kamera erlauben';

  @override
  String get qrScannerBlockedMsg =>
      'Kamera ist blockiert. In den Einstellungen aktivieren.';

  @override
  String get qrScannerBlockedSettings => 'Einstellungen öffnen';

  @override
  String get screenShareIncomingTitle => 'Eingehende Bildschirmfreigabe';

  @override
  String get screenShareWantsToShare => 'möchte den Bildschirm teilen';

  @override
  String get screenShareReject => 'Ablehnen';

  @override
  String get screenShareAccept => 'Annehmen';

  @override
  String get screenShareCantAccept =>
      'Annahme fehlgeschlagen. Verbindung prüfen.';

  @override
  String screenShareDeclined(String name) {
    return '$name hat abgelehnt';
  }

  @override
  String get screenShareNoAnswer => 'Keine Antwort';

  @override
  String get screenShareStartError => 'Freigabe konnte nicht gestartet werden';

  @override
  String get screenShareStatusRequesting => 'Frage Erlaubnis an';

  @override
  String get screenShareStatusInitializing => 'Übertragung startet';

  @override
  String get screenShareStatusWaitingParticipant => 'Warte auf Teilnehmer';

  @override
  String get screenShareStatusActive => 'Bildschirmfreigabe aktiv';

  @override
  String screenShareSubWaitingAccept(String name) {
    return 'Warte auf Bestätigung von $name…';
  }

  @override
  String get screenShareSubEstablishing =>
      'Verschlüsselte Verbindung wird aufgebaut...';

  @override
  String screenShareSubWaitingJoin(String name) {
    return 'Warte auf Beitritt von $name...';
  }

  @override
  String get screenShareSubActive => 'Dein kompletter Bildschirm wird geteilt.';

  @override
  String get screenShareBadgeRequesting => 'ANFRAGE';

  @override
  String get screenShareBadgeConnecting => 'VERBINDE';

  @override
  String get screenShareSharedWith => 'Geteilt mit ';

  @override
  String get screenShareRequestingFrom => 'Anfrage an ';

  @override
  String get screenShareMinimizeTip => 'Du kannst dieses Fenster minimieren.';

  @override
  String get screenShareStop => 'Freigabe beenden';

  @override
  String get screenShareCancelRequest => 'Anfrage abbrechen';

  @override
  String screenShareViewerTitle(String name) {
    return '$name teilt den Bildschirm';
  }

  @override
  String get screenShareViewerLive => 'LIVE';

  @override
  String get screenShareViewerMinimize => 'Minimieren';

  @override
  String get screenShareViewerLeave => 'Verlassen';

  @override
  String screenShareViewerWaitingStream(String name) {
    return 'Warte auf Übertragung von $name...';
  }

  @override
  String get screenShareViewerConnecting => 'Verbinde mit Stream...';

  @override
  String get viewOnceVideoTitle => 'Video · Einmalige Ansicht';

  @override
  String get viewOncePhotoTitle => 'Foto · Einmalige Ansicht';

  @override
  String get viewOnceCantOpen => 'Medium konnte nicht geöffnet werden.';

  @override
  String get viewOnceUnavailable => 'Nicht mehr verfügbar.';

  @override
  String get viewOnceBlockedFooter => 'Screenshots blockiert.';

  @override
  String get anonRestoreBanner => 'Anonymes Banner';

  @override
  String get contactsInviteFriends => 'Freunde zu GupShupGo einladen';

  @override
  String get inviteImageShareFailed =>
      'Das Bild konnte nicht geteilt werden. Versuche es erneut oder teile den Link.';

  @override
  String get viewOnceUnblockedFooter => 'Nur einmaliges Öffnen möglich.';

  @override
  String get tabMessages => 'Nachrichten';
}
