class_name IconView
extends Control
## Ícone de assets/ se existir; senão, um círculo colorido com uma letra.

var _texture: Texture2D
var _color: Color
var _letter: String


func setup(path: String, placeholder_color: Color, letter: String, icon_size: Vector2) -> IconView:
	_texture = ArtLoader.texture_or_null(path)
	_color = placeholder_color
	_letter = letter
	custom_minimum_size = icon_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self


func has_art() -> bool:
	return _texture != null


func _draw() -> void:
	if _texture != null:
		draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false)
		return
	var radius := minf(size.x, size.y) / 2.0
	draw_circle(size / 2.0, radius, _color)
	var font := get_theme_default_font()
	var font_size := int(radius)
	var text_size := font.get_string_size(_letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := Vector2((size.x - text_size.x) / 2.0,
		(size.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0)
	draw_string(font, baseline, _letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
