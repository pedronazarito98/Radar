# STATE — Radar

## Decisions

### AD-001
- **Decision**: Esta autorização cobre o plano; a implementação do aplicativo ainda não começou.
- **Reason**: O usuário pediu o plano depois da exploração visual.
- **Trade-off**: Código, instalação, configuração ativa, integrações reais e distribuição aguardam autorização da etapa correspondente.
- **Scope**: Todo o projeto.
- **Date**: 2026-10-22
- **Status**: superseded somente quanto à implementação local por AD-009; histórico preservado.

### AD-002
- **Decision**: Preservar a identidade Radar revisão 3: superfície preta, duas colunas, seleção cinza, faixa inferior e nenhuma barra colorida lateral.
- **Reason**: Organização e identidade escolhidas e refinadas pelo usuário.
- **Trade-off**: Novas propostas visuais não substituem a base sem decisão explícita.
- **Scope**: Interface e revisão visual.
- **Date**: 2026-10-22
- **Status**: active

### AD-003
- **Decision**: Notch fechado por padrão, abrir por clique, contagens pessoais distintas dos vínculos, CI e revisão separados, consulta vazia distinta de falha.
- **Reason**: Comportamentos solicitados e comentários aprovados na conversa.
- **Trade-off**: Origem do vínculo, fase do PR e estados parciais exigem rótulos próprios.
- **Scope**: Domínio e experiência.
- **Date**: 2026-10-22
- **Status**: active

### AD-004
- **Decision**: A V1 é pessoal, com Jira Cloud e GitHub.com, considerando o gh CLI existente; distribuição e Enterprise ficam para evolução.
- **Reason**: Respostas explícitas do usuário nesta etapa.
- **Trade-off**: gh é pré-requisito externo para a proposta inicial e a política da conta Jira ainda precisa permitir o método pessoal.
- **Scope**: Integrações e entrega inicial.
- **Date**: 2026-10-22
- **Status**: superseded na parte gh por AD-018/G1; demais limites preservados

### AD-005
- **Decision**: Não criar testes, arquivos de teste ou mocks sem pedido explícito; gates e relatórios devem distinguir evidência manual, build e automação não executada.
- **Reason**: Regra expressa no AGENTS.md fornecido pelo usuário.
- **Trade-off**: A TLC será adaptada com matriz de verificação; não haverá alegação de cobertura automatizada ou sensor de mutação realizado.
- **Scope**: Planejamento, implementação e verificação.
- **Date**: 2026-10-22
- **Status**: active

### AD-006
- **Decision**: Agentes não leem/copiam credenciais, sessões, arquivos de auth, logs, bancos SQLite, paste cache ou históricos brutos; valores secretos nunca entram em contexto ou saídas.
- **Reason**: Restrição explícita de segurança do usuário.
- **Trade-off**: Verificação usa saídas sanitizadas, estados de UI e metadados permitidos. Credenciais futuras são inseridas diretamente no app e manipuladas somente por seu fluxo de autenticação.
- **Scope**: Agentes, documentação e integração.
- **Date**: 2026-10-22
- **Status**: active

### AD-007
- **Decision**: Usar subagentes com contexto canônico e comunicação explícita; manter autor e verificador independentes.
- **Reason**: Pedido direto do usuário e fechamento da TLC.
- **Trade-off**: Mensagens não substituem documentos versionados; edição de código segue um único escritor por lote.
- **Scope**: Execução com Codex.
- **Date**: 2026-10-22
- **Status**: active

### AD-008
- **Decision**: Ler estrutura antes de editar, preservar convenções, importar diretamente, evitar dependências e mudanças fora do escopo; aplicar tipagem segura na stack escolhida.
- **Reason**: AGENTS.md fornecido na conversa.
- **Trade-off**: Sem barrel exports, reexportação por index, arquitetura nova sem necessidade ou testes adicionados por padrão.
- **Scope**: Todo código futuro, inclusive eventual TypeScript.
- **Date**: 2026-10-22
- **Status**: active

### AD-009
- **Decision**: Autorizar implementação local da V1 e repositório dedicado /Users/pedronazarito/Developer/Radar; esta decisão supera AD-001 somente no limite de implementação local. Sem publicação, remotes, instalação ou configuração global.
- **Reason**: Pedido explícito do usuário em 22/10/2026 e prompt-nova-sessao-radar.md.
- **Trade-off**: Acesso/política Jira, entrada segura e gates de runtime ainda dependem de evidência; não são aprovados por presunção.
- **Scope**: Execute local; fonte canônica migrada para este repositório, pacote original preservado.
- **Date**: 2026-10-22
- **Status**: active

### AD-010
- **Decision**: Adotar A01/A04–A12 como ponto de partida técnico: Xcode SwiftUI/AppKit, bundle dev.pedronazarito.Radar, assinatura local ad-hoc com Hardened Runtime sem App Sandbox; reabrir visão geral, tela com notch e menu fallback; dados de trabalho em memória; 250/180/120 ms; cadências 60/15 s; timeout 15 s, 5 MiB, 10 páginas, relação 20 chamadas/30 s.
- **Reason**: Autorização de implementar as propostas do plano e qualificação inicial do ambiente.
- **Trade-off**: Tempos são parâmetros, não medições. Escopos concretos A08 são entrada pendente; A03/política Jira e A13/capacidades não são presumidos. Assinatura ad-hoc pode exigir novo consentimento Keychain após rebuild, a observar pelo usuário no app.
- **Scope**: Base local; qualificação Finder/CLI e runtime permanece nos gates próprios.
- **Date**: 2026-10-22
- **Status**: active

### AD-011
- **Decision**: Contrato C1.1 publicado pelo orquestrador antes dos consumidores: ambiente gh construído do zero, HOME canônico por FileManager, PATH fixo; GH_PROMPT_DISABLED=1, GH_NO_UPDATE_NOTIFIER=1, GH_NO_EXTENSION_UPDATE_NOTIFIER=1, GH_TELEMETRY=false, GH_PAGER=cat e NO_COLOR=1. Ausentes GH_DEBUG, DEBUG, tokens, GH_CONFIG_DIR, GH_HOST e GH_REPO; Process/pipes fora MainActor, término único.
- **Reason**: Acordo explícito entre os especialistas nativo/providers e publicação do orquestrador nesta execução.
- **Trade-off**: Não herdar personalização corporativa; auth e Finder só qualificados pelo app em T26. Nenhum contrato de domínio C1 foi alterado.
- **Scope**: GitHubCLI transport e gates T25–T28.
- **Date**: 2026-10-22
- **Status**: superseded na parte gh por AD-018/G1; demais limites preservados

### AD-012
- **Decision**: Contrato C1.2 publicado pelo orquestrador: GitHub usa X-GitHub-Api-Version: 2026-03-10 e Accept application/vnd.github+json, DTOs mínimos com assignees[]/head.sha; Jira distingue token scoped/legado, fields explícitos e paginação nextPageToken/isLast com parcial para contradição/truncamento.
- **Reason**: Documentação primária atual qualificada pelo especialista de providers nesta sessão e acordo publicado antes dos consumidores.
- **Trade-off**: Identidade Jira e busca têm capacidades distintas; nenhum escopo é ampliado automaticamente. Não há implementação de provider neste lote.
- **Scope**: Integrações futuras T23–T28; contratos C1 de domínio preservados.
- **Date**: 2026-10-22
- **Status**: active

### AD-013
- **Decision**: Ordem de implementação e escritor permanecem sequenciais. Bloqueio de interação não conclui tarefa/lote nem libera aceite; entregas independentes desse gate podem ser preparadas com build/review e commits explicitamente parciais, com dependência e limite registrados.
- **Reason**: Publicação do orquestrador aplicando a instrução atual do usuário: quando depender de acesso/interação, registrar impedimento e continuar trabalho independente possível.
- **Trade-off**: Nenhum requisito ou gate é dispensado. O timeout CUA de T02 foi resolvido pela observação direta do usuário antes do commit. Gates futuros bloqueados continuam NOT-RUN.
- **Scope**: Execução local com impedimento externo de interação; handoff e manifesto preservam PARTIAL.
- **Date**: 2026-10-22
- **Status**: active

### AD-014
- **Decision**: Usar o Invertocat oficial branco sem recolorir/distorcer, com identificação violeta em texto/acentos separados. Preservar superfície preta, seleção cinza, contadores, duas colunas e faixa V3.
- **Reason**: Refinamento estreito publicado pelo orquestrador após leitura do guia oficial atual de marca GitHub (Color/Usage/Show integration).
- **Trade-off**: O glifo violeta ilustrado na V3 é substituído pelo branco oficial; não é uma nova identidade nem reprodução de UI de terceiro. Procedência/hashes em docs/assets/README.md.
- **Scope**: Recurso e tokens T06; demais decisões visuais intactas.
- **Date**: 2026-10-22
- **Status**: active

### AD-015
- **Decision**: Publicar C1.3 para revisão de PR antes de corrigir T10: selecionar a última decisão formal por autor dentro do SHA atual; DISMISSED suprime somente decisões anteriores desse SHA. Histórico contém todos os registros únicos submetidos com SHA conhecido diferente, inclusive COMMENTED. Resumo conclusivo exige cobertura completa de decisões e solicitações; contagens observadas permanecem separadas.
- **Reason**: Revisão independente com contexto fresco encontrou ambiguidade na interpretação de C1 e uma omissão na contagem histórica. O orquestrador qualificou a redação antes da mudança do consumidor.
- **Trade-off**: O resumo é conservador quando alguma dimensão está parcial. São registros vinculados ao commit observado, sem avaliação de branch protection, quorum ou prontidão de merge.
- **Scope**: T10, consumidores T18/T28 e revisão semântica R07.2; demais contratos C1/C1.1/C1.2 preservados.
- **Date**: 2026-10-23
- **Status**: active

### AD-016
- **Decision**: Publicar C1.4 antes dos consumidores GitHub: adicionar responsabilidade de revisão solicitada sem modalidade qualificada; reduzir statuses pela primeira ocorrência do contexto sem diferenciar maiúsculas/minúsculas na ordem documentada; qualificar o teto de check-runs com o total de check-suites do mesmo SHA, sem filtros.
- **Reason**: Pesquisa oficial e revisão independente confirmaram que review-requested inclui equipes e que o endpoint de runs limita a leitura às 1.000 suites mais recentes sem indicador próprio desse truncamento.
- **Trade-off**: Uma consulta adicional por detalhe usa o mesmo orçamento. Mais de 1.000 suites, total ausente/incoerente ou falha mantém checks parciais. Até 1.000 afasta somente esse teto observado; paginação e validade dos runs continuam obrigatórias. Não inferir associação a equipe ou prontidão de merge.
- **Scope**: Correção atômica de T10 e consumidores T17/T18/T26–T28; demais contratos preservados.
- **Date**: 2026-10-23
- **Status**: active

### AD-017
- **Decision**: Publicar C1.5: cofre clássico próprio delimitado, sem acesso automático, somente ações explícitas do usuário; segredo em memória privada do adapter durante conexão ativa. Remoção negada preserva referência para retry e invalida uso em memória.
- **Reason**: Qualificação de Security para bundle ad-hoc, revisão independente de proposta e diálogo com apresentação.
- **Trade-off**: Não prometer atributos Data Protection não qualificados; retomada após reinício é explícita e prompts são observados só pelo usuário.
- **Scope**: T22/T23/T35; sem mudança global/entitlement ou acesso por agentes.
- **Date**: 2026-10-23
- **Status**: active

### AD-018
- **Decision**: Substituir gh por GitHub App device flow nativo com refresh sem client secret e catálogo selecionável de repositórios. G1 em github-onboarding.md prevalece sobre a baseline gh (AD-004/011 e critérios afetados).
- **Reason**: Usuário rejeitou a UX técnica e pediu conexão amigável/listagem em 24/10/2026.
- **Trade-off**: Cadastro GitHub App e aprovação/instalação são gates externos. G04 criou registro próprio privado após confirmação específica e usuário confirmou a instalação. Client ID público/slug no build; segredos somente no fluxo do app/cofre. Sem backend/publicação.
- **Scope**: Integração GitHub e configurações; Jira e visual V3 preservados. Escrita G02 transferida explicitamente a github_onboarding_review; root retomou ownership após entrega, sem alterar código.
- **Date**: 2026-10-24
- **Status**: active; G02 preparado em 5aaf302, BUILD/REVIEW PASS; G03 parcial, LIVE pendente.

### AD-019
- **Decision**: Autorizar criação de pedronazarito98/Radar privado, origin local e push da fonte após revisão de segurança; supera a restrição de remotes de AD-009 somente nessa entrega.
- **Reason**: Pedido explícito do usuário em 26/10/2026, condicionado à revisão prévia.
- **Trade-off**: Fonte/documentação e histórico Git são enviados ao destino privado; não é release, instalação ou aceite da V1. Sem ferramentas/configuração global, testes/mocks ou leitura de stores reais.
- **Scope**: Repositório Git e documentação de entrega. Revisão Standard da árvore congelada 859b273 + WIP G05, depois verificação de blobs históricos e revisão estreita das mudanças documentais/ignore.
- **Date**: 2026-10-26
- **Status**: complete no limite desta entrega; repositório privado criado, primeiro push 8a9f3fe verificado em main/feat, default main e upstream próprio. Fechamento em docs/handoffs/github-repository.md; não aceita a V1 nem publica o app.

### AD-020
- **Decision**: Gerar DMG pessoal e publicá-lo como prévia em Release de pedronazarito98/Radar privado, para instalação no outro Mac sem Xcode; supera o limite anterior de release somente nessa entrega.
- **Reason**: Pedido explícito do usuário em 27/10/2026, após rejeitar instalar Xcode no destino.
- **Trade-off**: Apple Silicon/macOS 27+, assinatura ad-hoc sem notarização; integridade local e publicação não comprovam Gatekeeper/máquina limpa ou aceite da V1. Sem ler Keychain/credenciais ou mudar proteções/globais.
- **Scope**: Script de empacotamento, bundle Release, DMG, checksum, guia e publicação privada. Código/identidade do app preservados.
- **Date**: 2026-10-27
- **Status**: in progress; P02 e evidência docs/evidence/P02.md.

## Handoff

- **Feature**: Radar / .specs/features/radar/; fonte canônica neste repositório.
- **Phase / Task**: Implementação local T01–T38 preparada; T39–T42 qualificação parcial documentada. V1 NÃO ACEITA enquanto gates obrigatórios externos não passarem.
- **Completed**: Composição d3f95f7, navegação d9ed688, displays 5d98465; persistência/reinício desconectado c952406; performance 23ed6f5; visual independente d26d4db; C08 Release sem get-task-allow 45cafdd; bundle 833c2d9; C09 299514b e Release reconstruído. Builds Debug/Release, revisões por lote, launch pelo caminho completo, gh --version e preferências via UI passaram no limite registrado.
- **Revisão atual**: G01/7dd8c45 definiu o escopo; G02/5aaf302 substituiu CLI por autenticação nativa e catálogo selecionável. Debug/Release finais e revisão fresca G1.1–G1.7 PASS no limite estático. G03 qualifica metadados, UI desconectada e quit/reabertura normal; OAuth/cofre/repos/PRs reais permanecem NOT-RUN. Evidências em docs/evidence/G03.md.
- **Next step**: G04/859b273 configurou o registro próprio privado; G05 observou autorização pessoal, catálogo real de 68, busca local, escolha explícita pelo usuário e consulta GitHub recebida com total 0. Fluxo normal de conexão concluído no limite observado; painel aberto. Próximos gates dependem de Jira/política/escopos, PRs/relações existentes e interação/ambiente reais, sem fabricar dados ou falhas. docs/evidence/G05.md.
- **Blockers**: Política/site/projetos Jira/conta, PRs/detalhes/relações preenchidos, Keychain/retomada/renovação/remoção, negação/expiração/erros condicionais, seleção/links reais sobre itens, VoiceOver/Reduzir Movimento, 30 ciclos físicos com seleção e modos/displays não observados. GitHub normal autorizado e consultado em G05; contagem 0 não foi comparada independentemente no provedor. Ver docs/evidence/pending-gates.md.
- **Persistence**: UUID próprio persistido antes do cofre por contrato/revisão; startup metadata-only, retomada explícita. Preferência gh/tela tem evidência histórica; nenhum cofre acessado por agentes e GitHub nativo ainda sem qualificação real de persistência.
- **Artifact histórico C09 (anterior a G02)**: .build/DerivedData/Build/Products/Release/Radar.app; arm64/macOS 27, ad-hoc/runtime, sem App Sandbox/get-task-allow; SHA256 e479390fcbc42043ec45f29c782f3cc07ed4266c0db2cd884c8d6b9f619bd984. Nenhuma publicação/instalação/global change.
- **Artifact histórico G02/G03**: mesmo caminho Release, fonte 5aaf302 sem configuração, arm64/ad-hoc/runtime, sem entitlements. Executável SHA256 2df75d3fcabdd6a04b78c61ad40e1dcf367ae44181793260d8aad829de52871c. Substituído pela configuração pública G04.
- **Artifact vigente G04**: mesmo caminho Release, lógica Swift G02 preservada e somente dois valores públicos no pbxproj. Executável SHA256 a560dfefbbc8d64f893c908acba43f24f0d902b053950dcd1685a487f13e1494; fonte/projeto fingerprint 5610736291c23f827b059936b06ead52ba405cf5078e2a1d82a9910f8c489f45. Arm64/ad-hoc/runtime/codesign strict PASS; Conectar habilitado observado via CUA. App próprio privado radar-pessoal-pedro, sem secret/chave gerados ou lidos.
- **Branch**: feat/radar-v1-local; origin privado autorizado em AD-019. Testes/mocks/sensores/Swift lint não executados. A fonte Swift permanece 859b273; G05 foi documentado em fb9a9e0.
