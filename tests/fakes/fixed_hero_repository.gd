class_name FixedHeroRepository
extends HeroRepository
## Repositório de teste que devolve sempre o mesmo jogador.

var player: Player


func _init(p_player: Player) -> void:
	player = p_player


func load_player() -> LoadResult:
	return LoadResult.success(player)


## O Aldric da spec, com ajustes opcionais para testes.
static func aldric(level: int = 1, hero_name: String = "Aldric", gold: int = 1250) -> FixedHeroRepository:
	var hero := Hero.new("hero-001", hero_name, "mage", level, 35, 240, Attributes.new(5, 8, 14, 12))
	return FixedHeroRepository.new(Player.new(hero, gold, 20))
