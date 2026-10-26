# Handoff — GitHub nativo

## Pedido e limite

Em 24/10/2026 o usuário rejeitou o uso de gh/caminho e digitação de repos, pedindo a experiência mais amigável possível com listagem. AD-018 e G1 substituem esse trecho do escopo anterior. Jira, V3, consulta de trabalho somente leitura, execução local e ausência de testes/mocks permanecem.

O usuário confirmou que não tem GitHub App cadastrado e pediu orientação após a implementação. Não foi cadastrado/publicado/instalado App por agentes; não foram lidos segredos ou arquivos de auth.

## Coordenação

Root publicou G1 em 7dd8c45. github_onboarding_review e github_auth_research herdaram contexto e conversaram sobre os contratos. Depois, root transferiu a escrita exclusiva de código a github_onboarding_review; root escreveu apenas documentação. github_native_verifier iniciou com contexto fresco para revisão independente, sem executar contas/UI/build.

## Estado

G02 preparado em **5aaf302**, builds Debug/Release finais e revisão independente fresca G1.1–G1.7 PASS no limite estático. Root retomou ownership sem alterar código e qualificou metadados, assinatura e UI real desconectada, quit/reabertura normal. [G03](../evidence/G03.md) é **PARTIAL**: cadastro/configuração e gates autenticados obrigatórios continuam NOT-RUN; V1 não aceita.

O verificador confirmou que os 103 arquivos commitados G02 de Radar/Radar.xcodeproj tinham o mesmo fingerprint revisado: `554c7994d585404e159d702abdadd67d88f612e9e572bda591d59fc504dcce2c`. Esse Release sem configuração é histórico. G04 adicionou somente Client ID/slug públicos no pbxproj; fonte Swift intacta, revisão estreita PASS e Debug/Release recompilados sem diagnóstico. Release vigente em `.build/DerivedData/Build/Products/Release/Radar.app`, executável SHA-256 `a560dfefbbc8d64f893c908acba43f24f0d902b053950dcd1685a487f13e1494`, fingerprint configurado `5610736291c23f827b059936b06ead52ba405cf5078e2a1d82a9910f8c489f45`. UI confirmou Conectar habilitado. Evidência [G04](../evidence/G04.md).

## Próximo gate externo

Continuar [ativação assistida](../github-setup.md): usuário já confirmou identidade, cadastro específico e instalação nos repos escolhidos; root coletou somente dados públicos e configurou o build. No Radar, usuário aciona Conectar → Copiar código e abrir GitHub e autoriza pessoalmente. Aguardar relato de catálogo/impedimento antes de observar o app; não ler/capturar o desafio ou qualquer segredo. Depois conferir catálogo/seleção/PRs e demais G1.1–G1.7, sem dados artificiais. Não exigir cópia de IDs/guia técnico. Preferências antigas do gh são históricas; nenhum PASS antigo substitui OAuth, renovação ou cofre reais.

Enquanto não houver App cadastrado, o formulário deve indicar indisponibilidade honestamente. Não usar ID de terceiro, criar dados artificiais, inspecionar token nem provocar rate limit para contornar o impedimento.
