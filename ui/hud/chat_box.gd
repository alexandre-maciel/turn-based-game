class_name ChatBox
extends PanelContainer
## Caixa de chat do canto inferior esquerdo. Só visual no MVP (não bloqueia cliques).

const BOX_SIZE := Vector2(420, 140)

var log_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	offset_left = 16
	offset_right = 16 + BOX_SIZE.x
	offset_top = -16 - BOX_SIZE.y
	offset_bottom = -16
	add_theme_stylebox_override("panel", GameTheme.box(Color(0, 0, 0, 0.45), Color.TRANSPARENT, 0, 4))
	log_label = Label.new()
	log_label.text = Texts.CHAT_TEXT
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_label.add_theme_font_size_override("font_size", 13)
	add_child(log_label)
