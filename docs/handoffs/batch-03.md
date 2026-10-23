# Handoff — lote3 / apresentação

Root foi o único escritor após o limite de uso do writer anterior. Fonte: 09450fd; contratos C1/C1.1–C1.4 e identidade V3 preservados. T15–T20 preparados; T21 parcial. Não é aceite do lote ou da V1.

| Tarefa | Commit | Evidência |
|---|---|---|
| T15 | 3706fcb | ../evidence/T15.md |
| T16 | 49a0425 | ../evidence/T16.md |
| T17 | d96c7d0 | ../evidence/T17.md |
| T18 | 23b8fb8 | ../evidence/T18.md |
| T19 | 892c825 | ../evidence/T19.md |
| T20 | f2f411f | ../evidence/T20.md |
| T21 | 09450fd | ../evidence/T21.md |

Builds Debug reais e UI sem contas foram observados. Usuário confirmou seleção do gh; isto não qualifica CLI/auth. T21 percorre o único controle disponível sem dados; linhas/setas/retorno/Esc em detalhes dependem dos providers. Revisão estática de presentation_review solicitada novamente; sem resultado até este handoff. Não há alegação independente T13 em diante.

## Contrato para lote4

- AppDelegate possui store estável; NotchPanelController possui foco estável. Não criar dependências em rootView reconstruída durante animação.
- Settings: token temporário privado na folha Jira, ainda desabilitado; tipo scoped/legado e aceite de política explícitos. Não capturar a UI durante entrada real. Nenhum token em store/preferências/evidências.
- GitHub seleciona arquivo e mostra caminho; ainda não executa. T25 qualifica executável; T26 usa ambiente novo/GET/limites C1.1; nunca auth/status/token/login ou leitura de arquivo auth.
- Providers precisam preservar cobertura, scope/context/generation, identidade e SHA. Erro não vira zero nem apaga snapshot antigo. T27 reserva /user inicial/final e serializa lote inteiro.
- Faixa única limitada, relações ainda notQueried. T31/T37 devem integrar ações reais e incluí-las na ordem do foco; não povoar dados ilustrativos.
- T22 começa pela fronteira do item próprio do Keychain; agente não a executa. Gates dependentes de conta/interação continuam NOT-RUN e não impedem preparação independente sob AD-013.

## Pendências

Política Jira, site/projetos/repos explícitos, entrada segura, providers e relações reais; revisão independente pendente por limitação anterior, acessibilidade, modos de display, 30 ciclos/medição e Release. Nenhum teste/mock/fixture/sensor criado; nenhuma publicação/instalação/alteração global.
