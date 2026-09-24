class_name BottomBar
extends HBoxContainer
## Barra de menu do canto inferior direito. Só "Personagem" funciona no MVP;
## os outros botões ficam esmaecidos e avisam "em breve".

signal character_pressed
signal unavailable_pressed(display_name: String)

const BUTTON_IDS: Array[String] = ["character", "bag", "skills", "quests", "guild", "settings"]
const BUTTON_SIZE := Vector2(76, 76)
const ICON_SIZE := Vector2(36, 36)
const ICON_COLOR := Color("#7a5230")
const UNAVAILABLE_ALPHA := 0.45

var buttons: Dictionary = {}  ## id -> Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = -16
	offset_right = -16
	offset_top = -16
	offset_bottom = -16
	add_theme_constant_override("separation", 6)
	for id in BUTTON_IDS:
		var button := _make_button(id)
		buttons[id] = button
		add_child(button)
	GameState.player_changed.connect(_on_player_changed)
	GameState.load_failed.connect(_on_load_failed)
	_refresh_character_button()


func _make_button(id: String) -> Button:
	var display_name: String = Texts.MENU[id]
	var button := Button.new()
	button.custom_minimum_size = BUTTON_SIZE
	button.tooltip_text = display_name
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)
	var icon := IconView.new().setup("res://assets/icons/%s.png" % id, ICON_COLOR, display_name.left(1), ICON_SIZE)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(icon)
	var caption := Label.new()
	caption.text = display_name
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_theme_font_size_override("font_size", 11)
	content.add_child(caption)
	if id == "character":
		button.pressed.connect(_on_character_pressed)
	else:
		button.modulate.a = UNAVAILABLE_ALPHA
		button.pressed.connect(_on_unavailable_pressed.bind(display_name))
	return button


func _on_character_pressed() -> void:
	character_pressed.emit()


func _on_unavailable_pressed(display_name: String) -> void:
	unavailable_pressed.emit(display_name)


func _on_player_changed(_player: Player) -> void:
	_refresh_character_button()


func _on_load_failed(_error: String) -> void:
	_refresh_character_button()


func _refresh_character_button() -> void:
	buttons["character"].disabled = not GameState.has_player()
