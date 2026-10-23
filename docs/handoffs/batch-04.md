# Handoff — lote4 / integrações pessoais

Preparação local T22–T28 concluída; gates externos permanecem PARTIAL/NOT-RUN. Próximo escritor inicia T29, corrige C06 antes de T30 e segue T30–T35. Não reiniciar T01. Ler AGENTS, STATE e contratos C1–C1.10 publicados antes de consumir APIs.

## Commits e evidência

| Trabalho | Commit | Evidência |
| --- | --- | --- |
| T22 — cofre próprio | 671efae | T22.md; BUILD/REVIEW PASS, runtime NOT-RUN |
| T23 — conexão Jira | cb9c140 | T23.md; BUILD/REVIEW PASS, LIVE NOT-RUN |
| C04 — cooldown por origem | 3b8a1a6 | C04.md; BUILD/REVIEW state_audit PASS |
| C05 — indisponibilidade | 2eed4b3 | C05.md; BUILD/REVIEW PASS |
| T24 — busca Jira | 330d241 | T24.md; BUILD/REVIEW PASS, LIVE NOT-RUN |
| T25 — executável gh | 10871d4 | T25.md; BUILD/REVIEW/UI-gh versão PASS |
| T26 — transporte gh | 272ba61 | T26.md; BUILD/REVIEW PASS, LIVE NOT-RUN |
| T27 — PRs pessoais | fb5ed1b | T27.md; BUILD/REVIEW PASS, LIVE NOT-RUN |
| T28 — detalhe por SHA | 3c6ebc2 | T28.md; BUILD/REVIEW independente PASS, LIVE NOT-RUN |

T13 recebeu revisão independente retomada; T14 teve achado corrigido/revisado em C04. A indisponibilidade anterior de revisão deixou de ser bloqueio. Não confundir revisão estática com UAT real.

## APIs para o lote seguinte

- RadarAppDelegate possui um RefreshScheduler compartilhado pelos controllers Jira/GitHub/lista/detalhe. GitHubConnectionController fornece connectionID, identity, executable e transport qualificados; store mantém escopo e contexto. Conexão somente por intenção explícita. Não há auto-connect no reinício.
- GitHubCLITransport.withBatch serializa lote inteiro e inclui callback de publicação dentro da lease. GitHubReadSession.get usa endpoints tipados GET github.com, reserva chamada final e preserva backoff/status sanitizado. GitHubEndpoint já inclui pulls/reviews/requests/checks/statuses. Falta C06: budget nasce depois de adquirir lease, portanto FIFO ainda fora prazo; criar orçamento antes da espera, expirar waiter e oferecer orçamento compartilhado para relação20/30s conforme C1.10.
- GitHubPersonalPRProvider.fetchAndPublish mantém três buscas, aliases e snapshot; headSHA/headRef nil. SSO200partial é rejeitado conservadoramente; não declarar escopo omitido completo. GitHubBatchFailure carrega problemas observados mesmo com falha final/cancelamento.
- GitHubPRDetailEnricher.fetchAndPublish qualifica GET PR, CI e revisão em lote20/30s com /user nas duas fronteiras. GitHubPRDetailObservation só chega ao callback depois da fronteira final. GitHubDetailController.configure(item:selection:) atende PR contextual autorizado sem inserir snapshot; selectionChanged() atende seleção pessoal existente. Callback verifica connectionID/SelectionToken/request antes de PRDetailStore.observeHead + publish(problem:for:).
- PRDetailStore usa headSHA + detailGeneration + selectionGeneration. O instante do término da lista não ordena observação de head. Branch consultada para relação não vira autoridade de CI.
- JiraCloudConnection.read(expectedConnectionID:path:query:) ainda permite apenas myself/search/jql; T30 precisa endpoint contextual mínimo, timeout restante e orçamento compartilhado. JiraIssueDTO atual aplica filtro pessoal; separar validação estrutural/escopo de assignee/status para contextual. Não colocar payload/segredo em store/prefs.
- C1.10 exige relações com dois connectionIDs, seleção e geração/operação própria, problemas tagged por origem, dependências/ocupação de escopos no scheduler. Relação não cria polling global. T32 integra sleep/wake e ciclo, preservando slot até término real.

## Limites e interação humana

Nenhuma consulta de conta/API/cofre foi executada pelo agente. T25 confirmou gh2.96.0 por --version/help público e pela UI real do bundle (parent/root): botão Validar gh mostrou versão e que autenticação não foi consultada. Não certifica Finder autenticado, API ou conta. Não houve teste/mock/fixture/sensor/lint.

T34 deve persistir referência não secreta UUID antes do save no Keychain, inclusive tentativa pendente. Hoje a referência em memória permite retry/remoção no processo, mas reinício nesse intervalo ainda pode perdê-la. Antes dessa persistência, não solicitar entrada real de token no build intermediário. Cancelamento/negação nunca é sucesso; remoção falha limpa segredo em memória e conserva referência.

[Checklist de gates pendentes](../evidence/pending-gates.md) concentra política/site/projetos/repos, LIVE e validações humanas. Quando disponíveis, usuário informa segredo somente no app; nunca chat/terminal/agente. Não capturar UI com entrada secreta disponível. Conta externa A→B→A entre fronteiras não observadas permanece limitação; nenhum novo lote sem /user final válido.

## Ownership

providers_writer concluiu T28 e este handoff, encerra alterações e libera explicitamente a escrita para root/relations_writer após o commit documental. Árvore sem alterações pendentes. Próximo trabalho: T29; nenhuma implementação de T29 foi iniciada aqui.
