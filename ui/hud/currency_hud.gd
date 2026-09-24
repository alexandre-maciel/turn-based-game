class_name CurrencyHud
extends HBoxContainer
## Canto superior direito: ouro e gemas do jogador.

const GOLD_COLOR := Color("#d4a017")
const GEMS_COLOR := Color("#3aa0d8")

var gold_label: Label
var gems_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_left = -16
	offset_right = -16
	offset_top = 16
	offset_bottom = 16
	add_theme_constant_override("separation", 8)
	gold_label = _add_pill("res://assets/icons/gold.png", GOLD_COLOR, "O")
	gems_label = _add_pill("res://assets/icons/gems.png", GEMS_COLOR, "G")
	GameState.player_changed.connect(_on_player_changed)
	GameState.load_failed.connect(_on_load_failed)
	_render()


func _add_pill(icon_path: String, color: Color, letter: String) -> Label:
	var pill := PanelContainer.new()
	add_child(pill)
	var row := HBoxContainer.new()
	pill.add_child(row)
	row.add_child(IconView.new().setup(icon_path, color, letter, Vector2(24, 24)))
	var label := Label.new()
	row.add_child(label)
	return label


func _on_player_changed(_player: Player) -> void:
	_render()


func _on_load_failed(_error: String) -> void:
	_render()


func _render() -> void:
	var player: Player = GameState.player
	visible = player != null
	if player == null:
		return
	gold_label.text = Texts.thousands(player.gold)
	gems_label.text = Texts.thousands(player.gems)
