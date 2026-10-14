// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '确定';

  @override
  String get commonContinue => '继续';

  @override
  String get commonSave => '保存';

  @override
  String get commonRetry => '重试';

  @override
  String get commonClose => '关闭';

  @override
  String get commonGotIt => '知道了';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLanguageTitle => '语言';

  @override
  String get settingsLanguageSubtitle => '选择你的首选语言';

  @override
  String get languagePickerTitle => '语言';

  @override
  String get languageSystemDefault => '系统默认';

  @override
  String get languageSystemDefaultSubtitle => '跟随设备语言';

  @override
  String get loginContinueWithPhone => '使用手机号继续';

  @override
  String get loginContinueWithGoogle => '使用 Google 继续';

  @override
  String get loginUseEmailPassword => '使用邮箱和密码';

  @override
  String get loginSignIn => '登录';

  @override
  String get loginSignUp => '注册';

  @override
  String get loginCreateAccount => '创建账号';

  @override
  String get loginForgotPassword => '忘记密码？';

  @override
  String get loginOfflineChat => '离线聊天';

  @override
  String get loginHintName => '您的姓名';

  @override
  String get loginHintEmail => '邮箱';

  @override
  String get loginHintPassword => '密码';

  @override
  String get loginPasswordHelper => '至少8个字符，包含字母和数字';

  @override
  String loginResetEmailSent(String email) {
    return '密码重置邮件已发送至 $email';
  }

  @override
  String get loginErrorEnterEmail => '请输入您的邮箱';

  @override
  String get loginErrorValidEmail => '请输入有效的邮箱地址';

  @override
  String get loginErrorEnterPassword => '请输入您的密码';

  @override
  String get loginErrorPasswordMin6 => '密码长度至少为 6 个字符';

  @override
  String get loginErrorEnterPasswordSignup => '请输入密码';

  @override
  String get loginErrorPasswordMin8 => '密码长度至少为 8 个字符';

  @override
  String get loginErrorPasswordLetter => '密码必须包含字母';

  @override
  String get loginErrorPasswordNumber => '密码必须包含数字';

  @override
  String get loginErrorEnterName => '请输入您的姓名';

  @override
  String get loginErrorGoogleCancelled => 'Google 登录已取消。';

  @override
  String get loginErrorProfileLoad => '无法加载个人资料。请检查网络后重试。';

  @override
  String get loginErrorGoogleFailed => 'Google 登录失败，请重试。';

  @override
  String get loginErrorSignInFailed => '登录失败，请重试。';

  @override
  String get loginErrorSignUpFailed => '注册失败，请重试。';

  @override
  String get loginErrorGeneric => '发生错误，请重试。';

  @override
  String get loginErrorResetFailed => '发送重置邮件失败，请重试。';

  @override
  String get loginErrorUserNotFound => '未找到此邮箱对应的账号。请先注册。';

  @override
  String get loginErrorWrongPassword => '密码错误，请重试。';

  @override
  String get loginErrorEmailInUse => '此邮箱已注册账号，请直接登录。';

  @override
  String get loginErrorInvalidEmail => '请输入有效的邮箱地址。';

  @override
  String get loginErrorWeakPassword => '密码强度太弱，请使用至少 6 个字符。';

  @override
  String get loginErrorInvalidCredential => '邮箱或密码错误，请检查后重试。';

  @override
  String get loginErrorTooManyRequests => '尝试次数过多，请稍后再试。';

  @override
  String get homeNavChats => '消息';

  @override
  String get homeNavMoments => '动态';

  @override
  String get homeNavCalls => '通话';

  @override
  String get homeNavProfile => '个人资料';

  @override
  String get homeTooltipOfflineChat => '离线聊天 — 与附近的人交流';

  @override
  String get homeTooltipSearch => '搜索';

  @override
  String get homeMenuProfile => '个人资料';

  @override
  String get homeMenuSettings => '设置';

  @override
  String get homeMenuRateUs => '给我们评分';

  @override
  String get homeMenuReportIssue => '反馈问题';

  @override
  String get homeMenuWhatsNew => '新功能介绍';

  @override
  String get homeMenuLogOut => '退出登录';

  @override
  String get homeEmptyChatsTitle => '暂无聊天';

  @override
  String get homeEmptyChatsSubtitle => '点击下方按钮开始对话';

  @override
  String get homeNewChatButton => '发起新聊天';

  @override
  String get homeAiAssistantTitle => 'GupAI';

  @override
  String get homeAiAssistantSubtitle => '草稿、翻译、摘要等更多功能';

  @override
  String get homeStrangerMatchTitle => '偶遇陌生人';

  @override
  String get homeStrangerMatchSubtitle => '匿名聊天 — 点击即刻匹配！';

  @override
  String get homeMyMoment => '我的动态';

  @override
  String get homeRecentMoments => '好友动态';

  @override
  String get homeEmptyMomentsTitle => '暂无最新动态。';

  @override
  String get homeEmptyMomentsSubtitle => '点击相机分享动态。';

  @override
  String get homeTapToAddMoment => '点击添加动态';

  @override
  String get homeEmptyCallsTitle => '暂无通话记录';

  @override
  String get homeEmptyCallsSubtitle => '您最近的通话将显示在这里';

  @override
  String get chatInputHint => '输入消息...';

  @override
  String get chatSearchHint => '搜索聊天记录...';

  @override
  String get chatStatusTyping => '正在输入...';

  @override
  String get chatStatusOnline => '在线';

  @override
  String get chatStatusOffline => '离线';

  @override
  String chatStatusLastSeen(String time) {
    return '上次上线 $time';
  }

  @override
  String get chatEndToEndEncrypted => '端到端加密';

  @override
  String get chatNoInternetOfflineTitle => '无网络连接？与附近设备离线聊天';

  @override
  String get chatEnableOfflineButton => '开启';

  @override
  String get chatSlideToCancel => '滑动取消发送';

  @override
  String get chatTooltipVoiceCall => '语音通话';

  @override
  String get chatTooltipVideoCall => '视频通话';

  @override
  String get chatMenuContactInfo => '联系人信息';

  @override
  String get chatMenuSearch => '搜索';

  @override
  String get chatMenuChatTheme => '聊天主题';

  @override
  String get chatMenuExportChat => '导出聊天记录';

  @override
  String get chatMenuMuteNotifications => '消息免打扰';

  @override
  String get chatMenuUnmuteNotifications => '取消免打扰';

  @override
  String get chatMenuBlockContact => '屏蔽联系人';

  @override
  String get chatActionReply => '回复';

  @override
  String get chatActionCopy => '复制';

  @override
  String get chatActionForward => '转发';

  @override
  String get chatActionTranslate => '翻译';

  @override
  String get chatActionSummarise => '总结';

  @override
  String get chatActionAskGupAi => '向 GupAI 提问';

  @override
  String get chatActionEdit => '编辑';

  @override
  String get chatActionDelete => '删除';

  @override
  String get chatDeleteMessageTitle => '删除消息？';

  @override
  String get chatDeleteMessageForEveryonePrompt => '仅为您删除，还是为群内所有人删除？';

  @override
  String chatDeleteMessageForMeOnlyPrompt(String name) {
    return '仅在您的设备上删除。$name 仍可看到该消息。';
  }

  @override
  String get chatDeleteForMe => '仅为我删除';

  @override
  String get chatDeleteForEveryone => '为所有人删除';

  @override
  String chatBlockContactTitle(String name) {
    return '屏蔽 $name？';
  }

  @override
  String get chatBlockContactPrompt =>
      '被屏蔽的联系人无法向您发送消息或拨打电话。您可以在“设置 → 隐私”中取消屏蔽。';

  @override
  String get chatBlockButton => '屏蔽';

  @override
  String get chatForwardTo => '转发给';

  @override
  String get chatNoForwardChats => '没有可转发的其他聊天';

  @override
  String get chatCannotSendMediaBlocked => '无法向此联系人发送媒体文件';

  @override
  String get attachmentShareTitle => '分享';

  @override
  String get attachmentPhoto => '照片';

  @override
  String get attachmentPhotoSubtitle => '从相册中选择图片';

  @override
  String get attachmentVideo => '视频';

  @override
  String get attachmentVideoSubtitle => '从相册中选择视频';

  @override
  String get attachmentDocument => '文档';

  @override
  String get attachmentDocumentSubtitle => 'PDF、Office 文档、压缩包等';

  @override
  String get attachmentLocation => '位置';

  @override
  String get attachmentLocationSubtitle => '分享您的当前位置';

  @override
  String get attachmentScreenShare => '屏幕共享';

  @override
  String get attachmentScreenShareSubtitle => '在聊天期间实时展示您的屏幕';

  @override
  String get attachmentViewOnce => '阅后即焚';

  @override
  String get attachmentViewOnceSubtitle => '照片或视频打开后即被销毁';

  @override
  String get contactsTitle => '联系人与发现';

  @override
  String get contactsTabFriends => '好友';

  @override
  String get contactsTabRequests => '请求';

  @override
  String get contactsTabDiscover => '发现';

  @override
  String get contactsScanQrTooltip => '扫描二维码';

  @override
  String get contactsMyHandleTooltip => '我的用户名';

  @override
  String get contactsSetUsernamePrompt => '请先在个人资料中设置 @用户名 — 这是您的二维码所分享的内容。';

  @override
  String get contactsMyQrCodeTitle => '我的个人二维码';

  @override
  String get contactsMyQrCodeSubtitle => '好友扫描此二维码即可立即与您建立联系';

  @override
  String get contactsCopyProfileLink => '复制个人主页链接';

  @override
  String contactsProfileLinkCopied(String username) {
    return '已复制 @$username 的主页链接！';
  }

  @override
  String get contactsScanSomeonesCode => '扫描他人二维码';

  @override
  String get contactsPermissionDenied => '读取联系人权限已被拒绝。';

  @override
  String get contactsNoUsersFound => '通讯录中暂无 GupShupGo 用户。';

  @override
  String contactsFailedToSync(String error) {
    return '同步联系人失败：$error';
  }

  @override
  String contactsMatchedCount(int count) {
    return '在 GupShupGo 上的联系人：$count';
  }

  @override
  String get contactsFromDeviceContacts => '来自手机通讯录';

  @override
  String get contactsLoadFriendsError => '无法加载好友列表。';

  @override
  String get contactsNoFriendsTitle => '尚未添加好友';

  @override
  String get contactsNoFriendsPrompt => '前往“发现”标签，按 @用户名、手机或邮箱搜索并添加好友！';

  @override
  String get contactsDiscoverPeopleButton => '发现好友';

  @override
  String get contactsQuickConnectHeader => '快速连接';

  @override
  String get contactsNoSuggestions => '暂无推荐用户。';

  @override
  String get contactsLoadRequestsError => '无法加载请求。';

  @override
  String contactsPendingRequestsHeader(int count) {
    return '待处理请求 ($count)';
  }

  @override
  String get contactsNoPendingRequestsTitle => '暂无待处理请求';

  @override
  String get contactsNoPendingRequestsSubtitle => '收到好友申请时将显示在此处。';

  @override
  String get contactsWantsToConnect => '希望建立联系';

  @override
  String get contactsAcceptButton => '接受';

  @override
  String get contactsAcceptFailed => '无法接受请求，请重试。';

  @override
  String contactsConnectedWith(String name) {
    return '已与 $name 成为好友！';
  }

  @override
  String get contactsDeclineFailed => '无法拒绝请求，请重试。';

  @override
  String get contactsYouMightKnowHeader => '可能认识的人';

  @override
  String get contactsSeeAll => '查看全部';

  @override
  String get contactsSearchHint => '搜索姓名、@用户名、手机或邮箱...';

  @override
  String get contactsTurnOnDiscoverability => '开启公开可见度以便出现在搜索和推荐中。';

  @override
  String get contactsNoMatchingUsersTitle => '未找到匹配用户';

  @override
  String get contactsNoMatchingUsersSubtitle => '请检查 @用户名、手机号或邮箱后再试。';

  @override
  String get contactsDiscoverHeroTitle => '在 GupShupGo 结识新朋友';

  @override
  String get contactsDiscoverHeroSubtitle => '在世界各地拓展高品质好友圈。';

  @override
  String get contactsSyncDeviceContacts => '同步手机通讯录';

  @override
  String get contactsSyncingContacts => '正在同步联系人...';

  @override
  String get contactsSyncDeviceSubtitle => '从通讯录快速找到好友';

  @override
  String get contactsSuggestedUsersHeader => '推荐用户';

  @override
  String get contactsAddFriendButton => '添加好友';

  @override
  String get contactsRequestedButton => '已申请';

  @override
  String contactsRequestSent(String name) {
    return '已向 $name 发送好友申请！';
  }

  @override
  String get contactsRequestFailed => '好友申请已在等待中或发送失败。';

  @override
  String get contactsRequestUnavailable => '该请求已失效。';

  @override
  String get profileEditTitle => '编辑个人资料';

  @override
  String get profileSaveButton => '保存';

  @override
  String get profileTapToChangePhoto => '点击更换头像';

  @override
  String get profileUpgradeToPro => '升级至 Pro';

  @override
  String get profileSectionName => '姓名';

  @override
  String get profileNameHint => '输入您的姓名';

  @override
  String get profileSectionHandle => '唯一用户名';

  @override
  String get profileHandleNotSet => '尚未设置';

  @override
  String get profileChangeHandle => '修改';

  @override
  String get profileSectionAbout => '个性签名';

  @override
  String get profileAboutHint => '分享近况...';

  @override
  String get profileDefaultAbout => '你好！我正在使用 GupShupGo。';

  @override
  String get profileSectionPhone => '手机号';

  @override
  String get profileSectionEmail => '电子邮箱';

  @override
  String get profileSectionLinkedMethods => '已绑定的登录方式';

  @override
  String get profileNotLinked => '未绑定';

  @override
  String get profileNameEmpty => '姓名不能为空。';

  @override
  String get profileUpdatedSuccess => '资料已更新';

  @override
  String profileUploadPhotoFailed(String error) {
    return '头像上传失败：$error';
  }

  @override
  String profileSaveFailed(String error) {
    return '保存资料失败：$error';
  }

  @override
  String get profilePoints => '积分';

  @override
  String get profileBadges => '徽章';

  @override
  String get profileBestBond => '最佳连续';

  @override
  String get settingsAccountCard => '账户';

  @override
  String get settingsProfileTile => '个人资料';

  @override
  String get settingsLinkedMethodsTile => '绑定的登录方式';

  @override
  String get settingsPhoneTile => '手机号码';

  @override
  String get settingsEmailTile => '电子邮箱';

  @override
  String get settingsPrivacyCard => '隐私';

  @override
  String get settingsDiscoverability => '被搜索发现';

  @override
  String get settingsLastSeen => '最后上线时间';

  @override
  String get settingsReadReceipts => '已读回执';

  @override
  String get settingsAdPreferences => '广告偏好';

  @override
  String get settingsManage => '管理';

  @override
  String get settingsAppearanceCard => '外观';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsChatTheme => '聊天主题';

  @override
  String get settingsHelpSecurityCard => '帮助与安全';

  @override
  String get settingsHelpCenter => '帮助中心';

  @override
  String get settingsReportProblem => '反馈问题';

  @override
  String get settingsE2EEShield => '端到端加密 (保险箱)';

  @override
  String get settingsVerifySafetyNumber => '验证安全码';

  @override
  String get settingsBlockedContacts => '已屏蔽的联系人';

  @override
  String get settingsClearAllGupHistory => '清除所有聊天记录';

  @override
  String get settingsRateUs => '给我们评分';

  @override
  String get settingsWhatsNew => '新功能';

  @override
  String get settingsCheckForUpdates => '检查更新';

  @override
  String get settingsAppInfo => '应用信息';

  @override
  String get settingsLogOut => '退出登录';

  @override
  String get settingsLogOutConfirmTitle => '退出登录';

  @override
  String get settingsLogOutConfirmPrompt => '确定要退出 GupShupGo 吗？';

  @override
  String get settingsSigningOut => '正在退出…';

  @override
  String get settingsClearChatsConfirmTitle => '清除所有聊天';

  @override
  String get settingsClearChatsConfirmPrompt => '这将永久删除您的所有聊天记录，此操作不可撤销。';

  @override
  String get settingsDeleteAll => '全部删除';

  @override
  String get settingsClearingChats => '正在清理聊天...';

  @override
  String get settingsAllChatsCleared => '已清除所有聊天';

  @override
  String settingsClearChatsFailed(String error) {
    return '清除聊天记录失败：$error';
  }

  @override
  String get settingsChooseThemeTitle => '选择主题';

  @override
  String get settingsUnlockPremiumFeatures => '解锁高级功能';

  @override
  String settingsProDaysLeft(String planLabel, int daysRemaining) {
    return '$planLabel · 剩余 $daysRemaining 天';
  }

  @override
  String get settingsCheckingForUpdates => '正在检查更新…';

  @override
  String settingsUpToDate(String version) {
    return '已是最新版本 (v$version)。';
  }

  @override
  String get settingsUpdateCheckUnavailable => '无法检查更新，请确保从 Google Play 商店安装。';

  @override
  String get settingsNoBlockedContacts => '无屏蔽联系人';

  @override
  String get settingsUnblock => '解除屏蔽';

  @override
  String settingsUserUnblocked(String name) {
    return '已解除屏蔽 $name';
  }

  @override
  String get settingsVerifyContactTitle => '验证联系人';

  @override
  String get settingsVerifyContactSubtitle => '选择联系人以查看共享安全码。';

  @override
  String get settingsComputingSafetyNumber => '正在计算安全码…';

  @override
  String settingsSafetyNumberExplanation(String name) {
    return '如果以下安全码与 $name 设备上的相符，则表明加密已验证。';
  }

  @override
  String get settingsSafetyNumberNoBundle => '该联系人尚未发布加密密钥束。';

  @override
  String get settingsSafetyNumberCompareHint => '请当面或通过可信通话核对此安全码。';

  @override
  String get callEndToEndEncrypted => '端到端加密';

  @override
  String get callSecuring => '正在加密通话…';

  @override
  String get callNotEncrypted => '未加密';

  @override
  String get callIncomingVoice => '来电语音通话';

  @override
  String get callIncomingVideo => '来电视频通话';

  @override
  String get callVoiceCall => '语音通话';

  @override
  String get callVideoCall => '视频通话';

  @override
  String get callDecline => '拒绝';

  @override
  String get callAccept => '接听';

  @override
  String get callConnecting => '正在连接...';

  @override
  String get callSettingUp => '正在建立通话...';

  @override
  String callNotifying(String name) {
    return '正在呼叫 $name...';
  }

  @override
  String get callRinging => '正在响铃...';

  @override
  String get callConnected => '已连接';

  @override
  String get callOnHold => '已保持';

  @override
  String get callCalling => '正在呼叫...';

  @override
  String get callWaitingForUser => '等待对方加入...';

  @override
  String get callEnded => '通话已结束';

  @override
  String get callDeclined => '通话已拒绝';

  @override
  String get callNoAnswer => '无应答';

  @override
  String get callFailedToConnect => '连接失败';

  @override
  String callFailedToStart(String error) {
    return '发起通话失败: $error';
  }

  @override
  String get callTokenExpired => '通话令牌已失效，请重新发起通话。';

  @override
  String callFailedToInit(String type, String error) {
    return '初始化$type通话失败: $error';
  }

  @override
  String get callTurnOffSpeaker => '关闭扬声器';

  @override
  String get callTurnOnSpeaker => '打开扬声器';

  @override
  String get callMuteMic => '静音麦克风';

  @override
  String get callUnmuteMic => '取消静音';

  @override
  String get callEndCall => '挂断通话';

  @override
  String get callSwitchCamera => '翻转镜头';

  @override
  String get callTurnOffCamera => '关闭摄像头';

  @override
  String get callTurnOnCamera => '打开摄像头';

  @override
  String statusViewedByCount(int count) {
    return '$count 人已浏览';
  }

  @override
  String get statusNoViewsYet => '暂无浏览';

  @override
  String statusViewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次浏览',
    );
    return '$_temp0';
  }

  @override
  String get statusDeleteTitle => '删除动态';

  @override
  String get statusDeleteConfirm => '确定要删除这条动态吗？';

  @override
  String get statusDeleteButton => '删除';

  @override
  String get statusReplySent => '回复已发送';

  @override
  String statusReplyFailed(String error) {
    return '回复发送失败: $error';
  }

  @override
  String get statusNoActive => '暂无动态';

  @override
  String get statusCouldNotLoad => '无法加载此更新';

  @override
  String get statusTapToRetry => '点击重试';

  @override
  String get statusFailedToLoadImage => '加载图片失败';

  @override
  String get statusLoadingVideo => '正在加载视频...';

  @override
  String get statusEnterTextPrompt => '请输入文字';

  @override
  String get statusNoContactsNotice => '暂无联系人 — 发布动态前请先开始聊天。';

  @override
  String statusPostFailed(String error) {
    return '发布动态失败: $error';
  }

  @override
  String get statusTypeHint => '输入动态...';

  @override
  String get statusCamera => '相机';

  @override
  String get statusTakePhoto => '拍照';

  @override
  String get statusGalleryPhoto => '相册图片';

  @override
  String get statusChooseImageGallery => '从相册选择图片';

  @override
  String get statusRecordVideo => '录制视频';

  @override
  String get statusRecordShortVideo => '录制短视频';

  @override
  String get statusGalleryVideo => '相册视频';

  @override
  String get statusChooseVideoGallery => '从相册选择视频';

  @override
  String statusFailedPickImage(String error) {
    return '选取图片失败: $error';
  }

  @override
  String statusFailedPickVideo(String error) {
    return '选取视频失败: $error';
  }

  @override
  String get statusChangeBgColorTooltip => '更改背景颜色';

  @override
  String aiMessagesRemaining(int count) {
    return '剩余 $count';
  }

  @override
  String get aiQuotaDialogTitle => 'GupAI 消息额度';

  @override
  String aiQuotaRemainingOfTotal(int remaining, int total) {
    return '今日剩余 $remaining / $total';
  }

  @override
  String aiQuotaUsedResetNote(int used) {
    return '今日已用 $used 条 · 明日重置。观看广告或升级 Pro 获得更多。';
  }

  @override
  String get aiQuotaGotIt => '知道了';

  @override
  String get aiTitle => 'GupAI';

  @override
  String get aiSubtitle => '您的应用内置助手';

  @override
  String get aiEmptyHelpTitle => '有什么我可以帮您的？';

  @override
  String get aiEmptyHelpSubtitle => '起草回复、翻译、总结或提问。';

  @override
  String get meshOfflineChatConnected => '离线聊天 · 已连接';

  @override
  String get meshConnecting => '正在连接…';

  @override
  String get meshBannerNotice => '离线聊天 — 无需网络，无需服务器';

  @override
  String meshSayHiTo(String name) {
    return '与 $name 打个招呼';
  }

  @override
  String meshOfflineDescription(String name) {
    return '您正在离线聊天。消息仅在您和 $name 之间传输。';
  }

  @override
  String get meshMediaUnavailable => '此媒体文件已失效。';

  @override
  String get meshViewOnceTitle => '阅后即焚';

  @override
  String meshViewOncePrompt(String type) {
    return '您只能打开此$type一次。';
  }

  @override
  String get arcadeTabOverview => '总览';

  @override
  String get arcadeTabChallenges => '挑战';

  @override
  String get arcadeTabLeaderboard => '排行榜';

  @override
  String get arcadeFailedLoadStats => '加载统计数据失败。';

  @override
  String get aiAskHint => '向 GupAI 询问任何问题…';

  @override
  String get settingsNotificationsTile => '通知';

  @override
  String get settingsNotificationsStatusOn => '开启';

  @override
  String get settingsNotificationsStatusOff => '关闭';

  @override
  String get settingsNotificationsEnabledToast => '通知已开启。';

  @override
  String get settingsEnableNotificationsTitle => '启用通知';

  @override
  String get settingsEnableNotificationsBody =>
      '通知已关闭。打开系统设置以允许 GupShupGo 提醒您新消息和来电。';

  @override
  String get settingsOpenSystemSettings => '打开设置';

  @override
  String get loginTagline => '无需网络也可使用的私密通讯。';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsTerms => '服务条款';

  @override
  String get settingsDeleteAccount => '注销账号';

  @override
  String get inviteSheetTitle => '邀请好友';

  @override
  String get inviteSheetSubtitle => '分享给更多人 — 推荐 GupShupGo';

  @override
  String get inviteShareImageBtn => '分享图片';

  @override
  String get inviteShareLinkBtn => '分享链接';

  @override
  String get inviteCopyLinkBtn => '复制链接';

  @override
  String get inviteLinkCopied => '邀请链接已复制';

  @override
  String inviteMessage(String link) {
    return '在 GupShupGo 上和我聊天吧 — 无需网络也可使用 👋 $link';
  }

  @override
  String get inviteCardTagline => '离线也能使用的私密聊天';

  @override
  String get inviteCardScan => '扫码下载';

  @override
  String get inviteCardDownload => '在 Google Play 下载';

  @override
  String get homeMenuInvite => '邀请好友';

  @override
  String get invitePromptTitle => '喜欢 GupShupGo 吗？';

  @override
  String get invitePromptBody => '与朋友一起体验更佳 — 且无需网络也能使用。邀请好友加入？';

  @override
  String get invitePromptInvite => '邀请好友';

  @override
  String get invitePromptLater => '稍后再说';

  @override
  String get homeOfflineBannerTitle => '没有网络？没问题';

  @override
  String get homeOfflineBannerSubtitle => '您仍可通过蓝牙与附近的人收发消息。';

  @override
  String homeNearbyBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '附近有 $count 人',
      one: '附近有 1 人',
    );
    return '$_temp0';
  }

  @override
  String get homeNearbyBannerSubtitle => '蓝牙聊天 — 无需网络。';

  @override
  String get linkBackupTitle => '添加备用登录方式';

  @override
  String get linkBackupSubtitle => '关联 Google 或电子邮箱，即使 SIM 卡不可用\n也能轻松重新登录。';

  @override
  String get linkGoogleTitle => '关联 Google 账号';

  @override
  String get linkGoogleSubtitleLinked => '已关联 ✓';

  @override
  String get linkGoogleSubtitleUnlinked => '无需 SIM 卡即可一键登录';

  @override
  String get linkGoogleAction => '关联';

  @override
  String get linkGoogleSuccess => 'Google 账号关联成功！';

  @override
  String get linkGoogleAlreadyUsed =>
      '该 Google 账号已注册为另一个 GupShupGo 账号。如需合并，请退出并使用 Google 登录，然后在设置中关联您的手机号。';

  @override
  String get linkGoogleFailed => 'Google 关联失败，请重试。';

  @override
  String get linkSessionExpired => '登录会话已过期，请重新登录。';

  @override
  String get linkEmailTitle => '关联电子邮箱与密码';

  @override
  String get linkEmailSubtitleLinked => '已关联 ✓';

  @override
  String get linkEmailSubtitleUnlinked => '在没有 SIM 卡或 Google 时使用邮箱登录';

  @override
  String get linkEmailActionAdd => '添加';

  @override
  String get linkEmailActionCancel => '取消';

  @override
  String get linkEmailFieldLabel => '电子邮箱';

  @override
  String get linkPasswordFieldLabel => '创建密码';

  @override
  String get linkPasswordHelper => '至少 6 个字符';

  @override
  String get linkEmailButton => '关联邮箱';

  @override
  String get linkEmailSuccess => '邮箱关联成功！';

  @override
  String get linkEmailInvalid => '请输入有效的电子邮箱地址。';

  @override
  String get linkPasswordTooShort => '密码长度至少需要 6 个字符。';

  @override
  String get linkEmailAlreadyInUse => '该邮箱已在 GupShupGo 注册。请先用邮箱登录，然后在设置中关联手机号。';

  @override
  String get linkEmailAlreadyLinked => '您的账号已关联电子邮箱。';

  @override
  String get linkEmailFailed => '邮箱关联失败，请重试。';

  @override
  String get linkContinueToApp => '继续进入应用';

  @override
  String get linkSkipForNow => '暂且跳过';

  @override
  String get linkSkip => '跳过';

  @override
  String get phoneAuthTitleEntry => '使用手机号码登录。';

  @override
  String get phoneAuthTitleOtp => '输入发送给您的验证码。';

  @override
  String get phoneAuthNameHint => '您的姓名';

  @override
  String get phoneAuthPhoneHint => '手机号码';

  @override
  String get phoneAuthUseSim => '使用 SIM 卡';

  @override
  String get phoneAuthSendOtp => '发送验证码';

  @override
  String phoneAuthOtpPrompt(String phone) {
    return '输入发送至 $phone 的 6 位验证码';
  }

  @override
  String get phoneAuthOtpPromptGeneric => '输入我们发送给您的 6 位验证码';

  @override
  String get phoneAuthOtpHint => '输入验证码';

  @override
  String get phoneAuthVerify => '验证';

  @override
  String get phoneAuthGoBack => '返回';

  @override
  String get phoneAuthResendCode => '重新发送验证码';

  @override
  String get phoneAuthEnterName => '请输入您的姓名';

  @override
  String get phoneAuthEnterValidPhone => '请输入有效的手机号码';

  @override
  String get phoneAuthEnterCode => '请输入验证码';

  @override
  String get phoneAuthRequestNewCode => '请重新获取验证码。';

  @override
  String get phoneAuthCodeIncorrect => '验证码不正确，请重试。';

  @override
  String get phoneAuthErrCodeIncorrect => '验证码错误，请重试。';

  @override
  String get phoneAuthErrCodeExpired => '验证码已过期，请获取新验证码。';

  @override
  String get phoneAuthErrTooManyRequests => '请求过于频繁，请等待 1 分钟后再试。';

  @override
  String get phoneAuthErrInvalidPhone => '手机号码格式无效。';

  @override
  String get phoneAuthErrQuotaExceeded => '已超出短信发送配额，请稍后重试。';

  @override
  String get phoneAuthErrFailed => '验证码发送失败，请重试。';

  @override
  String get usernameSetupAppBarTitle => '设置用户名';

  @override
  String get usernameSetupHeaderTitle => '选择您的用户名';

  @override
  String get usernameSetupHeaderDesc => '设置一个独一无二的用户名，方便其他人在 GupShupGo 上找到您。';

  @override
  String get usernameSetupInputHint => '用户名';

  @override
  String get usernameSetupChecking => '正在检查可用性…';

  @override
  String usernameSetupAvailable(String handle) {
    return '@$handle 可用！';
  }

  @override
  String usernameSetupTaken(String handle) {
    return '@$handle 已被占用。';
  }

  @override
  String get usernameSetupCharRules => '允许字符：a-z、0-9、下划线(_)和点(.)';

  @override
  String get usernameSetupTooShort => '用户名至少需要 3 个字符';

  @override
  String get usernameSetupTooLong => '用户名最多不能超过 20 个字符';

  @override
  String get usernameSetupInvalidChars => '仅支持小写字母、数字、下划线和点';

  @override
  String get usernameSetupRecommended => '推荐：';

  @override
  String get usernameSetupSaveBtn => '保存用户名';

  @override
  String get usernameSetupSkipBtn => '暂且跳过';

  @override
  String usernameSetupFailed(String error) {
    return '设置用户名失败：$error';
  }

  @override
  String get vaultProtectTitle => '保护私密聊天';

  @override
  String get vaultUnlockTitle => '解锁私密保险库';

  @override
  String get vaultSetupDesc => '设置保险库 PIN 码或密码短语以加密您的保险库对话。';

  @override
  String get vaultUnlockDescBio => '使用生物识别或输入 PIN 码即可访问。';

  @override
  String get vaultUnlockDescPin => '输入您的保险库 PIN 码以解密私密消息。';

  @override
  String get vaultReinstallHint => '重新安装？请输入之前创建的 PIN 码。';

  @override
  String get vaultUnlockWithFingerprint => '使用指纹解锁';

  @override
  String get vaultOrDivider => '或';

  @override
  String get vaultNewPin => '设置新的保险库 PIN 码';

  @override
  String get vaultConfirmPin => '确认新的 PIN 码';

  @override
  String get vaultEnterPin => '输入保险库 PIN 码';

  @override
  String get vaultKeyboardUseLetters => '使用字母键盘（密码短语）';

  @override
  String get vaultKeyboardUseNumbers => '使用数字键盘（PIN 码）';

  @override
  String get vaultRestoreLater => '稍后恢复';

  @override
  String get vaultForgotPin => '忘记 PIN 码？';

  @override
  String get vaultSetPinBtn => '设置 PIN 码并加密';

  @override
  String get vaultDecryptBtn => '解密并解锁';

  @override
  String get vaultPinMinLength => 'PIN 码至少需要 4 位';

  @override
  String get vaultPinsDoNotMatch => '两次输入的 PIN 码不匹配';

  @override
  String get vaultSetupFailed => '保险库设置失败，请重试。';

  @override
  String get vaultIncorrectPin => 'PIN 码不正确';

  @override
  String get vaultFingerprintOutOfDate => '指纹已更改，请使用 PIN 码解锁。';

  @override
  String get vaultBiometricError => '生物识别不可用';

  @override
  String get vaultBioReasonUnlock => '验证身份以解锁您的保险库聊天';

  @override
  String get vaultBioReasonEnrol => '验证身份以启用生物识别快速解锁';

  @override
  String get vaultAskBioTitle => '启用生物识别解锁？';

  @override
  String get vaultAskBioDesc => '使用指纹或面容快速安全地解锁您的保险库。';

  @override
  String get vaultAskBioNotNow => '以后再说';

  @override
  String get vaultAskBioEnable => '启用';

  @override
  String get vaultDeleteMessagesTitle => '删除保险库消息？';

  @override
  String get vaultDeleteMessagesDesc =>
      '如果您忘记了 PIN 码，加密消息将无法恢复。重置 PIN 码将清除当前保险库的所有内容。';

  @override
  String get vaultDeleteMessagesCancel => '取消';

  @override
  String get vaultDeleteMessagesConfirm => '删除消息并重置 PIN 码';

  @override
  String get vaultCustodyConfirmTitle => '确认保险库托管模式';

  @override
  String get vaultCustodyChooseTitle => '保险库密钥托管模式';

  @override
  String get vaultCustodyConfirmDesc => '请确认您偏好的加密密钥存储模式。';

  @override
  String get vaultCustodyChooseDesc => '选择保险库加密密钥的存储与保护方式。';

  @override
  String get vaultCustodyDontKnow => '不确定？稍后可随时在保险库设置中更改。';

  @override
  String get vaultCustodyConfirmBtn => '确认并继续';

  @override
  String get vaultCustodySaveBtn => '保存并继续';

  @override
  String get vaultCustodyMismatchError => '加密元数据不匹配，请重试。';

  @override
  String get vaultCustodyAutoUpdateFailed => '自动更新托管模式失败。';

  @override
  String vaultCustodyReencrypting(int done, int total) {
    return '正在重新加密 $done / $total… 请保持应用开启。';
  }

  @override
  String get vaultCustodyPreparing => '正在准备重新加密…';

  @override
  String get vaultSettingsTitle => '保险库设置';

  @override
  String get vaultSettingsAboutTitle => '关于私密保险库';

  @override
  String get vaultSettingsAboutDesc =>
      '保险库是一个独立且安全的聊天空间，受专属 PIN 码保护，专为极度隐私的对话设计。';

  @override
  String get vaultSettingsBulletMessages => '端到端加密所有保险库内的消息与文件。';

  @override
  String get vaultSettingsBulletStatuses => '完全隔离的私密状态与聊天，不会出现在系统通知中。';

  @override
  String get vaultSettingsNeverKept => '绝不在服务器保留明文解密密钥。';

  @override
  String get vaultSettingsSectionPrivacy => '隐私与自动销毁';

  @override
  String get vaultSettingsAutoDelete => '自动销毁保险库消息';

  @override
  String get vaultSettingsKeepForever => '永久保留';

  @override
  String vaultSettingsDeleteAfter(String label) {
    return '$label 后销毁';
  }

  @override
  String get vaultSettingsSectionPin => 'PIN 码与生物识别';

  @override
  String get vaultSettingsChangePin => '更改保险库 PIN 码';

  @override
  String get vaultSettingsChangePinSubtitle => '更新您的保险库 PIN 码或密码短语';

  @override
  String get vaultSettingsBioTitle => '生物识别解锁';

  @override
  String get vaultSettingsBioSubOn => '使用指纹或面容快速解锁保险库';

  @override
  String get vaultSettingsBioSubOff => '已关闭生物识别';

  @override
  String get vaultSettingsSectionDanger => '危险区域';

  @override
  String get vaultSettingsDeleteData => '清空保险库数据';

  @override
  String get vaultSettingsDeleteDataSubtitle => '从此设备中永久删除所有加密消息和媒体';

  @override
  String get vaultSettingsResetVault => '重置整个保险库';

  @override
  String get vaultSettingsResetVaultSubtitle => '移除保险库 PIN 码并删除所有保险库数据';

  @override
  String get vaultSettingsPinChanged => '保险库 PIN 码修改成功！';

  @override
  String get vaultSettingsBioTurnedOff => '已停用生物识别解锁。';

  @override
  String get vaultSettingsBioTurnedOn => '已启用生物识别解锁。';

  @override
  String get vaultSettingsClearDataTitle => '清空所有保险库数据？';

  @override
  String get vaultSettingsClearDataDesc => '这将从此设备中彻底删除所有保险库消息与媒体文件，且无法找回。';

  @override
  String get vaultSettingsClearDataCancel => '取消';

  @override
  String get vaultSettingsClearDataConfirm => '清空数据';

  @override
  String get vaultSettingsDataDeleted => '保险库数据已清空。';

  @override
  String get vaultSettingsResetTitle => '彻底重置保险库？';

  @override
  String get vaultSettingsResetDesc => '所有加密内容将被永久删除，且 PIN 码将被重置。您需要重新设置保险库。';

  @override
  String get vaultSettingsResetConfirm => '重置并清除';

  @override
  String get vaultSettingsChangeDialogDesc => '输入当前 PIN 码并设置新的 PIN 码。';

  @override
  String get vaultSettingsCurrentPin => '当前 PIN 码';

  @override
  String get vaultSettingsNewPin => '新 PIN 码';

  @override
  String get vaultSettingsConfirmNewPin => '确认新 PIN 码';

  @override
  String get vaultSettingsEnterCurrentPin => '请输入当前 PIN 码';

  @override
  String get vaultSettingsNewPinMinLength => '新 PIN 码至少需要 4 位';

  @override
  String get vaultSettingsNewPinMismatch => '新 PIN 码两次输入不一致';

  @override
  String get vaultSettingsCurrentPinIncorrect => '当前 PIN 码错误';

  @override
  String vaultSettingsReencryptingCount(int done, int total) {
    return '正在重新加密 $done / $total…';
  }

  @override
  String get vaultSettingsChangeBtn => '更改 PIN 码';

  @override
  String get vaultSettingsBioPinDialogTitle => '验证保险库 PIN 码';

  @override
  String get vaultSettingsBioPinDialogDesc => '请输入您的保险库 PIN 码以修改生物识别设置。';

  @override
  String get vaultSettingsContinueBtn => '继续';

  @override
  String get premiumTitle => 'GupShupGo 高级版';

  @override
  String get premiumSubtitleMember => '您已是高级版尊贵会员';

  @override
  String get premiumSubtitleUnlock => '解锁极致特权与无缝隐私体验';

  @override
  String premiumActiveDaysRemaining(int days) {
    return '剩余 $days 天';
  }

  @override
  String get premiumFeaturesHeader => '包含的所有特权';

  @override
  String get premiumPlansHeader => '选择订阅计划';

  @override
  String get premiumSubscribeBtn => '立即升级';

  @override
  String get premiumCancelAnytime => '可随时在应用商店中取消订阅';

  @override
  String get premiumRestoreBtn => '恢复购买';

  @override
  String get premiumRestoring => '正在恢复购买…';

  @override
  String get premiumRestoredSuccess => '已成功恢复您的购买！';

  @override
  String get premiumNoActiveSub => '未找到有效的订阅。';

  @override
  String get premiumProductUnavailable => '订阅项目暂时不可用，请稍后重试。';

  @override
  String get premiumFeatureMediaTitle => '无损原画质媒体';

  @override
  String get premiumFeatureMediaDesc => '以未经压缩的最高质量发送高清照片与视频';

  @override
  String get premiumFeatureMediaFree => '标准压缩媒体';

  @override
  String get premiumFeatureMediaPro => '原图画质，零压缩';

  @override
  String get premiumFeatureScreenShareTitle => '超高清屏幕共享';

  @override
  String get premiumFeatureScreenShareDesc => '支持高达 1080p 60fps 的超清晰实时屏幕串流';

  @override
  String get premiumFeatureScreenShareFree => '标准 720p 串流';

  @override
  String get premiumFeatureScreenSharePro => '超清 1080p 60fps 串流';

  @override
  String get premiumFeatureThemesTitle => '尊贵个性化主题';

  @override
  String get premiumFeatureThemesDesc => '解锁所有专属深色主题、强调色与聊天气泡外观';

  @override
  String get premiumFeatureThemesFree => '仅限默认主题';

  @override
  String get premiumFeatureThemesPro => '无限制使用所有高级主题';

  @override
  String get premiumFeatureVoiceTitle => '超长语音备忘录';

  @override
  String get premiumFeatureVoiceDesc => '录制并发送长达 30 分钟的高音质语音留言';

  @override
  String get premiumFeatureVoiceFree => '最长 2 分钟';

  @override
  String get premiumFeatureVoicePro => '单条长达 30 分钟';

  @override
  String get premiumFeatureQualityTitle => '极速优先传输';

  @override
  String get premiumFeatureQualityDesc => '专享极速通道，上传与下载快人一步';

  @override
  String get premiumFeatureQualityFree => '标准网络带宽';

  @override
  String get premiumFeatureQualityPro => '独享高优先级专属通道';

  @override
  String get premiumFeatureBondTitle => '亲密度专属徽章';

  @override
  String get premiumFeatureBondDesc => '与密友聊天时展示独特亲密度动态特效与标识';

  @override
  String get premiumFeatureBondFree => '基础亲密度等级';

  @override
  String get premiumFeatureBondPro => '专属光效与特别徽章';

  @override
  String get premiumFeatureBadgeTitle => 'PRO 专属身份标识';

  @override
  String get premiumFeatureBadgeDesc => '在个人资料与群组中展示高贵 PRO 徽标';

  @override
  String get premiumFeatureBadgeFree => '无专属标识';

  @override
  String get premiumFeatureBadgePro => '尊贵 PRO 金色徽章';

  @override
  String get premiumFeatureExportTitle => '聊天记录完整导出';

  @override
  String get premiumFeatureExportDesc => '一键导出聊天记录与多媒体文件为 PDF 或 ZIP';

  @override
  String get premiumFeatureExportFree => '不可导出';

  @override
  String get premiumFeatureExportPro => '一键完整备份导出';

  @override
  String get premiumFeatureAdFreeTitle => '纯净清爽体验';

  @override
  String get premiumFeatureAdFreeDesc => '享受彻底无广告的纯净通讯空间';

  @override
  String get premiumFeatureAdFreeFree => '含应用支持广告';

  @override
  String get premiumFeatureAdFreePro => '100% 纯净无广告';

  @override
  String get premiumPlanMonthly => '按月订阅';

  @override
  String get premiumPlanYearly => '按年订阅';

  @override
  String get premiumPlanSavings => '立省 40%';

  @override
  String get premiumPeriodMonth => '每月';

  @override
  String get premiumPeriodYear => '每年';

  @override
  String get nearbyOfflineChatTitle => '离线本地快传';

  @override
  String get nearbySearchingDevices => '正在搜索周边设备…';

  @override
  String get nearbyTooltipStop => '停止搜索';

  @override
  String get nearbyTooltipStart => '开始搜索';

  @override
  String get nearbyDevicesSection => '发现的周边设备';

  @override
  String get nearbyDiscoveryOn => '广播搜索已开启';

  @override
  String get nearbyDiscoveryOff => '广播搜索已关闭';

  @override
  String get nearbyHeroTitle => '随时随地面对面畅聊';

  @override
  String nearbyHeroNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '附近 $count 台设备',
      one: '附近 1 台设备',
    );
    return '$_temp0';
  }

  @override
  String get nearbyHeroOff => '离线雷达已关闭';

  @override
  String get nearbyHeroDesc => '无需网络连接，利用 Wi-Fi 与蓝牙即刻与周围好友离线聊天传图。';

  @override
  String get nearbyYourNameHint => '向他人显示的设备昵称';

  @override
  String get nearbyEmptySearching => '正在搜寻周围设备…';

  @override
  String get nearbyEmptyOff => '雷达发现已关闭';

  @override
  String get nearbyEmptySearchingDesc => '请确保附近的设备也打开了此屏幕。';

  @override
  String get nearbyEmptyOffDesc => '点击右上角播放按钮开启周边设备扫描。';

  @override
  String get nearbyPeerConnected => '已连接';

  @override
  String get nearbyPeerConnecting => '正在连接…';

  @override
  String get nearbyPeerTapToConnect => '点击即可连接';

  @override
  String get nearbyActionChat => '聊天';

  @override
  String get nearbyActionConnecting => '连接中…';

  @override
  String get nearbyActionConnect => '连接';

  @override
  String get nearbyPermNeededTitle => '需要必要权限';

  @override
  String get nearbyPermNeededDesc => '离线搜索需要位置信息以及蓝牙周边设备访问权限。';

  @override
  String get nearbyTryAgainBtn => '重试';

  @override
  String get nearbySettingsBtn => '前往设置';

  @override
  String get nearbyHelpTip => '提示：请确保双方设备均已开启 Wi-Fi 和蓝牙开关。';

  @override
  String get anonLobbyTitle => '匿名漂流聊天';

  @override
  String get anonLobbyFinding => '正在为您寻找聊天对象…';

  @override
  String get anonLobbyHangTight => '请稍候，系统正在为您匹配在线的陌生人。';

  @override
  String get anonLobbyCancelBtn => '取消匹配';

  @override
  String get anonLobbyPrivacyNote => '您的身份完全保密。对方无法看到您的真实姓名、电话或头像。';

  @override
  String get anonLobbyConnecting => '正在建立连接…';

  @override
  String get anonLobbyWaitingOthers => '正在等待更多用户加入…';

  @override
  String anonLobbyOnlineCount(int count) {
    return '当前 $count 人在线';
  }

  @override
  String get anonChatNotEncrypted => '注意：为便于举报不良行为，匿名随机聊天不使用端到端加密。';

  @override
  String get anonChatRequestSentTooltip => '好友申请已发送';

  @override
  String get anonChatAddFriendTooltip => '添加为好友';

  @override
  String get anonChatNextStrangerTooltip => '换下一位';

  @override
  String get anonChatReportTooltip => '举报违规';

  @override
  String get anonChatSayHi => '打个招呼吧！您已连接上一位匿名用户。';

  @override
  String get anonChatFriendsTransition => '你们已成为好友！会话已迁移至主聊天列表。';

  @override
  String get anonChatStrangerDisconnected => '对方已离开聊天。';

  @override
  String get anonChatFindNextBtn => '寻找下一位';

  @override
  String get anonChatFriendReqTitle => '好友申请';

  @override
  String get anonChatFriendReqDesc => '对方希望添加您为好友并公开彼此的个人资料。';

  @override
  String get anonChatDecline => '婉拒';

  @override
  String get anonChatAccept => '接受';

  @override
  String get anonChatWaitingReqTitle => '已发送好友申请';

  @override
  String get anonChatWaitingReqDesc => '正在等待对方接受您的身份公开请求…';

  @override
  String get anonChatReportTitle => '举报匿名用户';

  @override
  String get anonChatReportQuestion => '您为何举报该用户？';

  @override
  String get anonChatReportReasonInappropriate => '不当或色情内容';

  @override
  String get anonChatReportReasonHarassment => '骚扰或侮辱行为';

  @override
  String get anonChatReportReasonSpam => '垃圾营销或诈骗';

  @override
  String get anonChatReportReasonThreatening => '威胁或危险行为';

  @override
  String get anonChatReportReasonOther => '其他原因';

  @override
  String get anonChatReportCancel => '取消';

  @override
  String get anonChatReportSubmit => '提交举报';

  @override
  String get anonChatReportSubmitted => '感谢您的反馈，我们已收到您的举报并将进行核实处理。';

  @override
  String get anonChatViewOnceVideoTitle => '阅后即焚视频';

  @override
  String get anonChatViewOncePhotoTitle => '阅后即焚照片';

  @override
  String get anonChatViewOnceVideoDesc => '该视频只能播放一次，播放结束后将被自动销毁。';

  @override
  String get anonChatViewOncePhotoDesc => '该照片只能查看一次，关闭后将无法再次打开。';

  @override
  String get anonChatViewOnceCancel => '取消';

  @override
  String get anonChatViewOnceOpen => '立即查看';

  @override
  String get unsupportedVersionTitle => '需要更新应用';

  @override
  String get unsupportedVersionDesc =>
      '当前 GupShupGo 版本已停止支持。请更新至最新版本以继续享受安全稳定的聊天和通话服务。';

  @override
  String get unsupportedVersionUpdateNow => '立即更新';

  @override
  String get unsupportedVersionOpenPlayStore => '打开应用商店';

  @override
  String publicProfileNotFound(String username) {
    return '未找到 @$username';
  }

  @override
  String get publicProfileUserNotFound => '未找到该用户';

  @override
  String get publicProfileNotFoundDesc => '该用户名可能已更改，或者该账号已不再活跃。';

  @override
  String get publicProfileTitle => '个人资料';

  @override
  String get publicProfileOnline => '在线';

  @override
  String publicProfileLastSeen(String time) {
    return '最后在线于 $time';
  }

  @override
  String get publicProfileJustNow => '刚刚';

  @override
  String publicProfileMinutesAgo(int minutes) {
    return '$minutes 分钟前';
  }

  @override
  String publicProfileHoursAgo(int hours) {
    return '$hours 小时前';
  }

  @override
  String publicProfileDaysAgo(int days) {
    return '$days 天前';
  }

  @override
  String publicProfileJoined(String date) {
    return '注册于 $date';
  }

  @override
  String get publicProfileOwnLink => '这是您的公开个人资料';

  @override
  String publicProfileGupPoints(int points) {
    return '$points Gup 积分';
  }

  @override
  String publicProfileLevel(int level) {
    return '等级 $level';
  }

  @override
  String get publicProfileStatPoints => '积分';

  @override
  String get publicProfileStatBadges => '徽章';

  @override
  String get publicProfileStatBestBond => '最佳羁绊';

  @override
  String get publicProfileBadges => '获得的徽章';

  @override
  String get qrScannerTitle => '扫一扫';

  @override
  String get qrScannerFlashOnTooltip => '开启手电筒';

  @override
  String get qrScannerFlashOffTooltip => '关闭手电筒';

  @override
  String get qrScannerPrompt => '将摄像头对准二维码以添加好友或连接设备';

  @override
  String get qrScannerNotProfileCode => '该二维码不是有效的 GupShupGo 个人资料码。';

  @override
  String get qrScannerCameraErrorTitle => '相机发生错误';

  @override
  String get qrScannerCameraErrorRetry => '重试';

  @override
  String get qrScannerPermissionMsg => '需要相机权限方能扫描二维码。';

  @override
  String get qrScannerPermissionAllow => '授权允许';

  @override
  String get qrScannerBlockedMsg => '相机权限已被禁用。请在系统设置中允许相机访问。';

  @override
  String get qrScannerBlockedSettings => '打开系统设置';

  @override
  String get screenShareIncomingTitle => '收到屏幕共享邀请';

  @override
  String get screenShareWantsToShare => '希望与您共享其屏幕画面。';

  @override
  String get screenShareReject => '拒绝';

  @override
  String get screenShareAccept => '接受';

  @override
  String get screenShareCantAccept => '当前无法接受屏幕共享邀请。';

  @override
  String screenShareDeclined(String name) {
    return '$name 拒绝了屏幕共享';
  }

  @override
  String get screenShareNoAnswer => '对方未应答。';

  @override
  String get screenShareStartError => '无法开启屏幕共享，请稍后再试。';

  @override
  String get screenShareStatusRequesting => '正在发起请求…';

  @override
  String get screenShareStatusInitializing => '正在初始化…';

  @override
  String get screenShareStatusWaitingParticipant => '正在等待参与者加入…';

  @override
  String get screenShareStatusActive => '您正在共享屏幕';

  @override
  String screenShareSubWaitingAccept(String name) {
    return '正在等待 $name 接受…';
  }

  @override
  String get screenShareSubEstablishing => '正在建立安全直连通道…';

  @override
  String screenShareSubWaitingJoin(String name) {
    return '正在等待 $name 加入...';
  }

  @override
  String get screenShareSubActive => '您的屏幕画面正在实时串流给对方';

  @override
  String get screenShareBadgeRequesting => '发起请求中';

  @override
  String get screenShareBadgeConnecting => '连接中';

  @override
  String get screenShareSharedWith => '共享对象：';

  @override
  String get screenShareRequestingFrom => '邀请人：';

  @override
  String get screenShareMinimizeTip => '共享进行时您可以最小化此面板';

  @override
  String get screenShareStop => '停止共享';

  @override
  String get screenShareCancelRequest => '取消请求';

  @override
  String screenShareViewerTitle(String name) {
    return '$name 的屏幕画面';
  }

  @override
  String get screenShareViewerLive => '直播中';

  @override
  String get screenShareViewerMinimize => '最小化窗口';

  @override
  String get screenShareViewerLeave => '退出共享';

  @override
  String screenShareViewerWaitingStream(String name) {
    return '正在等待 $name 开启屏幕串流...';
  }

  @override
  String get screenShareViewerConnecting => '正在连接视频画面…';

  @override
  String get viewOnceVideoTitle => '阅后即焚视频';

  @override
  String get viewOncePhotoTitle => '阅后即焚照片';

  @override
  String get viewOnceCantOpen => '已过期的媒体文件无法再次打开。';

  @override
  String get viewOnceUnavailable => '该媒体不可用或已查看销毁。';

  @override
  String get viewOnceBlockedFooter => '为保障隐私，已禁止截屏与录屏。';

  @override
  String get viewOnceUnblockedFooter => '关闭此窗口后媒体内容将立刻销毁。';
}
