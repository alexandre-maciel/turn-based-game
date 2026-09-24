class_name Player
extends RefCounted
## A conta do jogador: o herói, as moedas (que no online pertencem à conta)
## e a escalada da Torre.

var hero: Hero
var gold: int
var gems: int
var tower: TowerProgress


## Sem `p_tower`, começa uma escalada nova.
func _init(p_hero: Hero, p_gold: int, p_gems: int, p_tower: TowerProgress = null) -> void:
	hero = p_hero
	gold = p_gold
	gems = p_gems
	tower = p_tower if p_tower != null else TowerProgress.fresh(p_hero)
