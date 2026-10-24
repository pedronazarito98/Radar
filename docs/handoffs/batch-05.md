# Handoff — lote5 / relações, recuperação e ciclo

Preparação local T29–T35 concluída sob AD-013; gates obrigatórios externos permanecem Prepared/PARTIAL/NOT-RUN. Próximo escritor executa T36–T38, seguido da qualificação T39–T42. Ler AGENTS, STATE, design C1–C1.11 e verification-plan antes de consumir APIs. Não reiniciar tarefas já implementadas nem considerar BUILD como aceite LIVE.

## Commits e gates

| Trabalho | Commit | Evidência |
| --- | --- | --- |
| T29 — referências textuais | cce213e | T29.md; BUILD/REVIEW independente PASS |
| C06 — prazo inclui fila gh | d1af26d | C06.md; BUILD/REVIEW PASS, corridas NOT-RUN |
| T30 — resolução bidirecional | 9b30356 | T30.md; BUILD/REVIEW PASS, LIVE NOT-RUN |
| C07 — excluir URLs reconhecidas | 9957c09 | C07.md; REVIEW PASS, BUILD em árvore com WIP T31 |
| T31 — seleção e relações contextuais | e13e1ab | T31.md; BUILD integrado/REVIEW PASS, LIVE/foco preenchido NOT-RUN |
| T32 — scheduler por escopo | d81169d | T32.md; BUILD/REVIEW PASS, LIVE/sleep-wake NOT-RUN |
| T33 — recuperação explícita | 791c6ac | T33.md; BUILD/REVIEW PASS, recuperação real NOT-RUN |
| T34 — preferências e referência própria | 965578b | T34.md; BUILD/REVIEW persistência PASS, reinício/cofre NOT-RUN |
| T35 — ciclo e identidade | 066b86b | T35.md; BUILD/REVIEW PASS, LIVE-Origens/shutdown NOT-RUN |

relations_review fez revisão independente estática com contexto canônico fresco e comunicação entre pares. Corrigimos seus achados antes dos commits: fronteiras Unicode, repetição/conflito em paginação, dedup por par, origem dos erros, retomada de consulta no wake e reconexão A→A coalescida. Os builds Debug reais usaram `./script/build_and_run.sh --build-only`, exit0; o último abrange todo o código até T35. Não criamos/executamos testes, mocks, fixtures, harness, sensor ou lint. Nenhuma conta/API/auth/cofre/arquivo real de preferências foi acessado pelo agente.

## Contratos e APIs de consumo

- **Composição/ciclo:** RadarAppDelegate possui um DataLifecycleController e o inicia em applicationDidFinishLaunching, encerrando em applicationWillTerminate. SourceRefreshCoordinator pertence a esse ciclo e é o único observador de sleep/wake. Não duplicar start/stop, observers ou scheduler em T36/T38. PreferencesController.load lê metadata própria, sem conexão ou acesso automático ao Keychain.
- **Seleção/detalhe:** RelatedItemsCoordinator é o único owner de consultas relativas à seleção. `selectionChanged(force:)` resolve `store.jiraItem(id)`/`store.pullRequest(id)` em lista pessoal ou contexto e chama `GitHubDetailController.configure(item:selection:)` para PR. Não voltar ao callback pessoal `selectionChanged()` do detail controller, pois ele descartaria seleção contextual. RadarContentView já observa RelatedItemsTrigger e para o coordinator no desaparecimento.
- **Relações/foco:** `store.selectRelated(key)` valida a aresta atual e conserva a primeira origem pessoal em SelectionStore. Esc retorna à linha original quando ainda disponível, sem transferência por índice. Alias fallback→ID estável reconcilia seleção/foco/contexto e mantém revision/ordem/contadores; publicação troca atomicamente para o token canônico. RelatedItemsStore retém somente a observação atual (incluindo subject), sem cache crescente de navegação. Contexto não entra nas listas/totais.
- **UI existente:** faixa inferior já mostra relações reais, proveniência, recorte por direção e chaves textuais fora de URLs; atualização explícita está ligada a `related.refresh()` e ao target `.refreshDetails` com guardas de disponibilidade/busy na UI e no coordinator. Targets `.related` preservam retorno. T37 implementa abrir/copiar e seus targets, mantendo foco e URLs validadas; ainda não qualificados nem ligados neste lote.
- **Orçamento/transporte:** C06 cria RequestBudget antes de adquirir lease, com waiter por ID e deadline monotônico absoluto. RelationResolver compartilha 20 chamadas/30 s entre Jira e GitHub, reservando /user final. Timeout Jira usa restante; headers de backoff são interpretados antes de cancelamento. Lote só publica dentro da lease após fronteira final válida e guardas de seleção/operação/escopos/conexões. Branch consultada para relação não promove headSHA; T28 continua autoridade de detalhe/CI.
- **Parser/escopo:** JiraKeyReferenceExtractor exige token ASCII inteiro, fronteiras Unicode e projeto/site autorizados; deduplica e une título/branch. C1.11 exclui candidatos dentro de URLs reconhecidas por NSDataDetector usando intervalos originais, de qualquer host. Não promete reconhecimento universal/decodificação de URI. Resolução contextual Jira permite outro assignee/status dentro do escopo, sem mudar filtros pessoais.
- **Scheduler:** RefreshScheduler é compartilhado. Lista 60 s, detalhe visível 15 s, relação on demand. Ocupação de todos SourceScopes da operação é atômica por runID e só termina no finish real, inclusive após cancel/remove. Origens independentes podem progredir em paralelo. OriginProblem preserva cooldown da origem mesmo em callback descartado; relação depende das duas. Sleep cancela e wake rearma recorrentes/one-shot pendentes, sem repetir relação já concluída. Cada execução efetiva de relação cria queryID/begin novos.
- **Identidade de configuração:** SourcePresentationState.configurationID muda quando a instância é recriada por configure/invalidate e permanece em snapshot/status/reconciliação. SourceRefreshCoordinator inclui ID na assinatura para observar disconnect→reconnect do mesmo escopo, mesmo se enum connected for coalescido. Não substituí-lo por igualdade de escopo/status apenas.
- **Recuperação:** ConnectionRecoveryController fornece planos tipados por origem; forms exibem guidance sanitizada e ações explícitas repetíveis. Source retry e relações já têm callers. Erro de auth é distinto de 403/SSO, indisponibilidade ou gh ausente/incompatível. Não executar login/refresh/switch nem inferir necessidade de escopo adicional.
- **Persistência:** PreferencesStore limita schema próprio a configuração não secreta, UUID Jira, ghPath validado, repos, tela e categorias explícitas. Ausência aceita defaults; corrupção/versão desconhecida/read failure bloqueia writes e preserva referência. Escrita atômica+synchronize precede vault.save. Falha de save mantém referência; remoção exige vault/no-item, depois prefs write, só então limpa memória. Startup não chama vault.read; retomar exige intenção/política explícitas e requalifica identidade.
- **T38:** `preferences.snapshot.preferredDisplayID` é a preferência de display; formulário já permite escolha/automático. Aplicação/fallback dinâmico no painel fica para T38. Categorias WEB/API/Infra/Outro já são escolha explícita persistida e rótulo nas linhas GitHub. Não inferir por nome do repo nem alterar preferências globais.
- **Desconexão/shutdown:** DataLifecycleController usa hook de GitHub para parar lista/detalhe/relações da origem invalidada, preservando lista Jira. Resume/remove Jira invalida uso ativo primeiro; view mantém guarda de geração antes de publicar. Shutdown limpa estado em memória e observers sem apagar cofre/prefs. Cancelamento é guardado também dentro do actor CredentialVault antes da chamada Security; não promete interromper chamada síncrona já iniciada nem zeroização síncrona verificável.

## Gates pendentes e limites

[Registro de interação](../evidence/pending-gates.md) continua válido: política/site/projetos/repos não são inventados; LIVE de listas/relações/CI/revisões, transição de conta e isolamento, conteúdo/foco/teclado preenchidos, sleep/wake, persistência/reinício/consentimento/negação, VoiceOver/Reduzir Movimento, cenários individuais de display/modos, medições e Release permanecem sem evidência deste lote. T36 deve qualificar composição real e T42 conservar os limites por critério.

A implementação de T34 permite a próxima verificação humana do fluxo seguro, mas BUILD/revisão não comprova Keychain ad-hoc. Usuário informa eventual segredo somente no SecureField, nunca chat/terminal/agente; não capturar UI enquanto entrada secreta está disponível. Nenhuma credencial gh é apagada/alternada. Conta A→B→A entre fronteiras não observadas permanece limitação; callback sem /user final válido não publica novo lote.

## Ownership

relations_writer encerra alterações de código do lote5 e libera explicitamente a escrita após o commit deste handoff. Árvore sem alterações pendentes nesse ponto. Root coordena native_finish_readiness como próximo escritor, com native_final_review independente. Nenhuma implementação de T36–T38 foi iniciada pelo autor deste handoff.
