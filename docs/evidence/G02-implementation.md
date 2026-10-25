# G02 — GitHub nativo e seleção de repositórios

Data: 24/10/2026. Contrato [G1](../../.specs/features/radar/github-onboarding.md), publicado em G01/7dd8c45. Escritor único: github_onboarding_review, ownership transferido explicitamente por root. Root manteve documentos/guia; github_auth_research compartilhou evidência oficial; github_native_verifier recebeu contexto fresco para revisão independente.

## Implementação

- Substituí gh/Process por HTTP nativo com GitHub App device flow. Client ID e slug são parâmetros públicos de build (`RADAR_GITHUB_CLIENT_ID`, `RADAR_GITHUB_APP_SLUG`), ambos vazios por padrão, interpolados no Info.plist. Nenhum client secret, chave privada ou ID de terceiros.
- Formulário oferece Conectar, código curto, Copiar código e abrir GitHub, Cancelar, Retomar, lista com busca/checkbox/paginação e seleção de 1–10 repos. O usuário não informa caminho, CLI, token ou owner/repo manualmente. Sem configuração pública, Conectar fica indisponível e o formulário explica o impedimento.
- Catálogo usa instalações acessíveis ao token e repositórios de cada instalação. Dedup por ID; valida nomes e identidades; compara totais e IDs por instalação; duplicados, mudanças, truncamento e teto ficam parciais. Busca somente no carregado. Páginas são explícitas; no máximo 10 páginas por endpoint e 5.000 repos em memória.
- Sessão autoriza primeiro; nenhum escopo antigo é ativado automaticamente. Preferências da mesma identidade só pré-marcam repos reencontrados no catálogo, uma única vez por escolha. O CTA confirma identidade e acesso dos selecionados antes de configurar novo connectionID/escopo. Guardas tardias de contexto/seleção/head permanecem nos providers.
- Cofre próprio armazena access/refresh tokens sem exposição à apresentação. Referência UUID durável precede nova gravação. Startup lê somente metadata própria; Retomar lê o item próprio após ação do usuário. Desconectar remove somente esse item e preserva referência para retry se falhar. Shutdown invalida memória sem remover a sessão salva.
- Refresh é serializado pela lease, contabilizado no orçamento, sem client secret; rotação persiste antes de atualizar a sessão. A rotação é limitada e termina persistência mesmo após cancelamento do chamador, desde que a credencial não tenha sido removida. Retomada durante rotação recebe espera explícita; falha definitiva/ambígua invalida memória, 429/503 preservam sessão e cooldown.
- HTTP efêmero sem cache/cookies/credentialStorage; redirects recusados, timeout de até 15 s, cap 5 MiB para GET e 64 KiB para OAuth. POST só nos dois endpoints OAuth oficiais; trabalho permanece GET. Poll respeita interval/slow_down e deadline monotônico de até 15 minutos, com espera limitada à expiração.
- Encerramento normal usa terminateLater: para o trabalho, bloqueia novos fluxos e aguarda somente rotação/gravação/remoção já iniciadas. A espera é assíncrona, com deadline de 30 s; se o macOS ainda aguarda consentimento, recusa a saída e reabre a composição desconectada, preservando o trabalho seguro em curso. Não inicia rede ou cofre ao sair.
- Removi infraestrutura CLI obsoleta. `ghPath` permanece apenas na decodificação compatível de preferências antigas; não executa binários. Novos saves GitHub limpam esse campo.

## Arquivos centrais

- `Radar/Integrations/GitHub/GitHubAppConfiguration.swift`, `GitHubOAuthClient.swift`, `GitHubAuthorizationStore.swift`, `GitHubNetworkTransport.swift`, `GitHubAPITransport.swift`, `GitHubHTTPResponse.swift`, `GitHubEndpoint.swift`, `GitHubRepositoryCatalog.swift`.
- `Radar/Persistence/GitHubCredentialVault.swift`, `PreferencesStore.swift`, `RadarPreferences.swift`.
- `Radar/Application/GitHubConnectionController.swift`, controllers de work/detail/relações/lifecycle e consumidores dos providers.
- `Radar/Presentation/Connections/GitHubConnectionFormView.swift`, `GitHubRepositoryPicker.swift`, mensagens de recuperação e estado vazio.
- `Radar/Resources/Info.plist`, `Radar.xcodeproj/project.pbxproj`, `Radar/App/AppComposition.swift` e `RadarAppDelegate.swift`.

## Gates reais locais

- **BUILD Debug PASS**: `./script/build_and_run.sh --build-only`, última passagem exit 0 sem diagnóstico. Uma primeira passagem emitiu warning de captura implicitamente forte/weak; capture list foi explicitada, e passagem posterior passou sem warning.
- **BUILD Release PASS**: xcodebuild Release/macOS arm64/DerivedData local, exit 0 sem diagnóstico.
- **REVIEW diffcheck PASS**: `git diff --check`, exit 0.
- **Metadados públicos PASS limitado**: Info.plist do Release contém Client ID e slug vazios. SHA-256 do executável desta passagem: `2df75d3fcabdd6a04b78c61ad40e1dcf367ae44181793260d8aad829de52871c`.
- **Revisão independente PASS estático**: github_native_verifier, contexto fresco, confirmou G1.1–G1.7 após correções. A revisão apontou revalidação da sessão após awaits do orçamento e necessidade de drenar rotação/persistência antes de encerrar o processo; ambas foram corrigidas e rechecadas. O delta final de User-Agent e cooldown OAuth também foi revisto. Fingerprint de fonte fornecido pelo revisor: `554c7994d585404e159d702abdadd67d88f612e9e572bda591d59fc504dcce2c`. Revisor não executou build/UI/auth/cofre/runtime.
- **Builds finais pós-revisão**: Debug e Release reais, sequenciais, ambos exit 0 sem diagnósticos. Não houve nova mudança de código após o fingerprint revisado. Root receberá ownership para UI/metadados/commit.

## Limites / próximos gates

Não executei UI/launch, autenticação, consultas de conta, Keychain, listagem de repos ou refresh real nem saída durante rotação real. Cadastro GitHub App e instalação ainda dependem do usuário; não há Client ID/slug real neste build. Não criei testes/mocks/fixtures nem executei lint. Não li logs/auth/credenciais, preferências reais, bancos ou histórico; não instalei ferramentas, publiquei ou alterei configurações globais.

O bundle/configuração ausente só pode comprovar o estado desconectado. Device flow, recusa/expiração real, consentimento Keychain, rotação/persistência/retomada, remoção negada, organizações, permissões, catálogo paginado e PRs continuam **LIVE NOT-RUN**. Ausência de cadastro não pode ser convertida em sucesso funcional. Revisor/owner podem qualificar somente os gates autorizados e registrar limites.
