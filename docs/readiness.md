# Prontidão local — T01

Data: 22/10/2026. Destino: /Users/pedronazarito/Developer/Radar. Origem preservada: pacote plano-implementacao-radar em Documents/Codex/2026-10-22/reverse-engineer-anything-users-pedronazarito-agents/outputs. AGENTS da conversa copiado com limites do prompt; nenhum AGENTS ancestral encontrado. Diretório inexistente antes desta tarefa; nenhum Git ancestral, código ou mudança anterior.

| Item | Evidência pública observada | Limite |
|---|---|---|
| macOS | 27.0.1 (26A434), arm64 | Mac atual apenas |
| Xcode selecionado | /Applications/Xcode.app/Contents/Developer; 27.1 (27A9275) | Nenhuma seleção global alterada |
| Swift / SDK | Swift 6.4; target arm64-apple-macosx27.0.0; SDK macOS 27.0 | Build do app começa T02 |
| First launch | xcodebuild -checkFirstLaunchStatus exit 0 | Nenhuma instalação |
| Tela | 1470×956 pt, scale 2, safeTop 32, 60 Hz; auxiliares x0..645.5 e x824.5..1470, altura32 | Uma tela; câmera derivada 179 pt; não é dimensão fixa de produto |
| Acessibilidade | reduceMotion=false observado por API pública | Não foi mudada configuração global |
| gh | /opt/homebrew/bin/gh, 2.96.0 (2026-07-02), Mach-O arm64; --version/help exit 0 | Auth e Finder NOT-RUN |
| Capacidades CLI | api --help: --method GET, --hostname, --include; code4 auth-required, code1 genérico | Sem chamadas de dados/auth |
| Jira | Cloud, token pessoal direto no app; gateway scoped e site legado qualificados documentalmente | Política, site/cloudID/projetos/token e conexão real pendentes |
| Colaboração | 4 slots reais; root+writer+2 consultores, pares comunicam diretamente | Um escritor, verificador final fresco |

Evidência de ambiente veio das ferramentas públicas executadas nesta sessão pelos especialistas native_readiness e providers_readiness; nenhum dado de auth/Keychain foi lido. REA anterior é somente inventário/plist e não prova runtime; não houve nova investigação nem execução de terceiro.

## Configuração adotada

Target Xcode Radar, bundle ID dev.pedronazarito.Radar, macOS 27, Swift estrito; SwiftUI/AppKit e frameworks nativos. Assinatura ad-hoc local (`CODE_SIGN_IDENTITY=-`), `ENABLE_APP_SANDBOX=NO`, `ENABLE_HARDENED_RUNTIME=YES`. A assinatura efetiva e os entitlements serão conferidos no bundle próprio T02/T41; nenhuma identidade de Keychain é consultada. Reconsentimento Keychain após rebuild continua observação futura do usuário.

C1.1: ambiente do gh construído do zero conforme design/AD-011. Execução sem shell, sem gh auth, sem leitura de configuração, sem instalação. Escopos concretos dependem do usuário; credencial Jira nunca entra em chat/documentos.

## Gates

T01 DOC: fonte canônica, decisões, 42 tarefas/56 critérios, dependências e limites conferidos. Build command e scheme reais PENDING até T02; não executar placeholders. Depois de criar o target, descobrir com `xcodebuild -list -project Radar.xcodeproj` e registrar comando real.

Sem lint externo instalado. Testes/mocks/sensor: NOT-RUN por política, não criados. Runtime/Finder/contas/performance/VoiceOver/Reduzir Movimento permanecem NOT-RUN até suas tarefas. Sem remotes, publicação, instalação ou configuração global.

C1.2 publicado pelo root antes dos consumidores: versão GitHub 2026-03-10 e DTO mínimo; token/gateway Jira explícito e paginação/completude qualificada, com fontes em design.md. Nenhuma chamada autenticada executada.
