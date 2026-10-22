# Estudo de conceito — Jira + GitHub no notch

Data da pesquisa: 22/10/2026. Público: engenheiros de software. Etapa: discussão de produto e visual, antes de implementação.

## Recomendação

A proposta mais útil é um radar pessoal de trabalho: dois indicadores discretos quando fechado e uma consulta rápida quando aberto. O diferencial é deixar claro o que o engenheiro possui, o que exige sua ação e o que aguarda outras pessoas.

O desenho enviado estabelece uma boa organização inicial: Jira e GitHub em grupos distintos. Eu preservaria essa separação, com uma superfície preta contínua que nasce na borda superior, tipografia nativa, divisórias leves e cores pontuais. As molduras grossas do esboço seriam substituídas por espaçamento e hierarquia.

Tudo que segue como proposta é uma decisão de design para discussão. As imagens são estudos estáticos com dados fictícios; não representam um aplicativo funcionando.

## Referências pesquisadas

| Referência | Evidência documental | Aplicação ao conceito |
|---|---|---|
| [NotchNook](https://getnotchnook.com/guides/make-macbook-notch-useful) | O guia do fornecedor descreve abertura pelo ponteiro ou gesto, módulos e uma alça em displays sem notch; a página do produto descreve painéis por display. | Revelar informação em etapas: sinal compacto, painel para consulta e ação rápida. O nosso padrão continuaria sendo clique, conforme solicitado. |
| [DynamicLake](https://www.dynamiclake.com/changelog) | O changelog registra prévia no hover, fechamento por clique externo, navegação por swipe, ajustes de animação e suporte a telas externas. | Pequenos avisos de CI/review podem ocupar o estado compacto sem expandir a lista. Gestos e hover seriam preferências opcionais. |
| [Alcove](https://github.com/henrikruscon/alcove-releases/releases) | Changelogs do autor registram duo mode, cápsula em tela sem notch e ajustes de fullscreen. Uma [resposta do autor](https://github.com/henrikruscon/alcove-releases/issues/717) explica a suspensão de gestos durante HUDs. | Definir uma prioridade entre estados para evitar disputa entre alerta, contadores e painel aberto. O material consultado é histórico; não foi confirmado como comportamento da versão atual. |
| [Boring Notch](https://github.com/TheBoredTeam/boring.notch/releases) | Notas de 2.8-rc descrevem indicador fechado, fila de notificações, ajustes de abertura e opção de acompanhar o display ativo. São recursos de pré-release, separados do pacote 2.7.3 inspecionado. | Indicador persistente com fila consultável; configurações explícitas de tela. |
| [Atoll — Ebullioscopic](https://github.com/Ebullioscopic/Atoll) | O README da branch dev descreve expansão em SwiftUI e configurações de hover, animações, atalhos e atividades. | Acompanhar um item escolhido, como um PR com CI em andamento. A documentação é de desenvolvimento, e a experiência não foi executada. |

Esses documentos mostram padrões disponíveis, mas não medem fluidez, consumo de bateria ou qualidade de acessibilidade. Nenhum desses apps foi instalado ou executado nesta pesquisa. A leitura de tryalcove.com ficou indisponível; a comparação de Alcove usa as fontes históricas do autor citadas acima.

## Inspeção estática com REA

Alvo: [release público Boring Notch v2.7.3](https://github.com/TheBoredTeam/boring.notch/releases/tag/v2.7.3), arquivo boringNotch.dmg de 9.727.030 bytes.

- SHA-256 do DMG: `23786382548d33c59b309db558e513a92e3f95b63d611544dcddf5d196e46698`.
- Inventário: 229 nós, 249 ocorrências; evidência `ev_87ab2f621d937034d80dd44186534310a52992788fdab200aa25bfb95b3ed5a0`.
- Manifesto do grafo: `agm_da5ad4d2dd1ae2d0e8425c555daacb6c2b4dcfd2d5ced7299541a0d60682d1ec`.
- Info.plist: versão 2.7.3, build 271, bundle `theboringteam.boringnotch`, sistema mínimo declarado 14.0 e `LSUIElement=true`; evidência `ev_f09d8121104d261e8f1523bc944131a8d5a6e20d0b2ef083e7c3a522022aac5a`.
- O pacote contém executáveis Mach-O e frameworks; essa observação é de formato/empacotamento, sem decompilação das rotinas de interface.

Interpretação limitada: a configuração de agente e o empacotamento são coerentes com um utilitário discreto para macOS. Eles não demonstram abertura por clique, foco de teclado, animação, compatibilidade com macOS 27 ou comportamento em monitores.

O REA inventariou o DMG, mas não ofereceu extração desse formato nessa operação. Para ler o plist, o DMG foi montado em modo somente leitura e sem abrir interface do aplicativo. Depois foi desmontado, e a sessão REA foi fechada. Não houve instalação, execução do app, leitura de contas, credenciais, sessões, históricos, logs ou bancos de dados.

## Comportamento proposto

| Estado | Conteúdo | Entrada e saída |
|---|---|---|
| Fechado, padrão | Jira: ícone + quantidade à esquerda da câmera; GitHub: ícone + quantidade à direita. | Clicar em qualquer uma das duas áreas visíveis abre a visão agrupada. Um atalho configurável oferece alternativa. |
| Aberto | Grupos Jira/GitHub com título, identificador, relação com o usuário e estado. Poucas linhas visíveis e acesso aos demais itens. | Esc, clique externo ou novo clique na área de ativação fecham. Fixar aberto pode ser opcional. |
| Aviso breve, opcional | Uma mudança relevante, como review solicitado ou CI que terminou com falha. | Destaque curto na área visível; não expande o painel automaticamente. Respeita preferências de foco. |
| Sem conexão ou acesso | Último estado conhecido, indicação de desatualização e ação de reconexão. | Falha de sincronização nunca se apresenta como zero pendências. |

Um pequeno indício no hover pode ajudar a descobrir que existe interação, mas não abriria o painel por padrão. Isso reduz aberturas acidentais ao alcançar a barra de menus.

A animação proposta é uma expansão contínua a partir do notch, para os lados e para baixo, em cerca de 220–280 ms, com amortecimento discreto. O conteúdo aparece após o início da expansão. Esses valores são um ponto de partida para validar, não uma medição nem uma duração obrigatória.

Enquanto a lista está aberta, novos eventos não devem reordenar os itens sob o ponteiro. Entram em uma fila, e a ordem é atualizada quando o usuário solicita ou reabre o painel.

## Significado dos contadores

Para preservar a ideia original, começaria com volume de itens abertos relacionados ao usuário. A atenção exigida aparece como um sinal secundário e como prioridade no painel. Depois podemos oferecer a preferência “contar apenas itens que precisam de mim”.

| Fonte | Padrão sugerido | Como explicar ao usuário |
|---|---|---|
| Jira | Itens atribuídos ao usuário e fora da categoria concluída. | “Atribuídos a mim”. Projeto, sprint e filtro salvo podem refinar a seleção. |
| GitHub | União de PRs abertos de autoria do usuário, atribuídos a ele ou com revisão solicitada. | Separar “Criei”, “Minha revisão” e “Atribuídos”; contar cada PR uma vez. Solicitações para equipes pedem uma opção própria. |

A Atlassian documenta `currentUser()`, responsável e categorias de status em [funções JQL](https://support.atlassian.com/jira-software-cloud/docs/jql-functions/) e [campos JQL](https://support.atlassian.com/jira-software-cloud/docs/jql-fields/). “Bloqueado” depende do fluxo da equipe e precisa de mapeamento; não deve ser presumido como status universal.

O GitHub distingue autoria, atribuição e revisão solicitada. O filtro `involves` também pode incluir menção e comentário e não substitui revisão pendente. A união de relações é uma proposta nossa, fundamentada nas [relações de pesquisa documentadas](https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests).

Draft, revisão e CI devem ser sinais independentes. “CI passou” não significa “aprovado” ou “pronto para merge”, conforme a distinção entre [filtros de PR](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/filtering-and-searching-issues-and-pull-requests) e [status checks](https://docs.github.com/en/pull-requests/reference/status-checks).

## Ideias com maior valor para engenheiros

1. **Minha próxima ação.** Destacar revisão solicitada, mudanças pedidas no meu PR e falha de CI. Deixar explícito quando algo aguarda outra pessoa. Critérios de urgência devem ser compreensíveis e ajustáveis.
2. **Card e PR conectados.** Ao selecionar um card, mostrar seus PRs relacionados. Começar por vínculos explícitos ou chave da tarefa no título/branch, indicando a origem da associação e permitindo correção. Não adivinhar relações por texto parecido.
3. **Ações de poucos segundos.** Abrir no Jira/GitHub, copiar link ou chave, adiar um lembrete e acompanhar um PR escolhido. “Revisar” abre a revisão no GitHub.
4. **Acompanhamento silencioso.** Um PR acompanhado pode informar quando CI termina ou chegam mudanças solicitadas. Sem contagem animada contínua, expansão automática ou alertas repetidos do mesmo evento.
5. **Retomar o trabalho.** Fixar o card atual com seus PRs e voltar a ele rapidamente depois de reuniões.
6. **Contextos profissionais.** Trocar entre organização/conta/projeto com identificação clara do contexto ativo. Evitar juntar trabalho pessoal e corporativo sem escolha explícita.
7. **Resumo para a daily.** Um resumo revisável de cards e PRs, com copiar texto; sem envio automático. Regras simples podem vir antes de qualquer recurso de IA.
8. **Privacidade manual imediata.** Um comando para esconder títulos e reter apenas contagens durante apresentação. Detecção automática de compartilhamento precisa de pesquisa e validação próprias.
9. **Lembrete de review envelhecido.** Lembrar de uma revisão adiada no horário escolhido, com limites para não criar uma segunda caixa de notificações.

Para uma primeira versão, priorizaria os três primeiros itens, sincronização confiável e acessibilidade. Acompanhar PR e adiar lembretes viriam logo depois. Merge, aprovação e mudança de status dentro do notch ficariam para uma discussão posterior, com contexto e tratamento de falhas adequados.

## Diretrizes visuais e acessibilidade

A região da câmera encobre conteúdo. Os controles precisam respeitar as [áreas seguras da tela](https://developer.apple.com/documentation/appkit/nsscreen/safeareainsets) e a [área visível lateral](https://developer.apple.com/documentation/appkit/nsscreen/auxiliarytopleftarea-uglc). Portanto, o clique deve funcionar nas áreas realmente visíveis ao lado ou abaixo da câmera.

O preto contínuo integra a interface ao recorte físico. Azul e violeta identificam provedores; âmbar/vermelho/verde ficam associados a estados com texto e símbolo. Não depender só de cor. Os estudos mostram uma direção escura intencional para fundir com o notch; preferências e outras janelas poderão acompanhar o tema do sistema.

A Apple documenta preferências de [diferenciação sem cor](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilitydifferentiatewithoutcolor) e [transições acessíveis](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilitypreferscrossfadetransitions). A experiência deve oferecer navegação por teclado, rótulos de VoiceOver, contraste legível e uma transição curta por opacidade quando houver redução de movimento.

Os três estudos estão ampliados para comparação de hierarquia e leitura. Proporção, altura, contraste e alvo de clique ainda precisam ser calibrados no Mac real; as imagens não fixam dimensões finais. Os pequenos detalhes de câmera desenhados em algumas imagens são ilustrativos, não conteúdo de interface a ser renderizado.

## Estudos visuais

Estudos independentes gerados pela ferramenta nativa de imagens com o esboço do usuário como referência. Ordem de apresentação no chat:

1. [Radar](notch-radar.png): grupos por origem, em duas colunas.
2. [Prioridade](notch-prioridade.png): uma fila curta com destaque para atenção exigida.
3. [Contexto](notch-contexto.png): navegação agrupada e um detalhe que aproxima tarefa e PR.

Os prompts completos foram preservados em [prompts-visuais.txt](prompts-visuais.txt). Nenhuma dessas imagens é um protótipo clicável ou uma prova de execução.

## Considerações técnicas para a etapa futura

Uma direção nativa com SwiftUI e AppKit é compatível com o tipo de superfície estudado. A Apple documenta um [painel sem ativar o app proprietário](https://developer.apple.com/documentation/appkit/nswindow/stylemask-swift.struct/nonactivatingpanel); isso fundamenta pesquisar uma consulta que preserve o contexto do editor. Foco de teclado e clique externo ainda exigem implementação e validação.

Telas, Spaces, Stage Manager e fullscreen são parte do produto. A documentação de [CollectionBehavior](https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct) e [NSScreen.screens](https://developer.apple.com/documentation/appkit/nsscreen/screens) dá mecanismos, sem garantir um resultado em qualquer combinação. Proponho escolher monitor do Mac/monitor específico, ter alternativa em monitor sem notch e permitir ocultação em fullscreen. Integração com outros apps que já ocupam o notch também precisa ser avaliada.

O [changelog de DynamicLake](https://www.dynamiclake.com/changelog) anuncia suporte inicial ao macOS 27. Isso é uma declaração do fornecedor sobre o produto dele. Nenhuma compatibilidade do nosso conceito foi validada no macOS 27.

Na conexão futura, usar autenticação oficial, permissões mínimas e armazenamento adequado do sistema. A disponibilidade de conectores nesta conversa não conecta automaticamente o futuro app às contas. Jira Cloud/Data Center, GitHub.com/Enterprise e exigências de SSO precisam ser confirmados na etapa de integração.

## Registro de cobertura e validações pendentes

| Pergunta | Estado | Evidência ou limite |
|---|---|---|
| Quais padrões outros apps oferecem? | Respondida documentalmente | Fontes oficiais listadas, com pré-releases e material histórico identificados. |
| O que o pacote inspecionado demonstra? | Respondida no escopo estático | Inventário e plist REA; sem inferência de fluidez a partir do pacote. |
| Qual região da tela pode receber conteúdo? | Respondida documentalmente | Áreas seguras e regiões laterais da Apple. |
| O que significa “relacionados a mim”? | Proposta fundamentada | Relações documentadas; padrão final depende de decisão de produto. |
| Qual direção visual seguir? | Aberta para discussão | Três imagens apresentadas. |
| Funciona bem no Mac com macOS 27? | Pendente | Sem implementação ou execução. |
| Dados reais, autenticação e sincronização funcionam? | Pendente | Nenhuma conta acessada ou integrada. |

Na etapa de implementação, validar manualmente: tamanho e clique nas áreas laterais; abrir/fechar repetidamente; retorno ao editor; Esc e navegação por teclado; VoiceOver; redução de movimento e transparência; light/dark mode; monitor externo e conexão/desconexão; Spaces/Stage Manager/fullscreen; coexistência com outro app de notch; contadores sem duplicidade; lista vazia; 99+ itens; offline, acesso expirado e revogado; atualização sem reordenar sob o ponteiro; latência e consumo em repouso.

Nenhum código do aplicativo foi criado ou alterado. Não foram criados testes, arquivos de teste ou mocks de código. Os dados das imagens são fictícios. Build, lint, testes e validações de runtime não foram executados.

