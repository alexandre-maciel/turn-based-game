class_name LocalHeroRepository
extends HeroRepository
## Carrega o jogador de um JSON local e valida cada campo.

const DEFAULT_PATH := "res://data/sample_hero.json"

var path: String


func _init(p_path: String = DEFAULT_PATH) -> void:
	path = p_path


func load_player() -> LoadResult:
	var fields := JsonFields.new()
	var root := fields.read_object(path)
	if fields.error != "":
		return LoadResult.failure(fields.error)
	var player := _parse_player(root, fields)
	if player == null:
		return LoadResult.failure("%s: %s" % [path, fields.error])
	return LoadResult.success(player)


## Lê o jogador; em caso de problema, preenche fields.error e devolve null.
func _parse_player(root: Dictionary, fields: JsonFields) -> Player:
	var hero_data := fields.dict(root, "hero", "")
	var attribute_data := fields.dict(hero_data, "attributes", "hero.")
	var currency_data := fields.dict(root, "currencies", "")
	var hero_class := fields.string(hero_data, "class", "hero.")
	if fields.error == "" and not StatFormulas.is_valid_class(hero_class):
		fields.error = "Classe desconhecida: '%s'" % hero_class
	var attributes := Attributes.new(
		fields.integer(attribute_data, "strength", "hero.attributes.", 0),
		fields.integer(attribute_data, "agility", "hero.attributes.", 0),
		fields.integer(attribute_data, "intelligence", "hero.attributes.", 0),
		fields.integer(attribute_data, "vitality", "hero.attributes.", 0))
	var hero := Hero.new(
		fields.string(hero_data, "id", "hero."),
		fields.string(hero_data, "name", "hero."),
		hero_class,
		fields.integer(hero_data, "level", "hero.", 1),
		fields.integer(hero_data, "xp", "hero.", 0),
		fields.integer(hero_data, "current_hp", "hero.", null),
		attributes)
	var gold := fields.integer(currency_data, "gold", "currencies.", 0)
	var gems := fields.integer(currency_data, "gems", "currencies.", 0)
	if fields.error != "":
		return null
	hero.current_hp = clampi(hero.current_hp, 0, StatFormulas.max_hp(hero))
	return Player.new(hero, gold, gems)
