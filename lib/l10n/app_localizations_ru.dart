// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonOk => 'ОК';

  @override
  String get commonContinue => 'Продолжить';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonGotIt => 'Понятно';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguageTitle => 'Язык';

  @override
  String get settingsLanguageSubtitle => 'Выберите предпочитаемый язык';

  @override
  String get languagePickerTitle => 'Язык';

  @override
  String get languageSystemDefault => 'Системный';

  @override
  String get languageSystemDefaultSubtitle => 'Язык вашего устройства';

  @override
  String get loginContinueWithPhone => 'Продолжить по номеру телефона';

  @override
  String get loginContinueWithGoogle => 'Продолжить через Google';

  @override
  String get loginUseEmailPassword => 'Использовать эл. почту и пароль';

  @override
  String get loginSignIn => 'Войти';

  @override
  String get loginSignUp => 'Регистрация';

  @override
  String get loginCreateAccount => 'Создать аккаунт';

  @override
  String get loginForgotPassword => 'Забыли пароль?';

  @override
  String get loginOfflineChat => 'Офлайн-чат';

  @override
  String get loginHintName => 'Ваше имя';

  @override
  String get loginHintEmail => 'Эл. почта';

  @override
  String get loginHintPassword => 'Пароль';

  @override
  String get loginPasswordHelper =>
      'Не менее 8 символов, включая букву и цифру';

  @override
  String loginResetEmailSent(String email) {
    return 'Письмо для сброса пароля отправлено на $email';
  }

  @override
  String get loginErrorEnterEmail => 'Пожалуйста, введите адрес эл. почты';

  @override
  String get loginErrorValidEmail =>
      'Пожалуйста, введите корректный адрес эл. почты';

  @override
  String get loginErrorEnterPassword => 'Пожалуйста, введите пароль';

  @override
  String get loginErrorPasswordMin6 =>
      'Пароль должен содержать не менее 6 символов';

  @override
  String get loginErrorEnterPasswordSignup => 'Пожалуйста, введите пароль';

  @override
  String get loginErrorPasswordMin8 =>
      'Пароль должен содержать не менее 8 символов';

  @override
  String get loginErrorPasswordLetter =>
      'Пароль должен содержать хотя бы одну букву';

  @override
  String get loginErrorPasswordNumber =>
      'Пароль должен содержать хотя бы одну цифру';

  @override
  String get loginErrorEnterName => 'Пожалуйста, введите ваше имя';

  @override
  String get loginErrorGoogleCancelled => 'Вход через Google был отменен.';

  @override
  String get loginErrorProfileLoad =>
      'Не удалось загрузить профиль. Проверьте соединение и повторите попытку.';

  @override
  String get loginErrorGoogleFailed =>
      'Ошибка входа через Google. Пожалуйста, повторите попытку.';

  @override
  String get loginErrorSignInFailed =>
      'Не удалось войти. Пожалуйста, повторите попытку.';

  @override
  String get loginErrorSignUpFailed =>
      'Не удалось зарегистрироваться. Пожалуйста, повторите попытку.';

  @override
  String get loginErrorGeneric =>
      'Произошла ошибка. Пожалуйста, повторите попытку.';

  @override
  String get loginErrorResetFailed =>
      'Не удалось отправить письмо для сброса. Повторите попытку.';

  @override
  String get loginErrorUserNotFound =>
      'Аккаунт с таким адресом не найден. Пожалуйста, зарегистрируйтесь.';

  @override
  String get loginErrorWrongPassword =>
      'Неверный пароль. Пожалуйста, повторите попытку.';

  @override
  String get loginErrorEmailInUse =>
      'Аккаунт с этим адресом уже существует. Пожалуйста, войдите.';

  @override
  String get loginErrorInvalidEmail =>
      'Пожалуйста, введите действительный адрес эл. почты.';

  @override
  String get loginErrorWeakPassword =>
      'Слишком простой пароль. Используйте не менее 6 символов.';

  @override
  String get loginErrorInvalidCredential =>
      'Неверный адрес эл. почты или пароль. Проверьте данные и повторите попытку.';

  @override
  String get loginErrorTooManyRequests =>
      'Слишком много попыток. Пожалуйста, повторите попытку позже.';

  @override
  String get homeNavChats => 'Сообщения';

  @override
  String get homeNavMoments => 'Моменты';

  @override
  String get homeNavCalls => 'Звонки';

  @override
  String get homeNavProfile => 'Профиль';

  @override
  String get homeTooltipOfflineChat => 'Офлайн-чат — общение с людьми рядом';

  @override
  String get homeTooltipSearch => 'Поиск';

  @override
  String get homeMenuProfile => 'Профиль';

  @override
  String get homeMenuPrivateVault => 'Личное хранилище';

  @override
  String get homeMenuSettings => 'Настройки';

  @override
  String get homeMenuRateUs => 'Оценить нас';

  @override
  String get homeMenuReportIssue => 'Сообщить о проблеме';

  @override
  String get homeMenuWhatsNew => 'Что нового';

  @override
  String get homeMenuLogOut => 'Выйти';

  @override
  String get homeEmptyChatsTitle => 'Пока нет чатов';

  @override
  String get homeEmptyChatsSubtitle => 'Начните общение, нажав кнопку ниже';

  @override
  String get homeNewChatButton => 'Новый чат';

  @override
  String get homeAiAssistantTitle => 'GupAI';

  @override
  String get homeAiAssistantSubtitle =>
      'Черновики, перевод, краткое содержание и многое другое';

  @override
  String get homeStrangerMatchTitle => 'Случайный собеседник';

  @override
  String get homeStrangerMatchSubtitle => 'Анонимный чат — нажмите для поиска!';

  @override
  String get homeMyMoment => 'Мой момент';

  @override
  String get homeRecentMoments => 'Недавние моменты';

  @override
  String get homeEmptyMomentsTitle => 'Пока нет обновлений.';

  @override
  String get homeEmptyMomentsSubtitle => 'Нажмите на камеру, чтобы поделиться.';

  @override
  String get homeTapToAddMoment => 'Нажмите, чтобы добавить статус';

  @override
  String get homeEmptyCallsTitle => 'История звонков пуста';

  @override
  String get homeEmptyCallsSubtitle =>
      'Здесь будут отображаться ваши недавние звонки';

  @override
  String get chatInputHint => 'Сообщение...';

  @override
  String get chatSearchHint => 'Поиск по сообщениям...';

  @override
  String get chatStatusTyping => 'печатает...';

  @override
  String get chatStatusOnline => 'В сети';

  @override
  String get chatStatusOffline => 'Не в сети';

  @override
  String chatStatusLastSeen(String time) {
    return 'Был(а) в сети $time';
  }

  @override
  String get chatEndToEndEncrypted => 'Сквозное шифрование';

  @override
  String get chatNoInternetOfflineTitle =>
      'Нет интернета? Общайтесь офлайн с устройствами рядом';

  @override
  String get chatEnableOfflineButton => 'Включить';

  @override
  String get chatSlideToCancel => 'Проведите для отмены';

  @override
  String get chatTooltipVoiceCall => 'Голосовой звонок';

  @override
  String get chatTooltipVideoCall => 'Видеозвонок';

  @override
  String get chatMenuContactInfo => 'Данные контакта';

  @override
  String get chatMenuSearch => 'Поиск';

  @override
  String get chatMenuChatTheme => 'Тема чата';

  @override
  String get chatMenuExportChat => 'Экспорт чата';

  @override
  String get chatMenuMuteNotifications => 'Отключить уведомления';

  @override
  String get chatMenuUnmuteNotifications => 'Включить уведомления';

  @override
  String get chatMenuBlockContact => 'Заблокировать';

  @override
  String get chatActionReply => 'Ответить';

  @override
  String get chatActionCopy => 'Копировать';

  @override
  String get chatActionForward => 'Переслать';

  @override
  String get chatActionTranslate => 'Перевести';

  @override
  String get chatActionSummarise => 'Кратко';

  @override
  String get chatActionAskGupAi => 'Спросить GupAI';

  @override
  String get chatActionEdit => 'Изменить';

  @override
  String get chatActionDelete => 'Удалить';

  @override
  String get chatDeleteMessageTitle => 'Удалить сообщение?';

  @override
  String get chatDeleteMessageForEveryonePrompt =>
      'Удалить только для вас или для всех в этом чате?';

  @override
  String chatDeleteMessageForMeOnlyPrompt(String name) {
    return 'Это удалит сообщение только с ваших устройств. $name продолжит его видеть.';
  }

  @override
  String get chatDeleteForMe => 'Удалить у меня';

  @override
  String get chatDeleteForEveryone => 'Удалить у всех';

  @override
  String chatBlockContactTitle(String name) {
    return 'Заблокировать $name?';
  }

  @override
  String get chatBlockContactPrompt =>
      'Заблокированные контакты не смогут писать вам или звонить. Разблокировать можно в меню Настройки → Конфиденциальность.';

  @override
  String get chatBlockButton => 'Заблокировать';

  @override
  String get chatForwardTo => 'Переслать в';

  @override
  String get chatNoForwardChats => 'Нет других чатов для пересылки';

  @override
  String get chatCannotSendMediaBlocked =>
      'Нельзя отправлять медиа этому контакту';

  @override
  String get attachmentShareTitle => 'Поделиться';

  @override
  String get attachmentPhoto => 'Фото';

  @override
  String get attachmentPhotoSubtitle => 'Выберите фото из галереи';

  @override
  String get attachmentVideo => 'Видео';

  @override
  String get attachmentVideoSubtitle => 'Выберите видео из галереи';

  @override
  String get attachmentDocument => 'Документ';

  @override
  String get attachmentDocumentSubtitle => 'PDF, офисный файл, архив';

  @override
  String get attachmentLocation => 'Геопозиция';

  @override
  String get attachmentLocationSubtitle => 'Поделитесь текущим местоположением';

  @override
  String get attachmentScreenShare => 'Демонстрация экрана';

  @override
  String get attachmentScreenShareSubtitle =>
      'Показывайте свой экран в реальном времени во время чата';

  @override
  String get attachmentViewOnce => 'Однократный просмотр';

  @override
  String get attachmentViewOnceSubtitle =>
      'Фото или видео исчезнет после открытия';

  @override
  String get contactsTitle => 'Контакты и поиск';

  @override
  String get contactsTabFriends => 'Друзья';

  @override
  String get contactsTabRequests => 'Запросы';

  @override
  String get contactsTabDiscover => 'Поиск';

  @override
  String get contactsScanQrTooltip => 'Сканировать QR-код';

  @override
  String get contactsMyHandleTooltip => 'Мой никнейм';

  @override
  String get contactsSetUsernamePrompt =>
      'Сначала укажите @username в профиле — именно им делится ваш QR-код.';

  @override
  String get contactsMyQrCodeTitle => 'QR-код моего профиля';

  @override
  String get contactsMyQrCodeSubtitle =>
      'Друзья могут отсканировать этот QR-код для мгновенной связи';

  @override
  String get contactsCopyProfileLink => 'Скопировать ссылку на профиль';

  @override
  String contactsProfileLinkCopied(String username) {
    return 'Ссылка на профиль @$username скопирована!';
  }

  @override
  String get contactsScanSomeonesCode => 'Сканировать чужой код';

  @override
  String get contactsPermissionDenied => 'Доступ к контактам отклонен.';

  @override
  String get contactsNoUsersFound =>
      'Пользователей GupShupGo в ваших контактах пока нет.';

  @override
  String contactsFailedToSync(String error) {
    return 'Не удалось синхронизировать контакты: $error';
  }

  @override
  String contactsMatchedCount(int count) {
    return 'Контактов в GupShupGo: $count';
  }

  @override
  String get contactsFromDeviceContacts => 'Из контактов вашего устройства';

  @override
  String get contactsLoadFriendsError => 'Не удалось загрузить список друзей.';

  @override
  String get contactsNoFriendsTitle => 'Друзья еще не добавлены';

  @override
  String get contactsNoFriendsPrompt =>
      'Используйте вкладку Поиск, чтобы найти пользователей по @username, телефону или email!';

  @override
  String get contactsDiscoverPeopleButton => 'Найти людей';

  @override
  String get contactsQuickConnectHeader => 'БЫСТРОЕ ПОДКЛЮЧЕНИЕ';

  @override
  String get contactsNoSuggestions => 'На данный момент предложений нет.';

  @override
  String get contactsLoadRequestsError => 'Не удалось загрузить запросы.';

  @override
  String contactsPendingRequestsHeader(int count) {
    return 'ВХОДЯЩИЕ ЗАПРОСЫ ($count)';
  }

  @override
  String get contactsNoPendingRequestsTitle => 'Нет входящих запросов';

  @override
  String get contactsNoPendingRequestsSubtitle =>
      'Когда вам отправят запрос на добавление, он появится здесь.';

  @override
  String get contactsWantsToConnect => 'Хочет связаться';

  @override
  String get contactsAcceptButton => 'ПРИНЯТЬ';

  @override
  String get contactsAcceptFailed =>
      'Не удалось принять запрос. Повторите попытку.';

  @override
  String contactsConnectedWith(String name) {
    return 'Вы добавили $name в друзья!';
  }

  @override
  String get contactsDeclineFailed =>
      'Не удалось отклонить запрос. Повторите попытку.';

  @override
  String get contactsYouMightKnowHeader => 'ВОЗМОЖНО, ВЫ ЗНАКОМЫ';

  @override
  String get contactsSeeAll => 'СМОТРЕТЬ ВСЕ';

  @override
  String get contactsSearchHint =>
      'Поиск по имени, @нику, телефону или email...';

  @override
  String get contactsTurnOnDiscoverability =>
      'Включите видимость, чтобы появляться в поиске и рекомендациях.';

  @override
  String get contactsNoMatchingUsersTitle => 'Пользователи не найдены';

  @override
  String get contactsNoMatchingUsersSubtitle =>
      'Проверьте @username, номер телефона или email и попробуйте снова.';

  @override
  String get contactsDiscoverHeroTitle => 'Знакомьтесь в GupShupGo';

  @override
  String get contactsDiscoverHeroSubtitle =>
      'Расширяйте круг общения надежными связями по всему миру.';

  @override
  String get contactsSyncDeviceContacts => 'Синхронизировать контакты';

  @override
  String get contactsSyncingContacts => 'Синхронизация контактов...';

  @override
  String get contactsSyncDeviceSubtitle =>
      'Мгновенно находите друзей из телефонной книги';

  @override
  String get contactsSuggestedUsersHeader => 'РЕКОМЕНДУЕМЫЕ ПОЛЬЗОВАТЕЛИ';

  @override
  String get contactsAddFriendButton => 'ДОБАВИТЬ В ДРУЗЬЯ';

  @override
  String get contactsRequestedButton => 'Запрос отправлен';

  @override
  String contactsRequestSent(String name) {
    return 'Запрос в друзья отправлен $name!';
  }

  @override
  String get contactsRequestFailed =>
      'Запрос уже отправлен или произошла ошибка.';

  @override
  String get contactsRequestUnavailable => 'Этот запрос больше недоступен.';

  @override
  String get profileEditTitle => 'Редактировать профиль';

  @override
  String get profileSaveButton => 'Сохранить';

  @override
  String get profileTapToChangePhoto => 'Нажмите, чтобы сменить фото';

  @override
  String get profileUpgradeToPro => 'Перейти на Pro';

  @override
  String get profileSectionName => 'ВАШЕ ИМЯ';

  @override
  String get profileNameHint => 'Введите ваше имя';

  @override
  String get profileSectionHandle => 'УНИКАЛЬНЫЙ НИКНЕЙМ';

  @override
  String get profileHandleNotSet => 'Еще не задан';

  @override
  String get profileChangeHandle => 'Изменить';

  @override
  String get profileSectionAbout => 'О СЕБЕ';

  @override
  String get profileAboutHint => 'Что у вас нового?';

  @override
  String get profileDefaultAbout => 'Привет! Я использую GupShupGo.';

  @override
  String get profileSectionPhone => 'ТЕЛЕФОН';

  @override
  String get profileSectionEmail => 'EMAIL';

  @override
  String get profileSectionLinkedMethods => 'ПРИВЯЗАННЫЕ СПОСОБЫ ВХОДА';

  @override
  String get profileNotLinked => 'Не привязано';

  @override
  String get profileNameEmpty => 'Имя не может быть пустым.';

  @override
  String get profileUpdatedSuccess => 'Профиль обновлен';

  @override
  String profileUploadPhotoFailed(String error) {
    return 'Не удалось загрузить фото: $error';
  }

  @override
  String profileSaveFailed(String error) {
    return 'Не удалось сохранить профиль: $error';
  }

  @override
  String get profilePoints => 'Очки';

  @override
  String get profileBadges => 'Значки';

  @override
  String get profileBestBond => 'Лучшая связь';

  @override
  String get settingsAccountCard => 'Аккаунт';

  @override
  String get settingsProfileTile => 'Профиль';

  @override
  String get settingsLinkedMethodsTile => 'Привязанные способы входа';

  @override
  String get settingsPhoneTile => 'Номер телефона';

  @override
  String get settingsEmailTile => 'Email';

  @override
  String get settingsPrivacyCard => 'Конфиденциальность';

  @override
  String get settingsDiscoverability => 'Видимость в поиске';

  @override
  String get settingsLastSeen => 'Время захода';

  @override
  String get settingsReadReceipts => 'Отчеты о прочтении';

  @override
  String get settingsAdPreferences => 'Настройки рекламы';

  @override
  String get settingsManage => 'Управление';

  @override
  String get settingsAppearanceCard => 'Внешний вид';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Темная';

  @override
  String get settingsThemeSystem => 'Системная';

  @override
  String get settingsChatTheme => 'Тема чата';

  @override
  String get settingsHelpSecurityCard => 'Помощь и безопасность';

  @override
  String get settingsHelpCenter => 'Справочный центр';

  @override
  String get settingsReportProblem => 'Сообщить о проблеме';

  @override
  String get settingsE2EEShield => 'Сквозное шифрование (Vault)';

  @override
  String get settingsVerifySafetyNumber => 'Проверить код безопасности';

  @override
  String get settingsBlockedContacts => 'Заблокированные контакты';

  @override
  String get settingsClearAllGupHistory => 'Очистить всю историю чатов';

  @override
  String get settingsRateUs => 'Оценить приложение';

  @override
  String get settingsWhatsNew => 'Что нового';

  @override
  String get settingsCheckForUpdates => 'Проверить обновления';

  @override
  String get settingsAppInfo => 'О приложении';

  @override
  String get settingsLogOut => 'Выйти';

  @override
  String get settingsLogOutConfirmTitle => 'Выход';

  @override
  String get settingsLogOutConfirmPrompt =>
      'Вы уверены, что хотите выйти из GupShupGo?';

  @override
  String get settingsSigningOut => 'Выход из аккаунта…';

  @override
  String get settingsClearChatsConfirmTitle => 'Очистить все чаты';

  @override
  String get settingsClearChatsConfirmPrompt =>
      'Это безвозвратно удалит всю историю сообщений. Действие нельзя отменить.';

  @override
  String get settingsDeleteAll => 'Удалить все';

  @override
  String get settingsClearingChats => 'Очистка чатов...';

  @override
  String get settingsAllChatsCleared => 'Все чаты очищены';

  @override
  String settingsClearChatsFailed(String error) {
    return 'Не удалось очистить чаты: $error';
  }

  @override
  String get settingsChooseThemeTitle => 'Выберите тему';

  @override
  String get settingsUnlockPremiumFeatures => 'Разблокируйте Pro-функции';

  @override
  String settingsProDaysLeft(String planLabel, int daysRemaining) {
    return '$planLabel · Осталось $daysRemaining дн.';
  }

  @override
  String get settingsCheckingForUpdates => 'Проверка обновлений…';

  @override
  String settingsUpToDate(String version) {
    return 'У вас установлена последняя версия (v$version).';
  }

  @override
  String get settingsUpdateCheckUnavailable =>
      'Не удалось проверить обновления. Убедитесь, что приложение установлено из Google Play.';

  @override
  String get settingsNoBlockedContacts => 'Нет заблокированных контактов';

  @override
  String get settingsUnblock => 'Разблокировать';

  @override
  String settingsUserUnblocked(String name) {
    return '$name разблокирован(а)';
  }

  @override
  String get settingsVerifyContactTitle => 'Проверить контакт';

  @override
  String get settingsVerifyContactSubtitle =>
      'Выберите контакт, чтобы просмотреть общий код безопасности.';

  @override
  String get settingsComputingSafetyNumber => 'Вычисление кода безопасности…';

  @override
  String settingsSafetyNumberExplanation(String name) {
    return 'Если код совпадает на устройстве $name, сквозное шифрование подтверждено.';
  }

  @override
  String get settingsSafetyNumberNoBundle =>
      'Этот контакт еще не опубликовал ключи шифрования.';

  @override
  String get settingsSafetyNumberCompareHint =>
      'Сравните этот номер лично или по защищенному звонку.';

  @override
  String get callEndToEndEncrypted => 'Сквозное шифрование';

  @override
  String get callSecuring => 'Защита вызова…';

  @override
  String get callNotEncrypted => 'Не зашифровано';

  @override
  String get callIncomingVoice => 'Входящий голосовой вызов';

  @override
  String get callIncomingVideo => 'Входящий видеовызов';

  @override
  String get callVoiceCall => 'Голосовой вызов';

  @override
  String get callVideoCall => 'Видеовызов';

  @override
  String get callDecline => 'Отклонить';

  @override
  String get callAccept => 'Принять';

  @override
  String get callConnecting => 'Подключение...';

  @override
  String get callSettingUp => 'Настройка вызова...';

  @override
  String callNotifying(String name) {
    return 'Оповещение $name...';
  }

  @override
  String get callRinging => 'Звонок...';

  @override
  String get callConnected => 'Подключено';

  @override
  String get callOnHold => 'На удержании';

  @override
  String get callCalling => 'Вызов...';

  @override
  String get callWaitingForUser => 'Ожидание собеседника...';

  @override
  String get callEnded => 'Звонок завершён';

  @override
  String get callDeclined => 'Вызов отклонён';

  @override
  String get callNoAnswer => 'Нет ответа';

  @override
  String get callFailedToConnect => 'Не удалось подключиться';

  @override
  String callFailedToStart(String error) {
    return 'Не удалось начать звонок: $error';
  }

  @override
  String get callTokenExpired =>
      'Токен истёк или недействителен. Перезапустите звонок.';

  @override
  String callFailedToInit(String type, String error) {
    return 'Ошибка инициализации $type вызова: $error';
  }

  @override
  String get callTurnOffSpeaker => 'Выключить динамик';

  @override
  String get callTurnOnSpeaker => 'Включить динамик';

  @override
  String get callMuteMic => 'Отключить микрофон';

  @override
  String get callUnmuteMic => 'Включить микрофон';

  @override
  String get callEndCall => 'Завершить звонок';

  @override
  String get callSwitchCamera => 'Переключить камеру';

  @override
  String get callTurnOffCamera => 'Выключить камеру';

  @override
  String get callTurnOnCamera => 'Включить камеру';

  @override
  String statusViewedByCount(int count) {
    return 'Просмотрено $count';
  }

  @override
  String get statusNoViewsYet => 'Пока нет просмотров';

  @override
  String statusViewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count просмотров',
      one: '1 просмотр',
    );
    return '$_temp0';
  }

  @override
  String get statusDeleteTitle => 'Удалить статус';

  @override
  String get statusDeleteConfirm =>
      'Вы уверены, что хотите удалить этот статус?';

  @override
  String get statusDeleteButton => 'Удалить';

  @override
  String get statusReplySent => 'Ответ отправлен';

  @override
  String statusReplyFailed(String error) {
    return 'Не удалось отправить ответ: $error';
  }

  @override
  String get statusNoActive => 'Нет активных статусов';

  @override
  String get statusCouldNotLoad => 'Не удалось загрузить обновление';

  @override
  String get statusTapToRetry => 'Нажмите для повтора';

  @override
  String get statusFailedToLoadImage => 'Не удалось загрузить фото';

  @override
  String get statusLoadingVideo => 'Загрузка видео...';

  @override
  String get statusEnterTextPrompt => 'Пожалуйста, введите текст';

  @override
  String get statusNoContactsNotice =>
      'Контактов пока нет — начните чат перед публикацией статуса.';

  @override
  String statusPostFailed(String error) {
    return 'Не удалось опубликовать статус: $error';
  }

  @override
  String get statusTypeHint => 'Введите статус...';

  @override
  String get statusCamera => 'Камера';

  @override
  String get statusTakePhoto => 'Сделать фото';

  @override
  String get statusGalleryPhoto => 'Фото из галереи';

  @override
  String get statusChooseImageGallery => 'Выбрать фото из галереи';

  @override
  String get statusRecordVideo => 'Записать видео';

  @override
  String get statusRecordShortVideo => 'Записать короткое видео';

  @override
  String get statusGalleryVideo => 'Видео из галереи';

  @override
  String get statusChooseVideoGallery => 'Выбрать видео из галереи';

  @override
  String statusFailedPickImage(String error) {
    return 'Не удалось выбрать фото: $error';
  }

  @override
  String statusFailedPickVideo(String error) {
    return 'Не удалось выбрать видео: $error';
  }

  @override
  String get statusChangeBgColorTooltip => 'Сменить цвет фона';

  @override
  String aiMessagesRemaining(int count) {
    return 'Осталось: $count';
  }

  @override
  String get aiQuotaDialogTitle => 'Сообщения GupAI';

  @override
  String aiQuotaRemainingOfTotal(int remaining, int total) {
    return 'Осталось $remaining из $total на сегодня';
  }

  @override
  String aiQuotaUsedResetNote(int used) {
    return 'Использовано $used сегодня · сбросится завтра. Посмотрите рекламу или оформите Pro.';
  }

  @override
  String get aiQuotaGotIt => 'Понятно';

  @override
  String get aiTitle => 'GupAI';

  @override
  String get aiSubtitle => 'Ваш помощник в приложении';

  @override
  String get aiEmptyHelpTitle => 'Чем я могу помочь?';

  @override
  String get aiEmptyHelpSubtitle =>
      'Составляйте ответы, переводите, резюмируйте или задавайте вопросы.';

  @override
  String get meshOfflineChatConnected => 'Офлайн-чат · подключено';

  @override
  String get meshConnecting => 'Подключение…';

  @override
  String get meshBannerNotice => 'Офлайн-чат — без интернета и серверов';

  @override
  String meshSayHiTo(String name) {
    return 'Поздоровайтесь с $name';
  }

  @override
  String meshOfflineDescription(String name) {
    return 'Вы в офлайн-чате. Сообщения остаются только между вами и $name.';
  }

  @override
  String get meshMediaUnavailable => 'Медиа больше недоступно.';

  @override
  String get meshViewOnceTitle => 'Однократный просмотр';

  @override
  String meshViewOncePrompt(String type) {
    return 'Вы можете открыть этот $type только один раз.';
  }

  @override
  String get arcadeTabOverview => 'Обзор';

  @override
  String get arcadeTabChallenges => 'Испытания';

  @override
  String get arcadeTabLeaderboard => 'Таблица лидеров';

  @override
  String get arcadeFailedLoadStats => 'Не удалось загрузить статистику.';

  @override
  String get aiAskHint => 'Спросите GupAI о чем угодно…';

  @override
  String get settingsNotificationsTile => 'Уведомления';

  @override
  String get settingsNotificationsStatusOn => 'Вкл';

  @override
  String get settingsNotificationsStatusOff => 'Выкл';

  @override
  String get settingsNotificationsEnabledToast => 'Уведомления включены.';

  @override
  String get settingsEnableNotificationsTitle => 'Включить уведомления';

  @override
  String get settingsEnableNotificationsBody =>
      'Уведомления отключены. Откройте настройки системы, чтобы GupShupGo мог уведомлять вас о новых сообщениях и звонках.';

  @override
  String get settingsOpenSystemSettings => 'Открыть настройки';

  @override
  String get loginTagline =>
      'Личные сообщения, которые работают даже без интернета.';

  @override
  String get settingsPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get settingsTerms => 'Условия обслуживания';

  @override
  String get settingsDeleteAccount => 'Удалить аккаунт';

  @override
  String get inviteSheetTitle => 'Пригласить друзей';

  @override
  String get inviteSheetSubtitle => 'Расскажите друзьям — поделитесь GupShupGo';

  @override
  String get inviteShareImageBtn => 'Поделиться картинкой';

  @override
  String get inviteShareLinkBtn => 'Поделиться ссылкой';

  @override
  String get inviteCopyLinkBtn => 'Скопировать ссылку';

  @override
  String get inviteLinkCopied => 'Ссылка для приглашения скопирована';

  @override
  String inviteMessage(String link) {
    return 'Общайся со мной в GupShupGo — работает даже без интернета 👋 $link';
  }

  @override
  String get inviteCardTagline =>
      'Личные сообщения, которые работают даже офлайн';

  @override
  String get inviteCardScan => 'Сканируйте для загрузки';

  @override
  String get inviteCardDownload => 'Загрузить в Google Play';

  @override
  String get homeMenuInvite => 'Пригласить друзей';

  @override
  String get invitePromptTitle => 'Нравится GupShupGo?';

  @override
  String get invitePromptBody =>
      'С друзьями веселее — и работает даже без интернета. Пригласить кого-нибудь?';

  @override
  String get invitePromptInvite => 'Пригласить друзей';

  @override
  String get invitePromptLater => 'Может позже';

  @override
  String get homeOfflineBannerTitle => 'Нет интернета? Не проблема';

  @override
  String get homeOfflineBannerSubtitle =>
      'Вы по-прежнему можете переписываться с людьми поблизости через Bluetooth.';

  @override
  String homeNearbyBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count человек поблизости',
      many: '$count человек поблизости',
      few: '$count человека поблизости',
      one: '1 человек поблизости',
    );
    return '$_temp0';
  }

  @override
  String get homeNearbyBannerSubtitle =>
      'Чат по Bluetooth — интернет не нужен.';

  @override
  String get linkBackupTitle => 'Добавить резервный способ входа';

  @override
  String get linkBackupSubtitle =>
      'Привяжите Google или эл. почту, чтобы входить даже при отсутствии SIM-карты.';

  @override
  String get linkGoogleTitle => 'Привязать аккаунт Google';

  @override
  String get linkGoogleSubtitleLinked => 'Привязано ✓';

  @override
  String get linkGoogleSubtitleUnlinked => 'Вход в одно касание без SIM';

  @override
  String get linkGoogleAction => 'Привязать';

  @override
  String get linkGoogleSuccess => 'Аккаунт Google успешно привязан!';

  @override
  String get linkGoogleAlreadyUsed =>
      'Этот аккаунт Google уже используется в другом профиле.';

  @override
  String get linkGoogleFailed => 'Ошибка привязки Google. Попробуйте снова.';

  @override
  String get linkSessionExpired => 'Сессия истекла. Войдите снова.';

  @override
  String get linkEmailTitle => 'Привязать эл. почту и пароль';

  @override
  String get linkEmailSubtitleLinked => 'Привязано ✓';

  @override
  String get linkEmailSubtitleUnlinked => 'Вход по почте без SIM или Google';

  @override
  String get linkEmailActionAdd => 'Добавить';

  @override
  String get linkEmailActionCancel => 'Отмена';

  @override
  String get linkEmailFieldLabel => 'Эл. почта';

  @override
  String get linkPasswordFieldLabel => 'Создать пароль';

  @override
  String get linkPasswordHelper => 'Минимум 6 символов';

  @override
  String get linkEmailButton => 'Привязать почту';

  @override
  String get linkEmailSuccess => 'Эл. почта успешно привязана!';

  @override
  String get linkEmailInvalid => 'Введите корректный адрес эл. почты.';

  @override
  String get linkPasswordTooShort =>
      'Пароль должен содержать не менее 6 символов.';

  @override
  String get linkEmailAlreadyInUse =>
      'Эта почта уже зарегистрирована в GupShupGo.';

  @override
  String get linkEmailAlreadyLinked => 'К вашему аккаунту уже привязана почта.';

  @override
  String get linkEmailFailed => 'Не удалось привязать почту.';

  @override
  String get linkContinueToApp => 'Продолжить в приложении';

  @override
  String get linkSkipForNow => 'Пропустить';

  @override
  String get linkSkip => 'Пропустить';

  @override
  String get phoneAuthTitleEntry => 'Войдите по номеру телефона.';

  @override
  String get phoneAuthTitleOtp => 'Введите отправленный код.';

  @override
  String get phoneAuthNameHint => 'Ваше имя';

  @override
  String get phoneAuthPhoneHint => 'Номер телефона';

  @override
  String get phoneAuthUseSim => 'SIM-карта';

  @override
  String get phoneAuthSendOtp => 'Отправить код';

  @override
  String phoneAuthOtpPrompt(String phone) {
    return 'Введите 6-значный код, отправленный на $phone';
  }

  @override
  String get phoneAuthOtpPromptGeneric => 'Введите отправленный 6-значный код';

  @override
  String get phoneAuthOtpHint => 'Введите код';

  @override
  String get phoneAuthVerify => 'Подтвердить';

  @override
  String get phoneAuthGoBack => 'Назад';

  @override
  String get phoneAuthResendCode => 'Отправить код повторно';

  @override
  String get phoneAuthEnterName => 'Пожалуйста, введите ваше имя';

  @override
  String get phoneAuthEnterValidPhone => 'Введите корректный номер телефона';

  @override
  String get phoneAuthEnterCode => 'Пожалуйста, введите код';

  @override
  String get phoneAuthRequestNewCode => 'Запросите новый код.';

  @override
  String get phoneAuthCodeIncorrect => 'Неверный код. Попробуйте снова.';

  @override
  String get phoneAuthErrCodeIncorrect => 'Код неверен. Проверьте и повторите.';

  @override
  String get phoneAuthErrCodeExpired => 'Срок действия кода истек.';

  @override
  String get phoneAuthErrTooManyRequests =>
      'Слишком много попыток. Подождите немного.';

  @override
  String get phoneAuthErrInvalidPhone => 'Некорректный номер телефона.';

  @override
  String get phoneAuthErrQuotaExceeded => 'Лимит SMS исчерпан.';

  @override
  String get phoneAuthErrFailed => 'Ошибка проверки.';

  @override
  String get usernameSetupAppBarTitle => 'Выберите имя пользователя';

  @override
  String get usernameSetupHeaderTitle => 'Защитите свою личность';

  @override
  String get usernameSetupHeaderDesc =>
      'Ваш @handle — уникальный ключ в GupShupGo. Друзья смогут находить вас без раскрытия телефона или почты.';

  @override
  String get usernameSetupInputHint => 'vash_nik';

  @override
  String get usernameSetupChecking => 'Проверка доступности...';

  @override
  String usernameSetupAvailable(String handle) {
    return '@$handle доступно!';
  }

  @override
  String usernameSetupTaken(String handle) {
    return '@$handle уже занято.';
  }

  @override
  String get usernameSetupCharRules => '3–20 символов (a-z, 0-9, _)';

  @override
  String get usernameSetupTooShort => 'Минимум 3 символа.';

  @override
  String get usernameSetupTooLong => 'Максимум 20 символов.';

  @override
  String get usernameSetupInvalidChars =>
      'Разрешены только буквы, цифры и подчеркивания.';

  @override
  String get usernameSetupRecommended => 'РЕКОМЕНДУЕМЫЕ';

  @override
  String get usernameSetupSaveBtn => 'Сохранить и продолжить';

  @override
  String get usernameSetupSkipBtn => 'Пропустить';

  @override
  String usernameSetupFailed(String error) {
    return 'Не удалось сохранить имя: $error';
  }

  @override
  String get vaultProtectTitle => 'Защитить хранилище';

  @override
  String get vaultUnlockTitle => 'Открыть хранилище';

  @override
  String get vaultSetupDesc =>
      'Выберите PIN-код для шифрования истории сообщений.';

  @override
  String get vaultUnlockDescBio =>
      'Введите PIN или отсканируйте отпечаток для расшифровки.';

  @override
  String get vaultUnlockDescPin => 'Введите PIN для расшифровки сообщений.';

  @override
  String get vaultReinstallHint =>
      'Введите PIN для восстановления истории на этом устройстве.';

  @override
  String get vaultUnlockWithFingerprint => 'Разблокировать отпечатком';

  @override
  String get vaultOrDivider => 'ИЛИ';

  @override
  String get vaultNewPin => 'Новый PIN';

  @override
  String get vaultConfirmPin => 'Подтвердите PIN';

  @override
  String get vaultEnterPin => 'Введите PIN';

  @override
  String get vaultKeyboardUseLetters => 'Использовать буквы';

  @override
  String get vaultKeyboardUseNumbers => 'Использовать цифры';

  @override
  String get vaultRestoreLater => 'Восстановить позже';

  @override
  String get vaultForgotPin => 'Забыли PIN?';

  @override
  String get vaultSetPinBtn => 'Задать PIN';

  @override
  String get vaultDecryptBtn => 'Расшифровать';

  @override
  String get vaultPinMinLength => 'PIN должен содержать минимум 6 символов.';

  @override
  String get vaultPinsDoNotMatch => 'PIN-коды не совпадают.';

  @override
  String get vaultSetupFailed => 'Ошибка настройки.';

  @override
  String get vaultIncorrectPin => 'Неверный PIN. Попробуйте снова.';

  @override
  String get vaultFingerprintOutOfDate => 'Отпечаток устарел. Введите PIN.';

  @override
  String get vaultBiometricError => 'Ошибка биометрии. Введите PIN вручную.';

  @override
  String get vaultBioReasonUnlock =>
      'Биометрическая аутентификация для открытия хранилища';

  @override
  String get vaultBioReasonEnrol =>
      'Подтвердите отпечаток для быстрой разблокировки';

  @override
  String get vaultAskBioTitle => 'Разблокировать отпечатком?';

  @override
  String get vaultAskBioDesc =>
      'Не вводите PIN каждый раз. Сохраните PIN для новых устройств.';

  @override
  String get vaultAskBioNotNow => 'Не сейчас';

  @override
  String get vaultAskBioEnable => 'Включить';

  @override
  String get vaultDeleteMessagesTitle => 'Удалить все сообщения?';

  @override
  String get vaultDeleteMessagesDesc =>
      'Без PIN расшифровать историю невозможно, сброс сотрет все данные навсегда.';

  @override
  String get vaultDeleteMessagesCancel => 'Отмена';

  @override
  String get vaultDeleteMessagesConfirm => 'Удалить все';

  @override
  String get vaultCustodyConfirmTitle => 'Подтвердите PIN хранилища';

  @override
  String get vaultCustodyChooseTitle => 'Выберите PIN';

  @override
  String get vaultCustodyConfirmDesc =>
      'История сообщений зашифрована PIN-кодом. Подтвердите его.';

  @override
  String get vaultCustodyChooseDesc =>
      'Выберите запоминающийся PIN. Все сообщения будут перешифрованы.';

  @override
  String get vaultCustodyDontKnow => 'Я не знаю свой PIN';

  @override
  String get vaultCustodyConfirmBtn => 'Подтвердить';

  @override
  String get vaultCustodySaveBtn => 'Сохранить PIN';

  @override
  String get vaultCustodyMismatchError => 'Этот PIN не подходит.';

  @override
  String get vaultCustodyAutoUpdateFailed =>
      'Не удалось обновить PIN автоматически.';

  @override
  String vaultCustodyReencrypting(int done, int total) {
    return 'Шифрование $done из $total… не закрывайте приложение.';
  }

  @override
  String get vaultCustodyPreparing => 'Подготовка… не закрывайте приложение.';

  @override
  String get vaultSettingsTitle => 'Хранилище';

  @override
  String get vaultSettingsAboutTitle => 'О хранилище';

  @override
  String get vaultSettingsAboutDesc =>
      'Приватная копия чатов, заблокированная вашим PIN-кодом. Никто другой не может ее прочитать.';

  @override
  String get vaultSettingsBulletMessages => 'Ваши сообщения';

  @override
  String get vaultSettingsBulletStatuses => 'Видимые статусы';

  @override
  String get vaultSettingsNeverKept =>
      'Здесь никогда не хранятся: звонки, контакты и фото из чатов.';

  @override
  String get vaultSettingsSectionPrivacy => 'КОНФИДЕНЦИАЛЬНОСТЬ';

  @override
  String get vaultSettingsAutoDelete => 'Автоудаление старых сообщений';

  @override
  String get vaultSettingsKeepForever => 'Хранить всегда';

  @override
  String vaultSettingsDeleteAfter(String label) {
    return 'Удалять через $label';
  }

  @override
  String get vaultSettingsSectionPin => 'PIN-КОД';

  @override
  String get vaultSettingsChangePin => 'Сменить PIN';

  @override
  String get vaultSettingsChangePinSubtitle =>
      'Заново шифрует все данные хранилища';

  @override
  String get vaultSettingsBioTitle => 'Вход по отпечатку';

  @override
  String get vaultSettingsBioSubOn => 'Включено на этом устройстве';

  @override
  String get vaultSettingsBioSubOff => 'Не вводить PIN на этом устройстве';

  @override
  String get vaultSettingsSectionDanger => 'ОПАСНАЯ ЗОНА';

  @override
  String get vaultSettingsDeleteData => 'Удалить данные хранилища';

  @override
  String get vaultSettingsDeleteDataSubtitle => 'Стирает историю, сохраняя PIN';

  @override
  String get vaultSettingsResetVault => 'Сбросить хранилище';

  @override
  String get vaultSettingsResetVaultSubtitle => 'Сбрасывает PIN и удаляет всё';

  @override
  String get vaultSettingsPinChanged => 'PIN изменен.';

  @override
  String get vaultSettingsBioTurnedOff => 'Вход по отпечатку выключен.';

  @override
  String get vaultSettingsBioTurnedOn => 'Вход по отпечатку включен.';

  @override
  String get vaultSettingsClearDataTitle => 'Удалить данные хранилища?';

  @override
  String get vaultSettingsClearDataDesc =>
      'Удаляет зашифрованные сообщения из облака. PIN сохраняется.';

  @override
  String get vaultSettingsClearDataCancel => 'Отмена';

  @override
  String get vaultSettingsClearDataConfirm => 'Удалить данные';

  @override
  String get vaultSettingsDataDeleted => 'Данные хранилища удалены.';

  @override
  String get vaultSettingsResetTitle => 'Сбросить хранилище?';

  @override
  String get vaultSettingsResetDesc =>
      'Удаляет PIN и все сообщения. Потребуется настроить новый PIN.';

  @override
  String get vaultSettingsResetConfirm => 'Сбросить';

  @override
  String get vaultSettingsChangeDialogDesc =>
      'Все сообщения будут перешифрованы новым PIN-кодом.';

  @override
  String get vaultSettingsCurrentPin => 'Текущий PIN';

  @override
  String get vaultSettingsNewPin => 'Новый PIN';

  @override
  String get vaultSettingsConfirmNewPin => 'Повторите новый PIN';

  @override
  String get vaultSettingsEnterCurrentPin => 'Введите текущий PIN.';

  @override
  String get vaultSettingsNewPinMinLength => 'Минимум 6 символов.';

  @override
  String get vaultSettingsNewPinMismatch => 'PIN-коды не совпадают.';

  @override
  String get vaultSettingsCurrentPinIncorrect => 'Текущий PIN неверен.';

  @override
  String vaultSettingsReencryptingCount(int done, int total) {
    return 'Шифрование $done из $total…';
  }

  @override
  String get vaultSettingsChangeBtn => 'Изменить';

  @override
  String get vaultSettingsBioPinDialogTitle => 'Введите PIN';

  @override
  String get vaultSettingsBioPinDialogDesc =>
      'PIN необходим для активации входа по отпечатку.';

  @override
  String get vaultSettingsContinueBtn => 'Продолжить';

  @override
  String get premiumTitle => 'GupShupGo Pro';

  @override
  String get premiumSubtitleMember => 'У вас статус Pro! 🎉';

  @override
  String get premiumSubtitleUnlock => 'Откройте все возможности';

  @override
  String premiumActiveDaysRemaining(int days) {
    return 'Осталось дней: $days';
  }

  @override
  String get premiumFeaturesHeader => 'Что дает Pro';

  @override
  String get premiumPlansHeader => 'Выберите тариф';

  @override
  String get premiumSubscribeBtn => 'Оформить подписку';

  @override
  String get premiumCancelAnytime => 'Отмена в любой момент в Google Play.';

  @override
  String get premiumRestoreBtn => 'Восстановить покупку';

  @override
  String get premiumRestoring => 'Восстановление…';

  @override
  String get premiumRestoredSuccess => 'Подписка Pro восстановлена! 🎉';

  @override
  String get premiumNoActiveSub => 'Активная подписка не найдена.';

  @override
  String get premiumProductUnavailable => 'Продукт недоступен.';

  @override
  String get premiumFeatureMediaTitle => 'Медиа-статусы';

  @override
  String get premiumFeatureMediaDesc => 'Делитесь фото и видео в статусах';

  @override
  String get premiumFeatureMediaFree => 'Только текст';

  @override
  String get premiumFeatureMediaPro => 'Фото + Видео';

  @override
  String get premiumFeatureScreenShareTitle => 'Трансляция экрана';

  @override
  String get premiumFeatureScreenShareDesc =>
      'Делитесь экраном прямо во время звонка';

  @override
  String get premiumFeatureScreenShareFree => 'Недоступно';

  @override
  String get premiumFeatureScreenSharePro => 'Полный доступ';

  @override
  String get premiumFeatureThemesTitle => 'Темы для чата';

  @override
  String get premiumFeatureThemesDesc =>
      'Фоны и градиентные сообщения для каждого чата';

  @override
  String get premiumFeatureThemesFree => '6 тем';

  @override
  String get premiumFeatureThemesPro => 'Все 12 + свое фото';

  @override
  String get premiumFeatureVoiceTitle => 'Длинные голосовые';

  @override
  String get premiumFeatureVoiceDesc =>
      'Записывайте длинные голосовые сообщения';

  @override
  String get premiumFeatureVoiceFree => '2 минуты';

  @override
  String get premiumFeatureVoicePro => 'Без ограничений';

  @override
  String get premiumFeatureQualityTitle => 'Высокое качество медиа';

  @override
  String get premiumFeatureQualityDesc => 'Четкие фото и статусы до 90 сек.';

  @override
  String get premiumFeatureQualityFree => 'Обычное качество';

  @override
  String get premiumFeatureQualityPro => 'Высокое качество + 90с видео';

  @override
  String get premiumFeatureBondTitle => 'Восстановление серии';

  @override
  String get premiumFeatureBondDesc =>
      'Восстанавливайте утерянные серии бесплатно';

  @override
  String get premiumFeatureBondFree => 'Баллы или реклама';

  @override
  String get premiumFeatureBondPro => '1 бесплатное восстановление в неделю';

  @override
  String get premiumFeatureBadgeTitle => 'Значок Pro';

  @override
  String get premiumFeatureBadgeDesc => 'Эксклюзивный значок в профиле';

  @override
  String get premiumFeatureBadgeFree => 'Без значка';

  @override
  String get premiumFeatureBadgePro => 'Значок Pro';

  @override
  String get premiumFeatureExportTitle => 'Экспорт чата';

  @override
  String get premiumFeatureExportDesc => 'Сохраняйте диалоги в PDF или текст';

  @override
  String get premiumFeatureExportFree => 'Недоступно';

  @override
  String get premiumFeatureExportPro => 'Экспорт в PDF и TXT';

  @override
  String get premiumFeatureAdFreeTitle => 'Без рекламы';

  @override
  String get premiumFeatureAdFreeDesc =>
      'Никаких рекламных баннеров в приложении';

  @override
  String get premiumFeatureAdFreeFree => 'Баннеры включены';

  @override
  String get premiumFeatureAdFreePro => 'Без баннеров';

  @override
  String get premiumPlanMonthly => 'Месяц';

  @override
  String get premiumPlanYearly => 'Год';

  @override
  String get premiumPlanSavings => 'Скидка ~33%';

  @override
  String get premiumPeriodMonth => '/мес.';

  @override
  String get premiumPeriodYear => '/год';

  @override
  String get nearbyOfflineChatTitle => 'Офлайн-чат';

  @override
  String get nearbySearchingDevices => 'Поиск устройств поблизости…';

  @override
  String get nearbyTooltipStop => 'Остановить офлайн-чат';

  @override
  String get nearbyTooltipStart => 'Запустить офлайн-чат';

  @override
  String get nearbyDevicesSection => 'Устройства поблизости';

  @override
  String get nearbyDiscoveryOn => 'ПОИСК ВКЛЮЧЕН';

  @override
  String get nearbyDiscoveryOff => 'ПОИСК ВЫКЛЮЧЕН';

  @override
  String get nearbyHeroTitle => 'Офлайн-режим';

  @override
  String nearbyHeroNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count рядом',
      one: '1 рядом',
    );
    return '$_temp0';
  }

  @override
  String get nearbyHeroOff => 'Офлайн-чат выключен';

  @override
  String get nearbyHeroDesc =>
      'Поиск в радиусе 100 метров по Bluetooth. Интернет не требуется.';

  @override
  String get nearbyYourNameHint => 'Ваше имя';

  @override
  String get nearbyEmptySearching => 'Поиск устройств поблизости…';

  @override
  String get nearbyEmptyOff => 'Офлайн-чат выключен';

  @override
  String get nearbyEmptySearchingDesc =>
      'Убедитесь, что GupShupGo открыт с включенным Bluetooth.';

  @override
  String get nearbyEmptyOffDesc =>
      'Нажмите кнопку запуска в правом верхнем углу.';

  @override
  String get nearbyPeerConnected => 'Подключено · Нажмите для чата';

  @override
  String get nearbyPeerConnecting => 'Подключение…';

  @override
  String get nearbyPeerTapToConnect => 'Нажмите для подключения';

  @override
  String get nearbyActionChat => 'Чат';

  @override
  String get nearbyActionConnecting => 'Связь';

  @override
  String get nearbyActionConnect => 'Подключить';

  @override
  String get nearbyPermNeededTitle => 'Нужны разрешения';

  @override
  String get nearbyPermNeededDesc =>
      'Требуется доступ к Bluetooth и поиск устройств поблизости.';

  @override
  String get nearbyTryAgainBtn => 'Повторить';

  @override
  String get nearbySettingsBtn => 'Настройки';

  @override
  String get nearbyHelpTip =>
      'Не видите друга? Проверьте Bluetooth на обоих устройствах.';

  @override
  String get anonLobbyTitle => 'Анонимный чат';

  @override
  String get anonLobbyFinding => 'Ищем собеседника…';

  @override
  String get anonLobbyHangTight =>
      'Секунду — соединяем со случайным собеседником.';

  @override
  String get anonLobbyCancelBtn => 'Отменить поиск';

  @override
  String get anonLobbyPrivacyNote => 'Ваша личность скрыта.';

  @override
  String get anonLobbyConnecting => 'Соединение…';

  @override
  String get anonLobbyWaitingOthers => 'Ожидание пользователей онлайн…';

  @override
  String anonLobbyOnlineCount(int count) {
    return '$count онлайн сейчас';
  }

  @override
  String get anonChatNotEncrypted =>
      'Сообщения не защищены сквозным шифрованием';

  @override
  String get anonChatRequestSentTooltip => 'Запрос отправлен';

  @override
  String get anonChatAddFriendTooltip => 'Добавить в друзья';

  @override
  String get anonChatNextStrangerTooltip => 'Следующий собеседник';

  @override
  String get anonChatReportTooltip => 'Пожаловаться';

  @override
  String get anonChatSayHi => 'Поприветствуйте собеседника! 👋';

  @override
  String get anonChatFriendsTransition =>
      'Теперь вы друзья! Переход в защищенный чат…';

  @override
  String get anonChatStrangerDisconnected => 'Собеседник отключился 👋';

  @override
  String get anonChatFindNextBtn => 'Найти следующего';

  @override
  String get anonChatFriendReqTitle => 'Собеседник хочет дружить!';

  @override
  String get anonChatFriendReqDesc =>
      'Принятие запроса раскроет профили и откроет защищенный чат.';

  @override
  String get anonChatDecline => 'Отклонить';

  @override
  String get anonChatAccept => 'Принять';

  @override
  String get anonChatWaitingReqTitle => 'Запрос дружбы отправлен';

  @override
  String get anonChatWaitingReqDesc => 'Ожидание ответа…';

  @override
  String get anonChatReportTitle => 'Пожаловаться';

  @override
  String get anonChatReportQuestion => 'Причина жалобы:';

  @override
  String get anonChatReportReasonInappropriate => 'Неприемлемый контент';

  @override
  String get anonChatReportReasonHarassment => 'Оскорбления или травля';

  @override
  String get anonChatReportReasonSpam => 'Спам или мошенничество';

  @override
  String get anonChatReportReasonThreatening => 'Угрозы';

  @override
  String get anonChatReportReasonOther => 'Другое';

  @override
  String get anonChatReportCancel => 'Отмена';

  @override
  String get anonChatReportSubmit => 'Пожаловаться и выйти';

  @override
  String get anonChatReportSubmitted => 'Жалоба отправлена. Спасибо за помощь.';

  @override
  String get anonChatViewOnceVideoTitle => 'Одноразовое видео?';

  @override
  String get anonChatViewOncePhotoTitle => 'Одноразовое фото?';

  @override
  String get anonChatViewOnceVideoDesc =>
      'Это видео можно открыть только один раз.';

  @override
  String get anonChatViewOncePhotoDesc =>
      'Это фото можно открыть только один раз.';

  @override
  String get anonChatViewOnceCancel => 'Отмена';

  @override
  String get anonChatViewOnceOpen => 'Открыть';

  @override
  String get unsupportedVersionTitle => 'Обновите GupShupGo';

  @override
  String get unsupportedVersionDesc =>
      'Эта версия больше не поддерживается. Обновитесь для продолжения общения.';

  @override
  String get unsupportedVersionUpdateNow => 'Обновить';

  @override
  String get unsupportedVersionOpenPlayStore => 'Открыть Play Store';

  @override
  String publicProfileNotFound(String username) {
    return '@$username не найден';
  }

  @override
  String get publicProfileUserNotFound => 'Пользователь не найден';

  @override
  String get publicProfileNotFoundDesc =>
      'Такого пользователя нет или ссылка недействительна.';

  @override
  String get publicProfileTitle => 'Профиль';

  @override
  String get publicProfileOnline => 'В сети';

  @override
  String publicProfileLastSeen(String time) {
    return 'Был(а) в сети $time';
  }

  @override
  String get publicProfileJustNow => 'только что';

  @override
  String publicProfileMinutesAgo(int minutes) {
    return '$minutes мин. назад';
  }

  @override
  String publicProfileHoursAgo(int hours) {
    return '$hours ч. назад';
  }

  @override
  String publicProfileDaysAgo(int days) {
    return '$days дн. назад';
  }

  @override
  String publicProfileJoined(String date) {
    return 'В клубе с $date';
  }

  @override
  String get publicProfileOwnLink => 'Это ссылка на ваш собственный профиль.';

  @override
  String publicProfileGupPoints(int points) {
    return '$points очков Gup';
  }

  @override
  String publicProfileLevel(int level) {
    return 'Уровень $level';
  }

  @override
  String get publicProfileStatPoints => 'Очки';

  @override
  String get publicProfileStatBadges => 'Значки';

  @override
  String get publicProfileStatBestBond => 'Лучшая серия';

  @override
  String get publicProfileBadges => 'ЗНАЧКИ';

  @override
  String get qrScannerTitle => 'Сканировать QR-код';

  @override
  String get qrScannerFlashOnTooltip => 'Включить вспышку';

  @override
  String get qrScannerFlashOffTooltip => 'Выключить вспышку';

  @override
  String get qrScannerPrompt => 'Наведите камеру на QR-код профиля GupShupGo';

  @override
  String get qrScannerNotProfileCode => 'Это не код профиля GupShupGo.';

  @override
  String get qrScannerCameraErrorTitle => 'Не удалось запустить камеру.';

  @override
  String get qrScannerCameraErrorRetry => 'Попробуйте снова.';

  @override
  String get qrScannerPermissionMsg =>
      'Нужен доступ к камере для сканирования QR.';

  @override
  String get qrScannerPermissionAllow => 'Разрешить камеру';

  @override
  String get qrScannerBlockedMsg =>
      'Камера заблокирована. Разрешите в Настройках.';

  @override
  String get qrScannerBlockedSettings => 'Открыть настройки';

  @override
  String get screenShareIncomingTitle => 'Входящая трансляция экрана';

  @override
  String get screenShareWantsToShare => 'хочет показать свой экран';

  @override
  String get screenShareReject => 'Отклонить';

  @override
  String get screenShareAccept => 'Принять';

  @override
  String get screenShareCantAccept => 'Не удалось принять. Проверьте интернет.';

  @override
  String screenShareDeclined(String name) {
    return '$name отклонил(а) показ экрана';
  }

  @override
  String get screenShareNoAnswer => 'Нет ответа';

  @override
  String get screenShareStartError => 'Не удалось запустить показ экрана';

  @override
  String get screenShareStatusRequesting => 'Запрос разрешения';

  @override
  String get screenShareStatusInitializing => 'Запуск трансляции';

  @override
  String get screenShareStatusWaitingParticipant => 'Ожидание участника';

  @override
  String get screenShareStatusActive => 'Трансляция экрана активна';

  @override
  String screenShareSubWaitingAccept(String name) {
    return 'Ожидание ответа от $name…';
  }

  @override
  String get screenShareSubEstablishing =>
      'Установка зашифрованного соединения...';

  @override
  String screenShareSubWaitingJoin(String name) {
    return 'Ожидание подключения $name...';
  }

  @override
  String get screenShareSubActive =>
      'Ваш экран транслируется в высоком разрешении.';

  @override
  String get screenShareBadgeRequesting => 'ЗАПРОС';

  @override
  String get screenShareBadgeConnecting => 'ПОДКЛЮЧЕНИЕ';

  @override
  String get screenShareSharedWith => 'Трансляция для: ';

  @override
  String get screenShareRequestingFrom => 'Запрос к: ';

  @override
  String get screenShareMinimizeTip =>
      'Вы можете свернуть окно и пользоваться приложением.';

  @override
  String get screenShareStop => 'Остановить';

  @override
  String get screenShareCancelRequest => 'Отменить запрос';

  @override
  String screenShareViewerTitle(String name) {
    return '$name показывает экран';
  }

  @override
  String get screenShareViewerLive => 'ПРЯМОЙ ЭФИР';

  @override
  String get screenShareViewerMinimize => 'Свернуть';

  @override
  String get screenShareViewerLeave => 'Выйти';

  @override
  String screenShareViewerWaitingStream(String name) {
    return 'Ожидание трансляции от $name...';
  }

  @override
  String get screenShareViewerConnecting => 'Подключение к трансляции...';

  @override
  String get viewOnceVideoTitle => 'Видео · Разовый просмотр';

  @override
  String get viewOncePhotoTitle => 'Фото · Разовый просмотр';

  @override
  String get viewOnceCantOpen => 'Не удалось открыть файл.';

  @override
  String get viewOnceUnavailable => 'Файл больше недоступен.';

  @override
  String get viewOnceBlockedFooter => 'Скриншоты заблокированы.';

  @override
  String get anonRestoreBanner => 'Показать баннер анонимного чата';

  @override
  String get contactsInviteFriends => 'Пригласить друзей в GupShupGo';

  @override
  String get inviteImageShareFailed =>
      'Не удалось поделиться изображением. Попробуйте ещё раз или отправьте ссылку.';

  @override
  String get viewOnceUnblockedFooter =>
      'Доступно только для разового просмотра.';

  @override
  String get tabMessages => 'Сообщения';
}
