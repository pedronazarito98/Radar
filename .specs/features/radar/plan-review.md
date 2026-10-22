# Radar — revisão independente do plano

**Data:** 22/10/2026. **Veredito:** **READY-FOR-USER-REVIEW**.  
**Objeto:** coerência e executabilidade do planejamento; nenhum aceite do app ou da implementação.

A revisão foi iniciada com contexto fresco, sem histórico do autor. Li STATE, spec, context, design, tasks, coordination, verification-plan e research; cruzei as referências documentais de outputs e inspecionei a imagem V3 e as pranchas 05/06. As correções documentais recebidas durante a revisão foram relidas antes deste veredito. Apenas este relatório foi criado pelo revisor.

## Achados e resolução independente

Cinco achados foram apresentados ao autor e corrigidos nos documentos. A releitura abaixo verificou o conteúdo efetivo das correções. Não há achado bloqueante de planejamento aberto no snapshot identificado ao final; as prioridades indicam o impacto original.

### F03 — P1 — Identidade autenticada do gh não delimita o lote que pode ser publicado

**Referências atuais:** design.md:203–211; tasks.md:485–491 e 597–605; spec.md:212 e 275; verification-plan.md:57.

**Achado original:** T27 qualificava `/user` antes de três buscas por subprocessos distintos, sem definir nova qualificação ao publicar. Cenário: `/user` qualifica A; o usuário troca externamente para B; um subprocesso seguinte consulta como B; o lote ainda conserva contextID/generation de A. As guardas de seleção/contexto não detectam essa diferença por si mesmas. O cenário indicava uma lacuna de contrato, sem falha de implementação observada.

A [documentação de gh auth switch](https://cli.github.com/manual/gh_auth_switch) confirma que a troca altera a autenticação usada pelos próximos comandos do host. Nesta revisão nenhum comando de auth foi executado.

**Resolução conferida:** cada lote pessoal, de detalhes ou relações é serializado, usa a identidade estável esperada e reserva orçamento para GET `/user` inicial e final. Divergência descarta o lote e invalida a geração/estado incompatível; falha de qualificação final impede publicar dados novos. O limite residual A→B→A externo é explícito, com uma identidade ativa durante a sincronização e requalificação após troca. A V1 não promete auth transacional multi-conta, nem resolve a limitação extraindo tokens ou lendo auth.

**Estado:** resolvido documentalmente. R19.2/R26.2, T27/T35 e U26 refletem detecção nas fronteiras; T35 também deixou de prometer invalidação de uma troca não observável. O limite residual deve permanecer visível na revisão do usuário. Runtime de troca externa continua NOT-RUN se não ocorrer naturalmente.

### F04 — P2 — O commit pode mudar sem mudar a chave de seleção

**Referências atuais:** design.md:181–183 e 201; tasks.md:499–505 e 541–547; spec.md:99–104 e 166–167; verification-plan.md:38 e 45.

**Achado original:** a guarda de contexto/PR/geração de seleção não cobria o mesmo PR recebendo um push. Um enriquecimento para SHA A poderia terminar depois de um snapshot que já conhecesse SHA B, sem A→B de seleção ou troca de conta. “SHA atual” não determinava o tratamento dessa resposta antiga.

**Resolução conferida:** PRDetails agora carrega contexto, PR, selectionGeneration, detailGeneration, headSHA observado e horário. Novo refresh incrementa a geração de detalhe mesmo sem mudar a seleção; checks/statuses usam o SHA capturado e novo head observado invalida a versão anterior. O plano distingue SHA observado de um push ainda desconhecido e não mistura CI antigo com metadados de head novo.

**Estado:** resolvido documentalmente. R07.2, T28 e U07 incluem a rejeição de SHA/geração antigos; T31 conserva a guarda de seleção que consome esse detalhe versionado. Não foi provocado push nem criado teste/mock para decidir o contrato.

### F05 — P2 — CI e revisão têm vocabulário, mas falta um resultado verificável para combinações reais

**Referências atuais:** design.md:185–201; tasks.md:247–253 e 499–505; spec.md:101–104; verification-plan.md:38.

**Achado original:** separar fase, CI e revisão estava correto, mas o vocabulário não determinava combinações como success com pending/failure, neutral/skipped, decisões sucessivas do mesmo revisor, dismissed, revisores discordando e solicitação ao usuário junto de decisão de outra pessoa. Responsabilidade e decisão poderiam ser reduzidas a um único rótulo sem oráculo de revisão.

A [API de reviews](https://docs.github.com/en/rest/pulls/reviews#list-reviews-for-a-pull-request) fornece eventos em ordem cronológica, com estado e commit; não entrega por si só a síntese de produto proposta. A [API de check runs](https://docs.github.com/en/rest/checks/runs#list-check-runs-for-a-git-reference) também oferece paginação e seleção de runs recentes. A simples presença de uma resposta 200 não fecha completude nem significado do agregado.

**Resolução conferida:** a política C1 define execuções recentes, paginação/completude, precedência de falha/ação/pendência/cancelamento e restrição de “Passou” a conjunto completo não vazio de sucessos. Neutral/skipped possuem síntese neutra e ausência confirmada é separada de inacessibilidade. A primeira correção chamava neutral de “não executado”; a releitura identificou essa imprecisão, e o texto atual distingue neutral executado de skipped (design.md:191).

A política de revisão conserva a solicitação de responsabilidade separada das decisões; usa última decisão formal por identidade para o SHA observado, não transforma COMMENTED/PENDING em aprovação, trata DISMISSED sem ressuscitar aprovação anterior e mantém decisões conflitantes/históricas com rótulos próprios. Ambiguidade ou parcial impede síntese conclusiva. Não avalia branch protection nem amplia escopos.

**Estado:** resolvido documentalmente. T28 e U07 referenciam os casos C1; REVIEW dessas regras não se disfarça de reprodução real. Combinações sem dados reais permanecem NOT-RUN em runtime.

## Achados corrigidos durante a revisão

| Achado original | Conflito encontrado | Resolução relida | Estado |
|---|---|---|---|
| F01 — P1 — gates antes de existirem seus componentes | UI-base obrigava os casos integrados em T02/T04, antes de painel, V3, seleção/faixa e teclado. | tasks.md:55–56 e 65–83 agora distinguem a observação disponível por tarefa do aceite posterior; T23–T35 ligam o componente real incrementalmente. | Resolvido documentalmente. |
| F02 — P1 — prova de fullscreen posterior às contas | O design pedia prova local antes das integrações; a qualificação só constava em T38. | design.md:106 e tasks.md:163–171 antecipam a prova mínima/fallback para T04; T38 conserva mudanças dinâmicas e matriz ampliada. | Resolvido documentalmente. |

A correção de F01 preserva o gate obrigatório da tarefa. Ela não transforma a observação de duas colunas desconectadas em PASS do fluxo card ↔ PR. A correção de F02 registra modos indisponíveis como não qualificados e não promete sobreposição universal.

## Conferências concluídas do planejamento

Uma conferência somente de texto, em memória e sem criar arquivos auxiliares, encontrou:

| Conferência | Resultado documental |
|---|---|
| Requisitos | 28 IDs distintos, R01–R28. |
| Critérios | 56 IDs, dois por requisito. |
| Casos de verificação | 28 casos, abrangendo os 56 IDs. |
| Definições de tarefa | 42, todas Pending; cada uma tem gate. |
| Grafo | 42 nós/41 arestas; ordem total T01→T42, sem ciclo ou órfão. |
| Grafo versus Depends on | Nenhuma divergência. |
| Matriz requisito→tarefa versus campos Requirement | Nenhuma divergência. |
| Lotes/ownership | Seis lotes de sete tarefas, um escritor de código; especialistas em leitura e decisões publicadas pelo orquestrador. |
| Atomicidade | As entregas têm um conceito/coordenador/componente ou relatório coeso. T26/T27 são densas, mas não há necessidade demonstrada de nova arquitetura para dividi-las. Correções descobertas são tarefas próprias. |
| Composição antes de T36 | tasks.md:14 e 65–83 e design.md:178 dão lugar à ligação incremental de produção, sem seed/mock. T18 declara entrada própria tipada antes de o resolver existir. |
| Deduplicação | design.md:75–89 separa identidade remota de conexão e reconcilia alias de repo antes da publicação/seleção. |
| Relações | design.md:148–176 delimita título/branch, site/projeto, PRs abertos em repos selecionados, proveniência, orçamento e parcial; PR contextual não altera contador pessoal. |
| Visual | O plano preserva duas colunas, seleção cinza, faixa inferior e ausência de barra lateral colorida da V3. Diferenças das pranchas e auth ilustrada não substituem a decisão canônica. |
| Auth/sandbox | Token Jira, gateway, escopos, configuração sem App Sandbox e assinatura/Hardened Runtime continuam propostas qualificáveis, não configuração aplicada nem aprovação presumida. |
| Limites de aceite | verification-plan.md:12–26 e 75–99 distinguem REVIEW/MANUAL/BUILD/MEASURE e impedem aceite quando faltar gate obrigatório. NOT-RUN externo não vira PASS. |
| Estado da autorização | STATE AD-001, spec.md:3 e 298–316 e context.md:40–51 conservam Draft, decisões abertas e Execute não iniciado. Visual aprovado não significa stack/auth/implementação aprovadas. |

O protocolo de contexto canônico e o cuidado com edição concorrente são compatíveis com a [documentação oficial consultada de subagentes](https://learn.chatgpt.com/docs/agent-configuration/subagents). O protocolo específico de contratos/mensagens é apresentado corretamente como decisão do projeto, com requalificação do runtime futuro.

## Observações para T01 e limites da revisão

- Como o diretório atual não é um repositório Git, T01 deve materializar o destino autorizado e confirmar/criar o repositório apropriado antes do primeiro commit. Não inicializar Git nem copiar documentos para outro destino nesta etapa.
- Os escopos reais de projetos/repos e as capacidades de Jira/gh continuam pendentes; devem ser coletados por fluxo autorizado antes das consultas correspondentes. Se não houver uma relação real preexistente disponível, o gate central permanece bloqueado até evidência ou revisão explícita do escopo; não criar trabalho corporativo para satisfazê-lo.
- A evidência compacta REA em outputs/evidencias-rea.json é coerente com os metadados citados. Não repeti o hash do DMG nem a inspeção do terceiro; a reconferência declarada em research.md pertence ao trabalho dos autores, e não é uma nova verificação minha. Inventário/plist não comprovam animação, foco, performance ou runtime no macOS 27.
- As fontes GitHub/gh e OpenAI citadas nos achados foram consultadas nesta revisão. Não se tratou de requalificação completa de todas as APIs e versões do plano; toolchain, SDK, políticas de conta e provedores reais continuam pendentes de Execute.
- Não li credenciais, auth, sessões, logs, bancos SQLite, paste cache ou históricos brutos. Não conectei contas, executei terceiros, instalei ferramentas ou alterei configuração ativa.
- **Build, lint, testes, execução funcional do Radar, medições e acessibilidade: não executados.** Nenhum app, teste, arquivo de teste ou mock foi criado.

## Conclusão

**READY-FOR-USER-REVIEW:** os cinco achados foram resolvidos documentalmente e relidos, e a conferência final manteve 28 requisitos, 56 critérios, 42 tarefas e 41 arestas, sem divergência de rastreabilidade/grafo. O pacote pode ser submetido à revisão do usuário, com propostas de auth/sandbox e limite residual do gh explícitos.

O estado continua **Draft**, com **Execute não iniciado** e todas as tarefas Pending. Este veredito não significa plano aprovado pelo usuário, autorização de implementação nem app aprovado/funcional. A qualificação de toolchain, contas, hardware e gates reais continua futura.

## Snapshot documental da última releitura

Os hashes identificam as versões efetivamente conferidas. Se estas fontes mudarem, reler o impacto antes de reaproveitar este veredito; o próprio relatório não é um gate funcional.

Na releitura final de STATE.md:69–78, o Handoff passou a registrar o plano concluído para revisão e este veredito, mantendo Draft, propostas A01–A13 e Execute não iniciado. Decisions permanecem preservadas; o texto não extrapola a revisão documental nem declara aceite do app.

| Fonte | SHA-256 |
|---|---|
| .specs/STATE.md | 194e7f163911ec7cb04d32f059e1f4c88e3e124e4e33e497fbb85366ecc88308 |
| spec.md | ca5c2b86d3d0c159efbd7dda7a2240f62dd1ae599285d9d71926a7f9154da641 |
| context.md | bd82594ae8796d6bd29654f8cc3c6b6f0c1801c41146d943a409c88de8a83f59 |
| design.md | 35de7afb78c8aa4ebbcc3a6698bacbdae234b72e999891607cdee379700288a4 |
| tasks.md | 7462c36db2fcede5c188824711071802339f200af1408b615df1010e871cb561 |
| coordination.md | dfba8839e22366b21a33a89c6d0ae4efb8b1007eab1b87bfef3b3c0b229b6375 |
| verification-plan.md | fd6e01c6bf1049eac017f9c2cb238efb0c0c478af73cea82c1242af21da5b469 |
| research.md | c7916c9ee831b2fa54e9d532cdc3af2e04171ca5ebb5e08d4963efc8613c96fb |

