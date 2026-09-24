extends BaseTest
## Painel da Torre e o ciclo subir → combate → painel (spec da Torre, seção 5).

var main: Node
var panel: TowerPanel
var screen: BattleScreen


func before_each() -> void:
	use_repository(FixedHeroRepository.aldric())
	main = add_to_tree(load("res://ui/main.tscn").instantiate())
	await tree.process_frame
	panel = main.tower_panel
	screen = main.battle_screen
	screen.event_delay = 0.0
	screen.dice = FixedDice.new()


func _click_tower() -> void:
	main.city.buildings["tower"].clicked.emit()


func test_tower_opens_panel_with_first_floor() -> void:
	_click_tower()
	assert_true(panel.is_open())
	assert_false(main.toast.visible, "a Torre não mostra mais 'em breve'")
	assert_eq(panel.floor_label.text, "Andar 1")
	assert_eq(panel.best_label.text, "Recorde: nenhum")
	assert_eq(panel.hp_label.text, "240 / 240")
	assert_eq(panel.enemy_name_label.text, "Esqueleto")
	assert_eq(panel.rewards_label.text, "+16 XP · +13 ouro")
	assert_false(panel.boss_label.visible)
	assert_true(panel.restart_button.disabled)


func test_boss_floor_shows_tag() -> void:
	GameState.player.tower = TowerProgress.new(5, 200, 4)
	_click_tower()
	assert_eq(panel.enemy_name_label.text, "Guardião")
	assert_true(panel.boss_label.visible)
	assert_eq(panel.best_label.text, "Recorde: andar 4")
	assert_false(panel.restart_button.disabled)


func test_climb_starts_battle_with_climb_hp() -> void:
	GameState.player.tower.hp = 150
	_click_tower()
	panel.climb_button.pressed.emit()
	assert_false(panel.is_open())
	assert_true(screen.is_active())
	assert_eq(screen.enemy_view.name_label.text, "Esqueleto")
	assert_eq(screen.hero_view.hp_label.text, "150 / 240")


func test_victory_reopens_panel_on_next_floor() -> void:
	_click_tower()
	panel.climb_button.pressed.emit()
	while not screen.battle.is_over():
		screen.action_buttons["attack"].pressed.emit()
	assert_eq(screen.result_title.text, "Vitória!")
	screen.back_button.pressed.emit()
	assert_true(panel.is_open())
	assert_eq(panel.floor_label.text, "Andar 2")
	assert_eq(panel.best_label.text, "Recorde: andar 1")
	assert_eq(panel.enemy_name_label.text, "Goblin")
	# Esqueleto: 3 golpes do Aldric, 2 do Esqueleto (10 cada); +48 de volta, limitado a 240.
	assert_eq(panel.hp_label.text, "240 / 240")
	assert_eq(GameState.player.hero.current_hp, 240)


func test_training_does_not_heal_the_climb() -> void:
	GameState.player.tower.hp = 100
	main.city.buildings["training"].clicked.emit()
	main.training_panel.fight_buttons["giant_rat"].pressed.emit()
	while not screen.battle.is_over():
		screen.action_buttons["attack"].pressed.emit()
	screen.back_button.pressed.emit()
	assert_eq(GameState.player.tower.hp, 100)
	assert_false(panel.is_open(), "combate do Treino não abre a Torre")


func test_flee_keeps_climb_and_shows_toast() -> void:
	GameState.player.tower = TowerProgress.new(3, 150, 2)
	_click_tower()
	panel.climb_button.pressed.emit()
	screen.action_buttons["flee"].pressed.emit()
	assert_eq(main.toast.label.text, "Você fugiu do combate")
	assert_false(panel.is_open())
	assert_eq(GameState.player.tower.floor_number, 3)
	assert_eq(GameState.player.tower.hp, 150)


func test_restart_button_resets_climb() -> void:
	GameState.player.tower = TowerProgress.new(6, 80, 5)
	_click_tower()
	panel.restart_button.pressed.emit()
	assert_eq(panel.floor_label.text, "Andar 1")
	assert_eq(panel.hp_label.text, "240 / 240")
	assert_eq(panel.best_label.text, "Recorde: andar 5")
	assert_true(panel.restart_button.disabled)


func test_escape_closes_panel() -> void:
	_click_tower()
	await press_key(KEY_ESCAPE)
	assert_false(panel.is_open())
