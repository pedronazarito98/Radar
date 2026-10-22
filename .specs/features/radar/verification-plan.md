# Radar — plano de verificação

**Status**: planejamento. Nenhum caso do app foi executado.  
**Cobertura**: 28 casos, cada um com dois subcritérios da spec (56 critérios). Uma linha abaixo não representa um único clique nem um resultado concluído.

## Política e evidência

Sem testes, arquivos de teste, mocks ou sensor novos, por instrução explícita do usuário. Não transformar estes roteiros em scripts de simulação. Build, revisão de código, observação manual e medição são modos diferentes de evidência.

Dados das pranchas (como 4 cards/3 PRs) são exemplos visuais; não popular o app com eles. Usar somente contas e recursos existentes já autorizados, sem criar/modificar cards, PRs, comentários ou solicitações de revisão para satisfazer cenário. Entrada Jira ocorre diretamente no app, sem screenshots do token.

Para cada subcritério, registrar um resultado e o modo que o sustenta. Revisão de código pode verificar uma invariante/ramo sem reproduzir a falha de um serviço; isso deve constar como **REVIEW**, não como execução de runtime. Quando a spec exige observação no Mac (foco, recorte, fluidez, acessibilidade, Finder e fluxo central real), revisão estática não substitui a execução.

Não provocar rate limit, invalidar credencial, alternar conta do gh, editar auth ou instalar ferramentas para gerar uma condição. Condição externa não encontrada permanece NOT-RUN em runtime, acompanhada da revisão do tratamento quando cabível. O relatório final delimita essa garantia; não a converte em reprodução real.

## Gates obrigatórios para a V1 pessoal

- Build do app real; abrir pelo Finder/caminho completo no Mac alvo.
- Recorte/hit area, foco, abrir/recolher e 30 ciclos sem resíduos.
- Conectar/consultar Jira e GitHub independentemente com os métodos qualificados.
- Listar/contar, selecionar card ↔ PR com uma relação real e abrir os destinos.
- Comparar identidade V3 e executar teclado/VoiceOver/Reduzir Movimento.
- Revisar todos os tratamentos e invariantes dos 56 critérios, com evidência de código onde não houve reprodução real; registrar separadamente cada cenário de runtime não exercitado.
- Verificador fresco confere código/evidências e a precisão das alegações.

Se faltar um gate obrigatório acima, o app não está aceito. Outros displays/combinações de estado/provedor não observados não podem ser declarados suportados/testados; seu impacto é reportado e, se necessário ao escopo acordado, impede fechamento até observação ou revisão explícita do escopo. Automação/sensor excluídos por política não viram requisitos ocultos de conclusão.

## Casos e critérios

| Caso / critérios | Ação/procedimento | Resultado esperado | Pré-requisito / momento | Modo |
|---|---|---|---|---|
| U01 — R01.1 e R01.2 | Iniciar sem contas; abrir menu e encerrar. | Notch inicialmente fechado; acesso alternativo; nenhum painel/timer/observador próprio sobrevive ao encerramento. | T02/T04/T05/T41; Mac principal | Manual + revisão do ciclo |
| U02 — R02.1 e R02.2 | Abrir/fechar e interromper transição; clicar perto/fora das asas visíveis. | Controles fora da câmera; painel em bounds; área transparente não intercepta clique. | T03/T04/T07/T38; tela real com notch | Manual obrigatório no hardware alvo |
| U03 — R03.1 e R03.2 | Conferir união com PR real que participe de mais de um papel; selecionar card. Inspecionar regra de unknown/parcial/99+. | Dedup e total pessoal estáveis; zero só completo; limite visual nunca afirma total exato inexistente. | T11/T15/T24/T27; dados autorizados existentes | Manual para dados existentes + revisão de regras |
| U04 — R04.1 e R04.2 | Clicar; retirar ponteiro; selecionar; Esc duas vezes; clicar no editor; abrir destino externo. | Saída do ponteiro não fecha; Esc recua e fecha; clique fora mantém editor; link mantém navegador; refresh não toma foco. | T05/T07/T13/T20/T21/T37 | Manual obrigatório |
| U05 — R05.1 e R05.2 | Comparar composição com V3, inclusive seleção e relação multi-repo. | Duas colunas, seleção cinza, faixa inferior e nenhuma borda lateral colorida; repo/texto/ícone distinguíveis. | T06/T15–T20/T40; V3 canônica | Manual visual + revisão de tokens |
| U06 — R06.1 e R06.2 | Selecionar card e PR, trocar item, voltar à linha, percorrer relações reais disponíveis. | Uma faixa substituível; listas/ordem/totais preservados; foco volta à origem; altura limitada. | T13/T16–T21/T31 | Manual obrigatório do fluxo bidirecional |
| U07 — R07.1 e R07.2 | Observar PR real; revisar novo SHA com resposta antiga, rerun, success+skipped, vazio/acesso, solicitação+aprovação e COMMENTED/DISMISSED segundo C1. | Fase, CI e revisão independentes; token de detalhe válido; política C1 verificável; sem inferência de merge ou verde por ausência. | T10/T17/T18/T28; design.md, políticas C1 | Manual + revisão semântica; combinações indisponíveis NOT-RUN runtime |
| U08 — R08.1 e R08.2 | Usuário conecta Jira diretamente no SecureField e desconecta; revisor lê fronteiras próprias no código. | Segredo só no fluxo do app/Keychain próprio; remoção própria; documentos/agentes não recebem token. | T19/T22/T23/T35/T36; método permitido pela organização | Manual pessoal + revisão, sem captura da entrada |
| U09 — R09.1 e R09.2 | Abrir pelo Finder e qualificar gh; observar estado de conexão. Inspecionar wrapper para ausente/incompatível/auth-required. | Caminho absoluto/GET/host/allowlist; nenhum shell/auth token/login/status; ação específica por falha. | T19/T25–T27/T33; gh existente | Manual real + revisão; não apagar auth para provocar caso |
| U10 — R10.1 e R10.2 | Consultar cards atribuídos no escopo real; comparar a UI com dados visíveis autorizados; revisar paginação. | Enhanced search e nextPageToken; status real; orçamento/falha nunca vira completude. | T09/T24/T32 | Manual real + revisão; múltiplas páginas só se existirem |
| U11 — R11.1 e R11.2 | Conferir consultas de autor/assignee/review-requested e um PR sobreposto se disponível. | União por identidade; limites/incomplete_results geram parcial; revisão pessoal/equipe não confundida. | T08/T10/T11/T27/T32 | Manual + revisão; não criar PRs/solicitações artificiais |
| U12 — R12.1 e R12.2 | Selecionar card com PRs em repos autorizados e caminho inverso; revisar ENG-241 vs ENG-2410. | Proveniência título/branch, site/projeto e repo claros; M:N; contexto fora da lista pessoal não altera total. | T29–T31; vínculos reais previamente existentes | Manual bidirecional + revisão de parser/escopo |
| U13 — R13.1 e R13.2 | Depois de dados carregados, desligar a rede temporariamente pelo usuário e atualizar; restaurar. Conferir vazio real quando disponível. | Snapshot anterior permanece com estado desatualizado/problema; sem snapshot não mostra zero; origens independentes. | T11/T12/T18/T32/T33 | Manual reversível + revisão; não interromper trabalho de terceiros |
| U14 — R14.1 e R14.2 | Alternar rapidamente entre dois itens durante consulta real; aplicar novo snapshot com painel aberto; revisar guardas de geração. | Conteúdo corresponde ao selecionado; resposta antiga não publica; ordem apresentada estável; nova ordem tem ação explícita. | T12–T14/T26/T31/T32 | Manual + revisão de concorrência; corrida não observada não é prova de runtime |
| U15 — R15.1 e R15.2 | Repetir atualizar; dormir/acordar o Mac se disponível; conferir budgets/backoff e descarte ao sair do detalhe. | Coalescência por origem/escopo; pausa/sleep; timeout/saída/páginas limitados; detalhe relevante apenas. | T14/T24/T26–T28/T30/T32 | Manual + revisão; não provocar rate limit real |
| U16 — R16.1 e R16.2 | Abrir destinos legítimos; revisar construtores, allowlists e rejeições de caminhos/esquemas/hosts. | Somente binário validado e REST permitido; nenhum dado vira comando/flag/arquivo; links HTTPS permitidos. | T23/T25/T26/T29/T37 | Manual para destino real + revisão de fronteiras, sem harness |
| U17 — R17.1 e R17.2 | Usar teclado e VoiceOver; ligar Reduzir Movimento; fechar painel e digitar no editor. | Foco visível, rótulos completos e Esc local; nenhuma captura global; transição reduzida discreta; estado sem depender só de cor. | T05/T07/T15–T18/T21/T40 | Manual obrigatório no Mac alvo |
| U18 — R18.1 e R18.2 | Variar escala/resolução, conectar display disponível e conferir Spaces/fullscreen/Stage Manager. | Uma instância em bounds; política suportada registrada; menu alternativo útil onde sobreposição não foi qualificada. | T03/T04/T38/T40 | Manual; hardware/modo indisponível fica NOT-RUN e fora da alegação de suporte |
| U19 — R19.1 e R19.2 | Fechar/reabrir; desconectar origem; revisar pontos próprios de escrita e invalidação. | Preferências não secretas permanecem; dados de trabalho voltam da rede; nenhum cache em disco; desconexão limpa somente próprio. | T12/T34–T36 | Manual + revisão de escrita; não abrir banco/auth externo |
| U20 — R20.1 e R20.2 | Conectar somente Jira, depois somente GitHub quando possível; acessar recuperação/configurações. | Origem disponível continua útil; textos correspondem ao modo pessoal; nenhuma promessa de OAuth pronto. | T19/T22/T23/T25/T33/T36 | Manual obrigatório por origem |
| U21 — R21.1 e R21.2 | Gerar bundle real e lançar pelo Finder/caminho completo; conferir metadados públicos do bundle produzido. | SDK/config/assinatura/sandbox/Hardened Runtime registrados; CLI funciona nesse lançamento; distribuição não inferida. | T01/T02/T25/T26/T41 | Build + manual obrigatório local |
| U22 — R22.1 e R22.2 | Executar 30 ciclos de abrir/fechar/selecionar e observar repouso com ferramentas nativas disponíveis. | UI independe de rede; nenhum painel/hit area residual; medidas/engasgos/recursos ou NOT-RUN explícitos. | T04/T07/T14/T26/T39 | Manual + medição; screenshot não comprova fluidez |
| U23 — R23.1 e R23.2 | Auditar pacotes de contexto, mensagens sanitizadas, ownership e relatório independente. | Contratos publicados antes do consumidor; um escritor; lotes sequenciais; verificador fresco. | T01/T42; coordination.md | Revisão documental de processo |
| U24 — R24.1 e R24.2 | Conferir hash/evidências REA e eventuais perguntas novas registradas. | Inventário/plist limitados a evidência estática; nenhuma inferência de runtime; investigação nova delimitada. | T01/T39/T42; research.md | Revisão documental; sem executar terceiro |
| U25 — R25.1 e R25.2 | Conferir cada tarefa/gate/commit e o relatório final. | Gate observado precede avanço; obrigatórios pendentes impedem conclusão; testes/sensor NOT-RUN por política. | T01/T39–T42; manifesto | Revisão documental; sem alegar automação |
| U26 — R26.1 e R26.2 | Revisar IDs e GET /user nas fronteiras; comparar repos/PRs reais diferentes; se houver troca externa voluntária de conta, requalificar. | Dedup e isolamento por identidade; divergência descarta lote; falha final impede publicar; limitação de troca A→B→A não observada está declarada. | T08–T13/T27/T30/T35 | Manual + revisão; troca externa nunca executada pelo agente |
| U27 — R27.1 e R27.2 | Revisar mapeamento de respostas/exit codes; observar falhas reais disponíveis sem provocá-las. | 401/auth-required, 403/SSO, 429, timeout, cancel e conteúdo inválido são distintos; nenhum vira vazio ou expiração presumida. | T11/T14/T23–T28/T33 | Revisão obrigatória; runtime indisponível NOT-RUN |
| U28 — R28.1 e R28.2 | Auditar chamadas de trabalho e ações de UI; abrir/copiar links reais permitidos. | Somente GET/consulta e navegação; nenhuma alteração Jira/GH; escopos reais não são descritos falsamente como read-only. | T19/T23/T24/T26–T28/T37 | Revisão obrigatória + manual de navegação |

## Roteiro do fluxo central

1. Iniciar sem contas. Conferir indicadores sem zero falso, menu e abertura pelo clique.
2. Conectar Jira diretamente na UI segura, depois qualificar gh existente. A origem já conectada continua útil.
3. Conferir listas reais, contagens e identificação de repos, preservando layout V3.
4. Selecionar um card que já tenha referência explícita em PR autorizado. Ler a faixa, distinguir CI/revisão e abrir PR.
5. Reabrir e selecionar um PR. Conferir card(s) referenciado(s), voltar por Esc e abrir Jira.
6. Repetir com consulta pendente e troca rápida de seleção; conferir snapshot/ordem estável e tratamento revisado de resposta atrasada.
7. Desconectar uma origem e conferir a outra. Reiniciar; conferir preferências e nova consulta.
8. Executar teclado, VoiceOver, Reduzir Movimento, modos de display disponíveis e 30 ciclos.
9. Registrar bundle/configuração e entrega pessoal; não publicar.

As oito pranchas/18 quadros continuam orientando o visual. Ajustar apenas textos/ações de conexão para token Jira + gh; a referência V3 prevalece sobre pequenas diferenças entre imagens geradas.

## Registro de evidência por subcritério

Campos obrigatórios:

| Campo | Conteúdo |
|---|---|
| Criterion | Rxx.1 ou Rxx.2, com caso Uxx |
| Task / commit | Txx e hash real conferido |
| Environment | macOS, hardware/tela, SDK/configuração e capacidades relevantes, sem endereço interno |
| Mode | BUILD, MANUAL, MEASURE ou REVIEW |
| Preconditions | Conexões/capacidades necessárias; sem credencial/identificador corporativo |
| Action | O que foi feito ou trecho/invariante revisado |
| Expected | Critério da spec |
| Observed | Resultado real ou razão da não execução |
| Evidence | Referência sanitizada, screenshot sem dados sensíveis ou caminho/linha de fonte própria |
| Status | PASS, FAIL ou NOT-RUN; REVIEW não se disfarça de MANUAL |
| Limits | O que não foi observado/medido e impacto na alegação |

Somente preencher PASS depois da observação/revisão correspondente. Registro atual de implementação: todos Pending/NOT-RUN, nenhum hash de app.

## Manifesto final

O futuro acceptance.md reúne uma entrada por subcritério e apontadores para os relatórios de performance, visual/acessibilidade e bundle. Totalizar PASS/FAIL/NOT-RUN por modo, listar bloqueios e cenários condicionais não observados. Um critério pode ter REVIEW concluído e MANUAL NOT-RUN; o manifesto conserva as duas informações.

O verificador independente confronta a árvore no commit final e o que cada evidência realmente prova. Não reexecuta automaticamente autenticação, não lê logs/auth/Keychain e não pede segredo no chat. Correções seguem o ciclo de coordination.md.

## O que já pode ser verificado nesta etapa

Apenas coerência dos documentos, referências locais, rastreabilidade, dependências, integridade do pacote e revisão independente do plano. Isso não é build, teste ou validação funcional do Radar.

