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
  String get homeNavChats => 'Chats';

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
}
