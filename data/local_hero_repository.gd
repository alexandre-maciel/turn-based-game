class_name LocalHeroRepository
extends HeroRepository
## Carrega o jogador de um JSON local e valida cada campo.

const DEFAULT_PATH := "res://data/sample_hero.json"

var path: String
var _error := ""


func _init(p_path: String = DEFAULT_PATH) -> void:
	path = p_path


func load_player() -> LoadResult:
	_error = ""
	if not FileAccess.file_exists(path):
		return LoadResult.failure("Arquivo não encontrado: %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return LoadResult.failure("JSON inválido em %s (linha %d): %s" % [
			path, json.get_error_line(), json.get_error_message()])
	if typeof(json.data) != TYPE_DICTIONARY:
		return LoadResult.failure("O JSON em %s deve ser um objeto" % path)
	var player := _parse_player(json.data)
	if player == null:
		return LoadResult.failure("%s: %s" % [path, _error])
	return LoadResult.success(player)


## Lê o jogador; em caso de problema, preenche _error e devolve null.
## Cada helper vira no-op depois do primeiro erro.
func _parse_player(root: Dictionary) -> Player:
	var hero_data := _dict(root, "hero", "")
	var attribute_data := _dict(hero_data, "attributes", "hero.")
	var currency_data := _dict(root, "currencies", "")
	var hero_class := _string(hero_data, "class", "hero.")
	if _error == "" and not StatFormulas.is_valid_class(hero_class):
		_error = "Classe desconhecida: '%s'" % hero_class
	var attributes := Attributes.new(
		_int(attribute_data, "strength", "hero.attributes.", 0),
		_int(attribute_data, "agility", "hero.attributes.", 0),
		_int(attribute_data, "intelligence", "hero.attributes.", 0),
		_int(attribute_data, "vitality", "hero.attributes.", 0))
	var hero := Hero.new(
		_string(hero_data, "id", "hero."),
		_string(hero_data, "name", "hero."),
		hero_class,
		_int(hero_data, "level", "hero.", 1),
		_int(hero_data, "xp", "hero.", 0),
		_int(hero_data, "current_hp", "hero.", null),
		attributes)
	var gold := _int(currency_data, "gold", "currencies.", 0)
	var gems := _int(currency_data, "gems", "currencies.", 0)
	if _error != "":
		return null
	hero.current_hp = clampi(hero.current_hp, 0, StatFormulas.max_hp(hero))
	return Player.new(hero, gold, gems)


func _dict(data: Dictionary, key: String, prefix: String) -> Dictionary:
	if _error != "":
		return {}
	if typeof(data.get(key)) != TYPE_DICTIONARY:
		_error = "Campo '%s%s' ausente ou não é um objeto" % [prefix, key]
		return {}
	return data[key]


func _string(data: Dictionary, key: String, prefix: String) -> String:
	if _error != "":
		return ""
	var value: Variant = data.get(key)
	if typeof(value) != TYPE_STRING or (value as String).strip_edges() == "":
		_error = "Campo '%s%s' ausente ou vazio" % [prefix, key]
		return ""
	return value


## O JSON do Godot entrega números como float: aceita 12 e 12.0, recusa 12.5 e "12".
## min_value = null significa sem mínimo.
func _int(data: Dictionary, key: String, prefix: String, min_value: Variant) -> int:
	if _error != "":
		return 0
	var field := prefix + key
	var value: Variant = data.get(key)
	if typeof(value) == TYPE_FLOAT and value == floorf(value):
		value = int(value)
	if typeof(value) != TYPE_INT:
		_error = "Campo '%s' ausente ou não é um número inteiro" % field
		return 0
	if min_value != null and value < min_value:
		_error = "Campo '%s' deve ser no mínimo %d (recebido %d)" % [field, min_value, value]
		return 0
	return value
