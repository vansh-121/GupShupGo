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
  String get homeNavChats => 'Чаты';

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
}
