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
  String get homeNavChats => 'メッセージ';

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
  String get attachmentScreenShare => '画面共有';

  @override
  String get attachmentScreenShareSubtitle => 'チャット中に画面をリアルタイムで共有';

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

  @override
  String get settingsNotificationsTile => '通知';

  @override
  String get settingsNotificationsStatusOn => 'オン';

  @override
  String get settingsNotificationsStatusOff => 'オフ';

  @override
  String get settingsNotificationsEnabledToast => '通知はオンです。';

  @override
  String get settingsEnableNotificationsTitle => '通知を有効にする';

  @override
  String get settingsEnableNotificationsBody =>
      '通知が無効になっています。新しいメッセージや着信をGupShupGoから通知できるようにシステム設定を開いてください。';

  @override
  String get settingsOpenSystemSettings => '設定を開く';

  @override
  String get loginTagline => 'インターネットがなくても使えるプライベートメッセージ。';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsTerms => '利用規約';

  @override
  String get settingsDeleteAccount => 'アカウントを削除';

  @override
  String get inviteSheetTitle => '友達を招待';

  @override
  String get inviteSheetSubtitle => 'みんなに教えよう — GupShupGoをシェア';

  @override
  String get inviteShareImageBtn => '画像を共有';

  @override
  String get inviteShareLinkBtn => 'リンクを共有';

  @override
  String get inviteCopyLinkBtn => 'リンクをコピー';

  @override
  String get inviteLinkCopied => '招待リンクをコピーしました';

  @override
  String inviteMessage(String link) {
    return 'GupShupGoでチャットしよう — インターネットがなくても使えます 👋 $link';
  }

  @override
  String get inviteCardTagline => 'オフラインでも使えるプライベートチャット';

  @override
  String get inviteCardScan => 'スキャンしてダウンロード';

  @override
  String get inviteCardDownload => 'Google Playでダウンロード';

  @override
  String get homeMenuInvite => '友達を招待';

  @override
  String get invitePromptTitle => 'GupShupGoを楽しんでいますか？';

  @override
  String get invitePromptBody => '友達と一緒ならもっと便利 — オフラインでも使えます。招待してみませんか？';

  @override
  String get invitePromptInvite => '友達を招待';

  @override
  String get invitePromptLater => 'あとで';

  @override
  String get homeOfflineBannerTitle => 'ネットがつながらない？ 問題ありません';

  @override
  String get homeOfflineBannerSubtitle => 'Bluetoothを使って近くの人にメッセージを送ることができます。';

  @override
  String homeNearbyBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '近くに$count人',
      one: '近くに1人',
    );
    return '$_temp0';
  }

  @override
  String get homeNearbyBannerSubtitle => 'Bluetoothでチャット — インターネット不要。';

  @override
  String get linkBackupTitle => '予備のログイン方法を追加';

  @override
  String get linkBackupSubtitle =>
      'SIMカードが利用できない場合でも、Googleやメールを連携しておけば\n簡単に再ログインできます。';

  @override
  String get linkGoogleTitle => 'Googleアカウントを連携';

  @override
  String get linkGoogleSubtitleLinked => '連携済み ✓';

  @override
  String get linkGoogleSubtitleUnlinked => 'SIM不要のワンタップログイン';

  @override
  String get linkGoogleAction => '連携する';

  @override
  String get linkGoogleSuccess => 'Googleアカウントが正常に連携されました！';

  @override
  String get linkGoogleAlreadyUsed =>
      'このGoogleアカウントはすでに別のGupShupGoアカウントに登録されています。統合するには、一度ログアウトしてGoogleでサインインし、設定から電話番号を連携してください。';

  @override
  String get linkGoogleFailed => 'Googleの連携に失敗しました。もう一度お試しください。';

  @override
  String get linkSessionExpired => 'セッションの有効期限が切れました。再度ログインしてください。';

  @override
  String get linkEmailTitle => 'メールアドレスとパスワードを連携';

  @override
  String get linkEmailSubtitleLinked => '連携済み ✓';

  @override
  String get linkEmailSubtitleUnlinked => 'SIMやGoogleがない場合でもメールでログイン';

  @override
  String get linkEmailActionAdd => '追加';

  @override
  String get linkEmailActionCancel => 'キャンセル';

  @override
  String get linkEmailFieldLabel => 'メールアドレス';

  @override
  String get linkPasswordFieldLabel => 'パスワードを作成';

  @override
  String get linkPasswordHelper => '6文字以上';

  @override
  String get linkEmailButton => 'メールを連携';

  @override
  String get linkEmailSuccess => 'メールアドレスが正常に連携されました！';

  @override
  String get linkEmailInvalid => '有効なメールアドレスを入力してください。';

  @override
  String get linkPasswordTooShort => 'パスワードは6文字以上である必要があります。';

  @override
  String get linkEmailAlreadyInUse =>
      'このメールアドレスは既にGupShupGoに登録されています。まずメールでログインし、設定から電話番号を連携してください。';

  @override
  String get linkEmailAlreadyLinked => 'すでにメールアドレスがアカウントに連携されています。';

  @override
  String get linkEmailFailed => 'メールの連携に失敗しました。もう一度お試しください。';

  @override
  String get linkContinueToApp => 'アプリへ進む';

  @override
  String get linkSkipForNow => '今はスキップ';

  @override
  String get linkSkip => 'スキップ';

  @override
  String get phoneAuthTitleEntry => '電話番号でログインします。';

  @override
  String get phoneAuthTitleOtp => '送信された確認コードを入力してください。';

  @override
  String get phoneAuthNameHint => 'お名前';

  @override
  String get phoneAuthPhoneHint => '電話番号';

  @override
  String get phoneAuthUseSim => 'SIMを使用';

  @override
  String get phoneAuthSendOtp => '認証コードを送信';

  @override
  String phoneAuthOtpPrompt(String phone) {
    return '$phone に送信された6桁のコードを入力';
  }

  @override
  String get phoneAuthOtpPromptGeneric => '送信された6桁のコードを入力してください';

  @override
  String get phoneAuthOtpHint => 'コードを入力';

  @override
  String get phoneAuthVerify => '認証する';

  @override
  String get phoneAuthGoBack => '戻る';

  @override
  String get phoneAuthResendCode => 'コードを再送';

  @override
  String get phoneAuthEnterName => 'お名前を入力してください';

  @override
  String get phoneAuthEnterValidPhone => '有効な電話番号を入力してください';

  @override
  String get phoneAuthEnterCode => 'コードを入力してください';

  @override
  String get phoneAuthRequestNewCode => '新しいコードをリクエストしてください。';

  @override
  String get phoneAuthCodeIncorrect => 'コードが正しくありません。もう一度お試しください。';

  @override
  String get phoneAuthErrCodeIncorrect => '認証コードが違います。再試行してください。';

  @override
  String get phoneAuthErrCodeExpired => 'コードの有効期限が切れました。再取得してください。';

  @override
  String get phoneAuthErrTooManyRequests => 'リクエストが多すぎます。1分ほど待ってから再試行してください。';

  @override
  String get phoneAuthErrInvalidPhone => '無効な電話番号です。';

  @override
  String get phoneAuthErrQuotaExceeded => 'SMS送信の上限に達しました。しばらくしてからお試しください。';

  @override
  String get phoneAuthErrFailed => 'コードの送信に失敗しました。再試行してください。';

  @override
  String get usernameSetupAppBarTitle => 'ユーザー名設定';

  @override
  String get usernameSetupHeaderTitle => 'ユーザー名を選択';

  @override
  String get usernameSetupHeaderDesc =>
      '友達がGupShupGoであなたを見つけられるように、固有のIDを設定しましょう。';

  @override
  String get usernameSetupInputHint => 'username';

  @override
  String get usernameSetupChecking => '利用可能か確認中…';

  @override
  String usernameSetupAvailable(String handle) {
    return '@$handle は利用可能です！';
  }

  @override
  String usernameSetupTaken(String handle) {
    return '@$handle は既に使用されています。';
  }

  @override
  String get usernameSetupCharRules => '使用可能文字: a-z、0-9、アンダースコア(_)、ドット(.)';

  @override
  String get usernameSetupTooShort => 'ユーザー名は3文字以上必要です';

  @override
  String get usernameSetupTooLong => 'ユーザー名は最大20文字までです';

  @override
  String get usernameSetupInvalidChars => '小文字、数字、_、. のみ使用できます';

  @override
  String get usernameSetupRecommended => 'おすすめ:';

  @override
  String get usernameSetupSaveBtn => 'ユーザー名を保存';

  @override
  String get usernameSetupSkipBtn => '今はスキップ';

  @override
  String usernameSetupFailed(String error) {
    return 'ユーザー名の設定に失敗しました: $error';
  }

  @override
  String get vaultProtectTitle => '秘密のチャットを保護';

  @override
  String get vaultUnlockTitle => '暗号化ボールトを解除';

  @override
  String get vaultSetupDesc => 'ボールトチャットを暗号化するためのPINまたはパスフレーズを設定します。';

  @override
  String get vaultUnlockDescBio => '生体認証を使用するか、PINを入力してアクセスします。';

  @override
  String get vaultUnlockDescPin => 'メッセージを復号化するためにボールトPINを入力してください。';

  @override
  String get vaultReinstallHint => '再インストールしましたか？以前作成したPINを入力してください。';

  @override
  String get vaultUnlockWithFingerprint => '指紋認証で解除';

  @override
  String get vaultOrDivider => 'または';

  @override
  String get vaultNewPin => '新しいボールトPIN';

  @override
  String get vaultConfirmPin => '新しいPINの確認';

  @override
  String get vaultEnterPin => 'ボールトPINを入力';

  @override
  String get vaultKeyboardUseLetters => '文字キーボード（パスフレーズ）';

  @override
  String get vaultKeyboardUseNumbers => '数字キーパッド（PIN）';

  @override
  String get vaultRestoreLater => '後で復元';

  @override
  String get vaultForgotPin => 'PINをお忘れですか？';

  @override
  String get vaultSetPinBtn => 'PINを設定して暗号化';

  @override
  String get vaultDecryptBtn => '復号化してロック解除';

  @override
  String get vaultPinMinLength => 'PINは4文字以上である必要があります';

  @override
  String get vaultPinsDoNotMatch => 'PINが一致しません';

  @override
  String get vaultSetupFailed => 'ボールトの設定に失敗しました。もう一度お試しください。';

  @override
  String get vaultIncorrectPin => 'PINが正しくありません';

  @override
  String get vaultFingerprintOutOfDate => '指紋情報が更新されました。PINを使用してください。';

  @override
  String get vaultBiometricError => '生体認証が利用できません';

  @override
  String get vaultBioReasonUnlock => 'ボールトチャットをロック解除するために認証してください';

  @override
  String get vaultBioReasonEnrol => '生体認証アクセスを有効にするために認証してください';

  @override
  String get vaultAskBioTitle => '生体認証ロック解除を有効にしますか？';

  @override
  String get vaultAskBioDesc => '指紋や顔認証を使用して、ボールトを迅速かつ安全にロック解除します。';

  @override
  String get vaultAskBioNotNow => '後で';

  @override
  String get vaultAskBioEnable => '有効にする';

  @override
  String get vaultDeleteMessagesTitle => 'ボールトメッセージを削除しますか？';

  @override
  String get vaultDeleteMessagesDesc =>
      'PINをお忘れの場合、暗号化されたメッセージを復元することはできません。新しいPINを設定するには、現在のボールトメッセージを消去する必要があります。';

  @override
  String get vaultDeleteMessagesCancel => 'キャンセル';

  @override
  String get vaultDeleteMessagesConfirm => 'メッセージを削除してPINをリセット';

  @override
  String get vaultCustodyConfirmTitle => 'ボールト管理モデルの確認';

  @override
  String get vaultCustodyChooseTitle => 'ボールトキー管理モデル';

  @override
  String get vaultCustodyConfirmDesc => '暗号化キーの保存方法の設定を確認してください。';

  @override
  String get vaultCustodyChooseDesc => 'ボールト暗号化キーをどこに保存し保護するかを選択します。';

  @override
  String get vaultCustodyDontKnow => '不明な場合は、後からボールト設定でいつでも変更できます。';

  @override
  String get vaultCustodyConfirmBtn => '確認して続行';

  @override
  String get vaultCustodySaveBtn => '保存して続行';

  @override
  String get vaultCustodyMismatchError => 'メタデータの不一致が発生しました。もう一度お試しください。';

  @override
  String get vaultCustodyAutoUpdateFailed => '管理モデルの自動更新に失敗しました。';

  @override
  String vaultCustodyReencrypting(int done, int total) {
    return '$total 件中 $done 件を再暗号化中… アプリを開いたままにしてください。';
  }

  @override
  String get vaultCustodyPreparing => '暗号化を準備中…';

  @override
  String get vaultSettingsTitle => 'ボールト設定';

  @override
  String get vaultSettingsAboutTitle => '暗号化ボールトについて';

  @override
  String get vaultSettingsAboutDesc =>
      'ボールトは専用のPINで保護された、機密性の高いチャットのためのプライベート空間です。';

  @override
  String get vaultSettingsBulletMessages =>
      'ボールト内のすべてのメッセージとメディアをエンドツーエンドで暗号化。';

  @override
  String get vaultSettingsBulletStatuses => 'システム通知や通常の履歴に表示されない完全隔離チャット。';

  @override
  String get vaultSettingsNeverKept => '復号キーがプレーンテキストでサーバーに保存されることは一切ありません。';

  @override
  String get vaultSettingsSectionPrivacy => 'プライバシーと自動消去';

  @override
  String get vaultSettingsAutoDelete => 'ボールトメッセージの自動消去';

  @override
  String get vaultSettingsKeepForever => '無期限に保持';

  @override
  String vaultSettingsDeleteAfter(String label) {
    return '$label 後に消去';
  }

  @override
  String get vaultSettingsSectionPin => 'PINと生体認証';

  @override
  String get vaultSettingsChangePin => 'ボールトPINを変更';

  @override
  String get vaultSettingsChangePinSubtitle => 'PINコードまたはパスフレーズを更新します';

  @override
  String get vaultSettingsBioTitle => '生体認証ロック解除';

  @override
  String get vaultSettingsBioSubOn => '指紋や顔認証でボールトを解除';

  @override
  String get vaultSettingsBioSubOff => '生体認証は無効です';

  @override
  String get vaultSettingsSectionDanger => '危険エリア';

  @override
  String get vaultSettingsDeleteData => 'ボールトデータを消去';

  @override
  String get vaultSettingsDeleteDataSubtitle =>
      'この端末からすべての暗号化メッセージとメディアを完全に削除します';

  @override
  String get vaultSettingsResetVault => 'ボールトを完全リセット';

  @override
  String get vaultSettingsResetVaultSubtitle => 'ボールトPINを削除し、すべてのボールトデータを消去します';

  @override
  String get vaultSettingsPinChanged => 'ボールトPINが変更されました！';

  @override
  String get vaultSettingsBioTurnedOff => '生体認証ロック解除を無効にしました。';

  @override
  String get vaultSettingsBioTurnedOn => '生体認証ロック解除を有効にしました。';

  @override
  String get vaultSettingsClearDataTitle => 'すべてのボールトデータを消去しますか？';

  @override
  String get vaultSettingsClearDataDesc =>
      'この端末からボールト内のすべてのメッセージとメディアが完全に削除され、復元できなくなります。';

  @override
  String get vaultSettingsClearDataCancel => 'キャンセル';

  @override
  String get vaultSettingsClearDataConfirm => 'データを消去';

  @override
  String get vaultSettingsDataDeleted => 'ボールトデータが消去されました。';

  @override
  String get vaultSettingsResetTitle => 'ボールトをリセットしますか？';

  @override
  String get vaultSettingsResetDesc =>
      'すべての内容が完全に削除され、PINがリセットされます。ボールトを一から再設定する必要があります。';

  @override
  String get vaultSettingsResetConfirm => 'リセットして消去';

  @override
  String get vaultSettingsChangeDialogDesc => '現在のPINを入力し、新しいPINを設定してください。';

  @override
  String get vaultSettingsCurrentPin => '現在のPIN';

  @override
  String get vaultSettingsNewPin => '新しいPIN';

  @override
  String get vaultSettingsConfirmNewPin => '新しいPINの確認';

  @override
  String get vaultSettingsEnterCurrentPin => '現在のPINを入力';

  @override
  String get vaultSettingsNewPinMinLength => '新しいPINは4文字以上必要です';

  @override
  String get vaultSettingsNewPinMismatch => '新しいPINが一致しません';

  @override
  String get vaultSettingsCurrentPinIncorrect => '現在のPINが正しくありません';

  @override
  String vaultSettingsReencryptingCount(int done, int total) {
    return '$total 件中 $done 件を再暗号化中…';
  }

  @override
  String get vaultSettingsChangeBtn => 'PINを変更';

  @override
  String get vaultSettingsBioPinDialogTitle => 'ボールトPINを入力';

  @override
  String get vaultSettingsBioPinDialogDesc => '生体認証設定を変更するには、ボールトPINを入力してください。';

  @override
  String get vaultSettingsContinueBtn => '続行';

  @override
  String get premiumTitle => 'GupShupGo プレミアム';

  @override
  String get premiumSubtitleMember => 'プレミアムメンバーです';

  @override
  String get premiumSubtitleUnlock => '最高のプライバシーと全機能を解放する';

  @override
  String premiumActiveDaysRemaining(int days) {
    return '残り $days 日';
  }

  @override
  String get premiumFeaturesHeader => '利用可能なすべての機能';

  @override
  String get premiumPlansHeader => 'プランを選択';

  @override
  String get premiumSubscribeBtn => '今すぐアップグレード';

  @override
  String get premiumCancelAnytime => 'いつでもアプリストアからキャンセル可能';

  @override
  String get premiumRestoreBtn => '購入を復元';

  @override
  String get premiumRestoring => '購入を復元中…';

  @override
  String get premiumRestoredSuccess => '購入が正常に復元されました！';

  @override
  String get premiumNoActiveSub => '有効なサブスクリプションが見つかりません。';

  @override
  String get premiumProductUnavailable => '現在商品をご利用いただけません。後でもう一度お試しください。';

  @override
  String get premiumFeatureMediaTitle => '無劣化オリジナル品質メディア';

  @override
  String get premiumFeatureMediaDesc => '写真や動画を圧縮せず最高のオリジナル画質のまま送信';

  @override
  String get premiumFeatureMediaFree => '標準圧縮メディア';

  @override
  String get premiumFeatureMediaPro => '最高画質（圧縮なし）';

  @override
  String get premiumFeatureScreenShareTitle => '高画質画面共有';

  @override
  String get premiumFeatureScreenShareDesc =>
      '最大1080p 60fpsの超スムーズでクリアな画面ストリーミング';

  @override
  String get premiumFeatureScreenShareFree => '標準720pストリーミング';

  @override
  String get premiumFeatureScreenSharePro => '超高精細1080p 60fps';

  @override
  String get premiumFeatureThemesTitle => '限定プレミアムテーマ';

  @override
  String get premiumFeatureThemesDesc => 'すべてのダークテーマ、アクセントカラー、吹き出しスタイルを解放';

  @override
  String get premiumFeatureThemesFree => 'デフォルトテーマのみ';

  @override
  String get premiumFeatureThemesPro => 'すべての限定テーマが無制限';

  @override
  String get premiumFeatureVoiceTitle => '長尺ボイスメッセージ';

  @override
  String get premiumFeatureVoiceDesc => '最大30分の高音質ボイスメモを録音して共有可能';

  @override
  String get premiumFeatureVoiceFree => '最長2分まで';

  @override
  String get premiumFeatureVoicePro => '最大30分まで対応';

  @override
  String get premiumFeatureQualityTitle => '最優先ネットワーク回線';

  @override
  String get premiumFeatureQualityDesc => '専用サーバーによる最速のアップロード＆ダウンロード速度';

  @override
  String get premiumFeatureQualityFree => '標準帯域幅';

  @override
  String get premiumFeatureQualityPro => '超高速プライオリティ回線';

  @override
  String get premiumFeatureBondTitle => '特別な親密関係バッジ';

  @override
  String get premiumFeatureBondDesc => '親しい友達とのチャットで特別なエフェクトやバッジを表示';

  @override
  String get premiumFeatureBondFree => '標準レベル表示';

  @override
  String get premiumFeatureBondPro => '限定アニメーション＆特別バッジ';

  @override
  String get premiumFeatureBadgeTitle => 'プロフィールPROバッジ';

  @override
  String get premiumFeatureBadgeDesc => 'お名前の横に輝くプレミアムPROバッジを表示';

  @override
  String get premiumFeatureBadgeFree => 'バッジなし';

  @override
  String get premiumFeatureBadgePro => 'ゴールドPROバッジ';

  @override
  String get premiumFeatureExportTitle => 'チャット完全エクスポート';

  @override
  String get premiumFeatureExportDesc => 'チャット履歴やメディアをPDFやZIP形式で一括バックアップ出力';

  @override
  String get premiumFeatureExportFree => 'エクスポート不可';

  @override
  String get premiumFeatureExportPro => 'ワンタップ完全エクスポート';

  @override
  String get premiumFeatureAdFreeTitle => '完全広告なしの快適体験';

  @override
  String get premiumFeatureAdFreeDesc => '広告が一切ない快適で純粋なメッセージング空間';

  @override
  String get premiumFeatureAdFreeFree => 'サポート広告あり';

  @override
  String get premiumFeatureAdFreePro => '100% 広告なし';

  @override
  String get premiumPlanMonthly => '月払い';

  @override
  String get premiumPlanYearly => '年払い';

  @override
  String get premiumPlanSavings => '40% お得';

  @override
  String get premiumPeriodMonth => '月額';

  @override
  String get premiumPeriodYear => '年額';

  @override
  String get nearbyOfflineChatTitle => 'オフライン近隣チャット';

  @override
  String get nearbySearchingDevices => '周辺の端末を検索中…';

  @override
  String get nearbyTooltipStop => '検索を停止';

  @override
  String get nearbyTooltipStart => '検索を開始';

  @override
  String get nearbyDevicesSection => '検出された端末';

  @override
  String get nearbyDiscoveryOn => '周辺検索がオン';

  @override
  String get nearbyDiscoveryOff => '周辺検索がオフ';

  @override
  String get nearbyHeroTitle => 'いつでもどこでも通信可能';

  @override
  String nearbyHeroNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '近くに $count 台の端末',
      one: '近くに 1 台の端末',
    );
    return '$_temp0';
  }

  @override
  String get nearbyHeroOff => 'オフライン検索はオフです';

  @override
  String get nearbyHeroDesc =>
      'インターネットに接続されていなくても、Wi-FiとBluetoothを使って近くの人と直接チャットできます。';

  @override
  String get nearbyYourNameHint => '相手に表示されるあなたの名前';

  @override
  String get nearbyEmptySearching => '近くの端末を探しています…';

  @override
  String get nearbyEmptyOff => '周辺検索が停止しています';

  @override
  String get nearbyEmptySearchingDesc => '近くの端末でもこの画面が開いていることを確認してください。';

  @override
  String get nearbyEmptyOffDesc => '右上の再生ボタンをタップして周辺端末のスキャンを開始します。';

  @override
  String get nearbyPeerConnected => '接続済み';

  @override
  String get nearbyPeerConnecting => '接続中…';

  @override
  String get nearbyPeerTapToConnect => 'タップして接続';

  @override
  String get nearbyActionChat => 'チャット';

  @override
  String get nearbyActionConnecting => '接続中…';

  @override
  String get nearbyActionConnect => '接続';

  @override
  String get nearbyPermNeededTitle => '権限が必要です';

  @override
  String get nearbyPermNeededDesc => 'オフライン通信には位置情報および周辺デバイスの検出権限が必要です。';

  @override
  String get nearbyTryAgainBtn => '再試行';

  @override
  String get nearbySettingsBtn => '設定を開く';

  @override
  String get nearbyHelpTip => 'ヒント: 両方の端末でWi-FiとBluetoothがオンになっていることを確認してください。';

  @override
  String get anonLobbyTitle => 'ランダム匿名チャット';

  @override
  String get anonLobbyFinding => '会話相手を探しています…';

  @override
  String get anonLobbyHangTight => '少々お待ちください。相手を見つけています。';

  @override
  String get anonLobbyCancelBtn => 'マッチングをキャンセル';

  @override
  String get anonLobbyPrivacyNote =>
      '完全匿名です。相手にあなたの名前や電話番号、プロフィールが表示されることはありません。';

  @override
  String get anonLobbyConnecting => '接続を確立中…';

  @override
  String get anonLobbyWaitingOthers => '他のユーザーの参加を待っています…';

  @override
  String anonLobbyOnlineCount(int count) {
    return '現在 $count 人がオンライン';
  }

  @override
  String get anonChatNotEncrypted =>
      '注意: 迷惑行為の通報を可能にするため、ランダムチャットはエンドツーエンド暗号化されません。';

  @override
  String get anonChatRequestSentTooltip => '友達リクエスト送信済み';

  @override
  String get anonChatAddFriendTooltip => '友達に追加';

  @override
  String get anonChatNextStrangerTooltip => '次の相手を探す';

  @override
  String get anonChatReportTooltip => '通報する';

  @override
  String get anonChatSayHi => '挨拶してみましょう！匿名ユーザーと接続されました。';

  @override
  String get anonChatFriendsTransition => '友達になりました！チャットはメインの会話リストに移動しました。';

  @override
  String get anonChatStrangerDisconnected => '相手が退出しました。';

  @override
  String get anonChatFindNextBtn => '次の相手を見つける';

  @override
  String get anonChatFriendReqTitle => '友達リクエスト';

  @override
  String get anonChatFriendReqDesc => '相手が友達追加とお互いのプロフィール公開を希望しています。';

  @override
  String get anonChatDecline => '辞退';

  @override
  String get anonChatAccept => '承認';

  @override
  String get anonChatWaitingReqTitle => 'リクエスト送信済み';

  @override
  String get anonChatWaitingReqDesc => '相手が身元公開リクエストを承認するのを待っています…';

  @override
  String get anonChatReportTitle => '匿名ユーザーを通報';

  @override
  String get anonChatReportQuestion => 'このユーザーを通報する理由は何ですか？';

  @override
  String get anonChatReportReasonInappropriate => '不適切なコンテンツや露骨な表現';

  @override
  String get anonChatReportReasonHarassment => '嫌がらせや誹謗中傷';

  @override
  String get anonChatReportReasonSpam => 'スパムまたは詐欺行為';

  @override
  String get anonChatReportReasonThreatening => '脅迫または危険な行為';

  @override
  String get anonChatReportReasonOther => 'その他の理由';

  @override
  String get anonChatReportCancel => 'キャンセル';

  @override
  String get anonChatReportSubmit => '通報を送信';

  @override
  String get anonChatReportSubmitted => '通報が送信されました。安全なコミュニティ維持にご協力ありがとうございます。';

  @override
  String get anonChatViewOnceVideoTitle => '1回限りの動画';

  @override
  String get anonChatViewOncePhotoTitle => '1回限りの写真';

  @override
  String get anonChatViewOnceVideoDesc => 'この動画は1回のみ再生できます。視聴後に消去されます。';

  @override
  String get anonChatViewOncePhotoDesc => 'この写真は1回のみ開くことができます。閉じると消去されます。';

  @override
  String get anonChatViewOnceCancel => 'キャンセル';

  @override
  String get anonChatViewOnceOpen => '開いて表示';

  @override
  String get unsupportedVersionTitle => 'アプリのアップデートが必要です';

  @override
  String get unsupportedVersionDesc =>
      '現在お使いのバージョンのGupShupGoはサポートを終了しました。安全にチャットや通話を続けるために、最新バージョンにアップデートしてください。';

  @override
  String get unsupportedVersionUpdateNow => '今すぐアップデート';

  @override
  String get unsupportedVersionOpenPlayStore => 'アプリストアを開く';

  @override
  String publicProfileNotFound(String username) {
    return '@$username は見つかりません';
  }

  @override
  String get publicProfileUserNotFound => 'ユーザーが見つかりません';

  @override
  String get publicProfileNotFoundDesc =>
      'ユーザー名が変更されたか、アカウントが利用できなくなっている可能性があります。';

  @override
  String get publicProfileTitle => 'プロフィール';

  @override
  String get publicProfileOnline => 'オンライン';

  @override
  String publicProfileLastSeen(String time) {
    return '最終ログイン: $time';
  }

  @override
  String get publicProfileJustNow => 'たった今';

  @override
  String publicProfileMinutesAgo(int minutes) {
    return '$minutes分前';
  }

  @override
  String publicProfileHoursAgo(int hours) {
    return '$hours時間前';
  }

  @override
  String publicProfileDaysAgo(int days) {
    return '$days日前';
  }

  @override
  String publicProfileJoined(String date) {
    return '登録日: $date';
  }

  @override
  String get publicProfileOwnLink => 'これはあなたの公開プロフィールです';

  @override
  String publicProfileGupPoints(int points) {
    return '$points Gupポイント';
  }

  @override
  String publicProfileLevel(int level) {
    return 'レベル $level';
  }

  @override
  String get publicProfileStatPoints => 'ポイント';

  @override
  String get publicProfileStatBadges => 'バッジ';

  @override
  String get publicProfileStatBestBond => '親密度トップ';

  @override
  String get publicProfileBadges => '獲得バッジ';

  @override
  String get qrScannerTitle => 'QRコードをスキャン';

  @override
  String get qrScannerFlashOnTooltip => 'ライトをオン';

  @override
  String get qrScannerFlashOffTooltip => 'ライトをオフ';

  @override
  String get qrScannerPrompt => 'カメラをQRコードに向けて友達追加や接続を行います';

  @override
  String get qrScannerNotProfileCode => 'このコードは有効なGupShupGoプロフィールコードではありません。';

  @override
  String get qrScannerCameraErrorTitle => 'カメラエラー';

  @override
  String get qrScannerCameraErrorRetry => '再試行';

  @override
  String get qrScannerPermissionMsg => 'QRコードをスキャンするにはカメラへのアクセス権限が必要です。';

  @override
  String get qrScannerPermissionAllow => 'アクセスを許可';

  @override
  String get qrScannerBlockedMsg => 'カメラへのアクセスが拒否されています。端末の設定から許可してください。';

  @override
  String get qrScannerBlockedSettings => '設定を開く';

  @override
  String get screenShareIncomingTitle => '画面共有のリクエスト';

  @override
  String get screenShareWantsToShare => '画面を共有しようとしています。';

  @override
  String get screenShareReject => '拒否';

  @override
  String get screenShareAccept => '承認';

  @override
  String get screenShareCantAccept => '現在画面共有を受信できません。';

  @override
  String screenShareDeclined(String name) {
    return '$name が画面共有を辞退しました';
  }

  @override
  String get screenShareNoAnswer => '応答がありませんでした。';

  @override
  String get screenShareStartError => '画面共有を開始できませんでした。もう一度お試しください。';

  @override
  String get screenShareStatusRequesting => 'リクエスト中…';

  @override
  String get screenShareStatusInitializing => '初期化中…';

  @override
  String get screenShareStatusWaitingParticipant => '参加者の接続を待機中…';

  @override
  String get screenShareStatusActive => '画面を共有しています';

  @override
  String screenShareSubWaitingAccept(String name) {
    return '$name の承認を待っています…';
  }

  @override
  String get screenShareSubEstablishing => '安全な接続を確立中…';

  @override
  String screenShareSubWaitingJoin(String name) {
    return '$name が参加するのを待っています...';
  }

  @override
  String get screenShareSubActive => 'あなたの画面が相手にリアルタイム配信されています';

  @override
  String get screenShareBadgeRequesting => 'リクエスト中';

  @override
  String get screenShareBadgeConnecting => '接続中';

  @override
  String get screenShareSharedWith => '共有先:';

  @override
  String get screenShareRequestingFrom => 'リクエスト送信元:';

  @override
  String get screenShareMinimizeTip => '共有中はこの通知バーを最小化できます';

  @override
  String get screenShareStop => '共有を停止';

  @override
  String get screenShareCancelRequest => 'リクエストをキャンセル';

  @override
  String screenShareViewerTitle(String name) {
    return '$name の画面';
  }

  @override
  String get screenShareViewerLive => 'ライブ配信';

  @override
  String get screenShareViewerMinimize => '最小化';

  @override
  String get screenShareViewerLeave => '退出する';

  @override
  String screenShareViewerWaitingStream(String name) {
    return '$name の画面配信を待機中...';
  }

  @override
  String get screenShareViewerConnecting => '配信に接続中…';

  @override
  String get viewOnceVideoTitle => '1回限定動画';

  @override
  String get viewOncePhotoTitle => '1回限定写真';

  @override
  String get viewOnceCantOpen => '期限切れのメディアは開けません。';

  @override
  String get viewOnceUnavailable => 'このメディアは利用できないか、既に閲覧期限が切れています。';

  @override
  String get viewOnceBlockedFooter => 'プライバシー保護のためスクリーンショットはブロックされています。';

  @override
  String get viewOnceUnblockedFooter => 'この画面を閉じるとメディアは完全に消去されます。';
}
