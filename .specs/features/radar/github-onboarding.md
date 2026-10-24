# GitHub nativo — revisão de escopo G01

Pedido de 24/10/2026: substituir a dependência do gh e entrada manual de owner/repo por autenticação amigável e lista selecionável. Esta revisão prevalece sobre os trechos anteriores de gh em spec/design/context/tasks/verification-plan e sobre seus resultados históricos. Não altera Jira, V3, consulta de trabalho somente GET ou limites de publicação/instalação/global.

## Contrato G1

- GitHub App próprio, device flow oficial. Client ID público e slug são configuração de build; nenhum client secret/chave privada no binário ou campos técnicos na UI.
- Autorização no navegador com código curto, ação explícita de copiar/abrir, cancelamento e expiração. Poll respeita interval/slow_down; erros são traduzidos sem guardar respostas brutas.
- Tokens de acesso/renovação ficam somente no adapter e Keychain próprio, com referência persistida antes da gravação. Refresh de token originalmente emitido por device flow dispensa client secret. Startup não lê Keychain; Retomar é ação explícita. Desconectar remove somente credencial própria; sair limpa memória e preserva sessão salva.
- Operações OAuth POST limitadas aos endpoints oficiais, sem confundir com mutação de trabalho. Consultas GET via api.github.com, sessão efêmera, sem cache/cookies/credentialStorage, redirects recusados, cap 5 MiB e timeout 15 s. Conservam lease/budget/backoff, identidades inicial/final, contexto/geração/head e descarte tardio.
- Catálogo por /user/installations e /user/installations/{id}/repositories, paginado, deduplicado por ID. Apenas repositórios acessíveis à interseção usuário/App. Instalação/permissão da organização ocorre no GitHub pelo usuário; nunca ampliar silenciosamente.
- Busca local sobre repositórios carregados, checkbox, público/privado, contagem de seleção (1–10), carregar mais e falha/parcial explícitos. Autenticação não ativa escopo anterior automaticamente. Aplicar valida escolhas no catálogo da mesma sessão e cria novo connectionID/escopo.
- Client ID ausente deixa conexão indisponível com texto honesto; não fabricar cadastro, repos, dados, sucesso ou executar auth como agente.

## Tarefas e gates

1. G01: publicar contrato e migração de escopo; root único escritor, consultores readonly github_onboarding_review e github_auth_research com contexto herdado e comunicação direta.
2. G02: implementar auth/refresh/cofre/HTTP nativo, migrar consumidores mantendo contratos, catálogo e formulário. BUILD Debug/Release + revisão independente fresca. Sem testes/mocks.
3. G03: qualificar UI desconectada/bundle, documentar cadastro e gates de conta. LIVE auth/poll/refresh/cofre/repos/PRs só após configuração e interação do usuário. NOT-RUN não é PASS.

## Novos critérios (substituem R09, R16.1, R20.2 e parte GitHub de R19)

- G1.1: Conectar não exige CLI, caminho, token colado ou nome de repo digitado; navegação limitada ao GitHub oficial.
- G1.2: Cancelar/expirar/recusar não conecta nem publica retorno tardio; interval/slow_down/retry não disparam loops sem limite.
- G1.3: Segredos somente no adapter/cofre próprio; refresh serializado/rotacionado, sem secret embarcado; startup metadata-only.
- G1.4: Listar instalações/repos com paginação explícita; falha não vira vazio completo; busca deixa claro que filtra somente o carregado.
- G1.5: Aplicar 1–10 escolhas verificadas ativa somente esse escopo; mudança de conta/seleção invalida dados e contexto antigos.
- G1.6: Sair mantém sessão salva sem autoacesso; desconectar invalida memória e remove somente item próprio, com retry se remoção falhar.
- G1.7: Falhas reais, permissões org e registro ausente têm ação compreensível; nenhuma alegação LIVE por build/review.

## Fontes oficiais

- https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app
- https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/refreshing-user-access-tokens
- https://docs.github.com/en/rest/apps/installations#list-app-installations-accessible-to-the-user-access-token
- https://docs.github.com/en/rest/apps/installations#list-repositories-accessible-to-the-user-access-token

O usuário confirmou que ainda não possui cadastro e pediu orientação depois da implementação. Registro, instalação e aprovação ficam pendentes; nenhum ID de terceiro será reutilizado.
