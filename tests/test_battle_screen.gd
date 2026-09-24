extends BaseTest
## Tela de combate (spec do combate, seção 5). Sem intervalo e sem sorteio.

var main: Node
var screen: BattleScreen


func before_each() -> void:
	use_repository(FixedHeroRepository.aldric())
	main = add_to_tree(load("res://ui/main.tscn").instantiate())
	await tree.process_frame
	screen = main.battle_screen
	screen.event_delay = 0.0
	screen.dice = FixedDice.new()


func _start(enemy_id: String) -> void:
	for enemy in GameState.enemies:
		if enemy.id == enemy_id:
			screen.start(enemy)


func _press(action_id: String) -> void:
	screen.action_buttons[action_id].pressed.emit()


func test_starts_with_both_fighters() -> void:
	_start("giant_rat")
	assert_true(screen.is_active())
	assert_eq(screen.hero_view.name_label.text, "Aldric")
	assert_eq(screen.hero_view.hp_label.text, "240 / 240")
	assert_eq(screen.enemy_view.name_label.text, "Rato Gigante")
	assert_eq(screen.enemy_view.hp_label.text, "80 / 80")
	assert_eq(screen.round_label.text, "Rodada 1")
	assert_eq(screen.action_buttons["skill"].text, "Bola de Fogo")
	assert_false(screen.result_box.visible)


func test_attack_updates_bars_log_and_popup() -> void:
	_start("giant_rat")
	_press("attack")
	assert_eq(screen.enemy_view.hp_label.text, "54 / 80")
	assert_eq(screen.enemy_view.hp_bar.value, 54.0)
	assert_eq(screen.hero_view.hp_label.text, "228 / 240")
	assert_eq(screen.enemy_view.damage_label.text, "-26")
	assert_eq(screen.log_label.text,
		"Aldric ataca Rato Gigante: 26 de dano.\nRato Gigante ataca Aldric: 12 de dano.")
	assert_eq(screen.round_label.text, "Rodada 2")


func test_fireball_shows_cooldown() -> void:
	_start("ogre")
	_press("skill")
	assert_true(screen.log_label.text.begins_with("Aldric usa Bola de Fogo em Ogro: 30 de dano."))
	assert_eq(screen.action_buttons["skill"].text, "Bola de Fogo (2)")
	assert_true(screen.action_buttons["skill"].disabled)
	assert_false(screen.action_buttons["attack"].disabled)


func test_critical_popup() -> void:
	screen.dice = FixedDice.new(0.0)
	_start("ogre")
	_press("attack")
	assert_eq(screen.enemy_view.damage_label.text, "CRÍTICO!\n-28")


func test_log_keeps_last_five_lines() -> void:
	_start("ogre")
	for i in 4:
		_press("attack")
	assert_eq(screen.log_label.text.split("\n").size(), 5)


func test_buttons_locked_while_events_play() -> void:
	screen.event_delay = 0.05
	_start("giant_rat")
	_press("attack")
	assert_true(screen.action_buttons["attack"].disabled)
	await tree.create_timer(0.3).timeout
	assert_false(screen.action_buttons["attack"].disabled)


func test_victory_shows_rewards_and_level_up() -> void:
	use_enemy_repository(FixedEnemyRepository.weak_and_strong())
	_start("weak")
	_press("attack")
	assert_true(screen.result_box.visible)
	assert_eq(screen.result_title.text, "Vitória!")
	assert_eq(screen.result_text.text, "+70 XP\n+15 ouro\nSubiu para o nível 2!")
	for id in screen.action_buttons:
		assert_true(screen.action_buttons[id].disabled)
	# As recompensas só entram ao voltar.
	assert_eq(GameState.player.gold, 1250)


func test_back_to_city_applies_result_and_updates_hud() -> void:
	use_enemy_repository(FixedEnemyRepository.weak_and_strong())
	_start("weak")
	_press("attack")
	screen.back_button.pressed.emit()
	assert_false(screen.is_active())
	assert_eq(GameState.player.gold, 1265)
	assert_eq(main.currency_hud.gold_label.text, "1.265")
	assert_eq(main.hero_hud.level_label.text, "Nv 2")


func test_defeat() -> void:
	use_enemy_repository(FixedEnemyRepository.weak_and_strong())
	_start("strong")
	_press("attack")
	assert_eq(screen.result_title.text, "Derrota")
	assert_eq(screen.result_text.text, "Você foi derrotado. Treine e tente de novo.")
	screen.back_button.pressed.emit()
	assert_eq(GameState.player.hero.xp, 35)


func test_flee_returns_to_city_with_toast() -> void:
	_start("wolf")
	_press("flee")
	assert_false(screen.is_active())
	assert_false(screen.result_box.visible)
	assert_true(main.toast.visible)
	assert_eq(main.toast.label.text, "Você fugiu do combate")


func test_screen_blocks_city_clicks() -> void:
	_start("giant_rat")
	assert_eq(screen.mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_eq(screen.anchor_right, 1.0)
	assert_eq(screen.anchor_bottom, 1.0)
	var layer: CanvasLayer = screen.get_parent()
	assert_true(layer.layer > 2, "acima das janelas")


func test_escape_does_not_close_battle() -> void:
	_start("giant_rat")
	await press_key(KEY_ESCAPE)
	assert_true(screen.is_active())


func test_new_battle_resets_screen() -> void:
	use_enemy_repository(FixedEnemyRepository.weak_and_strong())
	_start("weak")
	_press("attack")
	screen.back_button.pressed.emit()
	_start("weak")
	assert_false(screen.result_box.visible)
	assert_eq(screen.log_label.text, "")
	assert_false(screen.action_buttons["attack"].disabled)
