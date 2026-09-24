class_name Hero
extends RefCounted
## Um herói do jogador. Só dados; as regras ficam em StatFormulas.

var id: String
var hero_name: String
var hero_class: String
var level: int
var xp: int
var current_hp: int
var attributes: Attributes


func _init(p_id: String, p_hero_name: String, p_hero_class: String, p_level: int, p_xp: int, p_current_hp: int, p_attributes: Attributes) -> void:
	id = p_id
	hero_name = p_hero_name
	hero_class = p_hero_class
	level = p_level
	xp = p_xp
	current_hp = p_current_hp
	attributes = p_attributes
