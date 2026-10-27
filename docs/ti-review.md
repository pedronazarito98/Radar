# Radar — informações para avaliação do time de TI

**27/10/2026 · Prévia pessoal 0.1.0 · Liberação corporativa ainda não concedida.**

O Radar é um app local SwiftUI/AppKit para **Apple Silicon e macOS 27+**. Reúne cards pessoais do Jira Cloud, PRs do GitHub.com e relações explícitas entre tarefa e PR. Código e [DMG/checksum](https://github.com/pedronazarito98/Radar/releases/tag/v0.1.0-personal.1) estão disponíveis para inspeção; a instalação no Mac de destino dispensa Xcode, Homebrew e gh.

## Acesso e permissões

- **GitHub:** o cadastro documentado solicita **Pull requests, Checks, Commit statuses e Metadata em leitura**, sem webhook. O usuário autoriza no navegador por device flow e escolhe 1–10 repositórios no catálogo. O acesso efetivo é limitado pelo usuário, permissões e instalação. Client ID/slug são públicos; não há client secret ou chave privada embarcados.
- **Trabalho remoto:** o código implementa somente GET de dados de trabalho; não implementa merge, aprovação, comentário ou transição Jira. Os POSTs existentes são para emissão/renovação de autorização GitHub, não para modificar PRs/cards.
- **Jira:** token pessoal inserido diretamente no app, somente se a organização permitir; autenticação email/token sobre HTTPS. O uso GET do Radar não restringe permissões adicionais que o token eventualmente possua. Site/projetos e escopos devem ser definidos pelo TI.

## Rede implementada

| Destino HTTPS | Finalidade |
|---|---|
| github.com | POST /login/device/code e /login/oauth/access_token; autorização/instalação e abertura de links no navegador. |
| api.github.com | GET de usuário, instalações/catálogo, repos/PRs, busca pessoal nos repos selecionados, checks, statuses e revisões. |
| tenant.atlassian.net, para o tenant autorizado | Descoberta /_edge/tenant_info e GET REST v3 de identidade, busca e issues; navegação ao Jira. |
| api.atlassian.com | Gateway /ex/jira/{cloudId}/rest/api/3 para token Jira com escopos. |

As sessões HTTP do app são efêmeras, recusam redirecionamentos e não usam cache/cookies/cofre de credenciais compartilhados. Há timeout de até 15 s, limite de saída/páginas, cancelamento e backoff. O download do instalador usa a infraestrutura de Releases/assets do GitHub pelo navegador; isso é separado das chamadas autenticadas do app. Não há backend de autenticação próprio.

## Dados locais

Conteúdo de cards/PRs é mantido em memória, sem cache de trabalho implementado em disco. Preferências não secretas em Application Support/Radar incluem site/email/projetos Jira, IDs e nomes dos repos escolhidos, categorias/tela e referências UUID. Tokens ficam em itens próprios do Keychain, sem sincronização configurada; retomada após iniciar é explícita, e sessão GitHub ativa pode renovar/gravar o par rotacionado. O pacote não inclui contas, preferências ou credenciais do desenvolvedor. Não enviar tokens/códigos em chat ou ticket de avaliação.

## Pacote e limites da evidência

- DMG v0.1.0-personal.1, app 0.1.0 (1), bundle ID **dev.pedronazarito.Radar**.
- SHA-256 DMG: `c88a2f63d3bb9defa2567ec651840aa6535e2a6ba2d3500f24f2ed3dc01c1200`.
- Assinatura **ad-hoc**, Hardened Runtime, **sem notarização Apple e sem App Sandbox**. Avaliação local Gatekeeper: **rejected**. O TI deve definir o método de confiança/instalação permitido no Mac gerenciado; não desativar proteções ou contornar MDM.
- Build Release, integridade/assinatura estrita, montagem/cópia do DMG e comparação do download passaram; revisão estática e de empacotamento sem bloqueadores no escopo observado. Não são certificação Apple nem garantia de ausência de vulnerabilidades.
- Fluxo GitHub pessoal observado até catálogo/escolha/consulta vazia; Jira, dados preenchidos/relações, casos condicionais de sessão, acessibilidade e primeiro uso no outro Mac continuam em qualificação. Não há atualizador automático. Testes/mocks e Swift lint não foram executados por política do projeto. Evidências: [P02](evidence/P02.md), [P03](evidence/P03.md) e [gates](evidence/pending-gates.md).

## O que o TI precisa decidir

O **repositório fonte público não torna o GitHub App público**. O cadastro pessoal documentado usa **Only on this account**: um App privado pessoal só pode ser instalado na conta proprietária. A organização precisa definir um cadastro instalável nela e aprovar permissões, repositórios, instalação/SSO, política Jira, rede e instalação do pacote. Nenhuma dessas configurações foi alterada para tornar o código público; nenhum acesso corporativo ou uso por outras contas está declarado liberado.

Fontes e pontos de inspeção: [regra de instalação GitHub App](https://docs.github.com/en/apps/using-github-apps/installing-your-own-github-app), [autorização em nome do usuário](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-with-a-github-app-on-behalf-of-a-user), [transport GitHub](../Radar/Integrations/GitHub/GitHubNetworkTransport.swift), [endpoints](../Radar/Integrations/GitHub/GitHubEndpoint.swift), [Jira](../Radar/Integrations/JiraCloud/JiraCloudConnection.swift), [persistência](../Radar/Persistence/PreferencesStore.swift), [cofre GitHub](../Radar/Persistence/GitHubCredentialVault.swift) e [primeira abertura macOS](https://support.apple.com/pt-br/102445).
