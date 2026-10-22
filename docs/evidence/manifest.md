# Manifesto de execução

Hashes são inseridos somente após cada commit existir; o próprio hash mais recente fica no handoff seguinte para evitar autorreferência. Gates e evidências pertencem à tarefa do commit, com modo explícito.

| Tarefa | Commit real | Gate | Evidência |
|---|---|---|---|
| T01 | 18f1de9140ad462a92346d07845242ebe9477d6b | DOC PASS | T01.md |
| T02 | c9105743d3dbdc551d4263285bf2fcb94c65ec47 | BUILD/REVIEW + MANUAL humano PASS | T02.md |
| T03 | 99e33183f8d73b299ff8a1a1947b87acfa65206a | BUILD + REVIEW PASS | T03.md |
| T04 | eab3dab56e81fc1219080c0e574505b470f8aaba | PARTIAL; BUILD/REVIEW/abre-recolhe/recorte/hit-through/cleanup PASS; modos NOT-RUN | T04.md |
| T05 | 7861676556bbc80aacec7d0f1a198e8de5d7289d | PARTIAL; BUILD/REVIEW/Esc PASS; foco externo NOT-RUN | T05.md |
| T06 | ce3c7d016925ed3ea9a999189e17abc4e46de979 | Prepared; BUILD/REVIEW visual PASS, dependências parciais | T06.md |
