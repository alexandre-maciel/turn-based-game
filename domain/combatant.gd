class_name Combatant
extends RefCounted
## Um lado do combate: cópia dos status no início da luta. O combate mexe só
## nesta cópia; o Hero original não muda.

var combatant_name: String
var level: int
var max_hp: int
var hp: int
var attack: int
var defense: int
var crit_chance: float  ## Em porcentagem.
var speed: int


static func from_hero(hero: Hero) -> Combatant:
	var combatant := Combatant.new()
	combatant.combatant_name = hero.hero_name
	combatant.level = hero.level
	combatant.max_hp = StatFormulas.max_hp(hero)
	# Herói com HP 0 no JSON entra com 1, senão perderia sem jogar.
	combatant.hp = clampi(hero.current_hp, 1, combatant.max_hp)
	combatant.attack = StatFormulas.attack(hero)
	combatant.defense = StatFormulas.defense(hero)
	combatant.crit_chance = StatFormulas.crit_chance(hero)
	combatant.speed = StatFormulas.speed(hero)
	return combatant


static func from_enemy(enemy: Enemy) -> Combatant:
	var combatant := Combatant.new()
	combatant.combatant_name = enemy.enemy_name
	combatant.level = enemy.level
	combatant.max_hp = enemy.max_hp
	combatant.hp = enemy.max_hp
	combatant.attack = enemy.attack
	combatant.defense = enemy.defense
	combatant.crit_chance = enemy.crit_chance
	combatant.speed = enemy.speed
	return combatant


func is_alive() -> bool:
	return hp > 0
