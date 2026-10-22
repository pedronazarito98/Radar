# Radar — ajustes visuais 3

22/10/2026 · estudo estático · etapa de discussão.

[Visual atualizado](notch-radar-conexoes-v3.png). Esta revisão parte do [estudo de comportamentos 2](radar-conexoes-comportamentos-v2.md) e altera a apresentação conforme os comentários do usuário. A disposição das informações, as duas colunas e a faixa inferior foram preservadas.

## Feedback incorporado

| Comentário do usuário | Tratamento |
|---|---|
| Aprovação da distinção entre contagem pessoal e conexões do card | Regra mantida: selecionar um item não altera os totais globais. Um PR exibido em duas áreas não é contado duas vezes. |
| Pedido de diferenciação visual entre repositórios | Proposta de ícone de tipo e selo textual discreto, sempre acompanhados do nome do repositório. |
| Pedido de diferenciar bem os status | A faixa passa a separar visualmente as colunas CI e Revisão, com rótulos e ícones próprios. |
| Aprovação de estados distintos de consulta | Mantidos consultando, consulta concluída sem vínculos e falha de consulta como situações diferentes. |
| Rejeição da borda esquerda colorida | Barras azuis e violetas removidas das linhas. Seleção passa a usar fundo cinza suave e identificação textual do vínculo. |

A aprovação da organização não representa autorização para implementar. As escolhas específicas de ícones, categorias e cores deste refinamento continuam sendo propostas visuais.

## Seleção e relações

- Card selecionado: fundo cinza discreto, com tipografia legível.
- Relação com PR: chave da tarefa e ícone do Jira junto ao item, com o contexto explícito na faixa inferior.
- Nenhuma barra colorida ou contorno luminoso na esquerda das linhas.
- Demais itens mantêm posição e legibilidade.
- Indicadores das fontes preservam as cores de Jira e GitHub.

A seleção não depende de uma borda lateral. Em uma futura interface, foco de teclado também precisará de tratamento próprio, distinto da seleção. Isso ainda não foi implementado.

## Repositórios

A proposta utiliza ícones monocromáticos com nomes e selos de tipo:

| Exemplo fictício | Tratamento visual |
|---|---|
| acme/web | Ícone de janela e selo WEB. |
| acme/api | Ícone de servidor e selo API. |
| Um repositório de infraestrutura, em uma evolução | Ícone de camadas e selo INFRA, seguindo a mesma linguagem discreta. |

O nome org/repositório é a identidade textual e continua visível. O tipo não identifica sozinho um repositório: dois serviços API podem compartilhar o mesmo ícone e continuam distinguíveis pelo nome.

O ícone do repositório se repete na lista GitHub e na faixa de conexões. Na imagem, os selos WEB/API aparecem na lista e os glifos correspondentes reaparecem na faixa.

As categorias são ilustrativas neste estudo, com dados fictícios. Não se presume que nomes de repositórios revelem automaticamente sua função. Uma classificação real precisará de uma definição explícita, e repositórios sem categoria podem usar um ícone genérico com seu nome.

Os selos de repositório usam tons neutros. Verde, âmbar e vermelho ficam disponíveis para comunicar estados, sempre com texto e símbolos.

## Hierarquia dos status

A faixa de conexões tem os títulos Repositório · PR, CI, Revisão e Ação. A posição e o título de cada coluna estabelecem a dimensão antes do conteúdo.

| Informação | Proposta visual |
|---|---|
| CI passou | Check verde e texto Passou na coluna CI. |
| CI falhou | X vermelho e texto explícito CI falhou quando fora da coluna rotulada. |
| CI em andamento | Indicador de progresso e texto Em andamento, se esse estado estiver disponível. |
| Sua revisão | Ícone de pessoa/revisão, âmbar e texto Sua revisão. |
| Aguardando revisão | Relógio, tom neutro e texto Aguardando revisão. |
| Revisão aprovada | Ícone de revisão com confirmação e rótulo Aprovado; continua pertencendo à dimensão Revisão. |
| Estado do card Jira | Seu próprio rótulo na coluna Jira, com o status do fluxo da equipe. |
| Fase do PR | Draft, Aberto, Merged ou Fechado são uma dimensão própria, a detalhar quando necessária. Não substituir CI ou revisão por uma cor agregada. |

O exemplo visual apresenta CI bem-sucedido nas duas conexões, enquanto a responsabilidade pela revisão difere. A lista GitHub também mostra um terceiro PR com CI falhando para comparar as famílias de status.

Ícones, títulos de coluna e rótulos permitem leitura além da cor. A forma exata dos glifos é uma proposta; o desenho final deve preservar a distinção entre status e controles clicáveis.

## Contagens e consulta

As regras aprovadas permanecem:

- GitHub 3 é a contagem da lista pessoal.
- 2 PRs é a quantidade de conexões do card selecionado no escopo consultado.
- Seleção não muda filtros nem totais.
- Consultando não se apresenta como zero.
- Nenhum vínculo identificado exige uma consulta concluída no escopo indicado.
- Erro oferece explicação e nova tentativa, preservando a distinção em relação ao estado vazio.
- Dados incompletos ou desatualizados recebem identificação própria.

A imagem mostra somente uma consulta bem-sucedida; estados de carregamento, vazio e erro estão definidos no documento, mas não foram desenhados nesta imagem.

## Escopo e validação

A revisão criou somente uma imagem, este documento e o prompt correspondente. Nenhum código do aplicativo foi criado ou alterado. Nenhuma integração, ação de Jira/GitHub ou instalação foi realizada.

A imagem foi inspecionada visualmente: as barras laterais foram removidas, os repositórios ganharam identificação e CI/Revisão receberam cabeçalhos separados. Arquivos e referências locais foram conferidos. Não foram executados build, lint, testes ou interações de runtime.

Na revisão manual do desenho, avaliar:

1. O fundo neutro deixa a seleção perceptível?
2. Os repositórios são reconhecíveis pelo ícone, tipo e nome?
3. CI e Revisão são distinguíveis sem depender somente de verde/âmbar?
4. Os novos ícones e selos mantêm a leveza e a leitura das linhas?

A decisão anterior sobre reabrir na visão geral ou retomar o último card continua em aberto.

[Prompt da edição](prompt-radar-conexoes-v3.txt). Ferramenta utilizada: geração/edição de imagens nativa, com a imagem da revisão 2 como referência direta. Dados fictícios; sem protótipo funcional.

