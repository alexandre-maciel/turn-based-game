class_name HeroSerializer
extends RefCounted
## Converte o Player no formato do JSON (o mesmo do sample_hero.json + version).

## Versão do formato. Ao mudar o formato, suba este número e trate a migração
## no SaveGameRepository.
const VERSION := 1


static func to_dict(player: Player) -> Dictionary:
	var hero := player.hero
	return {
		"version": VERSION,
		"hero": {
			"id": hero.id,
			"name": hero.hero_name,
			"class": hero.hero_class,
			"level": hero.level,
			"xp": hero.xp,
			"current_hp": hero.current_hp,
			"attributes": {
				"strength": hero.attributes.strength,
				"agility": hero.attributes.agility,
				"intelligence": hero.attributes.intelligence,
				"vitality": hero.attributes.vitality,
			},
		},
		"currencies": {"gold": player.gold, "gems": player.gems},
	}
