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
