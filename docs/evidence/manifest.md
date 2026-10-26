# Manifesto de execução

Hashes são inseridos somente após cada commit existir; o próprio hash mais recente fica no handoff seguinte para evitar autorreferência. Gates e evidências pertencem à tarefa do commit, com modo explícito.

Complemento T34/T35: `c952406`, persistência do caminho gh e encerramento/reabertura observados via CUA no Debug T35; cofre/contas continuam NOT-RUN.

| Tarefa | Commit real | Gate | Evidência |
|---|---|---|---|
| T01 | 18f1de9140ad462a92346d07845242ebe9477d6b | DOC PASS | T01.md |
| T02 | c9105743d3dbdc551d4263285bf2fcb94c65ec47 | BUILD/REVIEW + MANUAL humano PASS | T02.md |
| T03 | 99e33183f8d73b299ff8a1a1947b87acfa65206a | BUILD + REVIEW PASS | T03.md |
| T04 | eab3dab56e81fc1219080c0e574505b470f8aaba | PARTIAL; BUILD/REVIEW/abre-recolhe/recorte/hit-through/cleanup PASS; modos NOT-RUN | T04.md |
| T05 | 7861676556bbc80aacec7d0f1a198e8de5d7289d | Prepared; BUILD/REVIEW/Esc + foco/teclado humano PASS; T04 parcial | T05.md |
| T06 | ce3c7d016925ed3ea9a999189e17abc4e46de979 | Prepared; BUILD/REVIEW visual PASS, dependências parciais | T06.md |
| T07 | 5fe9ecb6e64aecc435d017e82e603bbf9d12826a | PARTIAL; BUILD/REVIEW/CUA + alternância humana PASS; reduzido NOT-RUN | T07.md |
| T08 | eded6129418d558b3b0dc4f8b83265a69457bf99 | Prepared; BUILD + REVIEW independente PASS; dependências parciais | T08.md |
| T09 | 2ee8cdebe0fd1390144e6f3e63d3acb6ec36bb41 | Prepared; BUILD + REVIEW independente PASS; dependências parciais | T09.md |
| T10 | 1fb9d4ea48ecbe58a0c36b070c4b7fdf933ed844 | Prepared; BUILD + REVIEW independente PASS; C1.3 aplicado; dependências parciais | T10.md |
| T11 | 64ea58177bf5966a76dc163ab36dcba87ad95fef | Prepared; BUILD + REVIEW independente PASS; dependências parciais | T11.md |
| T12 | b66305a5714ae986aebabcf6f9a08ab1afcfa232 | Prepared; BUILD + REVIEW independente PASS; dependências parciais | T12.md |
| C01 | e00a903 | Prepared; BUILD + REVIEW independente PASS; C1.4 | C01.md |
| T13 | a4d500cebfdebf0f9473295f1bd60bbcbbb89ffd | Prepared; BUILD/REVIEW independente retomada PASS; runtime NOT-RUN | T13.md |
| T14 | 7d962b1bfb5a1b768da039bcabbf32fe517ff876 | Prepared; BUILD/REVIEW independente após C04 PASS; runtime NOT-RUN | T14.md |
| T15 | 3706fcb | Prepared; BUILD + UI-base CUA/AX desconectada PASS | T15.md |
| T16 | 49a0425 | Prepared; BUILD + visual CUA desconectado PASS | T16.md |
| T17 | d96c7d0 | Prepared; BUILD + visual CUA desconectado PASS | T17.md |
| T18 | 23b8fb8 | Prepared; BUILD + visual CUA sem seleção PASS | T18.md |
| T19 | 892c825 | Prepared; BUILD/formulários CUA/seleção humana gh PASS | T19.md |
| T20 | f2f411f | Prepared; BUILD/REVIEW autor + UI-base posterior PASS | T20.md |
| T21 | 09450fd | PARTIAL; BUILD/REVIEW autor/UI-base desconectada PASS | T21.md |
| C02 | b5b957b | BUILD/REVIEW independente PASS; runtime preenchido NOT-RUN | C02.md |
| C03 | ef973f2 | BUILD/REVIEW independente PASS; runtime relações NOT-RUN | C03.md |
| T22 | 671efae | Prepared; BUILD/REVIEW independente PASS; cofre runtime NOT-RUN | T22.md |
| T23 | cb9c140 | Prepared/PARTIAL; BUILD/REVIEW independente PASS; LIVE-Jira NOT-RUN | T23.md |
| C04 | 3b8a1a6 | BUILD/REVIEW independente PASS; runtime NOT-RUN | C04.md |
| C05 | 2eed4b3 | BUILD/REVIEW independente PASS; runtime NOT-RUN | C05.md |
| T24 | 330d241 | Prepared/PARTIAL; BUILD/REVIEW independente PASS; LIVE-Jira NOT-RUN | T24.md |
| T25 | 10871d4 | BUILD/REVIEW independente/UI-gh versão PASS; auth/Finder final NOT-RUN | T25.md |
| T26 | 272ba61 | BUILD/REVIEW independente PASS; LIVE-GitHub NOT-RUN | T26.md |
| T27 | fb5ed1b | BUILD/REVIEW independente PASS; LIVE-GitHub NOT-RUN | T27.md |
| T28 | 3c6ebc2 | BUILD/REVIEW independente PASS; LIVE-GitHub NOT-RUN | T28.md |
| T29 | cce213e | BUILD/REVIEW independente PASS | T29.md |
| C06 | d1af26d | BUILD/REVIEW independente PASS; corridas runtime NOT-RUN | C06.md |
| T30 | 9b30356 | BUILD/REVIEW independente PASS; LIVE-Relações NOT-RUN | T30.md |
| C07 | 9957c09 | REVIEW PASS; BUILD árvore com WIP T31 PASS | C07.md |
| T31 | e13e1ab | BUILD/REVIEW independente PASS; LIVE/foco preenchido NOT-RUN | T31.md |
| T32 | d81169d | BUILD/REVIEW independente PASS; LIVE/sleep-wake NOT-RUN | T32.md |
| T33 | 791c6ac | BUILD/REVIEW independente PASS; LIVE/recuperação real NOT-RUN | T33.md |
| T34 | 965578b | BUILD/REVIEW e UI persistência gh/tela PASS; cofre/categorias reais NOT-RUN | T34.md |
| T35 | 066b86b | BUILD/REVIEW/quit-reinício desconectado PASS; LIVE/shutdown em voo NOT-RUN | T35.md |
| T36 | d3f95f7 | BUILD/REVIEW independente PASS; UI-integrada/LIVE NOT-RUN | T36.md |
| T37 | d9ed688 | BUILD/REVIEW independente PASS; UI-integrada/navegação real NOT-RUN | T37.md |
| T38 | 5d98465 | BUILD/REVIEW/preferência da tela interna via UI PASS; hotplug/modos NOT-RUN | T38.md |
| T39 | 23ed6f5 | PARTIAL; 3 ciclos CUA/2 pontos repouso; 30 ciclos/timing NOT-RUN | performance.md |
| T40 | d26d4db | PARTIAL; REVIEW visual/código independente PASS; a11y real NOT-RUN | visual-accessibility.md |
| C08 | 45cafdd | BUILD Release/REVIEW/codesign PASS | C08.md |
| T41 | 833c2d9 | BUILD/codesign/launch/UI gh e prefs PASS; auth NOT-RUN | local-bundle.md |
| T42 | 545705e | 56 registros; revisão fresca executada, P2 resolvido em C09; aceite real bloqueado | acceptance.md; final-verification.md |
| C09 | 299514b | BUILD Debug/Release/REVIEW independente/codesign/launch sem contas PASS; rótulo LIVE NOT-RUN | C09.md |
| G01 | 7dd8c45 | DOC/diffcheck PASS; contrato GitHub nativo publicado antes dos consumidores | ../../.specs/features/radar/github-onboarding.md |
| G02 | 5aaf302 | Prepared/PARTIAL; BUILD Debug/Release finais e REVIEW fresco PASS estático; LIVE NOT-RUN | G02-implementation.md |
| G03 | 9391b3e | PARTIAL; bundle/UI desconectada/quit-reabertura PASS limitados, cadastro então pendente | G03.md |
| G04 documental inicial | a9b5401 | DOC/revisão estreita PASS; ativação assistida definida, então em Confirm access | G04.md |
| G04 configuração pública | 859b273 | BUILD Debug/Release, revisão estreita/fingerprint, codesign e UI Conectar habilitado PASS; OAuth/cofre/catalog pendentes | G04.md |

G03 preserva a qualificação desconectada anterior à configuração pública. A continuação [G04](G04.md) confirmou cadastro próprio privado, instalação escolhida pelo usuário, configuração do build e Conectar habilitado em 859b273, com BUILD Debug/Release e revisão estreita PASS; OAuth/cofre/catalog/PRs ainda exigem gates próprios. Ver [guia](../github-setup.md) e [handoff](../handoffs/github-native.md).
