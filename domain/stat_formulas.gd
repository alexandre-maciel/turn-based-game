class_name StatFormulas
extends RefCounted
## Regras de cálculo dos status. Funções puras: mesmo herói, mesmo resultado.
## Todo o balanceamento mora aqui.

## Classes jogáveis. Para criar outra classe, acrescente uma entrada.
const CLASSES := {
	"mage": {"main_attribute": "intelligence"},
}


## Habilidade de combate de cada classe. `cooldown`: rodadas até poder usar de novo.
const SKILLS := {
	"mage": {"id": "fireball", "multiplier": 1.6, "cooldown": 3},
}

const CRIT_MULTIPLIER := 1.5
const DEFEND_MULTIPLIER := 0.5


static func is_valid_class(hero_class: String) -> bool:
	return CLASSES.has(hero_class)


static func main_attribute(hero_class: String) -> String:
	return CLASSES[hero_class]["main_attribute"]


static func max_hp(hero: Hero) -> int:
	return 100 + hero.attributes.vitality * 10 + hero.level * 20


static func attack(hero: Hero) -> int:
	return hero.attributes.get_value(main_attribute(hero.hero_class)) * 2 + hero.level


static func defense(hero: Hero) -> int:
	return hero.attributes.vitality + floori(hero.attributes.agility / 2.0) + hero.level


## Chance de crítico em porcentagem (4.0 = 4%).
static func crit_chance(hero: Hero) -> float:
	return hero.attributes.agility * 0.5


static func speed(hero: Hero) -> int:
	return 100 + hero.attributes.agility


static func xp_to_next_level(level: int) -> int:
	return roundi(100.0 * pow(level, 1.5))


static func skill_for(hero_class: String) -> Dictionary:
	return SKILLS[hero_class]


## Dano de um golpe. Mínimo 1; arredonda para baixo.
## base = ataque − defesa÷2; depois multiplicador da ação, variação, crítico e defesa.
static func damage(attack: int, defense: int, multiplier: float, variance: float,
		critical: bool, defending: bool) -> int:
	var value := float(maxi(1, attack - floori(defense / 2.0))) * multiplier * variance
	if critical:
		value *= CRIT_MULTIPLIER
	if defending:
		value *= DEFEND_MULTIPLIER
	# A folga evita que 27,0 vire 26,999... e perca 1 ponto no floor.
	return maxi(1, floori(value + 0.0001))
