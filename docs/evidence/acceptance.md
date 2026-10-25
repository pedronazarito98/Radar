# T42 — Aceite integrado da V1 pessoal

> **Histórico da baseline até C09:** os resultados abaixo qualificam o build anterior com gh. A revisão de 24/10/2026 (AD-018/G1) substitui R09, R16.1, R19.2, R20.2 e a parte gh dos demais critérios. Os PASS antigos não qualificam OAuth/catálogo; novos gates em [G03](G03.md).

**Estado: implementação local preparada; V1 NÃO ACEITA.** Gates obrigatórios de contas/fluxo central, acessibilidade e protocolo físico continuam NOT-RUN. A revisão final fresca foi executada após T42/545705e: encontrou um P2, corrigido e revisto em C09/299514b. Resultado e limites em final-verification.md.

## Contexto comum de cada registro

- Environment: Mac arm64/macOS 27.0.1, tela 1470×956pt@2/60Hz; Xcode 27.1/SDK 27.0, Swift 6 strict. Release final em [T41](local-bundle.md), código 299514b, SHA-256 e479390fcbc42043ec45f29c782f3cc07ed4266c0db2cd884c8d6b9f619bd984.
- Task/commit: indicado por registro; referências históricas apontam a evidência original e correções posteriores. O manifesto resolve hashes completos.
- REVIEW PASS significa apenas invariante/código/documentação revisados, não execução de rede, teclado preenchido ou hardware. Revisões independentes por lotes e T40 são preservadas; a revisão final fresca e a revisão da correção C09 estão registradas em final-verification.md.
- MANUAL via CUA é interação com o app real; não é observação física humana. Respostas humanas anteriores ficam delimitadas ao roteiro respondido. Sem resposta nova não há PASS presumido.
- BUILD: T41/R21.1 PASS no Release, e builds Debug por tarefa registrados; não é autenticação. MEASURE: R22.2 PASS somente para duas leituras nativas de repouso; duração/engasgos NOT-RUN.
- Dados: nenhum seed/mock/fixture/teste/sensor; nenhum acesso por agente a contas, auth, Keychain, logs ou bancos. Tokens só podem ser informados pelo usuário no SecureField, após política permitida.

## Registros por critério — 56

### R01.1 / U01
- **Task / commit:** T02 c910574; T35 066b86b; T36 d3f95f7; T41 833c2d9.
- **Preconditions:** Mac alvo e bundle local.
- **Expected:** Ao iniciar, o app apresenta o notch fechado e um acesso alternativo de menu; iniciar sem contas conectadas não exige credenciais nem captura de câmera/tela.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** AppComposition inicia painel compacto e ciclo único sem autoauth/captura.
- **Evidence:** [T02.md](T02.md); [T35.md](T35.md); [local-bundle.md](local-bundle.md).
- **Mode / action / observed / limits — MANUAL:** PASS: Release abriu compacto/desconectado pelo caminho completo.

### R01.2 / U01
- **Task / commit:** T02 c910574; T35 066b86b; T36 d3f95f7; T41 833c2d9.
- **Preconditions:** Mac alvo e bundle local.
- **Expected:** Ao encerrar, o app remove painel, timers e observadores que criou; não instala inicialização automática.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** stop desmonta observadores, scheduler e painel; não registra inicialização automática.
- **Evidence:** [T02.md](T02.md); [T35.md](T35.md); [local-bundle.md](local-bundle.md).
- **Mode / action / observed / limits — MANUAL:** PASS: Encerrar pela UI removeu processo próprio; reabertura observada.

### R02.1 / U02
- **Task / commit:** T03 99e3318; T04 eab3dab; T38 5d98465.
- **Preconditions:** Tela com notch e interação física.
- **Expected:** Ao abrir em uma tela com notch, nenhum controle ocupa a área da câmera e toda a superfície permanece nos limites da tela escolhida.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** ScreenGeometryResolver limita bounds; câmera deriva das áreas seguras reais.
- **Evidence:** [T03.md](T03.md); [T04.md](T04.md); [T38.md](T38.md); [performance.md](performance.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN no build final físico: captura mostra recorte; confirmação humana anterior preservada.

### R02.2 / U02
- **Task / commit:** T03 99e3318; T04 eab3dab; T38 5d98465.
- **Preconditions:** Tela com notch e interação física.
- **Expected:** Ao fechar ou interromper uma animação, não permanece área invisível interceptando cliques fora dos indicadores.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Recorte/hit shape e cancelamento da animação acompanham a mesma geometria.
- **Evidence:** [T03.md](T03.md); [T04.md](T04.md); [T38.md](T38.md); [performance.md](performance.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN físico final: três ciclos CUA terminaram compactos, sem comprovar hit-through; confirmação humana anterior preservada.

### R03.1 / U03
- **Task / commit:** T11 64ea581; T12 b66305a; T15 3706fcb; T27 fb5ed1b; T31 e13e1ab.
- **Preconditions:** Listas autorizadas completas/parciais existentes.
- **Expected:** Ao concluir toda a consulta e união, cada PR remoto conta uma vez; selecionar um card e exibir relações não muda esse total.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Identidades/aliases deduplicam união; contexto relacionado não entra no snapshot pessoal.
- **Evidence:** [T11.md](T11.md); [T15.md](T15.md); [T27.md](T27.md); [T31.md](T31.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: união pessoal e relações exigem PRs reais.

### R03.2 / U03
- **Task / commit:** T11 64ea581; T12 b66305a; T15 3706fcb; T27 fb5ed1b; T31 e13e1ab.
- **Preconditions:** Listas autorizadas completas/parciais existentes.
- **Expected:** Quando o total é desconhecido exibir —; parcial exibir n+ ou … se nenhum item confirmado; zero só após consulta completa; acima de 99 exibir 99+, com rótulo acessível que distingue total exato de “pelo menos n” quando parcial.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Count distingue desconhecido/parcial/vazio/99+ e rótulos acessíveis.
- **Evidence:** [T11.md](T11.md); [T15.md](T15.md); [T27.md](T27.md); [T31.md](T31.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN completo: — desconectado observado; parcial/zero/99+ não exercitados.

### R04.1 / U04
- **Task / commit:** T05 7861676; T07 5fe9ecb; T21 09450fd; T37 d9ed688.
- **Preconditions:** Editor, navegador e seleção real.
- **Expected:** Ao clicar no alvo visível, abrir a visão agrupada; sair com o ponteiro não fecha; Esc em detalhes retorna à visão geral e outro Esc fecha.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Abertura por intenção; sem fechamento por hover; Esc recua seleção antes do painel.
- **Evidence:** [T05.md](T05.md); [T07.md](T07.md); [T21.md](T21.md); [T37.md](T37.md); [performance.md](performance.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN completo: abrir/Esc geral observados; Esc em duas etapas precisa seleção real.

### R04.2 / U04
- **Task / commit:** T05 7861676; T07 5fe9ecb; T21 09450fd; T37 d9ed688.
- **Preconditions:** Editor, navegador e seleção real.
- **Expected:** Ao clicar fora, preservar o aplicativo clicado; ao abrir link, preservar o navegador; atualização de contadores nunca toma foco.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** PanelDismissalReason separa link/clique externo/escape; refresh não ativa janela.
- **Evidence:** [T05.md](T05.md); [T07.md](T07.md); [T21.md](T21.md); [T37.md](T37.md); [performance.md](performance.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN completo: foco no editor confirmado anteriormente; navegador e refresh reais pendentes.

### R05.1 / U05
- **Task / commit:** T06 ce3c7d0; T16 49a0425; T17 d96c7d0; T18 23b8fb8; T40 d26d4db.
- **Preconditions:** V3 canônica e listas reais.
- **Expected:** Em visão geral e detalhes, manter Jira à esquerda, GitHub à direita, seleção cinza e uma faixa inferior; não desenhar barras coloridas laterais.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Tokens/composição mantêm duas colunas, seleção cinza, faixa única e nenhuma barra lateral colorida.
- **Evidence:** [T06.md](T06.md); [visual-accessibility.md](visual-accessibility.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN completo: captura desconectada aprovada por revisor fresco; seleção preenchida pendente.

### R05.2 / U05
- **Task / commit:** T06 ce3c7d0; T16 49a0425; T17 d96c7d0; T18 23b8fb8; T40 d26d4db.
- **Preconditions:** V3 canônica e listas reais.
- **Expected:** Identificar repositórios por nome completo e ícone/selo neutro; cores de origem e de estado não substituem texto e símbolo.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** GitHubRowView mostra nome completo, símbolo neutro e rótulos de estado; AD014 conserva glifo branco oficial.
- **Evidence:** [T06.md](T06.md); [visual-accessibility.md](visual-accessibility.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: nomes extensos/repos/estados reais não apresentados.

### R06.1 / U06
- **Task / commit:** T13 a4d500c; T18 23b8fb8; T21 09450fd; T31 e13e1ab.
- **Preconditions:** Card e PR com vínculo autorizado existente.
- **Expected:** Ao selecionar card ou PR, usar a mesma faixa abaixo das listas, mantendo ordem, totais e itens não relacionados visíveis.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Store separa apresentado/pendente e contexto relacionado, preservando ordem/contadores.
- **Evidence:** [T13.md](T13.md); [C02.md](C02.md); [T31.md](T31.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: fluxo bidirecional exige itens e relações reais.

### R06.2 / U06
- **Task / commit:** T13 a4d500c; T18 23b8fb8; T21 09450fd; T31 e13e1ab.
- **Preconditions:** Card e PR com vínculo autorizado existente.
- **Expected:** Ao escolher outro item, substituir o conteúdo da faixa; ao fechar detalhes, devolver o foco à linha de origem; relações extensas não aumentam altura indefinidamente.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** SelectionStore conserva originKey; faixa com altura limitada e rolagem substitui conteúdo.
- **Evidence:** [T13.md](T13.md); [C02.md](C02.md); [T31.md](T31.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: troca, retorno à origem e relações extensas exigem dados reais.

### R07.1 / U07
- **Task / commit:** T10 1fb9d4e; C01 e00a903; T18 23b8fb8; T28 3c6ebc2.
- **Preconditions:** PR autorizado e sinais existentes.
- **Expected:** Ao consultar PR, mostrar fase do PR, CI e revisão em áreas rotuladas; verde em CI não implica aprovação ou pronto para merge.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Fase/CI/revisão têm modelos e áreas independentes, sem inferência de merge.
- **Evidence:** [T10.md](T10.md); [C01.md](C01.md); [T18.md](T18.md); [T28.md](T28.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: detalhe de PR real.

### R07.2 / U07
- **Task / commit:** T10 1fb9d4e; C01 e00a903; T18 23b8fb8; T28 3c6ebc2.
- **Preconditions:** PR autorizado e sinais existentes.
- **Expected:** Ao faltar acesso ou conclusão, mostrar indisponível/desconhecido; conjunto completo sem checks recebe “Sem checks”; não tratar revisão histórica como satisfação das regras atuais nem aplicar CI de um headSHA anterior ao atual observado.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Tokens/headSHA, cobertura, latest formal review e histórico seguem C1; ausência não vira sucesso.
- **Evidence:** [T10.md](T10.md); [C01.md](C01.md); [T18.md](T18.md); [T28.md](T28.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: combinações reais de checks/reviews/head e acesso não provocadas.

### R08.1 / U08
- **Task / commit:** T22 671efae; T23 cb9c140; T34 965578b; T35 066b86b.
- **Preconditions:** Política Jira permitida e entrada pessoal segura.
- **Expected:** Ao conectar Jira, o usuário fornece o token diretamente em uma interface segura do app; o app guarda-o no Keychain e valida a identidade/escopo sem exibir seu valor.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** SecureField e actor privado; UUID persistido antes de vault.save; retomada explícita requalifica.
- **Evidence:** [T22.md](T22.md); [T23.md](T23.md); [T34.md](T34.md); [T35.md](T35.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: política/conta/token/consentimento fornecidos apenas pelo usuário no app.

### R08.2 / U08
- **Task / commit:** T22 671efae; T23 cb9c140; T34 965578b; T35 066b86b.
- **Preconditions:** Política Jira permitida e entrada pessoal segura.
- **Expected:** Ao desconectar, remover somente o item Keychain próprio e invalidar dados daquele contexto; agentes e documentos nunca recebem a credencial.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Query de cofre delimitada por service/account próprios; falha de remoção conserva referência/retry.
- **Evidence:** [T22.md](T22.md); [T23.md](T23.md); [T34.md](T34.md); [T35.md](T35.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: remoção/consentimento/negação reais não exercitados.

### R09.1 / U09
- **Task / commit:** T25 10871d4; T26 272ba61; T33 791c6ac; T41 833c2d9.
- **Preconditions:** gh existente e escopo autorizado para consultas.
- **Expected:** Ao consultar GitHub, executar gh por caminho absoluto com argumentos estruturados, --hostname github.com e --method GET em endpoints permitidos; não invocar shell, login, refresh de auth ou gh auth token.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Process usa executável qualificado/argumentos estruturados/GET github.com/allowlist, sem shell/auth subcommand.
- **Evidence:** [T25.md](T25.md); [T26.md](T26.md); [T33.md](T33.md); [local-bundle.md](local-bundle.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN autenticação/GET: --version 2.96.0 passou também no Release.

### R09.2 / U09
- **Task / commit:** T25 10871d4; T26 272ba61; T33 791c6ac; T41 833c2d9.
- **Preconditions:** gh existente e escopo autorizado para consultas.
- **Expected:** Se gh estiver ausente, incompatível ou não autenticado, apresentar ação específica; não instalar, alterar permissões ou aumentar escopos automaticamente.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Erros específicos e ações de recuperação; não instala nem amplia permissões.
- **Evidence:** [T25.md](T25.md); [T26.md](T26.md); [T33.md](T33.md); [local-bundle.md](local-bundle.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN falhas reais: versão válida observada; não alterei auth/binário para induzir falha.

### R10.1 / U10
- **Task / commit:** T24 330d241; T32 d81169d.
- **Preconditions:** Site/projetos/política e conta Jira.
- **Expected:** Ao consultar cards, usar enhanced search /rest/api/3/search/jql com assignee=currentUser e categoria não concluída, preservando o status real e seguindo nextPageToken.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Enhanced search com fields explícitos, currentUser/não concluído e nextPageToken.
- **Evidence:** [T24.md](T24.md); [T32.md](T32.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: consulta Jira real.

### R10.2 / U10
- **Task / commit:** T24 330d241; T32 d81169d.
- **Preconditions:** Site/projetos/política e conta Jira.
- **Expected:** Se parar por orçamento, falha ou paginação incompleta, marcar resultado parcial; uma página não é apresentada como total completo.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Cobertura/problemas/páginas/orçamento preservam parcial; ausência de resultado útil mantém estado anterior.
- **Evidence:** [T24.md](T24.md); [T32.md](T32.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: paginação/limite real não disponível.

### R11.1 / U11
- **Task / commit:** T08 eded612; T11 64ea581; T27 fb5ed1b.
- **Preconditions:** Repos autorizados e permissões existentes.
- **Expected:** Ao obter as três consultas is:pr/is:open, deduplicar por identidade remota no contexto, inclusive quando o mesmo PR vem de duas consultas ou conexões.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Três consultas pessoais abertas unidas por identidade/alias remoto.
- **Evidence:** [T08.md](T08.md); [T11.md](T11.md); [T27.md](T27.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: PR sobreposto real não consultado.

### R11.2 / U11
- **Task / commit:** T08 eded612; T11 64ea581; T27 fb5ed1b; C09 299514b.
- **Preconditions:** Repos autorizados e permissões existentes.
- **Expected:** Ao receber incomplete_results ou atingir limite/orçamento da busca, marcar parcial; distinguir revisão direta e de equipe quando houver dados suficientes.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** incomplete_results/limites preservam parcial; C09 compara ID autenticado final com usuários solicitados e publica revisão direta observada. Ausência não infere equipe; papéis da busca/contadores permanecem intactos.
- **Evidence:** [T08.md](T08.md); [T11.md](T11.md); [T27.md](T27.md); [C09.md](C09.md); [final-verification.md](final-verification.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: parcial, solicitação direta e equipe não verificados com PR real; nenhum cenário fabricado.

### R12.1 / U12
- **Task / commit:** T29 cce213e; C07 9957c09; T30 9b30356; T31 e13e1ab.
- **Preconditions:** Vínculos existentes no site/projetos/repos autorizados.
- **Expected:** Ao encontrar chave no título ou branch, mostrar origem da referência e repositório; ENG-241 não corresponde a ENG-2410 nem a outro site Jira por texto semelhante.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Parser ASCII com fronteiras Unicode/site/projeto e proveniência; C1.11 exclui URLs reconhecidas.
- **Evidence:** [T29.md](T29.md); [C07.md](C07.md); [T30.md](T30.md); [T31.md](T31.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: referência textual real em título/branch.

### R12.2 / U12
- **Task / commit:** T29 cce213e; C07 9957c09; T30 9b30356; T31 e13e1ab.
- **Preconditions:** Vínculos existentes no site/projetos/repos autorizados.
- **Expected:** Um PR acessível fora da lista pessoal pode aparecer como contexto sem alterar o contador; consulta parcial e ausência de acesso são rotuladas; não presumir API universal do painel Development.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Resolução M:N com dados contextuais separados das listas e cobertura explícita.
- **Evidence:** [T29.md](T29.md); [C07.md](C07.md); [T30.md](T30.md); [T31.md](T31.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: relação contextual fora da lista e escopo parcial reais.

### R13.1 / U13
- **Task / commit:** T11 64ea581; T12 b66305a; C03 ef973f2; T33 791c6ac.
- **Preconditions:** Dados reais prévios e condições externas disponíveis.
- **Expected:** Quando refresh falha com snapshot anterior, manter o conteúdo com desatualização e ação adequada; sem snapshot, mostrar estado inicial de falha, não zero.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** SourceSnapshot/status separam conteúdo, refresh e problema; sem snapshot não há zero.
- **Evidence:** [T11.md](T11.md); [T12.md](T12.md); [C03.md](C03.md); [T33.md](T33.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: offline/refresh após snapshot real não executado.

### R13.2 / U13
- **Task / commit:** T11 64ea581; T12 b66305a; C03 ef973f2; T33 791c6ac.
- **Preconditions:** Dados reais prévios e condições externas disponíveis.
- **Expected:** Quando não há vínculos após consulta completa, mostrar vazio; enquanto consulta estiver pendente, mostrar consultando; um serviço com problema não apaga o outro.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** RelatedItemsStore conserva observação e rotula consultando/vazio/erro; origem independente preservada.
- **Evidence:** [T11.md](T11.md); [T12.md](T12.md); [C03.md](C03.md); [T33.md](T33.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: vínculos vazios completos e falha parcial reais não executados.

### R14.1 / U14
- **Task / commit:** T12 b66305a; T13 a4d500c; T26 272ba61; T31 e13e1ab.
- **Preconditions:** Consultas reais em voo.
- **Expected:** Ao selecionar A e depois B, qualquer resposta tardia de A é descartada mesmo se cancelamento não interromper a rede/processo.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Guardas de seleção/generation/conexões/lease impedem publicação tardia.
- **Evidence:** [T12.md](T12.md); [T13.md](T13.md); [T26.md](T26.md); [T31.md](T31.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: corrida real A→B com rede.

### R14.2 / U14
- **Task / commit:** T12 b66305a; T13 a4d500c; T26 272ba61; T31 e13e1ab.
- **Preconditions:** Consultas reais em voo.
- **Expected:** Durante consulta aberta, manter itens sob o ponteiro estáveis; marcar novos dados/ordenação disponível e aplicar sem transferir a seleção por índice.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Snapshot apresentado estável; atualização explícita por identidade, nunca índice.
- **Evidence:** [T12.md](T12.md); [T13.md](T13.md); [T26.md](T26.md); [T31.md](T31.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: novo snapshot enquanto usuário percorre listas reais.

### R15.1 / U15
- **Task / commit:** T14 7d962b1; C04 3b8a1a6; C05 2eed4b3; C06 d1af26d; T32 d81169d.
- **Preconditions:** Contas e condições reais, sem provocar rate limit.
- **Expected:** Cliques repetidos em atualizar produzem no máximo uma consulta em voo por origem/escopo; respeitar Retry-After e reset, pausar trabalho desnecessário ao dormir.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Scheduler ocupa escopos atomicamente até finish e preserva cooldown/sleep/wake.
- **Evidence:** [T14.md](T14.md); [C04.md](C04.md); [C05.md](C05.md); [C06.md](C06.md); [T32.md](T32.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: clique repetido com rede e sleep/wake humano.

### R15.2 / U15
- **Task / commit:** T14 7d962b1; C04 3b8a1a6; C05 2eed4b3; C06 d1af26d; T32 d81169d.
- **Preconditions:** Contas e condições reais, sem provocar rate limit.
- **Expected:** Timeout, saída, páginas e repos têm limites documentados; atingimento gera parcial/timeout explícito; detalhe só atualiza enquanto relevante.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Budgets de chamadas/tempo/bytes/páginas/repos incluem fila; detalhe depende da seleção visível.
- **Evidence:** [T14.md](T14.md); [C04.md](C04.md); [C05.md](C05.md); [C06.md](C06.md); [T32.md](T32.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN runtime: limites/backoff não provocados; fronteiras revisadas.

### R16.1 / U16
- **Task / commit:** T23 cb9c140; T25 10871d4; T26 272ba61; T37 d9ed688.
- **Preconditions:** gh existente e destino real autorizado.
- **Expected:** Somente executar arquivo gh escolhido/validado e chamadas REST permitidas; títulos, chave e nomes de repo não se tornam comandos, flags, arquivos ou instruções.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Binário nativo/caminho qualificado e endpoints tipados; entradas não viram shell/flags.
- **Evidence:** [T23.md](T23.md); [T25.md](T25.md); [T26.md](T26.md); [T37.md](T37.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN completo: binário válido observado; chamadas de dados não executadas.

### R16.2 / U16
- **Task / commit:** T23 cb9c140; T25 10871d4; T26 272ba61; T37 d9ed688.
- **Preconditions:** gh existente e destino real autorizado.
- **Expected:** Abrir apenas HTTPS do site Jira configurado ou github.com, com destino validado; rejeitar javascript, file, shell e host divergente.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** NavigationCoordinator valida HTTPS exato, site/repo/proveniência e intenção atual após await.
- **Evidence:** [T23.md](T23.md); [T25.md](T25.md); [T26.md](T26.md); [T37.md](T37.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: abrir/copiar destino de item real.

### R17.1 / U17
- **Task / commit:** T05 7861676; T07 5fe9ecb; T21 09450fd; T40 d26d4db.
- **Preconditions:** Teclado/VoiceOver e preferência escolhida pelo usuário.
- **Expected:** Com teclado no painel, Tab/setas/Enter/Esc têm foco visível e rótulos completos; com painel fechado, nenhuma tecla global é capturada.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Foco por identidade/contorno; handlers locais; monitores globais somente de mouse.
- **Evidence:** [T21.md](T21.md); [visual-accessibility.md](visual-accessibility.md); [performance.md](performance.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN completo: Tab/ShiftTab/Return/Space/Esc geral CUA passou; VoiceOver e linhas reais pendentes.

### R17.2 / U17
- **Task / commit:** T05 7861676; T07 5fe9ecb; T21 09450fd; T40 d26d4db.
- **Preconditions:** Teclado/VoiceOver e preferência escolhida pelo usuário.
- **Expected:** Com Reduzir Movimento, usar transição discreta sem expansão ampla; status e seleção continuam identificáveis sem cor.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Reduce Motion consulta preferência e usa tamanho final/fade, sem expansão ampla; estados têm texto/símbolo.
- **Evidence:** [T21.md](T21.md); [visual-accessibility.md](visual-accessibility.md); [performance.md](performance.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: preferência global não alterada pelo agente; observação humana solicitada.

### R18.1 / U18
- **Task / commit:** T03 99e3318; T38 5d98465; T41 833c2d9.
- **Preconditions:** Hardware/modos disponíveis escolhidos pelo usuário.
- **Expected:** Ao mudar resolução, escala ou conectar/desconectar display, recalcular uma única instância sem sair da tela ou misturar contexto.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** DisplayPolicyController atualiza mesma instância, cancela transição e mantém preferência indisponível/fallback.
- **Evidence:** [T03.md](T03.md); [T38.md](T38.md); [local-bundle.md](local-bundle.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN hotplug/escala: escolha de tela interna no app persistiu, retorno ao automático observado.

### R18.2 / U18
- **Task / commit:** T03 99e3318; T38 5d98465; T41 833c2d9.
- **Preconditions:** Hardware/modos disponíveis escolhidos pelo usuário.
- **Expected:** Em fullscreen/Spaces/Stage Manager, cumprir política explicitamente qualificada; se não for possível sobrepor com APIs públicas, oferecer menu bar e registrar limitação.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Menu alternativo e flags públicas preservados; não afirmam suporte universal.
- **Evidence:** [T03.md](T03.md); [T38.md](T38.md); [local-bundle.md](local-bundle.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN por modo individual: resposta humana anterior confirmou acesso genericamente.

### R19.1 / U19
- **Task / commit:** T34 965578b; T35 066b86b; T36 d3f95f7.
- **Preconditions:** Preferências próprias; conta real para ciclo de dados.
- **Expected:** Ao reiniciar, consultar dados novamente e manter somente preferências não secretas; nenhum banco/cache em disco de títulos e PRs é criado por padrão.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Schema allowlist sem cache de negócio; startup metadata-only e retomada explícita.
- **Evidence:** [T34.md](T34.md); [T35.md](T35.md); [local-bundle.md](local-bundle.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN completo: preferências gh/tela e startup desconectado passaram; retomada com dados não exercitada.

### R19.2 / U19
- **Task / commit:** T34 965578b; T35 066b86b; T36 d3f95f7.
- **Preconditions:** Preferências próprias; conta real para ciclo de dados.
- **Expected:** Ao mudar contexto ou detectar mudança de usuário no gh nas fronteiras de consulta, descartar seleções/snapshots/lote incompatíveis; ao desconectar, limpar apenas estado próprio. A limitação de troca externa A→B→A não observada é declarada, sem prometer sessão transacional entre contas.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** configurationID/contexto/IDs invalidam snapshots/seleções; fronteiras /user e limitação A→B→A declaradas.
- **Evidence:** [T34.md](T34.md); [T35.md](T35.md); [local-bundle.md](local-bundle.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: desconexão e mudança de conta reais.

### R20.1 / U20
- **Task / commit:** T19 892c825; T33 791c6ac; T36 d3f95f7.
- **Preconditions:** Contas/políticas por origem.
- **Expected:** Jira e GitHub podem conectar independentemente; a origem disponível continua útil enquanto a outra precisa de conexão/reconexão.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Estados/controllers por origem e scheduler compartilhado preservam trabalho independente.
- **Evidence:** [T19.md](T19.md); [T33.md](T33.md); [T36.md](T36.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: conectar apenas uma origem exige conta.

### R20.2 / U20
- **Task / commit:** T19 892c825; T33 791c6ac; T36 d3f95f7.
- **Preconditions:** Contas/políticas por origem.
- **Expected:** Os botões de conexão refletem o modo pessoal escolhido: token seguro para Jira e gh existente para GitHub; não prometer OAuth próprio pronto.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Forms refletem token pessoal Jira e gh existente, sem promessa de OAuth pronto.
- **Evidence:** [T19.md](T19.md); [T33.md](T33.md); [T36.md](T36.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN completo: escolha/versão gh observadas; fluxo Jira ainda pessoal e pendente.

### R21.1 / U21
- **Task / commit:** C08 45cafdd; T41 833c2d9.
- **Preconditions:** Artefato local existente.
- **Expected:** Ao empacotar, registrar target, SDK, assinatura, Hardened Runtime e política de sandbox realmente usados; iniciar pelo Finder/caminho completo é verificado.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Build e metadados reais: SDK 27, ad-hoc/runtime, sem sandbox/get-task-allow; caminho completo.
- **Evidence:** [C08.md](C08.md); [local-bundle.md](local-bundle.md).
- **Mode / action / observed / limits — MANUAL:** PASS: Release iniciou, configurações e gh --version funcionaram pelo caminho completo.

### R21.2 / U21
- **Task / commit:** C08 45cafdd; T41 833c2d9.
- **Preconditions:** Artefato local existente.
- **Expected:** Build local não marca notarização, Mac App Store, máquina limpa ou suporte Enterprise como validados; nenhuma publicação é realizada.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Relatório limita entrega local; não houve publicação nem alegação de notarização/máquina limpa/Enterprise.
- **Evidence:** [C08.md](C08.md); [local-bundle.md](local-bundle.md).
- **Mode / action / observed / limits — MANUAL:** —: critério documental, evidência BUILD/REVIEW.

### R22.1 / U22
- **Task / commit:** T39 23ed6f5.
- **Preconditions:** App real sem contas; itens reais para protocolo completo.
- **Expected:** Abrir, fechar e trocar seleção funciona sem esperar consulta de rede; em 30 ciclos manuais, não deixa painéis/observadores extras ou região invisível de clique.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Animação local/cancelamento e reaproveitamento de painel independem de payload de rede.
- **Evidence:** [performance.md](performance.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN completo: três ciclos CUA sem itens; 30 ciclos com seleção/físico pendentes.

### R22.2 / U22
- **Task / commit:** T39 23ed6f5.
- **Preconditions:** App real sem contas; itens reais para protocolo completo.
- **Expected:** Registrar duração/engasgos e repouso observados ou NOT-RUN; nenhuma meta de desempenho é considerada atingida por screenshot ou análise estática.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Relatório separa dois pontos de repouso dos parâmetros/tempos não medidos.
- **Evidence:** [performance.md](performance.md).
- **Mode / action / observed / limits — MANUAL:** —: MEASURE PASS limitado a duas leituras de repouso; duração/engasgos NOT-RUN explícitos.

### R23.1 / U23
- **Task / commit:** T01 18f1de9; handoffs01–06; T42 neste commit.
- **Preconditions:** Handoffs, commits e revisor sem histórico do autor.
- **Expected:** Cada worker recebe spec/context/design/contratos e seu lote, comunica dúvidas ao especialista/pares e registra acordos via orquestrador antes de mudar contrato.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Contratos/contexto canônicos e acordos entre pares registrados antes dos consumidores.
- **Evidence:** [../handoffs/batch-05.md](../handoffs/batch-05.md); [../handoffs/batch-06-implementation.md](../handoffs/batch-06-implementation.md); [../../.specs/features/radar/coordination.md](../../.specs/features/radar/coordination.md).
- **Mode / action / observed / limits — MANUAL:** —: critério de processo/documentação.

### R23.2 / U23
- **Task / commit:** T01 18f1de9; handoffs01–06; T42 545705e; C09 299514b.
- **Preconditions:** Handoffs, commits e revisor sem histórico do autor.
- **Expected:** Somente um worker escreve código por lote; lotes seguem ordem; verificador fresco usa spec e evidências sem herdar raciocínio do autor.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Ownership sequencial registrado; verificação final fresca executada após T42, achado P2 corrigido e revisto em C09.
- **Evidence:** [../handoffs/batch-05.md](../handoffs/batch-05.md); [../handoffs/batch-06-implementation.md](../handoffs/batch-06-implementation.md); [../../.specs/features/radar/coordination.md](../../.specs/features/radar/coordination.md); [final-verification.md](final-verification.md).
- **Mode / action / observed / limits — MANUAL:** —: critério de processo; revisão final pós-commit executada, sem substituir gates reais.

### R24.1 / U24
- **Task / commit:** T01 18f1de9; T39 23ed6f5.
- **Preconditions:** Evidência histórica delimitada.
- **Expected:** Reutilizar as evidências de Boring Notch já obtidas para inventário/plist; elas não provam animação nem execução no macOS 27.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Evidência REA herdada limitada a inventário/plist, sem alegação de animação/runtime.
- **Evidence:** [T01.md](T01.md); [../../.specs/features/radar/research.md](../../.specs/features/radar/research.md); [performance.md](performance.md).
- **Mode / action / observed / limits — MANUAL:** —: critério documental.

### R24.2 / U24
- **Task / commit:** T01 18f1de9; T39 23ed6f5.
- **Preconditions:** Evidência histórica delimitada.
- **Expected:** Nova investigação declara alvo/hash/pergunta/tipo de evidência e limites; não executar binário de terceiro nem reparar configuração por presunção.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Nenhuma nova investigação/binário terceiro/configuração foi executada nesta implementação.
- **Evidence:** [T01.md](T01.md); [../../.specs/features/radar/research.md](../../.specs/features/radar/research.md); [performance.md](performance.md).
- **Mode / action / observed / limits — MANUAL:** —: nenhuma nova investigação necessária; revisão de escopo.

### R25.1 / U25
- **Task / commit:** T01 18f1de9; manifesto; T42 neste commit.
- **Preconditions:** Árvore/commits e documentação canônica.
- **Expected:** Antes de avançar, registrar requisito, gate, evidência e commit atômico; falha ou NOT-RUN de gate obrigatório impede concluir a tarefa/lote.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Manifesto aponta commits/evidências; Prepared/PARTIAL conserva gates externos sob AD013.
- **Evidence:** [manifest.md](manifest.md); [../../.specs/features/radar/tasks.md](../../.specs/features/radar/tasks.md).
- **Mode / action / observed / limits — MANUAL:** —: critério documental.

### R25.2 / U25
- **Task / commit:** T01 18f1de9; manifesto; T42 neste commit.
- **Preconditions:** Árvore/commits e documentação canônica.
- **Expected:** Não gerar testes/mocks/sensores automáticos; verificação manual/build é identificada como tal, e testes automatizados/sensor ficam NOT-RUN por política.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Sem testes/mocks/sensores novos; build/review/CUA/medidas separados e automação de testes NOT-RUN por política.
- **Evidence:** [manifest.md](manifest.md); [../../.specs/features/radar/tasks.md](../../.specs/features/radar/tasks.md).
- **Mode / action / observed / limits — MANUAL:** —: critério documental e inventário versionado.

### R26.1 / U26
- **Task / commit:** T08 eded612; T13 a4d500c; T27 fb5ed1b; T30 9b30356; T35 066b86b.
- **Preconditions:** Dados autorizados e conta estável nas fronteiras.
- **Expected:** Mesmo PR remoto visto por duas origens no mesmo contexto deduplica; PRs de hosts/repos diferentes com mesmo número permanecem distintos.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** IDs e aliases distinguem host/repo/número no contexto; dedup por identidade.
- **Evidence:** [T08.md](T08.md); [T13.md](T13.md); [T27.md](T27.md); [T30.md](T30.md); [T35.md](T35.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: comparar objetos reais por múltiplas consultas.

### R26.2 / U26
- **Task / commit:** T08 eded612; T13 a4d500c; T27 fb5ed1b; T30 9b30356; T35 066b86b.
- **Preconditions:** Dados autorizados e conta estável nas fronteiras.
- **Expected:** Chave Jira é apresentação; identidade usa site e issueID; seleção usa contexto+identidade, e mudança de identidade autenticada detectada invalida resultados anteriores. Lotes gh são qualificados por GET /user antes e ao publicar; divergência descarta o lote e falha na qualificação final impede publicar dados novos.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Jira usa site/issueID; seleção/contexto e /user antes/depois descartam lote incompatível.
- **Evidence:** [T08.md](T08.md); [T13.md](T13.md); [T27.md](T27.md); [T30.md](T30.md); [T35.md](T35.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: mudança externa voluntária de conta não executada pelo agente.

### R27.1 / U27
- **Task / commit:** T23 cb9c140; T26 272ba61; T33 791c6ac.
- **Preconditions:** Condições externas existentes, sem fabricar cenário.
- **Expected:** Erro 401 ou necessidade de auth do gh permite pedir reconexão; 403/code 1 não é automaticamente chamado de sessão expirada.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** 401/auth-required separados de 403/SSO/code1; guidance específica, sem elevar escopo.
- **Evidence:** [T23.md](T23.md); [T26.md](T26.md); [T33.md](T33.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: falhas de auth/permissão reais não provocadas.

### R27.2 / U27
- **Task / commit:** T23 cb9c140; T26 272ba61; T33 791c6ac.
- **Preconditions:** Condições externas existentes, sem fabricar cenário.
- **Expected:** 429/limite respeita espera; timeout, cancelamento, JSON inválido e capacidade indisponível têm representação própria e não viram vazio.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** 429/503/backoff, timeout/cancel/JSON/limites são tipados; não transformados em vazio.
- **Evidence:** [T23.md](T23.md); [T26.md](T26.md); [T33.md](T33.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: falhas externas reais não provocadas.

### R28.1 / U28
- **Task / commit:** T23 cb9c140; T24 330d241; T26 272ba61; T37 d9ed688.
- **Preconditions:** Escopos existentes autorizados; auth apenas pelo usuário.
- **Expected:** Os únicos efeitos sobre serviços de trabalho são consultas autenticadas e abertura de links; não há merge, aprovação, comentário, transição de card ou alteração de repo.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Trabalho remoto somente GET/consultas; navegação e cópia explícitas, sem mutação Jira/GitHub.
- **Evidence:** [T23.md](T23.md); [T24.md](T24.md); [T26.md](T26.md); [T37.md](T37.md); [local-bundle.md](local-bundle.md).
- **Mode / action / observed / limits — MANUAL:** NOT-RUN: consulta/navegação de itens reais.

### R28.2 / U28
- **Task / commit:** T23 cb9c140; T24 330d241; T26 272ba61; T37 d9ed688.
- **Preconditions:** Escopos existentes autorizados; auth apenas pelo usuário.
- **Expected:** Auth local, copiar link e preferências têm escopo explícito; permissões existentes do token não são descritas como somente leitura se concederem mais.
- **Mode / action / observed — REVIEW PASS limitado ao modo:** Textos distinguem operações limitadas do Radar das permissões possivelmente mais amplas do token/gh.
- **Evidence:** [T23.md](T23.md); [T24.md](T24.md); [T26.md](T26.md); [T37.md](T37.md); [local-bundle.md](local-bundle.md).
- **Mode / action / observed / limits — MANUAL:** —: descrição e fronteiras revisadas; nenhuma credencial lida pelo agente.

## Totais por modo e bloqueios

- REVIEW: 56 PASS limitados a fonte/documentação após C09; 0 FAIL pendentes; 0 NOT-RUN de revisão. A rodada inicial teve 55 critérios sem achado adicional e 1 FAIL (R11.2), preservado em final-verification.md.
- MANUAL: 3 PASS no critério delimitado; 44 NOT-RUN integral com observações parciais explicitadas; 9 critérios sem gate MANUAL aplicável, tratados em REVIEW/MEASURE.
- BUILD: 1 registro agregado PASS (R21.1) com builds por tarefa no manifesto; 0 FAIL pendentes.
- MEASURE: 1 registro PASS limitado (R22.2, repouso); duração/engasgos e protocolo completo não executados.
- Nenhum total acima é cobertura automatizada nem aceite global. Testes/mocks/sensores/Swift lint: NOT-RUN por política ou ausência de execução.

Bloqueios que impedem aceite: política/escopos/contas Jira e GitHub; Keychain/consentimento/remoção; listas e relação bidirecional reais; navegação/copiar e foco no navegador; teclado preenchido/VoiceOver/Reduzir Movimento; 30 ciclos com seleção e hit-through; modos/displays não observados. Não provocar falhas de provider ou trocar credenciais para satisfazer cenários.

As questões de interação humana foram enviadas com Release aberto e recolhido. O registro [pending-gates.md](pending-gates.md) define entradas e limites; nenhuma pendência autoriza publicação, instalação ou configuração global.

## Handoff para verificador fresco

Revisar este commit e a árvore real contra spec/STATE/design/C1–C1.11/tasks/manifest, handoffs01–06 e relatórios T39–41. Conferir precisão das alegações e invariantes, sem repetir autenticação/cofre ou fabricar dados. Root é o único escritor; achado concreto gera correção atômica, gate apropriado e nova revisão antes de fechar. Resultado independente registrado em [final-verification.md](final-verification.md).
