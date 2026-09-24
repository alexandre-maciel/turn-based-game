class_name Enemy
extends RefCounted
## Definição de um inimigo (vem do JSON). Só dados, com status prontos.

var id: String
var enemy_name: String
var level: int
var max_hp: int
var attack: int
var defense: int
var crit_chance: int  ## Em porcentagem.
var speed: int
var xp_reward: int
var gold_reward: int


func _init(p_id: String, p_enemy_name: String, p_level: int, p_max_hp: int, p_attack: int,
		p_defense: int, p_crit_chance: int, p_speed: int, p_xp_reward: int, p_gold_reward: int) -> void:
	id = p_id
	enemy_name = p_enemy_name
	level = p_level
	max_hp = p_max_hp
	attack = p_attack
	defense = p_defense
	crit_chance = p_crit_chance
	speed = p_speed
	xp_reward = p_xp_reward
	gold_reward = p_gold_reward
