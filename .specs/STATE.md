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
- **Status**: active

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
- **Status**: active

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

## Handoff

- **Feature**: Radar / .specs/features/radar/; fonte canônica neste repositório.
- **Phase / Task**: Execute local, lote1; T01/T02 Complete (BUILD/assinatura e UI-base humana PASS).
- **Completed**: T01 commit18f1de9; target/scheme Radar único, bundle Debug local com assinatura ad-hoc/runtime e processo confirmado.
- **In-progress**: T03 próxima; usuário confirmou abertura de configurações e encerramento normalmente.
- **Next step**: T03 geometria pelo NSScreen; T04 painel.
- **Blockers**: CUA getApp path/id/nome retorna timeoutReached -10005; UI-base T02 resolvida por evidência humana. Jira política/escopos e providers runtime continuam pendentes.
- **Uncommitted files**: T02 antes do commit; consultar git status. Hash real fica no manifesto seguinte.
- **Branch**: feat/radar-v1-local; sem remote.
