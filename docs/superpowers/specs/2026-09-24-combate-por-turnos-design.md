# Combate por turnos no Campo de Treino (design)

**Data:** 2026-09-24
**Engine:** Godot 4.7.2
**Depende de:** MVP cidade + personagem (`2026-09-24-mvp-cidade-personagem-design.md`)
**Status:** aprovado e implementado (plano: `docs/superpowers/plans/2026-09-24-combate-por-turnos.md`)

## 1. Objetivo

Dar ao jogador a primeira coisa para **fazer**: lutar. Clicar no **Treino** abre uma lista de inimigos. O jogador escolhe um e entra num combate por turnos, herói contra inimigo. Ao vencer, ganha XP e ouro e pode subir de nível. As fórmulas de ataque, defesa, crítico e velocidade do MVP passam a ter efeito de verdade.

**Critério de sucesso:** partindo da cidade, o jogador clica em Treino, escolhe "Rato Gigante", vence usando Atacar e Bola de Fogo e volta à cidade. O HUD mostra o XP e o ouro novos. Vencer inimigos suficientes sobe o herói para o nível 2, e o painel do Personagem mostra os status recalculados. Os testes automatizados passam.

### Decisões aprovadas
| Tema | Decisão |
|---|---|
| Controle | Manual: a cada rodada o jogador escolhe a ação do herói |
| Tamanho | 1 contra 1 |
| Recompensa | XP e ouro ao vencer, com subida de nível; **não salva** (perde ao fechar o jogo) |
| Entrada | Construção **Treino**; as outras continuam "em breve" |

### Decisões propostas (revisar)
| Tema | Proposta | Motivo |
|---|---|---|
| Ações do herói | Atacar, Bola de Fogo, Defender, Fugir | Dá escolha tática sem criar mana |
| Recurso da habilidade | Recarga de 3 rodadas, sem mana | Um recurso a menos para exibir e balancear |
| Ordem dos turnos | Por rodada: quem tem mais velocidade age primeiro (empate: herói) | Faz a velocidade importar e é fácil de prever |
| HP entre combates | No Treino o HP **volta ao máximo** ao fim de cada combate | Sem cura nem descanso no jogo, o HP gasto prenderia o jogador. O desgaste de HP entra com a Torre |
| Derrota | Sem penalidade: não ganha nada e volta à cidade | É treino |
| Inimigo | Sempre ataca (IA mínima) | Suficiente para o 1×1; a IA cresce depois |
| Subir de nível | Só o `level` sobe; atributos não mudam | As fórmulas já crescem com o nível; distribuir pontos está fora do escopo |
| Inimigos | 3 no Treino, definidos em JSON (seção 4) | Mesmo padrão validado do herói; pronto para vir do servidor |

### Fora do escopo
Salvar o progresso, mana, vários inimigos ou escolha de alvo, aliados e formação, Arena/PvP, combate automático, itens e drops, equipamentos alterando status, distribuição de pontos, a Torre, animações além do número de dano, e som.

## 2. Arquitetura

Mesma regra do MVP: as regras do combate ficam em `domain/`, sem nós, e poderiam rodar num servidor. A UI só mostra e repassa a escolha do jogador.

```
domain/
├── combatant.gd        Combatant: nome, hp, max_hp, attack, defense, crit_chance, speed
├── enemy.gd            Enemy: definição de um inimigo (dados do JSON + recompensas)
├── dice.gd             Dice: sorteios do combate (crítico e variação). Trocável em testes
├── battle_action.gd    BattleAction: enum ATTACK, SKILL, DEFEND, FLEE
├── battle_event.gd     BattleEvent: uma linha do que aconteceu (quem, o quê, dano, crítico)
├── battle.gd           Battle: estado do combate e play_round(acao) -> Array[BattleEvent]
├── progression.gd      Progression: aplica XP e sobe níveis (funções puras)
└── stat_formulas.gd    + damage(...), SKILLS
data/
├── enemies.json
├── enemy_repository.gd        interface: load_enemies() -> EnemyLoadResult
├── enemy_load_result.gd
└── local_enemy_repository.gd  lê e valida o JSON
game/game_state.gd             + enemies, apply_battle_result(battle)
ui/
├── training/training_panel.gd lista de inimigos (janela)
└── battle/battle_screen.gd    tela do combate
```

### Fluxo
```
Treino (clique) → TrainingPanel (GameState.enemies) → "Lutar"
  → BattleScreen cria Battle(Combatant.from_hero(hero), Combatant.from_enemy(enemy), Dice.new())
  → a cada ação: battle.play_round(acao) → eventos → a tela exibe um por um
  → fim: GameState.apply_battle_result(battle) → player_changed → HUD e painel se redesenham
```

- `Battle` **não conhece** o `Player`. Trabalha com duas cópias `Combatant` e só informa o resultado (`VICTORY`, `DEFEAT`, `FLED`) e o inimigo vencido.
- Quem altera o `Player` é o `GameState.apply_battle_result()`, a primeira "ação" do jogo, como a spec do MVP previa.
- Sorteio injetado: `Battle` recebe um `Dice`. Nos testes, `FixedDice` (em `tests/fakes/`) devolve valores escolhidos, e o combate fica determinístico.

## 3. Regras do combate

### Rodada
1. O jogador escolhe uma ação.
2. **Fugir** e **Defender** têm prioridade: valem antes de qualquer ataque da rodada.
   - Fugir encerra o combate na hora (`FLED`), sempre com sucesso.
   - Defender reduz à metade o dano que o herói recebe **nesta rodada**.
3. Os ataques acontecem em ordem de velocidade (maior primeiro; empate: herói primeiro). Se o primeiro derrubar o outro (HP 0), o segundo não age.
4. HP do inimigo 0 → `VICTORY`. HP do herói 0 → `DEFEAT`.
5. A recarga da Bola de Fogo diminui 1 no fim da rodada.

### Dano (`StatFormulas.damage`)
```
base   = max(1, ataque_do_atacante − floor(defesa_do_alvo ÷ 2))
dano   = base × multiplicador_da_acao × variacao × (1,5 se crítico) × (0,5 se o alvo defende)
final  = max(1, floor(dano))
```
- `variacao`: sorteada entre 0,9 e 1,1 (`Dice.variance()`).
- Crítico: `Dice.roll_percent() < crit_chance` do atacante.
- Multiplicador: Atacar = 1,0; Bola de Fogo = 1,6.

### Habilidades (`StatFormulas.SKILLS`, por classe)
| Classe | Habilidade | Multiplicador | Recarga |
|---|---|---|---|
| `mage` | Bola de Fogo | 1,6 | 3 rodadas (usada na rodada 1, volta na rodada 4) |

### Progressão (`Progression`)
- `apply_xp(hero, ganho)`: soma o XP. Enquanto `xp >= xp_to_next_level(level)`, desconta esse valor e sobe 1 nível. Devolve quantos níveis subiu.
- Ouro: somado ao `Player.gold`.
- Ao fim de qualquer combate, `current_hp = max_hp` (já com o nível novo).

Exemplo: Aldric (nível 1, XP 35) vence o Lobo (+45) e fica com XP 80/100. Depois vence o Rato (+20) e chega a 100. Aí sobe para o nível 2 com XP 0/283.

## 4. Inimigos

### Formato (`data/enemies.json`)
Os inimigos têm status prontos, sem atributos, para facilitar o balanceamento.
```json
{
  "enemies": [
    { "id": "giant_rat", "name": "Rato Gigante", "level": 1,
      "max_hp": 80,  "attack": 20, "defense": 6,  "crit_chance": 2, "speed": 95,
      "rewards": { "xp": 20, "gold": 15 } },
    { "id": "wolf", "name": "Lobo", "level": 2,
      "max_hp": 140, "attack": 30, "defense": 10, "crit_chance": 5, "speed": 112,
      "rewards": { "xp": 45, "gold": 30 } },
    { "id": "ogre", "name": "Ogro", "level": 4,
      "max_hp": 320, "attack": 45, "defense": 20, "crit_chance": 5, "speed": 90,
      "rewards": { "xp": 120, "gold": 80 } }
  ]
}
```

Balanceamento de referência contra o Aldric nível 1 (ataque 29, defesa 17, HP 240, velocidade 108), sem variação nem crítico:

| Inimigo | Dano do Aldric (Atacar / Bola) | Dano recebido por rodada | Resultado esperado |
|---|---|---|---|
| Rato Gigante | 26 / 41 | 12 | Fácil (≈3 rodadas) |
| Lobo (mais rápido que o herói) | 24 / 38 | 22 | Médio, perde ≈100 de HP |
| Ogro | 19 / 30 | 37 | Perde no nível 1; objetivo para depois de subir de nível |

### Validação (`LocalEnemyRepository`, mesmo estilo do `LocalHeroRepository`)
Arquivo inexistente ou malformado; `enemies` ausente, vazio ou que não é lista; campo obrigatório ausente ou com tipo errado; `id` repetido; `level < 1`, `max_hp < 1`; `attack`, `defense`, `speed`, `crit_chance` ou recompensas negativos. Qualquer falha invalida o arquivo inteiro e gera uma mensagem de erro descritiva.

Se os inimigos não carregarem, o jogo continua funcionando. O `GameState` guarda `enemies = []` e `enemies_error`, e o painel do Treino mostra "Erro ao carregar inimigos".

## 5. Interface

### Painel do Treino (`TrainingPanel`, na `WindowLayer`)
- Mesmo estilo e comportamento do painel do Personagem: fundo escurecido, fecha no ✕, com Esc ou clique fora.
- Título "Campo de Treino". Uma linha por inimigo: nome, "Nv X", recompensas ("+20 XP · +15 ouro") e botão **Lutar**.
- Inimigo de nível maior que o do herói: nível em vermelho (aviso, sem bloquear).
- Clicar em Treino sem herói carregado mostra o Toast de erro e não abre o painel.

### Tela de combate (`BattleScreen`, nova `BattleLayer`, layer 3)
Cobre a tela inteira com fundo opaco, então a cidade, o HUD e a barra ficam por baixo e não recebem cliques.

```
┌──────────────────────────────────────────────────────────┐
│                     Rodada 3                              │
│   [Aldric]                               [Rato Gigante]   │
│   Nv 1  HP ███████░░ 216/240             Nv 1  HP ██░ 28/80│
│   (figura)        -26                    (figura)         │
│                                                           │
│   ┌ registro (últimas 5 linhas) ─────────────────────┐    │
│   │ Aldric ataca Rato Gigante: 26 de dano.           │    │
│   │ Rato Gigante ataca Aldric: 12 de dano.           │    │
│   └──────────────────────────────────────────────────┘    │
│   [Atacar] [Bola de Fogo (2)] [Defender] [Fugir]          │
└──────────────────────────────────────────────────────────┘
```

- Herói à esquerda e inimigo à direita. Figura: arte se existir, senão um placeholder (retângulo com a inicial, como o retrato do HUD).
- Os eventos da rodada aparecem **um por um**, com intervalo de `event_delay` segundos (padrão 0,5; os testes usam 0). Cada evento atualiza a barra de HP, escreve no registro e mostra o número de dano subindo e sumindo sobre o alvo ("CRÍTICO!" em dourado).
- Os botões ficam desativados enquanto os eventos são exibidos. A Bola de Fogo em recarga mostra quantas rodadas faltam: "Bola de Fogo (2)".
- Esc não faz nada no combate; para sair, use Fugir.
- **Fim do combate:** uma caixa central com o resultado.
  - Vitória: "Vitória!", "+20 XP", "+15 ouro" e, se subiu, "Subiu para o nível 2!".
  - Derrota: "Derrota" e "Você foi derrotado. Treine e tente de novo."
  - Fugiu: não mostra a caixa; volta direto à cidade com o Toast "Você fugiu do combate".
  - Botão **Voltar à cidade**: chama `GameState.apply_battle_result(battle)` e fecha a tela. As recompensas entram no clique, então o HUD atualiza ao voltar.

Todos os textos novos vão para `Texts`.

### Ligações em `main.gd`
- `building_clicked("training")` → abre o `TrainingPanel`. As outras construções continuam "em breve".
- `TrainingPanel.fight_pressed(enemy)` → fecha o painel e chama `BattleScreen.start(enemy)`.
- `BattleScreen.finished(outcome)` → se `FLED`, mostra o Toast.

## 6. Tratamento de erros

- `enemies.json` inválido não derruba o jogo (seção 4).
- `Battle.play_round()` com o combate já terminado, ou Bola de Fogo em recarga, não faz nada e devolve uma lista vazia. A UI não deixa isso acontecer, mas o domínio se protege.
- `apply_battle_result()` sem herói carregado ou com combate não terminado: `push_error` e nada muda.

## 7. Testes

Mesmo executor (`tests/run_tests.gd`) e `BaseTest`. Fakes novos: `FixedDice` (sorteios escolhidos) e `FixedEnemyRepository`/`FailingEnemyRepository`.

- **`test_damage`**: exemplos da tabela da seção 4; dano mínimo 1; crítico ×1,5; defesa ×0,5; variação nos extremos 0,9 e 1,1; arredondamento para baixo.
- **`test_battle`**: o mais rápido age primeiro (Lobo antes do Aldric); empate favorece o herói; quem cai não age; Defender vale mesmo quando o herói é mais lento; Fugir encerra sem o inimigo agir; recarga da Bola de Fogo (usada na 1, bloqueada na 2 e na 3, livre na 4); vitória e derrota; `play_round` depois do fim devolve vazio; o `Hero` original não é alterado.
- **`test_progression`**: ganho sem subir; subir exatamente no limite; subir 2 níveis de uma vez; XP que sobra é mantido.
- **`test_local_enemy_repository`**: exemplo válido carrega os 3; cada regra de validação da seção 4 (com fixtures).
- **`test_game_state`** (acréscimos): vitória soma XP e ouro e emite `player_changed`; derrota e fuga não dão nada; HP volta ao máximo; falha dos inimigos preenche `enemies_error`.
- **`test_training_panel`**: clicar em Treino abre o painel com 3 inimigos; aviso vermelho de nível; Esc e ✕ fecham; Lutar abre o combate; outras construções continuam "em breve"; erro de inimigos mostra a mensagem.
- **`test_battle_screen`** (com `event_delay = 0` e `FixedDice`): Atacar reduz a barra do inimigo e escreve no registro; botões desativados durante os eventos; Bola de Fogo mostra a recarga; vitória mostra as recompensas e "Voltar à cidade" atualiza o HUD; Fugir volta com Toast; a tela bloqueia cliques na cidade.

## 8. Lista de artes (opcional)

| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `assets/battle/background.png` | 1280×720 | Fundo do combate (campo de treino) |
| `assets/enemies/giant_rat.png`, `wolf.png`, `ogre.png` | até 220×250, transparente | Inimigos virados para a esquerda |

Ícones nos botões de ação ficaram para depois: os botões são só texto.

O herói usa o `assets/portraits/mage_full.png` que já está na lista, virado para a direita. O `assets/README.md` recebe essas linhas.
