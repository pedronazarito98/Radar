# Gates que dependem de interação ou ambiente real

Atualizado em 23/10/2026. A implementação local continua nas tarefas independentes, conforme instrução do usuário. Este registro não substitui o manifesto por tarefa nem o aceite por critério.

## Contas e recursos autorizados — NOT-RUN

| Gate | Entrada/interação necessária | Limite da evidência atual |
|---|---|---|
| Jira Cloud / T22–T24 | Site, projetos e confirmação de política que permita token pessoal. Depois de T34, entrada direta no SecureField do app e consentimento do próprio Keychain quando solicitado. | Código/build/revisão não comprovam conexão, persistência ou consulta real. Não enviar token no chat. |
| GitHub.com / T26–T28 | Repositórios owner/repo autorizados e conexão pela UI com a autenticação já administrada pelo gh. | Escolha de `/opt/homebrew/bin/gh` confirmada pelo usuário; versão 2.96.0 validada pelo app Debug. Nenhuma consulta de conta executada pelo agente. |
| Relação bidirecional / T30–T31 | Card e PR existentes, com referência real no título/branch, dentro dos escopos autorizados. | Sem dados artificiais. Deve incluir contexto fora da lista pessoal quando existir, preservando contadores. |
| Refresh/isolamento / T32–T35 | Consultas reais, troca rápida de seleção, desconexão e reinício pelo usuário. | Falhas condicionais são revisadas; não provocar rate limit, revogar token ou alterar conta do gh para fabricar cenário. |
| Fluxo integrado / T36–T37 | Listas reais, seleção card ↔ PR, abrir/copiar destinos e conferir foco no navegador. | Gate preenchido não é substituído pela UI desconectada. |
| Bundle / T41 | Executar o Release local pelo caminho completo e usar as integrações permitidas. | Launch e metadados do bundle podem ser qualificados separadamente; autenticação continua pendente. |

O usuário pode fornecer site/projetos/repos e a política em texto, sem segredos. Nenhuma escolha de escopo será inventada. Não solicitar entrada real do token enquanto a referência própria do cofre não estiver persistida antes da gravação do segredo.

## Interface e hardware — observações preservadas e limites

- **Observado pelo usuário:** Configurações e Encerrar funcionam; recorte e cliques funcionam, com acesso ao Radar preservado; foco no editor e alternância rápida foram confirmados com “ok”; escolha do gh retornou o caminho ao formulário.
- **Ainda não qualificado por essas respostas:** VoiceOver; Reduzir Movimento; matriz individual de Spaces/tela cheia/Stage Manager; troca de escala/resolução ou monitores; 30 ciclos medidos; navegação por teclado sobre itens e relações reais; funcionamento autenticado no Release.
- T39 pode observar abrir/recolher sem contas, mas seleção e troca de itens nos 30 ciclos exigem dados reais. Screenshot não comprova duração, fluidez ou ausência de interceptação invisível.
- Mudanças de preferências globais, resolução, rede ou conexão de hardware são feitas pelo usuário quando optar por executar o roteiro. O agente não as altera automaticamente.

## Fechamento

T42 deve manter separados BUILD, REVIEW, MANUAL e MEASURE, e indicar NOT-RUN para cada cenário não observado. Gates obrigatórios pendentes impedem declarar a V1 aceita. Testes, mocks e sensores não foram autorizados e não são criados para substituir esses gates. Publicação, instalação de ferramentas, notarização e alterações globais permanecem fora do escopo.
