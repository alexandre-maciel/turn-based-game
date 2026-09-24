extends Node
## Cena principal: liga a cidade, o HUD, a barra de menu e o painel entre si.

@onready var city: CityScreen = $CityScreen
@onready var hero_hud: HeroHud = $HUDLayer/HUD/HeroHud
@onready var currency_hud: CurrencyHud = $HUDLayer/HUD/CurrencyHud
@onready var chat_box: ChatBox = $HUDLayer/HUD/ChatBox
@onready var bottom_bar: BottomBar = $HUDLayer/HUD/BottomBar
@onready var toast: Toast = $HUDLayer/HUD/Toast
@onready var character_panel: CharacterPanel = $WindowLayer/CharacterPanel


func _enter_tree() -> void:
	# CanvasLayer não repassa tema: aplica em cada Control raiz.
	var theme := GameTheme.get_theme()
	for path in ["CityScreen", "HUDLayer/HUD", "WindowLayer/CharacterPanel"]:
		(get_node(path) as Control).theme = theme


func _ready() -> void:
	city.building_clicked.connect(_on_building_clicked)
	bottom_bar.character_pressed.connect(character_panel.open)
	bottom_bar.unavailable_pressed.connect(_show_coming_soon)


func _on_building_clicked(_building_id: String, display_name: String) -> void:
	_show_coming_soon(display_name)


func _show_coming_soon(display_name: String) -> void:
	toast.show_message(Texts.coming_soon(display_name))
