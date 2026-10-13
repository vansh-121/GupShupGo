// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonGotIt => 'Entendido';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Elige tu idioma preferido';

  @override
  String get languagePickerTitle => 'Idioma';

  @override
  String get languageSystemDefault => 'Predeterminado del sistema';

  @override
  String get languageSystemDefaultSubtitle => 'Usa el idioma de tu dispositivo';

  @override
  String get loginContinueWithPhone => 'Continuar con teléfono';

  @override
  String get loginContinueWithGoogle => 'Continuar con Google';

  @override
  String get loginUseEmailPassword => 'Usar correo y contraseña';

  @override
  String get loginSignIn => 'Iniciar sesión';

  @override
  String get loginSignUp => 'Registrarse';

  @override
  String get loginCreateAccount => 'Crear cuenta';

  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginOfflineChat => 'Chat sin conexión';

  @override
  String get loginHintName => 'Tu nombre';

  @override
  String get loginHintEmail => 'Correo electrónico';

  @override
  String get loginHintPassword => 'Contraseña';

  @override
  String get loginPasswordHelper =>
      'Al menos 8 caracteres, con una letra y un número';

  @override
  String loginResetEmailSent(String email) {
    return 'Correo de restablecimiento enviado a $email';
  }

  @override
  String get loginErrorEnterEmail => 'Por favor ingresa tu correo electrónico';

  @override
  String get loginErrorValidEmail => 'Por favor ingresa un correo válido';

  @override
  String get loginErrorEnterPassword => 'Por favor ingresa tu contraseña';

  @override
  String get loginErrorPasswordMin6 =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get loginErrorEnterPasswordSignup =>
      'Por favor ingresa una contraseña';

  @override
  String get loginErrorPasswordMin8 =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get loginErrorPasswordLetter => 'La contraseña debe incluir una letra';

  @override
  String get loginErrorPasswordNumber => 'La contraseña debe incluir un número';

  @override
  String get loginErrorEnterName => 'Por favor ingresa tu nombre';

  @override
  String get loginErrorGoogleCancelled =>
      'Se canceló el inicio de sesión con Google.';

  @override
  String get loginErrorProfileLoad =>
      'No se pudo cargar tu perfil. Revisa tu conexión e intenta de nuevo.';

  @override
  String get loginErrorGoogleFailed =>
      'Error al iniciar sesión con Google. Intenta de nuevo.';

  @override
  String get loginErrorSignInFailed =>
      'Error al iniciar sesión. Intenta de nuevo.';

  @override
  String get loginErrorSignUpFailed =>
      'Error al registrarse. Intenta de nuevo.';

  @override
  String get loginErrorGeneric => 'Ocurrió un error. Intenta de nuevo.';

  @override
  String get loginErrorResetFailed =>
      'Error al enviar el correo de restablecimiento. Intenta de nuevo.';

  @override
  String get loginErrorUserNotFound =>
      'No se encontró ninguna cuenta con este correo. Por favor regístrate.';

  @override
  String get loginErrorWrongPassword =>
      'Contraseña incorrecta. Intenta de nuevo.';

  @override
  String get loginErrorEmailInUse =>
      'Ya existe una cuenta con este correo. Por favor inicia sesión.';

  @override
  String get loginErrorInvalidEmail =>
      'Por favor ingresa una dirección de correo válida.';

  @override
  String get loginErrorWeakPassword =>
      'La contraseña es muy débil. Usa al menos 6 caracteres.';

  @override
  String get loginErrorInvalidCredential =>
      'Correo o contraseña incorrectos. Verifica e intenta de nuevo.';

  @override
  String get loginErrorTooManyRequests =>
      'Demasiados intentos. Intenta de nuevo más tarde.';

  @override
  String get homeNavChats => 'Chats';

  @override
  String get homeNavMoments => 'Momentos';

  @override
  String get homeNavCalls => 'Llamadas';

  @override
  String get homeNavProfile => 'Perfil';

  @override
  String get homeTooltipOfflineChat =>
      'Chat sin conexión — habla con personas cercanas';

  @override
  String get homeTooltipSearch => 'Buscar';

  @override
  String get homeMenuProfile => 'Perfil';

  @override
  String get homeMenuSettings => 'Ajustes';

  @override
  String get homeMenuRateUs => 'Califícanos';

  @override
  String get homeMenuReportIssue => 'Reportar problema';

  @override
  String get homeMenuWhatsNew => 'Novedades';

  @override
  String get homeMenuLogOut => 'Cerrar sesión';

  @override
  String get homeEmptyChatsTitle => 'No hay chats todavía';

  @override
  String get homeEmptyChatsSubtitle =>
      'Inicia una conversación tocando el botón de abajo';

  @override
  String get homeNewChatButton => 'Nuevo chat';

  @override
  String get homeAiAssistantTitle => 'GupAI';

  @override
  String get homeAiAssistantSubtitle => 'Redacta, traduce, resume y más';

  @override
  String get homeStrangerMatchTitle => 'Conéctate con un desconocido';

  @override
  String get homeStrangerMatchSubtitle => 'Chat anónimo: ¡toca para conectar!';

  @override
  String get homeMyMoment => 'Mi Momento';

  @override
  String get homeRecentMoments => 'Momentos recientes';

  @override
  String get homeEmptyMomentsTitle => 'No hay actualizaciones aún.';

  @override
  String get homeEmptyMomentsSubtitle => 'Toca la cámara para compartir.';

  @override
  String get homeTapToAddMoment => 'Toca para añadir una actualización';

  @override
  String get homeEmptyCallsTitle => 'Sin historial de llamadas';

  @override
  String get homeEmptyCallsSubtitle => 'Tus llamadas recientes aparecerán aquí';

  @override
  String get chatInputHint => 'Mensaje...';

  @override
  String get chatSearchHint => 'Buscar mensajes...';

  @override
  String get chatStatusTyping => 'escribiendo...';

  @override
  String get chatStatusOnline => 'En línea';

  @override
  String get chatStatusOffline => 'Desconectado';

  @override
  String chatStatusLastSeen(String time) {
    return 'Visto por última vez $time';
  }

  @override
  String get chatEndToEndEncrypted => 'Cifrado de extremo a extremo';

  @override
  String get chatNoInternetOfflineTitle =>
      '¿Sin internet? Chatea sin conexión con dispositivos cercanos';

  @override
  String get chatEnableOfflineButton => 'Activar';

  @override
  String get chatSlideToCancel => 'Desliza para cancelar';

  @override
  String get chatTooltipVoiceCall => 'Llamada de voz';

  @override
  String get chatTooltipVideoCall => 'Videollamada';

  @override
  String get chatMenuContactInfo => 'Info. del contacto';

  @override
  String get chatMenuSearch => 'Buscar';

  @override
  String get chatMenuChatTheme => 'Tema del chat';

  @override
  String get chatMenuExportChat => 'Exportar chat';

  @override
  String get chatMenuMuteNotifications => 'Silenciar notificaciones';

  @override
  String get chatMenuUnmuteNotifications => 'Desactivar silencio';

  @override
  String get chatMenuBlockContact => 'Bloquear contacto';

  @override
  String get chatActionReply => 'Responder';

  @override
  String get chatActionCopy => 'Copiar';

  @override
  String get chatActionForward => 'Reenviar';

  @override
  String get chatActionTranslate => 'Traducir';

  @override
  String get chatActionSummarise => 'Resumir';

  @override
  String get chatActionAskGupAi => 'Preguntar a GupAI';

  @override
  String get chatActionEdit => 'Editar';

  @override
  String get chatActionDelete => 'Eliminar';

  @override
  String get chatDeleteMessageTitle => '¿Eliminar mensaje?';

  @override
  String get chatDeleteMessageForEveryonePrompt =>
      '¿Eliminar solo para ti o para todos en este chat?';

  @override
  String chatDeleteMessageForMeOnlyPrompt(String name) {
    return 'Esto solo lo elimina de tus dispositivos. $name seguirá viéndolo.';
  }

  @override
  String get chatDeleteForMe => 'Eliminar para mí';

  @override
  String get chatDeleteForEveryone => 'Eliminar para todos';

  @override
  String chatBlockContactTitle(String name) {
    return '¿Bloquear a $name?';
  }

  @override
  String get chatBlockContactPrompt =>
      'Los contactos bloqueados no pueden enviarte mensajes ni llamarte. Puedes desbloquearlos en Ajustes → Privacidad.';

  @override
  String get chatBlockButton => 'Bloquear';

  @override
  String get chatForwardTo => 'Reenviar a';

  @override
  String get chatNoForwardChats => 'No hay otros chats para reenviar';

  @override
  String get chatCannotSendMediaBlocked =>
      'No se pueden enviar archivos a este contacto';

  @override
  String get attachmentShareTitle => 'Compartir';

  @override
  String get attachmentPhoto => 'Foto';

  @override
  String get attachmentPhotoSubtitle => 'Elige una imagen de tu galería';

  @override
  String get attachmentVideo => 'Video';

  @override
  String get attachmentVideoSubtitle => 'Elige un video de tu galería';

  @override
  String get attachmentDocument => 'Documento';

  @override
  String get attachmentDocumentSubtitle =>
      'PDF, archivo de Office, archivo comprimido';

  @override
  String get attachmentLocation => 'Ubicación';

  @override
  String get attachmentLocationSubtitle => 'Comparte tu ubicación actual';

  @override
  String get attachmentViewOnce => 'Ver una vez';

  @override
  String get attachmentViewOnceSubtitle =>
      'La foto o video desaparece después de abrirse';

  @override
  String get contactsTitle => 'Contactos y Descubrir';

  @override
  String get contactsTabFriends => 'Amigos';

  @override
  String get contactsTabRequests => 'Solicitudes';

  @override
  String get contactsTabDiscover => 'Descubrir';

  @override
  String get contactsScanQrTooltip => 'Escanear código QR';

  @override
  String get contactsMyHandleTooltip => 'Mi usuario';

  @override
  String get contactsSetUsernamePrompt =>
      'Configura un @nombre en tu perfil primero; eso es lo que comparte tu código QR.';

  @override
  String get contactsMyQrCodeTitle => 'Mi código QR de perfil';

  @override
  String get contactsMyQrCodeSubtitle =>
      'Tus amigos pueden escanear este código QR para conectar contigo al instante';

  @override
  String get contactsCopyProfileLink => 'Copiar enlace de perfil';

  @override
  String contactsProfileLinkCopied(String username) {
    return '¡Enlace de perfil para @$username copiado!';
  }

  @override
  String get contactsScanSomeonesCode => 'Escanear código de alguien';

  @override
  String get contactsPermissionDenied =>
      'Se denegó el permiso para acceder a los contactos.';

  @override
  String get contactsNoUsersFound =>
      'Aún no se encontraron usuarios de GupShupGo en tus contactos.';

  @override
  String contactsFailedToSync(String error) {
    return 'Error al sincronizar contactos: $error';
  }

  @override
  String contactsMatchedCount(int count) {
    return '$count contactos en GupShupGo';
  }

  @override
  String get contactsFromDeviceContacts => 'De los contactos de tu dispositivo';

  @override
  String get contactsLoadFriendsError => 'No se pudieron cargar tus amigos.';

  @override
  String get contactsNoFriendsTitle => 'Aún no has añadido amigos';

  @override
  String get contactsNoFriendsPrompt =>
      '¡Usa la pestaña Descubrir para buscar usuarios por @usuario, teléfono o correo y enviarles solicitud!';

  @override
  String get contactsDiscoverPeopleButton => 'Descubrir personas';

  @override
  String get contactsQuickConnectHeader => 'CONEXIÓN RÁPIDA';

  @override
  String get contactsNoSuggestions =>
      'No hay sugerencias disponibles en este momento.';

  @override
  String get contactsLoadRequestsError =>
      'No se pudieron cargar tus solicitudes.';

  @override
  String contactsPendingRequestsHeader(int count) {
    return 'SOLICITUDES PENDIENTES ($count)';
  }

  @override
  String get contactsNoPendingRequestsTitle => 'No hay solicitudes pendientes';

  @override
  String get contactsNoPendingRequestsSubtitle =>
      'Cuando otros usuarios te envíen solicitudes, aparecerán aquí.';

  @override
  String get contactsWantsToConnect => 'Quiere conectar';

  @override
  String get contactsAcceptButton => 'ACEPTAR';

  @override
  String get contactsAcceptFailed =>
      'No se pudo aceptar la solicitud. Inténtalo de nuevo.';

  @override
  String contactsConnectedWith(String name) {
    return '¡Conectado con $name!';
  }

  @override
  String get contactsDeclineFailed =>
      'No se pudo rechazar la solicitud. Inténtalo de nuevo.';

  @override
  String get contactsYouMightKnowHeader => 'QUIZÁS CONOZCAS';

  @override
  String get contactsSeeAll => 'VER TODOS';

  @override
  String get contactsSearchHint =>
      'Buscar nombre, @usuario, teléfono o correo...';

  @override
  String get contactsTurnOnDiscoverability =>
      'Activa la visibilidad para aparecer en búsquedas y sugerencias.';

  @override
  String get contactsNoMatchingUsersTitle =>
      'No se encontraron usuarios coincidentes';

  @override
  String get contactsNoMatchingUsersSubtitle =>
      'Verifica el @usuario, número de teléfono o correo e inténtalo de nuevo.';

  @override
  String get contactsDiscoverHeroTitle => 'Descubre personas en GupShupGo';

  @override
  String get contactsDiscoverHeroSubtitle =>
      'Amplía tu círculo con conexiones de alta fidelidad en todo el mundo.';

  @override
  String get contactsSyncDeviceContacts =>
      'Sincronizar contactos del dispositivo';

  @override
  String get contactsSyncingContacts => 'Sincronizando contactos...';

  @override
  String get contactsSyncDeviceSubtitle =>
      'Encuentra amigos al instante desde tu agenda';

  @override
  String get contactsSuggestedUsersHeader => 'USUARIOS SUGERIDOS';

  @override
  String get contactsAddFriendButton => 'AÑADIR AMIGO';

  @override
  String get contactsRequestedButton => 'Solicitado';

  @override
  String contactsRequestSent(String name) {
    return '¡Solicitud de amistad enviada a $name!';
  }

  @override
  String get contactsRequestFailed =>
      'La solicitud ya está pendiente o ha fallado.';

  @override
  String get contactsRequestUnavailable =>
      'Esa solicitud ya no está disponible.';

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileSaveButton => 'Guardar';

  @override
  String get profileTapToChangePhoto => 'Toca para cambiar la foto';

  @override
  String get profileUpgradeToPro => 'Mejorar a Pro';

  @override
  String get profileSectionName => 'TU NOMBRE';

  @override
  String get profileNameHint => 'Introduce tu nombre';

  @override
  String get profileSectionHandle => 'NOMBRE DE USUARIO ÚNICO';

  @override
  String get profileHandleNotSet => 'Aún no establecido';

  @override
  String get profileChangeHandle => 'Cambiar';

  @override
  String get profileSectionAbout => 'INFO';

  @override
  String get profileAboutHint => '¿Qué estás pensando?';

  @override
  String get profileDefaultAbout => '¡Hola! Estoy usando GupShupGo.';

  @override
  String get profileSectionPhone => 'TELÉFONO';

  @override
  String get profileSectionEmail => 'CORREO ELECTRÓNICO';

  @override
  String get profileSectionLinkedMethods => 'MÉTODOS DE INICIO VINCULADOS';

  @override
  String get profileNotLinked => 'No vinculado';

  @override
  String get profileNameEmpty => 'El nombre no puede estar vacío.';

  @override
  String get profileUpdatedSuccess => 'Perfil actualizado';

  @override
  String profileUploadPhotoFailed(String error) {
    return 'Error al subir la foto: $error';
  }

  @override
  String profileSaveFailed(String error) {
    return 'Error al guardar el perfil: $error';
  }

  @override
  String get profilePoints => 'Puntos';

  @override
  String get profileBadges => 'Insignias';

  @override
  String get profileBestBond => 'Mejor Racha';

  @override
  String get settingsAccountCard => 'Cuenta';

  @override
  String get settingsProfileTile => 'Perfil';

  @override
  String get settingsLinkedMethodsTile => 'Métodos de inicio vinculados';

  @override
  String get settingsPhoneTile => 'Número de teléfono';

  @override
  String get settingsEmailTile => 'Correo electrónico';

  @override
  String get settingsPrivacyCard => 'Privacidad';

  @override
  String get settingsDiscoverability => 'Visibilidad pública';

  @override
  String get settingsLastSeen => 'Hora de últ. vez';

  @override
  String get settingsReadReceipts => 'Confirmaciones de lectura';

  @override
  String get settingsAdPreferences => 'Preferencias de anuncios';

  @override
  String get settingsManage => 'Gestionar';

  @override
  String get settingsAppearanceCard => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsChatTheme => 'Tema del chat';

  @override
  String get settingsHelpSecurityCard => 'Ayuda y seguridad';

  @override
  String get settingsHelpCenter => 'Centro de ayuda';

  @override
  String get settingsReportProblem => 'Informar de un problema';

  @override
  String get settingsE2EEShield => 'Cifrado de extremo a extremo (Bóveda)';

  @override
  String get settingsVerifySafetyNumber => 'Verificar código de seguridad';

  @override
  String get settingsBlockedContacts => 'Contactos bloqueados';

  @override
  String get settingsClearAllGupHistory => 'Borrar todo el historial de chats';

  @override
  String get settingsRateUs => 'Califícanos';

  @override
  String get settingsWhatsNew => 'Novedades';

  @override
  String get settingsCheckForUpdates => 'Buscar actualizaciones';

  @override
  String get settingsAppInfo => 'Información de la aplicación';

  @override
  String get settingsLogOut => 'Cerrar sesión';

  @override
  String get settingsLogOutConfirmTitle => 'Cerrar sesión';

  @override
  String get settingsLogOutConfirmPrompt =>
      '¿Seguro que quieres cerrar sesión en GupShupGo?';

  @override
  String get settingsSigningOut => 'Cerrando sesión…';

  @override
  String get settingsClearChatsConfirmTitle => 'Borrar todos los chats';

  @override
  String get settingsClearChatsConfirmPrompt =>
      'Esto eliminará permanentemente todo tu historial de mensajes. Esta acción no se puede deshacer.';

  @override
  String get settingsDeleteAll => 'Eliminar todo';

  @override
  String get settingsClearingChats => 'Borrando chats...';

  @override
  String get settingsAllChatsCleared => 'Todos los chats han sido borrados';

  @override
  String settingsClearChatsFailed(String error) {
    return 'Error al borrar chats: $error';
  }

  @override
  String get settingsChooseThemeTitle => 'Elegir tema';

  @override
  String get settingsUnlockPremiumFeatures => 'Desbloquea funciones premium';

  @override
  String settingsProDaysLeft(String planLabel, int daysRemaining) {
    return '$planLabel · Quedan $daysRemaining días';
  }

  @override
  String get settingsCheckingForUpdates => 'Buscando actualizaciones…';

  @override
  String settingsUpToDate(String version) {
    return 'Estás en la última versión (v$version).';
  }

  @override
  String get settingsUpdateCheckUnavailable =>
      'No se pudieron buscar actualizaciones. Asegúrate de instalar GupShupGo desde Google Play Store.';

  @override
  String get settingsNoBlockedContacts => 'No hay contactos bloqueados';

  @override
  String get settingsUnblock => 'Desbloquear';

  @override
  String settingsUserUnblocked(String name) {
    return '$name desbloqueado';
  }

  @override
  String get settingsVerifyContactTitle => 'Verificar un contacto';

  @override
  String get settingsVerifyContactSubtitle =>
      'Selecciona un contacto para ver vuestro código de seguridad compartido.';

  @override
  String get settingsComputingSafetyNumber => 'Calculando código de seguridad…';

  @override
  String settingsSafetyNumberExplanation(String name) {
    return 'Si el número coincide con el dispositivo de $name, el cifrado de extremo a extremo está verificado.';
  }

  @override
  String get settingsSafetyNumberNoBundle =>
      'Este contacto aún no ha publicado un paquete de claves de cifrado.';

  @override
  String get settingsSafetyNumberCompareHint =>
      'Compara este número en persona o mediante una llamada segura.';

  @override
  String get callEndToEndEncrypted => 'Cifrado de extremo a extremo';

  @override
  String get callSecuring => 'Protegiendo llamada…';

  @override
  String get callNotEncrypted => 'No cifrado';

  @override
  String get callIncomingVoice => 'Llamada de voz entrante';

  @override
  String get callIncomingVideo => 'Videollamada entrante';

  @override
  String get callVoiceCall => 'Llamada de voz';

  @override
  String get callVideoCall => 'Videollamada';

  @override
  String get callDecline => 'Rechazar';

  @override
  String get callAccept => 'Aceptar';

  @override
  String get callConnecting => 'Conectando...';

  @override
  String get callSettingUp => 'Configurando llamada...';

  @override
  String callNotifying(String name) {
    return 'Notificando a $name...';
  }

  @override
  String get callRinging => 'Sonando...';

  @override
  String get callConnected => 'Conectado';

  @override
  String get callOnHold => 'En espera';

  @override
  String get callCalling => 'Llamando...';

  @override
  String get callWaitingForUser => 'Esperando al usuario remoto...';

  @override
  String get callEnded => 'Llamada finalizada';

  @override
  String get callDeclined => 'Llamada rechazada';

  @override
  String get callNoAnswer => 'Sin respuesta';

  @override
  String get callFailedToConnect => 'Error al conectar';

  @override
  String callFailedToStart(String error) {
    return 'Error al iniciar llamada: $error';
  }

  @override
  String get callTokenExpired =>
      'Token vencido o inválido. Reinicie la llamada.';

  @override
  String callFailedToInit(String type, String error) {
    return 'Error al inicializar llamada de $type: $error';
  }

  @override
  String get callTurnOffSpeaker => 'Desactivar altavoz';

  @override
  String get callTurnOnSpeaker => 'Activar altavoz';

  @override
  String get callMuteMic => 'Silenciar micrófono';

  @override
  String get callUnmuteMic => 'Activar micrófono';

  @override
  String get callEndCall => 'Finalizar llamada';

  @override
  String get callSwitchCamera => 'Cambiar cámara';

  @override
  String get callTurnOffCamera => 'Apagar cámara';

  @override
  String get callTurnOnCamera => 'Encender cámara';

  @override
  String statusViewedByCount(int count) {
    return 'Visto por $count';
  }

  @override
  String get statusNoViewsYet => 'Sin vistas aún';

  @override
  String statusViewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vistas',
      one: '1 vista',
    );
    return '$_temp0';
  }

  @override
  String get statusDeleteTitle => 'Eliminar estado';

  @override
  String get statusDeleteConfirm => '¿Seguro que deseas eliminar este estado?';

  @override
  String get statusDeleteButton => 'Eliminar';

  @override
  String get statusReplySent => 'Respuesta enviada';

  @override
  String statusReplyFailed(String error) {
    return 'Error al enviar respuesta: $error';
  }

  @override
  String get statusNoActive => 'No hay estados activos';

  @override
  String get statusCouldNotLoad => 'No se pudo cargar la actualización';

  @override
  String get statusTapToRetry => 'Toca para reintentar';

  @override
  String get statusFailedToLoadImage => 'Error al cargar imagen';

  @override
  String get statusLoadingVideo => 'Cargando video...';

  @override
  String get statusEnterTextPrompt => 'Introduce un texto';

  @override
  String get statusNoContactsNotice =>
      'Aún no tienes contactos; inicia un chat antes de publicar un estado.';

  @override
  String statusPostFailed(String error) {
    return 'Error al publicar estado: $error';
  }

  @override
  String get statusTypeHint => 'Escribe un estado...';

  @override
  String get statusCamera => 'Cámara';

  @override
  String get statusTakePhoto => 'Tomar foto';

  @override
  String get statusGalleryPhoto => 'Foto de galería';

  @override
  String get statusChooseImageGallery => 'Elegir foto de galería';

  @override
  String get statusRecordVideo => 'Grabar video';

  @override
  String get statusRecordShortVideo => 'Grabar video corto';

  @override
  String get statusGalleryVideo => 'Video de galería';

  @override
  String get statusChooseVideoGallery => 'Elegir video de galería';

  @override
  String statusFailedPickImage(String error) {
    return 'Error al elegir foto: $error';
  }

  @override
  String statusFailedPickVideo(String error) {
    return 'Error al elegir video: $error';
  }

  @override
  String get statusChangeBgColorTooltip => 'Cambiar color de fondo';

  @override
  String aiMessagesRemaining(int count) {
    return '$count restantes';
  }

  @override
  String get aiQuotaDialogTitle => 'Mensajes GupAI';

  @override
  String aiQuotaRemainingOfTotal(int remaining, int total) {
    return '$remaining de $total restantes hoy';
  }

  @override
  String aiQuotaUsedResetNote(int used) {
    return 'Usados $used hoy · se restablece mañana. Mira un anuncio o suscríbete a Pro.';
  }

  @override
  String get aiQuotaGotIt => 'Entendido';

  @override
  String get aiTitle => 'GupAI';

  @override
  String get aiSubtitle => 'Tu asistente en la app';

  @override
  String get aiEmptyHelpTitle => '¿Cómo puedo ayudarte?';

  @override
  String get aiEmptyHelpSubtitle =>
      'Redacta respuestas, traduce, resume o haz preguntas.';

  @override
  String get meshOfflineChatConnected => 'Chat sin conexión · conectado';

  @override
  String get meshConnecting => 'Conectando…';

  @override
  String get meshBannerNotice =>
      'Chat sin conexión — sin internet ni servidores';

  @override
  String meshSayHiTo(String name) {
    return 'Saluda a $name';
  }

  @override
  String meshOfflineDescription(String name) {
    return 'Estás en el chat sin conexión. Los mensajes quedan entre tú y $name.';
  }

  @override
  String get meshMediaUnavailable => 'Este archivo ya no está disponible.';

  @override
  String get meshViewOnceTitle => 'Ver una vez';

  @override
  String meshViewOncePrompt(String type) {
    return 'Solo puedes abrir este $type una vez.';
  }

  @override
  String get arcadeTabOverview => 'Resumen';

  @override
  String get arcadeTabChallenges => 'Desafíos';

  @override
  String get arcadeTabLeaderboard => 'Clasificación';

  @override
  String get arcadeFailedLoadStats => 'Error al cargar estadísticas.';

  @override
  String get aiAskHint => 'Pregúntale lo que sea a GupAI…';
}
