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
- Escopo local pessoal: Jira Cloud + GitHub.com. O pedido de 24/10/2026 substitui gh por autenticação nativa e seletor de repositórios, conforme .specs/features/radar/github-onboarding.md. Não publicar, configurar remotes, instalar ferramentas ou alterar configurações globais. Nenhuma escrita de trabalho remota (merge/aprovação/comentário/transição).
- Commits em primeira pessoa, claros e objetivos em pt-BR, descrevendo o que fiz, impacto e como validar de verdade.
- Ao finalizar: resumo, arquivos alterados/criados, decisões técnicas, pontos de atenção e validação manual. Não inventar testes/lint/build; informar o que não rodou.
