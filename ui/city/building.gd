class_name Building
extends Control
## Uma construção clicável da cidade. Usa assets/city/<id>.png se existir;
## senão desenha um placeholder (paredes, telhado e porta). O nome aparece embaixo.

signal clicked

const WALL := Color("#8a6a4a")
const WALL_BORDER := Color("#3b2a1a")
const ROOF := Color("#a33a2a")
const DOOR := Color("#4a3020")
const HOVER_TINT := Color(1.25, 1.2, 1.0)
const NAME_FONT_SIZE := 14

var building_id: String
var display_name: String
var _texture: Texture2D
var _hovered := false


func setup(p_id: String, p_display_name: String, rect: Rect2) -> void:
	building_id = p_id
	display_name = p_display_name
	position = rect.position
	size = rect.size
	tooltip_text = p_display_name
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_texture = ArtLoader.texture_or_null("res://assets/city/%s.png" % p_id)


func _ready() -> void:
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))


func is_hovered() -> bool:
	return _hovered


func _set_hovered(value: bool) -> void:
	_hovered = value
	modulate = HOVER_TINT if value else Color.WHITE


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
		accept_event()


func _draw() -> void:
	if _texture != null:
		draw_texture_rect(_texture, _fit(_texture.get_size()), false)
	else:
		_draw_placeholder()
	_draw_name()


func _draw_placeholder() -> void:
	var roof_height := size.y * 0.35
	var walls := Rect2(0, roof_height, size.x, size.y - roof_height)
	draw_rect(walls, WALL)
	draw_rect(walls, WALL_BORDER, false, 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x / 2.0, 0), Vector2(size.x, roof_height), Vector2(0, roof_height)]), ROOF)
	var door_size := Vector2(size.x * 0.18, walls.size.y * 0.45)
	draw_rect(Rect2(Vector2((size.x - door_size.x) / 2.0, size.y - door_size.y), door_size), DOOR)


func _draw_name() -> void:
	var font := get_theme_default_font()
	var text_width := font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE).x
	var baseline := Vector2((size.x - text_width) / 2.0, size.y - 6)
	draw_string_outline(font, baseline, display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE, 4, Color.BLACK)
	draw_string(font, baseline, display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE, Color.WHITE)


## Encaixa a arte na caixa mantendo a proporção, alinhada embaixo e no centro.
func _fit(texture_size: Vector2) -> Rect2:
	var factor := minf(size.x / texture_size.x, size.y / texture_size.y)
	var draw_size := texture_size * factor
	return Rect2(Vector2((size.x - draw_size.x) / 2.0, size.y - draw_size.y), draw_size)
