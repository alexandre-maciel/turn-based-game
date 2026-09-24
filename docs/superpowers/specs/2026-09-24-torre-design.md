# Torre de andares (design)

**Data:** 2026-09-24
**Engine:** Godot 4.7.2
**Depende de:** combate por turnos e salvar progresso
**Status:** implementado com as propostas abaixo; revisar a seção 1

Nota de implementação: no código, o andar se chama `floor_number` (`floor` é função do GDScript). No JSON continua `"floor"`.

## 1. Objetivo

A Torre é o primeiro desafio de verdade: o jogador sobe andar por andar, cada um com um inimigo mais forte. Ao contrário do Treino, **o HP gasto continua gasto** de um andar para o outro. A ideia vem do labirinto do Legend Online.

**Critério de sucesso:** o jogador clica na Torre, vê o andar atual, o HP da escalada e o próximo inimigo, e sobe. Cada vitória dá XP e ouro e leva ao próximo andar com o HP que sobrou (mais uma pequena recuperação). Uma derrota encerra a escalada e ela recomeça do andar 1. O recorde e a escalada em andamento ficam salvos.

### Decisões propostas (revisar)
| Tema | Proposta | Motivo |
|---|---|---|
| Andares | Infinitos, gerados por fórmula a partir do número do andar | Sem limite artificial; o balanceamento é um lugar só (`Tower`) |
| Chefe | A cada 5 andares: mais HP e ataque, recompensa em dobro | Marca o ritmo e dá metas claras |
| HP na Torre | A escalada tem **HP próprio**, separado do herói. Treino não cura a escalada | Sem isso, lutar com um Rato no Treino (que devolve o HP cheio) tornaria o HP da Torre irrelevante |
| Recuperação | Ao vencer um andar, recupera 20% do HP máximo | A escalada vai mais longe que 3 ou 4 andares sem virar passeio |
| Derrota | Fim da escalada: volta ao andar 1 com HP cheio; o recorde fica | É o "custo" da Torre; XP e ouro já ganhos não se perdem |
| Fugir | Sai da luta mantendo o andar e o HP que sobrou | Dá para sair e voltar depois, sem apagar a escalada |
| Recomeçar | Botão para abandonar a escalada (andar 1, HP cheio) | Saída para quem ficou com pouco HP num andar alto |
| Recompensa | XP e ouro a cada andar vencido | Mesmo modelo do Treino |

### Fora do escopo
Recompensa especial de recorde, ranking, andares com mais de um inimigo, eventos entre andares (baú, fonte de cura), itens que curam e arte própria para os inimigos da Torre além do nome do arquivo.

## 2. Regras (`domain/tower.gd`, funções puras)

Inimigo do andar `n`:

| Status | Fórmula | Andar 1 | Andar 5 (chefe) | Andar 10 (chefe) |
|---|---|---|---|---|
| HP | 50 + 20n | 70 | 150 × 1,6 = 240 | 250 × 1,6 = 400 |
| Ataque | 14 + 4n | 18 | 34 × 1,2 = 40 | 54 × 1,2 = 64 |
| Defesa | 2n | 2 | 10 | 20 |
| Velocidade | 88 + 3n | 91 | 103 | 118 |
| Crítico | 3% | 3 | 3 | 3 |
| XP | 10 + 6n | 16 | 40 × 2 = 80 | 70 × 2 = 140 |
| Ouro | 8 + 5n | 13 | 33 × 2 = 66 | 58 × 2 = 116 |
| Nível exibido | 1 + floor(n ÷ 2) | 1 | 3 | 6 |

Multiplicações arredondam para baixo. Nomes, em ciclo: Esqueleto, Goblin, Aranha Gigante, Cultista. O chefe se chama "Guardião". Os `id`s são `tower_skeleton`, `tower_goblin`, `tower_spider`, `tower_cultist` e `tower_guardian`, e a arte opcional é `assets/enemies/<id>.png`.

Referência: o Aldric nível 1 vence os andares 1 a 4 em sequência (por volta do andar 4 já sobe para o nível 2) e perde para o primeiro Guardião. É uma meta para depois de alguns níveis.

## 3. Arquitetura

```
domain/tower_progress.gd   TowerProgress: floor (andar a enfrentar), hp (HP da escalada), best_floor
domain/tower.gd            Tower.enemy_for_floor(n), is_boss(n), REGEN_FRACTION
domain/player.gd           + tower: TowerProgress
domain/battle.gd           Battle.new(hero, enemy, dice, start_hp = -1): -1 usa o HP do herói
game/game_state.gd         + apply_tower_result(battle) -> int, reset_tower()
ui/tower/tower_panel.gd    janela da Torre (GameWindow)
ui/battle/battle_screen.gd start(enemy, start_hp = -1); o resultado passa a ser aplicado pelo main
ui/main.gd                 Torre abre o painel; lembra se o combate é do Treino ou da Torre
```

- `GameState.apply_tower_result(battle)`:
  - Vitória: XP e ouro (como no Treino). `hp = min(max_hp, hp_restante + floor(max_hp × 0,2))`, `floor += 1` e `best_floor = max(best_floor, andar vencido)`.
  - Derrota: `floor = 1` e `hp = max_hp`.
  - Fuga: `hp = hp_restante`.
  - Em todos os casos, `player_changed` e `_save()`.
- Subir de nível durante a escalada aumenta o HP máximo, mas não cura: o HP da escalada fica igual (limitado ao novo máximo).
- O `BattleScreen` deixa de chamar o `GameState` e só emite `finished(battle)`. O `main.gd` aplica o resultado conforme a origem do combate (`apply_battle_result` ou `apply_tower_result`). Depois de um combate da Torre (menos na fuga), o painel da Torre reabre com o andar novo.

## 4. Save (versão 2)

```json
"tower": { "floor": 4, "hp": 131, "best_floor": 3 }
```
- `HeroSerializer.VERSION = 2`. Saves da versão 1 (sem `tower`) continuam válidos: começam no andar 1, com HP cheio e recorde 0.
- Validação: `floor >= 1`, `best_floor >= 0`, `hp >= 0`. O `hp` é limitado a `[1, max_hp]` sem erro, como o `current_hp`.

## 5. Interface: painel da Torre

- Título "Torre". Linha grande "Andar N" e, embaixo, "Recorde: andar X" (ou "Recorde: nenhum").
- "HP da escalada" com barra vermelha e `atual / máx`.
- Cartão do próximo inimigo: nome, "Nv X", a etiqueta **CHEFE** em dourado quando for chefe, e as recompensas.
- Botões **Subir** (inicia o combate com o HP da escalada) e **Recomeçar** (desativado quando já está no andar 1 com HP cheio).

## 6. Testes
- **`test_tower`**: tabela da seção 2 (andares 1, 5 e 10); ciclo de nomes; chefe só nos múltiplos de 5.
- **`test_battle`** (acréscimo): `start_hp` define o HP inicial.
- **`test_game_state`** (acréscimos): vitória na Torre avança o andar, recupera 20%, atualiza o recorde e dá recompensas; derrota volta ao andar 1 com HP cheio e mantém o recorde; fuga mantém o andar com o HP que sobrou; `reset_tower`; tudo é salvo.
- **`test_hero_serializer` / `test_save_game_repository`** (acréscimos): formato versão 2; save da versão 1 sem `tower` carrega com os valores iniciais; `tower` inválido conta como save danificado.
- **`test_tower_panel`**: abrir pela construção; andar, recorde, HP e inimigo exibidos; etiqueta de chefe; Subir abre o combate com o HP da escalada; depois de vencer, o painel reabre no andar seguinte; Recomeçar.
