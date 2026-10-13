// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonOk => 'OK';

  @override
  String get commonContinue => '続行';

  @override
  String get commonSave => '保存';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonGotIt => '了解';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLanguageTitle => '言語';

  @override
  String get settingsLanguageSubtitle => '言語を選択してください';

  @override
  String get languagePickerTitle => '言語';

  @override
  String get languageSystemDefault => 'システムのデフォルト';

  @override
  String get languageSystemDefaultSubtitle => '端末の言語設定に従います';

  @override
  String get loginContinueWithPhone => '電話番号で続行';

  @override
  String get loginContinueWithGoogle => 'Googleで続行';

  @override
  String get loginUseEmailPassword => 'メールとパスワードを使用';

  @override
  String get loginSignIn => 'ログイン';

  @override
  String get loginSignUp => '登録';

  @override
  String get loginCreateAccount => 'アカウント作成';

  @override
  String get loginForgotPassword => 'パスワードをお忘れですか？';

  @override
  String get loginOfflineChat => 'オフラインチャット';

  @override
  String get loginHintName => 'お名前';

  @override
  String get loginHintEmail => 'メールアドレス';

  @override
  String get loginHintPassword => 'パスワード';

  @override
  String get loginPasswordHelper => '英字と数字を含む8文字以上';

  @override
  String loginResetEmailSent(String email) {
    return '$email にパスワード再設定メールを送信しました';
  }

  @override
  String get loginErrorEnterEmail => 'メールアドレスを入力してください';

  @override
  String get loginErrorValidEmail => '有効なメールアドレスを入力してください';

  @override
  String get loginErrorEnterPassword => 'パスワードを入力してください';

  @override
  String get loginErrorPasswordMin6 => 'パスワードは6文字以上にする必要があります';

  @override
  String get loginErrorEnterPasswordSignup => 'パスワードを入力してください';

  @override
  String get loginErrorPasswordMin8 => 'パスワードは8文字以上にする必要があります';

  @override
  String get loginErrorPasswordLetter => 'パスワードには英字を含める必要があります';

  @override
  String get loginErrorPasswordNumber => 'パスワードには数字を含める必要があります';

  @override
  String get loginErrorEnterName => '名前を入力してください';

  @override
  String get loginErrorGoogleCancelled => 'Googleログインがキャンセルされました。';

  @override
  String get loginErrorProfileLoad => 'プロフィールを読み込めませんでした。接続を確認して再試行してください。';

  @override
  String get loginErrorGoogleFailed => 'Googleログインに失敗しました。もう一度お試しください。';

  @override
  String get loginErrorSignInFailed => 'ログインに失敗しました。もう一度お試しください。';

  @override
  String get loginErrorSignUpFailed => 'アカウント登録に失敗しました。もう一度お試しください。';

  @override
  String get loginErrorGeneric => 'エラーが発生しました。もう一度お試しください。';

  @override
  String get loginErrorResetFailed => '再設定メールの送信に失敗しました。もう一度お試しください。';

  @override
  String get loginErrorUserNotFound => 'このメールアドレスのアカウントは見つかりませんでした。新規登録してください。';

  @override
  String get loginErrorWrongPassword => 'パスワードが正しくありません。もう一度お試しください。';

  @override
  String get loginErrorEmailInUse => 'このメールアドレスのアカウントは既に存在します。ログインしてください。';

  @override
  String get loginErrorInvalidEmail => '有効なメールアドレスを入力してください。';

  @override
  String get loginErrorWeakPassword => 'パスワードが短すぎます。6文字以上使用してください。';

  @override
  String get loginErrorInvalidCredential =>
      'メールアドレスまたはパスワードが無効です。確認して再試行してください。';

  @override
  String get loginErrorTooManyRequests => '試行回数が多すぎます。しばらくしてから再試行してください。';

  @override
  String get homeNavChats => 'チャット';

  @override
  String get homeNavMoments => 'モーメント';

  @override
  String get homeNavCalls => '通話';

  @override
  String get homeNavProfile => 'プロフィール';

  @override
  String get homeTooltipOfflineChat => 'オフラインチャット — 近くの人と話す';

  @override
  String get homeTooltipSearch => '検索';

  @override
  String get homeMenuProfile => 'プロフィール';

  @override
  String get homeMenuSettings => '設定';

  @override
  String get homeMenuRateUs => '評価する';

  @override
  String get homeMenuReportIssue => '問題を報告';

  @override
  String get homeMenuWhatsNew => '新機能';

  @override
  String get homeMenuLogOut => 'ログアウト';

  @override
  String get homeEmptyChatsTitle => 'チャットはまだありません';

  @override
  String get homeEmptyChatsSubtitle => '下のボタンをタップして会話を始めましょう';

  @override
  String get homeNewChatButton => '新しいチャット';

  @override
  String get homeAiAssistantTitle => 'GupAI';

  @override
  String get homeAiAssistantSubtitle => '下書き作成、翻訳、要約など';

  @override
  String get homeStrangerMatchTitle => '誰かと話す';

  @override
  String get homeStrangerMatchSubtitle => '匿名チャット — タップしてマッチング！';

  @override
  String get homeMyMoment => '私のモーメント';

  @override
  String get homeRecentMoments => '最近のモーメント';

  @override
  String get homeEmptyMomentsTitle => 'まだ更新はありません。';

  @override
  String get homeEmptyMomentsSubtitle => 'カメラをタップして共有しましょう。';

  @override
  String get homeTapToAddMoment => 'タップして更新を追加';

  @override
  String get homeEmptyCallsTitle => '通話履歴はありません';

  @override
  String get homeEmptyCallsSubtitle => '最近の通話がここに表示されます';

  @override
  String get chatInputHint => 'メッセージ...';

  @override
  String get chatSearchHint => 'メッセージを検索...';

  @override
  String get chatStatusTyping => '入力中...';

  @override
  String get chatStatusOnline => 'オンライン';

  @override
  String get chatStatusOffline => 'オフライン';

  @override
  String chatStatusLastSeen(String time) {
    return '最終ログイン $time';
  }

  @override
  String get chatEndToEndEncrypted => 'エンドツーエンド暗号化';

  @override
  String get chatNoInternetOfflineTitle => 'インターネットなし？ 近くの端末とオフラインでチャット';

  @override
  String get chatEnableOfflineButton => '有効にする';

  @override
  String get chatSlideToCancel => 'スライドしてキャンセル';

  @override
  String get chatTooltipVoiceCall => '音声通話';

  @override
  String get chatTooltipVideoCall => 'ビデオ通話';

  @override
  String get chatMenuContactInfo => '連絡先情報';

  @override
  String get chatMenuSearch => '検索';

  @override
  String get chatMenuChatTheme => 'チャットテーマ';

  @override
  String get chatMenuExportChat => 'チャットをエクスポート';

  @override
  String get chatMenuMuteNotifications => '通知をミュート';

  @override
  String get chatMenuUnmuteNotifications => '通知ミュート解除';

  @override
  String get chatMenuBlockContact => '連絡先をブロック';

  @override
  String get chatActionReply => '返信';

  @override
  String get chatActionCopy => 'コピー';

  @override
  String get chatActionForward => '転送';

  @override
  String get chatActionTranslate => '翻訳';

  @override
  String get chatActionSummarise => '要約';

  @override
  String get chatActionAskGupAi => 'GupAIに質問';

  @override
  String get chatActionEdit => '編集';

  @override
  String get chatActionDelete => '削除';

  @override
  String get chatDeleteMessageTitle => 'メッセージを削除しますか？';

  @override
  String get chatDeleteMessageForEveryonePrompt =>
      '自分のみ削除しますか、それとも全員に対して削除しますか？';

  @override
  String chatDeleteMessageForMeOnlyPrompt(String name) {
    return '自分の端末からのみ削除されます。$nameには引き続き表示されます。';
  }

  @override
  String get chatDeleteForMe => '自分のみ削除';

  @override
  String get chatDeleteForEveryone => '全員に対して削除';

  @override
  String chatBlockContactTitle(String name) {
    return '$name をブロックしますか？';
  }

  @override
  String get chatBlockContactPrompt =>
      'ブロックされた連絡先はあなたにメッセージや通話を行えなくなります。設定 → プライバシーから解除できます。';

  @override
  String get chatBlockButton => 'ブロック';

  @override
  String get chatForwardTo => '転送先';

  @override
  String get chatNoForwardChats => '転送できる他のチャットがありません';

  @override
  String get chatCannotSendMediaBlocked => 'この連絡先にはメディアを送信できません';

  @override
  String get attachmentShareTitle => '共有';

  @override
  String get attachmentPhoto => '写真';

  @override
  String get attachmentPhotoSubtitle => 'ギャラリーから画像を選択';

  @override
  String get attachmentVideo => '動画';

  @override
  String get attachmentVideoSubtitle => 'ギャラリーから動画を選択';

  @override
  String get attachmentDocument => 'ドキュメント';

  @override
  String get attachmentDocumentSubtitle => 'PDF、Officeファイル、ZIPなど';

  @override
  String get attachmentLocation => '位置情報';

  @override
  String get attachmentLocationSubtitle => '現在地を共有';

  @override
  String get attachmentViewOnce => '1回のみ表示';

  @override
  String get attachmentViewOnceSubtitle => '開くと写真や動画が自動的に消えます';

  @override
  String get contactsTitle => '連絡先と見つける';

  @override
  String get contactsTabFriends => '友だち';

  @override
  String get contactsTabRequests => 'リクエスト';

  @override
  String get contactsTabDiscover => '見つける';

  @override
  String get contactsScanQrTooltip => 'QRコードをスキャン';

  @override
  String get contactsMyHandleTooltip => 'マイID';

  @override
  String get contactsSetUsernamePrompt =>
      'まずプロフィールで@ユーザー名を設定してください。それがQRコードで共有されます。';

  @override
  String get contactsMyQrCodeTitle => 'マイプロフィールQRコード';

  @override
  String get contactsMyQrCodeSubtitle => '友だちがこのQRコードをスキャンするとすぐにつながります';

  @override
  String get contactsCopyProfileLink => 'プロフィールリンクをコピー';

  @override
  String contactsProfileLinkCopied(String username) {
    return '@$usernameのプロフィールリンクをコピーしました！';
  }

  @override
  String get contactsScanSomeonesCode => 'QRコードを読み取る';

  @override
  String get contactsPermissionDenied => '連絡先へのアクセス権限が拒否されました。';

  @override
  String get contactsNoUsersFound => '連絡先にGupShupGoユーザーが見つかりませんでした。';

  @override
  String contactsFailedToSync(String error) {
    return '連絡先の同期に失敗しました: $error';
  }

  @override
  String contactsMatchedCount(int count) {
    return 'GupShupGo上の連絡先: $count件';
  }

  @override
  String get contactsFromDeviceContacts => '端末の連絡先から';

  @override
  String get contactsLoadFriendsError => '友だちリストを読み込めませんでした。';

  @override
  String get contactsNoFriendsTitle => '友だちがまだいません';

  @override
  String get contactsNoFriendsPrompt =>
      '「見つける」タブから@ユーザー名、電話番号、メールで検索してリクエストを送信しましょう！';

  @override
  String get contactsDiscoverPeopleButton => 'ユーザーを見つける';

  @override
  String get contactsQuickConnectHeader => 'クイック接続';

  @override
  String get contactsNoSuggestions => '現在おすすめのユーザーはいません。';

  @override
  String get contactsLoadRequestsError => 'リクエストを読み込めませんでした。';

  @override
  String contactsPendingRequestsHeader(int count) {
    return '保留中のリクエスト ($count)';
  }

  @override
  String get contactsNoPendingRequestsTitle => '保留中のリクエストはありません';

  @override
  String get contactsNoPendingRequestsSubtitle => 'リクエストが届くとここに表示されます。';

  @override
  String get contactsWantsToConnect => 'つながりを希望しています';

  @override
  String get contactsAcceptButton => '承認';

  @override
  String get contactsAcceptFailed => 'リクエストを承認できませんでした。再試行してください。';

  @override
  String contactsConnectedWith(String name) {
    return '$nameと友だちになりました！';
  }

  @override
  String get contactsDeclineFailed => 'リクエストを拒否できませんでした。再試行してください。';

  @override
  String get contactsYouMightKnowHeader => '知り合いかも';

  @override
  String get contactsSeeAll => 'すべて見る';

  @override
  String get contactsSearchHint => '名前、@ユーザー名、電話、メールで検索...';

  @override
  String get contactsTurnOnDiscoverability => '検索やおすすめに表示されるように検索公開をオンにしてください。';

  @override
  String get contactsNoMatchingUsersTitle => '一致するユーザーが見つかりません';

  @override
  String get contactsNoMatchingUsersSubtitle =>
      '@ユーザー名、電話番号、メールを確認して再試行してください。';

  @override
  String get contactsDiscoverHeroTitle => 'GupShupGoで仲間を見つけよう';

  @override
  String get contactsDiscoverHeroSubtitle => '世界中のユーザーと高品質なつながりを広げましょう。';

  @override
  String get contactsSyncDeviceContacts => '端末の連絡先を同期';

  @override
  String get contactsSyncingContacts => '連絡先を同期中...';

  @override
  String get contactsSyncDeviceSubtitle => 'アドレス帳から友だちをすぐに見つけます';

  @override
  String get contactsSuggestedUsersHeader => 'おすすめのユーザー';

  @override
  String get contactsAddFriendButton => '友だち追加';

  @override
  String get contactsRequestedButton => '申請中';

  @override
  String contactsRequestSent(String name) {
    return '$nameに友だち申請を送信しました！';
  }

  @override
  String get contactsRequestFailed => 'すでに申請中か、送信に失敗しました。';

  @override
  String get contactsRequestUnavailable => 'このリクエストは利用できなくなりました。';

  @override
  String get profileEditTitle => 'プロフィールを編集';

  @override
  String get profileSaveButton => '保存';

  @override
  String get profileTapToChangePhoto => 'タップして写真を変更';

  @override
  String get profileUpgradeToPro => 'Proにアップグレード';

  @override
  String get profileSectionName => '名前';

  @override
  String get profileNameHint => '名前を入力';

  @override
  String get profileSectionHandle => 'ユーザー名';

  @override
  String get profileHandleNotSet => '未設定';

  @override
  String get profileChangeHandle => '変更';

  @override
  String get profileSectionAbout => 'ステータスメッセージ';

  @override
  String get profileAboutHint => 'いまどうしてる？';

  @override
  String get profileDefaultAbout => 'こんにちは！GupShupGoを使っています。';

  @override
  String get profileSectionPhone => '電話番号';

  @override
  String get profileSectionEmail => 'メールアドレス';

  @override
  String get profileSectionLinkedMethods => '連携済みログイン方法';

  @override
  String get profileNotLinked => '未連携';

  @override
  String get profileNameEmpty => '名前を入力してください。';

  @override
  String get profileUpdatedSuccess => 'プロフィールを更新しました';

  @override
  String profileUploadPhotoFailed(String error) {
    return '写真のアップロードに失敗しました: $error';
  }

  @override
  String profileSaveFailed(String error) {
    return 'プロフィールの保存に失敗しました: $error';
  }

  @override
  String get profilePoints => 'ポイント';

  @override
  String get profileBadges => 'バッジ';

  @override
  String get profileBestBond => 'ベスト絆';

  @override
  String get settingsAccountCard => 'アカウント';

  @override
  String get settingsProfileTile => 'プロフィール';

  @override
  String get settingsLinkedMethodsTile => '連携済みログイン方法';

  @override
  String get settingsPhoneTile => '電話番号';

  @override
  String get settingsEmailTile => 'メールアドレス';

  @override
  String get settingsPrivacyCard => 'プライバシー';

  @override
  String get settingsDiscoverability => '検索での公開';

  @override
  String get settingsLastSeen => '最終ログイン';

  @override
  String get settingsReadReceipts => '既読確認';

  @override
  String get settingsAdPreferences => '広告の設定';

  @override
  String get settingsManage => '管理';

  @override
  String get settingsAppearanceCard => '外観';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsThemeSystem => 'システム設定に従う';

  @override
  String get settingsChatTheme => 'チャットテーマ';

  @override
  String get settingsHelpSecurityCard => 'ヘルプとセキュリティ';

  @override
  String get settingsHelpCenter => 'ヘルプセンター';

  @override
  String get settingsReportProblem => '問題を報告';

  @override
  String get settingsE2EEShield => 'エンドツーエンド暗号化（Vault）';

  @override
  String get settingsVerifySafetyNumber => '安全番号を確認';

  @override
  String get settingsBlockedContacts => 'ブロック中の連絡先';

  @override
  String get settingsClearAllGupHistory => 'チャット履歴を全消去';

  @override
  String get settingsRateUs => 'アプリを評価';

  @override
  String get settingsWhatsNew => '新着情報';

  @override
  String get settingsCheckForUpdates => 'アップデートを確認';

  @override
  String get settingsAppInfo => 'アプリ情報';

  @override
  String get settingsLogOut => 'ログアウト';

  @override
  String get settingsLogOutConfirmTitle => 'ログアウト';

  @override
  String get settingsLogOutConfirmPrompt => 'GupShupGoからログアウトしてもよろしいですか？';

  @override
  String get settingsSigningOut => 'ログアウト中…';

  @override
  String get settingsClearChatsConfirmTitle => 'すべてのチャットを消去';

  @override
  String get settingsClearChatsConfirmPrompt =>
      'これによりメッセージ履歴が完全に削除されます。この操作は元に戻せません。';

  @override
  String get settingsDeleteAll => 'すべて削除';

  @override
  String get settingsClearingChats => 'チャットを消去中...';

  @override
  String get settingsAllChatsCleared => 'すべてのチャットが消去されました';

  @override
  String settingsClearChatsFailed(String error) {
    return 'チャットの消去に失敗しました: $error';
  }

  @override
  String get settingsChooseThemeTitle => 'テーマを選択';

  @override
  String get settingsUnlockPremiumFeatures => 'プレミアム機能をアンロック';

  @override
  String settingsProDaysLeft(String planLabel, int daysRemaining) {
    return '$planLabel · 残り$daysRemaining日';
  }

  @override
  String get settingsCheckingForUpdates => 'アップデートを確認中…';

  @override
  String settingsUpToDate(String version) {
    return '最新バージョンです (v$version)。';
  }

  @override
  String get settingsUpdateCheckUnavailable =>
      'アップデートを確認できませんでした。Google Playストアからインストールされているか確認してください。';

  @override
  String get settingsNoBlockedContacts => 'ブロック中の連絡先はありません';

  @override
  String get settingsUnblock => 'ブロック解除';

  @override
  String settingsUserUnblocked(String name) {
    return '$nameのブロックを解除しました';
  }

  @override
  String get settingsVerifyContactTitle => '連絡先を確認';

  @override
  String get settingsVerifyContactSubtitle => '連絡先を選択して共有安全番号を表示します。';

  @override
  String get settingsComputingSafetyNumber => '安全番号を計算中…';

  @override
  String settingsSafetyNumberExplanation(String name) {
    return 'この番号が$nameの端末と一致していれば暗号化が検証されます。';
  }

  @override
  String get settingsSafetyNumberNoBundle => 'このユーザーはまだ暗号化キーを登録していません。';

  @override
  String get settingsSafetyNumberCompareHint => '対面または安全な通話でこの番号を照合してください。';

  @override
  String get callEndToEndEncrypted => 'エンドツーエンド暗号化';

  @override
  String get callSecuring => '通話を保護中…';

  @override
  String get callNotEncrypted => '暗号化されていません';

  @override
  String get callIncomingVoice => '音声着信';

  @override
  String get callIncomingVideo => 'ビデオ着信';

  @override
  String get callVoiceCall => '音声通話';

  @override
  String get callVideoCall => 'ビデオ通話';

  @override
  String get callDecline => '拒否';

  @override
  String get callAccept => '応答';

  @override
  String get callConnecting => '接続中...';

  @override
  String get callSettingUp => '通話を準備中...';

  @override
  String callNotifying(String name) {
    return '$nameに通知中...';
  }

  @override
  String get callRinging => '呼び出し中...';

  @override
  String get callConnected => '接続完了';

  @override
  String get callOnHold => '保留中';

  @override
  String get callCalling => '発信中...';

  @override
  String get callWaitingForUser => '相手を待機中...';

  @override
  String get callEnded => '通話終了';

  @override
  String get callDeclined => '通話が拒否されました';

  @override
  String get callNoAnswer => '応答なし';

  @override
  String get callFailedToConnect => '接続に失敗しました';

  @override
  String callFailedToStart(String error) {
    return '通話の開始に失敗しました: $error';
  }

  @override
  String get callTokenExpired => 'トークンが無効または期限切れです。通話をやり直してください。';

  @override
  String callFailedToInit(String type, String error) {
    return '$type通話の初期化に失敗しました: $error';
  }

  @override
  String get callTurnOffSpeaker => 'スピーカーをオフ';

  @override
  String get callTurnOnSpeaker => 'スピーカーをオン';

  @override
  String get callMuteMic => 'マイクをミュート';

  @override
  String get callUnmuteMic => 'ミュート解除';

  @override
  String get callEndCall => '通話終了';

  @override
  String get callSwitchCamera => 'カメラ切り替え';

  @override
  String get callTurnOffCamera => 'カメラをオフ';

  @override
  String get callTurnOnCamera => 'カメラをオン';

  @override
  String statusViewedByCount(int count) {
    return '$count人が閲覧';
  }

  @override
  String get statusNoViewsYet => 'まだ閲覧がありません';

  @override
  String statusViewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count回の閲覧',
    );
    return '$_temp0';
  }

  @override
  String get statusDeleteTitle => 'ステータスを削除';

  @override
  String get statusDeleteConfirm => 'このステータスを削除してもよろしいですか？';

  @override
  String get statusDeleteButton => '削除';

  @override
  String get statusReplySent => '返信を送信しました';

  @override
  String statusReplyFailed(String error) {
    return '返信の送信に失敗しました: $error';
  }

  @override
  String get statusNoActive => 'アクティブなステータスはありません';

  @override
  String get statusCouldNotLoad => '更新を読み込めませんでした';

  @override
  String get statusTapToRetry => 'タップして再試行';

  @override
  String get statusFailedToLoadImage => '画像の読み込みに失敗しました';

  @override
  String get statusLoadingVideo => '動画を読み込み中...';

  @override
  String get statusEnterTextPrompt => 'テキストを入力してください';

  @override
  String get statusNoContactsNotice => '連絡先がまだありません。投稿する前にチャットを開始してください。';

  @override
  String statusPostFailed(String error) {
    return 'ステータスの投稿に失敗しました: $error';
  }

  @override
  String get statusTypeHint => 'ステータスを入力...';

  @override
  String get statusCamera => 'カメラ';

  @override
  String get statusTakePhoto => '写真を撮影';

  @override
  String get statusGalleryPhoto => 'ギャラリーの写真';

  @override
  String get statusChooseImageGallery => 'ギャラリーから写真を選択';

  @override
  String get statusRecordVideo => '動画を録画';

  @override
  String get statusRecordShortVideo => '短い動画を録画';

  @override
  String get statusGalleryVideo => 'ギャラリーの動画';

  @override
  String get statusChooseVideoGallery => 'ギャラリーから動画を選択';

  @override
  String statusFailedPickImage(String error) {
    return '写真の選択に失敗しました: $error';
  }

  @override
  String statusFailedPickVideo(String error) {
    return '動画の選択に失敗しました: $error';
  }

  @override
  String get statusChangeBgColorTooltip => '背景色を変更';

  @override
  String aiMessagesRemaining(int count) {
    return '残り$count';
  }

  @override
  String get aiQuotaDialogTitle => 'GupAIメッセージ';

  @override
  String aiQuotaRemainingOfTotal(int remaining, int total) {
    return '本日の残り: $remaining / $total';
  }

  @override
  String aiQuotaUsedResetNote(int used) {
    return '本日$used使用 · 明日リセットされます。広告を見るかProにアップグレードしてください。';
  }

  @override
  String get aiQuotaGotIt => '了解';

  @override
  String get aiTitle => 'GupAI';

  @override
  String get aiSubtitle => 'アプリ内アシスタント';

  @override
  String get aiEmptyHelpTitle => '何かお手伝いできますか？';

  @override
  String get aiEmptyHelpSubtitle => '返信の作成、翻訳、要約、質問などを行えます。';

  @override
  String get meshOfflineChatConnected => 'オフラインチャット · 接続中';

  @override
  String get meshConnecting => '接続中…';

  @override
  String get meshBannerNotice => 'オフラインチャット — インターネット・サーバー不要';

  @override
  String meshSayHiTo(String name) {
    return '$nameにあいさつする';
  }

  @override
  String meshOfflineDescription(String name) {
    return 'オフラインチャット中です。メッセージはあなたと$nameの間でのみ保持されます。';
  }

  @override
  String get meshMediaUnavailable => 'このメディアは利用できなくなりました。';

  @override
  String get meshViewOnceTitle => '1回のみ表示';

  @override
  String meshViewOncePrompt(String type) {
    return 'この$typeは1回しか開けません。';
  }

  @override
  String get arcadeTabOverview => '概要';

  @override
  String get arcadeTabChallenges => 'チャレンジ';

  @override
  String get arcadeTabLeaderboard => 'リーダーボード';

  @override
  String get arcadeFailedLoadStats => '統計を読み込めませんでした。';

  @override
  String get aiAskHint => 'GupAIに何でも質問してください…';
}
