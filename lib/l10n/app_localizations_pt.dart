// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonOk => 'OK';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonGotIt => 'Entendi';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Escolha seu idioma preferido';

  @override
  String get languagePickerTitle => 'Idioma';

  @override
  String get languageSystemDefault => 'Padrão do sistema';

  @override
  String get languageSystemDefaultSubtitle => 'Usar o idioma do dispositivo';

  @override
  String get loginContinueWithPhone => 'Continuar com telefone';

  @override
  String get loginContinueWithGoogle => 'Continuar com o Google';

  @override
  String get loginUseEmailPassword => 'Usar e-mail e senha';

  @override
  String get loginSignIn => 'Entrar';

  @override
  String get loginSignUp => 'Cadastre-se';

  @override
  String get loginCreateAccount => 'Criar conta';

  @override
  String get loginForgotPassword => 'Esqueceu a senha?';

  @override
  String get loginOfflineChat => 'Chat offline';

  @override
  String get loginHintName => 'Seu nome';

  @override
  String get loginHintEmail => 'E-mail';

  @override
  String get loginHintPassword => 'Senha';

  @override
  String get loginPasswordHelper =>
      'Pelo menos 8 caracteres, com uma letra e um número';

  @override
  String loginResetEmailSent(String email) {
    return 'E-mail de redefinição de senha enviado para $email';
  }

  @override
  String get loginErrorEnterEmail => 'Por favor, insira seu e-mail';

  @override
  String get loginErrorValidEmail => 'Por favor, insira um e-mail válido';

  @override
  String get loginErrorEnterPassword => 'Por favor, insira sua senha';

  @override
  String get loginErrorPasswordMin6 =>
      'A senha deve ter pelo menos 6 caracteres';

  @override
  String get loginErrorEnterPasswordSignup => 'Por favor, insira uma senha';

  @override
  String get loginErrorPasswordMin8 =>
      'A senha deve ter pelo menos 8 caracteres';

  @override
  String get loginErrorPasswordLetter => 'A senha deve incluir uma letra';

  @override
  String get loginErrorPasswordNumber => 'A senha deve incluir um número';

  @override
  String get loginErrorEnterName => 'Por favor, insira seu nome';

  @override
  String get loginErrorGoogleCancelled => 'O login com o Google foi cancelado.';

  @override
  String get loginErrorProfileLoad =>
      'Não foi possível carregar seu perfil. Verifique sua conexão e tente novamente.';

  @override
  String get loginErrorGoogleFailed =>
      'Falha no login com o Google. Tente novamente.';

  @override
  String get loginErrorSignInFailed => 'Falha ao entrar. Tente novamente.';

  @override
  String get loginErrorSignUpFailed => 'Falha ao cadastrar. Tente novamente.';

  @override
  String get loginErrorGeneric => 'Ocorreu um erro. Tente novamente.';

  @override
  String get loginErrorResetFailed =>
      'Falha ao enviar e-mail de redefinição. Tente novamente.';

  @override
  String get loginErrorUserNotFound =>
      'Nenhuma conta encontrada com este e-mail. Cadastre-se.';

  @override
  String get loginErrorWrongPassword => 'Senha incorreta. Tente novamente.';

  @override
  String get loginErrorEmailInUse =>
      'Já existe uma conta com este e-mail. Faça login.';

  @override
  String get loginErrorInvalidEmail =>
      'Por favor, insira um endereço de e-mail válido.';

  @override
  String get loginErrorWeakPassword =>
      'Senha muito fraca. Use pelo menos 6 caracteres.';

  @override
  String get loginErrorInvalidCredential =>
      'E-mail ou senha inválidos. Verifique e tente novamente.';

  @override
  String get loginErrorTooManyRequests =>
      'Muitas tentativas. Tente novamente mais tarde.';

  @override
  String get homeNavChats => 'Conversas';

  @override
  String get homeNavMoments => 'Momentos';

  @override
  String get homeNavCalls => 'Chamadas';

  @override
  String get homeNavProfile => 'Perfil';

  @override
  String get homeTooltipOfflineChat =>
      'Chat offline — converse com pessoas próximas';

  @override
  String get homeTooltipSearch => 'Pesquisar';

  @override
  String get homeMenuProfile => 'Perfil';

  @override
  String get homeMenuSettings => 'Configurações';

  @override
  String get homeMenuRateUs => 'Avalie-nos';

  @override
  String get homeMenuReportIssue => 'Relatar problema';

  @override
  String get homeMenuWhatsNew => 'Novidades';

  @override
  String get homeMenuLogOut => 'Sair';

  @override
  String get homeEmptyChatsTitle => 'Nenhuma conversa ainda';

  @override
  String get homeEmptyChatsSubtitle =>
      'Inicie uma conversa tocando no botão abaixo';

  @override
  String get homeNewChatButton => 'Nova conversa';

  @override
  String get homeAiAssistantTitle => 'GupAI';

  @override
  String get homeAiAssistantSubtitle => 'Escreva, traduza, resuma e muito mais';

  @override
  String get homeStrangerMatchTitle => 'Conecte-se com um estranho';

  @override
  String get homeStrangerMatchSubtitle => 'Chat anônimo — toque para combinar!';

  @override
  String get homeMyMoment => 'Meu Momento';

  @override
  String get homeRecentMoments => 'Momentos recentes';

  @override
  String get homeEmptyMomentsTitle => 'Nenhuma atualização ainda.';

  @override
  String get homeEmptyMomentsSubtitle => 'Toque na câmera para compartilhar.';

  @override
  String get homeTapToAddMoment => 'Toque para adicionar uma atualização';

  @override
  String get homeEmptyCallsTitle => 'Nenhum histórico de chamadas';

  @override
  String get homeEmptyCallsSubtitle => 'Suas chamadas recentes aparecerão aqui';

  @override
  String get chatInputHint => 'Mensagem...';

  @override
  String get chatSearchHint => 'Pesquisar mensagens...';

  @override
  String get chatStatusTyping => 'digitando...';

  @override
  String get chatStatusOnline => 'Online';

  @override
  String get chatStatusOffline => 'Offline';

  @override
  String chatStatusLastSeen(String time) {
    return 'Visto por último $time';
  }

  @override
  String get chatEndToEndEncrypted => 'Criptografado de ponta a ponta';

  @override
  String get chatNoInternetOfflineTitle =>
      'Sem internet? Converse offline com aparelhos próximos';

  @override
  String get chatEnableOfflineButton => 'Ativar';

  @override
  String get chatSlideToCancel => 'Deslize para cancelar';

  @override
  String get chatTooltipVoiceCall => 'Chamada de voz';

  @override
  String get chatTooltipVideoCall => 'Chamada de vídeo';

  @override
  String get chatMenuContactInfo => 'Dados do contato';

  @override
  String get chatMenuSearch => 'Pesquisar';

  @override
  String get chatMenuChatTheme => 'Tema da conversa';

  @override
  String get chatMenuExportChat => 'Exportar conversa';

  @override
  String get chatMenuMuteNotifications => 'Silenciar notificações';

  @override
  String get chatMenuUnmuteNotifications => 'Desativar silêncio';

  @override
  String get chatMenuBlockContact => 'Bloquear contato';

  @override
  String get chatActionReply => 'Responder';

  @override
  String get chatActionCopy => 'Copiar';

  @override
  String get chatActionForward => 'Encaminhar';

  @override
  String get chatActionTranslate => 'Traduzir';

  @override
  String get chatActionSummarise => 'Resumir';

  @override
  String get chatActionAskGupAi => 'Perguntar ao GupAI';

  @override
  String get chatActionEdit => 'Editar';

  @override
  String get chatActionDelete => 'Excluir';

  @override
  String get chatDeleteMessageTitle => 'Excluir mensagem?';

  @override
  String get chatDeleteMessageForEveryonePrompt =>
      'Excluir apenas para você ou para todos nesta conversa?';

  @override
  String chatDeleteMessageForMeOnlyPrompt(String name) {
    return 'Isso remove apenas dos seus dispositivos. $name ainda verá.';
  }

  @override
  String get chatDeleteForMe => 'Excluir para mim';

  @override
  String get chatDeleteForEveryone => 'Excluir para todos';

  @override
  String chatBlockContactTitle(String name) {
    return 'Bloquear $name?';
  }

  @override
  String get chatBlockContactPrompt =>
      'Contatos bloqueados não podem enviar mensagens nem ligar para você. Você pode desbloqueá-los em Configurações → Privacidade.';

  @override
  String get chatBlockButton => 'Bloquear';

  @override
  String get chatForwardTo => 'Encaminhar para';

  @override
  String get chatNoForwardChats => 'Nenhuma outra conversa para encaminhar';

  @override
  String get chatCannotSendMediaBlocked =>
      'Não é possível enviar mídia para este contato';

  @override
  String get attachmentShareTitle => 'Compartilhar';

  @override
  String get attachmentPhoto => 'Foto';

  @override
  String get attachmentPhotoSubtitle => 'Escolha uma imagem da sua galeria';

  @override
  String get attachmentVideo => 'Vídeo';

  @override
  String get attachmentVideoSubtitle => 'Escolha um vídeo da sua galeria';

  @override
  String get attachmentDocument => 'Documento';

  @override
  String get attachmentDocumentSubtitle =>
      'PDF, arquivo do Office, arquivo compactado';

  @override
  String get attachmentLocation => 'Localização';

  @override
  String get attachmentLocationSubtitle => 'Compartilhe sua localização atual';

  @override
  String get attachmentViewOnce => 'Visualização única';

  @override
  String get attachmentViewOnceSubtitle =>
      'A foto ou o vídeo desaparece após ser aberto';

  @override
  String get contactsTitle => 'Contatos e Descobrir';

  @override
  String get contactsTabFriends => 'Amigos';

  @override
  String get contactsTabRequests => 'Pedidos';

  @override
  String get contactsTabDiscover => 'Descobrir';

  @override
  String get contactsScanQrTooltip => 'Escanear código QR';

  @override
  String get contactsMyHandleTooltip => 'Meu identificador';

  @override
  String get contactsSetUsernamePrompt =>
      'Defina um @nome_de_usuario no seu perfil primeiro — é isso que seu código QR compartilha.';

  @override
  String get contactsMyQrCodeTitle => 'QR Code do meu perfil';

  @override
  String get contactsMyQrCodeSubtitle =>
      'Seus amigos podem ler este QR code para se conectar instantaneamente';

  @override
  String get contactsCopyProfileLink => 'Copiar link do perfil';

  @override
  String contactsProfileLinkCopied(String username) {
    return 'Link do perfil de @$username copiado!';
  }

  @override
  String get contactsScanSomeonesCode => 'Escanear código de alguém';

  @override
  String get contactsPermissionDenied =>
      'Permissão para acessar os contatos foi negada.';

  @override
  String get contactsNoUsersFound =>
      'Nenhum usuário do GupShupGo encontrado nos seus contatos ainda.';

  @override
  String contactsFailedToSync(String error) {
    return 'Falha ao sincronizar contatos: $error';
  }

  @override
  String contactsMatchedCount(int count) {
    return '$count contatos no GupShupGo';
  }

  @override
  String get contactsFromDeviceContacts => 'Dos contatos do seu dispositivo';

  @override
  String get contactsLoadFriendsError =>
      'Não foi possível carregar seus amigos.';

  @override
  String get contactsNoFriendsTitle => 'Nenhum amigo adicionado ainda';

  @override
  String get contactsNoFriendsPrompt =>
      'Use a aba Descobrir para procurar usuários por @usuario, telefone ou e-mail e enviar solicitações de amizade!';

  @override
  String get contactsDiscoverPeopleButton => 'Descobrir pessoas';

  @override
  String get contactsQuickConnectHeader => 'CONEXÃO RÁPIDA';

  @override
  String get contactsNoSuggestions => 'Nenhuma sugestão disponível no momento.';

  @override
  String get contactsLoadRequestsError =>
      'Não foi possível carregar suas solicitações.';

  @override
  String contactsPendingRequestsHeader(int count) {
    return 'PEDIDOS PENDENTES ($count)';
  }

  @override
  String get contactsNoPendingRequestsTitle => 'Nenhum pedido pendente';

  @override
  String get contactsNoPendingRequestsSubtitle =>
      'Quando outros usuários enviarem pedidos de conexão, eles aparecerão aqui.';

  @override
  String get contactsWantsToConnect => 'Quer se conectar';

  @override
  String get contactsAcceptButton => 'ACEITAR';

  @override
  String get contactsAcceptFailed =>
      'Não foi possível aceitar a solicitação. Tente novamente.';

  @override
  String contactsConnectedWith(String name) {
    return 'Conectado com $name!';
  }

  @override
  String get contactsDeclineFailed =>
      'Não foi possível recusar a solicitação. Tente novamente.';

  @override
  String get contactsYouMightKnowHeader => 'VOCÊ TALVEZ CONHEÇA';

  @override
  String get contactsSeeAll => 'VER TODOS';

  @override
  String get contactsSearchHint =>
      'Buscar nome, @usuario, telefone ou e-mail...';

  @override
  String get contactsTurnOnDiscoverability =>
      'Ative a visibilidade pública para aparecer em buscas e sugestões.';

  @override
  String get contactsNoMatchingUsersTitle =>
      'Nenhum usuário correspondente encontrado';

  @override
  String get contactsNoMatchingUsersSubtitle =>
      'Verifique o @usuario, telefone ou e-mail e tente novamente.';

  @override
  String get contactsDiscoverHeroTitle => 'Descubra pessoas no GupShupGo';

  @override
  String get contactsDiscoverHeroSubtitle =>
      'Expanda seu círculo com conexões de alta fidelidade ao redor do mundo.';

  @override
  String get contactsSyncDeviceContacts => 'Sincronizar contatos do aparelho';

  @override
  String get contactsSyncingContacts => 'Sincronizando contatos...';

  @override
  String get contactsSyncDeviceSubtitle =>
      'Encontre seus amigos instantaneamente da agenda';

  @override
  String get contactsSuggestedUsersHeader => 'USUÁRIOS SUGERIDOS';

  @override
  String get contactsAddFriendButton => 'ADICIONAR AMIGO';

  @override
  String get contactsRequestedButton => 'Solicitado';

  @override
  String contactsRequestSent(String name) {
    return 'Solicitação de amizade enviada para $name!';
  }

  @override
  String get contactsRequestFailed =>
      'A solicitação já está pendente ou falhou.';

  @override
  String get contactsRequestUnavailable =>
      'Essa solicitação não está mais disponível.';

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileSaveButton => 'Salvar';

  @override
  String get profileTapToChangePhoto => 'Toque para alterar a foto';

  @override
  String get profileUpgradeToPro => 'Assinar o Pro';

  @override
  String get profileSectionName => 'SEU NOME';

  @override
  String get profileNameHint => 'Digite seu nome';

  @override
  String get profileSectionHandle => 'NOME DE USUÁRIO ÚNICO';

  @override
  String get profileHandleNotSet => 'Ainda não definido';

  @override
  String get profileChangeHandle => 'Alterar';

  @override
  String get profileSectionAbout => 'RECADO';

  @override
  String get profileAboutHint => 'O que você está pensando?';

  @override
  String get profileDefaultAbout => 'Olá! Estou usando o GupShupGo.';

  @override
  String get profileSectionPhone => 'TELEFONE';

  @override
  String get profileSectionEmail => 'E-MAIL';

  @override
  String get profileSectionLinkedMethods => 'MÉTODOS DE LOGIN VINCULADOS';

  @override
  String get profileNotLinked => 'Não vinculado';

  @override
  String get profileNameEmpty => 'O nome não pode ficar em branco.';

  @override
  String get profileUpdatedSuccess => 'Perfil atualizado';

  @override
  String profileUploadPhotoFailed(String error) {
    return 'Falha ao enviar foto: $error';
  }

  @override
  String profileSaveFailed(String error) {
    return 'Falha ao salvar perfil: $error';
  }

  @override
  String get profilePoints => 'Pontos';

  @override
  String get profileBadges => 'Emblemas';

  @override
  String get profileBestBond => 'Maior Sequência';

  @override
  String get settingsAccountCard => 'Conta';

  @override
  String get settingsProfileTile => 'Perfil';

  @override
  String get settingsLinkedMethodsTile => 'Métodos de login vinculados';

  @override
  String get settingsPhoneTile => 'Número de telefone';

  @override
  String get settingsEmailTile => 'E-mail';

  @override
  String get settingsPrivacyCard => 'Privacidade';

  @override
  String get settingsDiscoverability => 'Visibilidade pública';

  @override
  String get settingsLastSeen => 'Visto por último';

  @override
  String get settingsReadReceipts => 'Confirmações de leitura';

  @override
  String get settingsAdPreferences => 'Preferências de anúncios';

  @override
  String get settingsManage => 'Gerenciar';

  @override
  String get settingsAppearanceCard => 'Aparência';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsChatTheme => 'Tema da conversa';

  @override
  String get settingsHelpSecurityCard => 'Ajuda e Segurança';

  @override
  String get settingsHelpCenter => 'Central de Ajuda';

  @override
  String get settingsReportProblem => 'Relatar um problema';

  @override
  String get settingsE2EEShield => 'Criptografia de ponta a ponta (Cofre)';

  @override
  String get settingsVerifySafetyNumber => 'Verificar número de segurança';

  @override
  String get settingsBlockedContacts => 'Contatos bloqueados';

  @override
  String get settingsClearAllGupHistory => 'Limpar histórico de conversas';

  @override
  String get settingsRateUs => 'Avalie-nos';

  @override
  String get settingsWhatsNew => 'Novidades';

  @override
  String get settingsCheckForUpdates => 'Verificar atualizações';

  @override
  String get settingsAppInfo => 'Informações do aplicativo';

  @override
  String get settingsLogOut => 'Sair';

  @override
  String get settingsLogOutConfirmTitle => 'Encerrar sessão';

  @override
  String get settingsLogOutConfirmPrompt =>
      'Tem certeza de que deseja sair do GupShupGo?';

  @override
  String get settingsSigningOut => 'Saindo…';

  @override
  String get settingsClearChatsConfirmTitle => 'Limpar todas as conversas';

  @override
  String get settingsClearChatsConfirmPrompt =>
      'Isso apagará permanentemente todo o histórico de mensagens. Esta ação não pode ser desfeita.';

  @override
  String get settingsDeleteAll => 'Apagar tudo';

  @override
  String get settingsClearingChats => 'Limpando conversas...';

  @override
  String get settingsAllChatsCleared => 'Todas as conversas foram limpas';

  @override
  String settingsClearChatsFailed(String error) {
    return 'Falha ao limpar conversas: $error';
  }

  @override
  String get settingsChooseThemeTitle => 'Escolher tema';

  @override
  String get settingsUnlockPremiumFeatures => 'Desbloqueie recursos premium';

  @override
  String settingsProDaysLeft(String planLabel, int daysRemaining) {
    return '$planLabel · Restam $daysRemaining dias';
  }

  @override
  String get settingsCheckingForUpdates => 'Verificando atualizações…';

  @override
  String settingsUpToDate(String version) {
    return 'Você está na versão mais recente (v$version).';
  }

  @override
  String get settingsUpdateCheckUnavailable =>
      'Não foi possível verificar atualizações. Certifique-se de instalar pela Google Play Store.';

  @override
  String get settingsNoBlockedContacts => 'Nenhum contato bloqueado';

  @override
  String get settingsUnblock => 'Desbloquear';

  @override
  String settingsUserUnblocked(String name) {
    return '$name desbloqueado';
  }

  @override
  String get settingsVerifyContactTitle => 'Verificar um contato';

  @override
  String get settingsVerifyContactSubtitle =>
      'Selecione um contato para ver o número de segurança compartilhado.';

  @override
  String get settingsComputingSafetyNumber => 'Calculando número de segurança…';

  @override
  String settingsSafetyNumberExplanation(String name) {
    return 'Se o número coincidir no dispositivo de $name, a criptografia de ponta a ponta está confirmada.';
  }

  @override
  String get settingsSafetyNumberNoBundle =>
      'Este contato ainda não publicou chaves de criptografia.';

  @override
  String get settingsSafetyNumberCompareHint =>
      'Compare este número pessoalmente ou por uma chamada segura.';

  @override
  String get callEndToEndEncrypted => 'Criptografado de ponta a ponta';

  @override
  String get callSecuring => 'Protegendo chamada…';

  @override
  String get callNotEncrypted => 'Não criptografado';

  @override
  String get callIncomingVoice => 'Chamada de voz recebida';

  @override
  String get callIncomingVideo => 'Chamada de vídeo recebida';

  @override
  String get callVoiceCall => 'Chamada de voz';

  @override
  String get callVideoCall => 'Chamada de vídeo';

  @override
  String get callDecline => 'Recusar';

  @override
  String get callAccept => 'Aceitar';

  @override
  String get callConnecting => 'Conectando...';

  @override
  String get callSettingUp => 'Configurando chamada...';

  @override
  String callNotifying(String name) {
    return 'Notificando $name...';
  }

  @override
  String get callRinging => 'Chamando...';

  @override
  String get callConnected => 'Conectado';

  @override
  String get callOnHold => 'Em espera';

  @override
  String get callCalling => 'Chamando...';

  @override
  String get callWaitingForUser => 'Aguardando participante...';

  @override
  String get callEnded => 'Chamada encerrada';

  @override
  String get callDeclined => 'Chamada recusada';

  @override
  String get callNoAnswer => 'Sem resposta';

  @override
  String get callFailedToConnect => 'Falha ao conectar';

  @override
  String callFailedToStart(String error) {
    return 'Falha ao iniciar chamada: $error';
  }

  @override
  String get callTokenExpired =>
      'Token expirado ou inválido. Reinicie a chamada.';

  @override
  String callFailedToInit(String type, String error) {
    return 'Falha ao inicializar chamada de $type: $error';
  }

  @override
  String get callTurnOffSpeaker => 'Desligar viva-voz';

  @override
  String get callTurnOnSpeaker => 'Ligar viva-voz';

  @override
  String get callMuteMic => 'Silenciar microfone';

  @override
  String get callUnmuteMic => 'Ativar microfone';

  @override
  String get callEndCall => 'Encerrar chamada';

  @override
  String get callSwitchCamera => 'Alternar câmera';

  @override
  String get callTurnOffCamera => 'Desligar câmera';

  @override
  String get callTurnOnCamera => 'Ligar câmera';

  @override
  String statusViewedByCount(int count) {
    return 'Visualizado por $count';
  }

  @override
  String get statusNoViewsYet => 'Nenhuma visualização ainda';

  @override
  String statusViewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visualizações',
      one: '1 visualização',
    );
    return '$_temp0';
  }

  @override
  String get statusDeleteTitle => 'Excluir status';

  @override
  String get statusDeleteConfirm =>
      'Tem certeza de que deseja excluir este status?';

  @override
  String get statusDeleteButton => 'Excluir';

  @override
  String get statusReplySent => 'Resposta enviada';

  @override
  String statusReplyFailed(String error) {
    return 'Falha ao enviar resposta: $error';
  }

  @override
  String get statusNoActive => 'Nenhum status ativo';

  @override
  String get statusCouldNotLoad => 'Não foi possível carregar esta atualização';

  @override
  String get statusTapToRetry => 'Toque para tentar novamente';

  @override
  String get statusFailedToLoadImage => 'Falha ao carregar imagem';

  @override
  String get statusLoadingVideo => 'Carregando vídeo...';

  @override
  String get statusEnterTextPrompt => 'Digite algum texto';

  @override
  String get statusNoContactsNotice =>
      'Nenhum contato ainda — inicie uma conversa antes de postar um status.';

  @override
  String statusPostFailed(String error) {
    return 'Falha ao postar status: $error';
  }

  @override
  String get statusTypeHint => 'Digite um status...';

  @override
  String get statusCamera => 'Câmera';

  @override
  String get statusTakePhoto => 'Tirar foto';

  @override
  String get statusGalleryPhoto => 'Foto da galeria';

  @override
  String get statusChooseImageGallery => 'Escolher foto da galeria';

  @override
  String get statusRecordVideo => 'Gravar vídeo';

  @override
  String get statusRecordShortVideo => 'Gravar vídeo curto';

  @override
  String get statusGalleryVideo => 'Vídeo da galeria';

  @override
  String get statusChooseVideoGallery => 'Escolher vídeo da galeria';

  @override
  String statusFailedPickImage(String error) {
    return 'Falha ao selecionar foto: $error';
  }

  @override
  String statusFailedPickVideo(String error) {
    return 'Falha ao selecionar vídeo: $error';
  }

  @override
  String get statusChangeBgColorTooltip => 'Alterar cor de fundo';

  @override
  String aiMessagesRemaining(int count) {
    return '$count restantes';
  }

  @override
  String get aiQuotaDialogTitle => 'Mensagens GupAI';

  @override
  String aiQuotaRemainingOfTotal(int remaining, int total) {
    return '$remaining de $total restantes hoje';
  }

  @override
  String aiQuotaUsedResetNote(int used) {
    return '$used usados hoje · reinicia amanhã. Assista a um anúncio ou seja Pro.';
  }

  @override
  String get aiQuotaGotIt => 'Entendi';

  @override
  String get aiTitle => 'GupAI';

  @override
  String get aiSubtitle => 'Seu assistente no app';

  @override
  String get aiEmptyHelpTitle => 'Como posso ajudar?';

  @override
  String get aiEmptyHelpSubtitle =>
      'Elabore respostas, traduza, resuma ou tire dúvidas.';

  @override
  String get meshOfflineChatConnected => 'Chat offline · conectado';

  @override
  String get meshConnecting => 'Conectando…';

  @override
  String get meshBannerNotice => 'Chat offline — sem internet nem servidores';

  @override
  String meshSayHiTo(String name) {
    return 'Diga oi para $name';
  }

  @override
  String meshOfflineDescription(String name) {
    return 'Você está no chat offline. As mensagens ficam entre você e $name.';
  }

  @override
  String get meshMediaUnavailable => 'Esta mídia não está mais disponível.';

  @override
  String get meshViewOnceTitle => 'Visualização única';

  @override
  String meshViewOncePrompt(String type) {
    return 'Você só pode abrir este $type uma vez.';
  }

  @override
  String get arcadeTabOverview => 'Visão geral';

  @override
  String get arcadeTabChallenges => 'Desafios';

  @override
  String get arcadeTabLeaderboard => 'Classificação';

  @override
  String get arcadeFailedLoadStats => 'Falha ao carregar estatísticas.';

  @override
  String get aiAskHint => 'Pergunte qualquer coisa ao GupAI…';
}
