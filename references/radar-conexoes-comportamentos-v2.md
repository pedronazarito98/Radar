# Radar — conexão entre card e PR

Versão de discussão 2 · 22/10/2026 · sem implementação.

## Direção escolhida e fronteira desta etapa

O usuário escolheu a primeira opção visual, Radar, e pediu a conexão entre card e PR da terceira, Contexto. Em seguida escolheu explicitamente uma faixa de detalhes abaixo das duas colunas, mantendo a visão geral visível.

Esta revisão preserva Jira à esquerda, GitHub à direita, a superfície preta ligada à borda da tela, dois contadores fechados e abertura por clique. O acréscimo é uma seleção contextual: escolher um item realça suas relações e revela a faixa inferior.

[Imagem refinada](notch-radar-conexoes-v2.png). A imagem é um estudo estático com dados fictícios. O título Radar é um nome de trabalho.

## Decisões confirmadas

- Base visual: primeira opção do estudo inicial.
- Conexão entre tarefa e código: incorporada à base escolhida.
- Local dos detalhes: faixa inferior ocupando a largura das duas colunas.
- As duas listas continuam visíveis durante a consulta.
- Esta etapa continua sendo discussão de visual e comportamentos, sem código do aplicativo.

Todos os demais comportamentos abaixo são propostas para discussão, e não decisões já aprovadas pelo usuário.

## Estrutura visual

### Fechado

Dois indicadores: ícone e número de Jira à esquerda da câmera e ícone e número de GitHub à direita. As cores identificam a origem; um indicador adicional de atenção, quando necessário, não altera o significado dos números.

Os alvos de clique ficam em pixels realmente visíveis nas laterais ou abaixo da câmera. O centro físico não recebe conteúdo.

### Visão geral aberta

Uma superfície com duas listas e divisória discreta:

- Jira: chave, título resumido, status real do fluxo e indicação de PRs relacionados quando essa consulta estiver disponível.
- GitHub: repositório, número, título e relação com o usuário, como “Sua revisão” ou “Meu PR”. Quando conhecido, um pequeno identificador informa o card relacionado.

São listas de itens com poucos elementos por linha. A indicação “2 PRs” pertence à relação do card; não substitui o contador global de GitHub.

A conexão aparece por texto e ícone, além de cor. O título pode ser abreviado visualmente, preservando seu valor completo para acessibilidade e consulta.

### Card selecionado

O card recebe um fundo azul discreto. PRs já visíveis que se relacionam a ele recebem uma marca lateral violeta e a chave da tarefa. Outros itens permanecem legíveis, no mesmo lugar, com os mesmos totais.

A faixa inferior informa:

- Contexto: “Conexões · ENG-241”.
- Quantidade de relações encontradas no escopo consultado.
- Uma linha por PR, com repositório e número, estado do CI, estado da revisão e ação de abertura.
- Origem da associação, como vínculo fornecido pela integração, referência à chave no título ou associação local feita pelo usuário.
- Controle para fechar apenas os detalhes.

No exemplo fictício, a tarefa ENG-241 tem dois PRs: acme/web #182 solicita a revisão do usuário; acme/api #181 aguarda a revisão de outra pessoa. Ambos têm CI concluído com sucesso. Essa diferença justifica manter CI e revisão como sinais separados.

## Fluxo de interação

| Ação | Resultado proposto |
|---|---|
| Clicar em um indicador fechado | Abre a visão geral com as duas colunas. O lado clicado pode receber foco de teclado, sem esconder a outra origem. |
| Passar o ponteiro | Apenas um realce discreto do alvo. Abertura por hover não é o padrão. |
| Clicar em uma linha Jira ou na indicação “2 PRs” | Seleciona o card e mostra suas conexões na faixa inferior. |
| Selecionar outro card | Atualiza a seleção, os realces relacionados e a faixa existente. Não cria outra faixa. |
| Clicar novamente no mesmo card | Mantém a seleção estável. Para sair, usar o controle da faixa ou Esc. |
| Selecionar um PR da coluna GitHub | Usa a mesma faixa para mostrar seus cards relacionados e seus próprios estados. Evita navegação adicional. |
| Acionar “Abrir revisão”, “Abrir PR” ou o atalho de link externo | Abre o destino explícito no navegador. Selecionar uma linha, por si só, consulta detalhes dentro do notch. |
| Fechar a faixa ou pressionar Esc com detalhes abertos | Volta à visão geral, preservando as posições das listas. |
| Pressionar Esc na visão geral | Fecha o painel. |
| Clicar fora ou clicar de novo no alvo do notch | Fecha todo o painel. Não fecha apenas uma camada. |
| Tirar o ponteiro do painel | Não fecha automaticamente. |
| Fechar e reabrir | Proposta inicial: voltar à visão geral. Retomar a última seleção permanece uma decisão de produto em aberto. |

As ações externas serão controles explícitos. Não é necessário duplo clique para o fluxo principal. Aprovação, merge e alteração de status Jira não fazem parte desta revisão.

## Relações e confiança

Um card pode ter vários PRs em diferentes repositórios. Um PR também pode fazer referência a mais de um card. A identificação de PR usa conta/host, organização, repositório e número; um número isolado não distingue repositórios.

A identidade do card também inclui o site/conta Jira e o projeto. A mesma sequência de caracteres em organizações diferentes não deve criar um vínculo entre contextos de trabalho.

Ordem sugerida de evidência:

1. Relação fornecida por uma integração autorizada, quando esse dado estiver disponível.
2. Referência explícita à chave da tarefa no título ou branch, exibindo a origem da referência.
3. Associação manual local, identificada como feita pelo usuário.

Uma referência encontrada no texto não deve ser apresentada como confirmação vinda do Jira. A interface deve permitir inspecionar a origem e, em uma evolução, ignorar uma associação incorreta. Vinculação manual local não altera o card ou o PR no serviço.

A Atlassian documenta referências à chave da tarefa em branch, commit e título do PR para relacionar dados de desenvolvimento. Esse padrão fundamenta pesquisar associações, mas não prova que o futuro app terá acesso a toda a informação de desenvolvimento de uma conta. [Fonte oficial](https://support.atlassian.com/jira-cloud-administration/docs/use-the-github-for-jira-app/).

Não propomos associar itens apenas porque os títulos parecem semelhantes.

## Contagens e contexto

| Número exibido | Significado proposto |
|---|---|
| Jira no notch e no cabeçalho | Itens atribuídos ao usuário e ainda não concluídos, dentro do contexto profissional selecionado. |
| GitHub no notch e no cabeçalho | PRs abertos na união de autoria, atribuição e revisão solicitada, sem duplicidade. |
| “2 PRs” ao lado de um card | PRs relacionados encontrados no escopo consultado para aquele card. |
| Quantidade na faixa inferior | Relações exibidas ou disponíveis para o item selecionado. |

Selecionar um card não muda os filtros globais nem os totais. Um PR que aparece na lista e na faixa continua sendo um único PR.

Pode haver um PR do card acessível ao usuário que não pertença à lista pessoal de autoria/atribuição/revisão. Ele pode aparecer como contexto na faixa, em um grupo identificado como “Outros PRs do card”, sem aumentar o contador pessoal do GitHub.

Uma quantidade não encontrada ainda não é zero. A indicação de relações deve distinguir consulta pendente, dados consultados, consulta incompleta e falha.

## Sinais de estado

### Jira

Mostrar o status do fluxo daquela equipe. Bloqueado pode ser um status, um marcador ou outra convenção, portanto seu significado precisa de configuração e validação futura.

Um PR merged não conclui automaticamente um card dentro deste produto. As informações podem divergir temporariamente sem que o app tente alterar o fluxo do usuário.

### GitHub

CI, revisão e estado do PR são independentes:

| Dimensão | Exemplos de rótulo |
|---|---|
| Execução do CI | Em fila; em andamento; passou; falhou; cancelado; não disponível. |
| Revisão | Sua revisão; aguardando revisão; mudanças solicitadas; aprovado. |
| Estado do PR | Draft; aberto; merged; fechado. |

O verde do CI informa somente o resultado dos checks observados. A imagem não usa “Pronto para merge”. Regras do repositório e outras condições podem continuar pendentes.

O GitHub documenta tipos distintos de decisão de revisão e a existência de requisitos de aprovação. [Revisões de PR](https://docs.github.com/en/pull-requests/reference/pull-request-reviews). O fluxo de PR também separa revisões e verificações necessárias para merge. [Documentação oficial do GitHub](https://github.com/github/docs/blob/main/content/pull-requests/get-started/about-pull-requests.md).

A origem e a atualização de cada informação devem ficar claras. “Atualizado agora” só aparece depois de uma consulta bem-sucedida para o escopo indicado; uma falha em uma fonte não faz a outra parecer desatualizada.

## Animação, altura e estabilidade

Propostas iniciais, a validar no Mac:

- Abertura da visão geral: cerca de 220–280 ms, com expansão contínua a partir do notch e amortecimento discreto.
- Revelação da faixa: cerca de 160–220 ms, mantendo a borda superior presa à tela e acrescentando altura para baixo.
- Troca entre cards com a faixa já aberta: manter sua geometria e usar uma transição curta do conteúdo.
- Não desenhar fios, setas atravessando as colunas ou animação contínua entre card e PR. Identificadores e realces consistentes comunicam a relação.
- Respeitar redução de movimento com transição curta por opacidade e sem expansão animada.
- Definir limite de altura com base no espaço disponível na tela. As imagens mostram a direção, não dimensões finais calibradas.
- A faixa mostra inicialmente até duas relações. Se houver mais, uma ação “Ver todas as conexões” abre uma listagem dentro da própria faixa, com altura limitada.
- Novos dados não devem reordenar os itens sob o ponteiro. Um indicador de atualização permite aplicar uma nova ordenação.
- Atualizações de estado podem aparecer no item atual. Caso deixe de pertencer à lista, mantê-lo temporariamente com seu novo estado para explicar a mudança, até o usuário aplicar a atualização ou reabrir.

O número de relações não deve fazer o painel crescer indefinidamente. Ao atualizar o conjunto de itens, totais e listas precisam usar o mesmo escopo e explicar itens mantidos temporariamente para continuidade.

## Teclado e foco

O foco de teclado precisa ser visível. Consultar um contador ou receber uma atualização não deve interromper a digitação no editor.

Dentro do painel, propomos navegação por Tab entre controles, setas dentro das listas e Enter para selecionar/consultar o item em foco. A ação externa pode receber um atalho próprio depois de verificar conflitos. Esc respeita as duas camadas: detalhes e visão geral.

Ao fechar detalhes, devolver o foco ao item que os abriu. Ao fechar todo o painel, devolver a interação ao aplicativo anterior. Esse comportamento ainda não foi implementado nem validado.

Rótulos acessíveis devem informar chave/número, título, status, relação com o usuário e quantidade de conexões. Cor e posição não carregam o significado sozinhas.

## Casos importantes

| Situação | Resposta proposta |
|---|---|
| Nenhum PR encontrado após consulta bem-sucedida | “Nenhum PR identificado neste escopo”, com abrir card e copiar chave. |
| Consulta de relações em andamento | “Consultando conexões”; não exibir “0 PRs”. |
| Relações encontradas só parcialmente | Mostrar o que foi obtido com aviso de consulta incompleta. |
| Consulta falhou | Explicar a falha e oferecer tentar novamente. Não apagar relações conhecidas como se não existissem. |
| PR sem card identificado | Mostrar o PR e “Nenhum card identificado”; não inventar associação. |
| Um item relacionado está fora da lista pessoal | Exibir como contexto, com identificação própria e sem alterar o total pessoal. |
| Vários repositórios ou PRs com o mesmo número | Exibir o repositório em cada linha e manter identidade completa. |
| Muitos vínculos | Faixa com altura limitada e listagem completa por ação explícita. |
| Seleção muda durante uma consulta | Os resultados anteriores continuam pertencendo ao item original e não aparecem sob o novo título. |
| Um PR recebe novas mudanças | Atualizar checks/revisão conforme os dados disponíveis, sem presumir que uma aprovação antiga continua válida. |
| Um PR é merged enquanto os detalhes estão abertos | Mostrar o novo estado e manter o contexto para explicar o que aconteceu. |
| Fonte sem acesso ou desconectada | Identificar o estado daquela fonte. O restante do painel continua útil. |
| Apenas um dos serviços está conectado | Mostrar sua lista e uma ação clara de conexão na outra coluna. |
| O app é reaberto depois de fechar o notch | Proposta: visão geral. A decisão sobre retomar seleção está aberta. |

## Escopo recomendado para continuar desenhando

Priorizar visão geral, seleção, faixa de relações, origem do vínculo, navegação externa, retorno e estados vazios/de consulta.

Depois podemos discutir acompanhar um card, adiar lembretes, privacidade e contextos profissionais. Essas opções não precisam aparecer todas no painel principal.

O próximo ponto de produto é decidir se reabrir o notch sempre começa na visão geral ou retoma o último card selecionado. A recomendação inicial é visão geral, deixando retomada persistente como preferência futura.

## Validação desta etapa e próxima revisão manual

Nesta etapa: duas imagens anteriores foram inspecionadas como referência; uma imagem combinada foi gerada; arquivos de entrega e suas referências locais foram conferidos. Não houve implementação, instalação, integração com contas ou mudança nos serviços.

Para revisar visualmente agora:

1. O realce do card e dos PRs comunica a relação sem esforço?
2. A faixa mantém legíveis as duas listas?
3. É claro que “GitHub 3” e “2 PRs do card” têm significados diferentes?
4. As ações de selecionar e abrir no navegador são distinguíveis?
5. O estado do CI e a responsabilidade pela revisão são compreensíveis?

Depois, em um protótipo autorizado, validar cliques, Esc em duas etapas, foco, navegação por teclado, movimento reduzido, altura no Mac real, monitores e mudanças de dados durante uma consulta.

Nenhum código do aplicativo, teste, arquivo de teste ou mock de código foi criado. Build, lint, testes e interações de runtime não foram executados.

Prompt e referências da geração preservados em [prompt-radar-conexoes-v2.txt](prompt-radar-conexoes-v2.txt). Ferramenta usada: geração de imagens nativa. A imagem é uma proposta visual e não é evidência de funcionamento.

