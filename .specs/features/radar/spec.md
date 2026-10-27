# Radar — especificação da V1 pessoal

> **Revisão vigente de 24/10/2026:** [GitHub nativo G1](github-onboarding.md) substitui a dependência do gh por GitHub App e seleção de repositórios. Trechos de gh abaixo são a baseline histórica; seus gates não qualificam o novo fluxo.

**Status**: execução local autorizada por AD-009. **Complexidade**: Complex. **Execute**: implementação local T01–T38 preparada; qualificação parcial T39–T42 conforme tasks.md e acceptance.md.
**Data**: 22/10/2026. **Contexto**: [context.md](context.md). **Decisões ativas**: [STATE](../../STATE.md).

**Entrega pessoal de 27/10/2026:** AD-020 autoriza DMG em Release do repositório privado para outro Mac sem Xcode. Esse limite prevalece sobre as proibições históricas de publicação abaixo; não inclui distribuição pública, notarização ou aceite automático da V1.

**Publicidade posterior de 27/10/2026:** AD-021 autoriza tornar fonte/histórico e a Release existente públicos para avaliação do TI. As referências históricas de entrega privada/proibição de publicação abaixo são superadas somente nesse limite; GitHub App, permissões/SSO, notarização e aceite funcional permanecem separados.

## Problema e objetivo

Engenheiros alternam entre Jira e GitHub para saber o que está atribuído a eles, o que exige revisão e como tarefa e código se relacionam. A V1 oferece consulta discreta no notch, com contexto bidirecional e navegação aos serviços.

O alvo confirmado é uso pessoal em macOS 27, Jira Cloud e GitHub.com com autenticação nativa e seletor de repositórios (AD-018/G1). A identidade aprovada é Radar revisão 3. Ambiente, SDK e gh existente foram qualificados localmente; permissões e funcionamento autenticado das contas continuam pendentes. Evidências em docs/evidence/acceptance.md.

## Escopo P1

Notch compacto, visão agrupada, seleção card/PR, faixa de relações, CI/revisão/fase separados, configuração pessoal por origem, refresh limitado, vazio/erro/desatualização, acessibilidade e bundle local. Uma combinação de contas/contexto ativo na primeira entrega; identidades preparam isolamento sem criar uma UI multi-tenant completa.

## Fora do escopo

| Item | Motivo |
|---|---|
| Jira Data Center, GitHub Enterprise Server/GHE.com | Possibilidades iniciais foram refinadas pelo usuário para Cloud + github.com; reavaliar em outra feature. |
| Distribuição pública, App Store, notarização e atualizador | Primeira entrega pessoal; não executar publicação ou compra. |
| OAuth Jira distribuído e serviço de token broker | A documentação atual exige segredo no fluxo; arquitetura futura separada. |
| Backend de autenticação, chave privada e client secret embarcado | Device flow/refresh local não requerem esses componentes; cadastro do GitHub App é gate externo. |
| Merge, aprovação, comentários e transição Jira | O app é de consulta e navegação. |
| IA, resumo de daily, notificações push, snooze e atalhos globais | Ideias não necessárias para o fluxo principal. |
| Persistir títulos/PRs ou dados corporativos em banco/cache de disco | V1 usa memória; preferências e credenciais têm meios distintos. |
| Testes, mocks e sensor de mutação novos | Política expressa do usuário; não contornar a regra com scripts disfarçados. |

## Histórias independentes

| Prioridade | História | Demonstração independente |
|---|---|---|
| P1 | Consultar trabalho sem abandonar o editor | Abrir/fechar o painel e ver o estado de cada origem, inclusive desconectada. |
| P1 | Conectar Jira Cloud pessoalmente | Conectar pela UI segura, listar cards reais permitidos e desconectar sem expor segredo. |
| P1 | Conectar GitHub e escolher repositórios | Autorizar no navegador, buscar/selecionar repos acessíveis e consultar PRs. |
| P1 | Aproximar tarefa e código | Selecionar card com relações conhecidas, abrir PR e fazer o caminho inverso. |
| P1 | Entender responsabilidade e falha | Diferenciar fase, CI, revisão, vazio, parcial e desatualizado. |
| P1 | Usar teclado e preferências de acessibilidade | Navegar e fechar sem capturar digitação fora do painel. |
| P1 | Receber um app pessoal verificável | Build e execução local qualificados, evidência manual por requisito e revisão independente. |
| P2/P3 | Distribuição e outros provedores | Fora deste pacote de tarefas; nova especificação. |

## Critérios de aceite

Cada critério usa evento e resultado observável. São requisitos da proposta, não alegações de execução. Todos começam Pending.
### R01 — Execução pessoal nativa

App macOS 27 de uso pessoal, com acesso a configurações e encerramento.

- **R01.1** — **QUANDO** processo do Radar iniciar, **ENTÃO DEVERÁ ser atendido este resultado**: Ao iniciar, o app apresenta o notch fechado e um acesso alternativo de menu; iniciar sem contas conectadas não exige credenciais nem captura de câmera/tela.
- **R01.2** — **QUANDO** usuário encerrar o app, **ENTÃO DEVERÁ ser atendido este resultado**: Ao encerrar, o app remove painel, timers e observadores que criou; não instala inicialização automática.

**Tarefas mapeadas**: T02, T04, T05, T41.

### R02 — Geometria e hit testing

Conteúdo e cliques respeitam a tela e o recorte físico.

- **R02.1** — **QUANDO** painel abrir numa tela com notch, **ENTÃO DEVERÁ ser atendido este resultado**: Ao abrir em uma tela com notch, nenhum controle ocupa a área da câmera e toda a superfície permanece nos limites da tela escolhida.
- **R02.2** — **QUANDO** painel fechar ou uma animação ser interrompida, **ENTÃO DEVERÁ ser atendido este resultado**: Ao fechar ou interromper uma animação, não permanece área invisível interceptando cliques fora dos indicadores.

**Tarefas mapeadas**: T03, T04, T07, T38.

### R03 — Contadores pessoais

Totais têm escopo, completude e significado independentes da seleção.

- **R03.1** — **QUANDO** consulta pessoal terminar com todas as páginas, **ENTÃO DEVERÁ ser atendido este resultado**: Ao concluir toda a consulta e união, cada PR remoto conta uma vez; selecionar um card e exibir relações não muda esse total.
- **R03.2** — **QUANDO** total estar desconhecido, parcial, vazio confirmado ou acima de 99, **ENTÃO DEVERÁ ser atendido este resultado**: Quando o total é desconhecido exibir —; parcial exibir n+ ou … se nenhum item confirmado; zero só após consulta completa; acima de 99 exibir 99+, com rótulo acessível que distingue total exato de “pelo menos n” quando parcial.

**Tarefas mapeadas**: T11, T12, T15, T24, T27.

### R04 — Abertura, seleção e fechamento

Clique abre; fechamento tem causa explícita e respeita o destino.

- **R04.1** — **QUANDO** usuário clicar no alvo, sair com o ponteiro ou usar Esc, **ENTÃO DEVERÁ ser atendido este resultado**: Ao clicar no alvo visível, abrir a visão agrupada; sair com o ponteiro não fecha; Esc em detalhes retorna à visão geral e outro Esc fecha.
- **R04.2** — **QUANDO** fechamento for causado por clique fora, link externo ou atualização, **ENTÃO DEVERÁ ser atendido este resultado**: Ao clicar fora, preservar o aplicativo clicado; ao abrir link, preservar o navegador; atualização de contadores nunca toma foco.

**Tarefas mapeadas**: T05, T07, T13, T20, T21, T37.

### R05 — Identidade visual

A revisão 3 é a referência visual canônica.

- **R05.1** — **QUANDO** visão geral ou detalhes forem apresentados, **ENTÃO DEVERÁ ser atendido este resultado**: Em visão geral e detalhes, manter Jira à esquerda, GitHub à direita, seleção cinza e uma faixa inferior; não desenhar barras coloridas laterais.
- **R05.2** — **QUANDO** repositório ou estado precisar ser identificado, **ENTÃO DEVERÁ ser atendido este resultado**: Identificar repositórios por nome completo e ícone/selo neutro; cores de origem e de estado não substituem texto e símbolo.

**Tarefas mapeadas**: T06, T15, T16, T17, T18, T20, T40.

### R06 — Detalhes reversíveis

Seleção muda contexto, preserva listas e oferece ações explícitas.

- **R06.1** — **QUANDO** usuário selecionar card ou PR, **ENTÃO DEVERÁ ser atendido este resultado**: Ao selecionar card ou PR, usar a mesma faixa abaixo das listas, mantendo ordem, totais e itens não relacionados visíveis.
- **R06.2** — **QUANDO** seleção mudar, detalhes fecharem ou houver muitas relações, **ENTÃO DEVERÁ ser atendido este resultado**: Ao escolher outro item, substituir o conteúdo da faixa; ao fechar detalhes, devolver o foco à linha de origem; relações extensas não aumentam altura indefinidamente.

**Tarefas mapeadas**: T13, T16, T17, T18, T20, T21, T31.

### R07 — Estado de PR, CI e revisão

Três dimensões independentes, com informações do commit atual.

- **R07.1** — **QUANDO** detalhes de PR forem consultados, **ENTÃO DEVERÁ ser atendido este resultado**: Ao consultar PR, mostrar fase do PR, CI e revisão em áreas rotuladas; verde em CI não implica aprovação ou pronto para merge.
- **R07.2** — **QUANDO** checks, acesso ou revisão atual não estiverem disponíveis, **ENTÃO DEVERÁ ser atendido este resultado**: Ao faltar acesso ou conclusão, mostrar indisponível/desconhecido; conjunto completo sem checks recebe “Sem checks”; não tratar revisão histórica como satisfação das regras atuais nem aplicar CI de um headSHA anterior ao atual observado.

**Tarefas mapeadas**: T10, T17, T18, T28.

### R08 — Jira Cloud pessoal

Conexão pessoal, condicionada à política da conta, com segredo restrito ao app.

- **R08.1** — **QUANDO** usuário conectar Jira Cloud pessoalmente, **ENTÃO DEVERÁ ser atendido este resultado**: Ao conectar Jira, o usuário fornece o token diretamente em uma interface segura do app; o app guarda-o no Keychain e valida a identidade/escopo sem exibir seu valor.
- **R08.2** — **QUANDO** usuário desconectar Jira, **ENTÃO DEVERÁ ser atendido este resultado**: Ao desconectar, remover somente o item Keychain próprio e invalidar dados daquele contexto; agentes e documentos nunca recebem a credencial.

**Tarefas mapeadas**: T19, T22, T23, T35, T36.

### R09 — GitHub nativo

GitHub App com autorização no navegador, sessão própria e seletor de repositórios (G1).

- **R09.1** — **QUANDO** usuário conectar GitHub, **ENTÃO** o Radar DEVERÁ iniciar autorização oficial no navegador sem CLI ou token colado; tokens são manipulados somente pelo app/cofre próprio e consultas de trabalho usam GET permitido em api.github.com.
- **R09.2** — **QUANDO** autorização terminar, **ENTÃO** o Radar DEVERÁ listar os repositórios acessíveis ao App/usuário, com busca, seleção de 1–10 e paginação/erros explícitos; não ativar escopo anterior silenciosamente nem ampliar acesso.

**Tarefas mapeadas**: G01–G03; T19/T25–T27/T33 são histórico substituído na parte gh. Critérios complementares G1.1–G1.7 em github-onboarding.md.

### R10 — Cards Jira corretos

Busca Cloud e paginação próprias.

- **R10.1** — **QUANDO** adapter buscar cards Jira, **ENTÃO DEVERÁ ser atendido este resultado**: Ao consultar cards, usar enhanced search /rest/api/3/search/jql com assignee=currentUser e categoria não concluída, preservando o status real e seguindo nextPageToken.
- **R10.2** — **QUANDO** paginação de Jira terminar antes da completude, **ENTÃO DEVERÁ ser atendido este resultado**: Se parar por orçamento, falha ou paginação incompleta, marcar resultado parcial; uma página não é apresentada como total completo.

**Tarefas mapeadas**: T09, T24, T32.

### R11 — PRs pessoais sem soma duplicada

União por autoria, atribuição e revisão solicitada.

- **R11.1** — **QUANDO** adapter reunir autoria, atribuição e revisão, **ENTÃO DEVERÁ ser atendido este resultado**: Ao obter as três consultas is:pr/is:open, deduplicar por identidade remota no contexto, inclusive quando o mesmo PR vem de duas consultas ou conexões.
- **R11.2** — **QUANDO** busca GitHub retornar parcial ou responsabilidade de equipe, **ENTÃO DEVERÁ ser atendido este resultado**: Ao receber incomplete_results ou atingir limite/orçamento da busca, marcar parcial; distinguir revisão direta e de equipe quando houver dados suficientes.

**Tarefas mapeadas**: T08, T10, T11, T27, T32.

### R12 — Card ↔ PR com proveniência

Relação M:N explícita dentro de escopo autorizado.

- **R12.1** — **QUANDO** chave de tarefa for encontrada em título ou branch, **ENTÃO DEVERÁ ser atendido este resultado**: Ao encontrar chave no título ou branch, mostrar origem da referência e repositório; ENG-241 não corresponde a ENG-2410 nem a outro site Jira por texto semelhante.
- **R12.2** — **QUANDO** relação envolver PR fora da lista pessoal ou escopo incompleto, **ENTÃO DEVERÁ ser atendido este resultado**: Um PR acessível fora da lista pessoal pode aparecer como contexto sem alterar o contador; consulta parcial e ausência de acesso são rotuladas; não presumir API universal do painel Development.

**Tarefas mapeadas**: T29, T30, T31.

### R13 — Conteúdo, atualização e falha ortogonais

Dados conhecidos coexistem com atualização e problema.

- **R13.1** — **QUANDO** refresh falhar com ou sem snapshot anterior, **ENTÃO DEVERÁ ser atendido este resultado**: Quando refresh falha com snapshot anterior, manter o conteúdo com desatualização e ação adequada; sem snapshot, mostrar estado inicial de falha, não zero.
- **R13.2** — **QUANDO** relações estiverem pendentes, vazias ou houver falha de uma origem, **ENTÃO DEVERÁ ser atendido este resultado**: Quando não há vínculos após consulta completa, mostrar vazio; enquanto consulta estiver pendente, mostrar consultando; um serviço com problema não apaga o outro.

**Tarefas mapeadas**: T11, T12, T18, T32, T33.

### R14 — Concorrência e ordenação

Respostas só se aplicam à seleção/conta/geração que as iniciou.

- **R14.1** — **QUANDO** seleção trocar de A para B antes da resposta, **ENTÃO DEVERÁ ser atendido este resultado**: Ao selecionar A e depois B, qualquer resposta tardia de A é descartada mesmo se cancelamento não interromper a rede/processo.
- **R14.2** — **QUANDO** snapshot novo chegar com painel aberto, **ENTÃO DEVERÁ ser atendido este resultado**: Durante consulta aberta, manter itens sob o ponteiro estáveis; marcar novos dados/ordenação disponível e aplicar sem transferir a seleção por índice.

**Tarefas mapeadas**: T12, T13, T14, T26, T31, T32.

### R15 — Rede e limites

Consultas limitadas, coalescidas e com espera por origem.

- **R15.1** — **QUANDO** usuário repetir atualizar ou o sistema dormir, **ENTÃO DEVERÁ ser atendido este resultado**: Cliques repetidos em atualizar produzem no máximo uma consulta em voo por origem/escopo; respeitar Retry-After e reset, pausar trabalho desnecessário ao dormir.
- **R15.2** — **QUANDO** consulta alcançar um limite de recurso, **ENTÃO DEVERÁ ser atendido este resultado**: Timeout, saída, páginas e repos têm limites documentados; atingimento gera parcial/timeout explícito; detalhe só atualiza enquanto relevante.

**Tarefas mapeadas**: T14, T24, T26, T27, T28, T30, T32.

### R16 — Entradas e navegação validadas

URLs e parâmetros são dados controlados.

- **R16.1** — **QUANDO** parâmetros de conexão/consulta forem recebidos, **ENTÃO** o Radar DEVERÁ usar somente endpoints construídos e permitidos; URLs remotas não autorizam redirect, código, shell, arquivo ou escopo adicional. Configuração pública de OAuth fica no build; nenhum segredo embarcado.
- **R16.2** — **QUANDO** usuário acionar um destino externo, **ENTÃO DEVERÁ ser atendido este resultado**: Abrir apenas HTTPS do site Jira configurado ou github.com, com destino validado; rejeitar javascript, file, shell e host divergente.

**Tarefas mapeadas**: T23, T25, T26, T29, T37.

### R17 — Acessibilidade e movimento

Teclado, VoiceOver e preferência de movimento têm comportamento observável.

- **R17.1** — **QUANDO** usuário navegar por teclado ou usar VoiceOver, **ENTÃO DEVERÁ ser atendido este resultado**: Com teclado no painel, Tab/setas/Enter/Esc têm foco visível e rótulos completos; com painel fechado, nenhuma tecla global é capturada.
- **R17.2** — **QUANDO** preferência Reduzir Movimento estiver ativa, **ENTÃO DEVERÁ ser atendido este resultado**: Com Reduzir Movimento, usar transição discreta sem expansão ampla; status e seleção continuam identificáveis sem cor.

**Tarefas mapeadas**: T05, T07, T15, T16, T17, T18, T21, T40.

### R18 — Displays e tela cheia

Uma superfície por vez, com fallback acessível.

- **R18.1** — **QUANDO** configuração de display mudar, **ENTÃO DEVERÁ ser atendido este resultado**: Ao mudar resolução, escala ou conectar/desconectar display, recalcular uma única instância sem sair da tela ou misturar contexto.
- **R18.2** — **QUANDO** Space, fullscreen ou Stage Manager mudar, **ENTÃO DEVERÁ ser atendido este resultado**: Em fullscreen/Spaces/Stage Manager, cumprir política explicitamente qualificada; se não for possível sobrepor com APIs públicas, oferecer menu bar e registrar limitação.

**Tarefas mapeadas**: T03, T04, T38, T40.

### R19 — Ciclo de dados e preferências

Conteúdo de trabalho em memória na V1; preferências separadas de segredos.

- **R19.1** — **QUANDO** app reiniciar, **ENTÃO DEVERÁ ser atendido este resultado**: Ao reiniciar, consultar dados novamente e manter somente preferências não secretas; nenhum banco/cache em disco de títulos e PRs é criado por padrão.
- **R19.2** — **QUANDO** conta/contexto mudar ou origem desconectar, **ENTÃO** o Radar DEVERÁ invalidar sessões, seleções, snapshots e lotes incompatíveis. Desconexão remove apenas credencial própria com retry se falhar; saída limpa memória preservando referência para retomada explícita. Identidade é qualificada nas fronteiras de cada lote.

**Tarefas mapeadas**: T12, T34, T35, T36.

### R20 — Configuração e falha parcial

Cada origem possui seu próprio estado de conexão.

- **R20.1** — **QUANDO** apenas uma origem estiver disponível, **ENTÃO DEVERÁ ser atendido este resultado**: Jira e GitHub podem conectar independentemente; a origem disponível continua útil enquanto a outra precisa de conexão/reconexão.
- **R20.2** — **QUANDO** usuário conectar uma origem, **ENTÃO** os botões DEVERÃO refletir token seguro Jira e autorização GitHub no navegador com escolha de repos. Cadastro ausente, autorização negada, expiração e permissões têm orientação honesta; não apresentar sucesso antes da confirmação.

**Tarefas mapeadas**: T19, T22, T23, T25, T33, T36.

### R21 — Entrega local honesta

Bundle pessoal validado separadamente de distribuição.

- **R21.1** — **QUANDO** bundle pessoal for gerado, **ENTÃO DEVERÁ ser atendido este resultado**: Ao empacotar, registrar target, SDK, assinatura, Hardened Runtime e política de sandbox realmente usados; iniciar pelo Finder/caminho completo é verificado.
- **R21.2** — **QUANDO** alguém avaliar prontidão para distribuição, **ENTÃO DEVERÁ ser atendido este resultado**: Build local não marca notarização, Mac App Store, máquina limpa ou suporte Enterprise como validados; nenhuma publicação é realizada.

**Tarefas mapeadas**: T01, T02, T25, T26, T41.

### R22 — Fluidez e recursos

Animação local independente de rede, com medição antes de alegação.

- **R22.1** — **QUANDO** usuário abrir/fechar e alternar seleção, **ENTÃO DEVERÁ ser atendido este resultado**: Abrir, fechar e trocar seleção funciona sem esperar consulta de rede; em 30 ciclos manuais, não deixa painéis/observadores extras ou região invisível de clique.
- **R22.2** — **QUANDO** fluidez ou recursos forem avaliados, **ENTÃO DEVERÁ ser atendido este resultado**: Registrar duração/engasgos e repouso observados ou NOT-RUN; nenhuma meta de desempenho é considerada atingida por screenshot ou análise estática.

**Tarefas mapeadas**: T04, T07, T14, T26, T39.

### R23 — Coordenação Codex

Contexto canônico, diálogo e revisão independente.

- **R23.1** — **QUANDO** worker iniciar lote ou precisar mudar contrato, **ENTÃO DEVERÁ ser atendido este resultado**: Cada worker recebe spec/context/design/contratos e seu lote, comunica dúvidas ao especialista/pares e registra acordos via orquestrador antes de mudar contrato.
- **R23.2** — **QUANDO** lote terminar e verificação começar, **ENTÃO DEVERÁ ser atendido este resultado**: Somente um worker escreve código por lote; lotes seguem ordem; verificador fresco usa spec e evidências sem herdar raciocínio do autor.

**Tarefas mapeadas**: T01, T42.

### R24 — Uso limitado de REA

Investigar artefatos apenas quando a pergunta exige essa evidência.

- **R24.1** — **QUANDO** plano reutilizar a evidência de Boring Notch, **ENTÃO DEVERÁ ser atendido este resultado**: Reutilizar as evidências de Boring Notch já obtidas para inventário/plist; elas não provam animação nem execução no macOS 27.
- **R24.2** — **QUANDO** nova pergunta exigir uma investigação REA, **ENTÃO DEVERÁ ser atendido este resultado**: Nova investigação declara alvo/hash/pergunta/tipo de evidência e limites; não executar binário de terceiro nem reparar configuração por presunção.

**Tarefas mapeadas**: T01, T39, T42.

### R25 — Gates e rastreabilidade

Cada tarefa tem resultado verificável, sem testes novos por padrão.

- **R25.1** — **QUANDO** tarefa ou lote tentar avançar, **ENTÃO DEVERÁ ser atendido este resultado**: Antes de avançar, registrar requisito, gate, evidência e commit atômico; falha ou NOT-RUN de gate obrigatório impede concluir a tarefa/lote.
- **R25.2** — **QUANDO** política de testes for aplicada, **ENTÃO DEVERÁ ser atendido este resultado**: Não gerar testes/mocks/sensores automáticos; verificação manual/build é identificada como tal, e testes automatizados/sensor ficam NOT-RUN por política.

**Tarefas mapeadas**: T01, T39, T40, T41, T42.

### R26 — Identidades e isolamento

Objetos remotos não são confundidos por apresentação ou conexão.

- **R26.1** — **QUANDO** mesmo objeto vier de duas consultas/conexões, **ENTÃO DEVERÁ ser atendido este resultado**: Mesmo PR remoto visto por duas origens no mesmo contexto deduplica; PRs de hosts/repos diferentes com mesmo número permanecem distintos.
- **R26.2** — **QUANDO** seleção ou identidade de conta mudar, **ENTÃO DEVERÁ ser atendido este resultado**: Chave Jira é apresentação; identidade usa site e issueID; seleção usa contexto+identidade, e mudança de identidade autenticada detectada invalida resultados anteriores. Lotes gh são qualificados por GET /user antes e ao publicar; divergência descarta o lote e falha na qualificação final impede publicar dados novos.

**Tarefas mapeadas**: T08, T09, T10, T12, T13, T27, T30, T35.

### R27 — Erros classificados

Autenticação, permissão, limite e falha técnica não se confundem.

- **R27.1** — **QUANDO** origem retornar erro de auth/permissão, **ENTÃO DEVERÁ ser atendido este resultado**: Erro 401 ou autorização revogada permite pedir reconexão; 403 não é automaticamente chamado de sessão expirada. Erros OAuth não expõem corpo ou segredo.
- **R27.2** — **QUANDO** origem retornar limite, timeout, cancelamento ou conteúdo inválido, **ENTÃO DEVERÁ ser atendido este resultado**: 429/limite respeita espera; timeout, cancelamento, JSON inválido e capacidade indisponível têm representação própria e não viram vazio.

**Tarefas mapeadas**: T11, T14, T23, T24, T26, T27, T28, T33.

### R28 — Somente leitura de trabalho

App e agentes não enviam alterações para Jira/GitHub na V1.

- **R28.1** — **QUANDO** Radar acessar serviços de trabalho, **ENTÃO DEVERÁ ser atendido este resultado**: Os únicos efeitos sobre serviços de trabalho são consultas autenticadas e abertura de links; não há merge, aprovação, comentário, transição de card ou alteração de repo.
- **R28.2** — **QUANDO** auth local ou permissão do token forem descritas, **ENTÃO DEVERÁ ser atendido este resultado**: Auth local, copiar link e preferências têm escopo explícito; permissões existentes do token não são descritas como somente leitura se concederem mais.

**Tarefas mapeadas**: T19, T23, T24, T26, T27, T28, T37.
## Suposições e decisões abertas

Tabela histórica do plano. AD-009 autoriza implementação local; AD-010 adota A01/A04–A12 como ponto de partida qualificável, sem presumir acesso/política de A03/A08/A13.

| ID | Proposta/default | Razão e gate | Confirmado |
|---|---|---|---|
| A01 | SwiftUI + ponte pequena AppKit em target Xcode | Melhor ajuste ao painel e bundle; comparar alternativas em design.md; confirmar plano antes de criar código. | Não |
| A02 | GitHub por gh já instalado/autenticado | Informação do usuário sobre uso de gh; instalação, conta e capacidade serão qualificadas sem ler auth. | Uso do gh informado; viabilidade não verificada |
| A03 | Jira Cloud pessoal por API token com escopos mínimos no Keychain | Somente se permitido pela conta/organização. Se não permitido, parar a tarefa de auth e propor fluxo confidencial; não embutir segredo OAuth. | Não |
| A04 | Configuração pessoal sem App Sandbox, com assinatura e Hardened Runtime | Process herda sandbox; CLI externa exige prova via Finder. Não promete App Store. | Não |
| A05 | Reabrir na visão geral | Apenas o fluxo ilustrado; a preferência do usuário ainda não foi respondida. | Não |
| A06 | Uma tela por vez: tela com notch, fallback de menu bar | Minimiza superfície e foco; política fullscreen é qualificada cedo. | Não |
| A07 | Dados de trabalho em memória; preferências não secretas persistidas | Reduz exposição e complexidade. Cache entre reinícios é evolução. | Não |
| A08 | Projetos Jira e repositórios GitHub delimitados pelo usuário na execução | Host e modalidades estão confirmados; escopos concretos ainda não foram coletados. | Não |
| A09 | Parâmetros iniciais: abrir 250 ms, detalhes 180 ms, fade reduzido 120 ms | Valores de design, a calibrar no hardware; não são medições. | Não |
| A10 | Atualização de listas 60 s; detalhes visíveis 15 s; timeout 15 s e saída 5 MiB | Defaults limitados, sobrepostos por backoff/limites; medir consumo. | Não |
| A11 | Até 10 páginas por consulta; relação sob demanda com até 20 chamadas/30 s | Ao atingir limite, resultado é parcial; não prometer exaustividade da organização. | Não |
| A12 | Destino do repositório e bundle ID definidos em T01 | Diretório atual só contém estudos e plano, sem Git ou app. | Pendente |
| A13 | Qualificação de escopos/SSO pode restringir dados | Não elevar permissões automaticamente; capacidade indisponível é visível. | Pendente |

**Execução**: autorização local explícita registrada em AD-009; defaults e limites em AD-010. Alterações futuras de contrato exigem publicação do orquestrador.

## Varredura de requisitos implícitos

| Dimensão | Cobertura |
|---|---|
| Entradas e limites | R02, R03, R15, R16: bounds de tela/contagem/saída/páginas e URLs. |
| Falha parcial | R13, R20, R27: cada origem e consulta têm estado próprio. |
| Idempotência/retry/dedup | R11, R15, R26: coalescer, identidades remotas e backoff. |
| Auth e limites | R08, R09, R15, R27: credenciais fora de contexto e capacidades qualificadas. |
| Concorrência e ordenação | R14, R26: seleção por identidade e geração. |
| Ciclo de dados | R19, R26: memória, invalidação e limpeza própria. |
| Observabilidade | R22, R25: evidência sanitizada e métricas; agentes não leem logs ou segredos. |
| Dependência externa | R09, R13, R20, R27: gh, rede, políticas e auth. |
| Integridade de transição | R04, R06, R14: estados explícitos e causa de fechamento. |
| Pagamentos | N/A: nenhum fluxo de pagamento na V1. |

## Rastreabilidade

| Requisito | Tarefas | Estado |
|---|---|---|
| R01 | T02, T04, T05, T41 | Pending |
| R02 | T03, T04, T07, T38 | Pending |
| R03 | T11, T12, T15, T24, T27 | Pending |
| R04 | T05, T07, T13, T20, T21, T37 | Pending |
| R05 | T06, T15, T16, T17, T18, T20, T40 | Pending |
| R06 | T13, T16, T17, T18, T20, T21, T31 | Pending |
| R07 | T10, T17, T18, T28 | Pending |
| R08 | T19, T22, T23, T35, T36 | Pending |
| R09 | T19, T25, T26, T27, T33 | Pending |
| R10 | T09, T24, T32 | Pending |
| R11 | T08, T10, T11, T27, T32 | Pending |
| R12 | T29, T30, T31 | Pending |
| R13 | T11, T12, T18, T32, T33 | Pending |
| R14 | T12, T13, T14, T26, T31, T32 | Pending |
| R15 | T14, T24, T26, T27, T28, T30, T32 | Pending |
| R16 | T23, T25, T26, T29, T37 | Pending |
| R17 | T05, T07, T15, T16, T17, T18, T21, T40 | Pending |
| R18 | T03, T04, T38, T40 | Pending |
| R19 | T12, T34, T35, T36 | Pending |
| R20 | T19, T22, T23, T25, T33, T36 | Pending |
| R21 | T01, T02, T25, T26, T41 | Pending |
| R22 | T04, T07, T14, T26, T39 | Pending |
| R23 | T01, T42 | Pending |
| R24 | T01, T39, T42 | Pending |
| R25 | T01, T39, T40, T41, T42 | Pending |
| R26 | T08, T09, T10, T12, T13, T27, T30, T35 | Pending |
| R27 | T11, T14, T23, T24, T26, T27, T28, T33 | Pending |
| R28 | T19, T23, T24, T26, T27, T28, T37 | Pending |

**Cobertura documental**: 28 requisitos, 56 critérios, todos mapeados. Resultados atuais por modo em docs/evidence/acceptance.md. Esta matriz é rastreabilidade de requisitos, não cobertura automatizada nem aceite.

## Sucesso da V1

Completar com evidência real: iniciar pelo Finder → conectar/qualificar origens → listar/contar → consultar card e PR → compreender status → abrir destino → recolher/voltar. Toda condição obrigatória precisa PASS no gate manual/build apropriado ou uma revisão explícita de escopo. NOT-RUN não equivale a PASS.

