class_name BattleScreen
extends Control
## Tela de combate (tela inteira, bloqueia a cidade). A cada ação, o Battle
## resolve a rodada e a tela exibe os eventos um por um. No fim, mostra o
## resultado; "Voltar à cidade" (ou a fuga) emite `finished` e o main aplica
## o resultado no GameState conforme a origem (Treino ou Torre).

signal finished(battle: Battle)

const BACKGROUND_PATH := "res://assets/battle/background.png"
const SKY := Color("#6d8db0")
const GROUND := Color("#4d6b39")
const HORIZON := 0.55
const HERO_FILL := Color("#7a5230")
const ENEMY_FILL := Color("#6b2f2a")
const LOG_LINES := 5
const ACTION_IDS: Array[String] = ["attack", "skill", "defend", "flee"]
const ACTIONS := {
	"attack": Battle.Action.ATTACK,
	"skill": Battle.Action.SKILL,
	"defend": Battle.Action.DEFEND,
	"flee": Battle.Action.FLEE,
}

## Intervalo entre os eventos da rodada. Os testes usam 0.
var event_delay := 0.5
## null: sorteio de verdade. Os testes trocam por um FixedDice.
var dice: Dice = null
var battle: Battle
var round_label: Label
var hero_view: FighterView
var enemy_view: FighterView
var log_label: Label
var action_buttons: Dictionary = {}  ## attack/skill/defend/flee -> Button
var result_dim: ColorRect
var result_box: PanelContainer
var result_title: Label
var result_text: Label
var back_button: Button
var _log_lines: Array[String] = []
var _busy := false
var _background: Texture2D


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_background = ArtLoader.texture_or_null(BACKGROUND_PATH)
	resized.connect(queue_redraw)
	_build()


## `start_hp`: HP inicial do herói (a Torre passa o HP da escalada); -1 usa o do herói.
func start(enemy: Enemy, start_hp: int = -1) -> void:
	var hero: Hero = GameState.player.hero
	battle = Battle.new(hero, enemy, dice if dice != null else Dice.new(), start_hp)
	hero_view.show_combatant(battle.hero, "res://assets/portraits/%s_full.png" % hero.hero_class)
	enemy_view.show_combatant(battle.enemy, "res://assets/enemies/%s.png" % enemy.id)
	_log_lines.clear()
	log_label.text = ""
	_set_result_visible(false)
	_busy = false
	_refresh_controls()
	visible = true


func is_active() -> bool:
	return visible


## Joga uma rodada com a ação escolhida. Os botões chamam isto.
func play(action: Battle.Action) -> void:
	if _busy or battle == null:
		return
	var events := battle.play_round(action)
	if events.is_empty():
		return
	_busy = true
	_refresh_controls()
	for event in events:
		_show_event(event)
		if event_delay > 0.0:
			await get_tree().create_timer(event_delay).timeout
	_busy = false
	if battle.outcome == Battle.Outcome.FLED:
		_leave()
		return
	if battle.is_over():
		_show_result()
	_refresh_controls()


func _unhandled_input(event: InputEvent) -> void:
	# Esc não fecha o combate; para sair, Fugir.
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()


func _show_event(event: BattleEvent) -> void:
	if event.kind == BattleEvent.Kind.HIT:
		var view := hero_view if event.target == battle.hero else enemy_view
		view.set_hp(event.target_hp_after)
		view.show_damage(event.damage, event.critical)
	_log_lines.append(Texts.battle_log(event, battle.skill["id"]))
	while _log_lines.size() > LOG_LINES:
		_log_lines.pop_front()
	log_label.text = "\n".join(_log_lines)


func _show_result() -> void:
	var lines: Array[String] = []
	if battle.outcome == Battle.Outcome.VICTORY:
		result_title.text = Texts.VICTORY
		var enemy := battle.enemy_data
		lines.append(Texts.xp_gain(enemy.xp_reward))
		lines.append(Texts.gold_gain(enemy.gold_reward))
		var hero: Hero = GameState.player.hero
		var new_level := Progression.after_xp(hero.level, hero.xp, enemy.xp_reward).x
		if new_level > hero.level:
			lines.append(Texts.level_up(new_level))
	else:
		result_title.text = Texts.DEFEAT
		lines.append(Texts.DEFEAT_TEXT)
	result_text.text = "\n".join(lines)
	_set_result_visible(true)


## Fecha a tela e avisa o main, que aplica o resultado.
func _leave() -> void:
	visible = false
	_set_result_visible(false)
	finished.emit(battle)


func _set_result_visible(value: bool) -> void:
	result_dim.visible = value
	result_box.visible = value


func _refresh_controls() -> void:
	round_label.text = Texts.battle_round(battle.round)
	var locked := _busy or battle.is_over()
	for id in ACTION_IDS:
		action_buttons[id].disabled = locked
	action_buttons["skill"].disabled = locked or not battle.can_use_skill()
	action_buttons["skill"].text = Texts.skill_button(battle.skill["id"], battle.skill_cooldown)


func _draw() -> void:
	if _background != null:
		draw_texture_rect(_background, Rect2(Vector2.ZERO, size), false)
		return
	var horizon_y := size.y * HORIZON
	draw_rect(Rect2(0, 0, size.x, horizon_y), SKY)
	draw_rect(Rect2(0, horizon_y, size.x, size.y - horizon_y), GROUND)


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	round_label = Label.new()
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_label.add_theme_font_size_override("font_size", 24)
	round_label.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	round_label.add_theme_color_override("font_outline_color", GameTheme.BROWN_DARK)
	round_label.add_theme_constant_override("outline_size", 6)
	layout.add_child(round_label)
	var arena := HBoxContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.add_theme_constant_override("separation", 260)
	layout.add_child(arena)
	hero_view = FighterView.new().setup_look(HERO_FILL)
	arena.add_child(hero_view)
	enemy_view = FighterView.new().setup_look(ENEMY_FILL)
	arena.add_child(enemy_view)
	var log_box := PanelContainer.new()
	log_box.custom_minimum_size = Vector2(700, 0)
	log_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(log_box)
	log_label = Label.new()
	log_label.custom_minimum_size.y = LOG_LINES * 25
	log_label.add_theme_font_size_override("font_size", 15)
	log_box.add_child(log_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	layout.add_child(actions)
	for id in ACTION_IDS:
		var button := Button.new()
		button.text = Texts.BATTLE_ACTIONS.get(id, "")
		button.custom_minimum_size = Vector2(160, 48)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(play.bind(ACTIONS[id]))
		actions.add_child(button)
		action_buttons[id] = button
	_build_result_box()


func _build_result_box() -> void:
	result_dim = ColorRect.new()
	result_dim.color = Color(0, 0, 0, 0.45)
	result_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_dim.visible = false
	add_child(result_dim)
	result_box = PanelContainer.new()
	result_box.visible = false
	result_box.set_anchors_preset(Control.PRESET_CENTER)
	result_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	result_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	result_box.custom_minimum_size = Vector2(380, 0)
	add_child(result_box)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	result_box.add_child(column)
	result_title = Label.new()
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 30)
	result_title.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	column.add_child(result_title)
	result_text = Label.new()
	result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(result_text)
	back_button = Button.new()
	back_button.text = Texts.BACK_TO_CITY
	back_button.custom_minimum_size = Vector2(200, 44)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(_leave)
	column.add_child(back_button)
