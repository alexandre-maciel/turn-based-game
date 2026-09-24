extends BaseTest
## Tema visual único.


func test_theme_is_shared_instance() -> void:
	assert_true(GameTheme.get_theme() == GameTheme.get_theme())


func test_label_uses_text_color() -> void:
	assert_eq(GameTheme.get_theme().get_color("font_color", "Label"), GameTheme.TEXT)


func test_panel_style_follows_frame_art() -> void:
	# Sem assets/ui/panel_frame.png: moldura desenhada. Com a arte: 9-slice da imagem.
	if ResourceLoader.exists(GameTheme.PANEL_FRAME_PATH):
		assert_true(GameTheme.panel_style() is StyleBoxTexture)
	else:
		assert_true(GameTheme.panel_style() is StyleBoxFlat)


func test_frame_art_keeps_text_inside_border() -> void:
	# Com panel_frame.png (bordas de 24 px), o conteúdo começa depois da borda.
	var style := GameTheme.frame_style(load("res://tests/fixtures/pixel.svg"))
	assert_eq(style.texture_margin_left, float(GameTheme.FRAME_BORDER))
	assert_eq(style.get_content_margin(SIDE_LEFT), float(GameTheme.FRAME_BORDER))
	assert_eq(style.get_content_margin(SIDE_TOP), float(GameTheme.FRAME_BORDER))


func test_make_bar() -> void:
	var bar := GameTheme.make_bar(GameTheme.HP_RED, 150.0)
	assert_false(bar.show_percentage)
	assert_eq(bar.custom_minimum_size.x, 150.0)
	bar.free()
