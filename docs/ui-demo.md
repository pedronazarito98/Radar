# Radar Demo — validação de UI/UX

O pedido de 27/10/2026 autoriza mocks locais (AD-022). A cópia existente em `/Users/pedronazarito/Developer/Radar` estava limpa e alinhada a `origin/main` em `d6fb14e`; foi reutilizada na branch `feat/radar-ui-demo`.

## Abrir

```sh
cd /Users/pedronazarito/Developer/Radar
./script/build_and_run.sh --demo
```

O comando compila e abre `.build/DemoDerivedData/Build/Products/Debug/RadarDemo.app`. Depois do primeiro build, pode abrir esse app diretamente pelo Finder, sem argumentos: o bundle `dev.pedronazarito.Radar.demo` seleciona o modo demo. O Radar normal usa o bundle original e não ativa mocks por padrão. Também é possível executar o binário normal com `--demo` deliberadamente.

O demo começa compacto com contadores 5/5. Clique no notch ou em **Radar Demo → Abrir ou recolher Radar**. Se os dois apps estiverem abertos sobre o mesmo notch, encerre um pelo próprio menu para avaliar a superfície sem sobreposição.

## Cenários

Escolha pelo menu **Cenários de demonstração** ou pela janela **Configurações** do Radar Demo. A troca limpa a seleção e abre a visão geral do cenário.

| Cenário | Conteúdo e o que observar |
|---|---|
| Dia de trabalho | 5 cards, 5 PRs pessoais, 3 repositórios e um PR contextual. Status Jira diferentes; autoria, atribuição, revisão e rascunho. |
| Tudo em dia | Zero confirmado nas duas origens, distinto de falta de consulta. |
| Carregando | Contadores desconhecidos e consulta pendente até trocar de cenário. |
| Falha de rede | Listas antigas preservadas, aviso de desatualização e erro nos detalhes. |
| Acesso parcial | 5+ nas origens, vínculos parciais e CI/revisão indisponíveis por permissão. |
| Reconectar GitHub | Jira preenchido enquanto GitHub pede requalificação. |
| Muitos itens · 99+ | 110 cards e 105 PRs, títulos longos e rolagem independente. Os rótulos acessíveis conservam os totais exatos. |

## Fluxo para validar

1. Em **Dia de trabalho**, selecione **RAD-241**. A faixa carrega por cerca de 450 ms e mostra três relações com proveniência de título/branch.
2. Abra a relação **radar-demo/api #24**. É contextual, fora da lista pessoal: o total GitHub permanece 5. Selecione RAD-241 na faixa para retornar ao card.
3. Selecione os PRs: **#81** traz CI aprovado e aprovação; **#82**, CI em andamento e sua revisão direta; **#23**, falha e alterações solicitadas; **#14**, rascunho sem checks; **#15**, resultados mistos e nenhum vínculo.
4. Com um detalhe selecionado, clique em **Simular atualização dentro do painel**. RAD-246 e a nova ordem dos PRs ficam pendentes; a seleção e o total apresentado continuam iguais. Clique em **Aplicar atualização**: Jira passa a 6 e o PR selecionado mantém a identidade. Fechar/reabrir também aplica o snapshot pendente.
5. Alterne rapidamente entre card e PR durante o carregamento. O detalhe final deve corresponder à última seleção. Esc fecha o detalhe; outro Esc recolhe o painel. Confira Tab, setas, Enter e retorno de foco.
6. Percorra os demais cenários e o conteúdo rolável de detalhes. Confira legibilidade, truncamento, contraste, VoiceOver e Reduzir Movimento no seu ambiente.

A ação de atualização no menu abre o painel e prepara dados, mas abrir o menu externo recolhe o painel conforme o comportamento normal. Use o botão **dentro do painel** para validar a preservação da seleção durante uma atualização.

## Interação do notch (C10)

1. Com uma janela rolável atrás, abra pelo centro do notch e pelas margens das asas, longe dos ícones. O primeiro clique deve abrir; repetir o clique mantém aberto.
2. Em **Muitos itens · 99+**, inicie gestos novos sobre cada lista e chegue ao fim. Só a lista apontada deve rolar; a janela atrás deve ficar imóvel. Repita com trackpad e roda de mouse.
3. Role e clique no cabeçalho, divisor e espaços vazios. O Radar deve continuar aberto. Confira também clique secundário.
4. Selecione um item; Esc fecha os detalhes e outro Esc recolhe. O botão Recolher também deve recolher sem reabrir.
5. Clique fora: o Radar recolhe e o destino clicado mantém o foco. No modo compacto, a antiga região expandida deve estar livre para a janela atrás.

O recorte físico permanece sem controles; o centro preto agora faz parte do alvo de abertura. Cantos transparentes ficam fora do alvo. Gestos com momentum iniciados em outro app antes de mover o ponteiro podem continuar vinculados ao destinatário original pelo macOS; avalie a contenção iniciando o gesto sobre o Radar.

Resultados e limites: [C10](evidence/C10.md).

## Isolamento e limites

- Dados de demonstração são construídos com os tipos reais de domínio e publicados pelos stores existentes. Vínculos usam o extrator real de chaves; CI/revisão usam os agregadores existentes.
- Rede, OAuth, Keychain, persistência real e polling de integrações não iniciam no modo demo. As preferências são efêmeras. Configurações do demo mostram cenários, sem ações de conta.
- Abrir/copiar links fica desativado, pois os destinos são fictícios. Nenhum conteúdo de clipboard é consultado.
- O build demo usa diretório, nome e bundle ID separados. O script só encerra a instância do caminho que está reconstruindo; não encerra o Radar normal ao executar `--demo`.
- Não foram criados testes automatizados, arquivos de teste, dependências ou simulações de serviços remotos. Esta entrega contém mocks de apresentação autorizados.
- Validação com esses dados não comprova autenticação, APIs reais, desempenho com rede, notarização ou uso em outro Mac. Resultados desta entrega ficam em [M01](evidence/M01.md).
