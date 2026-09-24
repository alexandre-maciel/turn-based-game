extends BaseTest
## Autoload GameState: carrega via repositório e avisa por sinais.


func test_loads_sample_player_on_startup() -> void:
	assert_true(GameState.has_player())
	assert_eq(GameState.player.hero.hero_name, "Aldric")
	assert_eq(GameState.load_error, "")


func test_reload_emits_player_changed() -> void:
	var received: Array = []
	var on_changed := func(player: Player) -> void: received.append(player)
	GameState.player_changed.connect(on_changed)
	GameState.reload()
	GameState.player_changed.disconnect(on_changed)
	assert_eq(received.size(), 1)
	assert_true(received[0] is Player)


func test_failure_clears_player_and_emits_load_failed() -> void:
	var errors: Array = []
	var on_failed := func(error: String) -> void: errors.append(error)
	GameState.load_failed.connect(on_failed)
	use_repository(FailingHeroRepository.new())
	GameState.load_failed.disconnect(on_failed)
	assert_false(GameState.has_player())
	assert_true(GameState.player == null)
	assert_eq(GameState.load_error, FailingHeroRepository.ERROR)
	assert_eq(errors, [FailingHeroRepository.ERROR])


func test_recovers_after_failure() -> void:
	use_repository(FailingHeroRepository.new())
	use_repository(FixedHeroRepository.aldric(5))
	assert_true(GameState.has_player())
	assert_eq(GameState.player.hero.level, 5)
	assert_eq(GameState.load_error, "")


func test_loads_training_enemies_on_startup() -> void:
	assert_eq(GameState.enemies.size(), 3)
	assert_eq(GameState.enemies_error, "")


func test_enemy_failure_keeps_game_running() -> void:
	use_enemy_repository(FailingEnemyRepository.new())
	assert_eq(GameState.enemies.size(), 0)
	assert_eq(GameState.enemies_error, FailingEnemyRepository.ERROR)
	assert_true(GameState.has_player())


func _finished_battle(enemy_index: int, action: Battle.Action = Battle.Action.ATTACK) -> Battle:
	use_enemy_repository(FixedEnemyRepository.weak_and_strong())
	var battle := Battle.new(GameState.player.hero, GameState.enemies[enemy_index], FixedDice.new())
	battle.play_round(action)
	return battle


func test_victory_gives_xp_gold_and_levels() -> void:
	use_repository(FixedHeroRepository.aldric())
	var battle := _finished_battle(0)
	var received: Array = []
	var on_changed := func(player: Player) -> void: received.append(player)
	GameState.player_changed.connect(on_changed)
	var levels := GameState.apply_battle_result(battle)
	GameState.player_changed.disconnect(on_changed)
	var hero := GameState.player.hero
	assert_eq(levels, 1)
	assert_eq(hero.level, 2)
	assert_eq(hero.xp, 5)
	assert_eq(GameState.player.gold, 1265)
	assert_eq(received.size(), 1)


func test_hp_is_full_after_battle_even_with_new_level() -> void:
	use_repository(FixedHeroRepository.aldric())
	GameState.player.hero.current_hp = 50
	GameState.apply_battle_result(_finished_battle(0))
	assert_eq(GameState.player.hero.current_hp, StatFormulas.max_hp(GameState.player.hero))
	assert_eq(GameState.player.hero.current_hp, 260)


func test_defeat_gives_nothing() -> void:
	use_repository(FixedHeroRepository.aldric())
	var battle := _finished_battle(1)
	assert_eq(battle.outcome, Battle.Outcome.DEFEAT)
	assert_eq(GameState.apply_battle_result(battle), 0)
	assert_eq(GameState.player.hero.xp, 35)
	assert_eq(GameState.player.gold, 1250)
	assert_eq(GameState.player.hero.current_hp, 240)


func test_flee_gives_nothing() -> void:
	use_repository(FixedHeroRepository.aldric())
	GameState.apply_battle_result(_finished_battle(0, Battle.Action.FLEE))
	assert_eq(GameState.player.hero.xp, 35)
	assert_eq(GameState.player.gold, 1250)


func test_unfinished_battle_changes_nothing() -> void:
	use_repository(FixedHeroRepository.aldric())
	use_enemy_repository(FixedEnemyRepository.weak_and_strong())
	var battle := Battle.new(GameState.player.hero, GameState.enemies[0], FixedDice.new())
	assert_eq(GameState.apply_battle_result(battle), 0)
	assert_eq(GameState.player.gold, 1250)


func test_tests_never_use_real_save() -> void:
	# Rodando pelo executor de testes, o padrão é só leitura.
	assert_true(GameState._default_repository() is LocalHeroRepository)
	assert_false(GameState._default_repository() is SaveGameRepository)


func test_victory_is_saved() -> void:
	var recorder := RecordingHeroRepository.new()
	use_repository(recorder)
	GameState.apply_battle_result(_finished_battle(0))
	assert_eq(recorder.saved.size(), 1)
	assert_eq(recorder.saved[0]["hero"]["level"], 2)
	assert_eq(recorder.saved[0]["currencies"]["gold"], 1265)


func test_defeat_and_flee_are_saved_too() -> void:
	var recorder := RecordingHeroRepository.new()
	use_repository(recorder)
	GameState.apply_battle_result(_finished_battle(1))
	GameState.apply_battle_result(_finished_battle(0, Battle.Action.FLEE))
	assert_eq(recorder.saved.size(), 2)


func test_save_failure_emits_signal_and_keeps_player() -> void:
	var recorder := RecordingHeroRepository.new()
	recorder.save_error = "disco cheio"
	use_repository(recorder)
	var errors: Array = []
	var on_failed := func(error: String) -> void: errors.append(error)
	GameState.save_failed.connect(on_failed)
	GameState.apply_battle_result(_finished_battle(0))
	GameState.save_failed.disconnect(on_failed)
	assert_eq(errors, ["disco cheio"])
	assert_eq(GameState.player.hero.level, 2)


func test_load_warning_is_kept() -> void:
	var recorder := RecordingHeroRepository.new()
	recorder.warning = "save danificado"
	use_repository(recorder)
	assert_eq(GameState.load_warning, "save danificado")
	assert_true(GameState.has_player())
	use_repository(FixedHeroRepository.aldric())
	assert_eq(GameState.load_warning, "")


func _tower_battle(enemy: Enemy, action: Battle.Action = Battle.Action.ATTACK) -> Battle:
	var battle := Battle.new(GameState.player.hero, enemy, FixedDice.new(), GameState.player.tower.hp)
	battle.play_round(action)
	return battle


func _tower() -> Array:
	var tower: TowerProgress = GameState.player.tower
	return [tower.floor_number, tower.hp, tower.best_floor]


func test_tower_victory_advances_regens_and_rewards() -> void:
	var recorder := RecordingHeroRepository.new()
	use_repository(recorder)
	GameState.player.tower.hp = 150
	# Morre com um golpe; o Aldric não apanha.
	var weak := Enemy.new("w", "Fraco", 1, 10, 1, 0, 0, 1, 20, 15)
	GameState.apply_tower_result(_tower_battle(weak))
	assert_eq(_tower(), [2, 198, 1])
	assert_eq(GameState.player.gold, 1265)
	assert_eq(GameState.player.hero.xp, 55)
	assert_eq(recorder.saved.size(), 1)
	assert_eq(recorder.saved[0]["tower"]["floor"], 2)


func test_tower_regen_does_not_pass_max() -> void:
	use_repository(FixedHeroRepository.aldric())
	var weak := Enemy.new("w", "Fraco", 1, 10, 1, 0, 0, 1, 0, 0)
	GameState.apply_tower_result(_tower_battle(weak))
	assert_eq(GameState.player.tower.hp, 240)


func test_tower_keeps_damage_between_floors() -> void:
	use_repository(FixedHeroRepository.aldric())
	# Mais rápido, bate 12 (20 − 8) e morre com um golpe.
	var hitter := Enemy.new("h", "Batedor", 1, 10, 20, 0, 0, 200, 0, 0)
	GameState.player.tower.hp = 100
	GameState.apply_tower_result(_tower_battle(hitter))
	assert_eq(GameState.player.tower.hp, 136, "100 − 12 + 48")
	assert_eq(GameState.player.hero.current_hp, 240, "o HP do herói não muda")


func test_tower_defeat_restarts_climb_and_keeps_best() -> void:
	use_repository(FixedHeroRepository.aldric())
	GameState.player.tower = TowerProgress.new(7, 90, 6)
	var strong := Enemy.new("s", "Forte", 9, 5000, 999, 0, 0, 999, 500, 200)
	GameState.apply_tower_result(_tower_battle(strong))
	assert_eq(_tower(), [1, 240, 6])
	assert_eq(GameState.player.gold, 1250)


func test_tower_flee_keeps_floor_and_remaining_hp() -> void:
	use_repository(FixedHeroRepository.aldric())
	GameState.player.tower = TowerProgress.new(3, 90, 2)
	GameState.apply_tower_result(_tower_battle(Tower.enemy_for_floor(3), Battle.Action.FLEE))
	assert_eq(_tower(), [3, 90, 2])


func test_reset_tower() -> void:
	var recorder := RecordingHeroRepository.new()
	use_repository(recorder)
	GameState.player.tower = TowerProgress.new(7, 90, 6)
	GameState.reset_tower()
	assert_eq(_tower(), [1, 240, 6])
	assert_eq(recorder.saved.size(), 1)
