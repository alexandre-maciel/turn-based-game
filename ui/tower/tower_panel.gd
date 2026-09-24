class_name TowerPanel
extends GameWindow
## Janela da Torre: andar atual, recorde, HP da escalada e o próximo inimigo.
## "Subir" pede o combate; "Recomeçar" abandona a escalada.

signal climb_pressed(enemy: Enemy, start_hp: int)

const WINDOW_SIZE := Vector2(560, 350)

var floor_label: Label
var best_label: Label
var hp_bar: ProgressBar
var hp_label: Label
var enemy_name_label: Label
var enemy_level_label: Label
var boss_label: Label
var rewards_label: Label
var climb_button: Button
var restart_button: Button
var _enemy: Enemy


func _ready() -> void:
	super()
	GameState.player_changed.connect(_on_player_changed)
	GameState.load_failed.connect(_on_load_failed)


func _window_title() -> String:
	return Texts.BUILDINGS["tower"]


func _window_size() -> Vector2:
	return WINDOW_SIZE


func open() -> void:
	if not GameState.has_player():
		return
	_render()
	visible = true


func _on_player_changed(_player: Player) -> void:
	if visible:
		_render()


func _on_load_failed(_error: String) -> void:
	close()


func _render() -> void:
	var player: Player = GameState.player
	var tower := player.tower
	var max_hp := StatFormulas.max_hp(player.hero)
	floor_label.text = Texts.tower_floor(tower.floor_number)
	best_label.text = Texts.tower_best(tower.best_floor)
	hp_bar.max_value = max_hp
	hp_bar.value = tower.hp
	hp_label.text = Texts.fraction(tower.hp, max_hp)
	_enemy = Tower.enemy_for_floor(tower.floor_number)
	enemy_name_label.text = _enemy.enemy_name
	enemy_level_label.text = Texts.short_level(_enemy.level)
	boss_label.visible = Tower.is_boss(tower.floor_number)
	rewards_label.text = Texts.rewards(_enemy.xp_reward, _enemy.gold_reward)
	restart_button.disabled = tower.floor_number == 1 and tower.hp >= max_hp


func _build_content(body: VBoxContainer) -> void:
	body.add_theme_constant_override("separation", 10)
	floor_label = _centered_label(body, 30, GameTheme.GOLD_LIGHT)
	best_label = _centered_label(body, 15, GameTheme.TEXT)
	var vitals := PanelContainer.new()
	vitals.add_theme_stylebox_override("panel", GameTheme.inner_box())
	body.add_child(vitals)
	var vitals_column := VBoxContainer.new()
	vitals.add_child(vitals_column)
	var hp_row := HBoxContainer.new()
	vitals_column.add_child(hp_row)
	var hp_caption := Label.new()
	hp_caption.text = Texts.TOWER_HP
	hp_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(hp_caption)
	hp_label = Label.new()
	hp_label.add_theme_color_override("font_color", Color.WHITE)
	hp_row.add_child(hp_label)
	hp_bar = GameTheme.make_bar(GameTheme.HP_RED, 0.0)
	vitals_column.add_child(hp_bar)
	body.add_child(_build_enemy_card())
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(spacer)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	body.add_child(buttons)
	climb_button = _button(buttons, Texts.CLIMB)
	climb_button.pressed.connect(_on_climb_pressed)
	restart_button = _button(buttons, Texts.RESTART_CLIMB)
	restart_button.pressed.connect(GameState.reset_tower)


func _build_enemy_card() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", GameTheme.inner_box())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	enemy_name_label = Label.new()
	enemy_name_label.add_theme_color_override("font_color", Color.WHITE)
	enemy_name_label.add_theme_font_size_override("font_size", 18)
	row.add_child(enemy_name_label)
	boss_label = Label.new()
	boss_label.text = Texts.BOSS_TAG
	boss_label.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	boss_label.add_theme_font_size_override("font_size", 13)
	row.add_child(boss_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	enemy_level_label = Label.new()
	row.add_child(enemy_level_label)
	rewards_label = Label.new()
	rewards_label.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	row.add_child(rewards_label)
	return card


func _on_climb_pressed() -> void:
	climb_pressed.emit(_enemy, GameState.player.tower.hp)


func _centered_label(parent: Control, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _button(parent: Control, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 44)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	parent.add_child(button)
	return button
