# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projeto

"Primeiro Jogo": RPG em Godot **4.7.2** (GDScript, renderer GL Compatibility, base 1280×720), inspirado no Legend Online e pensado para virar um jogo **online** no futuro. Hoje tem a cidade, o painel do Personagem e o combate por turnos 1×1 no Campo de Treino (XP, ouro e nível; nada é salvo em disco). Spec e plano de implementação: `docs/superpowers/specs/` e `docs/superpowers/plans/`. Código, comentários, textos de UI e mensagens de teste são em português.

## Comandos

O Godot fica na raiz, ignorado pelo git: ou a pasta `Godot_v4.7.2-stable_win64.exe/` (zip extraído, com o `_console.exe`) ou o exe solto `Godot_v4.7.2-stable_win64.exe`; os scripts de teste aceitam os dois. Ao chamar o exe solto pelo PowerShell, redirecione a saída por pipe (`| Out-String`): ele é um app de janela e, sem isso, o PowerShell não espera ele terminar (o `--import` fica pela metade e os testes falham com "Could not find type BaseTest").

```sh
run_tests.cmd                      # Windows: todos os testes (headless)
bash run_tests.sh                  # idem via bash
bash run_tests.sh --only=hud       # só arquivos tests/test_*.gd cujo nome contém "hud"
```

Os scripts rodam `--import` antes dos testes: necessário para registrar `class_name` novos e arte nova. O filtro `--only` é por **arquivo**, não por método.

Screenshots para conferência visual (precisa de janela, **não** usar `--headless`); salva em `screenshots/` a cidade, os painéis, o combate e o resultado:

```sh
Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/screenshot.gd
```

Não há linter configurado.

Scripts rodados com `--script` (`tests/run_tests.gd`, `tools/screenshot.gd`) compilam **antes** do autoload `GameState` existir: neles, não tipe variáveis com classes que usam `GameState` (ex.: `BattleScreen`), senão a compilação falha em cascata.

## Arquitetura

Fluxo de dados em uma só direção:

```
data/sample_hero.json → LocalHeroRepository.load_player() → LoadResult → GameState (autoload)
                                                              sinais player_changed / load_failed
                                                                          ↓
                                                  componentes de UI (leem e exibem via StatFormulas)

data/enemies.json → LocalEnemyRepository → GameState.enemies → TrainingPanel → BattleScreen
BattleScreen: Battle.play_round(ação) → BattleEvent[] (exibidos um a um) → GameState.apply_battle_result(battle)
```

- **`domain/`**: `Attributes`, `Hero`, `Player`, `Enemy` são só dados (`RefCounted`, sem nós). Todas as fórmulas e o balanceamento ficam em `StatFormulas` (funções estáticas puras), incluindo `damage()` e a habilidade de cada classe (`SKILLS`). Classes jogáveis ficam no dicionário `StatFormulas.CLASSES`; hoje só `mage`. Essa camada deve continuar reutilizável por um servidor.
  - Combate: `Battle` trabalha com cópias (`Combatant`) e nunca altera o `Hero`; `play_round(ação)` resolve a rodada inteira e devolve `BattleEvent`s, cada um com o HP do alvo naquele momento. Todo sorteio passa por `Dice` (injetado; nos testes, `FixedDice`). `Progression` cuida de XP e nível.
- **`data/`**: `HeroRepository` e `EnemyRepository` são interfaces; as versões `Local*` leem JSON validando campo a campo com `JsonFields`. `LocalHeroRepository` lê e valida o JSON (campos obrigatórios, tipos, classe válida, limites); falha vira `LoadResult.failure(msg)`, nunca crash. `current_hp` é limitado a `[0, max_hp]` sem erro. Moedas ficam no `Player` (conta), não no `Hero`.
- **`game/game_state.gd`** (autoload `GameState`): dono do `Player` e da lista de inimigos. Os repositórios são injetáveis (`repository`, `enemy_repository`); `reload()` / `reload_enemies()` recarregam. Toda alteração do `Player` é um método daqui (hoje, `apply_battle_result()`), que emite `player_changed`.
- **`ui/`**: a UI **nunca altera** `Player`/`Hero` e não guarda cópia dos dados; cada componente se redesenha a cada `player_changed` e trata `load_failed` (a cidade continua de pé com mensagem de erro).
  - Janelas (`CharacterPanel`, `TrainingPanel`) estendem `GameWindow`, que já traz fundo escurecido, título, ✕, Esc e clique fora. Camadas: HUD = 1, janelas = 2, combate = 3.
  - Só existe uma cena, `ui/main.tscn`; os componentes (`CityScreen`, `HeroHud`, `CharacterPanel` etc.) montam seus nós **em código** no `_ready()` e expõem os nós filhos como variáveis públicas (usadas pelos testes).
  - `main.gd` liga os sinais entre componentes. `CanvasLayer` não repassa tema, então `main.gd` aplica `GameTheme.get_theme()` em cada Control raiz.
  - Todo texto visível ao jogador fica em `ui/texts.gd` (`Texts`), incluindo formatação de números (`thousands`, `percent`).
  - Arte é opcional: `ArtLoader.texture_or_null(path)` devolve `null` se o arquivo não existe e o componente desenha um placeholder. Nomes, tamanhos e posições esperados estão em `assets/README.md`.

## Testes

Executor próprio, sem plugins (`tests/run_tests.gd`, `extends SceneTree`): descobre `tests/test_*.gd`, e para cada método `test_*` cria uma instância nova e chama `before_each` → teste → `after_each` → `cleanup`.

- Todo arquivo de teste deve `extends BaseTest` (`tests/base_test.gd`), que fornece `assert_eq` (compara também o **tipo**: `240` ≠ `240.0`), `assert_true`, `assert_false`, `add_to_tree(node)` (liberado no cleanup), `use_repository(repo)` / `use_enemy_repository(repo)` (trocam as fontes do `GameState`; o cleanup sempre recarrega das fontes reais), `left_click()` e `press_key(key)` (usar com `await`).
- Erros de script durante o teste (acesso a null etc.) viram falha via um `Logger` customizado; `push_error` não conta como falha.
- Fakes em `tests/fakes/`: `FixedHeroRepository`, `FailingHeroRepository`, `FixedEnemyRepository` (`weak_and_strong()`: um inimigo que morre com um golpe e um que vence), `FailingEnemyRepository`, `FixedDice`. JSONs inválidos em `tests/fixtures/` (inimigos em `tests/fixtures/enemies/`).
- Testes do combate na tela: `screen.event_delay = 0.0` e `screen.dice = FixedDice.new()` antes de `start()`, para os eventos saírem na hora e com valores previsíveis.
- Testes de UI instanciam `res://ui/main.tscn` com `add_to_tree` e fazem `await tree.process_frame` antes de inspecionar.
