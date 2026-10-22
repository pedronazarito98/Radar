# Radar — fluxos visuais de Jira e GitHub

22/10/2026 · oito pranchas · dezoito quadros de estado · estudo estático.

Esta entrega mostra os caminhos de entrada, consulta, relação card–PR, saída e recuperação do Radar. A base visual é a revisão 3 aprovada na conversa. Nenhum aplicativo foi implementado e nenhuma conta foi conectada.

## Pranchas

| Prancha | Imagem | Quadros |
|---|---|---|
| 01 | [Conectar contas](01-conectar-contas.png) | Primeiro acesso; Jira conectado e GitHub pendente. |
| 02 | [Do notch à visão geral](02-notch-visao-geral.png) | Notch fechado no uso normal; primeira consulta; visão geral carregada. |
| 03 | [Jira: do card aos PRs](03-jira-card-prs.png) | Selecionar ENG-241 e consultar detalhes; relações carregadas e ações disponíveis. |
| 04 | [Jira: vazio e recuperação](04-jira-vazio-recuperacao.png) | Card sem PR identificado; falha de atualização com dados anteriores. |
| 05 | [GitHub: do PR ao card](05-github-pr-card.png) | PR #182 selecionado e seus estados; navegação para as conexões de ENG-241. |
| 06 | [GitHub: CI e revisão](06-github-ci-revisao.png) | PR #179 com CI falhando e mudanças solicitadas; PR #181 com CI bem-sucedido aguardando revisão. |
| 07 | [Reconexão e estados vazios](07-reconexao-estados-vazios.png) | GitHub com acesso expirado e Jira disponível; cenário separado com consulta concluída sem itens. |
| 08 | [Abrir, voltar e recolher](08-abrir-voltar-recolher.png) | Abrir o item no serviço; notch recolhido; retorno à visão geral. |

As legendas e as margens das pranchas são documentação do fluxo, não elementos do aplicativo. Os estados vazios e de erro são exemplos alternativos, não uma afirmação de que todos os usuários passarão por eles em sequência.

## Leitura do caminho inicial

1. Abrir o notch e conectar Jira e GitHub na prancha 01. A autenticação continua no navegador; as telas de autenticação dos provedores não foram redesenhadas.
2. Voltar à primeira consulta da prancha 02. Sem valores conhecidos, os indicadores usam traço; carregamento não é zero.
3. Depois da consulta, a visão geral mostra os grupos e totais.
4. O quadro compacto da prancha 02 representa o uso normal após uma sincronização bem-sucedida: painel fechado com seus dois indicadores.

A disposição da prancha 02 começa pelo notch fechado como apresentação do estado padrão. A ordem temporal do primeiro acesso é conectar → consultar → apresentar dados → recolher.

## Fluxo Jira

Visão geral → selecionar um card → faixa de conexões → consultar CI/revisão → abrir PR/revisão ou continuar pelo Jira.

- Ao escolher ENG-241, a faixa fica abaixo das duas listas. As contagens globais permanecem Jira 4 e GitHub 3.
- As relações conhecidas podem permanecer visíveis enquanto seus detalhes são consultados. A prancha 03 mostra esse carregamento com informação parcial, seguido do resultado.
- A faixa identifica acme/web #182 e acme/api #181, com repositório e número. A origem do vínculo é indicada no rodapé.
- Selecionar ENG-232 na prancha 04 mostra uma consulta concluída sem PR identificado naquele escopo. Há ações de abrir o card e copiar sua chave.
- Se a atualização de ENG-241 falhar, a prancha 04 mantém os dados anteriores identificados como desatualizados e oferece Tentar novamente.
- A recuperação bem-sucedida retorna ao estado carregado da prancha 03. Ela não cria vínculos nem altera o status do Jira.

## Fluxo GitHub

Visão geral → selecionar PR → consultar estado do PR, CI e revisão → acessar card relacionado ou abrir o trabalho no GitHub.

- Na prancha 05, #182 apresenta Estado do PR, CI e Revisão como informações separadas.
- Ver conexões é uma ação de navegação dentro do Radar: seleciona o card relacionado e mostra os PRs desse card na mesma faixa.
- Abrir revisão, Abrir PR e Ver checks continuam no serviço correspondente. São propostas de navegação, não aprovação, merge ou alteração de código.
- A prancha 06 mostra que CI falhando e mudanças solicitadas podem coexistir. Outra seleção mostra CI concluído e revisão ainda aguardada.
- A identidade de cada PR considera repositório e número. #181 e #182 não são tratados como identificadores globais isolados.

## Recuperação e ausência de itens

A prancha 07 separa dois cenários:

- Acesso do GitHub expirado: Jira permanece disponível. O último total conhecido do GitHub continua identificado com aviso, e os dados são marcados como desatualizados. Reconectar GitHub retoma a conexão e depois a consulta.
- Consulta bem-sucedida sem itens: zero é um resultado conhecido. As duas colunas mantêm sua identidade, com mensagens de ausência de cards/PRs e ações de abertura nos provedores.

O cenário de zero não acontece por selecionar ou desmarcar um card. Ele corresponde a outro conjunto de dados consultado com sucesso. Avisos de um serviço não transformam automaticamente os dados do outro em falha.

## Saída e retorno

A prancha 08 ilustra a proposta de uma ação externa recolher o painel, preservando os indicadores compactos. O navegador continua o trabalho em Jira/GitHub. O desenho não representa esses websites nem uma conexão real com os serviços.

Para tornar a sequência concreta, a reabertura foi ilustrada na visão geral. A decisão anterior entre sempre reabrir na visão geral ou retomar a última seleção continua pendente; esta imagem não registra uma escolha do usuário.

O retorno por teclado proposto é: Esc fecha os detalhes; outro Esc recolhe o painel. Clique fora fecha o painel inteiro. São comportamentos desenhados para discussão e ainda não foram implementados.

## Identidade preservada

- Superfície preta ligada visualmente ao notch, com papel de parede azul acinzentado.
- Jira à esquerda, GitHub à direita e faixa de contexto abaixo das duas colunas.
- Indicadores Jira/GitHub com suas cores de origem.
- Seleção e agrupamento em tons neutros, sem barras coloridas na esquerda.
- Repositórios com ícones e selos WEB/API, acompanhados dos nomes.
- Tipografia de aparência nativa, divisórias discretas e hierarquia da revisão 3.
- CI e revisão com texto, posição e símbolo, além da cor.
- Totais pessoais separados das quantidades de vínculos do item selecionado.

As imagens são ilustrações de estados. Pequenas variações de proporção, glifos, quebras de linha e acabamento entre quadros não estabelecem novos tokens ou componentes. O alvo visual de referência continua sendo a revisão 3; dimensões finais e animações precisam de um protótipo autorizado.

## O que foi criado e conferido

Oito PNGs foram gerados pela ferramenta nativa de imagens, cada um recebendo a referência visual da revisão 3. Cada prancha representa estados do mesmo produto, não uma alternativa visual.

Os arquivos foram salvos localmente e suas assinaturas/dimensões de PNG, referências do roteiro e integridade do pacote ZIP foram conferidas. Também foi realizada inspeção visual das imagens retornadas: os caminhos principais estão representados e as barras coloridas laterais não foram reintroduzidas.

Os prompts completos constam em [prompts.txt](prompts.txt). Os dados, organizações, repositórios e relações das imagens são fictícios. Categorias de repositório são exemplos visuais.

Não houve criação ou alteração de código do aplicativo, instalação, acesso a contas, aprovação de PR, merge, alteração de card, build, lint, testes ou verificação de runtime. A cobertura desta entrega é visual, com os caminhos e cenários listados; ela não comprova funcionamento nem pretende enumerar todas as possíveis regras de Jira/GitHub.

## Próxima revisão manual

Revisar a continuidade das seleções e ações: visão geral → card → PR; visão geral → PR → card; falha → tentar novamente; abrir no serviço → voltar. Conferir legibilidade dos status e se o tamanho da faixa inferior continua confortável.

A implementação e a validação no Mac real continuam fora desta etapa.

