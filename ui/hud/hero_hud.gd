class_name HeroHud
extends PanelContainer
## Canto superior esquerdo: retrato, nome, nível e barras de HP/XP do herói.

const BAR_WIDTH := 150.0
const NAME_WIDTH := 100.0

var portrait: Portrait
var name_label: Label
var level_label: Label
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var error_label: Label
var _info: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(16, 16)
	_build()
	GameState.player_changed.connect(_on_player_changed)
	GameState.load_failed.connect(_on_load_failed)
	_render()


func _build() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	portrait = Portrait.new()
	portrait.custom_minimum_size = Vector2(56, 56)
	row.add_child(portrait)
	_info = VBoxContainer.new()
	_info.add_theme_constant_override("separation", 3)
	row.add_child(_info)
	var title := HBoxContainer.new()
	_info.add_child(title)
	name_label = Label.new()
	name_label.custom_minimum_size.x = NAME_WIDTH
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_child(name_label)
	level_label = Label.new()
	level_label.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	title.add_child(level_label)
	hp_bar = GameTheme.make_bar(GameTheme.HP_RED, BAR_WIDTH)
	_info.add_child(hp_bar)
	xp_bar = GameTheme.make_bar(GameTheme.GOLD, BAR_WIDTH)
	_info.add_child(xp_bar)
	error_label = Label.new()
	error_label.text = Texts.LOAD_ERROR
	row.add_child(error_label)


func _on_player_changed(_player: Player) -> void:
	_render()


func _on_load_failed(_error: String) -> void:
	_render()


func _render() -> void:
	var player: Player = GameState.player
	_info.visible = player != null
	error_label.visible = player == null
	if player == null:
		portrait.clear()
		return
	var hero := player.hero
	portrait.set_hero(hero)
	name_label.text = hero.hero_name
	level_label.text = Texts.short_level(hero.level)
	hp_bar.max_value = StatFormulas.max_hp(hero)
	hp_bar.value = hero.current_hp
	xp_bar.max_value = StatFormulas.xp_to_next_level(hero.level)
	xp_bar.value = hero.xp
