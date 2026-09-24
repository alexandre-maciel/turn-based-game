class_name TrainingPanel
extends GameWindow
## Janela "Campo de Treino": um inimigo por linha, com nível, recompensas e
## botão Lutar. Nível acima do herói aparece em vermelho (só aviso).

signal fight_pressed(enemy: Enemy)

const WINDOW_SIZE := Vector2(620, 400)
const WARNING := Color("#e0604e")

var error_label: Label
var list: VBoxContainer
var fight_buttons: Dictionary = {}  ## enemy_id -> Button
var level_labels: Dictionary = {}  ## enemy_id -> Label


func _ready() -> void:
	super()
	GameState.player_changed.connect(_on_player_changed)
	GameState.load_failed.connect(_on_load_failed)


func _window_title() -> String:
	return Texts.TRAINING_TITLE


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


func _build_content(body: VBoxContainer) -> void:
	error_label = Label.new()
	error_label.text = Texts.ENEMIES_LOAD_ERROR
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.visible = false
	body.add_child(error_label)
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	body.add_child(list)


func _render() -> void:
	for child in list.get_children():
		child.free()
	fight_buttons.clear()
	level_labels.clear()
	error_label.visible = GameState.enemies_error != ""
	var hero_level: int = GameState.player.hero.level
	for enemy in GameState.enemies:
		list.add_child(_make_row(enemy, hero_level))


func _make_row(enemy: Enemy, hero_level: int) -> Control:
	var row_box := PanelContainer.new()
	row_box.add_theme_stylebox_override("panel", GameTheme.inner_box())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row_box.add_child(row)
	var name_label := Label.new()
	name_label.text = enemy.enemy_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(name_label)
	var level_label := Label.new()
	level_label.text = Texts.short_level(enemy.level)
	level_label.custom_minimum_size.x = 50
	if enemy.level > hero_level:
		level_label.add_theme_color_override("font_color", WARNING)
	row.add_child(level_label)
	level_labels[enemy.id] = level_label
	var rewards := Label.new()
	rewards.text = Texts.rewards(enemy.xp_reward, enemy.gold_reward)
	rewards.custom_minimum_size.x = 170
	rewards.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	row.add_child(rewards)
	var button := Button.new()
	button.text = Texts.FIGHT
	button.custom_minimum_size = Vector2(90, 36)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_on_fight_pressed.bind(enemy))
	row.add_child(button)
	fight_buttons[enemy.id] = button
	return row_box


func _on_fight_pressed(enemy: Enemy) -> void:
	fight_pressed.emit(enemy)
