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
  String get homeNavChats => 'Mensajes';

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
  String get homeMenuPrivateVault => 'Bóveda privada';

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
  String get attachmentScreenShare => 'Compartir pantalla';

  @override
  String get attachmentScreenShareSubtitle =>
      'Muestra tu pantalla en vivo durante el chat';

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

  @override
  String get settingsNotificationsTile => 'Notificaciones';

  @override
  String get settingsNotificationsStatusOn => 'Activado';

  @override
  String get settingsNotificationsStatusOff => 'Desactivado';

  @override
  String get settingsNotificationsEnabledToast =>
      'Las notificaciones están activadas.';

  @override
  String get settingsEnableNotificationsTitle => 'Activar notificaciones';

  @override
  String get settingsEnableNotificationsBody =>
      'Las notificaciones están desactivadas. Abre los ajustes del sistema para permitir que GupShupGo te avise de nuevos mensajes y llamadas.';

  @override
  String get settingsOpenSystemSettings => 'Abrir ajustes';

  @override
  String get loginTagline =>
      'Mensajería privada que funciona incluso sin internet.';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsTerms => 'Condiciones del servicio';

  @override
  String get settingsDeleteAccount => 'Eliminar cuenta';

  @override
  String get inviteSheetTitle => 'Invitar amigos';

  @override
  String get inviteSheetSubtitle => 'Pasa la voz — comparte GupShupGo';

  @override
  String get inviteShareImageBtn => 'Compartir imagen';

  @override
  String get inviteShareLinkBtn => 'Compartir enlace';

  @override
  String get inviteCopyLinkBtn => 'Copiar enlace';

  @override
  String get inviteLinkCopied => 'Enlace de invitación copiado';

  @override
  String inviteMessage(String link) {
    return 'Chatea conmigo en GupShupGo — funciona incluso sin internet 👋 $link';
  }

  @override
  String get inviteCardTagline =>
      'Chat privado que funciona incluso sin conexión';

  @override
  String get inviteCardScan => 'Escanea para descargar';

  @override
  String get inviteCardDownload => 'Descargar en Google Play';

  @override
  String get homeMenuInvite => 'Invitar amigos';

  @override
  String get invitePromptTitle => '¿Te gusta GupShupGo?';

  @override
  String get invitePromptBody =>
      'Es mejor con amigos — y funciona incluso sin internet. ¿Invitas a alguien?';

  @override
  String get invitePromptInvite => 'Invitar amigos';

  @override
  String get invitePromptLater => 'Quizás más tarde';

  @override
  String get homeOfflineBannerTitle => '¿Sin internet? No hay problema';

  @override
  String get homeOfflineBannerSubtitle =>
      'Aún puedes enviar mensajes a personas cercanas por Bluetooth.';

  @override
  String homeNearbyBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas cerca',
      one: '1 persona cerca',
    );
    return '$_temp0';
  }

  @override
  String get homeNearbyBannerSubtitle =>
      'Chatea por Bluetooth — no necesitas internet.';

  @override
  String get linkBackupTitle => 'Añadir método de acceso de respaldo';

  @override
  String get linkBackupSubtitle =>
      'Vincula Google o correo para volver a entrar incluso si tu SIM no está disponible.';

  @override
  String get linkGoogleTitle => 'Vincular cuenta de Google';

  @override
  String get linkGoogleSubtitleLinked => 'Vinculado ✓';

  @override
  String get linkGoogleSubtitleUnlinked => 'Acceso con un toque sin SIM';

  @override
  String get linkGoogleAction => 'Vincular';

  @override
  String get linkGoogleSuccess => '¡Cuenta de Google vinculada con éxito!';

  @override
  String get linkGoogleAlreadyUsed =>
      'Esta cuenta de Google ya está registrada en otra cuenta de GupShupGo.';

  @override
  String get linkGoogleFailed =>
      'Error al vincular Google. Inténtalo de nuevo.';

  @override
  String get linkSessionExpired => 'Sesión expirada. Vuelve a iniciar sesión.';

  @override
  String get linkEmailTitle => 'Vincular correo y contraseña';

  @override
  String get linkEmailSubtitleLinked => 'Vinculado ✓';

  @override
  String get linkEmailSubtitleUnlinked =>
      'Inicia sesión con correo si no tienes SIM ni Google';

  @override
  String get linkEmailActionAdd => 'Añadir';

  @override
  String get linkEmailActionCancel => 'Cancelar';

  @override
  String get linkEmailFieldLabel => 'Correo electrónico';

  @override
  String get linkPasswordFieldLabel => 'Crea una contraseña';

  @override
  String get linkPasswordHelper => 'Mínimo 6 caracteres';

  @override
  String get linkEmailButton => 'Vincular correo';

  @override
  String get linkEmailSuccess => '¡Correo vinculado con éxito!';

  @override
  String get linkEmailInvalid => 'Introduce un correo válido.';

  @override
  String get linkPasswordTooShort =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get linkEmailAlreadyInUse =>
      'Este correo ya está registrado en GupShupGo.';

  @override
  String get linkEmailAlreadyLinked =>
      'Ya hay un correo vinculado a tu cuenta.';

  @override
  String get linkEmailFailed => 'Error al vincular correo. Inténtalo de nuevo.';

  @override
  String get linkContinueToApp => 'Continuar a la app';

  @override
  String get linkSkipForNow => 'Omitir por ahora';

  @override
  String get linkSkip => 'Omitir';

  @override
  String get phoneAuthTitleEntry => 'Inicia sesión con tu número de teléfono.';

  @override
  String get phoneAuthTitleOtp => 'Introduce el código que te enviamos.';

  @override
  String get phoneAuthNameHint => 'Tu nombre';

  @override
  String get phoneAuthPhoneHint => 'Número de teléfono';

  @override
  String get phoneAuthUseSim => 'Usar SIM';

  @override
  String get phoneAuthSendOtp => 'Enviar código';

  @override
  String phoneAuthOtpPrompt(String phone) {
    return 'Introduce el código de 6 dígitos enviado a $phone';
  }

  @override
  String get phoneAuthOtpPromptGeneric =>
      'Introduce el código de 6 dígitos que te enviamos';

  @override
  String get phoneAuthOtpHint => 'Introduce código';

  @override
  String get phoneAuthVerify => 'Verificar';

  @override
  String get phoneAuthGoBack => 'Atrás';

  @override
  String get phoneAuthResendCode => 'Reenviar código';

  @override
  String get phoneAuthEnterName => 'Introduce tu nombre';

  @override
  String get phoneAuthEnterValidPhone =>
      'Introduce un número de teléfono válido';

  @override
  String get phoneAuthEnterCode => 'Introduce el código';

  @override
  String get phoneAuthRequestNewCode => 'Solicita un código nuevo.';

  @override
  String get phoneAuthCodeIncorrect =>
      'El código es incorrecto. Inténtalo de nuevo.';

  @override
  String get phoneAuthErrCodeIncorrect =>
      'Ese código es incorrecto. Compruébalo e inténtalo de nuevo.';

  @override
  String get phoneAuthErrCodeExpired =>
      'El código expiró. Toca \"Reenviar código\" para obtener uno nuevo.';

  @override
  String get phoneAuthErrTooManyRequests =>
      'Demasiados intentos. Espera un momento y vuelve a intentarlo.';

  @override
  String get phoneAuthErrInvalidPhone =>
      'El número de teléfono parece no ser válido.';

  @override
  String get phoneAuthErrQuotaExceeded =>
      'Límite de SMS alcanzado. Inténtalo más tarde.';

  @override
  String get phoneAuthErrFailed => 'Verificación fallida. Inténtalo de nuevo.';

  @override
  String get usernameSetupAppBarTitle => 'Elige tu nombre de usuario';

  @override
  String get usernameSetupHeaderTitle => 'Asegura tu identidad';

  @override
  String get usernameSetupHeaderDesc =>
      'Tu @handle es tu clave única en GupShupGo. Otros pueden buscarte y agregarte sin compartir tu teléfono ni correo.';

  @override
  String get usernameSetupInputHint => 'tu_usuario';

  @override
  String get usernameSetupChecking => 'Comprobando disponibilidad...';

  @override
  String usernameSetupAvailable(String handle) {
    return '¡@$handle está disponible!';
  }

  @override
  String usernameSetupTaken(String handle) {
    return '@$handle ya está en uso.';
  }

  @override
  String get usernameSetupCharRules => '3–20 caracteres (a-z, 0-9, _)';

  @override
  String get usernameSetupTooShort =>
      'El usuario debe tener al menos 3 caracteres.';

  @override
  String get usernameSetupTooLong =>
      'El usuario debe tener como máximo 20 caracteres.';

  @override
  String get usernameSetupInvalidChars =>
      'Solo se permiten letras, números y guiones bajos.';

  @override
  String get usernameSetupRecommended => 'RECOMENDADOS PARA TI';

  @override
  String get usernameSetupSaveBtn => 'Guardar y continuar';

  @override
  String get usernameSetupSkipBtn => 'Omitir por ahora';

  @override
  String usernameSetupFailed(String error) {
    return 'Error al establecer usuario: $error';
  }

  @override
  String get vaultProtectTitle => 'Proteger baúl';

  @override
  String get vaultUnlockTitle => 'Desbloquear baúl';

  @override
  String get vaultSetupDesc =>
      'Elige un PIN para cifrar tu historial de mensajes. Lo necesitarás en un teléfono nuevo.';

  @override
  String get vaultUnlockDescBio =>
      'Introduce tu PIN o huella para descifrar el historial.';

  @override
  String get vaultUnlockDescPin =>
      'Introduce tu PIN para descifrar tu historial.';

  @override
  String get vaultReinstallHint =>
      'Introduce tu PIN para restaurar tu historial en este dispositivo.';

  @override
  String get vaultUnlockWithFingerprint => 'Desbloquear con huella';

  @override
  String get vaultOrDivider => 'O';

  @override
  String get vaultNewPin => 'Nuevo PIN';

  @override
  String get vaultConfirmPin => 'Confirmar PIN';

  @override
  String get vaultEnterPin => 'Introduce PIN';

  @override
  String get vaultKeyboardUseLetters => 'Usar letras';

  @override
  String get vaultKeyboardUseNumbers => 'Usar números';

  @override
  String get vaultRestoreLater => 'Restaurar luego';

  @override
  String get vaultForgotPin => '¿Olvidaste el PIN?';

  @override
  String get vaultSetPinBtn => 'Establecer PIN';

  @override
  String get vaultDecryptBtn => 'Descifrar';

  @override
  String get vaultPinMinLength => 'El PIN debe tener al menos 6 caracteres.';

  @override
  String get vaultPinsDoNotMatch => 'Los PIN no coinciden.';

  @override
  String get vaultSetupFailed =>
      'Configuración fallida. Comprueba la conexión.';

  @override
  String get vaultIncorrectPin => 'PIN incorrecto. Inténtalo de nuevo.';

  @override
  String get vaultFingerprintOutOfDate =>
      'La huella no está actualizada. Introduce tu PIN.';

  @override
  String get vaultBiometricError =>
      'Error biométrico. Introduce el PIN manualmente.';

  @override
  String get vaultBioReasonUnlock =>
      'Autentícate con biometría para desbloquear tu baúl';

  @override
  String get vaultBioReasonEnrol =>
      'Confirma tu huella para habilitar desbloqueo rápido';

  @override
  String get vaultAskBioTitle => '¿Desbloquear con huella?';

  @override
  String get vaultAskBioDesc =>
      'Evita escribir tu PIN en este teléfono. Guarda bien tu PIN para nuevos dispositivos.';

  @override
  String get vaultAskBioNotNow => 'Ahora no';

  @override
  String get vaultAskBioEnable => 'Activar';

  @override
  String get vaultDeleteMessagesTitle => '¿Eliminar todos los mensajes?';

  @override
  String get vaultDeleteMessagesDesc =>
      'Sin tu PIN tu historial no se puede descifrar, por lo que restablecer borrará todo. No se puede deshacer.';

  @override
  String get vaultDeleteMessagesCancel => 'Cancelar';

  @override
  String get vaultDeleteMessagesConfirm => 'Eliminar todo';

  @override
  String get vaultCustodyConfirmTitle => 'Confirma el PIN de tu baúl';

  @override
  String get vaultCustodyChooseTitle => 'Elige un PIN';

  @override
  String get vaultCustodyConfirmDesc =>
      'Tu historial está cifrado con un PIN. Confírmalo una vez.';

  @override
  String get vaultCustodyChooseDesc =>
      'Elige un PIN que recuerdes. Tus mensajes se volverán a cifrar con el nuevo PIN.';

  @override
  String get vaultCustodyDontKnow => 'No sé mi PIN';

  @override
  String get vaultCustodyConfirmBtn => 'Confirmar';

  @override
  String get vaultCustodySaveBtn => 'Guardar PIN';

  @override
  String get vaultCustodyMismatchError => 'Ese PIN no coincide.';

  @override
  String get vaultCustodyAutoUpdateFailed =>
      'No se pudo actualizar el PIN automáticamente.';

  @override
  String vaultCustodyReencrypting(int done, int total) {
    return 'Cifrando $done de $total… mantén la app abierta.';
  }

  @override
  String get vaultCustodyPreparing => 'Preparando… mantén la app abierta.';

  @override
  String get vaultSettingsTitle => 'Baúl';

  @override
  String get vaultSettingsAboutTitle => 'Acerca del baúl';

  @override
  String get vaultSettingsAboutDesc =>
      'Copia de seguridad privada de tus chats, bloqueada con tu PIN. Solo tu PIN puede abrirlo.';

  @override
  String get vaultSettingsBulletMessages => 'Tus mensajes';

  @override
  String get vaultSettingsBulletStatuses => 'Estados que puedes ver';

  @override
  String get vaultSettingsNeverKept =>
      'Nunca se guarda aquí: historial de llamadas, contactos o fotos de chats.';

  @override
  String get vaultSettingsSectionPrivacy => 'PRIVACIDAD';

  @override
  String get vaultSettingsAutoDelete => 'Auto-eliminar mensajes antiguos';

  @override
  String get vaultSettingsKeepForever => 'Conservar siempre';

  @override
  String vaultSettingsDeleteAfter(String label) {
    return 'Eliminar tras $label';
  }

  @override
  String get vaultSettingsSectionPin => 'PIN';

  @override
  String get vaultSettingsChangePin => 'Cambiar PIN';

  @override
  String get vaultSettingsChangePinSubtitle =>
      'Vuelve a cifrar todo el contenido del baúl';

  @override
  String get vaultSettingsBioTitle => 'Desbloquear con huella';

  @override
  String get vaultSettingsBioSubOn => 'Activado en este dispositivo';

  @override
  String get vaultSettingsBioSubOff =>
      'Evita escribir el PIN en este dispositivo';

  @override
  String get vaultSettingsSectionDanger => 'ZONA DE PELIGRO';

  @override
  String get vaultSettingsDeleteData => 'Eliminar datos del baúl';

  @override
  String get vaultSettingsDeleteDataSubtitle =>
      'Borra el historial cifrado, conserva el PIN';

  @override
  String get vaultSettingsResetVault => 'Restablecer baúl';

  @override
  String get vaultSettingsResetVaultSubtitle => 'Olvida el PIN y borra todo';

  @override
  String get vaultSettingsPinChanged => 'PIN cambiado.';

  @override
  String get vaultSettingsBioTurnedOff => 'Desbloqueo por huella desactivado.';

  @override
  String get vaultSettingsBioTurnedOn => 'Desbloqueo por huella activado.';

  @override
  String get vaultSettingsClearDataTitle => '¿Eliminar datos del baúl?';

  @override
  String get vaultSettingsClearDataDesc =>
      'Elimina los mensajes cifrados de la nube. Tu PIN se conserva.';

  @override
  String get vaultSettingsClearDataCancel => 'Cancelar';

  @override
  String get vaultSettingsClearDataConfirm => 'Eliminar datos';

  @override
  String get vaultSettingsDataDeleted => 'Datos del baúl eliminados.';

  @override
  String get vaultSettingsResetTitle => '¿Restablecer baúl?';

  @override
  String get vaultSettingsResetDesc =>
      'Elimina tu PIN y todos los mensajes. Deberás configurar un PIN nuevo.';

  @override
  String get vaultSettingsResetConfirm => 'Restablecer';

  @override
  String get vaultSettingsChangeDialogDesc =>
      'Todo se cifrará de nuevo con el nuevo PIN. Mantén la app abierta.';

  @override
  String get vaultSettingsCurrentPin => 'PIN actual';

  @override
  String get vaultSettingsNewPin => 'Nuevo PIN';

  @override
  String get vaultSettingsConfirmNewPin => 'Confirmar nuevo PIN';

  @override
  String get vaultSettingsEnterCurrentPin => 'Introduce tu PIN actual.';

  @override
  String get vaultSettingsNewPinMinLength =>
      'El nuevo PIN debe tener al menos 6 caracteres.';

  @override
  String get vaultSettingsNewPinMismatch => 'Los nuevos PIN no coinciden.';

  @override
  String get vaultSettingsCurrentPinIncorrect => 'El PIN actual es incorrecto.';

  @override
  String vaultSettingsReencryptingCount(int done, int total) {
    return 'Cifrando $done de $total…';
  }

  @override
  String get vaultSettingsChangeBtn => 'Cambiar';

  @override
  String get vaultSettingsBioPinDialogTitle => 'Introduce tu PIN';

  @override
  String get vaultSettingsBioPinDialogDesc =>
      'Se necesita tu PIN para habilitar el desbloqueo con huella.';

  @override
  String get vaultSettingsContinueBtn => 'Continuar';

  @override
  String get premiumTitle => 'GupShupGo Pro';

  @override
  String get premiumSubtitleMember => '¡Eres miembro Pro! 🎉';

  @override
  String get premiumSubtitleUnlock => 'Desbloquea la experiencia completa';

  @override
  String premiumActiveDaysRemaining(int days) {
    return '$days días restantes';
  }

  @override
  String get premiumFeaturesHeader => 'Lo que obtienes con Pro';

  @override
  String get premiumPlansHeader => 'Elige tu plan';

  @override
  String get premiumSubscribeBtn => 'Suscribirse ahora';

  @override
  String get premiumCancelAnytime =>
      'Cancela en cualquier momento desde Google Play.';

  @override
  String get premiumRestoreBtn => 'Restaurar compra anterior';

  @override
  String get premiumRestoring => 'Restaurando…';

  @override
  String get premiumRestoredSuccess => '¡Suscripción Pro restaurada! 🎉';

  @override
  String get premiumNoActiveSub => 'No se encontró ninguna suscripción activa.';

  @override
  String get premiumProductUnavailable => 'Producto no disponible.';

  @override
  String get premiumFeatureMediaTitle => 'Momentos Multimedia';

  @override
  String get premiumFeatureMediaDesc => 'Comparte fotos y vídeos como estados';

  @override
  String get premiumFeatureMediaFree => 'Solo texto';

  @override
  String get premiumFeatureMediaPro => 'Fotos + Vídeos';

  @override
  String get premiumFeatureScreenShareTitle => 'Compartir pantalla';

  @override
  String get premiumFeatureScreenShareDesc =>
      'Comparte tu pantalla en directo durante chats';

  @override
  String get premiumFeatureScreenShareFree => 'Bloqueado';

  @override
  String get premiumFeatureScreenSharePro => 'Acceso total';

  @override
  String get premiumFeatureThemesTitle => 'Temas de chat';

  @override
  String get premiumFeatureThemesDesc =>
      'Fondos y burbujas con degradados por chat';

  @override
  String get premiumFeatureThemesFree => '6 temas';

  @override
  String get premiumFeatureThemesPro => 'Los 12 + tu propia foto';

  @override
  String get premiumFeatureVoiceTitle => 'Mensajes de voz más largos';

  @override
  String get premiumFeatureVoiceDesc => 'Graba notas de voz de mayor duración';

  @override
  String get premiumFeatureVoiceFree => '2 minutos';

  @override
  String get premiumFeatureVoicePro => 'Ilimitado';

  @override
  String get premiumFeatureQualityTitle => 'Mayor calidad multimedia';

  @override
  String get premiumFeatureQualityDesc =>
      'Fotos más nítidas y vídeos de estado de 90s';

  @override
  String get premiumFeatureQualityFree => 'Calidad estándar';

  @override
  String get premiumFeatureQualityPro => 'Alta calidad + vídeos 90s';

  @override
  String get premiumFeatureBondTitle => 'Restaurar vínculo';

  @override
  String get premiumFeatureBondDesc => 'Restaura vínculos rotos gratis';

  @override
  String get premiumFeatureBondFree => 'Puntos o ver anuncio';

  @override
  String get premiumFeatureBondPro => '1 restauración gratis/semana';

  @override
  String get premiumFeatureBadgeTitle => 'Insignia Pro';

  @override
  String get premiumFeatureBadgeDesc => 'Presume de tu estatus Pro';

  @override
  String get premiumFeatureBadgeFree => 'Sin insignia';

  @override
  String get premiumFeatureBadgePro => 'Insignia Pro exclusiva';

  @override
  String get premiumFeatureExportTitle => 'Exportar chat';

  @override
  String get premiumFeatureExportDesc => 'Guarda chats en PDF o texto plano';

  @override
  String get premiumFeatureExportFree => 'No disponible';

  @override
  String get premiumFeatureExportPro => 'Exportación PDF y TXT';

  @override
  String get premiumFeatureAdFreeTitle => 'Sin anuncios';

  @override
  String get premiumFeatureAdFreeDesc => 'Sin anuncios de banner en la app';

  @override
  String get premiumFeatureAdFreeFree => 'Banners mostrados';

  @override
  String get premiumFeatureAdFreePro => 'Sin banners';

  @override
  String get premiumPlanMonthly => 'Mensual';

  @override
  String get premiumPlanYearly => 'Anual';

  @override
  String get premiumPlanSavings => 'Ahorra ~33%';

  @override
  String get premiumPeriodMonth => '/mes';

  @override
  String get premiumPeriodYear => '/año';

  @override
  String get nearbyOfflineChatTitle => 'Chat sin conexión';

  @override
  String get nearbySearchingDevices => 'Buscando dispositivos cercanos…';

  @override
  String get nearbyTooltipStop => 'Detener chat sin conexión';

  @override
  String get nearbyTooltipStart => 'Iniciar chat sin conexión';

  @override
  String get nearbyDevicesSection => 'Dispositivos cercanos';

  @override
  String get nearbyDiscoveryOn => 'BÚSQUEDA ACTIVA';

  @override
  String get nearbyDiscoveryOff => 'BÚSQUEDA INACTIVA';

  @override
  String get nearbyHeroTitle => 'Modo sin conexión';

  @override
  String nearbyHeroNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cercanos',
      one: '1 cercano',
    );
    return '$_temp0';
  }

  @override
  String get nearbyHeroOff => 'Chat sin conexión desactivado';

  @override
  String get nearbyHeroDesc =>
      'Buscando en un radio de 100 m. Conexiones cifradas y directas.';

  @override
  String get nearbyYourNameHint => 'Tu nombre';

  @override
  String get nearbyEmptySearching => 'Buscando dispositivos cercanos…';

  @override
  String get nearbyEmptyOff => 'El chat sin conexión está desactivado';

  @override
  String get nearbyEmptySearchingDesc =>
      'Asegúrate de tener GupShupGo abierto con Bluetooth activo.';

  @override
  String get nearbyEmptyOffDesc =>
      'Toca el icono de inicio arriba a la derecha para escanear.';

  @override
  String get nearbyPeerConnected => 'Conectado · Toca para chatear';

  @override
  String get nearbyPeerConnecting => 'Conectando…';

  @override
  String get nearbyPeerTapToConnect => 'Toca para conectar';

  @override
  String get nearbyActionChat => 'Chat';

  @override
  String get nearbyActionConnecting => 'Conectando';

  @override
  String get nearbyActionConnect => 'Conectar';

  @override
  String get nearbyPermNeededTitle => 'Permisos necesarios';

  @override
  String get nearbyPermNeededDesc =>
      'El chat sin conexión necesita acceso a Bluetooth y dispositivos cercanos.';

  @override
  String get nearbyTryAgainBtn => 'Reintentar';

  @override
  String get nearbySettingsBtn => 'Ajustes';

  @override
  String get nearbyHelpTip =>
      '¿No ves a tu amigo? Aseguraos de tener el Bluetooth activado.';

  @override
  String get anonLobbyTitle => 'Chat anónimo';

  @override
  String get anonLobbyFinding => 'Buscando a alguien para ti…';

  @override
  String get anonLobbyHangTight =>
      'Espera un momento — te conectaremos con un desconocido.';

  @override
  String get anonLobbyCancelBtn => 'Cancelar búsqueda';

  @override
  String get anonLobbyPrivacyNote => 'Tu identidad se mantiene oculta.';

  @override
  String get anonLobbyConnecting => 'Conectando…';

  @override
  String get anonLobbyWaitingOthers => 'Esperando a que otros se conecten…';

  @override
  String anonLobbyOnlineCount(int count) {
    return '$count conectados ahora';
  }

  @override
  String get anonChatNotEncrypted =>
      'Los mensajes no están cifrados de extremo a extremo';

  @override
  String get anonChatRequestSentTooltip => 'Solicitud enviada';

  @override
  String get anonChatAddFriendTooltip => 'Añadir amigo';

  @override
  String get anonChatNextStrangerTooltip => 'Siguiente desconocido';

  @override
  String get anonChatReportTooltip => 'Reportar';

  @override
  String get anonChatSayHi => '¡Saluda al desconocido! 👋';

  @override
  String get anonChatFriendsTransition =>
      '¡Ahora sois amigos! Abriendo chat seguro…';

  @override
  String get anonChatStrangerDisconnected =>
      'El desconocido se ha desconectado 👋';

  @override
  String get anonChatFindNextBtn => 'Buscar siguiente desconocido';

  @override
  String get anonChatFriendReqTitle => '¡El desconocido quiere conectar!';

  @override
  String get anonChatFriendReqDesc =>
      'Aceptar revelará tu perfil real y abrirá un chat cifrado.';

  @override
  String get anonChatDecline => 'Rechazar';

  @override
  String get anonChatAccept => 'Aceptar';

  @override
  String get anonChatWaitingReqTitle => 'Solicitud de amistad enviada';

  @override
  String get anonChatWaitingReqDesc => 'Esperando respuesta del desconocido…';

  @override
  String get anonChatReportTitle => 'Reportar desconocido';

  @override
  String get anonChatReportQuestion => '¿Por qué reportas a este usuario?';

  @override
  String get anonChatReportReasonInappropriate => 'Contenido inapropiado';

  @override
  String get anonChatReportReasonHarassment => 'Acoso o intimidación';

  @override
  String get anonChatReportReasonSpam => 'Spam o estafa';

  @override
  String get anonChatReportReasonThreatening => 'Comportamiento amenazante';

  @override
  String get anonChatReportReasonOther => 'Otro';

  @override
  String get anonChatReportCancel => 'Cancelar';

  @override
  String get anonChatReportSubmit => 'Reportar y salir';

  @override
  String get anonChatReportSubmitted =>
      'Reporte enviado. Gracias por mantener seguro GupShupGo.';

  @override
  String get anonChatViewOnceVideoTitle => '¿Reproducir una vez?';

  @override
  String get anonChatViewOncePhotoTitle => '¿Abrir una vez?';

  @override
  String get anonChatViewOnceVideoDesc =>
      'Solo puedes abrir este vídeo una vez. Desaparecerá al cerrarlo.';

  @override
  String get anonChatViewOncePhotoDesc =>
      'Solo puedes abrir esta foto una vez. Desaparecerá al cerrarla.';

  @override
  String get anonChatViewOnceCancel => 'Cancelar';

  @override
  String get anonChatViewOnceOpen => 'Abrir';

  @override
  String get unsupportedVersionTitle => 'Actualiza GupShupGo';

  @override
  String get unsupportedVersionDesc =>
      'Esta versión ya no es compatible. Actualiza para seguir chateando.';

  @override
  String get unsupportedVersionUpdateNow => 'Actualizar ahora';

  @override
  String get unsupportedVersionOpenPlayStore => 'Abrir Play Store';

  @override
  String publicProfileNotFound(String username) {
    return '@$username no encontrado';
  }

  @override
  String get publicProfileUserNotFound => 'Usuario no encontrado';

  @override
  String get publicProfileNotFoundDesc =>
      'Este usuario no existe o el enlace está roto.';

  @override
  String get publicProfileTitle => 'Perfil';

  @override
  String get publicProfileOnline => 'En línea';

  @override
  String publicProfileLastSeen(String time) {
    return 'Últ. vez $time';
  }

  @override
  String get publicProfileJustNow => 'ahora mismo';

  @override
  String publicProfileMinutesAgo(int minutes) {
    return 'hace $minutes m';
  }

  @override
  String publicProfileHoursAgo(int hours) {
    return 'hace $hours h';
  }

  @override
  String publicProfileDaysAgo(int days) {
    return 'hace $days d';
  }

  @override
  String publicProfileJoined(String date) {
    return 'Se unió en $date';
  }

  @override
  String get publicProfileOwnLink => 'Este es tu propio enlace de perfil.';

  @override
  String publicProfileGupPoints(int points) {
    return '$points Puntos Gup';
  }

  @override
  String publicProfileLevel(int level) {
    return 'Nivel $level';
  }

  @override
  String get publicProfileStatPoints => 'Puntos';

  @override
  String get publicProfileStatBadges => 'Insignias';

  @override
  String get publicProfileStatBestBond => 'Mejor vínculo';

  @override
  String get publicProfileBadges => 'INSIGNIAS';

  @override
  String get qrScannerTitle => 'Escanear código QR';

  @override
  String get qrScannerFlashOnTooltip => 'Activar flash';

  @override
  String get qrScannerFlashOffTooltip => 'Desactivar flash';

  @override
  String get qrScannerPrompt => 'Apunta la cámara a un código QR de GupShupGo';

  @override
  String get qrScannerNotProfileCode =>
      'No es un código de perfil de GupShupGo.';

  @override
  String get qrScannerCameraErrorTitle => 'No se pudo iniciar la cámara.';

  @override
  String get qrScannerCameraErrorRetry => 'Inténtalo de nuevo.';

  @override
  String get qrScannerPermissionMsg =>
      'Se necesita permiso de cámara para escanear.';

  @override
  String get qrScannerPermissionAllow => 'Permitir cámara';

  @override
  String get qrScannerBlockedMsg =>
      'La cámara está bloqueada. Actívala en Ajustes.';

  @override
  String get qrScannerBlockedSettings => 'Abrir ajustes';

  @override
  String get screenShareIncomingTitle => 'Pantalla compartida entrante';

  @override
  String get screenShareWantsToShare => 'quiere compartir su pantalla';

  @override
  String get screenShareReject => 'Rechazar';

  @override
  String get screenShareAccept => 'Aceptar';

  @override
  String get screenShareCantAccept =>
      'No se pudo aceptar. Comprueba tu conexión.';

  @override
  String screenShareDeclined(String name) {
    return '$name rechazó tu pantalla compartida';
  }

  @override
  String get screenShareNoAnswer => 'Sin respuesta';

  @override
  String get screenShareStartError =>
      'No se pudo iniciar la pantalla compartida';

  @override
  String get screenShareStatusRequesting => 'Solicitando permiso';

  @override
  String get screenShareStatusInitializing => 'Iniciando transmisión';

  @override
  String get screenShareStatusWaitingParticipant => 'Esperando al participante';

  @override
  String get screenShareStatusActive => 'Pantalla compartida activa';

  @override
  String screenShareSubWaitingAccept(String name) {
    return 'Esperando a que $name acepte…';
  }

  @override
  String get screenShareSubEstablishing => 'Estableciendo conexión cifrada...';

  @override
  String screenShareSubWaitingJoin(String name) {
    return 'Esperando a que $name se una...';
  }

  @override
  String get screenShareSubActive =>
      'Tu pantalla completa es visible en alta definición.';

  @override
  String get screenShareBadgeRequesting => 'SOLICITANDO';

  @override
  String get screenShareBadgeConnecting => 'CONECTANDO';

  @override
  String get screenShareSharedWith => 'Compartida con ';

  @override
  String get screenShareRequestingFrom => 'Solicitando a ';

  @override
  String get screenShareMinimizeTip =>
      'Puedes minimizar esta pantalla para seguir usando GupShupGo.';

  @override
  String get screenShareStop => 'Dejar de compartir';

  @override
  String get screenShareCancelRequest => 'Cancelar solicitud';

  @override
  String screenShareViewerTitle(String name) {
    return '$name está compartiendo';
  }

  @override
  String get screenShareViewerLive => 'EN DIRECTO';

  @override
  String get screenShareViewerMinimize => 'Minimizar';

  @override
  String get screenShareViewerLeave => 'Salir';

  @override
  String screenShareViewerWaitingStream(String name) {
    return 'Esperando a que $name transmita la pantalla...';
  }

  @override
  String get screenShareViewerConnecting => 'Conectando a la transmisión...';

  @override
  String get viewOnceVideoTitle => 'Vídeo · Ver una vez';

  @override
  String get viewOncePhotoTitle => 'Foto · Ver una vez';

  @override
  String get viewOnceCantOpen => 'No se pudo abrir este archivo.';

  @override
  String get viewOnceUnavailable => 'Este archivo ya no está disponible.';

  @override
  String get viewOnceBlockedFooter => 'Capturas de pantalla bloqueadas.';

  @override
  String get anonRestoreBanner => 'Mostrar el banner de chat anónimo';

  @override
  String get contactsInviteFriends => 'Invita a tus amigos a GupShupGo';

  @override
  String get inviteImageShareFailed =>
      'No se pudo compartir la imagen. Inténtalo de nuevo o comparte el enlace.';

  @override
  String get viewOnceUnblockedFooter =>
      'No se puede volver a abrir. En iOS no se pueden bloquear capturas.';

  @override
  String get tabMessages => 'Mensajes';
}
