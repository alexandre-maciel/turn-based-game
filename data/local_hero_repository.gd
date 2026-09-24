class_name LocalHeroRepository
extends HeroRepository
## Carrega o jogador de um JSON local e valida cada campo. Só leitura.

const DEFAULT_PATH := "res://data/sample_hero.json"

var path: String


func _init(p_path: String = DEFAULT_PATH) -> void:
	path = p_path


func load_player() -> LoadResult:
	var fields := JsonFields.new()
	var root := fields.read_object(path)
	if fields.error != "":
		return LoadResult.failure(fields.error)
	return parse_player(root, path)


## Valida o objeto raiz já lido. `source` só aparece nas mensagens de erro.
static func parse_player(root: Dictionary, source: String) -> LoadResult:
	var fields := JsonFields.new()
	var player := _parse_player(root, fields)
	if player == null:
		return LoadResult.failure("%s: %s" % [source, fields.error])
	return LoadResult.success(player)


## Lê o jogador; em caso de problema, preenche fields.error e devolve null.
static func _parse_player(root: Dictionary, fields: JsonFields) -> Player:
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
	var tower := _parse_tower(root, fields)
	if fields.error != "":
		return null
	var max_hp := StatFormulas.max_hp(hero)
	hero.current_hp = clampi(hero.current_hp, 0, max_hp)
	if tower == null:
		return Player.new(hero, gold, gems)
	tower.hp = clampi(tower.hp, 1, max_hp)
	return Player.new(hero, gold, gems, tower)


## "tower" é opcional (o herói de exemplo e os saves da versão 1 não têm).
static func _parse_tower(root: Dictionary, fields: JsonFields) -> TowerProgress:
	if fields.error != "" or not root.has("tower"):
		return null
	var data := fields.dict(root, "tower", "")
	var tower := TowerProgress.new(
		fields.integer(data, "floor", "tower.", 1),
		fields.integer(data, "hp", "tower.", 0),
		fields.integer(data, "best_floor", "tower.", 0))
	return tower if fields.error == "" else null
