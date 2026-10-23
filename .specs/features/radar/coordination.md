# Radar — execução com Codex e subagentes

**Status**: execução local ativa; lote2 preparado. Após limite de uso de batch_2_resume/domain_review, root assumiu escritor único; revisão independente de T13/T14 pendente. Nenhum agente é simulado.
**Fonte canônica**: [STATE](../../STATE.md), [spec](spec.md), [context](context.md), [design](design.md), [tasks](tasks.md). Contratos C1 e refinamentos C1.1–C1.4 publicados pelo orquestrador. Handoff em docs/handoffs/batch-02.md.


## O que a documentação do Codex sustenta

A documentação oficial descreve delegação a subagentes, herança de contexto/configuração/permissões e o valor de paralelizar leitura/investigação com cautela em edições simultâneas. [Subagentes no Codex](https://learn.chatgpt.com/docs/agent-configuration/subagents).

O protocolo de mensagens/contratos abaixo é a proposta deste projeto usando as ferramentas de colaboração disponíveis nesta sessão. Não é uma promessa de memória compartilhada automática entre todos os agentes, nem depende de uma flag/configuração de CLI não confirmada.

Não configurar agora agentes globais, modelos, MCPs, skills ou permissões do usuário. Na futura execução, qualificar os recursos disponíveis no runtime. Herdar modelo e nível de raciocínio do pai; não escolher outro sem pedido do usuário/regra aplicável.

## Papéis e autoridade de escrita

| Papel | Trabalho | Escrita permitida |
|---|---|---|
| Orquestrador | Priorizar, distribuir contexto, resolver conflito e publicar decisões/contratos. | STATE, contrato/design, tasks, manifestos e decisões; coordena o dono de cada arquivo. |
| Worker do lote | Executar sete tarefas sequenciais, gates e commits atômicos. | Somente arquivos do lote/tarefa declarados e registro do próprio gate. |
| Especialista nativo | Investigar painel, foco, displays, recursos e acessibilidade. | Leitura e mensagens; sem editar código concorrentemente. |
| Especialista de providers | Investigar Jira/gh, paginação, auth, identidade e relações. | Leitura e mensagens; sem editar código concorrentemente. |
| Verificador fresco | Conferir fonte real, requisitos e evidências sem o raciocínio do autor. | Relatório de verificação; não corrige a própria auditoria silenciosamente. |

Nesta sessão há quatro slots: orquestrador + worker + dois consultores, ou orquestrador + três revisores de leitura. Isso é capacidade observada, não requisito de licença/execução futura. Workers não criam sub-subagentes; solicitações adicionais voltam ao orquestrador.

Nenhum chat público separado será criado para os lotes. São subtarefas da mesma solicitação.

## Contexto compartilhado de forma explícita

Antes de um lote, o orquestrador entrega um pacote pequeno, com caminhos canônicos e versão:

1. Objetivo, limites da autorização e regras do AGENTS.md aplicável.
2. Decisões ativas de STATE; feature e tarefa atual; último commit verificado.
3. spec/context/design, contratos C1 e tarefas do lote com dependências.
4. Referência V3 e pranchas relevantes; mudanças de texto de conexão já acordadas.
5. Evidência sanitizada do lote anterior e perguntas ainda abertas.
6. Arquivos permitidos para escrita, skills necessárias e gates exatos.

A fonte atual é o documento versionado, não a cópia antiga que um agente herdou. No início e ao receber mudança de contrato, reler somente as seções afetadas e confirmar a versão. O compartilhamento de filesystem não sincroniza a memória interna dos agentes.

Full-history fork pode ser usado para workers/consultores se disponível; o pacote canônico continua obrigatório. O verificador final inicia com contexto fresco, sem full-history fork.

## Comunicação direta entre pares

Os agentes podem se consultar diretamente nas ferramentas de colaboração disponíveis, mantendo o orquestrador copiado nos acordos. Se a interface de execução não permitir mensagem entre pares, o orquestrador encaminha a mensagem com autoria e referências; não inventar comando/flag para simular esse recurso.

Formato curto de mensagem:

> Tipo: CONTRACT_PROPOSAL | QUESTION | EVIDENCE | BLOCKER | HANDOFF  
> Lote/tarefa/requisito: identificadores afetados  
> Contrato: C1 ou proposta C2  
> Referência: caminho e seção, ou documento primário  
> Pergunta/resultado: afirmação precisa e efeito no consumidor  
> Próxima ação: quem responde/publica/retoma

Exemplo: “QUESTION — T31/R14 — C1 — SelectionKey em design.md: o retorno conserva contextID e generation? O cancelamento do processo pode chegar tarde. Proponho guardar os dois antes de publicar na faixa.”

O especialista responde com evidência/limites. O worker não altera contrato compartilhado por acordo informal. O orquestrador publica a revisão no design/STATE, atualiza tarefas/consumidores e anuncia a versão antes de retomar. Decisões de STATE são acrescentadas; Handoff é atualizado apenas na própria seção, sem apagar decisões anteriores.

Não colocar tokens, cookies, auth, payloads corporativos, títulos internos, logs, bancos ou históricos brutos no contexto/mensagens. Usar IDs de requisitos/tarefas e descrições sanitizadas. Nome privado que apareça por necessidade de UI não é copiado para documentação.

## Sequência de execução

1. Receber autorização explícita de implementação e confirmar destino. Rodar T01: ler estrutura, qualificar limites e fixar handoff.
2. Worker batch_1 executa T01–T07. Especialistas podem investigar em paralelo, apenas leitura. Gate do painel real ocorre cedo, sem contas.
3. Worker B recebe handoff e executa T08–T14; C executa T15–T21.
4. Worker D executa T22–T28; credencial é informada pelo usuário diretamente na UI. gh continua sendo pré-requisito externo.
5. Worker E executa T29–T35. Especialistas conferem contratos de integração e concorrência.
6. Worker F executa T36–T42; revisão visual T40 usa um revisor que não produziu as views.
7. Após o commit T42, iniciar automaticamente verificador fresco, sem pedir uma confirmação intermediária só para a revisão.
8. Se houver falha, converter achado em tarefa atômica com gate; corrigir por um worker e reverificar independentemente. Até três rodadas automáticas de correção/revisão; persistindo falha, entregar evidência e impedimento sem declarar conclusão.

AD-013 permite preparação sequencial de trabalho independente de interação bloqueada, sem concluir a tarefa/lote anterior nem dispensar gate obrigatório. Commits parciais são explicitamente rotulados.

Não executar fases em paralelo. Handoff só avança com gate da tarefa concluído e commit conhecido. Read-only review pode ocorrer junto do trabalho do autor, mas a evidência final deve apontar para o commit exato conferido; se o código mudar, rever a parte afetada.

## Handoff mínimo de lote

- Lote/tarefas concluídas e próximo ponto.
- Commit de cada tarefa, último commit e arquivos tocados.
- Contratos usados/alterados e compatibilidade com consumidores.
- Gates executados com modo (build/revisão/manual), ambiente e resultado.
- NOT-RUN, riscos, bloqueios e próximos passos.
- Sem dados corporativos ou segredos.

O worker relata o que fez e o que não verificou. O orquestrador confere o diff e os gates, atualiza STATE e só então entrega o próximo lote.

## Verificação independente e adaptação TLC

Entrada do verificador: árvore/commit real, spec/STATE/design/contratos/tasks, evidências sanitizadas e referência visual. Não enviar justificativas privadas, resumo persuasivo do autor ou histórico de tentativas.

Saída: conformidade por critério; lacunas de implementação; qualidade das evidências; problemas de foco/concorrência/auth; limites de hardware/provedor. Ausência de evidência não vira PASS por concordância entre agentes.

A política do usuário exclui testes novos, mocks e sensor de mutação. O verificador registra essa exclusão e **não emite um selo de cobertura automatizada/TLC integral**. Build/manual/revisão têm escopos próprios. Nenhum script de simulação será criado para contornar a regra.

## Prompt de retomada — usar somente após autorizar implementação

> Implemente a V1 pessoal do Radar seguindo .specs/STATE.md e .specs/features/radar/{spec,context,design,tasks,coordination,verification-plan}.md. Antes de editar, leia as regras e a estrutura reais. Comece em T01 e declare tarefa, arquivos, suposições, critério e gate. Preserve a identidade V3 e o escopo Jira Cloud + GitHub.com pelo gh existente. Não crie testes/mocks, não leia auth/credenciais/logs/bancos/históricos nem exponha tokens. Use seis lotes sequenciais de sete tarefas com um escritor por vez, consultores em leitura, contexto canônico e mensagens diretas quando disponíveis. Registre acordos de contrato via orquestrador, gates reais, commits atômicos e handoffs. Não instale ferramentas nem amplie auth por presunção. Depois de T42, dispare revisão independente fresca. Não publique ou distribua o app. Se um gate obrigatório não puder ser executado, registre o impedimento e avance somente no trabalho independente permitido.

Esse texto é uma instrução futura reutilizável, não uma ordem executada nesta etapa.

## Colaboração realizada no planejamento

radar_native_plan e radar_providers_plan herdaram o contexto e conversaram diretamente sobre identidades, snapshots, geração e transporte. Seus acordos foram consolidados em design.md. Um terceiro agente fresco revisará a coerência deste pacote de planejamento. Nenhum deles implementou o app.

