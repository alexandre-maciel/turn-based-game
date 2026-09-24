class_name CharacterPanel
extends GameWindow
## Janela "Personagem" (layout A da spec): herói e 8 slots à esquerda;
## HP/XP, atributos e combate à direita. Só exibe dados do GameState.
## Fecha no X, com Esc ou com clique no fundo escurecido.

const WINDOW_SIZE := Vector2(900, 560)
const SLOT_SIZE := Vector2(64, 64)
const FIGURE_SIZE := Vector2(140, 230)
const FIGURE_CENTER := Vector2(0.5, 0.52)
const FIGURE_FILL := Color("#7a5230")
const SLOT_TEXT := Color("#b99c5e")
const SLOT_ART_PATH := "res://assets/ui/slot_empty.png"
## Centro de cada slot, em fração da área do retrato.
const SLOT_ANCHORS := {
	"helmet": Vector2(0.14, 0.30),
	"armor": Vector2(0.14, 0.52),
	"boots": Vector2(0.14, 0.74),
	"necklace": Vector2(0.86, 0.30),
	"ring": Vector2(0.86, 0.52),
	"cape": Vector2(0.86, 0.74),
	"weapon": Vector2(0.36, 0.90),
	"shield": Vector2(0.64, 0.90),
}

var name_label: Label
var class_level_label: Label
var hp_label: Label
var xp_label: Label
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var value_labels: Dictionary = {}  ## strength..speed -> Label
var slots: Dictionary = {}  ## helmet..shield -> Panel
var _figure_art: TextureRect
var _figure_placeholder: Panel


func _ready() -> void:
	super()
	GameState.player_changed.connect(_on_player_changed)
	GameState.load_failed.connect(_on_load_failed)


func _window_title() -> String:
	return Texts.PANEL_TITLE


func _window_size() -> Vector2:
	return WINDOW_SIZE


func open() -> void:
	if not GameState.has_player():
		return
	_render()
	visible = true


func _on_player_changed(_player: Player) -> void:
	_render()


func _on_load_failed(_error: String) -> void:
	close()


func _render() -> void:
	var player: Player = GameState.player
	if player == null:
		return
	var hero := player.hero
	name_label.text = hero.hero_name
	class_level_label.text = Texts.class_and_level(hero.hero_class, hero.level)
	var max_hp := StatFormulas.max_hp(hero)
	hp_label.text = Texts.fraction(hero.current_hp, max_hp)
	hp_bar.max_value = max_hp
	hp_bar.value = hero.current_hp
	var xp_next := StatFormulas.xp_to_next_level(hero.level)
	xp_label.text = Texts.fraction(hero.xp, xp_next)
	xp_bar.max_value = xp_next
	xp_bar.value = hero.xp
	for attribute in Attributes.NAMES:
		value_labels[attribute].text = str(hero.attributes.get_value(attribute))
	value_labels["attack"].text = str(StatFormulas.attack(hero))
	value_labels["defense"].text = str(StatFormulas.defense(hero))
	value_labels["crit_chance"].text = Texts.percent(StatFormulas.crit_chance(hero))
	value_labels["speed"].text = str(StatFormulas.speed(hero))
	var figure := ArtLoader.texture_or_null("res://assets/portraits/%s_full.png" % hero.hero_class)
	_figure_art.texture = figure
	_figure_art.visible = figure != null
	_figure_placeholder.visible = figure == null


func _build_content(body: VBoxContainer) -> void:
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	body.add_child(columns)
	columns.add_child(_build_paperdoll())
	columns.add_child(_build_stats())


func _build_paperdoll() -> Control:
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_stretch_ratio = 1.1
	frame.add_theme_stylebox_override("panel", GameTheme.inner_box())
	var area := Control.new()
	frame.add_child(area)
	var header := VBoxContainer.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	area.add_child(header)
	name_label = _centered_label(20)
	header.add_child(name_label)
	class_level_label = _centered_label(15)
	class_level_label.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	header.add_child(class_level_label)
	_figure_placeholder = Panel.new()
	var figure_style := GameTheme.box(FIGURE_FILL, GameTheme.GOLD_LIGHT, 2, 12)
	figure_style.corner_radius_top_left = 60
	figure_style.corner_radius_top_right = 60
	_figure_placeholder.add_theme_stylebox_override("panel", figure_style)
	_place(area, _figure_placeholder, FIGURE_CENTER, FIGURE_SIZE)
	_figure_art = TextureRect.new()
	_figure_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_figure_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_figure_art.visible = false
	_place(area, _figure_art, FIGURE_CENTER, FIGURE_SIZE * 1.3)
	for slot_id in SLOT_ANCHORS:
		var slot := _make_slot(Texts.SLOTS[slot_id])
		_place(area, slot, SLOT_ANCHORS[slot_id], SLOT_SIZE)
		slots[slot_id] = slot
	return frame


func _build_stats() -> Control:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	var vitals := _section(column, "")
	hp_label = _add_row(vitals, Texts.HP)
	hp_bar = GameTheme.make_bar(GameTheme.HP_RED, 0.0)
	vitals.add_child(hp_bar)
	xp_label = _add_row(vitals, Texts.XP)
	xp_bar = GameTheme.make_bar(GameTheme.GOLD, 0.0)
	vitals.add_child(xp_bar)
	var attributes := _section(column, Texts.SECTION_ATTRIBUTES)
	for key in Texts.ATTRIBUTES:
		value_labels[key] = _add_row(attributes, Texts.ATTRIBUTES[key])
	var combat := _section(column, Texts.SECTION_COMBAT)
	for key in Texts.COMBAT_STATS:
		value_labels[key] = _add_row(combat, Texts.COMBAT_STATS[key])
	return column


## Bloco com fundo escuro (e título, se houver). Devolve a coluna interna.
func _section(parent: Control, title: String) -> VBoxContainer:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", GameTheme.inner_box())
	parent.add_child(box)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 2)
	box.add_child(inner)
	if title != "":
		var heading := Label.new()
		heading.text = title.to_upper()
		heading.add_theme_font_size_override("font_size", 13)
		heading.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
		inner.add_child(heading)
	return inner


## Linha "Nome ........ valor". Devolve o Label do valor.
func _add_row(parent: Control, caption: String) -> Label:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var caption_label := Label.new()
	caption_label.text = caption
	caption_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(caption_label)
	var value := Label.new()
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(value)
	return value


func _make_slot(caption: String) -> Panel:
	var slot := Panel.new()
	var art := ArtLoader.texture_or_null(SLOT_ART_PATH)
	if art != null:
		var style := StyleBoxTexture.new()
		style.texture = art
		slot.add_theme_stylebox_override("panel", style)
	else:
		slot.add_theme_stylebox_override("panel", GameTheme.box(Color(0, 0, 0, 0.35), GameTheme.GOLD.darkened(0.2), 1, 4))
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", SLOT_TEXT)
	slot.add_child(label)
	return slot


## Coloca `child` centralizado no ponto `anchor` (fração do tamanho de `parent`).
func _place(parent: Control, child: Control, anchor: Vector2, child_size: Vector2) -> void:
	child.anchor_left = anchor.x
	child.anchor_right = anchor.x
	child.anchor_top = anchor.y
	child.anchor_bottom = anchor.y
	child.offset_left = -child_size.x / 2.0
	child.offset_right = child_size.x / 2.0
	child.offset_top = -child_size.y / 2.0
	child.offset_bottom = child_size.y / 2.0
	parent.add_child(child)


func _centered_label(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label
