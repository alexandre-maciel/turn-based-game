extends BaseTest
## Painel do Campo de Treino (spec do combate, seção 5).

var main: Node
var panel: TrainingPanel


func before_each() -> void:
	main = add_to_tree(load("res://ui/main.tscn").instantiate())
	await tree.process_frame
	panel = main.training_panel


func _click_training() -> void:
	main.city.buildings["training"].clicked.emit()


func test_panel_starts_closed() -> void:
	assert_false(panel.is_open())


func test_training_opens_panel_with_three_enemies() -> void:
	_click_training()
	assert_true(panel.is_open())
	assert_eq(panel.fight_buttons.keys(), ["giant_rat", "wolf", "ogre"])
	assert_false(panel.error_label.visible)
	assert_false(main.toast.visible, "Treino não mostra mais 'em breve'")


func test_higher_level_enemy_is_red() -> void:
	_click_training()
	assert_false(panel.level_labels["giant_rat"].has_theme_color_override("font_color"))
	assert_true(panel.level_labels["wolf"].has_theme_color_override("font_color"))
	assert_eq(panel.level_labels["ogre"].get_theme_color("font_color"), TrainingPanel.WARNING)


func test_warning_follows_hero_level() -> void:
	use_repository(FixedHeroRepository.aldric(4))
	_click_training()
	assert_false(panel.level_labels["ogre"].has_theme_color_override("font_color"))


func test_escape_and_close_button_close_panel() -> void:
	_click_training()
	await press_key(KEY_ESCAPE)
	assert_false(panel.is_open())
	_click_training()
	panel.close_button.pressed.emit()
	assert_false(panel.is_open())


func test_other_buildings_still_coming_soon() -> void:
	main.city.buildings["arena"].clicked.emit()
	assert_false(panel.is_open())
	assert_eq(main.toast.label.text, "Arena — em breve")


func test_fight_closes_panel_and_starts_battle() -> void:
	_click_training()
	panel.fight_buttons["wolf"].pressed.emit()
	assert_false(panel.is_open())
	assert_true(main.battle_screen.is_active())
	assert_eq(main.battle_screen.enemy_view.name_label.text, "Lobo")


func test_enemy_load_error_is_shown() -> void:
	use_enemy_repository(FailingEnemyRepository.new())
	_click_training()
	assert_true(panel.is_open())
	assert_true(panel.error_label.visible)
	assert_eq(panel.fight_buttons.size(), 0)


func test_without_hero_shows_error_toast() -> void:
	use_repository(FailingHeroRepository.new())
	_click_training()
	assert_false(panel.is_open())
	assert_eq(main.toast.label.text, "Erro ao carregar personagem")
