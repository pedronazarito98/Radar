# Radar — pesquisa e limites de evidência

**Data da consolidação**: 22/10/2026. **Objetivo**: fundamentar o plano, sem implementar ou configurar o app.  
Fontes primárias foram consultadas pelos agentes de planejamento; para Codex, a pesquisa oficial antecedeu a consulta local da skill. Context7 apoiou a pesquisa das APIs, com confirmação nas páginas oficiais. Requalificar APIs/versões na execução quando necessário.

## Decisões fundamentadas

| Tema | Evidência documental | Consequência no plano |
|---|---|---|
| Conteúdo nativo em painel | [NSHostingView](https://developer.apple.com/documentation/swiftui/nshostingview), [NSPanel](https://developer.apple.com/documentation/appkit/nspanel) | SwiftUI com ponte AppKit pequena; não usar UI web sem benefício demonstrado. |
| Recorte real | [safeAreaInsets](https://developer.apple.com/documentation/appkit/nsscreen/safeareainsets), [área superior esquerda](https://developer.apple.com/documentation/appkit/nsscreen/auxiliarytopleftarea-uglc), [direita](https://developer.apple.com/documentation/appkit/nsscreen/auxiliarytoprightarea-gr2n) | Calcular por tela; a câmera não é um alvo clicável. |
| Foco de painel | [nonactivatingPanel](https://developer.apple.com/documentation/appkit/nswindow/stylemask-swift.struct/nonactivatingpanel), [becomesKeyOnlyIfNeeded](https://developer.apple.com/documentation/appkit/nspanel/becomeskeyonlyifneeded) | Flag de janela não prova navegação por teclado; conferir foco por causa do fechamento. |
| Processo externo | [Process](https://developer.apple.com/documentation/foundation/process), [environment](https://developer.apple.com/documentation/foundation/process/environment), [terminationHandler](https://developer.apple.com/documentation/foundation/process/terminationhandler) | Subprocesso assíncrono limitado; sandbox herdado precisa ser considerado. |
| Entrega macOS | [Preparar distribuição](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution), [Hardened Runtime](https://developer.apple.com/documentation/security/hardened-runtime) | Bundle pessoal/assinatura são qualificados; publicação/notarização ficam fora. |
| Token pessoal Jira | [Gerenciar API tokens](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/) | Método pessoal condicionado à política da conta; escopos/tipo/gateway não presumidos. |
| OAuth Jira | [OAuth 2.0 3LO](https://developer.atlassian.com/cloud/jira/platform/oauth-2-3lo-apps/) | Fluxo documentado usa client_secret; não embutir segredo no app nem prometer PKCE público sem suporte documentado. Reavaliar distribuição. |
| Busca Jira | [Issue search REST v3](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue-search/) | Enhanced search e nextPageToken; não iniciar no endpoint legado. |
| Vínculos Jira | [Development Information](https://developer.atlassian.com/cloud/jira/software/rest/api-group-development-information/), [GitHub for Jira](https://support.atlassian.com/jira-cloud-administration/docs/use-the-github-for-jira-app/) | Não assumir que o desktop pode ler universalmente o painel Development. Referências explícitas têm proveniência própria. |
| Auth gh | [gh auth login](https://cli.github.com/manual/gh_auth_login) | O próprio CLI administra auth e pode usar fallback em arquivo. Radar não extrai nem examina essa auth. |
| REST gh | [gh api](https://cli.github.com/manual/gh_api) | Método GET explícito, host fixo e parâmetros estruturados permitidos; não usar comando arbitrário. |
| Ambiente gh | [gh environment](https://cli.github.com/manual/gh_help_environment), [exit codes](https://cli.github.com/manual/gh_help_exit-codes) | Não herdar tokens/debug de terminal; desativar prompts; code 4 e code 1 têm semânticas distintas. |
| PRs pessoais | [Buscar issues/PRs](https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests), [REST search](https://docs.github.com/en/rest/search/search) | Consultas por papel, união por identidade e completude; limite da busca existe mesmo via CLI. |
| Branches de PRs | [REST pull requests](https://docs.github.com/en/rest/pulls/pulls) | Listagem por repo fornece título/head ref para relações; não inventar qualificador de busca por branch. |
| CI e revisão | [Commit statuses](https://docs.github.com/en/rest/commits/statuses), [Checks](https://docs.github.com/en/rest/checks/runs), [Reviews](https://docs.github.com/en/rest/pulls/reviews) | Examinar SHA atual e separar conceitos; ausência/permissão negada não certifica sucesso. |
| Escopos existentes | [OAuth scopes](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps) | Token clássico com repo pode permitir escrita; Radar limitar operações não altera a permissão existente. |
| Subagentes Codex | [Documentação oficial](https://learn.chatgpt.com/docs/agent-configuration/subagents), [customização](https://learn.chatgpt.com/docs/customization/overview) | Delegação, contexto e cautela em edição paralela; protocolo de contratos/mensagens é decisão deste projeto. |

Fatos documentais não são comprovação de execução no Mac do usuário. A stack, o modo sem App Sandbox e os parâmetros de refresh/animação continuam propostas A01–A13.

## Evidência REA reaproveitada

Artefato público já analisado no estudo visual: Boring Notch 2.7.3 em DMG.

- SHA-256: `23786382548d33c59b309db558e513a92e3f95b63d611544dcddf5d196e46698`.
- Hash do arquivo local reconferido nesta etapa; não foi repetida a análise sem necessidade.
- Inventário: 229 nós/249 ocorrências.
- Evidence ID de inventário: `ev_87ab2f621d937034d80dd44186534310a52992788fdab200aa25bfb95b3ed5a0`.
- Plist: LSUIElement=true, versão 2.7.3, mínimo declarado macOS 14.
- Evidence ID do plist: `ev_f09d8121104d261e8f1523bc944131a8d5a6e20d0b2ef083e7c3a522022aac5a`.

O inventário sanitizado está preservado em references/evidencias-rea.json neste repositório e no pacote original. O DMG/binário de terceiro não é necessário para implementar Radar e não será distribuído no plano.

Essa evidência mostra organização/metadados do pacote. **Não prova** tecnologia de animação, desempenho, foco, comportamento no fullscreen, permissões reais ou compatibilidade de runtime com macOS 27. Nenhum binário de terceiro foi executado nesta etapa.

A pesquisa comparativa anterior está no estudo visual preservado. O plano usa princípios de interação e APIs públicas; não copia implementação de concorrente.

## Protocolo para investigação futura

1. Declarar pergunta concreta, alvo autorizado, hash e tipo de evidência necessário.
2. Para código fonte próprio completo, usar ferramentas normais de código.
3. Reaproveitar sessão/evidência existente quando responde à pergunta.
4. Abrir somente a superfície necessária; não ler credenciais/logs/bancos/auth/históricos.
5. Separar observado de inferido e não verificado. Registrar IDs e limites, não payloads.
6. Não executar terceiro, instalar engines ou reconfigurar REA automaticamente; autorização deve cobrir o efeito real.

Nenhuma investigação adicional é pré-requisito automático de todos os lotes.

## Estado das verificações

| Verificação | Resultado nesta etapa |
|---|---|
| Pesquisa documental | Realizada; fontes e limites acima. |
| Comunicação entre especialistas | Realizada; contratos consolidados em design.md. |
| Hash do artefato público já existente | Reconferido. |
| Coerência do pacote de plano | Será registrada em plan-review.md após revisão. |
| Toolchain/SDK/gh instalados | Não qualificados para este app. |
| Jira/GitHub reais | Não conectados/consultados por este planejamento. |
| Build, lint, testes, execução do app | Não realizados; app ainda não existe. |
| VoiceOver, telas, recursos, Finder | Não realizados; gates de implementação futuros. |
| Instalação/publicação/distribuição | Não realizadas. |

## Distribuição futura

Preparar fronteiras de provider e identidade na V1 evita acoplar views ao processo gh. Não implementar quatro adapters, backend OAuth, updater ou múltiplos tenants antecipadamente. Uma especificação futura decidirá GitHub App/device flow, Jira 3LO com componente confidencial adequado, modelos comerciais, assinatura/notarização e ambientes Enterprise.

