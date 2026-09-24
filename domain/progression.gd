class_name Progression
extends RefCounted
## Ganho de XP e subida de nível. Só o nível sobe; os atributos não mudam.


## Nível e XP depois de ganhar `gain`, sem alterar nada: Vector2i(nível, xp).
static func after_xp(level: int, xp: int, gain: int) -> Vector2i:
	xp += gain
	while xp >= StatFormulas.xp_to_next_level(level):
		xp -= StatFormulas.xp_to_next_level(level)
		level += 1
	return Vector2i(level, xp)


## Aplica o XP no herói e devolve quantos níveis ele subiu.
static func apply_xp(hero: Hero, gain: int) -> int:
	var result := after_xp(hero.level, hero.xp, gain)
	var levels_gained := result.x - hero.level
	hero.level = result.x
	hero.xp = result.y
	return levels_gained
