class_name LocalEnemyRepository
extends EnemyRepository
## Carrega os inimigos de um JSON local. Qualquer entrada inválida invalida o arquivo.

const DEFAULT_PATH := "res://data/enemies.json"

var path: String


func _init(p_path: String = DEFAULT_PATH) -> void:
	path = p_path


func load_enemies() -> EnemyLoadResult:
	var fields := JsonFields.new()
	var root := fields.read_object(path)
	if fields.error != "":
		return EnemyLoadResult.failure(fields.error)
	var entries := fields.array(root, "enemies", "")
	if fields.error == "" and entries.is_empty():
		fields.error = "Campo 'enemies' não pode estar vazio"
	var enemies: Array[Enemy] = []
	var ids := {}
	for i in entries.size():
		var enemy := _parse_enemy(entries[i], "enemies[%d]." % i, fields)
		if enemy == null:
			break
		if ids.has(enemy.id):
			fields.error = "Inimigo com id repetido: '%s'" % enemy.id
			break
		ids[enemy.id] = true
		enemies.append(enemy)
	if fields.error != "":
		return EnemyLoadResult.failure("%s: %s" % [path, fields.error])
	return EnemyLoadResult.success(enemies)


func _parse_enemy(entry: Variant, prefix: String, fields: JsonFields) -> Enemy:
	if typeof(entry) != TYPE_DICTIONARY:
		fields.error = "Entrada '%s' não é um objeto" % prefix.trim_suffix(".")
		return null
	var data: Dictionary = entry
	var rewards := fields.dict(data, "rewards", prefix)
	var enemy := Enemy.new(
		fields.string(data, "id", prefix),
		fields.string(data, "name", prefix),
		fields.integer(data, "level", prefix, 1),
		fields.integer(data, "max_hp", prefix, 1),
		fields.integer(data, "attack", prefix, 0),
		fields.integer(data, "defense", prefix, 0),
		fields.integer(data, "crit_chance", prefix, 0),
		fields.integer(data, "speed", prefix, 0),
		fields.integer(rewards, "xp", prefix + "rewards.", 0),
		fields.integer(rewards, "gold", prefix + "rewards.", 0))
	return enemy if fields.error == "" else null
