# Handoff — GitHub nativo

## Pedido e limite

Em 24/10/2026 o usuário rejeitou o uso de gh/caminho e digitação de repos, pedindo a experiência mais amigável possível com listagem. AD-018 e G1 substituem esse trecho do escopo anterior. Jira, V3, consulta de trabalho somente leitura, execução local e ausência de testes/mocks permanecem.

O usuário confirmou que não tem GitHub App cadastrado e pediu orientação após a implementação. Não foi cadastrado/publicado/instalado App por agentes; não foram lidos segredos ou arquivos de auth.

## Coordenação

Root publicou G1 em 7dd8c45. github_onboarding_review e github_auth_research herdaram contexto e conversaram sobre os contratos. Depois, root transferiu a escrita exclusiva de código a github_onboarding_review; root escreveu apenas documentação. github_native_verifier iniciou com contexto fresco para revisão independente, sem executar contas/UI/build.

## Estado

G02 preparado em **5aaf302**, builds Debug/Release finais e revisão independente fresca G1.1–G1.7 PASS no limite estático. Root retomou ownership sem alterar código e qualificou metadados, assinatura e UI real desconectada, quit/reabertura normal. [G03](../evidence/G03.md) é **PARTIAL**: cadastro/configuração e gates autenticados obrigatórios continuam NOT-RUN; V1 não aceita.

O verificador confirmou que os 103 arquivos commitados de Radar/Radar.xcodeproj têm o mesmo fingerprint revisado: `554c7994d585404e159d702abdadd67d88f612e9e572bda591d59fc504dcce2c`. Release em `.build/DerivedData/Build/Products/Release/Radar.app`, executável SHA-256 `2df75d3fcabdd6a04b78c61ad40e1dcf367ae44181793260d8aad829de52871c`. Configuração pública vazia; formulário GitHub deixado aberto para o usuário. Nenhuma implementação independente restante identificada.

## Próximo gate externo

Executar [ativação assistida](../github-setup.md): root prepara cadastro/opções; usuário confirma identidade, criação e permissões no GitHub. Root coleta somente Client ID/endereço públicos na UI, configura o build e acompanha G1.1–G1.7. Não exigir cópia de IDs/guia técnico pelo usuário. Em G04 a aba oficial parou em Confirm access, aguardando autenticação pessoal antes do formulário. Nenhum cadastro ou concessão foi executado. Preferências antigas do gh são históricas; nenhum PASS antigo substitui OAuth, renovação, catálogo ou cofre reais.

Enquanto não houver App cadastrado, o formulário deve indicar indisponibilidade honestamente. Não usar ID de terceiro, criar dados artificiais, inspecionar token nem provocar rate limit para contornar o impedimento.
