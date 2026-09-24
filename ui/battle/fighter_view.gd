class_name FighterView
extends VBoxContainer
## Um lado da tela de combate: nome, nível, barra de HP e a figura (arte se
## existir; senão um placeholder com a inicial). Mostra o dano subindo sobre a figura.

const FIGURE_SIZE := Vector2(220, 250)
const POPUP_TIME := 0.9
const POPUP_START := 70.0  ## Altura (dentro da figura) onde o número de dano aparece.
const POPUP_RISE := 50.0

var name_label: Label
var level_label: Label
var hp_bar: ProgressBar
var hp_label: Label
var initial_label: Label
var damage_label: Label
var _placeholder: Panel
var _art: TextureRect
var _fill: Color
var _tween: Tween


func setup_look(fill: Color) -> FighterView:
	_fill = fill
	return self


func _ready() -> void:
	custom_minimum_size.x = FIGURE_SIZE.x + 40
	add_theme_constant_override("separation", 4)
	name_label = _label(20, Color.WHITE)
	level_label = _label(14, GameTheme.GOLD_LIGHT)
	hp_bar = GameTheme.make_bar(GameTheme.HP_RED, FIGURE_SIZE.x)
	hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(hp_bar)
	hp_label = _label(14, GameTheme.TEXT)
	var figure := Control.new()
	figure.custom_minimum_size = FIGURE_SIZE
	figure.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(figure)
	_placeholder = Panel.new()
	_placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := GameTheme.box(_fill, GameTheme.GOLD_LIGHT, 2, 12)
	style.corner_radius_top_left = 90
	style.corner_radius_top_right = 90
	_placeholder.add_theme_stylebox_override("panel", style)
	figure.add_child(_placeholder)
	initial_label = Label.new()
	initial_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	initial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initial_label.add_theme_font_size_override("font_size", 72)
	initial_label.add_theme_color_override("font_color", Color.WHITE)
	_placeholder.add_child(initial_label)
	_art = TextureRect.new()
	_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	figure.add_child(_art)
	damage_label = Label.new()
	damage_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.add_theme_font_size_override("font_size", 30)
	damage_label.add_theme_color_override("font_outline_color", Color.BLACK)
	damage_label.add_theme_constant_override("outline_size", 6)
	damage_label.visible = false
	figure.add_child(damage_label)


func show_combatant(combatant: Combatant, art_path: String) -> void:
	name_label.text = combatant.combatant_name
	level_label.text = Texts.short_level(combatant.level)
	hp_bar.max_value = combatant.max_hp
	set_hp(combatant.hp)
	initial_label.text = combatant.combatant_name.left(1).to_upper()
	var art := ArtLoader.texture_or_null(art_path)
	_art.texture = art
	_art.visible = art != null
	_placeholder.visible = art == null
	damage_label.visible = false


func set_hp(hp: int) -> void:
	hp_bar.value = hp
	hp_label.text = Texts.fraction(hp, int(hp_bar.max_value))


func show_damage(amount: int, critical: bool) -> void:
	damage_label.text = Texts.damage_popup(amount, critical)
	damage_label.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT if critical else Color.WHITE)
	damage_label.visible = true
	damage_label.modulate.a = 1.0
	damage_label.position.y = POPUP_START
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(damage_label, "position:y", POPUP_START - POPUP_RISE, POPUP_TIME)
	_tween.tween_property(damage_label, "modulate:a", 0.0, POPUP_TIME).set_ease(Tween.EASE_IN)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label
