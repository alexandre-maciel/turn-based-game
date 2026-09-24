# Plano: combate por turnos no Campo de Treino

Spec: `docs/superpowers/specs/2026-09-24-combate-por-turnos-design.md`. Cada tarefa termina com `run_tests.cmd` passando.

## Restrições (as mesmas do MVP)
- `domain/` sem nós. A UI só lê o `GameState`; quem altera o `Player` é `GameState.apply_battle_result()`.
- Textos visíveis ao jogador só em `ui/texts.gd`.
- Sinais do `GameState` conectados a métodos, nunca a lambdas.
- Sorteio sempre via `Dice`; nos testes, `FixedDice`.

## Desvios conscientes da spec
- `Battle.Action` e `Battle.Outcome` são enums dentro de `Battle`, e não o arquivo `battle_action.gd`.
- `JsonFields` (`data/json_fields.gd`) reúne a leitura e validação de campos que o `LocalHeroRepository` já fazia; o `LocalEnemyRepository` reaproveita.
- `GameWindow` (`ui/common/game_window.gd`) reúne o fundo escurecido, a janela, o título, o ✕ e o Esc do `CharacterPanel`; o `TrainingPanel` reaproveita.
- `Progression.after_xp()` calcula o nível e o XP sem alterar nada, para a tela de vitória mostrar "Subiu para o nível 2!" antes de o `GameState` aplicar.
- `BaseTest.cleanup()` sempre recarrega o `GameState` (herói e inimigos), porque agora os testes alteram o `Player`.

## Tarefas

### 1. Refatorações sem mudar comportamento
- `data/json_fields.gd`: `read_object(path)`, `dict`, `array`, `string`, `integer` com o mesmo texto de erro de hoje. `LocalHeroRepository` passa a usá-lo.
- `ui/common/game_window.gd`: base de janela. `CharacterPanel` passa a estendê-la. `GameTheme.inner_box()`.
- Os testes existentes devem continuar passando sem alteração.

### 2. Domínio do combate
- `domain/dice.gd` (`roll_percent()` 0–100, `variance()` 0,9–1,1) e `tests/fakes/fixed_dice.gd`.
- `StatFormulas.damage(attack, defense, multiplier, variance, critical, defending)`, `SKILLS`, `skill_for(hero_class)`.
- `domain/enemy.gd`, `domain/combatant.gd` (`from_hero`, `from_enemy`), `domain/battle_event.gd`, `domain/battle.gd`, `domain/progression.gd`.
- Testes: `test_damage`, `test_battle`, `test_progression`.

### 3. Inimigos
- `data/enemies.json`, `data/enemy_repository.gd`, `data/enemy_load_result.gd`, `data/local_enemy_repository.gd` e os fixtures.
- Fakes: `FixedEnemyRepository`, `FailingEnemyRepository`. Teste: `test_local_enemy_repository`.

### 4. GameState
- `enemy_repository`, `enemies`, `enemies_error`, `reload_enemies()`, `apply_battle_result(battle) -> int`.
- `BaseTest.use_enemy_repository()`, com o cleanup restaurando tudo. Acréscimos em `test_game_state`.

### 5. Painel do Treino
- `Texts` novos, `ui/training/training_panel.gd`, nó em `main.tscn`, ligação em `main.gd`. Teste: `test_training_panel`.

### 6. Tela de combate
- `ui/battle/fighter_view.gd`, `ui/battle/battle_screen.gd`, `BattleLayer` em `main.tscn`, ligações em `main.gd`. Teste: `test_battle_screen`.

### 7. Fechamento
- `assets/README.md` com a arte nova; `tools/screenshot.gd` também fotografa o Treino e o combate.
- Conferência visual das capturas e atualização do `CLAUDE.md`.
