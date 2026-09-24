class_name Portrait
extends Control
## Retrato redondo do herói. Usa assets/portraits/<classe>_face.png se existir
## (recortado em círculo); senão, um círculo com a inicial do nome.

const FILL := Color("#7a5230")
const SEGMENTS := 48

var initial := "?"
var _texture: Texture2D


func set_hero(hero: Hero) -> void:
	_texture = ArtLoader.texture_or_null("res://assets/portraits/%s_face.png" % hero.hero_class)
	initial = hero.hero_name.left(1).to_upper()
	queue_redraw()


func clear() -> void:
	_texture = null
	initial = "?"
	queue_redraw()


func has_art() -> bool:
	return _texture != null


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in SEGMENTS:
		var angle := TAU * i / SEGMENTS
		var point := center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
		uvs.append(point / size)
	if _texture != null:
		draw_colored_polygon(points, Color.WHITE, uvs, _texture)
	else:
		draw_colored_polygon(points, FILL)
		_draw_initial(center, radius)
	draw_circle(center, radius - 1.0, GameTheme.GOLD_LIGHT, false, 2.0)


func _draw_initial(center: Vector2, radius: float) -> void:
	var font := get_theme_default_font()
	var font_size := int(radius)
	var text_size := font.get_string_size(initial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := center + Vector2(-text_size.x / 2.0,
		(font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0)
	draw_string(font, baseline, initial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
