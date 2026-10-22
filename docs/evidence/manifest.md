# Manifesto de execução

Hashes são inseridos somente após cada commit existir; o próprio hash mais recente fica no handoff seguinte para evitar autorreferência. Gates e evidências pertencem à tarefa do commit, com modo explícito.

| Tarefa | Commit real | Gate | Evidência |
|---|---|---|---|
