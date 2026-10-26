# Ativar a conexão GitHub do Radar

Esta é uma configuração única de quem mantém o Radar. Depois dela, a conexão cotidiana será: autorizar no navegador → escolher repositórios na lista → acompanhar PRs. O usuário não precisa escolher executável, usar terminal, copiar IDs ou digitar owner/repo.

## Ativação assistida — caminho principal

O Codex prepara o cadastro e as permissões; o usuário fica com as confirmações pessoais no GitHub. Não exigir que leia as opções técnicas abaixo ou configure o build.

1. Quando o GitHub pedir, confirme sua identidade pelo método que já usa, diretamente no navegador.
2. Confira o cadastro preparado e confirme a criação; depois escolha os repositórios permitidos e confirme a instalação/autorização quando solicitado. Cada etapa é apresentada na tela antes de qualquer confirmação.
3. O Codex coleta somente Client ID/endereço públicos na UI e configura o build. No Radar, use **Conectar ao GitHub**, autorize no navegador e escolha os repos na lista.

Não há senha, código ou token para enviar no chat. O cadastro próprio ainda é exigido pelo GitHub; o fluxo assistido reduz o trabalho manual, sem prometer removê-lo.

**Estado observado:** G04 confirmou cadastro próprio privado, instalação e build configurado sem cópia de IDs pelo usuário. Em [G05](evidence/G05.md), o usuário concluiu a autorização e a escolha de escopo; o Radar carregou 68 repos, filtrou a lista e recebeu consulta com 0 PRs pessoais. Não é necessário repetir o cadastro. Renovação/retomada/remoção do cofre e conteúdo preenchido permanecem em gates próprios.

## Referência de configuração — para quem prepara o cadastro

Para uma conta pessoal, preparei um [atalho com opções de cadastro](https://github.com/settings/apps/new?name=Radar%20Pessoal&description=Consulta%20pessoal%20de%20PRs%20no%20Radar&public=false&webhook_active=false&request_oauth_on_install=false&pull_requests=read&checks=read&statuses=read). Ele abre o formulário; não cria nem instala o App. Confira as opções e complete nome disponível, Homepage e Device Flow. O preenchimento por URL é [documentado pelo GitHub](https://docs.github.com/en/apps/sharing-github-apps/registering-a-github-app-using-url-parameters); a tela real ainda não foi verificada nesta sessão.

1. Abra **Settings → Developer settings → GitHub Apps → New GitHub App** na conta proprietária.
2. Escolha um nome disponível e use a URL pública dessa conta como **Homepage URL**.
3. Ative **Enable Device Flow**; mantenha a expiração de tokens. Deixe **Request user authorization during installation** desmarcado e Callback vazio.
4. Desative **Active** em Webhook. Em **Repository permissions**, marque **Read-only** para **Pull requests**, **Checks** e **Commit statuses**. **Metadata** fica em leitura; demais permissões, sem acesso.
5. Escolha **Only on this account** para uso restrito à proprietária e crie o App. Repositórios de uma organização exigem decidir a conta proprietária e obter aprovação; não tornar público automaticamente.
6. O Codex pode coletar somente **Client ID** e o endereço `https://github.com/apps/<slug>` na UI, sem exigir cópia pelo usuário. Não gerar/ler secret ou chave privada. Em **Install App**, o usuário autoriza apenas os repositórios desejados.

Fonte: [cadastro oficial de GitHub Apps](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app).

## Configuração local do build

Os valores públicos alimentam `RADAR_GITHUB_CLIENT_ID` e `RADAR_GITHUB_APP_SLUG` no projeto. O bundle lê `RadarGitHubClientID` e `RadarGitHubAppSlug` de Info.plist. Nenhum desses valores é uma credencial; nenhum segredo deve ser adicionado ao projeto. G04 configurou o registro próprio `radar-pessoal-pedro` nas duas configurações do build; o app já pode iniciar a autorização.

O Codex pode inserir os dois valores públicos e recompilar após coletá-los da interface. Não precisa de credenciais, arquivo de auth ou acesso ao Keychain para isso. A instalação/permissão do App é realizada pelo usuário no GitHub.

## Uso no Radar — gate real após configuração

1. Em Configurações → GitHub.com, use **Conectar ao GitHub**.
2. Copie o código mostrado e abra o GitHub pelo botão. Confira o nome do App e autorize pessoalmente no navegador.
3. Volte ao Radar. Busque os repositórios na lista carregada e selecione de 1 a 10. Carregue mais páginas quando disponível.
4. Use **Começar a acompanhar**. Só então o Radar consulta seus PRs nesses repositórios. Para alterar o escopo conectado, use **Salvar seleção**.
5. Se faltar um repo, use **Liberar acesso a outros repositórios no GitHub…**, ajuste a instalação no GitHub e use **Atualizar lista**. Política de organização pode exigir aprovação.

Os nomes vêm da implementação revisada. A [qualificação G03](evidence/G03.md) preserva a tela histórica sem cadastro; [G04](evidence/G04.md) configurou a integração e G05 qualificou o fluxo normal autorizado até consulta vazia. Não enviar código de autorização ou token no chat. Cenários condicionais, refresh/retomada/remoção e PRs preenchidos ainda exigem observação própria; nenhum dado artificial substitui esses gates.

A renovação local não exige client secret quando a autorização original usou device flow, conforme a [documentação de refresh](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/refreshing-user-access-tokens). O Radar conserva apenas preferências não secretas fora do cofre.
