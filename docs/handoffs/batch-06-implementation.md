# Handoff — lote6 / implementação T36–T38

Base recebida 6795dc3, handoff05 e C1–C1.11 preservados. native_finish_readiness foi o único escritor; native_final_review fez revisão independente de cada diff estável. Entregas locais preparadas sob AD-013; contas e gates obrigatórios de runtime não foram substituídos por build/review.

| Tarefa | Commit | Gate observado |
| --- | --- | --- |
| T36 — composição | d3f95f7 | BUILD Debug e REVIEW independente PASS; UI-integrada/LIVE NOT-RUN |
| T37 — navegação | d9ed688 | BUILD Debug e REVIEW independente PASS; links/cópia/foco reais NOT-RUN |
| T38 — display | 5d98465 | BUILD Debug e REVIEW independente PASS; UI-display/modos reais NOT-RUN |

Cada build real usou `./script/build_and_run.sh --build-only`, exit0, sem iniciar/encerrar o app. T37 teve erro intermediário de ordem de argumentos de init SwiftUI, corrigido antes do build final PASS. O build de T38 inclui todo o código final. Diffcheck PASS em cada etapa; não criamos/executamos testes, mocks, fixtures, sensor ou lint. Nenhuma conta/API/auth/cofre, conteúdo de clipboard ou arquivo real de preferências foi acessado pelo autor/revisor.

## APIs e ownership

- AppComposition é o ponto único do grafo. RadarAppDelegate apenas chama start/stop; RadarApp fornece as mesmas instâncias às configurações. DataLifecycleController, SourceRefreshCoordinator e RelatedItemsCoordinator mantêm seus papéis anteriores, inclusive configurationID para reconnect coalescido. Não duplicar observers de sleep/wake ou scheduler.
- NavigationCoordinator é ponte AppKit estreita para intenção explícita. open/copyLink aceitam SelectionKey apresentada e autorizada. Validação Jira usa currentConnection de metadata em memória, host exato do site e provenance; GitHub é github.com com repo/connectionID vigentes. Guarda de geração/seleção após await rejeita ação tardia. Pasteboard somente escrita explícita; nenhuma leitura.
- RadarFocusCoordinator inclui openDestination/copyDestination para seleção e relações. Esc, origem pessoal, aliases e refreshDetails permanecem. DetailsStripView usa ícones com labels/help/foco; teclado real e VoiceOver não foram observados.
- DisplayPolicyController observa displays/Space/preferência e atualiza availableDisplays. Settings recebe esse controller; Picker conserva a opção salva indisponível. Não regrava preferência durante fallback.
- AppComposition.applyGeometry cria painel só na primeira tela disponível. NotchPanelController.updateGeometry altera o mesmo painel e cancela a animação velha. Tela disponível preserva estado/seleção sem ativação; ausência total cancela interação/detalhe, limpa seleção e oculta até voltar. Menu chama togglePanel, recalculando geometria antes da intenção explícita.
- Flags existentes canJoinAllSpaces/fullScreenAuxiliary/stationary não certificam suporte universal. No monitor sem notch o compacto é oculto, com abertura pelo menu. Hardware/escala/resolução/Spaces/fullscreen/Stage Manager exigem evidência própria.

## Próxima execução — root T39–T42

1. Incorporar evidência root da cópia imutável T35 (preferências gh pelo app/quit/reabertura) separada destes gates; não atribuir essa UI ao writer.
2. Qualificar UI final sem duplicar instâncias; dados reais somente quando disponíveis/autorizados, sem seed. T36/T37 integrados continuam NOT-RUN sem contas/recursos.
3. T39: 30 ciclos reais com seleção quando houver itens; observar interrupção/repouso e medir recursos do processo pelo caminho exato. Sem dados, abrir/fechar não comprova seleção. Nenhum script de simulação/sensor novo.
4. T40: comparar V3, teclado/VoiceOver/Reduzir Movimento e modos disponíveis. Review de fonte não comprova movimento ou foco físico.
5. T41: gerar Release existente com xcodebuild e conferir metadados públicos do próprio artefato. O script atual fixa Debug; não alterei sua interface.
6. T42: consolidar cada critério/gate e disparar verificação fresca. NOT-RUN obrigatório impede aceite integral; publicação/notarização/instalação limpa/Enterprise continuam fora da entrega local.

Comando preparado para o root, não executado neste lote:

```sh
/usr/bin/xcodebuild -quiet -project /Users/pedronazarito/Developer/Radar/Radar.xcodeproj -scheme Radar -configuration Release -destination 'platform=macOS,arch=arm64' -derivedDataPath /Users/pedronazarito/Developer/Radar/.build/DerivedData build
```

Após gerar, somente metadados públicos do bundle próprio: codesign --verify --strict, codesign --display --verbose=4, codesign --display --entitlements - e plutil do Contents/Info.plist. Flags de runtime reais devem vir desse artefato: o build pode emitir nota sobre ad-hoc apesar de OTHER_CODE_SIGN_FLAGS; não inferir resultado do setting. Root já qualificou flags adhoc,runtime na cópia T35, o que não substitui Release.

## Liberação

Após o commit deste documento e manifesto, native_finish_readiness encerra as alterações e libera explicitamente ownership ao root. T39–T42 não foram executados por este escritor. Estado final e arquivos limpos são conferidos no handoff por mensagem. Nenhum processo do Radar foi iniciado por este escritor.
