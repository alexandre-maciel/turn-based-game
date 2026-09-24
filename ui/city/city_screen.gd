class_name CityScreen
extends Control
## Tela da cidade: fundo + construções clicáveis. As construções ficam num
## "palco" fixo de 1280×720 centralizado; telas largas só ganham céu/grama nas laterais.

signal building_clicked(building_id: String, display_name: String)

const STAGE_SIZE := Vector2(1280, 720)
const BACKGROUND_PATH := "res://assets/city/background.png"
const SKY := Color("#9cc3e6")
const GRASS := Color("#5f8a47")
const HORIZON := 0.39  ## Fração da altura do palco onde o céu vira grama.

## Posição e tamanho de cada construção no palco (spec, seção 5).
const LAYOUT := {
	"castle": Rect2(512, 173, 230, 187),
	"tower": Rect2(138, 206, 120, 190),
	"blacksmith": Rect2(320, 360, 141, 108),
	"market": Rect2(819, 317, 154, 115),
	"arena": Rect2(1024, 216, 166, 130),
	"training": Rect2(602, 410, 154, 94),
}

var buildings: Dictionary = {}  ## building_id -> Building
var stage: Control
var _background: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background = ArtLoader.texture_or_null(BACKGROUND_PATH)
	resized.connect(queue_redraw)
	stage = Control.new()
	stage.name = "Stage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.set_anchors_preset(Control.PRESET_CENTER)
	stage.offset_left = -STAGE_SIZE.x / 2.0
	stage.offset_top = -STAGE_SIZE.y / 2.0
	stage.offset_right = STAGE_SIZE.x / 2.0
	stage.offset_bottom = STAGE_SIZE.y / 2.0
	add_child(stage)
	for building_id in LAYOUT:
		var building := Building.new()
		building.setup(building_id, Texts.BUILDINGS[building_id], LAYOUT[building_id])
		building.clicked.connect(_on_building_clicked.bind(building_id))
		stage.add_child(building)
		buildings[building_id] = building


func _on_building_clicked(building_id: String) -> void:
	building_clicked.emit(building_id, Texts.BUILDINGS[building_id])


## Onde a arte de fundo é desenhada: exatamente sobre o palco, para as construções
## caírem nos lugares pintados nela. As sobras da tela ficam com céu e grama.
func background_rect() -> Rect2:
	return Rect2((size - STAGE_SIZE) / 2.0, STAGE_SIZE)


func _draw() -> void:
	var horizon_y := (size.y - STAGE_SIZE.y) / 2.0 + STAGE_SIZE.y * HORIZON
	draw_rect(Rect2(0, 0, size.x, horizon_y), SKY)
	draw_rect(Rect2(0, horizon_y, size.x, size.y - horizon_y), GRASS)
	if _background != null:
		draw_texture_rect(_background, background_rect(), false)
