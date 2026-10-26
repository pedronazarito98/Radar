# Gates que dependem de interação ou ambiente real

Atualizado em 25/10/2026. O usuário pediu substituir o gh por autenticação GitHub nativa e seletor de repos. G02/5aaf302 está preparado com builds finais e revisão fresca PASS; G03 confirmou metadados e UI desconectada/quit/reabertura normal. As evidências anteriores do gh ficam históricas. Este registro não substitui o manifesto por tarefa nem o aceite por critério; os gates abaixo continuam pendentes.

## Contas e recursos autorizados — NOT-RUN

| Gate | Entrada/interação necessária | Limite da evidência atual |
|---|---|---|
| Jira Cloud / T22–T24 | Site, projetos e confirmação de política que permita token pessoal. T34 implementada/revisada; entrada direta no SecureField do app e consentimento do próprio Keychain quando solicitado. | Código/build/revisão não comprovam conexão, persistência ou consulta real. Não enviar token no chat. |
| GitHub.com / G1 e G04 | Autorizar pelo Radar/navegador e conferir catálogo/seleção/PRs reais. | G04 já confirmou cadastro próprio privado, instalação escolhida pelo usuário, dois valores públicos no build e Conectar habilitado. Nenhum token/secret no chat; não ler/capturar o desafio. |
| Relação bidirecional / T30–T31 | Card e PR existentes, com referência real no título/branch, dentro dos escopos autorizados. | Sem dados artificiais. Deve incluir contexto fora da lista pessoal quando existir, preservando contadores. |
| Refresh/isolamento / T32–T35 e G1 | Consultas reais, troca rápida de seleção, desconexão e reinício pelo usuário. | Falhas condicionais e saída aguardando rotação são revisadas; não provocar rate limit nem revogar credenciais para fabricar cenário. |
| Fluxo integrado / T36–T37 | Listas reais, seleção card ↔ PR, abrir/copiar destinos e conferir foco no navegador. | Gate preenchido não é substituído pela UI desconectada. |
| Bundle / T41 | Executar o Release local pelo caminho completo e usar as integrações permitidas. | Launch e metadados do bundle podem ser qualificados separadamente; autenticação continua pendente. |

O usuário pode fornecer site/projetos Jira e a política em texto, sem segredos. No GitHub, os repos serão escolhidos no catálogo do app; não precisam ser digitados no chat. Cadastro exige somente Client ID e slug públicos para configuração do build. Nenhuma escolha de escopo será inventada. T34 já confirma a referência própria persistida antes de gravar segredo, por revisão de código. Isso habilita a futura verificação pessoal após política/escopo, mas não comprova consentimento/Keychain real.

## Interface e hardware — observações preservadas e limites

- **Observado pelo usuário:** Configurações e Encerrar funcionam; recorte e cliques funcionam, com acesso ao Radar preservado; foco no editor e alternância rápida foram confirmados com “ok”; escolha do gh retornou o caminho ao formulário.
- **Ainda não qualificado por essas respostas:** VoiceOver; Reduzir Movimento; matriz individual de Spaces/tela cheia/Stage Manager; troca de escala/resolução ou monitores; 30 ciclos medidos; navegação por teclado sobre itens e relações reais; funcionamento autenticado no Release.
- T39 observou 3 ciclos CUA e 2 pontos de repouso; seleção e troca de itens nos 30 ciclos exigem dados reais. Screenshot não comprova duração, fluidez ou ausência de interceptação invisível.
- Mudanças de preferências globais, resolução, rede ou conexão de hardware são feitas pelo usuário quando optar por executar o roteiro. O agente não as altera automaticamente.

## Qualificações históricas anteriores a G01–G03

- Preferência gh restaurada após reinício na cópia T35; tela interna escolhida no app persistiu no Release e foi restaurada para Automática. Não houve leitura de arquivo de preferências pelo agente nem alteração global.
- Release compilado, codesign verificado com ad-hoc/runtime e sem get-task-allow, aberto pelo caminho completo; gh 2.96.0 qualificado sem consulta de conta. T41 permanece parcial para auth real.
- T40: revisão independente de capturas desconectadas e código PASS; não substitui VoiceOver/Reduzir Movimento ou visual preenchido.
- Perguntas de observação física/30 ciclos e VoiceOver/Reduzir Movimento enviadas ao usuário com Release aberto. Sem resposta, permanecem NOT-RUN. Ver acceptance.md e os relatórios T39–41.

## Fechamento

T42 deve manter separados BUILD, REVIEW, MANUAL e MEASURE, e indicar NOT-RUN para cada cenário não observado. Gates obrigatórios pendentes impedem declarar a V1 aceita. Testes, mocks e sensores não foram autorizados e não são criados para substituir esses gates. Publicação, instalação de ferramentas, notarização e alterações globais permanecem fora do escopo.

## Gates da revisão GitHub nativa

Ver [G03](G03.md): auth/renovação/cofre, instalação/permissões, catálogo/busca/paginação/seleção e fluxo PRs precisam de observação própria. Os resultados de `gh --version` não qualificam o fluxo novo. Registro de App e instalação serão feitos pessoalmente pelo usuário, guiado após implementação; sem publicação automática.

O Release atual foi aberto por caminho completo, mostrou o cadastro ausente e Conectar desabilitado, sem campos de caminho/CLI/token/repo. Encerramento normal e reabertura desconectada foram observados por CUA; isso não qualifica saída durante rotação real, retomada autenticada, teclado ou VoiceOver.

## G04 — confirmação atual

Usuário pediu eliminar a carga técnica do cadastro. O agente preparou formulário/permissões, criou o registro próprio privado após confirmação específica e coletou somente metadados públicos; não exigiu cópia de IDs. Usuário confirmou identidade e instalação nos repos escolhidos. Os builds configurados e UI Conectar habilitado passaram; aguarda autorização pelo Radar e relato de catálogo/impedimento. Ver [G04](G04.md).
