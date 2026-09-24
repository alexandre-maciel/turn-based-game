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
