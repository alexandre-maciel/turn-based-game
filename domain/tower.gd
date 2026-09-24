class_name Tower
extends RefCounted
## Regras da Torre: o inimigo de cada andar sai de uma fórmula (andares
## infinitos). Todo o balanceamento da Torre mora aqui.

const BOSS_EVERY := 5
const BOSS_HP := 1.6
const BOSS_ATTACK := 1.2
const BOSS_REWARD := 2
## Fração do HP máximo recuperada ao vencer um andar.
const REGEN_FRACTION := 0.2
const CRIT_CHANCE := 3

## id -> nome, na ordem do ciclo dos andares comuns.
const ROSTER := [
	["tower_skeleton", "Esqueleto"],
	["tower_goblin", "Goblin"],
	["tower_spider", "Aranha Gigante"],
	["tower_cultist", "Cultista"],
]
const BOSS := ["tower_guardian", "Guardião"]


static func is_boss(floor_number: int) -> bool:
	return floor_number % BOSS_EVERY == 0


static func enemy_for_floor(n: int) -> Enemy:
	var boss := is_boss(n)
	var identity: Array = BOSS if boss else ROSTER[(n - 1) % ROSTER.size()]
	var max_hp := 50 + 20 * n
	var attack := 14 + 4 * n
	var xp := 10 + 6 * n
	var gold := 8 + 5 * n
	if boss:
		max_hp = floori(max_hp * BOSS_HP)
		attack = floori(attack * BOSS_ATTACK)
		xp *= BOSS_REWARD
		gold *= BOSS_REWARD
	return Enemy.new(identity[0], identity[1], 1 + floori(n / 2.0), max_hp, attack,
		2 * n, CRIT_CHANCE, 88 + 3 * n, xp, gold)


## HP recuperado ao vencer um andar.
static func regen(max_hp: int) -> int:
	return floori(max_hp * REGEN_FRACTION)
