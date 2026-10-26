# Handoff — GitHub nativo

## Pedido e limite

Em 24/10/2026 o usuário rejeitou o uso de gh/caminho e digitação de repos, pedindo a experiência mais amigável possível com listagem. AD-018 e G1 substituem esse trecho do escopo anterior. Jira, V3, consulta de trabalho somente leitura, execução local e ausência de testes/mocks permanecem.

No início de G02/G03, o usuário ainda não tinha GitHub App e pediu orientação após a implementação. Essa situação é histórica: G04 criou o registro próprio privado após confirmação específica e o usuário confirmou a instalação. Segredos/arquivos de auth não foram lidos; o Radar não foi publicado.

## Coordenação

Root publicou G1 em 7dd8c45. github_onboarding_review e github_auth_research herdaram contexto e conversaram sobre os contratos. Durante G02, root transferiu a escrita exclusiva de código a github_onboarding_review e escreveu apenas documentação. github_native_verifier iniciou com contexto fresco para revisão independente, sem executar contas/UI/build. Em G04, root retomou escrita exclusiva, preparou/enviou o cadastro confirmado, configurou os dois valores públicos e recompilou; o revisor permaneceu readonly.

## Estado

G02 preparado em **5aaf302**, builds Debug/Release finais e revisão independente fresca G1.1–G1.7 PASS no limite estático. [G03](../evidence/G03.md) preserva a passagem histórica sem cadastro. **G04/859b273** confirmou cadastro/configuração/instalação e Conectar habilitado. [G05](../evidence/G05.md) observou autorização pessoal, catálogo de 68, busca local, escolha explícita e consulta GitHub recebida com total 0. Renovação/retomada/remoção, PRs preenchidos e demais gates da V1 continuam pendentes; V1 não aceita.

O verificador confirmou que os 103 arquivos commitados G02 de Radar/Radar.xcodeproj tinham o mesmo fingerprint revisado: `554c7994d585404e159d702abdadd67d88f612e9e572bda591d59fc504dcce2c`. Esse Release sem configuração é histórico. G04 adicionou somente Client ID/slug públicos no pbxproj; fonte Swift intacta, revisão estreita PASS e Debug/Release recompilados sem diagnóstico. Release vigente em `.build/DerivedData/Build/Products/Release/Radar.app`, executável SHA-256 `a560dfefbbc8d64f893c908acba43f24f0d902b053950dcd1685a487f13e1494`, fingerprint configurado `5610736291c23f827b059936b06ead52ba405cf5078e2a1d82a9910f8c489f45`. UI confirmou Conectar habilitado. Evidência [G04](../evidence/G04.md).

## Próximo gate externo

A primeira conexão e consulta já ocorreram em G05; não exigir novo cadastro ou cópia de IDs. Continuar somente os gates ainda pendentes: Jira conforme política/escopo reais, PRs/detalhes/relações existentes, retomada/renovação/remoção e cenários condicionais/hardware. Não fabricar dados, forçar rate limit ou desconectar a sessão recém-aberta só para completar roteiro. Agente não lê/captura desafio, credencial ou store real. Preferências antigas do gh são históricas.

Enquanto não houver App cadastrado, o formulário deve indicar indisponibilidade honestamente. Não usar ID de terceiro, criar dados artificiais, inspecionar token nem provocar rate limit para contornar o impedimento.
