class_name TowerProgress
extends RefCounted
## A escalada da Torre: o andar a enfrentar, o HP que sobrou (separado do HP
## do herói, que o Treino restaura) e o maior andar já vencido.

var floor_number: int
var hp: int
var best_floor: int


func _init(p_floor_number: int = 1, p_hp: int = 0, p_best_floor: int = 0) -> void:
	floor_number = p_floor_number
	hp = p_hp
	best_floor = p_best_floor


## Escalada nova para o herói: andar 1, HP cheio, recorde mantido.
static func fresh(hero: Hero, best: int = 0) -> TowerProgress:
	return TowerProgress.new(1, StatFormulas.max_hp(hero), best)
