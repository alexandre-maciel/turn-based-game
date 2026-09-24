class_name Toast
extends PanelContainer
## Aviso curto no topo da tela (ex.: "Torre — em breve"). Some sozinho.

const DURATION := 2.0

var label: Label
var hide_timer: Timer


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Já dentro da árvore, set_anchors_preset recalcula os offsets: redefina os quatro.
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_left = 0
	offset_right = 0
	offset_top = 96
	offset_bottom = 96
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	hide_timer = Timer.new()
	hide_timer.one_shot = true
	hide_timer.timeout.connect(hide)
	add_child(hide_timer)


func show_message(text: String) -> void:
	label.text = text
	visible = true
	hide_timer.start(DURATION)
