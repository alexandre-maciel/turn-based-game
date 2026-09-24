class_name GameTheme
extends RefCounted
## Tema visual único (marrom e dourado). CanvasLayer não repassa tema, então
## main.gd aplica get_theme() em cada Control raiz. Se
## assets/ui/panel_frame.png existir, as janelas usam essa moldura (9-slice, bordas de 24 px).

const BROWN := Color("#3d2a16")
const BROWN_DARK := Color("#2a1c0e")
const GOLD := Color("#c9a24a")
const GOLD_LIGHT := Color("#e8c56a")
const TEXT := Color("#f3e2b3")
const HP_RED := Color("#c0392b")
const INNER_BORDER := Color("#6b5020")
const PANEL_FRAME_PATH := "res://assets/ui/panel_frame.png"
const FRAME_BORDER := 24

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


static func panel_style() -> StyleBox:
	var frame := ArtLoader.texture_or_null(PANEL_FRAME_PATH)
	if frame == null:
		return box(BROWN, GOLD, 3, 8)
	return frame_style(frame)


## Moldura 9-slice a partir da arte (bordas de FRAME_BORDER px).
static func frame_style(frame: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = frame
	style.texture_margin_left = FRAME_BORDER
	style.texture_margin_top = FRAME_BORDER
	style.texture_margin_right = FRAME_BORDER
	style.texture_margin_bottom = FRAME_BORDER
	# O conteúdo começa depois da borda desenhada, senão o texto fica por cima dela.
	style.set_content_margin_all(FRAME_BORDER)
	return style


static func box(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(6)
	return style


## Caixa escura de dentro das janelas (blocos, listas).
static func inner_box() -> StyleBoxFlat:
	return box(Color(0, 0, 0, 0.25), INNER_BORDER, 1, 4)


static func make_bar(fill: Color, min_width: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(min_width, 10)
	bar.add_theme_stylebox_override("fill", box(fill, Color.TRANSPARENT, 0, 3))
	return bar


static func _build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16
	theme.set_color("font_color", "Label", TEXT)
	theme.set_stylebox("panel", "PanelContainer", panel_style())
	theme.set_stylebox("panel", "Panel", panel_style())
	theme.set_stylebox("normal", "Button", box(BROWN, GOLD, 2, 6))
	theme.set_stylebox("hover", "Button", box(BROWN.lightened(0.15), GOLD_LIGHT, 2, 6))
	theme.set_stylebox("pressed", "Button", box(BROWN_DARK, GOLD_LIGHT, 2, 6))
	theme.set_stylebox("disabled", "Button", box(BROWN_DARK, GOLD.darkened(0.5), 2, 6))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", GOLD_LIGHT)
	theme.set_color("font_pressed_color", "Button", GOLD_LIGHT)
	theme.set_color("font_disabled_color", "Button", Color(TEXT, 0.4))
	theme.set_stylebox("background", "ProgressBar", box(Color("#222222"), Color.TRANSPARENT, 0, 3))
	theme.set_stylebox("fill", "ProgressBar", box(GOLD, Color.TRANSPARENT, 0, 3))
	return theme
