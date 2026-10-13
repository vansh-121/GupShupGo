// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonOk => 'OK';

  @override
  String get commonContinue => 'Lanjutkan';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonGotIt => 'Mengerti';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsLanguageTitle => 'Bahasa';

  @override
  String get settingsLanguageSubtitle => 'Pilih bahasa pilihan Anda';

  @override
  String get languagePickerTitle => 'Bahasa';

  @override
  String get languageSystemDefault => 'Bawaan sistem';

  @override
  String get languageSystemDefaultSubtitle => 'Ikuti bahasa perangkat Anda';

  @override
  String get loginContinueWithPhone => 'Lanjutkan dengan Telepon';

  @override
  String get loginContinueWithGoogle => 'Lanjutkan dengan Google';

  @override
  String get loginUseEmailPassword => 'Gunakan Email & Kata Sandi';

  @override
  String get loginSignIn => 'Masuk';

  @override
  String get loginSignUp => 'Daftar';

  @override
  String get loginCreateAccount => 'Buat Akun';

  @override
  String get loginForgotPassword => 'Lupa Kata Sandi?';

  @override
  String get loginOfflineChat => 'Obrolan Offline';

  @override
  String get loginHintName => 'Nama Anda';

  @override
  String get loginHintEmail => 'Email';

  @override
  String get loginHintPassword => 'Kata Sandi';

  @override
  String get loginPasswordHelper =>
      'Minimal 8 karakter, mengandung huruf dan angka';

  @override
  String loginResetEmailSent(String email) {
    return 'Email reset kata sandi telah dikirim ke $email';
  }

  @override
  String get loginErrorEnterEmail => 'Silakan masukkan email Anda';

  @override
  String get loginErrorValidEmail => 'Silakan masukkan email yang valid';

  @override
  String get loginErrorEnterPassword => 'Silakan masukkan kata sandi Anda';

  @override
  String get loginErrorPasswordMin6 => 'Kata sandi minimal harus 6 karakter';

  @override
  String get loginErrorEnterPasswordSignup => 'Silakan masukkan kata sandi';

  @override
  String get loginErrorPasswordMin8 => 'Kata sandi minimal harus 8 karakter';

  @override
  String get loginErrorPasswordLetter => 'Kata sandi harus menyertakan huruf';

  @override
  String get loginErrorPasswordNumber => 'Kata sandi harus menyertakan angka';

  @override
  String get loginErrorEnterName => 'Silakan masukkan nama Anda';

  @override
  String get loginErrorGoogleCancelled => 'Masuk dengan Google dibatalkan.';

  @override
  String get loginErrorProfileLoad =>
      'Gagal memuat profil Anda. Periksa koneksi dan coba lagi.';

  @override
  String get loginErrorGoogleFailed =>
      'Gagal masuk dengan Google. Silakan coba lagi.';

  @override
  String get loginErrorSignInFailed => 'Gagal masuk. Silakan coba lagi.';

  @override
  String get loginErrorSignUpFailed => 'Gagal mendaftar. Silakan coba lagi.';

  @override
  String get loginErrorGeneric => 'Terjadi kesalahan. Silakan coba lagi.';

  @override
  String get loginErrorResetFailed =>
      'Gagal mengirim email reset. Silakan coba lagi.';

  @override
  String get loginErrorUserNotFound =>
      'Tidak ada akun dengan email ini. Silakan daftar.';

  @override
  String get loginErrorWrongPassword => 'Kata sandi salah. Silakan coba lagi.';

  @override
  String get loginErrorEmailInUse =>
      'Akun sudah terdaftar dengan email ini. Silakan masuk.';

  @override
  String get loginErrorInvalidEmail =>
      'Silakan masukkan alamat email yang valid.';

  @override
  String get loginErrorWeakPassword =>
      'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';

  @override
  String get loginErrorInvalidCredential =>
      'Email atau kata sandi tidak valid. Silakan periksa dan coba lagi.';

  @override
  String get loginErrorTooManyRequests =>
      'Terlalu banyak percobaan. Silakan coba lagi nanti.';

  @override
  String get homeNavChats => 'Obrolan';

  @override
  String get homeNavMoments => 'Momen';

  @override
  String get homeNavCalls => 'Panggilan';

  @override
  String get homeNavProfile => 'Profil';

  @override
  String get homeTooltipOfflineChat =>
      'Obrolan Offline — bicara dengan orang di sekitar';

  @override
  String get homeTooltipSearch => 'Cari';

  @override
  String get homeMenuProfile => 'Profil';

  @override
  String get homeMenuSettings => 'Pengaturan';

  @override
  String get homeMenuRateUs => 'Beri Nilai Kami';

  @override
  String get homeMenuReportIssue => 'Laporkan Masalah';

  @override
  String get homeMenuWhatsNew => 'Yang Baru';

  @override
  String get homeMenuLogOut => 'Keluar';

  @override
  String get homeEmptyChatsTitle => 'Belum ada obrolan';

  @override
  String get homeEmptyChatsSubtitle =>
      'Mulai percakapan dengan mengetuk tombol di bawah';

  @override
  String get homeNewChatButton => 'Obrolan baru';

  @override
  String get homeAiAssistantTitle => 'GupAI';

  @override
  String get homeAiAssistantSubtitle =>
      'Menulis draf, menerjemahkan, merangkum & lainnya';

  @override
  String get homeStrangerMatchTitle => 'Terhubung dengan Orang Baru';

  @override
  String get homeStrangerMatchSubtitle =>
      'Obrolan anonim — ketuk untuk mencocokkan!';

  @override
  String get homeMyMoment => 'Momen Saya';

  @override
  String get homeRecentMoments => 'Momen Terbaru';

  @override
  String get homeEmptyMomentsTitle => 'Belum ada pembaruan.';

  @override
  String get homeEmptyMomentsSubtitle => 'Ketuk kamera untuk berbagi.';

  @override
  String get homeTapToAddMoment => 'Ketuk untuk menambahkan pembaruan';

  @override
  String get homeEmptyCallsTitle => 'Tidak ada riwayat panggilan';

  @override
  String get homeEmptyCallsSubtitle =>
      'Panggilan terbaru Anda akan muncul di sini';

  @override
  String get chatInputHint => 'Pesan...';

  @override
  String get chatSearchHint => 'Cari pesan...';

  @override
  String get chatStatusTyping => 'mengetik...';

  @override
  String get chatStatusOnline => 'Online';

  @override
  String get chatStatusOffline => 'Offline';

  @override
  String chatStatusLastSeen(String time) {
    return 'Terakhir dilihat $time';
  }

  @override
  String get chatEndToEndEncrypted => 'Terenkripsi ujung ke ujung';

  @override
  String get chatNoInternetOfflineTitle =>
      'Tidak ada internet? Obrolan offline dengan perangkat terdekat';

  @override
  String get chatEnableOfflineButton => 'Aktifkan';

  @override
  String get chatSlideToCancel => 'Geser untuk membatalkan';

  @override
  String get chatTooltipVoiceCall => 'Panggilan Suara';

  @override
  String get chatTooltipVideoCall => 'Panggilan Video';

  @override
  String get chatMenuContactInfo => 'Info kontak';

  @override
  String get chatMenuSearch => 'Cari';

  @override
  String get chatMenuChatTheme => 'Tema obrolan';

  @override
  String get chatMenuExportChat => 'Ekspor obrolan';

  @override
  String get chatMenuMuteNotifications => 'Bisukan notifikasi';

  @override
  String get chatMenuUnmuteNotifications => 'Bunyikan notifikasi';

  @override
  String get chatMenuBlockContact => 'Blokir kontak';

  @override
  String get chatActionReply => 'Balas';

  @override
  String get chatActionCopy => 'Salin';

  @override
  String get chatActionForward => 'Teruskan';

  @override
  String get chatActionTranslate => 'Terjemahkan';

  @override
  String get chatActionSummarise => 'Rangkum';

  @override
  String get chatActionAskGupAi => 'Tanya GupAI';

  @override
  String get chatActionEdit => 'Edit';

  @override
  String get chatActionDelete => 'Hapus';

  @override
  String get chatDeleteMessageTitle => 'Hapus pesan?';

  @override
  String get chatDeleteMessageForEveryonePrompt =>
      'Hapus untuk Anda saja, atau untuk semua orang di obrolan ini?';

  @override
  String chatDeleteMessageForMeOnlyPrompt(String name) {
    return 'Ini hanya menghapusnya dari perangkat Anda. $name masih bisa melihatnya.';
  }

  @override
  String get chatDeleteForMe => 'Hapus untuk saya';

  @override
  String get chatDeleteForEveryone => 'Hapus untuk semua';

  @override
  String chatBlockContactTitle(String name) {
    return 'Blokir $name?';
  }

  @override
  String get chatBlockContactPrompt =>
      'Kontak yang diblokir tidak dapat mengirimi Anda pesan atau menelepon Anda. Anda dapat membuka blokir dari Pengaturan → Privasi.';

  @override
  String get chatBlockButton => 'Blokir';

  @override
  String get chatForwardTo => 'Teruskan ke';

  @override
  String get chatNoForwardChats => 'Tidak ada obrolan lain untuk diteruskan';

  @override
  String get chatCannotSendMediaBlocked =>
      'Tidak dapat mengirim media ke kontak ini';

  @override
  String get attachmentShareTitle => 'Bagikan';

  @override
  String get attachmentPhoto => 'Foto';

  @override
  String get attachmentPhotoSubtitle => 'Pilih gambar dari galeri Anda';

  @override
  String get attachmentVideo => 'Video';

  @override
  String get attachmentVideoSubtitle => 'Pilih video dari galeri Anda';

  @override
  String get attachmentDocument => 'Dokumen';

  @override
  String get attachmentDocumentSubtitle =>
      'PDF, file Office, arsip — dikirim apa adanya';

  @override
  String get attachmentLocation => 'Lokasi';

  @override
  String get attachmentLocationSubtitle => 'Bagikan lokasi Anda saat ini';

  @override
  String get attachmentViewOnce => 'Sekali lihat';

  @override
  String get attachmentViewOnceSubtitle =>
      'Foto atau video menghilang setelah dibuka';

  @override
  String get contactsTitle => 'Kontak & Temukan';

  @override
  String get contactsTabFriends => 'Teman';

  @override
  String get contactsTabRequests => 'Permintaan';

  @override
  String get contactsTabDiscover => 'Temukan';

  @override
  String get contactsScanQrTooltip => 'Pindai Kode QR';

  @override
  String get contactsMyHandleTooltip => 'Handle Saya';

  @override
  String get contactsSetUsernamePrompt =>
      'Atur @username di profil Anda terlebih dahulu — itulah yang dibagikan kode QR Anda.';

  @override
  String get contactsMyQrCodeTitle => 'Kode QR Profil Saya';

  @override
  String get contactsMyQrCodeSubtitle =>
      'Teman dapat memindai kode QR ini untuk terhubung seketika';

  @override
  String get contactsCopyProfileLink => 'Salin Tautan Profil';

  @override
  String contactsProfileLinkCopied(String username) {
    return 'Tautan profil untuk @$username disalin!';
  }

  @override
  String get contactsScanSomeonesCode => 'Pindai Kode Orang Lain';

  @override
  String get contactsPermissionDenied => 'Izin untuk mengakses kontak ditolak.';

  @override
  String get contactsNoUsersFound =>
      'Belum ada pengguna GupShupGo yang ditemukan di kontak Anda.';

  @override
  String contactsFailedToSync(String error) {
    return 'Gagal menyinkronkan kontak: $error';
  }

  @override
  String contactsMatchedCount(int count) {
    return '$count kontak di GupShupGo';
  }

  @override
  String get contactsFromDeviceContacts => 'Dari kontak perangkat Anda';

  @override
  String get contactsLoadFriendsError => 'Tidak dapat memuat teman Anda.';

  @override
  String get contactsNoFriendsTitle => 'Belum Ada Teman';

  @override
  String get contactsNoFriendsPrompt =>
      'Gunakan tab Temukan untuk mencari pengguna berdasarkan @username, telepon, atau email dan kirim permintaan pertemanan!';

  @override
  String get contactsDiscoverPeopleButton => 'Temukan Orang';

  @override
  String get contactsQuickConnectHeader => 'KONEKSI CEPAT';

  @override
  String get contactsNoSuggestions => 'Tidak ada saran saat ini.';

  @override
  String get contactsLoadRequestsError => 'Tidak dapat memuat permintaan Anda.';

  @override
  String contactsPendingRequestsHeader(int count) {
    return 'PERMINTAAN TERTUNDA ($count)';
  }

  @override
  String get contactsNoPendingRequestsTitle => 'Tidak Ada Permintaan Tertunda';

  @override
  String get contactsNoPendingRequestsSubtitle =>
      'Saat pengguna mengirim permintaan koneksi, permintaan akan muncul di sini.';

  @override
  String get contactsWantsToConnect => 'Ingin terhubung';

  @override
  String get contactsAcceptButton => 'TERIMA';

  @override
  String get contactsAcceptFailed =>
      'Tidak dapat menerima permintaan. Silakan coba lagi.';

  @override
  String contactsConnectedWith(String name) {
    return 'Terhubung dengan $name!';
  }

  @override
  String get contactsDeclineFailed =>
      'Tidak dapat menolak permintaan. Silakan coba lagi.';

  @override
  String get contactsYouMightKnowHeader => 'MUNGKIN ANDA KENAL';

  @override
  String get contactsSeeAll => 'LIHAT SEMUA';

  @override
  String get contactsSearchHint => 'Cari nama, @handle, telepon atau email...';

  @override
  String get contactsTurnOnDiscoverability =>
      'Aktifkan Keterlihatan agar muncul di pencarian dan saran.';

  @override
  String get contactsNoMatchingUsersTitle => 'Pengguna Tidak Ditemukan';

  @override
  String get contactsNoMatchingUsersSubtitle =>
      'Periksa @username, nomor telepon, atau email dan coba lagi.';

  @override
  String get contactsDiscoverHeroTitle => 'Temukan Orang di GupShupGo';

  @override
  String get contactsDiscoverHeroSubtitle =>
      'Perluas relasi Anda dengan koneksi tepercaya di seluruh dunia.';

  @override
  String get contactsSyncDeviceContacts => 'Sinkronkan Kontak Perangkat';

  @override
  String get contactsSyncingContacts => 'Menyinkronkan kontak...';

  @override
  String get contactsSyncDeviceSubtitle =>
      'Temukan teman Anda seketika dari buku telepon';

  @override
  String get contactsSuggestedUsersHeader => 'PENGGUNA YANG DISARANKAN';

  @override
  String get contactsAddFriendButton => 'TAMBAH TEMAN';

  @override
  String get contactsRequestedButton => 'Diminta';

  @override
  String contactsRequestSent(String name) {
    return 'Permintaan pertemanan dikirim ke $name!';
  }

  @override
  String get contactsRequestFailed =>
      'Permintaan pertemanan sudah tertunda atau gagal.';

  @override
  String get contactsRequestUnavailable =>
      'Permintaan itu sudah tidak tersedia.';

  @override
  String get profileEditTitle => 'Edit Profil';

  @override
  String get profileSaveButton => 'Simpan';

  @override
  String get profileTapToChangePhoto => 'Ketuk untuk mengubah foto';

  @override
  String get profileUpgradeToPro => 'Tingkatkan ke Pro';

  @override
  String get profileSectionName => 'NAMA ANDA';

  @override
  String get profileNameHint => 'Masukkan nama Anda';

  @override
  String get profileSectionHandle => 'HANDLE UNIK';

  @override
  String get profileHandleNotSet => 'Belum diatur';

  @override
  String get profileChangeHandle => 'Ubah';

  @override
  String get profileSectionAbout => 'TENTANG';

  @override
  String get profileAboutHint => 'Apa yang Anda pikirkan?';

  @override
  String get profileDefaultAbout => 'Hai! Saya menggunakan GupShupGo.';

  @override
  String get profileSectionPhone => 'TELEPON';

  @override
  String get profileSectionEmail => 'EMAIL';

  @override
  String get profileSectionLinkedMethods => 'METODE MASUK TERTAUT';

  @override
  String get profileNotLinked => 'Tidak ditautkan';

  @override
  String get profileNameEmpty => 'Nama tidak boleh kosong.';

  @override
  String get profileUpdatedSuccess => 'Profil diperbarui';

  @override
  String profileUploadPhotoFailed(String error) {
    return 'Gagal mengunggah foto: $error';
  }

  @override
  String profileSaveFailed(String error) {
    return 'Gagal menyimpan profil: $error';
  }

  @override
  String get profilePoints => 'Poin';

  @override
  String get profileBadges => 'Lencana';

  @override
  String get profileBestBond => 'Streak Terbaik';

  @override
  String get settingsAccountCard => 'Akun';

  @override
  String get settingsProfileTile => 'Profil';

  @override
  String get settingsLinkedMethodsTile => 'Metode masuk tertaut';

  @override
  String get settingsPhoneTile => 'Nomor telepon';

  @override
  String get settingsEmailTile => 'Email';

  @override
  String get settingsPrivacyCard => 'Privasi';

  @override
  String get settingsDiscoverability => 'Keterlihatan (Discoverability)';

  @override
  String get settingsLastSeen => 'Terakhir dilihat';

  @override
  String get settingsReadReceipts => 'Laporan dibaca';

  @override
  String get settingsAdPreferences => 'Preferensi iklan';

  @override
  String get settingsManage => 'Kelola';

  @override
  String get settingsAppearanceCard => 'Tampilan';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeLight => 'Terang';

  @override
  String get settingsThemeDark => 'Gelap';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsChatTheme => 'Tema obrolan';

  @override
  String get settingsHelpSecurityCard => 'Bantuan & Keamanan';

  @override
  String get settingsHelpCenter => 'Pusat Bantuan';

  @override
  String get settingsReportProblem => 'Laporkan masalah';

  @override
  String get settingsE2EEShield => 'Enkripsi ujung-ke-ujung (Brankas)';

  @override
  String get settingsVerifySafetyNumber => 'Verifikasi nomor keamanan';

  @override
  String get settingsBlockedContacts => 'Kontak diblokir';

  @override
  String get settingsClearAllGupHistory => 'Hapus semua riwayat obrolan';

  @override
  String get settingsRateUs => 'Beri kami nilai';

  @override
  String get settingsWhatsNew => 'Yang Baru';

  @override
  String get settingsCheckForUpdates => 'Periksa pembaruan';

  @override
  String get settingsAppInfo => 'Info aplikasi';

  @override
  String get settingsLogOut => 'Keluar';

  @override
  String get settingsLogOutConfirmTitle => 'Keluar';

  @override
  String get settingsLogOutConfirmPrompt =>
      'Apakah Anda yakin ingin keluar dari GupShupGo?';

  @override
  String get settingsSigningOut => 'Sedang keluar…';

  @override
  String get settingsClearChatsConfirmTitle => 'Hapus semua obrolan';

  @override
  String get settingsClearChatsConfirmPrompt =>
      'Ini akan menghapus riwayat pesan Anda secara permanen. Tindakan ini tidak dapat dibatalkan.';

  @override
  String get settingsDeleteAll => 'Hapus Semua';

  @override
  String get settingsClearingChats => 'Menghapus obrolan...';

  @override
  String get settingsAllChatsCleared => 'Semua obrolan dihapus';

  @override
  String settingsClearChatsFailed(String error) {
    return 'Gagal menghapus obrolan: $error';
  }

  @override
  String get settingsChooseThemeTitle => 'Pilih tema';

  @override
  String get settingsUnlockPremiumFeatures => 'Buka fitur premium';

  @override
  String settingsProDaysLeft(String planLabel, int daysRemaining) {
    return '$planLabel · Sisa $daysRemaining hari';
  }

  @override
  String get settingsCheckingForUpdates => 'Memeriksa pembaruan…';

  @override
  String settingsUpToDate(String version) {
    return 'Anda menggunakan versi terbaru (v$version).';
  }

  @override
  String get settingsUpdateCheckUnavailable =>
      'Tidak dapat memeriksa pembaruan. Pastikan aplikasi dipasang dari Google Play Store.';

  @override
  String get settingsNoBlockedContacts => 'Tidak ada kontak yang diblokir';

  @override
  String get settingsUnblock => 'Buka blokir';

  @override
  String settingsUserUnblocked(String name) {
    return '$name dibuka blokirnya';
  }

  @override
  String get settingsVerifyContactTitle => 'Verifikasi kontak';

  @override
  String get settingsVerifyContactSubtitle =>
      'Pilih kontak untuk melihat nomor keamanan bersama.';

  @override
  String get settingsComputingSafetyNumber => 'Menghitung nomor keamanan…';

  @override
  String settingsSafetyNumberExplanation(String name) {
    return 'Jika nomor cocok di perangkat $name, enkripsi ujung-ke-ujung Anda terverifikasi.';
  }

  @override
  String get settingsSafetyNumberNoBundle =>
      'Kontak ini belum memublikasikan bundel kunci enkripsi.';

  @override
  String get settingsSafetyNumberCompareHint =>
      'Bandingkan nomor ini secara langsung atau melalui panggilan tepercaya.';

  @override
  String get callEndToEndEncrypted => 'Terenkripsi ujung ke ujung';

  @override
  String get callSecuring => 'Mengamankan panggilan…';

  @override
  String get callNotEncrypted => 'Tidak terenkripsi';

  @override
  String get callIncomingVoice => 'Panggilan Suara Masuk';

  @override
  String get callIncomingVideo => 'Panggilan Video Masuk';

  @override
  String get callVoiceCall => 'Panggilan Suara';

  @override
  String get callVideoCall => 'Panggilan Video';

  @override
  String get callDecline => 'Tolak';

  @override
  String get callAccept => 'Terima';

  @override
  String get callConnecting => 'Menghubungkan...';

  @override
  String get callSettingUp => 'Menyiapkan panggilan...';

  @override
  String callNotifying(String name) {
    return 'Memberitahu $name...';
  }

  @override
  String get callRinging => 'Berdering...';

  @override
  String get callConnected => 'Terhubung';

  @override
  String get callOnHold => 'Ditahan';

  @override
  String get callCalling => 'Memanggil...';

  @override
  String get callWaitingForUser => 'Menunggu pengguna lain...';

  @override
  String get callEnded => 'Panggilan Berakhir';

  @override
  String get callDeclined => 'Panggilan Ditolak';

  @override
  String get callNoAnswer => 'Tidak Ada Jawaban';

  @override
  String get callFailedToConnect => 'Gagal terhubung';

  @override
  String callFailedToStart(String error) {
    return 'Gagal memulai panggilan: $error';
  }

  @override
  String get callTokenExpired =>
      'Token kedaluwarsa atau tidak valid. Silakan mulai ulang panggilan.';

  @override
  String callFailedToInit(String type, String error) {
    return 'Gagal menginisialisasi panggilan $type: $error';
  }

  @override
  String get callTurnOffSpeaker => 'Matikan speaker';

  @override
  String get callTurnOnSpeaker => 'Nyalakan speaker';

  @override
  String get callMuteMic => 'Bisukan mikrofon';

  @override
  String get callUnmuteMic => 'Bunyikan mikrofon';

  @override
  String get callEndCall => 'Akhiri panggilan';

  @override
  String get callSwitchCamera => 'Ganti kamera';

  @override
  String get callTurnOffCamera => 'Matikan kamera';

  @override
  String get callTurnOnCamera => 'Nyalakan kamera';

  @override
  String statusViewedByCount(int count) {
    return 'Dilihat oleh $count';
  }

  @override
  String get statusNoViewsYet => 'Belum ada yang melihat';

  @override
  String statusViewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kali dilihat',
      one: '1 kali dilihat',
    );
    return '$_temp0';
  }

  @override
  String get statusDeleteTitle => 'Hapus Status';

  @override
  String get statusDeleteConfirm =>
      'Apakah Anda yakin ingin menghapus status ini?';

  @override
  String get statusDeleteButton => 'Hapus';

  @override
  String get statusReplySent => 'Balasan terkirim';

  @override
  String statusReplyFailed(String error) {
    return 'Gagal mengirim balasan: $error';
  }

  @override
  String get statusNoActive => 'Tidak ada status aktif';

  @override
  String get statusCouldNotLoad => 'Tidak dapat memuat pembaruan ini';

  @override
  String get statusTapToRetry => 'Ketuk untuk mencoba lagi';

  @override
  String get statusFailedToLoadImage => 'Gagal memuat gambar';

  @override
  String get statusLoadingVideo => 'Memuat video...';

  @override
  String get statusEnterTextPrompt => 'Silakan masukkan teks';

  @override
  String get statusNoContactsNotice =>
      'Belum ada kontak — mulai obrolan sebelum membuat status.';

  @override
  String statusPostFailed(String error) {
    return 'Gagal memposting status: $error';
  }

  @override
  String get statusTypeHint => 'Ketik status...';

  @override
  String get statusCamera => 'Kamera';

  @override
  String get statusTakePhoto => 'Ambil foto';

  @override
  String get statusGalleryPhoto => 'Foto Galeri';

  @override
  String get statusChooseImageGallery => 'Pilih gambar dari galeri';

  @override
  String get statusRecordVideo => 'Rekam Video';

  @override
  String get statusRecordShortVideo => 'Rekam video pendek';

  @override
  String get statusGalleryVideo => 'Video Galeri';

  @override
  String get statusChooseVideoGallery => 'Pilih video dari galeri';

  @override
  String statusFailedPickImage(String error) {
    return 'Gagal memilih gambar: $error';
  }

  @override
  String statusFailedPickVideo(String error) {
    return 'Gagal memilih video: $error';
  }

  @override
  String get statusChangeBgColorTooltip => 'Ubah warna latar belakang';

  @override
  String aiMessagesRemaining(int count) {
    return 'Sisa $count';
  }

  @override
  String get aiQuotaDialogTitle => 'Pesan GupAI';

  @override
  String aiQuotaRemainingOfTotal(int remaining, int total) {
    return 'Sisa $remaining dari $total hari ini';
  }

  @override
  String aiQuotaUsedResetNote(int used) {
    return 'Terpakai $used hari ini · direset besok. Tonton iklan atau upgrade ke Pro.';
  }

  @override
  String get aiQuotaGotIt => 'Mengerti';

  @override
  String get aiTitle => 'GupAI';

  @override
  String get aiSubtitle => 'Asisten dalam aplikasi Anda';

  @override
  String get aiEmptyHelpTitle => 'Ada yang bisa dibantu?';

  @override
  String get aiEmptyHelpSubtitle =>
      'Buat draf, terjemahkan, ringkas, atau ajukan pertanyaan.';

  @override
  String get meshOfflineChatConnected => 'Obrolan offline · terhubung';

  @override
  String get meshConnecting => 'Menghubungkan…';

  @override
  String get meshBannerNotice =>
      'Obrolan offline — tanpa internet, tanpa server';

  @override
  String meshSayHiTo(String name) {
    return 'Sapa $name';
  }

  @override
  String meshOfflineDescription(String name) {
    return 'Anda berada di obrolan offline. Pesan hanya ada antara Anda dan $name.';
  }

  @override
  String get meshMediaUnavailable => 'Media ini tidak lagi tersedia.';

  @override
  String get meshViewOnceTitle => 'Lihat sekali';

  @override
  String meshViewOncePrompt(String type) {
    return 'Anda hanya dapat membuka $type ini satu kali.';
  }

  @override
  String get arcadeTabOverview => 'Ikhtisar';

  @override
  String get arcadeTabChallenges => 'Tantangan';

  @override
  String get arcadeTabLeaderboard => 'Papan Peringkat';

  @override
  String get arcadeFailedLoadStats => 'Gagal memuat statistik reputasi.';

  @override
  String get aiAskHint => 'Tanyakan apa saja ke GupAI…';
}
