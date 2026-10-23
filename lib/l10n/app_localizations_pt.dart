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
  String get homeNavChats => 'Mensagens';

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
  String get homeMenuPrivateVault => 'Cofre privado';

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
  String get attachmentScreenShare => 'Compartilhar tela';

  @override
  String get attachmentScreenShareSubtitle =>
      'Mostre sua tela ao vivo durante o bate-papo';

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

  @override
  String get settingsNotificationsTile => 'Notificações';

  @override
  String get settingsNotificationsStatusOn => 'Ativado';

  @override
  String get settingsNotificationsStatusOff => 'Desativado';

  @override
  String get settingsNotificationsEnabledToast =>
      'As notificações estão ativadas.';

  @override
  String get settingsEnableNotificationsTitle => 'Ativar notificações';

  @override
  String get settingsEnableNotificationsBody =>
      'As notificações estão desativadas. Abra as configurações do sistema para permitir que o GupShupGo notifique você sobre novas mensagens e chamadas.';

  @override
  String get settingsOpenSystemSettings => 'Abrir configurações';

  @override
  String get loginTagline =>
      'Mensagens privadas que funcionam mesmo sem internet.';

  @override
  String get settingsPrivacyPolicy => 'Política de Privacidade';

  @override
  String get settingsTerms => 'Termos de Serviço';

  @override
  String get settingsDeleteAccount => 'Excluir conta';

  @override
  String get inviteSheetTitle => 'Convidar amigos';

  @override
  String get inviteSheetSubtitle =>
      'Espalhe a novidade — compartilhe o GupShupGo';

  @override
  String get inviteShareImageBtn => 'Compartilhar imagem';

  @override
  String get inviteShareLinkBtn => 'Compartilhar link';

  @override
  String get inviteCopyLinkBtn => 'Copiar link';

  @override
  String get inviteLinkCopied => 'Link de convite copiado';

  @override
  String inviteMessage(String link) {
    return 'Converse comigo no GupShupGo — funciona até sem internet 👋 $link';
  }

  @override
  String get inviteCardTagline => 'Chat privado que funciona mesmo offline';

  @override
  String get inviteCardScan => 'Digitalize para baixar';

  @override
  String get inviteCardDownload => 'Baixar no Google Play';

  @override
  String get homeMenuInvite => 'Convidar amigos';

  @override
  String get invitePromptTitle => 'Curtindo o GupShupGo?';

  @override
  String get invitePromptBody =>
      'É melhor com amigos — e funciona até sem internet. Quer convidar alguém?';

  @override
  String get invitePromptInvite => 'Convidar amigos';

  @override
  String get invitePromptLater => 'Talvez mais tarde';

  @override
  String get homeOfflineBannerTitle => 'Sem internet? Sem problemas';

  @override
  String get homeOfflineBannerSubtitle =>
      'Você ainda pode enviar mensagens para pessoas próximas via Bluetooth.';

  @override
  String homeNearbyBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pessoas por perto',
      one: '1 pessoa por perto',
    );
    return '$_temp0';
  }

  @override
  String get homeNearbyBannerSubtitle =>
      'Converse via Bluetooth — sem necessidade de internet.';

  @override
  String get linkBackupTitle => 'Adicionar método de login de backup';

  @override
  String get linkBackupSubtitle =>
      'Vincule Google ou e-mail para poder entrar mesmo sem o chip SIM.';

  @override
  String get linkGoogleTitle => 'Vincular conta do Google';

  @override
  String get linkGoogleSubtitleLinked => 'Vinculado ✓';

  @override
  String get linkGoogleSubtitleUnlinked => 'Login com um toque sem SIM';

  @override
  String get linkGoogleAction => 'Vincular';

  @override
  String get linkGoogleSuccess => 'Conta do Google vinculada com sucesso!';

  @override
  String get linkGoogleAlreadyUsed =>
      'Esta conta do Google já está registrada no GupShupGo.';

  @override
  String get linkGoogleFailed => 'Falha ao vincular Google. Tente novamente.';

  @override
  String get linkSessionExpired => 'Sessão expirada. Faça login novamente.';

  @override
  String get linkEmailTitle => 'Vincular e-mail e senha';

  @override
  String get linkEmailSubtitleLinked => 'Vinculado ✓';

  @override
  String get linkEmailSubtitleUnlinked =>
      'Entre com e-mail se não tiver chip ou Google';

  @override
  String get linkEmailActionAdd => 'Adicionar';

  @override
  String get linkEmailActionCancel => 'Cancelar';

  @override
  String get linkEmailFieldLabel => 'E-mail';

  @override
  String get linkPasswordFieldLabel => 'Criar uma senha';

  @override
  String get linkPasswordHelper => 'Mínimo de 6 caracteres';

  @override
  String get linkEmailButton => 'Vincular e-mail';

  @override
  String get linkEmailSuccess => 'E-mail vinculado com sucesso!';

  @override
  String get linkEmailInvalid => 'Insira um e-mail válido.';

  @override
  String get linkPasswordTooShort =>
      'A senha deve ter pelo menos 6 caracteres.';

  @override
  String get linkEmailAlreadyInUse =>
      'Este e-mail já está registrado no GupShupGo.';

  @override
  String get linkEmailAlreadyLinked =>
      'Já existe um e-mail vinculado à sua conta.';

  @override
  String get linkEmailFailed => 'Falha ao vincular e-mail. Tente novamente.';

  @override
  String get linkContinueToApp => 'Continuar para o app';

  @override
  String get linkSkipForNow => 'Pular por enquanto';

  @override
  String get linkSkip => 'Pular';

  @override
  String get phoneAuthTitleEntry => 'Entre com seu número de telefone.';

  @override
  String get phoneAuthTitleOtp => 'Digite o código enviado.';

  @override
  String get phoneAuthNameHint => 'Seu nome';

  @override
  String get phoneAuthPhoneHint => 'Número de telefone';

  @override
  String get phoneAuthUseSim => 'Usar SIM';

  @override
  String get phoneAuthSendOtp => 'Enviar código';

  @override
  String phoneAuthOtpPrompt(String phone) {
    return 'Digite o código de 6 dígitos enviado para $phone';
  }

  @override
  String get phoneAuthOtpPromptGeneric =>
      'Digite o código de 6 dígitos que enviamos';

  @override
  String get phoneAuthOtpHint => 'Digite o código';

  @override
  String get phoneAuthVerify => 'Verificar';

  @override
  String get phoneAuthGoBack => 'Voltar';

  @override
  String get phoneAuthResendCode => 'Reenviar código';

  @override
  String get phoneAuthEnterName => 'Digite seu nome';

  @override
  String get phoneAuthEnterValidPhone => 'Digite um número de telefone válido';

  @override
  String get phoneAuthEnterCode => 'Digite o código';

  @override
  String get phoneAuthRequestNewCode => 'Solicite um novo código.';

  @override
  String get phoneAuthCodeIncorrect => 'Código incorreto. Tente novamente.';

  @override
  String get phoneAuthErrCodeIncorrect =>
      'Código incorreto. Verifique e tente novamente.';

  @override
  String get phoneAuthErrCodeExpired =>
      'O código expirou. Toque em \"Reenviar código\".';

  @override
  String get phoneAuthErrTooManyRequests =>
      'Muitas tentativas. Aguarde um momento.';

  @override
  String get phoneAuthErrInvalidPhone => 'Número de telefone inválido.';

  @override
  String get phoneAuthErrQuotaExceeded => 'Limite de SMS atingido.';

  @override
  String get phoneAuthErrFailed => 'Falha na verificação.';

  @override
  String get usernameSetupAppBarTitle => 'Escolha seu nome de usuário';

  @override
  String get usernameSetupHeaderTitle => 'Proteja sua identidade';

  @override
  String get usernameSetupHeaderDesc =>
      'Seu @handle é sua chave exclusiva no GupShupGo. Outras pessoas podem te encontrar sem você compartilhar telefone ou e-mail.';

  @override
  String get usernameSetupInputHint => 'seu_usuario';

  @override
  String get usernameSetupChecking => 'Verificando disponibilidade...';

  @override
  String usernameSetupAvailable(String handle) {
    return '@$handle está disponível!';
  }

  @override
  String usernameSetupTaken(String handle) {
    return '@$handle já está em uso.';
  }

  @override
  String get usernameSetupCharRules => '3 a 20 caracteres (a-z, 0-9, _)';

  @override
  String get usernameSetupTooShort => 'Mínimo de 3 caracteres.';

  @override
  String get usernameSetupTooLong => 'Máximo de 20 caracteres.';

  @override
  String get usernameSetupInvalidChars =>
      'Apenas letras, números e sublinhados.';

  @override
  String get usernameSetupRecommended => 'RECOMENDADO PARA VOCÊ';

  @override
  String get usernameSetupSaveBtn => 'Salvar e continuar';

  @override
  String get usernameSetupSkipBtn => 'Pular por enquanto';

  @override
  String usernameSetupFailed(String error) {
    return 'Falha ao definir nome de usuário: $error';
  }

  @override
  String get vaultProtectTitle => 'Proteger cofre';

  @override
  String get vaultUnlockTitle => 'Desbloquear cofre';

  @override
  String get vaultSetupDesc =>
      'Escolha um PIN para criptografar seu histórico de mensagens. Você precisará dele em um novo aparelho.';

  @override
  String get vaultUnlockDescBio =>
      'Digite seu PIN ou use a biometria para descriptografar.';

  @override
  String get vaultUnlockDescPin =>
      'Digite seu PIN para descriptografar seu histórico.';

  @override
  String get vaultReinstallHint =>
      'Digite seu PIN para restaurar o histórico neste aparelho.';

  @override
  String get vaultUnlockWithFingerprint => 'Desbloquear com digital';

  @override
  String get vaultOrDivider => 'OU';

  @override
  String get vaultNewPin => 'Novo PIN';

  @override
  String get vaultConfirmPin => 'Confirmar PIN';

  @override
  String get vaultEnterPin => 'Digitar PIN';

  @override
  String get vaultKeyboardUseLetters => 'Usar letras';

  @override
  String get vaultKeyboardUseNumbers => 'Usar números';

  @override
  String get vaultRestoreLater => 'Restaurar mais tarde';

  @override
  String get vaultForgotPin => 'Esqueceu o PIN?';

  @override
  String get vaultSetPinBtn => 'Definir PIN';

  @override
  String get vaultDecryptBtn => 'Descriptografar';

  @override
  String get vaultPinMinLength => 'O PIN deve ter pelo menos 6 caracteres.';

  @override
  String get vaultPinsDoNotMatch => 'Os PINs não coincidem.';

  @override
  String get vaultSetupFailed => 'Falha na configuração. Verifique a conexão.';

  @override
  String get vaultIncorrectPin => 'PIN incorreto. Tente novamente.';

  @override
  String get vaultFingerprintOutOfDate =>
      'Digital desatualizada. Digite seu PIN.';

  @override
  String get vaultBiometricError =>
      'Erro biométrico. Digite o PIN manualmente.';

  @override
  String get vaultBioReasonUnlock =>
      'Autentique-se com biometria para abrir seu cofre';

  @override
  String get vaultBioReasonEnrol =>
      'Confirme sua digital para ativar o desbloqueio rápido';

  @override
  String get vaultAskBioTitle => 'Desbloquear com digital?';

  @override
  String get vaultAskBioDesc =>
      'Evite digitar seu PIN neste celular. Mas lembre-se do PIN para novos aparelhos.';

  @override
  String get vaultAskBioNotNow => 'Agora não';

  @override
  String get vaultAskBioEnable => 'Ativar';

  @override
  String get vaultDeleteMessagesTitle => 'Excluir todas as mensagens?';

  @override
  String get vaultDeleteMessagesDesc =>
      'Sem seu PIN, o histórico não pode ser lido. Redefinir apagará tudo permanentemente.';

  @override
  String get vaultDeleteMessagesCancel => 'Cancelar';

  @override
  String get vaultDeleteMessagesConfirm => 'Excluir tudo';

  @override
  String get vaultCustodyConfirmTitle => 'Confirme o PIN do seu cofre';

  @override
  String get vaultCustodyChooseTitle => 'Escolha um PIN';

  @override
  String get vaultCustodyConfirmDesc =>
      'Seu histórico é criptografado por um PIN. Confirme-o uma vez.';

  @override
  String get vaultCustodyChooseDesc =>
      'Escolha um PIN memorável. Suas mensagens serão criptografadas com o novo código.';

  @override
  String get vaultCustodyDontKnow => 'Não sei meu PIN';

  @override
  String get vaultCustodyConfirmBtn => 'Confirmar';

  @override
  String get vaultCustodySaveBtn => 'Salvar PIN';

  @override
  String get vaultCustodyMismatchError => 'Esse PIN não coincide.';

  @override
  String get vaultCustodyAutoUpdateFailed =>
      'Não foi possível atualizar o PIN automaticamente.';

  @override
  String vaultCustodyReencrypting(int done, int total) {
    return 'Recriptografando $done de $total… mantenha o app aberto.';
  }

  @override
  String get vaultCustodyPreparing => 'Preparando… mantenha o app aberto.';

  @override
  String get vaultSettingsTitle => 'Cofre';

  @override
  String get vaultSettingsAboutTitle => 'Sobre o cofre';

  @override
  String get vaultSettingsAboutDesc =>
      'Backup privado das suas conversas trancado com seu PIN. Somente seu PIN pode abrir.';

  @override
  String get vaultSettingsBulletMessages => 'Suas mensagens';

  @override
  String get vaultSettingsBulletStatuses => 'Status que você pode ver';

  @override
  String get vaultSettingsNeverKept =>
      'Nunca armazenado aqui: histórico de chamadas, contatos ou fotos de conversas.';

  @override
  String get vaultSettingsSectionPrivacy => 'PRIVACIDADE';

  @override
  String get vaultSettingsAutoDelete =>
      'Exclusão automática de mensagens antigas';

  @override
  String get vaultSettingsKeepForever => 'Manter para sempre';

  @override
  String vaultSettingsDeleteAfter(String label) {
    return 'Excluir após $label';
  }

  @override
  String get vaultSettingsSectionPin => 'PIN';

  @override
  String get vaultSettingsChangePin => 'Alterar PIN';

  @override
  String get vaultSettingsChangePinSubtitle =>
      'Recriptografa todos os dados do cofre';

  @override
  String get vaultSettingsBioTitle => 'Desbloquear com digital';

  @override
  String get vaultSettingsBioSubOn => 'Ativado neste aparelho';

  @override
  String get vaultSettingsBioSubOff => 'Evite digitar o PIN neste aparelho';

  @override
  String get vaultSettingsSectionDanger => 'ZONA DE PERIGO';

  @override
  String get vaultSettingsDeleteData => 'Excluir dados do cofre';

  @override
  String get vaultSettingsDeleteDataSubtitle =>
      'Apaga o histórico, mantém o PIN';

  @override
  String get vaultSettingsResetVault => 'Redefinir cofre';

  @override
  String get vaultSettingsResetVaultSubtitle => 'Esquece o PIN e apaga tudo';

  @override
  String get vaultSettingsPinChanged => 'PIN alterado com sucesso.';

  @override
  String get vaultSettingsBioTurnedOff => 'Desbloqueio por digital desativado.';

  @override
  String get vaultSettingsBioTurnedOn => 'Desbloqueio por digital ativado.';

  @override
  String get vaultSettingsClearDataTitle => 'Excluir dados do cofre?';

  @override
  String get vaultSettingsClearDataDesc =>
      'Remove todas as mensagens criptografadas da nuvem. Seu PIN continua o mesmo.';

  @override
  String get vaultSettingsClearDataCancel => 'Cancelar';

  @override
  String get vaultSettingsClearDataConfirm => 'Excluir dados';

  @override
  String get vaultSettingsDataDeleted => 'Dados do cofre excluídos.';

  @override
  String get vaultSettingsResetTitle => 'Redefinir cofre?';

  @override
  String get vaultSettingsResetDesc =>
      'Remove o PIN e todas as mensagens salvas.';

  @override
  String get vaultSettingsResetConfirm => 'Redefinir';

  @override
  String get vaultSettingsChangeDialogDesc =>
      'Tudo será recriptografado com o novo PIN.';

  @override
  String get vaultSettingsCurrentPin => 'PIN atual';

  @override
  String get vaultSettingsNewPin => 'Novo PIN';

  @override
  String get vaultSettingsConfirmNewPin => 'Confirmar novo PIN';

  @override
  String get vaultSettingsEnterCurrentPin => 'Digite seu PIN atual.';

  @override
  String get vaultSettingsNewPinMinLength => 'Mínimo de 6 caracteres.';

  @override
  String get vaultSettingsNewPinMismatch => 'Os novos PINs não coincidem.';

  @override
  String get vaultSettingsCurrentPinIncorrect => 'PIN atual incorreto.';

  @override
  String vaultSettingsReencryptingCount(int done, int total) {
    return 'Recriptografando $done de $total…';
  }

  @override
  String get vaultSettingsChangeBtn => 'Alterar';

  @override
  String get vaultSettingsBioPinDialogTitle => 'Digite seu PIN';

  @override
  String get vaultSettingsBioPinDialogDesc =>
      'Seu PIN é necessário para ativar a digital.';

  @override
  String get vaultSettingsContinueBtn => 'Continuar';

  @override
  String get premiumTitle => 'GupShupGo Pro';

  @override
  String get premiumSubtitleMember => 'Você é membro Pro! 🎉';

  @override
  String get premiumSubtitleUnlock => 'Desbloqueie a experiência completa';

  @override
  String premiumActiveDaysRemaining(int days) {
    return '$days dias restantes';
  }

  @override
  String get premiumFeaturesHeader => 'O que você ganha com o Pro';

  @override
  String get premiumPlansHeader => 'Escolha seu plano';

  @override
  String get premiumSubscribeBtn => 'Assinar agora';

  @override
  String get premiumCancelAnytime =>
      'Cancele a qualquer momento no Google Play.';

  @override
  String get premiumRestoreBtn => 'Restaurar compra anterior';

  @override
  String get premiumRestoring => 'Restaurando…';

  @override
  String get premiumRestoredSuccess => 'Assinatura Pro restaurada! 🎉';

  @override
  String get premiumNoActiveSub => 'Nenhuma assinatura ativa encontrada.';

  @override
  String get premiumProductUnavailable => 'Produto não disponível.';

  @override
  String get premiumFeatureMediaTitle => 'Momentos de Mídia';

  @override
  String get premiumFeatureMediaDesc => 'Compartilhe fotos e vídeos em status';

  @override
  String get premiumFeatureMediaFree => 'Apenas texto';

  @override
  String get premiumFeatureMediaPro => 'Fotos + Vídeos';

  @override
  String get premiumFeatureScreenShareTitle => 'Compartilhamento de tela';

  @override
  String get premiumFeatureScreenShareDesc =>
      'Compartilhe sua tela ao vivo no chat';

  @override
  String get premiumFeatureScreenShareFree => 'Bloqueado';

  @override
  String get premiumFeatureScreenSharePro => 'Acesso total';

  @override
  String get premiumFeatureThemesTitle => 'Temas de chat';

  @override
  String get premiumFeatureThemesDesc =>
      'Planos de fundo e balões personalizados por chat';

  @override
  String get premiumFeatureThemesFree => '6 temas';

  @override
  String get premiumFeatureThemesPro => 'Todos os 12 + sua própria foto';

  @override
  String get premiumFeatureVoiceTitle => 'Áudios mais longos';

  @override
  String get premiumFeatureVoiceDesc => 'Grave mensagens de voz sem limite';

  @override
  String get premiumFeatureVoiceFree => '2 minutos';

  @override
  String get premiumFeatureVoicePro => 'Ilimitado';

  @override
  String get premiumFeatureQualityTitle => 'Mídia de alta qualidade';

  @override
  String get premiumFeatureQualityDesc =>
      'Fotos mais nítidas e vídeos de status de 90s';

  @override
  String get premiumFeatureQualityFree => 'Qualidade padrão';

  @override
  String get premiumFeatureQualityPro => 'Alta qualidade + vídeos 90s';

  @override
  String get premiumFeatureBondTitle => 'Restauração de Vínculo';

  @override
  String get premiumFeatureBondDesc => 'Restaure vínculos perdidos de graça';

  @override
  String get premiumFeatureBondFree => 'Pontos ou anúncio';

  @override
  String get premiumFeatureBondPro => '1 restauração grátis/semana';

  @override
  String get premiumFeatureBadgeTitle => 'Selo Pro';

  @override
  String get premiumFeatureBadgeDesc => 'Exiba seu selo exclusivo Pro';

  @override
  String get premiumFeatureBadgeFree => 'Sem selo';

  @override
  String get premiumFeatureBadgePro => 'Selo Pro exclusivo';

  @override
  String get premiumFeatureExportTitle => 'Exportação de chat';

  @override
  String get premiumFeatureExportDesc =>
      'Salve conversas em PDF ou texto simples';

  @override
  String get premiumFeatureExportFree => 'Não disponível';

  @override
  String get premiumFeatureExportPro => 'Exportação em PDF e TXT';

  @override
  String get premiumFeatureAdFreeTitle => 'Sem anúncios';

  @override
  String get premiumFeatureAdFreeDesc => 'Sem banners de anúncio no app';

  @override
  String get premiumFeatureAdFreeFree => 'Exibe banners';

  @override
  String get premiumFeatureAdFreePro => 'Sem banners';

  @override
  String get premiumPlanMonthly => 'Mensal';

  @override
  String get premiumPlanYearly => 'Anual';

  @override
  String get premiumPlanSavings => 'Economize ~33%';

  @override
  String get premiumPeriodMonth => '/mês';

  @override
  String get premiumPeriodYear => '/ano';

  @override
  String get nearbyOfflineChatTitle => 'Chat offline';

  @override
  String get nearbySearchingDevices => 'Procurando dispositivos próximos…';

  @override
  String get nearbyTooltipStop => 'Parar chat offline';

  @override
  String get nearbyTooltipStart => 'Iniciar chat offline';

  @override
  String get nearbyDevicesSection => 'Dispositivos próximos';

  @override
  String get nearbyDiscoveryOn => 'BUSCA ATIVA';

  @override
  String get nearbyDiscoveryOff => 'BUSCA DESATIVADA';

  @override
  String get nearbyHeroTitle => 'Modo offline';

  @override
  String nearbyHeroNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count próximos',
      one: '1 próximo',
    );
    return '$_temp0';
  }

  @override
  String get nearbyHeroOff => 'Chat offline desativado';

  @override
  String get nearbyHeroDesc =>
      'Buscando em até 100 metros. Conexões criptografadas ponto a ponto.';

  @override
  String get nearbyYourNameHint => 'Seu nome';

  @override
  String get nearbyEmptySearching => 'Procurando dispositivos próximos…';

  @override
  String get nearbyEmptyOff => 'Chat offline desativado';

  @override
  String get nearbyEmptySearchingDesc =>
      'Abra o GupShupGo com Bluetooth ativado em outros celulares.';

  @override
  String get nearbyEmptyOffDesc =>
      'Toque no ícone de início no canto superior direito.';

  @override
  String get nearbyPeerConnected => 'Conectado · Toque para conversar';

  @override
  String get nearbyPeerConnecting => 'Conectando…';

  @override
  String get nearbyPeerTapToConnect => 'Toque para conectar';

  @override
  String get nearbyActionChat => 'Chat';

  @override
  String get nearbyActionConnecting => 'Conectando';

  @override
  String get nearbyActionConnect => 'Conectar';

  @override
  String get nearbyPermNeededTitle => 'Permissões necessárias';

  @override
  String get nearbyPermNeededDesc =>
      'Requer permissões de Bluetooth e dispositivos por perto.';

  @override
  String get nearbyTryAgainBtn => 'Tentar novamente';

  @override
  String get nearbySettingsBtn => 'Configurações';

  @override
  String get nearbyHelpTip =>
      'Não vê seu amigo? Verifique o Bluetooth nos dois aparelhos.';

  @override
  String get anonLobbyTitle => 'Chat anônimo';

  @override
  String get anonLobbyFinding => 'Procurando alguém para você…';

  @override
  String get anonLobbyHangTight =>
      'Aguarde um momento — conectando com um estranho.';

  @override
  String get anonLobbyCancelBtn => 'Cancelar busca';

  @override
  String get anonLobbyPrivacyNote => 'Sua identidade fica oculta.';

  @override
  String get anonLobbyConnecting => 'Conectando…';

  @override
  String get anonLobbyWaitingOthers =>
      'Aguardando mais usuários ficarem online…';

  @override
  String anonLobbyOnlineCount(int count) {
    return '$count online agora';
  }

  @override
  String get anonChatNotEncrypted =>
      'As mensagens não são criptografadas de ponta a ponta';

  @override
  String get anonChatRequestSentTooltip => 'Pedido enviado';

  @override
  String get anonChatAddFriendTooltip => 'Adicionar amigo';

  @override
  String get anonChatNextStrangerTooltip => 'Próximo estranho';

  @override
  String get anonChatReportTooltip => 'Denunciar';

  @override
  String get anonChatSayHi => 'Diga oi ao estranho! 👋';

  @override
  String get anonChatFriendsTransition =>
      'Agora vocês são amigos! Abrindo chat seguro…';

  @override
  String get anonChatStrangerDisconnected => 'O estranho se desconectou 👋';

  @override
  String get anonChatFindNextBtn => 'Encontrar próximo estranho';

  @override
  String get anonChatFriendReqTitle => 'O estranho quer se conectar!';

  @override
  String get anonChatFriendReqDesc =>
      'Aceitar revelará seu perfil real e abrirá um chat criptografado.';

  @override
  String get anonChatDecline => 'Recusar';

  @override
  String get anonChatAccept => 'Aceitar';

  @override
  String get anonChatWaitingReqTitle => 'Pedido de amizade enviado';

  @override
  String get anonChatWaitingReqDesc => 'Aguardando resposta…';

  @override
  String get anonChatReportTitle => 'Denunciar estranho';

  @override
  String get anonChatReportQuestion => 'Por que você está denunciando?';

  @override
  String get anonChatReportReasonInappropriate => 'Conteúdo inadequado';

  @override
  String get anonChatReportReasonHarassment => 'Assédio ou bullying';

  @override
  String get anonChatReportReasonSpam => 'Spam ou golpe';

  @override
  String get anonChatReportReasonThreatening => 'Comportamento ameaçador';

  @override
  String get anonChatReportReasonOther => 'Outro';

  @override
  String get anonChatReportCancel => 'Cancelar';

  @override
  String get anonChatReportSubmit => 'Denunciar e sair';

  @override
  String get anonChatReportSubmitted =>
      'Denúncia enviada. Obrigado por manter o app seguro.';

  @override
  String get anonChatViewOnceVideoTitle => 'Assistir uma vez?';

  @override
  String get anonChatViewOncePhotoTitle => 'Abrir uma vez?';

  @override
  String get anonChatViewOnceVideoDesc =>
      'Você só pode abrir este vídeo uma vez.';

  @override
  String get anonChatViewOncePhotoDesc =>
      'Você só pode abrir esta foto uma vez.';

  @override
  String get anonChatViewOnceCancel => 'Cancelar';

  @override
  String get anonChatViewOnceOpen => 'Abrir';

  @override
  String get unsupportedVersionTitle => 'Atualize o GupShupGo';

  @override
  String get unsupportedVersionDesc =>
      'Esta versão não é mais suportada. Atualize para continuar.';

  @override
  String get unsupportedVersionUpdateNow => 'Atualizar agora';

  @override
  String get unsupportedVersionOpenPlayStore => 'Abrir Play Store';

  @override
  String publicProfileNotFound(String username) {
    return '@$username não encontrado';
  }

  @override
  String get publicProfileUserNotFound => 'Usuário não encontrado';

  @override
  String get publicProfileNotFoundDesc =>
      'Este usuário não existe ou o link está quebrado.';

  @override
  String get publicProfileTitle => 'Perfil';

  @override
  String get publicProfileOnline => 'Online';

  @override
  String publicProfileLastSeen(String time) {
    return 'Visto por último $time';
  }

  @override
  String get publicProfileJustNow => 'agora mesmo';

  @override
  String publicProfileMinutesAgo(int minutes) {
    return 'há $minutes min';
  }

  @override
  String publicProfileHoursAgo(int hours) {
    return 'há $hours h';
  }

  @override
  String publicProfileDaysAgo(int days) {
    return 'há $days d';
  }

  @override
  String publicProfileJoined(String date) {
    return 'Entrou em $date';
  }

  @override
  String get publicProfileOwnLink => 'Este é o link do seu próprio perfil.';

  @override
  String publicProfileGupPoints(int points) {
    return '$points Pontos Gup';
  }

  @override
  String publicProfileLevel(int level) {
    return 'Nível $level';
  }

  @override
  String get publicProfileStatPoints => 'Pontos';

  @override
  String get publicProfileStatBadges => 'Medalhas';

  @override
  String get publicProfileStatBestBond => 'Melhor vínculo';

  @override
  String get publicProfileBadges => 'MEDALHAS';

  @override
  String get qrScannerTitle => 'Escanear código QR';

  @override
  String get qrScannerFlashOnTooltip => 'Ligar flash';

  @override
  String get qrScannerFlashOffTooltip => 'Desligar flash';

  @override
  String get qrScannerPrompt =>
      'Aponte a câmera para um código QR do GupShupGo';

  @override
  String get qrScannerNotProfileCode =>
      'Não é um código de perfil do GupShupGo.';

  @override
  String get qrScannerCameraErrorTitle => 'Não foi possível abrir a câmera.';

  @override
  String get qrScannerCameraErrorRetry => 'Tente novamente.';

  @override
  String get qrScannerPermissionMsg =>
      'Permissão de câmera necessária para escanear.';

  @override
  String get qrScannerPermissionAllow => 'Permitir câmera';

  @override
  String get qrScannerBlockedMsg =>
      'Câmera bloqueada. Ative nas Configurações.';

  @override
  String get qrScannerBlockedSettings => 'Abrir configurações';

  @override
  String get screenShareIncomingTitle => 'Tela compartilhada recebida';

  @override
  String get screenShareWantsToShare => 'quer compartilhar a tela';

  @override
  String get screenShareReject => 'Recusar';

  @override
  String get screenShareAccept => 'Aceitar';

  @override
  String get screenShareCantAccept =>
      'Não foi possível aceitar. Verifique sua conexão.';

  @override
  String screenShareDeclined(String name) {
    return '$name recusou o compartilhamento';
  }

  @override
  String get screenShareNoAnswer => 'Sem resposta';

  @override
  String get screenShareStartError =>
      'Não foi possível iniciar o compartilhamento';

  @override
  String get screenShareStatusRequesting => 'Solicitando permissão';

  @override
  String get screenShareStatusInitializing => 'Iniciando transmissão';

  @override
  String get screenShareStatusWaitingParticipant => 'Aguardando participante';

  @override
  String get screenShareStatusActive => 'Compartilhamento de tela ativo';

  @override
  String screenShareSubWaitingAccept(String name) {
    return 'Aguardando $name aceitar…';
  }

  @override
  String get screenShareSubEstablishing =>
      'Estabelecendo transmissão criptografada...';

  @override
  String screenShareSubWaitingJoin(String name) {
    return 'Aguardando $name entrar...';
  }

  @override
  String get screenShareSubActive =>
      'Sua tela inteira está visível em alta definição.';

  @override
  String get screenShareBadgeRequesting => 'SOLICITANDO';

  @override
  String get screenShareBadgeConnecting => 'CONECTANDO';

  @override
  String get screenShareSharedWith => 'Compartilhado com ';

  @override
  String get screenShareRequestingFrom => 'Solicitando a ';

  @override
  String get screenShareMinimizeTip =>
      'Você pode minimizar esta tela para continuar usando o app.';

  @override
  String get screenShareStop => 'Parar compartilhamento';

  @override
  String get screenShareCancelRequest => 'Cancelar solicitação';

  @override
  String screenShareViewerTitle(String name) {
    return '$name está compartilhando';
  }

  @override
  String get screenShareViewerLive => 'AO VIVO';

  @override
  String get screenShareViewerMinimize => 'Minimizar';

  @override
  String get screenShareViewerLeave => 'Sair';

  @override
  String screenShareViewerWaitingStream(String name) {
    return 'Aguardando transmissão de tela de $name...';
  }

  @override
  String get screenShareViewerConnecting => 'Conectando à transmissão...';

  @override
  String get viewOnceVideoTitle => 'Vídeo · Visualização única';

  @override
  String get viewOncePhotoTitle => 'Foto · Visualização única';

  @override
  String get viewOnceCantOpen => 'Não foi possível abrir este arquivo.';

  @override
  String get viewOnceUnavailable => 'Arquivo não mais disponível.';

  @override
  String get viewOnceBlockedFooter => 'Capturas de tela bloqueadas.';

  @override
  String get anonRestoreBanner => 'Mostrar banner de chat anônimo';

  @override
  String get contactsInviteFriends => 'Convide amigos para o GupShupGo';

  @override
  String get inviteImageShareFailed =>
      'Não foi possível compartilhar a imagem. Tente novamente ou compartilhe o link.';

  @override
  String get viewOnceUnblockedFooter => 'Apenas visualização única.';

  @override
  String get tabMessages => 'Mensagens';
}
