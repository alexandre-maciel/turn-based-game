class_name GameWindow
extends Control
## Base das janelas (Personagem, Treino...): fundo escurecido que bloqueia a
## cidade, janela centralizada com título e ✕. Fecha no ✕, com Esc ou com
## clique no fundo. As subclasses definem _window_title(), _window_size() e
## montam o conteúdo em _build_content(body).

var dim: ColorRect
var window: PanelContainer
var close_button: Button


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_frame()


func _window_title() -> String:
	return ""


func _window_size() -> Vector2:
	return Vector2(600, 400)


func _build_content(_body: VBoxContainer) -> void:
	pass


func close() -> void:
	visible = false


func is_open() -> bool:
	return visible


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()


func _build_frame() -> void:
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_gui_input)
	add_child(dim)
	var window_size := _window_size()
	window = PanelContainer.new()
	window.set_anchors_preset(Control.PRESET_CENTER)
	window.offset_left = -window_size.x / 2.0
	window.offset_right = window_size.x / 2.0
	window.offset_top = -window_size.y / 2.0
	window.offset_bottom = window_size.y / 2.0
	add_child(window)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	window.add_child(layout)
	layout.add_child(_build_title_bar())
	layout.add_child(HSeparator.new())
	var body := VBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)
	_build_content(body)


func _build_title_bar() -> Control:
	var bar := HBoxContainer.new()
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(36, 0)
	bar.add_child(spacer)
	var title := Label.new()
	title.text = _window_title()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	bar.add_child(title)
	close_button = Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(36, 36)
	close_button.pressed.connect(close)
	bar.add_child(close_button)
	return bar
