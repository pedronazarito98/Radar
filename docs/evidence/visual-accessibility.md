# T40 — Revisão visual e acessibilidade

**PARTIAL.** Revisor independente `visual_accessibility_review`, contexto fresco, leu fontes canônicas e comparou capturas reais sem contas em HEAD `881b050` (código T38 `5d98465`). REVIEW visual/código PASS qualificado; sem defeito bloqueador confirmado no escopo examinado. O revisor não executou app, build, preferências globais ou contas e não alterou arquivos.

## Visual observado

Comparação de [V3 canônica](../../assets/notch-radar-conexoes-v3.png), [painel expandido](images/T38-expanded.png) e [compacto](images/T38-compact.png): superfície escura, Jira à esquerda, GitHub à direita, separadores neutros, faixa inferior única, ausência de barra lateral colorida. Totais `—` e desconexão em texto, sem zero falso. GitHub branco é a exceção aprovada AD-014. Não há dados de negócio artificiais nas capturas.

O recorte central está vazio na captura; isso não prova passagem de cliques nem posicionamento físico em outros displays. Seleção cinza/listas preenchidas e identificação de repositórios extensos foram revisadas na fonte, mas permanecem NOT-RUN visual com conteúdo real.

## REVIEW estático independente

| Comportamento | Evidência de fonte | Resultado e limite |
| --- | --- | --- |
| Foco visível neutro | RadarFocusOutline.swift; RadarFocusCoordinator.swift | PASS: contorno, identidade estável, retorno à origem/fallback. Linhas reais não exercitadas. |
| Teclado local | RadarContentView.swift; PanelInteractionController.swift | PASS: Tab/Shift-Tab/ativação locais, modificadores respeitados; monitor global somente de mouse. VoiceOver não executado. |
| Rótulos e estados | JiraRowView.swift; GitHubRowView.swift; SourceStatusText.swift | PASS: texto/símbolo, nome completo de repo e seleção acessível. Não mede contraste nem legibilidade de todos os conteúdos. |
| Faixa inferior | DetailsStripView.swift | PASS: altura limitada, rolagem e ações nomeadas. Esc em duas etapas e retorno com dados reais NOT-RUN. |
| Reduzir Movimento | PresentationMotionPolicy.swift; NotchPanelController.swift | PASS: preferência consultada por transição, tamanho final/fade na abertura e fechamento imediato. Preferência real não foi alterada nem executada. |

Fontes ficam sob `Radar/Presentation/` e `Radar/Platform/`; links/linhas podem ser localizados no código do commit T38. A revisão T36–T38 anterior de `native_final_review` também passou e está nos relatórios individuais.

## Interação e pendências

Root executou os três ciclos CUA descritos em [T39](performance.md): abrir pelos indicadores e recolher por Return/Espaço/Escape, com foco em Recolher e estado final compacto. Essa observação é separada da inspeção visual independente.

**NOT-RUN:** VoiceOver; Reduzir Movimento real; listas/repos/títulos extensos; setas e ações em linhas/relações; abrir/copiar e foco no navegador; Esc em duas etapas; contraste medido; troca de escala/resolução/monitor; matriz individual Spaces/tela cheia/Stage Manager; hit-through físico deste build e interrupção dentro de frame de animação. O usuário havia confirmado recorte/cliques e foco/alternância em builds anteriores (T04/T05/T07), sem qualificar esses novos cenários.

T40/R17 não estão aceitos integralmente. Não foram criados/executados testes, mocks, sensor ou lint; nenhuma configuração global foi alterada. O roteiro humano fica em [gates pendentes](pending-gates.md), para execução no bundle final sem exigir credenciais.
