extends BaseTest
## Cidade: 6 construções nas posições da spec; clique mostra "em breve".

var main: Node


func before_each() -> void:
	main = add_to_tree(load("res://ui/main.tscn").instantiate())
	await tree.process_frame


func test_six_buildings_in_spec_positions() -> void:
	var city: CityScreen = main.city
	assert_eq(city.buildings.keys(), ["castle", "tower", "blacksmith", "market", "arena", "training"])
	var tower: Building = city.buildings["tower"]
	assert_eq(tower.position, Vector2(138, 206))
	assert_eq(tower.size, Vector2(120, 190))
	var castle: Building = city.buildings["castle"]
	assert_eq(castle.position, Vector2(512, 173))
	assert_eq(castle.size, Vector2(230, 187))


func test_click_building_shows_coming_soon_toast() -> void:
	var castle: Building = main.city.buildings["castle"]
	castle._gui_input(left_click())
	assert_true(main.toast.visible)
	assert_eq(main.toast.label.text, "Castelo — em breve")


func test_right_click_does_nothing() -> void:
	var event := left_click()
	event.button_index = MOUSE_BUTTON_RIGHT
	main.city.buildings["arena"]._gui_input(event)
	assert_false(main.toast.visible)


func test_toast_hides_when_timer_ends() -> void:
	main.toast.show_message("x")
	main.toast.hide_timer.timeout.emit()
	assert_false(main.toast.visible)


func test_clicking_again_shows_latest_text_and_restarts_timer() -> void:
	main.city.buildings["castle"]._gui_input(left_click())
	main.city.buildings["market"]._gui_input(left_click())
	assert_eq(main.toast.label.text, "Mercado — em breve")
	assert_true(main.toast.hide_timer.time_left > Toast.DURATION - 0.2)


func test_hover_highlights_building() -> void:
	var market: Building = main.city.buildings["market"]
	market.mouse_entered.emit()
	assert_true(market.is_hovered())
	assert_true(market.modulate != Color.WHITE)
	market.mouse_exited.emit()
	assert_false(market.is_hovered())
	assert_eq(market.modulate, Color.WHITE)


func test_buildings_use_pointing_hand_cursor() -> void:
	for building: Building in main.city.buildings.values():
		assert_eq(building.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND, building.building_id)
