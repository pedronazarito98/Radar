# Regras do Radar

Atue como um engenheiro sênior criterioso. Antes de alterar código, leia a estrutura, estas regras e .specs/STATE.md, spec.md, context.md, design.md, tasks.md, coordination.md e verification-plan.md da feature radar. Preserve padrões existentes e comportamento; não invente arquitetura sem necessidade.

- Um único escritor de código por vez; subagentes de investigação somente leitura, contexto explicitamente compartilhado, comunicação entre pares e revisão independente com contexto fresco.
- Execute tarefas com gate real, evidência sanitizada, commit atômico e handoff. Gate obrigatório NOT-RUN não conclui tarefa.
- Não criar testes, arquivos de teste, mocks, fixtures de negócio ou sensor de mutação sem pedido explícito.
- Não usar barrel exports nem criar index.ts/index.tsx de reexportação; importar arquivos diretamente.
- Não usar React.FC ou adicionar "use client" sem necessidade. Se TypeScript for necessário, usar tipagem clara e segura e evitar any. A stack aprovada para esta V1 é Swift nativo com tipos seguros.
- Separar componentes, subcomponentes, estilos, tipos, hooks, constantes, utilitários e lógica quando fizer sentido; evitar regra de negócio complexa em JSX ou views.
- Código simples, modular, legível, escalável e fácil de revisar; sem duplicação, arquivos gigantes ou nomes genéricos. Não adicionar dependências nem mudar arquivos fora do escopo sem necessidade justificada.
- Preservar design system, tokens e identidade Radar V3: preto, duas colunas, seleção cinza, faixa inferior, sem borda esquerda colorida. Considerar light/dark mode quando aplicável.
- Skills são lidas sob demanda; nunca carregar todas no bootstrap.
- Não ler/copiar credenciais, sessões, arquivos de auth, logs, SQLite, paste cache ou históricos brutos. Se um segredo aparecer incidentalmente, registrar somente [REDACTED]. Nunca expor tokens nem consultar Keychain como agente.
- Jira token é informado pelo usuário diretamente no fluxo seguro do app, condicionado à política da conta. Nunca pedir no chat. Não executar gh auth token/status/login/refresh/switch nem abrir seus arquivos de auth/configuração.
- Escopo pessoal: Jira Cloud + GitHub.com. O pedido de 24/10/2026 substitui gh por autenticação nativa e seletor de repositórios, conforme .specs/features/radar/github-onboarding.md. O pedido de 26/10/2026 autoriza criar o repositório privado pedronazarito98/Radar, configurar origin local e fazer push da fonte após revisão de segurança (AD-019). Não publicar releases/app, instalar ferramentas ou alterar configurações globais. Nenhuma escrita de trabalho remota (merge/aprovação/comentário/transição).
- Commits em primeira pessoa, claros e objetivos em pt-BR, descrevendo o que fiz, impacto e como validar de verdade.
- O pedido de 27/10/2026 autoriza empacotar e publicar um DMG pessoal em Release do mesmo repositório privado para outro Mac sem Xcode (AD-020). Essa autorização supera o limite anterior de releases somente nessa entrega; não autoriza tornar o repo público, instalar ferramentas, acessar identidades/segredos do Keychain, notarizar ou alterar proteções/configurações globais.
- O pedido posterior de 27/10/2026 autoriza tornar pedronazarito98/Radar público para avaliação do TI (AD-021), incluindo fonte/histórico e a Release existente. Prevalece sobre o limite privado de AD-019/020. Não autoriza alterar a visibilidade/permissões do GitHub App, instalar em organizações, conceder acesso corporativo, mudar proteções do Mac ou enviar mensagens ao TI.
- Ao finalizar: resumo, arquivos alterados/criados, decisões técnicas, pontos de atenção e validação manual. Não inventar testes/lint/build; informar o que não rodou.
