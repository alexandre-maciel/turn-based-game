extends BaseTest
## Barra de menu + painel do personagem (spec, seção 5).

var main: Node
var panel: CharacterPanel
var bar: BottomBar


func before_each() -> void:
	main = add_to_tree(load("res://ui/main.tscn").instantiate())
	await tree.process_frame
	panel = main.character_panel
	bar = main.bottom_bar


func _open_with_button() -> void:
	bar.buttons["character"].pressed.emit()


func test_panel_starts_closed() -> void:
	assert_false(panel.is_open())


func test_bar_has_six_buttons_in_order() -> void:
	assert_eq(bar.buttons.keys(), ["character", "bag", "skills", "quests", "guild", "settings"])


func test_character_button_opens_panel_with_aldric_stats() -> void:
	_open_with_button()
	assert_true(panel.is_open())
	assert_eq(panel.name_label.text, "Aldric")
	assert_eq(panel.class_level_label.text, "Mago · Nível 1")
	assert_eq(panel.hp_label.text, "240 / 240")
	assert_eq(panel.xp_label.text, "35 / 100")
	assert_eq(panel.xp_bar.value, 35.0)
	assert_eq(panel.value_labels["strength"].text, "5")
	assert_eq(panel.value_labels["agility"].text, "8")
	assert_eq(panel.value_labels["intelligence"].text, "14")
	assert_eq(panel.value_labels["vitality"].text, "12")
	assert_eq(panel.value_labels["attack"].text, "29")
	assert_eq(panel.value_labels["defense"].text, "17")
	assert_eq(panel.value_labels["crit_chance"].text, "4%")
	assert_eq(panel.value_labels["speed"].text, "108")


func test_eight_empty_equipment_slots() -> void:
	assert_eq(panel.slots.keys(), ["helmet", "armor", "boots", "necklace", "ring", "cape", "weapon", "shield"])


func test_escape_closes_panel() -> void:
	_open_with_button()
	await press_key(KEY_ESCAPE)
	assert_false(panel.is_open())


func test_escape_with_panel_closed_does_nothing() -> void:
	await press_key(KEY_ESCAPE)
	assert_false(panel.is_open())


func test_close_button_closes_panel() -> void:
	_open_with_button()
	panel.close_button.pressed.emit()
	assert_false(panel.is_open())


func test_click_on_dim_background_closes_panel() -> void:
	_open_with_button()
	panel.dim.gui_input.emit(left_click())
	assert_false(panel.is_open())


func test_dim_blocks_clicks_to_city() -> void:
	assert_eq(panel.dim.mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_eq(panel.dim.anchor_right, 1.0)
	assert_eq(panel.dim.anchor_bottom, 1.0)


func test_open_twice_keeps_panel_open() -> void:
	_open_with_button()
	panel.open()
	assert_true(panel.is_open())


func test_unavailable_buttons_show_coming_soon() -> void:
	bar.buttons["bag"].pressed.emit()
	assert_eq(main.toast.label.text, "Mochila — em breve")
	assert_false(panel.is_open())


func test_unavailable_buttons_look_faded_but_clickable() -> void:
	for id in ["bag", "skills", "quests", "guild", "settings"]:
		var button: Button = bar.buttons[id]
		assert_false(button.disabled, id)
		assert_true(button.modulate.a < 1.0, id)


func test_panel_refreshes_when_player_changes() -> void:
	_open_with_button()
	use_repository(FixedHeroRepository.aldric(5))
	assert_eq(panel.class_level_label.text, "Mago · Nível 5")
	assert_eq(panel.value_labels["attack"].text, "33")
	assert_eq(panel.hp_label.text, "240 / 320")
	assert_eq(panel.xp_label.text, "35 / 1118")


func test_load_failure_disables_character_button_and_closes_panel() -> void:
	_open_with_button()
	use_repository(FailingHeroRepository.new())
	assert_false(panel.is_open())
	assert_true(bar.buttons["character"].disabled)
	panel.open()
	assert_false(panel.is_open(), "não deve abrir sem jogador")


func test_character_button_enabled_again_after_recovery() -> void:
	use_repository(FailingHeroRepository.new())
	use_repository(FixedHeroRepository.aldric())
	assert_false(bar.buttons["character"].disabled)
