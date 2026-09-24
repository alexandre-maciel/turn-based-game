class_name EnemyLoadResult
extends RefCounted
## Resultado de carregar os inimigos: ou a lista, ou `error`.

var enemies: Array[Enemy] = []
var error: String = ""


static func success(p_enemies: Array[Enemy]) -> EnemyLoadResult:
	var result := EnemyLoadResult.new()
	result.enemies = p_enemies
	return result


static func failure(message: String) -> EnemyLoadResult:
	var result := EnemyLoadResult.new()
	result.error = message
	return result


func is_ok() -> bool:
	return error == ""
