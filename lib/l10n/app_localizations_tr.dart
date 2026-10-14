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
  String get homeNavChats => 'Mesajlar';

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
  String get attachmentScreenShare => 'Ekran paylaş';

  @override
  String get attachmentScreenShareSubtitle =>
      'Sohbet sırasında ekranınızı canlı gösterin';

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

  @override
  String get settingsNotificationsTile => 'Bildirimler';

  @override
  String get settingsNotificationsStatusOn => 'Açık';

  @override
  String get settingsNotificationsStatusOff => 'Kapalı';

  @override
  String get settingsNotificationsEnabledToast => 'Bildirimler açık.';

  @override
  String get settingsEnableNotificationsTitle => 'Bildirimleri etkinleştir';

  @override
  String get settingsEnableNotificationsBody =>
      'Bildirimler kapalı. GupShupGo\'nun yeni mesajlar ve aramalar hakkında sizi bilgilendirmesi için sistem ayarlarını açın.';

  @override
  String get settingsOpenSystemSettings => 'Ayarları aç';

  @override
  String get loginTagline => 'İnternet olmadan bile çalışan gizli mesajlaşma.';

  @override
  String get settingsPrivacyPolicy => 'Gizlilik Politikası';

  @override
  String get settingsTerms => 'Hizmet Şartları';

  @override
  String get settingsDeleteAccount => 'Hesabı sil';

  @override
  String get inviteSheetTitle => 'Arkadaşlarını davet et';

  @override
  String get inviteSheetSubtitle => 'Herkese duyur — GupShupGo\'yu paylaş';

  @override
  String get inviteShareImageBtn => 'Resmi paylaş';

  @override
  String get inviteShareLinkBtn => 'Bağlantıyı paylaş';

  @override
  String get inviteCopyLinkBtn => 'Bağlantıyı kopyala';

  @override
  String get inviteLinkCopied => 'Davet bağlantısı kopyalandı';

  @override
  String inviteMessage(String link) {
    return 'GupShupGo\'da benimle sohbet et — internet olmadan bile çalışır 👋 $link';
  }

  @override
  String get inviteCardTagline => 'Çevrimdışı bile çalışan özel sohbet';

  @override
  String get inviteCardScan => 'İndirmek için tara';

  @override
  String get inviteCardDownload => 'Google Play\'den indirin';

  @override
  String get homeMenuInvite => 'Arkadaşlarını davet et';

  @override
  String get invitePromptTitle => 'GupShupGo hoşunuza gidiyor mu?';

  @override
  String get invitePromptBody =>
      'Arkadaşlarla daha güzel — ve internet olmadan da çalışıyor. Birini davet etmek ister misiniz?';

  @override
  String get invitePromptInvite => 'Arkadaşlarını davet et';

  @override
  String get invitePromptLater => 'Belki sonra';

  @override
  String get homeOfflineBannerTitle => 'İnternet yok mu? Sorun değil';

  @override
  String get homeOfflineBannerSubtitle =>
      'Yakındaki kişilere Bluetooth üzerinden mesaj göndermeye devam edebilirsiniz.';

  @override
  String homeNearbyBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Yakında $count kişi',
      one: 'Yakında 1 kişi',
    );
    return '$_temp0';
  }

  @override
  String get homeNearbyBannerSubtitle =>
      'Bluetooth üzerinden sohbet edin — internet gerekmez.';

  @override
  String get linkBackupTitle => 'Yedek giriş yöntemi ekle';

  @override
  String get linkBackupSubtitle =>
      'SIM kartınız olmasa bile tekrar giriş yapabilmek için Google veya e-posta bağlayın.';

  @override
  String get linkGoogleTitle => 'Google Hesabı Bağla';

  @override
  String get linkGoogleSubtitleLinked => 'Bağlandı ✓';

  @override
  String get linkGoogleSubtitleUnlinked => 'SIM olmadan tek dokunuşla giriş';

  @override
  String get linkGoogleAction => 'Bağla';

  @override
  String get linkGoogleSuccess => 'Google hesabı başarıyla bağlandı!';

  @override
  String get linkGoogleAlreadyUsed =>
      'Bu Google hesabı başka bir GupShupGo hesabına kayıtlı.';

  @override
  String get linkGoogleFailed =>
      'Google bağlantısı başarısız oldu. Tekrar deneyin.';

  @override
  String get linkSessionExpired =>
      'Oturum süresi doldu. Lütfen tekrar giriş yapın.';

  @override
  String get linkEmailTitle => 'E-posta ve Şifre Bağla';

  @override
  String get linkEmailSubtitleLinked => 'Bağlandı ✓';

  @override
  String get linkEmailSubtitleUnlinked =>
      'SIM veya Google yoksa e-posta ile giriş yapın';

  @override
  String get linkEmailActionAdd => 'Ekle';

  @override
  String get linkEmailActionCancel => 'İptal';

  @override
  String get linkEmailFieldLabel => 'E-posta';

  @override
  String get linkPasswordFieldLabel => 'Şifre oluştur';

  @override
  String get linkPasswordHelper => 'En az 6 karakter';

  @override
  String get linkEmailButton => 'E-postayı Bağla';

  @override
  String get linkEmailSuccess => 'E-posta başarıyla bağlandı!';

  @override
  String get linkEmailInvalid => 'Geçerli bir e-posta adresi girin.';

  @override
  String get linkPasswordTooShort => 'Şifre en az 6 karakter olmalıdır.';

  @override
  String get linkEmailAlreadyInUse => 'Bu e-posta zaten kullanımda.';

  @override
  String get linkEmailAlreadyLinked => 'Hesabınıza zaten bir e-posta bağlı.';

  @override
  String get linkEmailFailed => 'E-posta bağlantısı başarısız oldu.';

  @override
  String get linkContinueToApp => 'Uygulamaya Devam Et';

  @override
  String get linkSkipForNow => 'Şimdilik Atla';

  @override
  String get linkSkip => 'Atla';

  @override
  String get phoneAuthTitleEntry => 'Telefon numaranızla giriş yapın.';

  @override
  String get phoneAuthTitleOtp => 'Gönderdiğimiz kodu girin.';

  @override
  String get phoneAuthNameHint => 'Adınız';

  @override
  String get phoneAuthPhoneHint => 'Telefon Numarası';

  @override
  String get phoneAuthUseSim => 'SIM Kullan';

  @override
  String get phoneAuthSendOtp => 'Kodu Gönder';

  @override
  String phoneAuthOtpPrompt(String phone) {
    return '$phone numarasına gönderilen 6 haneli kodu girin';
  }

  @override
  String get phoneAuthOtpPromptGeneric => 'Gönderdiğimiz 6 haneli kodu girin';

  @override
  String get phoneAuthOtpHint => 'Kodu girin';

  @override
  String get phoneAuthVerify => 'Doğrula';

  @override
  String get phoneAuthGoBack => 'Geri Dön';

  @override
  String get phoneAuthResendCode => 'Kodu tekrar gönder';

  @override
  String get phoneAuthEnterName => 'Lütfen adınızı girin';

  @override
  String get phoneAuthEnterValidPhone =>
      'Lütfen geçerli bir telefon numarası girin';

  @override
  String get phoneAuthEnterCode => 'Lütfen kodu girin';

  @override
  String get phoneAuthRequestNewCode => 'Lütfen yeni bir kod isteyin.';

  @override
  String get phoneAuthCodeIncorrect => 'Kod hatalı. Tekrar deneyin.';

  @override
  String get phoneAuthErrCodeIncorrect =>
      'Bu kod hatalı. Lütfen kontrol edip tekrar deneyin.';

  @override
  String get phoneAuthErrCodeExpired => 'Kodun süresi doldu.';

  @override
  String get phoneAuthErrTooManyRequests =>
      'Çok fazla deneme yapıldı. Lütfen bekleyin.';

  @override
  String get phoneAuthErrInvalidPhone => 'Telefon numarası geçersiz görünüyor.';

  @override
  String get phoneAuthErrQuotaExceeded => 'SMS limitine ulaşıldı.';

  @override
  String get phoneAuthErrFailed => 'Doğrulama başarısız oldu.';

  @override
  String get usernameSetupAppBarTitle => 'Kullanıcı Adınızı Seçin';

  @override
  String get usernameSetupHeaderTitle => 'Kimliğinizi Güvenceye Alın';

  @override
  String get usernameSetupHeaderDesc =>
      'Kullanıcı adınız (@handle) GupShupGo\'daki benzersiz anahtarınızdır. Başkaları numaranızı bilmeden sizi ekleyebilir.';

  @override
  String get usernameSetupInputHint => 'kullanici_adiniz';

  @override
  String get usernameSetupChecking => 'Uygunluk kontrol ediliyor...';

  @override
  String usernameSetupAvailable(String handle) {
    return '@$handle kullanılabilir!';
  }

  @override
  String usernameSetupTaken(String handle) {
    return '@$handle zaten alınmış.';
  }

  @override
  String get usernameSetupCharRules => '3–20 karakter (a-z, 0-9, _)';

  @override
  String get usernameSetupTooShort => 'En az 3 karakter olmalıdır.';

  @override
  String get usernameSetupTooLong => 'En fazla 20 karakter olabilir.';

  @override
  String get usernameSetupInvalidChars =>
      'Yalnızca harf, rakam ve alt çizgi kullanılabilir.';

  @override
  String get usernameSetupRecommended => 'SİZİN İÇİN ÖNERİLENLER';

  @override
  String get usernameSetupSaveBtn => 'Kaydet ve Devam Et';

  @override
  String get usernameSetupSkipBtn => 'Şimdilik atla';

  @override
  String usernameSetupFailed(String error) {
    return 'Kullanıcı adı kaydedilemedi: $error';
  }

  @override
  String get vaultProtectTitle => 'Kasayı Koru';

  @override
  String get vaultUnlockTitle => 'Kasa Kilidini Aç';

  @override
  String get vaultSetupDesc =>
      'Mesaj geçmişinizi şifrelemek için bir PIN seçin. Yeni bir telefonda buna ihtiyacınız olacak.';

  @override
  String get vaultUnlockDescBio =>
      'Geçmişi açmak için PIN girin veya parmak izinizi kullanın.';

  @override
  String get vaultUnlockDescPin => 'Geçmişinizi açmak için PIN kodunuzu girin.';

  @override
  String get vaultReinstallHint =>
      'Geçmişi geri yüklemek için PIN kodunuzu girin.';

  @override
  String get vaultUnlockWithFingerprint => 'Parmak İziyle Aç';

  @override
  String get vaultOrDivider => 'VEYA';

  @override
  String get vaultNewPin => 'Yeni PIN';

  @override
  String get vaultConfirmPin => 'PIN\'i Onayla';

  @override
  String get vaultEnterPin => 'PIN Girin';

  @override
  String get vaultKeyboardUseLetters => 'Harf kullan';

  @override
  String get vaultKeyboardUseNumbers => 'Rakam kullan';

  @override
  String get vaultRestoreLater => 'Sonra geri yükle';

  @override
  String get vaultForgotPin => 'PIN\'i unuttunuz mu?';

  @override
  String get vaultSetPinBtn => 'PIN Ayarla';

  @override
  String get vaultDecryptBtn => 'Kilidi Aç';

  @override
  String get vaultPinMinLength => 'PIN en az 6 karakter olmalıdır.';

  @override
  String get vaultPinsDoNotMatch => 'PIN kodları eşleşmiyor.';

  @override
  String get vaultSetupFailed => 'Kurulum başarısız oldu.';

  @override
  String get vaultIncorrectPin => 'Hatalı PIN. Tekrar deneyin.';

  @override
  String get vaultFingerprintOutOfDate => 'Parmak izi güncel değil. PIN girin.';

  @override
  String get vaultBiometricError => 'Biyometrik hata. PIN\'i elle girin.';

  @override
  String get vaultBioReasonUnlock => 'Kasayı açmak için biyometriyi kullanın';

  @override
  String get vaultBioReasonEnrol =>
      'Hızlı kilit açmayı etkinleştirmek için parmak izinizi onaylayın';

  @override
  String get vaultAskBioTitle => 'Parmak iziyle açılsın mı?';

  @override
  String get vaultAskBioDesc =>
      'Bu telefonda PIN yazmaktan kurtulun. Ancak yeni telefonlar için PIN\'inizi unutmayın.';

  @override
  String get vaultAskBioNotNow => 'Şimdi değil';

  @override
  String get vaultAskBioEnable => 'Etkinleştir';

  @override
  String get vaultDeleteMessagesTitle => 'Tüm mesajlar silinsin mi?';

  @override
  String get vaultDeleteMessagesDesc =>
      'PIN olmadan geçmiş çözülemez, sıfırlama işlemi her şeyi silecektir. Geri alınamaz.';

  @override
  String get vaultDeleteMessagesCancel => 'İptal';

  @override
  String get vaultDeleteMessagesConfirm => 'Her şeyi sil';

  @override
  String get vaultCustodyConfirmTitle => 'Kasa PIN kodunuzu onaylayın';

  @override
  String get vaultCustodyChooseTitle => 'Bir PIN seçin';

  @override
  String get vaultCustodyConfirmDesc =>
      'Mesaj geçmişiniz bir PIN ile korunuyor. Bir kez onaylayın.';

  @override
  String get vaultCustodyChooseDesc =>
      'Hatırlayacağınız bir PIN seçin. Tüm mesajlar yeni PIN ile tekrar şifrelenecektir.';

  @override
  String get vaultCustodyDontKnow => 'PIN kodumu bilmiyorum';

  @override
  String get vaultCustodyConfirmBtn => 'Onayla';

  @override
  String get vaultCustodySaveBtn => 'PIN\'i Kaydet';

  @override
  String get vaultCustodyMismatchError => 'Bu PIN eşleşmiyor.';

  @override
  String get vaultCustodyAutoUpdateFailed => 'PIN otomatik güncellenemedi.';

  @override
  String vaultCustodyReencrypting(int done, int total) {
    return '$total öğeden $done tanesi yeniden şifreleniyor… uygulamayı açık tutun.';
  }

  @override
  String get vaultCustodyPreparing => 'Hazırlanıyor… uygulamayı açık tutun.';

  @override
  String get vaultSettingsTitle => 'Kasa';

  @override
  String get vaultSettingsAboutTitle => 'Kasa Hakkında';

  @override
  String get vaultSettingsAboutDesc =>
      'Sohbet geçmişinizin PIN ile korunan özel yedeği. Sadece PIN kodunuz açabilir.';

  @override
  String get vaultSettingsBulletMessages => 'Mesajlarınız';

  @override
  String get vaultSettingsBulletStatuses => 'Gördüğünüz durumlar';

  @override
  String get vaultSettingsNeverKept =>
      'Burada asla tutulmaz: Arama geçmişi, kişiler veya fotoğraflar.';

  @override
  String get vaultSettingsSectionPrivacy => 'GİZLİLİK';

  @override
  String get vaultSettingsAutoDelete => 'Eski mesajları otomatik sil';

  @override
  String get vaultSettingsKeepForever => 'Süresiz sakla';

  @override
  String vaultSettingsDeleteAfter(String label) {
    return '$label sonra sil';
  }

  @override
  String get vaultSettingsSectionPin => 'PIN KODU';

  @override
  String get vaultSettingsChangePin => 'PIN Değiştir';

  @override
  String get vaultSettingsChangePinSubtitle =>
      'Tüm kasa verilerini yeniden şifreler';

  @override
  String get vaultSettingsBioTitle => 'Parmak iziyle kilit aç';

  @override
  String get vaultSettingsBioSubOn => 'Bu cihazda açık';

  @override
  String get vaultSettingsBioSubOff => 'Bu cihazda PIN girmeyi atla';

  @override
  String get vaultSettingsSectionDanger => 'TEHLİKELİ BÖLGE';

  @override
  String get vaultSettingsDeleteData => 'Kasa verilerini sil';

  @override
  String get vaultSettingsDeleteDataSubtitle =>
      'Şifreli geçmişi siler, PIN\'i korur';

  @override
  String get vaultSettingsResetVault => 'Kasayı sıfırla';

  @override
  String get vaultSettingsResetVaultSubtitle =>
      'PIN\'i unutur ve her şeyi siler';

  @override
  String get vaultSettingsPinChanged => 'PIN değiştirildi.';

  @override
  String get vaultSettingsBioTurnedOff => 'Parmak iziyle kilit açma kapatıldı.';

  @override
  String get vaultSettingsBioTurnedOn => 'Parmak iziyle kilit açma açıldı.';

  @override
  String get vaultSettingsClearDataTitle => 'Kasa verileri silinsin mi?';

  @override
  String get vaultSettingsClearDataDesc =>
      'Buluttaki şifreli mesajları siler. PIN kodunuz değişmez.';

  @override
  String get vaultSettingsClearDataCancel => 'İptal';

  @override
  String get vaultSettingsClearDataConfirm => 'Verileri sil';

  @override
  String get vaultSettingsDataDeleted => 'Kasa verileri silindi.';

  @override
  String get vaultSettingsResetTitle => 'Kasa sıfırlansın mı?';

  @override
  String get vaultSettingsResetDesc =>
      'PIN kodunuzu ve tüm geçmişi siler. Yeni PIN oluşturmanız gerekir.';

  @override
  String get vaultSettingsResetConfirm => 'Sıfırla';

  @override
  String get vaultSettingsChangeDialogDesc =>
      'Tüm veriler yeni PIN ile yeniden şifrelenecek.';

  @override
  String get vaultSettingsCurrentPin => 'Mevcut PIN';

  @override
  String get vaultSettingsNewPin => 'Yeni PIN';

  @override
  String get vaultSettingsConfirmNewPin => 'Yeni PIN\'i onayla';

  @override
  String get vaultSettingsEnterCurrentPin => 'Mevcut PIN\'i girin.';

  @override
  String get vaultSettingsNewPinMinLength => 'En az 6 karakter olmalı.';

  @override
  String get vaultSettingsNewPinMismatch => 'Yeni PIN kodları eşleşmiyor.';

  @override
  String get vaultSettingsCurrentPinIncorrect => 'Mevcut PIN hatalı.';

  @override
  String vaultSettingsReencryptingCount(int done, int total) {
    return '$total öğeden $done tanesi yeniden şifreleniyor…';
  }

  @override
  String get vaultSettingsChangeBtn => 'Değiştir';

  @override
  String get vaultSettingsBioPinDialogTitle => 'PIN Kodunuzu Girin';

  @override
  String get vaultSettingsBioPinDialogDesc =>
      'Parmak izini etkinleştirmek için PIN kodunuz gerekir.';

  @override
  String get vaultSettingsContinueBtn => 'Devam Et';

  @override
  String get premiumTitle => 'GupShupGo Pro';

  @override
  String get premiumSubtitleMember => 'Pro üyesisiniz! 🎉';

  @override
  String get premiumSubtitleUnlock => 'Tüm deneyimin kilidini açın';

  @override
  String premiumActiveDaysRemaining(int days) {
    return '$days gün kaldı';
  }

  @override
  String get premiumFeaturesHeader => 'Pro ile Neler Kazanırsınız';

  @override
  String get premiumPlansHeader => 'Planınızı Seçin';

  @override
  String get premiumSubscribeBtn => 'Hemen Abone Ol';

  @override
  String get premiumCancelAnytime =>
      'Google Play\'den istediğiniz zaman iptal edin.';

  @override
  String get premiumRestoreBtn => 'Önceki satın alımı geri yükle';

  @override
  String get premiumRestoring => 'Geri yükleniyor…';

  @override
  String get premiumRestoredSuccess => 'Pro aboneliği geri yüklendi! 🎉';

  @override
  String get premiumNoActiveSub => 'Aktif abonelik bulunamadı.';

  @override
  String get premiumProductUnavailable => 'Ürün mevcut değil.';

  @override
  String get premiumFeatureMediaTitle => 'Medya Durumları';

  @override
  String get premiumFeatureMediaDesc =>
      'Durum olarak fotoğraf ve video paylaşın';

  @override
  String get premiumFeatureMediaFree => 'Yalnızca metin';

  @override
  String get premiumFeatureMediaPro => 'Fotoğraf + Video';

  @override
  String get premiumFeatureScreenShareTitle => 'Ekran Paylaşımı';

  @override
  String get premiumFeatureScreenShareDesc =>
      'Sohbet sırasında ekranınızı canlı paylaşın';

  @override
  String get premiumFeatureScreenShareFree => 'Kilitli';

  @override
  String get premiumFeatureScreenSharePro => 'Tam erişim';

  @override
  String get premiumFeatureThemesTitle => 'Sohbet Temaları';

  @override
  String get premiumFeatureThemesDesc =>
      'Her sohbete özel arka plan ve baloncuklar';

  @override
  String get premiumFeatureThemesFree => '6 tema';

  @override
  String get premiumFeatureThemesPro => 'Tüm 12 tema + kendi fotoğrafınız';

  @override
  String get premiumFeatureVoiceTitle => 'Daha Uzun Sesli Mesajlar';

  @override
  String get premiumFeatureVoiceDesc => 'Süre sınırı olmadan ses kaydı yapın';

  @override
  String get premiumFeatureVoiceFree => '2 dakika';

  @override
  String get premiumFeatureVoicePro => 'Sınırsız';

  @override
  String get premiumFeatureQualityTitle => 'Yüksek Kaliteli Medya';

  @override
  String get premiumFeatureQualityDesc =>
      'Daha net fotoğraflar ve 90 sn durum videoları';

  @override
  String get premiumFeatureQualityFree => 'Standart kalite';

  @override
  String get premiumFeatureQualityPro => 'Yüksek kalite + 90s video';

  @override
  String get premiumFeatureBondTitle => 'Bağ Kurtarma';

  @override
  String get premiumFeatureBondDesc =>
      'Kopan arkadaşlık serilerini ücretsiz kurtarın';

  @override
  String get premiumFeatureBondFree => 'Puan veya reklam izleme';

  @override
  String get premiumFeatureBondPro => 'Haftada 1 ücretsiz kurtarma';

  @override
  String get premiumFeatureBadgeTitle => 'Pro Rozeti';

  @override
  String get premiumFeatureBadgeDesc => 'Pro statünüzü sergileyin';

  @override
  String get premiumFeatureBadgeFree => 'Rozet yok';

  @override
  String get premiumFeatureBadgePro => 'Özel Pro rozeti';

  @override
  String get premiumFeatureExportTitle => 'Sohbeti Dışa Aktar';

  @override
  String get premiumFeatureExportDesc =>
      'Sohbetleri PDF veya metin dosyası olarak kaydedin';

  @override
  String get premiumFeatureExportFree => 'Kullanılamaz';

  @override
  String get premiumFeatureExportPro => 'PDF ve TXT dışa aktarma';

  @override
  String get premiumFeatureAdFreeTitle => 'Reklamsız Deneyim';

  @override
  String get premiumFeatureAdFreeDesc => 'Uygulamada hiçbir banner reklamı yok';

  @override
  String get premiumFeatureAdFreeFree => 'Banner reklamlar var';

  @override
  String get premiumFeatureAdFreePro => 'Reklamsız';

  @override
  String get premiumPlanMonthly => 'Aylık';

  @override
  String get premiumPlanYearly => 'Yıllık';

  @override
  String get premiumPlanSavings => '~%33 tasarruf';

  @override
  String get premiumPeriodMonth => '/ay';

  @override
  String get premiumPeriodYear => '/yıl';

  @override
  String get nearbyOfflineChatTitle => 'Çevrimdışı Sohbet';

  @override
  String get nearbySearchingDevices => 'Yakındaki cihazlar taranıyor…';

  @override
  String get nearbyTooltipStop => 'Çevrimdışı sohbeti durdur';

  @override
  String get nearbyTooltipStart => 'Çevrimdışı sohbeti başlat';

  @override
  String get nearbyDevicesSection => 'Yakındaki Cihazlar';

  @override
  String get nearbyDiscoveryOn => 'TARAMA AÇIK';

  @override
  String get nearbyDiscoveryOff => 'TARAMA KAPALI';

  @override
  String get nearbyHeroTitle => 'Çevrimdışı Mod';

  @override
  String nearbyHeroNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kişi yakında',
      one: '1 kişi yakında',
    );
    return '$_temp0';
  }

  @override
  String get nearbyHeroOff => 'Çevrimdışı sohbet kapalı';

  @override
  String get nearbyHeroDesc =>
      '100 metre mesafedeki cihazlar taranıyor. İnternet gerektirmez.';

  @override
  String get nearbyYourNameHint => 'Adınız';

  @override
  String get nearbyEmptySearching => 'Yakındaki cihazlar taranıyor…';

  @override
  String get nearbyEmptyOff => 'Çevrimdışı sohbet kapalı';

  @override
  String get nearbyEmptySearchingDesc =>
      'Diğer cihazlarda Bluetooth açıkken GupShupGo\'nun açık olduğundan emin olun.';

  @override
  String get nearbyEmptyOffDesc =>
      'Taramayı başlatmak için sağ üstteki ikona dokunun.';

  @override
  String get nearbyPeerConnected => 'Bağlandı · Sohbet etmek için dokunun';

  @override
  String get nearbyPeerConnecting => 'Bağlanıyor…';

  @override
  String get nearbyPeerTapToConnect => 'Bağlanmak için dokunun';

  @override
  String get nearbyActionChat => 'Sohbet';

  @override
  String get nearbyActionConnecting => 'Bağlanıyor';

  @override
  String get nearbyActionConnect => 'Bağlan';

  @override
  String get nearbyPermNeededTitle => 'İzinler Gerekli';

  @override
  String get nearbyPermNeededDesc =>
      'Çevrimdışı sohbet için Bluetooth ve yakın cihaz izni gereklidir.';

  @override
  String get nearbyTryAgainBtn => 'Tekrar Dene';

  @override
  String get nearbySettingsBtn => 'Ayarlar';

  @override
  String get nearbyHelpTip =>
      'Arkadaşınızı göremiyor musunuz? İki cihazda da Bluetooth\'un açık olduğunu kontrol edin.';

  @override
  String get anonLobbyTitle => 'Anonim Sohbet';

  @override
  String get anonLobbyFinding => 'Biri aranıyor…';

  @override
  String get anonLobbyHangTight =>
      'Bekleyin — rastgele biriyle eşleştiriliyorsunuz.';

  @override
  String get anonLobbyCancelBtn => 'Aramayı İptal Et';

  @override
  String get anonLobbyPrivacyNote => 'Kimliğiniz gizli kalır.';

  @override
  String get anonLobbyConnecting => 'Bağlanıyor…';

  @override
  String get anonLobbyWaitingOthers =>
      'Diğer kullanıcıların çevrimiçi olması bekleniyor…';

  @override
  String anonLobbyOnlineCount(int count) {
    return '$count kişi şu an çevrimiçi';
  }

  @override
  String get anonChatNotEncrypted => 'Mesajlar uçtan uca şifreli değildir';

  @override
  String get anonChatRequestSentTooltip => 'İstek gönderildi';

  @override
  String get anonChatAddFriendTooltip => 'Arkadaş ekle';

  @override
  String get anonChatNextStrangerTooltip => 'Sonraki kişi';

  @override
  String get anonChatReportTooltip => 'Bildir';

  @override
  String get anonChatSayHi => 'Yabancıya merhaba deyin! 👋';

  @override
  String get anonChatFriendsTransition =>
      'Artık arkadaşsınız! Güvenli sohbet açılıyor…';

  @override
  String get anonChatStrangerDisconnected => 'Yabancı sohbetten ayrıldı 👋';

  @override
  String get anonChatFindNextBtn => 'Sonraki Yabancıyı Bul';

  @override
  String get anonChatFriendReqTitle => 'Yabancı arkadaş olmak istiyor!';

  @override
  String get anonChatFriendReqDesc =>
      'Kabul etmek gerçek profilinizi gösterir ve şifreli sohbet başlatır.';

  @override
  String get anonChatDecline => 'Reddet';

  @override
  String get anonChatAccept => 'Kabul Et';

  @override
  String get anonChatWaitingReqTitle => 'Arkadaşlık isteği gönderildi';

  @override
  String get anonChatWaitingReqDesc => 'Cevap bekleniyor…';

  @override
  String get anonChatReportTitle => 'Yabancıyı Bildir';

  @override
  String get anonChatReportQuestion => 'Neden bildiriyorsunuz?';

  @override
  String get anonChatReportReasonInappropriate => 'Uygunsuz içerik';

  @override
  String get anonChatReportReasonHarassment => 'Taciz veya zorbalık';

  @override
  String get anonChatReportReasonSpam => 'Spam veya dolandırıcılık';

  @override
  String get anonChatReportReasonThreatening => 'Tehditkar davranış';

  @override
  String get anonChatReportReasonOther => 'Diğer';

  @override
  String get anonChatReportCancel => 'İptal';

  @override
  String get anonChatReportSubmit => 'Bildir ve Ayrıl';

  @override
  String get anonChatReportSubmitted => 'Bildirim iletildi. Teşekkürler.';

  @override
  String get anonChatViewOnceVideoTitle => 'Bir kez oynat?';

  @override
  String get anonChatViewOncePhotoTitle => 'Bir kez aç?';

  @override
  String get anonChatViewOnceVideoDesc =>
      'Bu videoyu yalnızca bir kez açabilirsiniz.';

  @override
  String get anonChatViewOncePhotoDesc =>
      'Bu fotoğrafı yalnızca bir kez açabilirsiniz.';

  @override
  String get anonChatViewOnceCancel => 'İptal';

  @override
  String get anonChatViewOnceOpen => 'Aç';

  @override
  String get unsupportedVersionTitle => 'GupShupGo\'yu Güncelleyin';

  @override
  String get unsupportedVersionDesc =>
      'Bu sürüm artık desteklenmiyor. Sohbete devam etmek için güncelleyin.';

  @override
  String get unsupportedVersionUpdateNow => 'Şimdi güncelle';

  @override
  String get unsupportedVersionOpenPlayStore => 'Play Store\'u aç';

  @override
  String publicProfileNotFound(String username) {
    return '@$username bulunamadı';
  }

  @override
  String get publicProfileUserNotFound => 'Kullanıcı bulunamadı';

  @override
  String get publicProfileNotFoundDesc =>
      'Bu kullanıcı adı yok veya bağlantı bozuk.';

  @override
  String get publicProfileTitle => 'Profil';

  @override
  String get publicProfileOnline => 'Çevrimiçi';

  @override
  String publicProfileLastSeen(String time) {
    return 'Son görülme $time';
  }

  @override
  String get publicProfileJustNow => 'az önce';

  @override
  String publicProfileMinutesAgo(int minutes) {
    return '$minutes dk önce';
  }

  @override
  String publicProfileHoursAgo(int hours) {
    return '$hours sa önce';
  }

  @override
  String publicProfileDaysAgo(int days) {
    return '$days gün önce';
  }

  @override
  String publicProfileJoined(String date) {
    return '$date tarihinde katıldı';
  }

  @override
  String get publicProfileOwnLink => 'Bu sizin profil bağlantınızdır.';

  @override
  String publicProfileGupPoints(int points) {
    return '$points Gup Puanı';
  }

  @override
  String publicProfileLevel(int level) {
    return 'Seviye $level';
  }

  @override
  String get publicProfileStatPoints => 'Puan';

  @override
  String get publicProfileStatBadges => 'Rozet';

  @override
  String get publicProfileStatBestBond => 'En İyi Seri';

  @override
  String get publicProfileBadges => 'ROZETLER';

  @override
  String get qrScannerTitle => 'QR Kod Tara';

  @override
  String get qrScannerFlashOnTooltip => 'Flaş aç';

  @override
  String get qrScannerFlashOffTooltip => 'Flaş kapat';

  @override
  String get qrScannerPrompt => 'Kamerayı GupShupGo profil QR koduna doğrultun';

  @override
  String get qrScannerNotProfileCode => 'Bu bir GupShupGo profil kodu değil.';

  @override
  String get qrScannerCameraErrorTitle => 'Kamera başlatılamadı.';

  @override
  String get qrScannerCameraErrorRetry => 'Lütfen tekrar deneyin.';

  @override
  String get qrScannerPermissionMsg => 'Tarama için kamera izni gerekiyor.';

  @override
  String get qrScannerPermissionAllow => 'Kameraya izin ver';

  @override
  String get qrScannerBlockedMsg => 'Kamera engellendi. Ayarlardan açın.';

  @override
  String get qrScannerBlockedSettings => 'Ayarları aç';

  @override
  String get screenShareIncomingTitle => 'Gelen Ekran Paylaşımı';

  @override
  String get screenShareWantsToShare => 'ekranını paylaşmak istiyor';

  @override
  String get screenShareReject => 'Reddet';

  @override
  String get screenShareAccept => 'Kabul Et';

  @override
  String get screenShareCantAccept =>
      'Kabul edilemedi. Bağlantınızı kontrol edin.';

  @override
  String screenShareDeclined(String name) {
    return '$name ekran paylaşımını reddetti';
  }

  @override
  String get screenShareNoAnswer => 'Cevap yok';

  @override
  String get screenShareStartError => 'Ekran paylaşımı başlatılamadı';

  @override
  String get screenShareStatusRequesting => 'İzin isteniyor';

  @override
  String get screenShareStatusInitializing => 'Yayın başlatılıyor';

  @override
  String get screenShareStatusWaitingParticipant => 'Katılımcı bekleniyor';

  @override
  String get screenShareStatusActive => 'Ekran Paylaşımı Aktif';

  @override
  String screenShareSubWaitingAccept(String name) {
    return '$name kullanıcısının kabul etmesi bekleniyor…';
  }

  @override
  String get screenShareSubEstablishing => 'Şifreli bağlantı kuruluyor...';

  @override
  String screenShareSubWaitingJoin(String name) {
    return '$name katılması bekleniyor...';
  }

  @override
  String get screenShareSubActive =>
      'Tüm ekranınız yüksek çözünürlükte paylaşılıyor.';

  @override
  String get screenShareBadgeRequesting => 'İSTEK';

  @override
  String get screenShareBadgeConnecting => 'BAĞLANIYOR';

  @override
  String get screenShareSharedWith => 'Paylaşılan: ';

  @override
  String get screenShareRequestingFrom => 'İstek yapılan: ';

  @override
  String get screenShareMinimizeTip =>
      'Uygulamayı kullanmaya devam etmek için küçültebilirsiniz.';

  @override
  String get screenShareStop => 'Paylaşımı durdur';

  @override
  String get screenShareCancelRequest => 'İsteği iptal et';

  @override
  String screenShareViewerTitle(String name) {
    return '$name ekranını paylaşıyor';
  }

  @override
  String get screenShareViewerLive => 'CANLI YAYIN';

  @override
  String get screenShareViewerMinimize => 'Küçült';

  @override
  String get screenShareViewerLeave => 'Ayrıl';

  @override
  String screenShareViewerWaitingStream(String name) {
    return '$name kullanıcısının ekran yayını bekleniyor...';
  }

  @override
  String get screenShareViewerConnecting => 'Yayına bağlanılıyor...';

  @override
  String get viewOnceVideoTitle => 'Video · Tek seferlik görüntüleme';

  @override
  String get viewOncePhotoTitle => 'Fotoğraf · Tek seferlik görüntüleme';

  @override
  String get viewOnceCantOpen => 'Medya açılamadı.';

  @override
  String get viewOnceUnavailable => 'Bu medya artık mevcut değil.';

  @override
  String get viewOnceBlockedFooter => 'Ekran görüntüsü engellendi.';

  @override
  String get viewOnceUnblockedFooter => 'Yalnızca bir kez açılabilir.';
}
