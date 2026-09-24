class_name LoadResult
extends RefCounted
## Resultado de carregar o jogador: ou `player` preenchido, ou `error`.

var player: Player
var error: String = ""
## Carregou, mas há algo a avisar (ex.: save danificado trocado por um jogo novo).
var warning: String = ""


static func success(p_player: Player) -> LoadResult:
	var result := LoadResult.new()
	result.player = p_player
	return result


static func failure(message: String) -> LoadResult:
	var result := LoadResult.new()
	result.error = message
	return result


func is_ok() -> bool:
	return player != null
