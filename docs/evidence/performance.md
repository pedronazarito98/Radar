# T39 — Fluidez e recursos

**PARTIAL.** UI desconectada e duas observações nativas de repouso registradas em 23/10/2026. Os 30 ciclos manuais com seleção, hit-through físico, duração de frames/transições e consultas em voo permanecem **NOT-RUN**. Nenhum sensor, harness, teste ou dado artificial foi criado.

## Ambiente e artefato

- macOS 27.0.1, arm64, tela interna 1470×956 pt @2, notch de 179 pt, 60 Hz; configuração de display/global não alterada.
- Código T38 `5d98465`, handoff `881b050`, Debug Swift 6 strict/SDK 27.0. Build real PASS pelo escritor antes do handoff; root abriu o bundle por caminho completo.
- Bundle: `.build/DerivedData/Build/Products/Debug/Radar.app`. Executável SHA-256 `75f65f44031b928479484f2a3293c9f178817d58e59f8096c35b08cd47004e39`.
- `ps` confirmou uma instância Radar nesse caminho, PID 74019. Não havia contas conectadas, dados de negócio, consultas de provider ou entrada de token.

## Interação observada — MANUAL via CUA

1. Inicialização compacta: somente indicadores Jira/GitHub, “Total desconhecido” e “Conta não conectada”. Clique no indicador Jira abriu a visão geral; Tab manteve o foco visível em Recolher; Return recolheu.
2. Clique no indicador GitHub abriu; Shift-Tab e Espaço recolheram.
3. Clique no indicador Jira abriu; Escape recolheu.

Em cada mudança o root consultou a árvore de acessibilidade real. Aberto: duas colunas e faixa inferior sem seleção. Fechado: conteúdo expandido removido da árvore e dois indicadores. Capturas [aberto](images/T38-expanded.png) e [compacto](images/T38-compact.png) documentam aparência, não timing ou entrega de cliques ao app inferior. Nenhuma espera por rede foi necessária neste estado sem contas.

São **3 ciclos**, não 30. Seleção/troca de itens, resposta em voo, Esc em duas etapas e resíduos de hit area física não foram exercitados nesta etapa; dependem de itens reais ou observação humana. A confirmação humana anterior de recorte/foco/alternância permanece em T04/T05/T07, sem ser ampliada para este protocolo.

## MEASURE — duas observações de repouso

Painel compacto, sem interação entre as leituras. Comando nativo: `ps -p 74019 -o pid=,%cpu=,rss=,time=,etime=`; timestamp via `date -u`. Não foram lidos logs, argumentos de outros processos ou arquivos de auth.

| Timestamp UTC (local UTC−3) | CPU reportada por ps | RSS (KiB) | CPU acumulada | Tempo do processo |
| --- | --- | --- | --- | --- |
| 2026-10-24 00:12:19 (23/10 21:12:19) | 0.0% | 98256 | 1.02 s | 1 min 10 s |
| 2026-10-24 00:12:56 (23/10 21:12:56) | 0.0% | 98064 | 1.03 s | 1 min 47 s |

Isso registra dois pontos e aproximadamente 0,01 s adicional de CPU acumulada em 37 s. Não é perfil contínuo, teste de vazamento, consumo com contas, garantia de estabilidade prolongada nem meta de desempenho atingida. A duração configurada de 250/120 ms é parâmetro, não medição. Engasgos/duração real de animação: **NOT-RUN**.

## REVIEW e fechamento

`NotchFrameAnimator` usa geração, timer transitório e cancelamento; `NotchPanelController` reaproveita o painel e interrompe animação antiga; `DataLifecycleController` e `DisplayPolicyController` removem observadores próprios. Reviews independentes T32/T35/T38 confirmaram as invariantes, sem provar recursos internos em runtime. A evidência REA anterior continua limitada a inventário/plist; não foi repetida nem usada para inferir fluidez.

R22.1 não está aceito: 30 ciclos completos e observação física pendentes. R22.2 tem estas medidas limitadas e NOT-RUN explícito para transições. Testes/mocks/sensores/lint não executados. Prosseguimento independente permitido por AD-013, sem dispensar gate.
