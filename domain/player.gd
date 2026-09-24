class_name Player
extends RefCounted
## A conta do jogador: o herói e as moedas (que no online pertencem à conta).

var hero: Hero
var gold: int
var gems: int


func _init(p_hero: Hero, p_gold: int, p_gems: int) -> void:
	hero = p_hero
	gold = p_gold
	gems = p_gems
