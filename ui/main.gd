extends Node
## Cena principal: liga a cidade, o HUD, a barra de menu, as janelas e o combate.

@onready var city: CityScreen = $CityScreen
@onready var hero_hud: HeroHud = $HUDLayer/HUD/HeroHud
@onready var currency_hud: CurrencyHud = $HUDLayer/HUD/CurrencyHud
@onready var chat_box: ChatBox = $HUDLayer/HUD/ChatBox
@onready var bottom_bar: BottomBar = $HUDLayer/HUD/BottomBar
@onready var toast: Toast = $HUDLayer/HUD/Toast
@onready var character_panel: CharacterPanel = $WindowLayer/CharacterPanel
@onready var training_panel: TrainingPanel = $WindowLayer/TrainingPanel
@onready var tower_panel: TowerPanel = $WindowLayer/TowerPanel
@onready var battle_screen: BattleScreen = $BattleLayer/BattleScreen

## De onde veio o combate em andamento: decide como o resultado é aplicado.
var _battle_from_tower := false


func _enter_tree() -> void:
	# CanvasLayer não repassa tema: aplica em cada Control raiz.
	var theme := GameTheme.get_theme()
	for path in ["CityScreen", "HUDLayer/HUD", "WindowLayer/CharacterPanel",
			"WindowLayer/TrainingPanel", "WindowLayer/TowerPanel", "BattleLayer/BattleScreen"]:
		(get_node(path) as Control).theme = theme


func _ready() -> void:
	city.building_clicked.connect(_on_building_clicked)
	bottom_bar.character_pressed.connect(character_panel.open)
	bottom_bar.unavailable_pressed.connect(_show_coming_soon)
	training_panel.fight_pressed.connect(_on_fight_pressed)
	tower_panel.climb_pressed.connect(_on_climb_pressed)
	battle_screen.finished.connect(_on_battle_finished)
	GameState.save_failed.connect(_on_save_failed)
	# O GameState carrega antes desta cena existir: o aviso fica guardado nele.
	if GameState.load_warning != "":
		toast.show_message(Texts.SAVE_CORRUPTED)


func _on_building_clicked(building_id: String, display_name: String) -> void:
	var windows := {"training": training_panel, "tower": tower_panel}
	if not windows.has(building_id):
		_show_coming_soon(display_name)
	elif not GameState.has_player():
		toast.show_message(Texts.LOAD_ERROR)
	else:
		windows[building_id].open()


func _on_fight_pressed(enemy: Enemy) -> void:
	training_panel.close()
	_battle_from_tower = false
	battle_screen.start(enemy)


func _on_climb_pressed(enemy: Enemy, start_hp: int) -> void:
	tower_panel.close()
	_battle_from_tower = true
	battle_screen.start(enemy, start_hp)


func _on_battle_finished(battle: Battle) -> void:
	if _battle_from_tower:
		GameState.apply_tower_result(battle)
	else:
		GameState.apply_battle_result(battle)
	if battle.outcome == Battle.Outcome.FLED:
		toast.show_message(Texts.FLED)
	elif _battle_from_tower:
		tower_panel.open()
	_battle_from_tower = false


func _on_save_failed(_error: String) -> void:
	toast.show_message(Texts.SAVE_FAILED)


func _show_coming_soon(display_name: String) -> void:
	toast.show_message(Texts.coming_soon(display_name))
