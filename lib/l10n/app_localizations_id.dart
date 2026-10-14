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
  String get homeNavChats => 'Pesan';

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
  String get attachmentScreenShare => 'Bagi layar';

  @override
  String get attachmentScreenShareSubtitle =>
      'Tampilkan layar Anda secara langsung selama obrolan';

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

  @override
  String get settingsNotificationsTile => 'Notifikasi';

  @override
  String get settingsNotificationsStatusOn => 'Aktif';

  @override
  String get settingsNotificationsStatusOff => 'Mati';

  @override
  String get settingsNotificationsEnabledToast => 'Notifikasi aktif.';

  @override
  String get settingsEnableNotificationsTitle => 'Aktifkan notifikasi';

  @override
  String get settingsEnableNotificationsBody =>
      'Notifikasi dimatikan. Buka pengaturan sistem agar GupShupGo dapat memberi tahu Anda tentang pesan dan panggilan baru.';

  @override
  String get settingsOpenSystemSettings => 'Buka pengaturan';

  @override
  String get loginTagline =>
      'Pesan pribadi yang berfungsi bahkan tanpa internet.';

  @override
  String get settingsPrivacyPolicy => 'Kebijakan Privasi';

  @override
  String get settingsTerms => 'Ketentuan Layanan';

  @override
  String get settingsDeleteAccount => 'Hapus akun';

  @override
  String get inviteSheetTitle => 'Undang teman';

  @override
  String get inviteSheetSubtitle => 'Sebarkan — bagikan GupShupGo';

  @override
  String get inviteShareImageBtn => 'Bagikan gambar';

  @override
  String get inviteShareLinkBtn => 'Bagikan tautan';

  @override
  String get inviteCopyLinkBtn => 'Salin tautan';

  @override
  String get inviteLinkCopied => 'Tautan undangan disalin';

  @override
  String inviteMessage(String link) {
    return 'Ngobrol dengan saya di GupShupGo — bahkan berfungsi tanpa internet 👋 $link';
  }

  @override
  String get inviteCardTagline =>
      'Obrolan pribadi yang berfungsi bahkan saat offline';

  @override
  String get inviteCardScan => 'Pindai untuk mengunduh';

  @override
  String get inviteCardDownload => 'Unduh di Google Play';

  @override
  String get homeMenuInvite => 'Undang teman';

  @override
  String get invitePromptTitle => 'Menikmati GupShupGo?';

  @override
  String get invitePromptBody =>
      'Lebih seru bersama teman — dan berfungsi tanpa internet. Ingin mengundang seseorang?';

  @override
  String get invitePromptInvite => 'Undang teman';

  @override
  String get invitePromptLater => 'Mungkin nanti';

  @override
  String get homeOfflineBannerTitle => 'Tidak ada internet? Tidak masalah';

  @override
  String get homeOfflineBannerSubtitle =>
      'Anda masih dapat mengirim pesan ke orang sekitar melalui Bluetooth.';

  @override
  String homeNearbyBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orang di sekitar',
      one: '1 orang di sekitar',
    );
    return '$_temp0';
  }

  @override
  String get homeNearbyBannerSubtitle =>
      'Mengobrol via Bluetooth — tidak perlu internet.';

  @override
  String get linkBackupTitle => 'Tambah metode masuk cadangan';

  @override
  String get linkBackupSubtitle =>
      'Hubungkan Google atau email agar Anda dapat masuk kembali\nbahkan jika kartu SIM tidak tersedia.';

  @override
  String get linkGoogleTitle => 'Hubungkan Akun Google';

  @override
  String get linkGoogleSubtitleLinked => 'Terhubung ✓';

  @override
  String get linkGoogleSubtitleUnlinked => 'Masuk sekali ketuk tanpa SIM';

  @override
  String get linkGoogleAction => 'Hubungkan';

  @override
  String get linkGoogleSuccess => 'Akun Google berhasil dihubungkan!';

  @override
  String get linkGoogleAlreadyUsed =>
      'Akun Google ini sudah terdaftar sebagai akun GupShupGo lain. Untuk menggabungkan, keluar lalu masuk dengan Google, kemudian hubungkan nomor telepon Anda dari pengaturan.';

  @override
  String get linkGoogleFailed => 'Gagal menghubungkan Google. Coba lagi.';

  @override
  String get linkSessionExpired =>
      'Sesi telah berakhir. Silakan masuk kembali.';

  @override
  String get linkEmailTitle => 'Hubungkan Email & Kata Sandi';

  @override
  String get linkEmailSubtitleLinked => 'Terhubung ✓';

  @override
  String get linkEmailSubtitleUnlinked =>
      'Masuk dengan email jika tidak ada SIM atau Google';

  @override
  String get linkEmailActionAdd => 'Tambah';

  @override
  String get linkEmailActionCancel => 'Batal';

  @override
  String get linkEmailFieldLabel => 'Email';

  @override
  String get linkPasswordFieldLabel => 'Buat kata sandi';

  @override
  String get linkPasswordHelper => 'Minimal 6 karakter';

  @override
  String get linkEmailButton => 'Hubungkan Email';

  @override
  String get linkEmailSuccess => 'Email berhasil dihubungkan!';

  @override
  String get linkEmailInvalid => 'Masukkan alamat email yang valid.';

  @override
  String get linkPasswordTooShort =>
      'Kata sandi harus terdiri dari minimal 6 karakter.';

  @override
  String get linkEmailAlreadyInUse =>
      'Email ini sudah terdaftar di GupShupGo. Masuk dengan email terlebih dahulu, lalu hubungkan nomor telepon dari pengaturan.';

  @override
  String get linkEmailAlreadyLinked => 'Email sudah terhubung ke akun Anda.';

  @override
  String get linkEmailFailed => 'Gagal menghubungkan email. Coba lagi.';

  @override
  String get linkContinueToApp => 'Lanjutkan ke Aplikasi';

  @override
  String get linkSkipForNow => 'Lewati untuk Sekarang';

  @override
  String get linkSkip => 'Lewati';

  @override
  String get phoneAuthTitleEntry => 'Masuk dengan nomor telepon Anda.';

  @override
  String get phoneAuthTitleOtp => 'Masukkan kode yang kami kirimkan.';

  @override
  String get phoneAuthNameHint => 'Nama Anda';

  @override
  String get phoneAuthPhoneHint => 'Nomor Telepon';

  @override
  String get phoneAuthUseSim => 'Gunakan SIM';

  @override
  String get phoneAuthSendOtp => 'Kirim OTP';

  @override
  String phoneAuthOtpPrompt(String phone) {
    return 'Masukkan kode 6 digit yang dikirim ke $phone';
  }

  @override
  String get phoneAuthOtpPromptGeneric =>
      'Masukkan kode 6 digit yang kami kirimkan kepada Anda';

  @override
  String get phoneAuthOtpHint => 'Masukkan kode';

  @override
  String get phoneAuthVerify => 'Verifikasi';

  @override
  String get phoneAuthGoBack => 'Kembali';

  @override
  String get phoneAuthResendCode => 'Kirim ulang kode';

  @override
  String get phoneAuthEnterName => 'Silakan masukkan nama Anda';

  @override
  String get phoneAuthEnterValidPhone =>
      'Silakan masukkan nomor telepon yang valid';

  @override
  String get phoneAuthEnterCode => 'Silakan masukkan kode';

  @override
  String get phoneAuthRequestNewCode => 'Silakan minta kode baru.';

  @override
  String get phoneAuthCodeIncorrect =>
      'Kode tersebut salah. Silakan coba lagi.';

  @override
  String get phoneAuthErrCodeIncorrect => 'Kode salah. Coba lagi.';

  @override
  String get phoneAuthErrCodeExpired =>
      'Kode telah kedaluwarsa. Minta kode baru.';

  @override
  String get phoneAuthErrTooManyRequests =>
      'Terlalu banyak permintaan. Tunggu sebentar dan coba lagi.';

  @override
  String get phoneAuthErrInvalidPhone => 'Nomor telepon tidak valid.';

  @override
  String get phoneAuthErrQuotaExceeded =>
      'Kuota SMS terlampaui. Coba lagi nanti.';

  @override
  String get phoneAuthErrFailed => 'Gagal mengirim kode verifikasi. Coba lagi.';

  @override
  String get usernameSetupAppBarTitle => 'Pengaturan Nama Pengguna';

  @override
  String get usernameSetupHeaderTitle => 'Pilih nama pengguna Anda';

  @override
  String get usernameSetupHeaderDesc =>
      'Pilih nama unik agar teman dapat menemukan Anda di GupShupGo.';

  @override
  String get usernameSetupInputHint => 'nama_pengguna';

  @override
  String get usernameSetupChecking => 'Memeriksa ketersediaan…';

  @override
  String usernameSetupAvailable(String handle) {
    return '@$handle tersedia!';
  }

  @override
  String usernameSetupTaken(String handle) {
    return '@$handle sudah digunakan pengguna lain.';
  }

  @override
  String get usernameSetupCharRules =>
      'Karakter yang diizinkan: a-z, 0-9, garis bawah (_), titik (.)';

  @override
  String get usernameSetupTooShort => 'Nama pengguna minimal 3 karakter';

  @override
  String get usernameSetupTooLong => 'Nama pengguna maksimal 20 karakter';

  @override
  String get usernameSetupInvalidChars =>
      'Hanya huruf kecil, angka, _, dan . yang diperbolehkan';

  @override
  String get usernameSetupRecommended => 'Disarankan:';

  @override
  String get usernameSetupSaveBtn => 'Simpan Nama Pengguna';

  @override
  String get usernameSetupSkipBtn => 'Lewati untuk Sekarang';

  @override
  String usernameSetupFailed(String error) {
    return 'Gagal menyimpan nama pengguna: $error';
  }

  @override
  String get vaultProtectTitle => 'Lindungi Obrolan Rahasia';

  @override
  String get vaultUnlockTitle => 'Buka Brankas Terenkripsi';

  @override
  String get vaultSetupDesc =>
      'Atur PIN brankas atau frasa sandi untuk mengenkripsi obrolan brankas Anda.';

  @override
  String get vaultUnlockDescBio =>
      'Gunakan biometrik atau masukkan PIN untuk mengakses.';

  @override
  String get vaultUnlockDescPin =>
      'Masukkan PIN brankas untuk mendekripsi pesan rahasia Anda.';

  @override
  String get vaultReinstallHint =>
      'Memasang ulang aplikasi? Masukkan PIN yang Anda buat sebelumnya.';

  @override
  String get vaultUnlockWithFingerprint => 'Buka dengan Sidik Jari';

  @override
  String get vaultOrDivider => 'ATAU';

  @override
  String get vaultNewPin => 'PIN Brankas Baru';

  @override
  String get vaultConfirmPin => 'Konfirmasi PIN Baru';

  @override
  String get vaultEnterPin => 'Masukkan PIN Brankas';

  @override
  String get vaultKeyboardUseLetters => 'Gunakan Papan Ketik Huruf (Frasa)';

  @override
  String get vaultKeyboardUseNumbers => 'Gunakan Papan Tombol Angka (PIN)';

  @override
  String get vaultRestoreLater => 'Pulihkan Nanti';

  @override
  String get vaultForgotPin => 'Lupa PIN?';

  @override
  String get vaultSetPinBtn => 'Atur PIN & Enkripsi';

  @override
  String get vaultDecryptBtn => 'Dekripsi & Buka';

  @override
  String get vaultPinMinLength => 'PIN harus minimal 4 karakter';

  @override
  String get vaultPinsDoNotMatch => 'PIN tidak cocok';

  @override
  String get vaultSetupFailed => 'Pengaturan brankas gagal. Coba lagi.';

  @override
  String get vaultIncorrectPin => 'PIN salah';

  @override
  String get vaultFingerprintOutOfDate =>
      'Data sidik jari telah diperbarui. Harap gunakan PIN Anda.';

  @override
  String get vaultBiometricError => 'Biometrik tidak tersedia';

  @override
  String get vaultBioReasonUnlock =>
      'Otentikasi untuk membuka obrolan brankas Anda';

  @override
  String get vaultBioReasonEnrol =>
      'Otentikasi untuk mengaktifkan akses biometrik brankas';

  @override
  String get vaultAskBioTitle => 'Aktifkan Buka Kunci Biometrik?';

  @override
  String get vaultAskBioDesc =>
      'Gunakan sidik jari atau pengenalan wajah untuk membuka brankas dengan cepat dan aman.';

  @override
  String get vaultAskBioNotNow => 'Jangan Sekarang';

  @override
  String get vaultAskBioEnable => 'Aktifkan';

  @override
  String get vaultDeleteMessagesTitle => 'Hapus Pesan Brankas?';

  @override
  String get vaultDeleteMessagesDesc =>
      'Jika lupa PIN, pesan terenkripsi tidak dapat dipulihkan. Menyetel ulang PIN akan menghapus pesan brankas yang ada.';

  @override
  String get vaultDeleteMessagesCancel => 'Batal';

  @override
  String get vaultDeleteMessagesConfirm => 'Hapus Pesan & Setel Ulang PIN';

  @override
  String get vaultCustodyConfirmTitle => 'Konfirmasi Model Kustodi Brankas';

  @override
  String get vaultCustodyChooseTitle => 'Model Kustodi Kunci Brankas';

  @override
  String get vaultCustodyConfirmDesc =>
      'Harap konfirmasikan preferensi penyimpanan kunci enkripsi Anda.';

  @override
  String get vaultCustodyChooseDesc =>
      'Pilih di mana kunci enkripsi brankas Anda disimpan dan dilindungi.';

  @override
  String get vaultCustodyDontKnow =>
      'Tidak yakin? Anda dapat mengubah opsi ini kapan saja di pengaturan brankas.';

  @override
  String get vaultCustodyConfirmBtn => 'Konfirmasi & Lanjutkan';

  @override
  String get vaultCustodySaveBtn => 'Simpan & Lanjutkan';

  @override
  String get vaultCustodyMismatchError =>
      'Ketidakcocokan metadata enkripsi. Silakan coba lagi.';

  @override
  String get vaultCustodyAutoUpdateFailed =>
      'Gagal memperbarui model kustodi secara otomatis.';

  @override
  String vaultCustodyReencrypting(int done, int total) {
    return 'Mengenkripsi ulang $done dari $total… Biarkan aplikasi tetap terbuka.';
  }

  @override
  String get vaultCustodyPreparing => 'Menyiapkan enkripsi…';

  @override
  String get vaultSettingsTitle => 'Pengaturan Brankas';

  @override
  String get vaultSettingsAboutTitle => 'Tentang Brankas Terenkripsi';

  @override
  String get vaultSettingsAboutDesc =>
      'Brankas adalah ruang obrolan terisolasi dan sangat aman yang dilindungi PIN khusus untuk percakapan privat Anda.';

  @override
  String get vaultSettingsBulletMessages =>
      'Enkripsi ujung-ke-ujung (E2EE) untuk semua pesan dan berkas brankas.';

  @override
  String get vaultSettingsBulletStatuses =>
      'Obrolan terpisah yang tidak akan muncul di riwayat obrolan biasa atau notifikasi sistem.';

  @override
  String get vaultSettingsNeverKept =>
      'Kunci dekripsi tidak pernah disimpan dalam bentuk teks biasa di server.';

  @override
  String get vaultSettingsSectionPrivacy => 'Privasi & Hapus Otomatis';

  @override
  String get vaultSettingsAutoDelete => 'Hapus Otomatis Pesan Brankas';

  @override
  String get vaultSettingsKeepForever => 'Simpan Selamanya';

  @override
  String vaultSettingsDeleteAfter(String label) {
    return 'Hapus setelah $label';
  }

  @override
  String get vaultSettingsSectionPin => 'PIN & Keamanan Biometrik';

  @override
  String get vaultSettingsChangePin => 'Ubah PIN Brankas';

  @override
  String get vaultSettingsChangePinSubtitle =>
      'Perbarui kode PIN atau frasa sandi brankas Anda';

  @override
  String get vaultSettingsBioTitle => 'Buka Kunci Biometrik';

  @override
  String get vaultSettingsBioSubOn =>
      'Gunakan sidik jari atau wajah untuk membuka brankas';

  @override
  String get vaultSettingsBioSubOff => 'Buka kunci biometrik dinonaktifkan';

  @override
  String get vaultSettingsSectionDanger => 'Zona Berbahaya';

  @override
  String get vaultSettingsDeleteData => 'Hapus Data Brankas';

  @override
  String get vaultSettingsDeleteDataSubtitle =>
      'Hapus permanen semua pesan dan media terenkripsi dari perangkat ini';

  @override
  String get vaultSettingsResetVault => 'Setel Ulang Brankas Total';

  @override
  String get vaultSettingsResetVaultSubtitle =>
      'Hapus PIN brankas dan bersihkan semua isi data brankas';

  @override
  String get vaultSettingsPinChanged => 'PIN brankas berhasil diubah!';

  @override
  String get vaultSettingsBioTurnedOff => 'Buka kunci biometrik dinonaktifkan.';

  @override
  String get vaultSettingsBioTurnedOn => 'Buka kunci biometrik diaktifkan.';

  @override
  String get vaultSettingsClearDataTitle => 'Hapus Semua Data Brankas?';

  @override
  String get vaultSettingsClearDataDesc =>
      'Semua pesan dan media brankas akan dihapus secara permanen dari perangkat ini dan tidak dapat dipulihkan.';

  @override
  String get vaultSettingsClearDataCancel => 'Batal';

  @override
  String get vaultSettingsClearDataConfirm => 'Hapus Data';

  @override
  String get vaultSettingsDataDeleted => 'Data brankas telah dihapus.';

  @override
  String get vaultSettingsResetTitle => 'Setel Ulang Brankas?';

  @override
  String get vaultSettingsResetDesc =>
      'Semua konten akan dihapus secara permanen dan PIN akan disetel ulang. Anda harus mengatur brankas dari awal.';

  @override
  String get vaultSettingsResetConfirm => 'Setel Ulang & Hapus';

  @override
  String get vaultSettingsChangeDialogDesc =>
      'Masukkan PIN saat ini dan buat PIN baru.';

  @override
  String get vaultSettingsCurrentPin => 'PIN Saat Ini';

  @override
  String get vaultSettingsNewPin => 'PIN Baru';

  @override
  String get vaultSettingsConfirmNewPin => 'Konfirmasi PIN Baru';

  @override
  String get vaultSettingsEnterCurrentPin => 'Masukkan PIN saat ini';

  @override
  String get vaultSettingsNewPinMinLength =>
      'PIN baru harus minimal 4 karakter';

  @override
  String get vaultSettingsNewPinMismatch => 'Konfirmasi PIN baru tidak cocok';

  @override
  String get vaultSettingsCurrentPinIncorrect => 'PIN saat ini salah';

  @override
  String vaultSettingsReencryptingCount(int done, int total) {
    return 'Mengenkripsi ulang $done dari $total…';
  }

  @override
  String get vaultSettingsChangeBtn => 'Ubah PIN';

  @override
  String get vaultSettingsBioPinDialogTitle => 'Verifikasi PIN Brankas';

  @override
  String get vaultSettingsBioPinDialogDesc =>
      'Masukkan PIN brankas Anda untuk mengubah pengaturan biometrik.';

  @override
  String get vaultSettingsContinueBtn => 'Lanjutkan';

  @override
  String get premiumTitle => 'GupShupGo Premium';

  @override
  String get premiumSubtitleMember => 'Anda adalah Anggota Premium';

  @override
  String get premiumSubtitleUnlock =>
      'Buka privasi maksimal dan fitur eksklusif';

  @override
  String premiumActiveDaysRemaining(int days) {
    return 'Tersisa $days hari';
  }

  @override
  String get premiumFeaturesHeader => 'Semua Fitur Termasuk';

  @override
  String get premiumPlansHeader => 'Pilih Paket Anda';

  @override
  String get premiumSubscribeBtn => 'Tingkatkan Sekarang';

  @override
  String get premiumCancelAnytime =>
      'Batalkan kapan saja di toko aplikasi Anda';

  @override
  String get premiumRestoreBtn => 'Pulihkan Pembelian';

  @override
  String get premiumRestoring => 'Memulihkan pembelian…';

  @override
  String get premiumRestoredSuccess => 'Pembelian Anda berhasil dipulihkan!';

  @override
  String get premiumNoActiveSub => 'Tidak ditemukan langganan aktif.';

  @override
  String get premiumProductUnavailable =>
      'Produk langganan saat ini tidak tersedia. Silakan coba lagi nanti.';

  @override
  String get premiumFeatureMediaTitle => 'Media Kualitas Asli';

  @override
  String get premiumFeatureMediaDesc =>
      'Kirim foto dan video dalam resolusi asli tanpa kompresi apa pun';

  @override
  String get premiumFeatureMediaFree => 'Media terkompresi standar';

  @override
  String get premiumFeatureMediaPro => 'Kualitas asli penuh tanpa kompresi';

  @override
  String get premiumFeatureScreenShareTitle => 'Bagi Layar Kualitas HD';

  @override
  String get premiumFeatureScreenShareDesc =>
      'Streaming layar jernih hingga 1080p 60fps yang sangat halus';

  @override
  String get premiumFeatureScreenShareFree => 'Streaming 720p standar';

  @override
  String get premiumFeatureScreenSharePro => 'Streaming jernih 1080p 60fps';

  @override
  String get premiumFeatureThemesTitle => 'Tema & Kustomisasi Eksklusif';

  @override
  String get premiumFeatureThemesDesc =>
      'Buka semua tema gelap premium, warna aksen, dan gelembung obrolan unik';

  @override
  String get premiumFeatureThemesFree => 'Hanya tema bawaan';

  @override
  String get premiumFeatureThemesPro => 'Semua tema eksklusif tanpa batas';

  @override
  String get premiumFeatureVoiceTitle => 'Pesan Suara Ekstra Panjang';

  @override
  String get premiumFeatureVoiceDesc =>
      'Rekam dan kirim catatan suara berkualitas tinggi hingga 30 menit';

  @override
  String get premiumFeatureVoiceFree => 'Maksimal 2 menit';

  @override
  String get premiumFeatureVoicePro => 'Hingga 30 menit per pesan';

  @override
  String get premiumFeatureQualityTitle => 'Jalur Jaringan Prioritas';

  @override
  String get premiumFeatureQualityDesc =>
      'Server khusus menjamin kecepatan unggah dan unduh secepat kilat';

  @override
  String get premiumFeatureQualityFree => 'Bandwidth standar';

  @override
  String get premiumFeatureQualityPro => 'Jalur prioritas ultra cepat';

  @override
  String get premiumFeatureBondTitle => 'Lencana Ikatan Spesial';

  @override
  String get premiumFeatureBondDesc =>
      'Lencana dan animasi khusus saat mengobrol dengan teman terdekat Anda';

  @override
  String get premiumFeatureBondFree => 'Tingkat ikatan standar';

  @override
  String get premiumFeatureBondPro => 'Animasi unik & lencana ikatan spesial';

  @override
  String get premiumFeatureBadgeTitle => 'Lencana PRO Profil';

  @override
  String get premiumFeatureBadgeDesc =>
      'Lencana PRO bergengsi di samping nama Anda di mana saja';

  @override
  String get premiumFeatureBadgeFree => 'Tanpa lencana';

  @override
  String get premiumFeatureBadgePro => 'Lencana PRO emas eksklusif';

  @override
  String get premiumFeatureExportTitle => 'Ekspor Obrolan Lengkap';

  @override
  String get premiumFeatureExportDesc =>
      'Ekspor cadangan obrolan dan media ke format PDF atau ZIP dengan mudah';

  @override
  String get premiumFeatureExportFree => 'Tidak dapat mengekspor';

  @override
  String get premiumFeatureExportPro => 'Ekspor lengkap sekali ketuk';

  @override
  String get premiumFeatureAdFreeTitle => 'Pengalaman Bersih Tanpa Iklan';

  @override
  String get premiumFeatureAdFreeDesc =>
      'Nikmati aplikasi perpesanan yang benar-benar bersih tanpa jeda iklan';

  @override
  String get premiumFeatureAdFreeFree => 'Iklan dukungan aplikasi';

  @override
  String get premiumFeatureAdFreePro => '100% bebas iklan';

  @override
  String get premiumPlanMonthly => 'Bulanan';

  @override
  String get premiumPlanYearly => 'Tahunan';

  @override
  String get premiumPlanSavings => 'Hemat 40%';

  @override
  String get premiumPeriodMonth => 'per bulan';

  @override
  String get premiumPeriodYear => 'per tahun';

  @override
  String get nearbyOfflineChatTitle => 'Obrolan Lokal Tanpa Internet';

  @override
  String get nearbySearchingDevices => 'Mencari perangkat di sekitar…';

  @override
  String get nearbyTooltipStop => 'Hentikan Pencarian';

  @override
  String get nearbyTooltipStart => 'Mulai Pencarian';

  @override
  String get nearbyDevicesSection => 'Perangkat yang Ditemukan';

  @override
  String get nearbyDiscoveryOn => 'Pencarian aktif';

  @override
  String get nearbyDiscoveryOff => 'Pencarian mati';

  @override
  String get nearbyHeroTitle => 'Tetap Terhubung di Mana Saja';

  @override
  String nearbyHeroNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perangkat di sekitar',
      one: '1 perangkat di sekitar',
    );
    return '$_temp0';
  }

  @override
  String get nearbyHeroOff => 'Mode offline mati';

  @override
  String get nearbyHeroDesc =>
      'Mengobrol dengan orang di sekitar Anda menggunakan Wi-Fi & Bluetooth tanpa perlu internet.';

  @override
  String get nearbyYourNameHint => 'Nama Anda yang terlihat orang lain';

  @override
  String get nearbyEmptySearching => 'Mencari perangkat di sekitar…';

  @override
  String get nearbyEmptyOff => 'Pencarian dinonaktifkan';

  @override
  String get nearbyEmptySearchingDesc =>
      'Pastikan perangkat lain di sekitar juga membuka layar ini.';

  @override
  String get nearbyEmptyOffDesc =>
      'Ketuk tombol putar di kanan atas untuk mulai memindai perangkat sekitar.';

  @override
  String get nearbyPeerConnected => 'Terhubung';

  @override
  String get nearbyPeerConnecting => 'Menghubungkan…';

  @override
  String get nearbyPeerTapToConnect => 'Ketuk untuk menghubungkan';

  @override
  String get nearbyActionChat => 'Obrolan';

  @override
  String get nearbyActionConnecting => 'Menghubungkan…';

  @override
  String get nearbyActionConnect => 'Hubungkan';

  @override
  String get nearbyPermNeededTitle => 'Izin Diperlukan';

  @override
  String get nearbyPermNeededDesc =>
      'Pencarian offline memerlukan izin lokasi dan perangkat di sekitar via Bluetooth.';

  @override
  String get nearbyTryAgainBtn => 'Coba Lagi';

  @override
  String get nearbySettingsBtn => 'Buka Pengaturan';

  @override
  String get nearbyHelpTip =>
      'Tips: Pastikan Wi-Fi dan Bluetooth aktif di kedua perangkat.';

  @override
  String get anonLobbyTitle => 'Obrolan Acak Anonim';

  @override
  String get anonLobbyFinding => 'Mencari teman bicara untuk Anda…';

  @override
  String get anonLobbyHangTight =>
      'Harap tunggu sebentar, kami sedang mencari seseorang yang tersedia.';

  @override
  String get anonLobbyCancelBtn => 'Batalkan Pencarian';

  @override
  String get anonLobbyPrivacyNote =>
      'Identitas Anda sepenuhnya anonim. Lawan bicara tidak dapat melihat nama, nomor, atau profil Anda.';

  @override
  String get anonLobbyConnecting => 'Menghubungkan ke ruang obrolan…';

  @override
  String get anonLobbyWaitingOthers => 'Menunggu pengguna lain bergabung…';

  @override
  String anonLobbyOnlineCount(int count) {
    return '$count online sekarang';
  }

  @override
  String get anonChatNotEncrypted =>
      'Catatan: Obrolan acak tidak terenkripsi E2EE agar moderasi laporan pelanggaran dapat dilakukan.';

  @override
  String get anonChatRequestSentTooltip => 'Permintaan pertemanan terkirim';

  @override
  String get anonChatAddFriendTooltip => 'Tambah sebagai teman';

  @override
  String get anonChatNextStrangerTooltip => 'Ganti orang berikutnya';

  @override
  String get anonChatReportTooltip => 'Laporkan pengguna';

  @override
  String get anonChatSayHi =>
      'Katakan halo! Anda sekarang terhubung dengan seseorang yang anonim.';

  @override
  String get anonChatFriendsTransition =>
      'Kalian sekarang berteman! Obrolan telah dipindahkan ke daftar obrolan utama.';

  @override
  String get anonChatStrangerDisconnected =>
      'Teman bicara telah meninggalkan obrolan.';

  @override
  String get anonChatFindNextBtn => 'Cari Orang Berikutnya';

  @override
  String get anonChatFriendReqTitle => 'Permintaan Pertemanan';

  @override
  String get anonChatFriendReqDesc =>
      'Lawan bicara ingin menambahkan Anda sebagai teman dan saling mengungkap profil.';

  @override
  String get anonChatDecline => 'Tolak';

  @override
  String get anonChatAccept => 'Terima';

  @override
  String get anonChatWaitingReqTitle => 'Permintaan Terkirim';

  @override
  String get anonChatWaitingReqDesc =>
      'Menunggu lawan bicara menyetujui permintaan mengungkap identitas…';

  @override
  String get anonChatReportTitle => 'Laporkan Pengguna Anonim';

  @override
  String get anonChatReportQuestion => 'Mengapa Anda melaporkan pengguna ini?';

  @override
  String get anonChatReportReasonInappropriate =>
      'Konten tidak pantas atau eksplisit';

  @override
  String get anonChatReportReasonHarassment => 'Pelecehan atau perilaku kasar';

  @override
  String get anonChatReportReasonSpam => 'Spam atau penipuan';

  @override
  String get anonChatReportReasonThreatening => 'Ancaman atau membahayakan';

  @override
  String get anonChatReportReasonOther => 'Alasan lain';

  @override
  String get anonChatReportCancel => 'Batal';

  @override
  String get anonChatReportSubmit => 'Kirim Laporan';

  @override
  String get anonChatReportSubmitted =>
      'Laporan berhasil dikirim. Terima kasih telah menjaga keamanan komunitas.';

  @override
  String get anonChatViewOnceVideoTitle => 'Video Sekali Lihat';

  @override
  String get anonChatViewOncePhotoTitle => 'Foto Sekali Lihat';

  @override
  String get anonChatViewOnceVideoDesc =>
      'Anda hanya dapat memutar video ini sekali. Video akan dihapus setelah ditonton.';

  @override
  String get anonChatViewOncePhotoDesc =>
      'Anda hanya dapat membuka foto ini sekali. Foto akan terhapus saat ditutup.';

  @override
  String get anonChatViewOnceCancel => 'Batal';

  @override
  String get anonChatViewOnceOpen => 'Buka Sekarang';

  @override
  String get unsupportedVersionTitle => 'Pembaruan Aplikasi Diperlukan';

  @override
  String get unsupportedVersionDesc =>
      'Versi GupShupGo ini sudah tidak lagi didukung. Silakan perbarui ke versi terbaru untuk terus mengobrol dan menelepon dengan aman.';

  @override
  String get unsupportedVersionUpdateNow => 'Perbarui Sekarang';

  @override
  String get unsupportedVersionOpenPlayStore => 'Buka Toko Aplikasi';

  @override
  String publicProfileNotFound(String username) {
    return '@$username tidak ditemukan';
  }

  @override
  String get publicProfileUserNotFound => 'Pengguna tidak ditemukan';

  @override
  String get publicProfileNotFoundDesc =>
      'Nama pengguna mungkin telah diubah atau akun tersebut sudah tidak aktif.';

  @override
  String get publicProfileTitle => 'Profil Publik';

  @override
  String get publicProfileOnline => 'Online';

  @override
  String publicProfileLastSeen(String time) {
    return 'Terlihat $time';
  }

  @override
  String get publicProfileJustNow => 'baru saja';

  @override
  String publicProfileMinutesAgo(int minutes) {
    return '${minutes}m yang lalu';
  }

  @override
  String publicProfileHoursAgo(int hours) {
    return '${hours}j yang lalu';
  }

  @override
  String publicProfileDaysAgo(int days) {
    return '${days}h yang lalu';
  }

  @override
  String publicProfileJoined(String date) {
    return 'Bergabung $date';
  }

  @override
  String get publicProfileOwnLink => 'Ini adalah tautan profil publik Anda';

  @override
  String publicProfileGupPoints(int points) {
    return '$points Poin Gup';
  }

  @override
  String publicProfileLevel(int level) {
    return 'Level $level';
  }

  @override
  String get publicProfileStatPoints => 'Poin Gup';

  @override
  String get publicProfileStatBadges => 'Lencana';

  @override
  String get publicProfileStatBestBond => 'Ikatan Terbaik';

  @override
  String get publicProfileBadges => 'Lencana yang Diperoleh';

  @override
  String get qrScannerTitle => 'Pindai Kode QR';

  @override
  String get qrScannerFlashOnTooltip => 'Nyalakan Lampu';

  @override
  String get qrScannerFlashOffTooltip => 'Matikan Lampu';

  @override
  String get qrScannerPrompt =>
      'Arahkan kamera ke kode QR untuk menambah teman atau menghubungkan';

  @override
  String get qrScannerNotProfileCode =>
      'Kode QR ini bukan kode profil GupShupGo yang valid.';

  @override
  String get qrScannerCameraErrorTitle => 'Kesalahan Kamera';

  @override
  String get qrScannerCameraErrorRetry => 'Coba Lagi';

  @override
  String get qrScannerPermissionMsg =>
      'Izin kamera diperlukan untuk memindai kode QR.';

  @override
  String get qrScannerPermissionAllow => 'Izinkan Akses';

  @override
  String get qrScannerBlockedMsg =>
      'Izin kamera diblokir. Harap aktifkan di pengaturan perangkat Anda.';

  @override
  String get qrScannerBlockedSettings => 'Buka Pengaturan';

  @override
  String get screenShareIncomingTitle => 'Undangan Berbagi Layar';

  @override
  String get screenShareWantsToShare =>
      'ingin membagikan layarnya kepada Anda.';

  @override
  String get screenShareReject => 'Tolak';

  @override
  String get screenShareAccept => 'Terima';

  @override
  String get screenShareCantAccept =>
      'Tidak dapat menerima panggilan berbagi layar saat ini.';

  @override
  String screenShareDeclined(String name) {
    return '$name menolak berbagi layar';
  }

  @override
  String get screenShareNoAnswer => 'Tidak ada jawaban.';

  @override
  String get screenShareStartError =>
      'Gagal memulai berbagi layar. Silakan coba lagi.';

  @override
  String get screenShareStatusRequesting => 'Meminta izin…';

  @override
  String get screenShareStatusInitializing => 'Menginisialisasi…';

  @override
  String get screenShareStatusWaitingParticipant =>
      'Menunggu peserta bergabung…';

  @override
  String get screenShareStatusActive => 'Anda sedang membagikan layar';

  @override
  String screenShareSubWaitingAccept(String name) {
    return 'Menunggu $name menerima…';
  }

  @override
  String get screenShareSubEstablishing => 'Membangun koneksi aman…';

  @override
  String screenShareSubWaitingJoin(String name) {
    return 'Menunggu $name bergabung...';
  }

  @override
  String get screenShareSubActive =>
      'Layar Anda sedang distreamingkan kepada peserta lain';

  @override
  String get screenShareBadgeRequesting => 'Meminta';

  @override
  String get screenShareBadgeConnecting => 'Menghubungkan';

  @override
  String get screenShareSharedWith => 'Dibagikan dengan:';

  @override
  String get screenShareRequestingFrom => 'Diminta dari:';

  @override
  String get screenShareMinimizeTip =>
      'Anda dapat meminimalkan panel ini saat berbagi';

  @override
  String get screenShareStop => 'Hentikan Berbagi';

  @override
  String get screenShareCancelRequest => 'Batalkan Permintaan';

  @override
  String screenShareViewerTitle(String name) {
    return 'Layar $name';
  }

  @override
  String get screenShareViewerLive => 'Langsung';

  @override
  String get screenShareViewerMinimize => 'Minimalkan Tampilan';

  @override
  String get screenShareViewerLeave => 'Tinggalkan Sesi';

  @override
  String screenShareViewerWaitingStream(String name) {
    return 'Menunggu $name memulai streaming layar...';
  }

  @override
  String get screenShareViewerConnecting => 'Menghubungkan ke streaming…';

  @override
  String get viewOnceVideoTitle => 'Video Sekali Lihat';

  @override
  String get viewOncePhotoTitle => 'Foto Sekali Lihat';

  @override
  String get viewOnceCantOpen =>
      'Tidak dapat membuka media yang telah kedaluwarsa.';

  @override
  String get viewOnceUnavailable =>
      'Media ini tidak tersedia atau sudah pernah dibuka.';

  @override
  String get viewOnceBlockedFooter =>
      'Tangkapan layar diblokir untuk melindungi privasi.';

  @override
  String get viewOnceUnblockedFooter =>
      'Media akan terhapus secara otomatis saat Anda menutup layar ini.';
}
