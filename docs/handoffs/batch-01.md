# Handoff preparatório — lote 1 (T01–T07)

Base de código entregue: `5fe9ecb6e64aecc435d017e82e603bbf9d12826a` (T07). Repositório canônico `/Users/pedronazarito/Developer/Radar`, branch `feat/radar-v1-local`, sem remote. O commit documental deste handoff é informado pelo worker ao orquestrador depois de existir; não há autorreferência inventada.

Lote preparado, **não concluído nem aceito**. AD-013 permite a preparação sequencial de domínio T08–T14, independente dos gates manuais abaixo. Após este commit, batch_1 libera ownership de código, documentação e controle UI ao root; nenhum consultor escreve. O próximo writer deve reler AGENTS/STATE/design/tasks e este handoff.

## Commits e gates

| Tarefa | Commit real | Resultado |
|---|---|---|
| T01 | 18f1de9140ad462a92346d07845242ebe9477d6b | Complete; migração canônica, prontidão e DOC PASS |
| T02 | c9105743d3dbdc551d4263285bf2fcb94c65ec47 | Complete; BUILD/REVIEW + UI-base humana PASS |
| T03 | 99e33183f8d73b299ff8a1a1947b87acfa65206a | Complete; BUILD + REVIEW geometria PASS |
| T04 | eab3dab56e81fc1219080c0e574505b470f8aaba | PARTIAL; painel/recorte/hit-through/cleanup PASS, modos individuais NOT-RUN |
| T05 | 7861676556bbc80aacec7d0f1a198e8de5d7289d | PARTIAL; BUILD/REVIEW/Esc CUA PASS, foco externo e teclado fechado NOT-RUN |
| T06 | ce3c7d016925ed3ea9a999189e17abc4e46de979 | Prepared; BUILD/REVIEW visual PASS; dependências parciais |
| T07 | 5fe9ecb6e64aecc435d017e82e603bbf9d12826a | PARTIAL; BUILD/REVIEW/estados finais CUA PASS; reversão/hit em movimento e modo reduzido NOT-RUN |

Evidências por tarefa em `docs/evidence/T01.md` a `T07.md`; complementos de T04 após seu commit estão identificados. Root recebeu do usuário “Abri configurações e encerrei normalmente” para T02 e “Recorte e cliques funcionam; acesso ao Radar preservado” para T04. São relatos humanos, não observações do agente. O segundo relato não discrimina Spaces/fullscreen/Stage Manager: suporte por modo permanece sem qualificação.

## Entrega e interfaces

- `Radar.xcodeproj`, target/scheme `Radar`, um app SwiftUI/AppKit, nenhum target de testes, nenhuma dependência. `RadarApp` fornece menu/configurações/encerrar; `RadarAppDelegate` cria uma instância do painel e invalida no encerramento.
- `ScreenGeometryResolver.resolve() -> ScreenGeometry?` usa NSScreen real, prefere tela com notch e limita frames aos bounds. `ScreenGeometry` expõe `compactFrame(wingWidth:height:) -> NSRect?`, `expandedFrame(preferredSize:) -> NSRect`, `cameraFrame` em coordenadas globais AppKit. Sem notch, compacto fica oculto e menu abre o painel. Mudança dinâmica de display pertence a T38; geometria atual é imutável.
- `NotchPanelController(geometry:)` é MainActor. Interface: `panel`, `phase` somente leitura (`compact/opening/expanded/closing`), `isExpanded` verdadeiro em opening/expanded; `toggle()`, `showExpanded()`, `showCompact()`, `dismiss(reason:)`, `invalidate()`. `showCompact` cancela transição e interação imediatamente; abertura explícita concede key; `dismiss` trata foco antes de animar. `invalidate` limpa timer, monitores, callbacks, conteúdo e janela.
- `PanelDismissalReason`: explicitToggle/escape podem restaurar app anterior; outsideClick/externalDestination/termination preservam destino. Consumidor de link deve usar `.externalDestination`. Não há monitor global de teclas. `PanelInteractionController` possui somente monitores de mouse transitórios; callbacks síncronos main e remoção antes de resignKey evitam reentrada.
- `PresentationMotionPolicy.current` lê a preferência real. Normal250ms; reduzido120ms de fade do conteúdo ao abrir com frame discreto; fechamento reduzido imediato. `NotchFrameAnimator.animate(duration:update:completion:)` recebe callbacks MainActor, usa uptime monotônico e Timer transitório RunLoop.main/common; `cancel()` invalida timer/geração. Não chamar com duração externa não positiva; atuais consumidores usam constantes internas. Não é scheduler de rede.
- `NotchPanelRootView` recebe alvo `isExpanded`, presença `showsContent`, opacidade atual, câmera local e ações. Câmera é convertida do frame global a cada quadro; clip even-odd comum mantém vazio real. Durante closing o conteúdo não recebe hit/AX, indicadores permitem reversão.
- `RadarTheme` concentra tokens V3; `SourceBrandMark` preserva a marca GitHub oficial branca, proporção e acento violeta separado conforme AD-014. Procedência/hashes em `docs/assets/README.md`. Views contêm somente estado desconectado genuíno. Não há rows, snapshots ou providers artificiais.

## Ambiente e reprodução

Mac27.0.1(26A434), arm64; Xcode27.1(27A9275), Swift6.4, SDK27.0. Um display1470×956pt @2, notch derivado179×32pt, 60Hz. Metadado Reduzir Movimento=false observado em T07, não alterado pelo agente.

Executar da raiz: `./script/build_and_run.sh --verify`. Build Debug e processo próprio foram verificados; interação continua gate separado. Bundle: `/Users/pedronazarito/Developer/Radar/.build/DerivedData/Build/Products/Debug/Radar.app`. O script encerra somente executáveis cujo caminho coincide com esse bundle; não encerra homônimos.

Bundle `dev.pedronazarito.Radar`, LSUIElement, macOS27, ad-hoc, sem App Sandbox, Hardened Runtime efetivo via `--options runtime`. `ENABLE_DEBUG_DYLIB=NO` mantém library validation sem entitlement de exceção; a relação com o primeiro processo instável foi hipótese delimitada, sem leitura de logs. T02 contém assinatura/metadados reais. Distribuição/notarização não executadas/autorizadas. Ad-hoc pode exigir consentimento Keychain novo após rebuild; só o usuário observa no fluxo futuro.

## Contratos e bloqueios para o próximo lote

Preservar C1 e refinamentos C1.1/C1.2, publicados antes de consumidores; AD-009 a AD-014 estão em STATE. Nenhuma implementação de provider foi antecipada. gh2.96.0 arm64 existe em `/opt/homebrew/bin/gh`, mas auth/Finder/dados não foram qualificados. Política/método/site/projetos/repos Jira/GitHub continuam entrada pendente conforme prontidão; não consultar credenciais para completá-la.

Roteiro humano pendente: foco ao clicar em outro app e digitar com Radar fechado (T05); interrupção/reversão e clique durante transição; Reduzir Movimento ativado diretamente pelo usuário e comparado (T07). Modos específicos disponíveis devem ser identificados sem alterar configuração global pelo agente (T04/T38). Nenhum desses gates é dispensado. Destino externo, seleção/detalhe, 30 ciclos/métricas e VoiceOver pertencem a consumidores/gates futuros.

Não criar testes/mocks/fixtures/harness/sensor. Testes, lint externo e sensor NOT-RUN. Não houve leitura de auth/credenciais/Keychain/logs/bancos/históricos; não houve instalação, remote, publicação ou mudança global. Evidência atual não equivale a V1 integrada ou aceite final.
