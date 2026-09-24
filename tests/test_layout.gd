extends BaseTest
## Telas maiores/ultrawide: HUD preso aos cantos, cidade e janela centralizadas.

var main: Node


func before_each() -> void:
	main = add_to_tree(load("res://ui/main.tscn").instantiate())
	await tree.process_frame


func test_bottom_bar_anchored_bottom_right() -> void:
	var bar: BottomBar = main.bottom_bar
	assert_eq(bar.anchor_left, 1.0)
	assert_eq(bar.anchor_top, 1.0)
	assert_eq(bar.grow_horizontal, Control.GROW_DIRECTION_BEGIN)
	assert_eq(bar.grow_vertical, Control.GROW_DIRECTION_BEGIN)


func test_currency_anchored_top_right() -> void:
	assert_eq(main.currency_hud.anchor_left, 1.0)
	assert_eq(main.currency_hud.anchor_top, 0.0)


func test_chat_anchored_bottom_left() -> void:
	assert_eq(main.chat_box.anchor_left, 0.0)
	assert_eq(main.chat_box.anchor_top, 1.0)


func test_hero_hud_anchored_top_left() -> void:
	assert_eq(main.hero_hud.anchor_left, 0.0)
	assert_eq(main.hero_hud.anchor_top, 0.0)


func test_city_stage_centered() -> void:
	var stage: Control = main.city.stage
	assert_eq(stage.anchor_left, 0.5)
	assert_eq(stage.anchor_top, 0.5)
	assert_eq(stage.offset_left, -640.0)
	assert_eq(stage.offset_top, -360.0)


func test_background_art_aligns_with_stage_on_wide_screens() -> void:
	# A arte de fundo tem os lugares das construções pintados: precisa coincidir com o palco.
	var original_size := tree.root.size
	for screen_size in [Vector2i(2560, 1080), Vector2i(1280, 800), Vector2i(1280, 720)]:
		tree.root.size = screen_size
		await tree.process_frame
		var city: CityScreen = main.city
		assert_eq(city.background_rect(), city.stage.get_rect(), str(screen_size))
	tree.root.size = original_size
	await tree.process_frame


func test_panel_window_centered() -> void:
	var window: PanelContainer = main.character_panel.window
	assert_eq(window.anchor_left, 0.5)
	assert_eq(window.anchor_top, 0.5)
