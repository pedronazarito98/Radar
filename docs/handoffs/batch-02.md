# Handoff — lote2 / domínio e estado

## Situação

T08–T14 preparados sequencialmente sob AD-013; não concluem o lote/aceite enquanto gates nativos anteriores estiverem pendentes. Nenhum provider, credencial ou payload de trabalho foi acessado. Fonte atual: commit 7d962b1, além deste handoff documental.

| Entrega | Commit | Evidência |
|---|---|---|
| T08 identidades | eded612 | ../evidence/T08.md |
| T09 Jira | 2ee8cde | ../evidence/T09.md |
| T10 PR/CI/revisão | 1fb9d4e | ../evidence/T10.md |
| T11 snapshots/count/status | 64ea581 | ../evidence/T11.md |
| T12 store | b66305a | ../evidence/T12.md |
| C01 revisão sem modalidade qualificada | e00a903 | ../evidence/C01.md |
| T13 seleção/alias/headSHA | a4d500c | ../evidence/T13.md |
| T14 scheduler/budget | 7d962b1 | ../evidence/T14.md |

Todos tiveram BUILD Debug arm64 real e revisão de invariantes. T08–T12/C01 receberam revisão independente. T13/T14 têm revisão do autor: subagentes escritor e revisor atingiram limite de uso antes do parecer T13. Root assumiu único escritor; não existe PASS independente T13/T14. Testes/mocks/fixtures/sensores não criados; runtime com dados reais NOT-RUN.

## Contratos para consumidores

- Preservar C1 e C1.1–C1.4/AD-009–AD-016. Count deriva exclusivamente do snapshot apresentado; não recalcular soma de queries nem alterar por seleção.
- RadarStore é proprietário de SourcePresentationState e SelectionStore. Abrir/fechar chama setPanelOpen; close aplica pendências e limpa seleção. Nova revisão aberta usa ação applyPendingUpdates.
- SelectionKey inclui contexto e identidade remota. select canonicaliza aliases; consumeFocusReturnKey só retorna linha ainda apresentada. Relações futuras devem preservar origem de foco explicitamente.
- PRDetailStore: beginRefresh → observeHead → publish/finish com o mesmo request. Nunca publicar por cancelamento apenas; guards de geração/seleção/SHA/status são obrigatórios.
- Resoluções de repo confirmadas acompanham publish GitHub e aplicam junto da revisão apresentada. Producer entrega itens já canônicos e deduplicados; conflito é erro.
- SourceSnapshot sem observação útil não representa sucesso; dados antigos permanecem. firstProblem serve apenas à apresentação. RefreshOutcome inclui TODOS os problemas para backoff.
- RefreshScheduler opera por contexto/escopo/lista ou seleção; mantém slot até término real mesmo cancelado. Operações assíncronas fazem I/O fora MainActor. RequestBudget monotônico reserva chamadas para fronteiras /user.

## Apresentação / lote3

T15–T21 sequenciais. Dono estável no AppDelegate/composição: NotchPanelRootView é reconstruída durante frames, não deve criar stores/coordenadores. Esc AppKit/SwiftUI deve ter roteamento único: faixa → geral → recolher, preservando causa de fechamento.

Usar referência V3 e tokens existentes; preto, duas colunas, seleção cinza, faixa limitada/rolável. GitHub oficial branco com acento violeta separado (AD-014). Não popular dados das pranchas. Count unknown não vira zero. Responsabilidade, CI, revisão e fase independentes.

presentation_review fez preparação estática independente (nenhum build/UI/escrita); apontou estado estável, Esc e bounds 760×410. Sua análise não qualifica runtime. Consultas e dados reais só nos lotes seguintes.

## Bloqueios preservados

Política/token Jira, projetos/repos explícitos e consultas reais pendentes. T04 modos específicos, T07 Reduzir Movimento, VoiceOver, relações reais, 30 ciclos e Release ainda NOT-RUN. Confirmações humanas anteriores permanecem delimitadas em T02/T04/T05/T07.

Próximo escritor: root, por limitação observada dos subagentes. Revisão independente fresca continua obrigatória antes do aceite final; retomar quando a capacidade voltar. Sem publicação, instalação, alteração global ou leitura de auth/logs.
