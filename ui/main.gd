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
@onready var battle_screen: BattleScreen = $BattleLayer/BattleScreen


func _enter_tree() -> void:
	# CanvasLayer não repassa tema: aplica em cada Control raiz.
	var theme := GameTheme.get_theme()
	for path in ["CityScreen", "HUDLayer/HUD", "WindowLayer/CharacterPanel",
			"WindowLayer/TrainingPanel", "BattleLayer/BattleScreen"]:
		(get_node(path) as Control).theme = theme


func _ready() -> void:
	city.building_clicked.connect(_on_building_clicked)
	bottom_bar.character_pressed.connect(character_panel.open)
	bottom_bar.unavailable_pressed.connect(_show_coming_soon)
	training_panel.fight_pressed.connect(_on_fight_pressed)
	battle_screen.finished.connect(_on_battle_finished)


func _on_building_clicked(building_id: String, display_name: String) -> void:
	if building_id != "training":
		_show_coming_soon(display_name)
	elif not GameState.has_player():
		toast.show_message(Texts.LOAD_ERROR)
	else:
		training_panel.open()


func _on_fight_pressed(enemy: Enemy) -> void:
	training_panel.close()
	battle_screen.start(enemy)


func _on_battle_finished(outcome: Battle.Outcome) -> void:
	if outcome == Battle.Outcome.FLED:
		toast.show_message(Texts.FLED)


func _show_coming_soon(display_name: String) -> void:
	toast.show_message(Texts.coming_soon(display_name))
