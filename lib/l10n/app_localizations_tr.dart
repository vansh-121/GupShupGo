// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonOk => 'Tamam';

  @override
  String get commonContinue => 'Devam';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonRetry => 'Yeniden dene';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonGotIt => 'Anladım';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsLanguageTitle => 'Dil';

  @override
  String get settingsLanguageSubtitle => 'Tercih ettiğiniz dili seçin';

  @override
  String get languagePickerTitle => 'Dil';

  @override
  String get languageSystemDefault => 'Sistem varsayılanı';

  @override
  String get languageSystemDefaultSubtitle => 'Cihazınızın dilini kullanın';

  @override
  String get loginContinueWithPhone => 'Telefon ile Devam Et';

  @override
  String get loginContinueWithGoogle => 'Google ile Devam Et';

  @override
  String get loginUseEmailPassword => 'E-posta ve Şifre Kullan';

  @override
  String get loginSignIn => 'Giriş Yap';

  @override
  String get loginSignUp => 'Kayıt Ol';

  @override
  String get loginCreateAccount => 'Hesap Oluştur';

  @override
  String get loginForgotPassword => 'Şifrenizi mi unuttunuz?';

  @override
  String get loginOfflineChat => 'Çevrimdışı Sohbet';

  @override
  String get loginHintName => 'Adınız';

  @override
  String get loginHintEmail => 'E-posta';

  @override
  String get loginHintPassword => 'Şifre';

  @override
  String get loginPasswordHelper =>
      'En az 8 karakter, bir harf ve bir rakam içermelidir';

  @override
  String loginResetEmailSent(String email) {
    return 'Şifre sıfırlama e-postası $email adresine gönderildi';
  }

  @override
  String get loginErrorEnterEmail => 'Lütfen e-posta adresinizi girin';

  @override
  String get loginErrorValidEmail => 'Lütfen geçerli bir e-posta adresi girin';

  @override
  String get loginErrorEnterPassword => 'Lütfen şifrenizi girin';

  @override
  String get loginErrorPasswordMin6 => 'Şifre en az 6 karakter olmalıdır';

  @override
  String get loginErrorEnterPasswordSignup => 'Lütfen bir şifre girin';

  @override
  String get loginErrorPasswordMin8 => 'Şifre en az 8 karakter olmalıdır';

  @override
  String get loginErrorPasswordLetter => 'Şifre en az bir harf içermelidir';

  @override
  String get loginErrorPasswordNumber => 'Şifre en az bir rakam içermelidir';

  @override
  String get loginErrorEnterName => 'Lütfen adınızı girin';

  @override
  String get loginErrorGoogleCancelled => 'Google ile giriş iptal edildi.';

  @override
  String get loginErrorProfileLoad =>
      'Profiliniz yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get loginErrorGoogleFailed =>
      'Google ile giriş başarısız oldu. Lütfen tekrar deneyin.';

  @override
  String get loginErrorSignInFailed =>
      'Giriş yapılamadı. Lütfen tekrar deneyin.';

  @override
  String get loginErrorSignUpFailed =>
      'Kayıt olunamadı. Lütfen tekrar deneyin.';

  @override
  String get loginErrorGeneric => 'Bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get loginErrorResetFailed =>
      'Sıfırlama e-postası gönderilemedi. Lütfen tekrar deneyin.';

  @override
  String get loginErrorUserNotFound =>
      'Bu e-posta ile kayıtlı hesap bulunamadı. Lütfen kayıt olun.';

  @override
  String get loginErrorWrongPassword => 'Hatalı şifre. Lütfen tekrar deneyin.';

  @override
  String get loginErrorEmailInUse =>
      'Bu e-posta adresi zaten kullanılıyor. Lütfen giriş yapın.';

  @override
  String get loginErrorInvalidEmail =>
      'Lütfen geçerli bir e-posta adresi girin.';

  @override
  String get loginErrorWeakPassword =>
      'Şifre çok zayıf. En az 6 karakter kullanın.';

  @override
  String get loginErrorInvalidCredential =>
      'Geçersiz e-posta veya şifre. Lütfen kontrol edip tekrar deneyin.';

  @override
  String get loginErrorTooManyRequests =>
      'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';

  @override
  String get homeNavChats => 'Sohbetler';

  @override
  String get homeNavMoments => 'Anlar';

  @override
  String get homeNavCalls => 'Aramalar';

  @override
  String get homeNavProfile => 'Profil';

  @override
  String get homeTooltipOfflineChat =>
      'Çevrimdışı Sohbet — yakındaki kişilerle konuşun';

  @override
  String get homeTooltipSearch => 'Ara';

  @override
  String get homeMenuProfile => 'Profil';

  @override
  String get homeMenuSettings => 'Ayarlar';

  @override
  String get homeMenuRateUs => 'Bizi Değerlendirin';

  @override
  String get homeMenuReportIssue => 'Sorun Bildir';

  @override
  String get homeMenuWhatsNew => 'Yenilikler';

  @override
  String get homeMenuLogOut => 'Çıkış Yap';

  @override
  String get homeEmptyChatsTitle => 'Henüz sohbet yok';

  @override
  String get homeEmptyChatsSubtitle =>
      'Aşağıdaki butona dokunarak sohbet başlatın';

  @override
  String get homeNewChatButton => 'Yeni sohbet';

  @override
  String get homeAiAssistantTitle => 'GupAI';

  @override
  String get homeAiAssistantSubtitle =>
      'Taslak oluşturun, çevirin, özetleyin ve daha fazlası';

  @override
  String get homeStrangerMatchTitle => 'Bir Yabancıyla Bağlan';

  @override
  String get homeStrangerMatchSubtitle =>
      'Anonim sohbet — eşleşmek için dokunun!';

  @override
  String get homeMyMoment => 'Benim Anım';

  @override
  String get homeRecentMoments => 'Son Anlar';

  @override
  String get homeEmptyMomentsTitle => 'Henüz güncelleme yok.';

  @override
  String get homeEmptyMomentsSubtitle => 'Paylaşmak için kameraya dokunun.';

  @override
  String get homeTapToAddMoment => 'Güncelleme eklemek için dokunun';

  @override
  String get homeEmptyCallsTitle => 'Arama geçmişi yok';

  @override
  String get homeEmptyCallsSubtitle => 'Son aramalarınız burada görünecek';

  @override
  String get chatInputHint => 'Mesaj...';

  @override
  String get chatSearchHint => 'Mesajlarda ara...';

  @override
  String get chatStatusTyping => 'yazıyor...';

  @override
  String get chatStatusOnline => 'Çevrimiçi';

  @override
  String get chatStatusOffline => 'Çevrimdışı';

  @override
  String chatStatusLastSeen(String time) {
    return 'Son görülme $time';
  }

  @override
  String get chatEndToEndEncrypted => 'Uçtan uca şifreli';

  @override
  String get chatNoInternetOfflineTitle =>
      'İnternet yok mu? Yakındaki cihazlarla çevrimdışı sohbet edin';

  @override
  String get chatEnableOfflineButton => 'Etkinleştir';

  @override
  String get chatSlideToCancel => 'İptal etmek için kaydırın';

  @override
  String get chatTooltipVoiceCall => 'Sesli Arama';

  @override
  String get chatTooltipVideoCall => 'Görüntülü Arama';

  @override
  String get chatMenuContactInfo => 'Kişi bilgisi';

  @override
  String get chatMenuSearch => 'Ara';

  @override
  String get chatMenuChatTheme => 'Sohbet teması';

  @override
  String get chatMenuExportChat => 'Sohbeti dışa aktar';

  @override
  String get chatMenuMuteNotifications => 'Bildirimleri sessize al';

  @override
  String get chatMenuUnmuteNotifications => 'Sessizden çıkar';

  @override
  String get chatMenuBlockContact => 'Kişiyi engelle';

  @override
  String get chatActionReply => 'Yanıtla';

  @override
  String get chatActionCopy => 'Kopyala';

  @override
  String get chatActionForward => 'İlet';

  @override
  String get chatActionTranslate => 'Çevir';

  @override
  String get chatActionSummarise => 'Özetle';

  @override
  String get chatActionAskGupAi => 'GupAI\'ye sor';

  @override
  String get chatActionEdit => 'Düzenle';

  @override
  String get chatActionDelete => 'Sil';

  @override
  String get chatDeleteMessageTitle => 'Mesaj silinsin mi?';

  @override
  String get chatDeleteMessageForEveryonePrompt =>
      'Yalnızca sizin için mi yoksa bu sohbetteki herkes için mi silinsin?';

  @override
  String chatDeleteMessageForMeOnlyPrompt(String name) {
    return 'Bu işlem mesajı yalnızca sizin cihazlarınızdan kaldırır. $name görmeye devam eder.';
  }

  @override
  String get chatDeleteForMe => 'Benden sil';

  @override
  String get chatDeleteForEveryone => 'Herkesten sil';

  @override
  String chatBlockContactTitle(String name) {
    return '$name engellensin mi?';
  }

  @override
  String get chatBlockContactPrompt =>
      'Engellenen kişiler size mesaj gönderemez veya arayamaz. Ayarlar → Gizlilik bölümünden engel kaldırılabilir.';

  @override
  String get chatBlockButton => 'Engelle';

  @override
  String get chatForwardTo => 'Şuraya ilet';

  @override
  String get chatNoForwardChats => 'İletilecek başka sohbet yok';

  @override
  String get chatCannotSendMediaBlocked => 'Bu kişiye medya gönderilemez';

  @override
  String get attachmentShareTitle => 'Paylaş';

  @override
  String get attachmentPhoto => 'Fotoğraf';

  @override
  String get attachmentPhotoSubtitle => 'Galerinizden bir resim seçin';

  @override
  String get attachmentVideo => 'Video';

  @override
  String get attachmentVideoSubtitle => 'Galerinizden bir video seçin';

  @override
  String get attachmentDocument => 'Belge';

  @override
  String get attachmentDocumentSubtitle => 'PDF, Office dosyası, arşiv';

  @override
  String get attachmentLocation => 'Konum';

  @override
  String get attachmentLocationSubtitle => 'Mevcut konumunuzu paylaşın';

  @override
  String get attachmentViewOnce => 'Tek seferlik görüntüleme';

  @override
  String get attachmentViewOnceSubtitle =>
      'Fotoğraf veya video açıldıktan sonra kaybolur';

  @override
  String get contactsTitle => 'Kişiler ve Keşfet';

  @override
  String get contactsTabFriends => 'Arkadaşlar';

  @override
  String get contactsTabRequests => 'İstekler';

  @override
  String get contactsTabDiscover => 'Keşfet';

  @override
  String get contactsScanQrTooltip => 'QR Kodu Tara';

  @override
  String get contactsMyHandleTooltip => 'Kullanıcı Adım';

  @override
  String get contactsSetUsernamePrompt =>
      'Önce profilinizde bir @kullanıcıadı belirleyin — QR kodunuz bunu paylaşır.';

  @override
  String get contactsMyQrCodeTitle => 'Profil QR Kodum';

  @override
  String get contactsMyQrCodeSubtitle =>
      'Arkadaşlarınız anında bağlanmak için bu QR kodunu tarayabilir';

  @override
  String get contactsCopyProfileLink => 'Profil Bağlantısını Kopyala';

  @override
  String contactsProfileLinkCopied(String username) {
    return '@$username için profil bağlantısı kopyalandı!';
  }

  @override
  String get contactsScanSomeonesCode => 'Birinin Kodunu Tara';

  @override
  String get contactsPermissionDenied => 'Kişilere erişim izni reddedildi.';

  @override
  String get contactsNoUsersFound =>
      'Rehberinizde henüz GupShupGo kullanıcısı bulunamadı.';

  @override
  String contactsFailedToSync(String error) {
    return 'Kişiler eşitlenemedi: $error';
  }

  @override
  String contactsMatchedCount(int count) {
    return 'GupShupGo\'daki $count kişi';
  }

  @override
  String get contactsFromDeviceContacts => 'Cihaz rehberinizden';

  @override
  String get contactsLoadFriendsError => 'Arkadaşlarınız yüklenemedi.';

  @override
  String get contactsNoFriendsTitle => 'Henüz Arkadaş Eklenmedi';

  @override
  String get contactsNoFriendsPrompt =>
      '@kullanıcıadı, telefon veya e-posta ile aramak için Keşfet sekmesini kullanın!';

  @override
  String get contactsDiscoverPeopleButton => 'Kişileri Keşfet';

  @override
  String get contactsQuickConnectHeader => 'HIZLI BAĞLANTI';

  @override
  String get contactsNoSuggestions => 'Şu anda öneri bulunmuyor.';

  @override
  String get contactsLoadRequestsError => 'İstekleriniz yüklenemedi.';

  @override
  String contactsPendingRequestsHeader(int count) {
    return 'BEKLEYEN İSTEKLER ($count)';
  }

  @override
  String get contactsNoPendingRequestsTitle => 'Bekleyen İstek Yok';

  @override
  String get contactsNoPendingRequestsSubtitle =>
      'Biri size bağlantı isteği gönderdiğinde burada görünecektir.';

  @override
  String get contactsWantsToConnect => 'Bağlantı kurmak istiyor';

  @override
  String get contactsAcceptButton => 'KABUL ET';

  @override
  String get contactsAcceptFailed =>
      'İstek kabul edilemedi. Lütfen tekrar deneyin.';

  @override
  String contactsConnectedWith(String name) {
    return '$name ile bağlandınız!';
  }

  @override
  String get contactsDeclineFailed =>
      'İstek reddedilemedi. Lütfen tekrar deneyin.';

  @override
  String get contactsYouMightKnowHeader => 'TANIYOR OLABİLECEKLERİNİZ';

  @override
  String get contactsSeeAll => 'TÜMÜNÜ GÖR';

  @override
  String get contactsSearchHint =>
      'İsim, @kullanıcıadı, telefon veya e-posta ara...';

  @override
  String get contactsTurnOnDiscoverability =>
      'Aramalarda ve önerilerde görünmek için Keşfedilebilirliği açın.';

  @override
  String get contactsNoMatchingUsersTitle => 'Eşleşen Kullanıcı Bulunamadı';

  @override
  String get contactsNoMatchingUsersSubtitle =>
      '@kullanıcıadı, telefon numarası veya e-postayı kontrol edip tekrar deneyin.';

  @override
  String get contactsDiscoverHeroTitle => 'GupShupGo\'da İnsanları Keşfet';

  @override
  String get contactsDiscoverHeroSubtitle =>
      'Dünya çapında güvenilir bağlantılarla çevrenizi genişletin.';

  @override
  String get contactsSyncDeviceContacts => 'Rehberi Eşitle';

  @override
  String get contactsSyncingContacts => 'Kişiler eşitleniyor...';

  @override
  String get contactsSyncDeviceSubtitle =>
      'Arkadaşlarınızı telefon rehberinizden anında bulun';

  @override
  String get contactsSuggestedUsersHeader => 'ÖNERİLEN KULLANICILAR';

  @override
  String get contactsAddFriendButton => 'ARKADAŞ EKLE';

  @override
  String get contactsRequestedButton => 'İstek Gönderildi';

  @override
  String contactsRequestSent(String name) {
    return '$name kişisine arkadaşlık isteği gönderildi!';
  }

  @override
  String get contactsRequestFailed =>
      'İstek zaten beklemede veya başarısız oldu.';

  @override
  String get contactsRequestUnavailable => 'Bu istek artık geçerli değil.';

  @override
  String get profileEditTitle => 'Profili Düzenle';

  @override
  String get profileSaveButton => 'Kaydet';

  @override
  String get profileTapToChangePhoto => 'Fotoğrafı değiştirmek için dokunun';

  @override
  String get profileUpgradeToPro => 'Pro\'ya Yükselt';

  @override
  String get profileSectionName => 'ADINIZ';

  @override
  String get profileNameHint => 'Adınızı girin';

  @override
  String get profileSectionHandle => 'BENZERSİZ KULLANICI ADI';

  @override
  String get profileHandleNotSet => 'Henüz ayarlanmadı';

  @override
  String get profileChangeHandle => 'Değiştir';

  @override
  String get profileSectionAbout => 'HAKKINDA';

  @override
  String get profileAboutHint => 'Neler düşünüyorsunuz?';

  @override
  String get profileDefaultAbout => 'Merhaba! GupShupGo kullanıyorum.';

  @override
  String get profileSectionPhone => 'TELEFON';

  @override
  String get profileSectionEmail => 'E-POSTA';

  @override
  String get profileSectionLinkedMethods => 'BAĞLI GİRİŞ YÖNTEMLERİ';

  @override
  String get profileNotLinked => 'Bağlı değil';

  @override
  String get profileNameEmpty => 'İsim boş bırakılamaz.';

  @override
  String get profileUpdatedSuccess => 'Profil güncellendi';

  @override
  String profileUploadPhotoFailed(String error) {
    return 'Fotoğraf yüklenemedi: $error';
  }

  @override
  String profileSaveFailed(String error) {
    return 'Profil kaydedilemedi: $error';
  }

  @override
  String get profilePoints => 'Puan';

  @override
  String get profileBadges => 'Rozetler';

  @override
  String get profileBestBond => 'En İyi Seri';

  @override
  String get settingsAccountCard => 'Hesap';

  @override
  String get settingsProfileTile => 'Profil';

  @override
  String get settingsLinkedMethodsTile => 'Bağlı giriş yöntemleri';

  @override
  String get settingsPhoneTile => 'Telefon numarası';

  @override
  String get settingsEmailTile => 'E-posta';

  @override
  String get settingsPrivacyCard => 'Gizlilik';

  @override
  String get settingsDiscoverability => 'Keşfedilebilirlik';

  @override
  String get settingsLastSeen => 'Son görülme';

  @override
  String get settingsReadReceipts => 'Okundu bilgisi';

  @override
  String get settingsAdPreferences => 'Reklam tercihleri';

  @override
  String get settingsManage => 'Yönet';

  @override
  String get settingsAppearanceCard => 'Görünüm';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsChatTheme => 'Sohbet teması';

  @override
  String get settingsHelpSecurityCard => 'Yardım ve Güvenlik';

  @override
  String get settingsHelpCenter => 'Yardım Merkezi';

  @override
  String get settingsReportProblem => 'Sorun bildir';

  @override
  String get settingsE2EEShield => 'Uçtan uca şifreleme (Kasa)';

  @override
  String get settingsVerifySafetyNumber => 'Güvenlik numarasını doğrula';

  @override
  String get settingsBlockedContacts => 'Engellenen kişiler';

  @override
  String get settingsClearAllGupHistory => 'Tüm sohbet geçmişini temizle';

  @override
  String get settingsRateUs => 'Bizi değerlendirin';

  @override
  String get settingsWhatsNew => 'Yenilikler';

  @override
  String get settingsCheckForUpdates => 'Güncellemeleri denetle';

  @override
  String get settingsAppInfo => 'Uygulama bilgisi';

  @override
  String get settingsLogOut => 'Çıkış Yap';

  @override
  String get settingsLogOutConfirmTitle => 'Çıkış yap';

  @override
  String get settingsLogOutConfirmPrompt =>
      'GupShupGo\'dan çıkış yapmak istediğinizden emin misiniz?';

  @override
  String get settingsSigningOut => 'Çıkış yapılıyor…';

  @override
  String get settingsClearChatsConfirmTitle => 'Tüm sohbetleri temizle';

  @override
  String get settingsClearChatsConfirmPrompt =>
      'Bu işlem mesaj geçmişinizi kalıcı olarak siler. Bu işlem geri alınamaz.';

  @override
  String get settingsDeleteAll => 'Tümünü Sil';

  @override
  String get settingsClearingChats => 'Sohbetler temizleniyor...';

  @override
  String get settingsAllChatsCleared => 'Tüm sohbetler temizlendi';

  @override
  String settingsClearChatsFailed(String error) {
    return 'Sohbetler temizlenemedi: $error';
  }

  @override
  String get settingsChooseThemeTitle => 'Tema seç';

  @override
  String get settingsUnlockPremiumFeatures =>
      'Premium özelliklerin kilidini açın';

  @override
  String settingsProDaysLeft(String planLabel, int daysRemaining) {
    return '$planLabel · $daysRemaining gün kaldı';
  }

  @override
  String get settingsCheckingForUpdates => 'Güncellemeler kontrol ediliyor…';

  @override
  String settingsUpToDate(String version) {
    return 'En son sürümü kullanıyorsunuz (v$version).';
  }

  @override
  String get settingsUpdateCheckUnavailable =>
      'Güncellemeler denetlenemedi. Google Play Store\'dan yüklendiğinden emin olun.';

  @override
  String get settingsNoBlockedContacts => 'Engellenen kişi yok';

  @override
  String get settingsUnblock => 'Engeli Kaldır';

  @override
  String settingsUserUnblocked(String name) {
    return '$name engeli kaldırıldı';
  }

  @override
  String get settingsVerifyContactTitle => 'Bir kişiyi doğrula';

  @override
  String get settingsVerifyContactSubtitle =>
      'Paylaşılan güvenlik numaranızı görüntülemek için bir kişi seçin.';

  @override
  String get settingsComputingSafetyNumber => 'Güvenlik numarası hesaplanıyor…';

  @override
  String settingsSafetyNumberExplanation(String name) {
    return 'Numara $name cihazındakiyle eşleşirse şifrelemeniz doğrulanmış olur.';
  }

  @override
  String get settingsSafetyNumberNoBundle =>
      'Bu kişi henüz bir şifreleme anahtarı yayınlamadı.';

  @override
  String get settingsSafetyNumberCompareHint =>
      'Bu numarayı yüz yüze veya güvenli bir aramayla karşılaştırın.';

  @override
  String get callEndToEndEncrypted => 'Uçtan uca şifreli';

  @override
  String get callSecuring => 'Arama güvenceye alınıyor…';

  @override
  String get callNotEncrypted => 'Şifreli değil';

  @override
  String get callIncomingVoice => 'Gelen Sesli Arama';

  @override
  String get callIncomingVideo => 'Gelen Görüntülü Arama';

  @override
  String get callVoiceCall => 'Sesli Arama';

  @override
  String get callVideoCall => 'Görüntülü Arama';

  @override
  String get callDecline => 'Reddet';

  @override
  String get callAccept => 'Kabul Et';

  @override
  String get callConnecting => 'Bağlanıyor...';

  @override
  String get callSettingUp => 'Arama ayarlanıyor...';

  @override
  String callNotifying(String name) {
    return '$name kişisine bildiriliyor...';
  }

  @override
  String get callRinging => 'Çalıyor...';

  @override
  String get callConnected => 'Bağlandı';

  @override
  String get callOnHold => 'Beklemede';

  @override
  String get callCalling => 'Aranıyor...';

  @override
  String get callWaitingForUser => 'Karşı taraf bekleniyor...';

  @override
  String get callEnded => 'Arama Sonlandı';

  @override
  String get callDeclined => 'Arama Reddedildi';

  @override
  String get callNoAnswer => 'Cevap Yok';

  @override
  String get callFailedToConnect => 'Bağlantı kurulamadı';

  @override
  String callFailedToStart(String error) {
    return 'Arama başlatılamadı: $error';
  }

  @override
  String get callTokenExpired =>
      'Jetonun süresi doldu veya geçersiz. Aramayı yeniden başlatın.';

  @override
  String callFailedToInit(String type, String error) {
    return '$type araması başlatılamadı: $error';
  }

  @override
  String get callTurnOffSpeaker => 'Hoparlörü kapat';

  @override
  String get callTurnOnSpeaker => 'Hoparlörü aç';

  @override
  String get callMuteMic => 'Mikrofonu sessize al';

  @override
  String get callUnmuteMic => 'Mikrofonun sesini aç';

  @override
  String get callEndCall => 'Aramayı sonlandır';

  @override
  String get callSwitchCamera => 'Kamerayı değiştir';

  @override
  String get callTurnOffCamera => 'Kamerayı kapat';

  @override
  String get callTurnOnCamera => 'Kamerayı aç';

  @override
  String statusViewedByCount(int count) {
    return '$count kişi gördü';
  }

  @override
  String get statusNoViewsYet => 'Henüz görüntüleme yok';

  @override
  String statusViewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count görüntüleme',
      one: '1 görüntüleme',
    );
    return '$_temp0';
  }

  @override
  String get statusDeleteTitle => 'Durumu Sil';

  @override
  String get statusDeleteConfirm =>
      'Bu durumu silmek istediğinizden emin misiniz?';

  @override
  String get statusDeleteButton => 'Sil';

  @override
  String get statusReplySent => 'Yanıt gönderildi';

  @override
  String statusReplyFailed(String error) {
    return 'Yanıt gönderilemedi: $error';
  }

  @override
  String get statusNoActive => 'Aktif durum yok';

  @override
  String get statusCouldNotLoad => 'Bu güncelleme yüklenemedi';

  @override
  String get statusTapToRetry => 'Yeniden denemek için dokunun';

  @override
  String get statusFailedToLoadImage => 'Görsel yüklenemedi';

  @override
  String get statusLoadingVideo => 'Video yükleniyor...';

  @override
  String get statusEnterTextPrompt => 'Lütfen bir metin girin';

  @override
  String get statusNoContactsNotice =>
      'Henüz kişi yok — durum paylaşmadan önce bir sohbet başlatın.';

  @override
  String statusPostFailed(String error) {
    return 'Durum paylaşılamadı: $error';
  }

  @override
  String get statusTypeHint => 'Bir durum yaz...';

  @override
  String get statusCamera => 'Kamera';

  @override
  String get statusTakePhoto => 'Fotoğraf çek';

  @override
  String get statusGalleryPhoto => 'Galeri Fotoğrafı';

  @override
  String get statusChooseImageGallery => 'Galeriden fotoğraf seç';

  @override
  String get statusRecordVideo => 'Video Kaydet';

  @override
  String get statusRecordShortVideo => 'Kısa video kaydet';

  @override
  String get statusGalleryVideo => 'Galeri Videosu';

  @override
  String get statusChooseVideoGallery => 'Galeriden video seç';

  @override
  String statusFailedPickImage(String error) {
    return 'Fotoğraf seçilemedi: $error';
  }

  @override
  String statusFailedPickVideo(String error) {
    return 'Video seçilemedi: $error';
  }

  @override
  String get statusChangeBgColorTooltip => 'Arka plan rengini değiştir';

  @override
  String aiMessagesRemaining(int count) {
    return '$count kaldı';
  }

  @override
  String get aiQuotaDialogTitle => 'GupAI Mesajları';

  @override
  String aiQuotaRemainingOfTotal(int remaining, int total) {
    return 'Bugün $total içinden $remaining kaldı';
  }

  @override
  String aiQuotaUsedResetNote(int used) {
    return 'Bugün $used kullanıldı · yarın sıfırlanır. Reklam izleyin veya Pro\'ya geçin.';
  }

  @override
  String get aiQuotaGotIt => 'Anladım';

  @override
  String get aiTitle => 'GupAI';

  @override
  String get aiSubtitle => 'Uygulama içi asistanınız';

  @override
  String get aiEmptyHelpTitle => 'Nasıl yardımcı olabilirim?';

  @override
  String get aiEmptyHelpSubtitle =>
      'Yanıt taslağı oluşturun, çeviri yapın, özetleyin veya soru sorun.';

  @override
  String get meshOfflineChatConnected => 'Çevrimdışı sohbet · bağlandı';

  @override
  String get meshConnecting => 'Bağlanıyor…';

  @override
  String get meshBannerNotice => 'Çevrimdışı sohbet — internet yok, sunucu yok';

  @override
  String meshSayHiTo(String name) {
    return '$name kişisine merhaba de';
  }

  @override
  String meshOfflineDescription(String name) {
    return 'Çevrimdışı sohbettesiniz. Mesajlar sadece siz ve $name arasında kalır.';
  }

  @override
  String get meshMediaUnavailable => 'Bu medya artık kullanılamıyor.';

  @override
  String get meshViewOnceTitle => 'Bir kez görüntüle';

  @override
  String meshViewOncePrompt(String type) {
    return 'Bu $type içeriğini yalnızca bir kez açabilirsiniz.';
  }

  @override
  String get arcadeTabOverview => 'Genel Bakış';

  @override
  String get arcadeTabChallenges => 'Görevler';

  @override
  String get arcadeTabLeaderboard => 'Lider Tablosu';

  @override
  String get arcadeFailedLoadStats => 'İstatistikler yüklenemedi.';

  @override
  String get aiAskHint => 'GupAI\'ye her şeyi sorabilirsiniz…';
}
