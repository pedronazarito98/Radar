# T41 — Bundle pessoal Release

**PARTIAL: BUILD, assinatura e launch/UI sem contas PASS.** Uso autenticado de Jira/GitHub pelo Release permanece NOT-RUN e impede aceite integral. Não há publicação/notarização/instalação de ferramentas/configuração global.

## Artefato

`/Users/pedronazarito/Developer/Radar/.build/DerivedData/Build/Products/Release/Radar.app`

Código T38 `5d98465` + correção C08 `45cafdd`; fontes Swift não mudaram após a revisão T38. Executável SHA-256 `c89e2634a81d942b5af4b7ae9268acf26d08ea722f3b38d3664d3e56d6e23475`. Não confundir com a cópia Debug T35 usada no complemento de persistência.

**Atualização após verificação final:** o artefato inicial acima foi substituído pela correção C09 `299514b`. O executável vigente tem SHA-256 `e479390fcbc42043ec45f29c782f3cc07ed4266c0db2cd884c8d6b9f619bd984`; builds Debug/Release, codesign strict, flags ad-hoc/runtime e ausência de entitlements foram reconfirmados. Root encerrou a versão anterior pela UI antes da substituição e abriu o novo Release pelo caminho completo. Startup compacto/desconectado, preferência Automática/caminho gh preservados e Validar gh2.96.0 sem auth foram observados novamente. Abaixo fica preservada a execução original T41; a nova linha de solicitação direta continua LIVE NOT-RUN. Ver [C09](C09.md) e [verificação final](final-verification.md).

## BUILD e metadados efetivos

Em 23/10/2026, o comando abaixo terminou exit0, inclusive depois de C08:

```sh
/usr/bin/xcodebuild -quiet -project /Users/pedronazarito/Developer/Radar/Radar.xcodeproj -scheme Radar -configuration Release -destination 'platform=macOS,arch=arm64' -derivedDataPath /Users/pedronazarito/Developer/Radar/.build/DerivedData build
```

| Campo | Observado no bundle próprio |
| --- | --- |
| Target / arquitetura | Radar / Mach-O thin arm64 |
| Sistema alvo / SDK | mínimo macOS27.0 / macosx27.0, build26A425 |
| Toolchain | Xcode27.1 build27A9275; Swift6 strict configurado |
| Bundle | dev.pedronazarito.Radar, 0.1.0 (1), LSUIElement=true |
| Assinatura | ad-hoc, TeamIdentifier não definido |
| Hardened Runtime | CodeDirectory flags0x10002(adhoc,runtime), RuntimeVersion27.0.0 |
| Entitlements | codesign exit0 sem dicionário/chaves; sem App Sandbox e sem get-task-allow após C08 |
| Verificação | codesign --verify --strict: valid on disk / satisfies its Designated Requirement |

`plutil -p` leu somente Info.plist público do artefato. A inspeção independente C08 confirmou configuração/assinatura. O primeiro build continha permissão de depuração; foi corrigido e reconstruído antes da execução descrita abaixo. Os settings do projeto, isoladamente, não foram tratados como evidência da assinatura.

## MANUAL via CUA no Release

1. Encerrar Debug pela UI; ausência de processo Radar confirmada. Abrir Release pelo caminho completo usando CUA; `ps` confirmou PID77257 nesse executável, sem instância Debug/T35 concomitante.
2. Inicialização compacta com Jira/GitHub desconectados e total desconhecido. Abrir Ajustes pelo menu; caminho gh persistido foi restaurado. Validar gh exibiu “gh 2.96.0 validado. A autenticação ainda não foi consultada.”.
3. Em Preferências, escolher Tela Retina Integrada no seletor do próprio app, encerrar e confirmar ausência do processo. Reabrir Release compacto/desconectado; Ajustes restaurou Tela Retina Integrada. Voltar para Automática — priorizar notch e confirmar o valor na UI. Não houve mudança de monitor/resolução/escala ou preferência global.
4. Fechar Ajustes, abrir pelo indicador Jira e recolher com Escape; estados confirmados por AX. Release deixado aberto e recolhido para a validação humana. A escolha local na mesma tela não qualifica hotplug, multi-display ou mudanças físicas de display.

Nenhum arquivo real de preferências foi aberto pelo agente. A gravação ocorreu pelas ações explícitas do app. Não foi clicado Conectar, inserido token, consultado provider ou acessado Keychain. Categorias/contas/negócio real e auth do gh são NOT-RUN. A observação de `--version` não comprova autenticação.

## Limites

O launch pelo caminho completo cumpre somente a alternativa local desse gate; não foi alegado um clique no Finder. Gatekeeper em máquina limpa, Developer ID, notarização, Mac App Store, auto-update e Enterprise não foram executados nem fazem parte da entrega autorizada. Testes/mocks/sensores/Swift lint não executados. O usuário recebeu roteiro de observação física e acessibilidade; respostas serão registradas separadamente, sem inferência por silêncio.
