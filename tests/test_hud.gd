extends BaseTest
## HUD: herói, moedas, chat e o estado de erro.

var main: Node


func before_each() -> void:
	main = add_to_tree(load("res://ui/main.tscn").instantiate())
	await tree.process_frame


func test_hero_hud_shows_sample_hero() -> void:
	var hud: HeroHud = main.hero_hud
	assert_eq(hud.name_label.text, "Aldric")
	assert_eq(hud.level_label.text, "Nv 1")
	assert_eq(hud.hp_bar.max_value, 240.0)
	assert_eq(hud.hp_bar.value, 240.0)
	assert_eq(hud.xp_bar.max_value, 100.0)
	assert_eq(hud.xp_bar.value, 35.0)
	assert_eq(hud.portrait.initial, "A")
	assert_false(hud.error_label.visible)


func test_currency_hud_formats_values() -> void:
	assert_eq(main.currency_hud.gold_label.text, "1.250")
	assert_eq(main.currency_hud.gems_label.text, "20")


func test_currency_hud_large_values() -> void:
	use_repository(FixedHeroRepository.aldric(1, "Aldric", 1234567))
	assert_eq(main.currency_hud.gold_label.text, "1.234.567")


func test_chat_box_shows_welcome() -> void:
	assert_true(main.chat_box.log_label.text.contains("Bem-vindo a Eldoria!"))


func test_load_failure_shows_error_and_hides_currencies() -> void:
	use_repository(FailingHeroRepository.new())
	assert_true(main.hero_hud.error_label.visible)
	assert_eq(main.hero_hud.error_label.text, Texts.LOAD_ERROR)
	assert_false(main.currency_hud.visible)
	assert_eq(main.hero_hud.portrait.initial, "?")


func test_hud_recovers_when_player_loads_again() -> void:
	use_repository(FailingHeroRepository.new())
	use_repository(FixedHeroRepository.aldric(5))
	assert_false(main.hero_hud.error_label.visible)
	assert_true(main.currency_hud.visible)
	assert_eq(main.hero_hud.level_label.text, "Nv 5")


func test_long_name_does_not_stretch_hud() -> void:
	use_repository(FixedHeroRepository.aldric(1, "Bartholomew Maximilian Von Eldoria"))
	await tree.process_frame
	assert_eq(main.hero_hud.name_label.text, "Bartholomew Maximilian Von Eldoria")
	assert_true(main.hero_hud.get_combined_minimum_size().x < 400.0,
		"largura mínima do HUD: %s" % main.hero_hud.get_combined_minimum_size().x)


func test_chat_box_does_not_block_clicks() -> void:
	assert_eq(main.chat_box.mouse_filter, Control.MOUSE_FILTER_IGNORE)
