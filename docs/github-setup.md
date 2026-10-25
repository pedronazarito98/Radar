# Ativar a conexão GitHub do Radar

Esta é uma configuração única de quem mantém o Radar. Depois dela, a conexão cotidiana será: autorizar no navegador → escolher repositórios na lista → acompanhar PRs. O usuário não precisa escolher executável, usar terminal ou digitar owner/repo.

## Cadastro único no GitHub — pendente

Para uma conta pessoal, preparei um [atalho com opções de cadastro](https://github.com/settings/apps/new?name=Radar%20Pessoal&description=Consulta%20pessoal%20de%20PRs%20no%20Radar&public=false&webhook_active=false&request_oauth_on_install=false&pull_requests=read&checks=read&statuses=read). Ele abre o formulário; não cria nem instala o App. Confira as opções e complete nome disponível, Homepage e Device Flow. O preenchimento por URL é [documentado pelo GitHub](https://docs.github.com/en/apps/sharing-github-apps/registering-a-github-app-using-url-parameters); a tela real ainda não foi verificada nesta sessão.

1. Abra **Settings → Developer settings → GitHub Apps → New GitHub App** na conta proprietária.
2. Escolha um nome disponível e use a URL pública dessa conta como **Homepage URL**.
3. Ative **Enable Device Flow**; mantenha a expiração de tokens. Deixe **Request user authorization during installation** desmarcado e Callback vazio.
4. Desative **Active** em Webhook. Em **Repository permissions**, marque **Read-only** para **Pull requests**, **Checks** e **Commit statuses**. **Metadata** fica em leitura; demais permissões, sem acesso.
5. Escolha **Only on this account** para uso restrito à proprietária e crie o App. Repositórios de uma organização exigem decidir a conta proprietária e obter aprovação; não tornar público automaticamente.
6. Compartilhe somente **Client ID** e o endereço `https://github.com/apps/<slug>`. Não gere/envie secret ou chave privada. Em **Install App**, autorize apenas os repositórios desejados.

Fonte: [cadastro oficial de GitHub Apps](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app).

## Configuração local do build

Os valores públicos alimentam `RADAR_GITHUB_CLIENT_ID` e `RADAR_GITHUB_APP_SLUG` no projeto. O bundle lê `RadarGitHubClientID` e `RadarGitHubAppSlug` de Info.plist. Nenhum desses valores é uma credencial; nenhum segredo deve ser adicionado ao projeto. O build padrão deixa ambos vazios, portanto não consegue autorizar enquanto este gate estiver pendente.

O Codex pode inserir os dois valores públicos e recompilar após recebê-los. Não precisa de credenciais, arquivo de auth ou acesso ao Keychain para isso. A instalação/permissão do App é realizada pelo usuário no GitHub.

## Uso no Radar — gate real após configuração

1. Em Configurações → GitHub.com, use **Conectar ao GitHub**.
2. Copie o código mostrado e abra o GitHub pelo botão. Confira o nome do App e autorize pessoalmente no navegador.
3. Volte ao Radar. Busque os repositórios na lista carregada e selecione de 1 a 10. Carregue mais páginas quando disponível.
4. Use **Começar a acompanhar**. Só então o Radar consulta seus PRs nesses repositórios. Para alterar o escopo conectado, use **Salvar seleção**.
5. Se faltar um repo, use **Liberar acesso a outros repositórios no GitHub…**, ajuste a instalação no GitHub e use **Atualizar lista**. Política de organização pode exigir aprovação.

Os nomes vêm da implementação revisada. A [qualificação G03](evidence/G03.md) observou somente a tela sem cadastro, com **Conectar ao GitHub** indisponível; os demais estados ainda exigem execução real. Não enviar código de autorização ou token no chat. Cadastro, autorização, catálogo, refresh, Keychain e PRs reais permanecem NOT-RUN até observação; nenhum dado artificial substitui esses gates.

A renovação local não exige client secret quando a autorização original usou device flow, conforme a [documentação de refresh](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/refreshing-user-access-tokens). O Radar conserva apenas preferências não secretas fora do cofre.
