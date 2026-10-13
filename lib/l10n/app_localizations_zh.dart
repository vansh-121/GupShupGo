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
  String get homeNavChats => '聊天';

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
}
