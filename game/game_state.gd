extends Node
## Autoload "GameState": dono do Player atual. A UI só lê daqui e escuta
## os sinais; nunca altera os dados diretamente.

signal player_changed(player: Player)
signal load_failed(error: String)

var repository: HeroRepository = LocalHeroRepository.new()
var player: Player = null
var load_error := ""


func _ready() -> void:
	reload()


func reload() -> void:
	var result := repository.load_player()
	if result.is_ok():
		player = result.player
		load_error = ""
		player_changed.emit(player)
	else:
		player = null
		load_error = result.error
		push_error("GameState: " + load_error)
		load_failed.emit(load_error)


func has_player() -> bool:
	return player != null
