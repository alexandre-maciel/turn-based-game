class_name SaveGameRepository
extends HeroRepository
## O save do jogador em user://save.json. Sem save, começa um jogo novo a
## partir do template. Save danificado é guardado com outro nome e o jogo
## recomeça do template, com `warning` preenchido.

const DEFAULT_SAVE_PATH := "user://save.json"

var save_path: String
var template_path: String


func _init(p_save_path: String = DEFAULT_SAVE_PATH,
		p_template_path: String = LocalHeroRepository.DEFAULT_PATH) -> void:
	save_path = p_save_path
	template_path = p_template_path


func load_player() -> LoadResult:
	if not FileAccess.file_exists(save_path):
		return _new_game()
	var result := _read_save()
	if result.is_ok():
		return result
	var backup := _backup_path()
	var rename_error := DirAccess.rename_absolute(save_path, backup)
	var fresh := _new_game()
	if rename_error != OK:
		# Sem conseguir guardar a cópia, não arrisca gravar por cima do save.
		return LoadResult.failure("%s (e não foi possível guardar a cópia: %s)" % [
			result.error, error_string(rename_error)])
	fresh.warning = "Save danificado (%s); cópia em %s" % [result.error, backup]
	return fresh


## Grava num .tmp e depois troca pelo save, para uma gravação interrompida
## não estragar o save anterior.
func save_player(player: Player) -> String:
	DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	var temp_path := save_path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return "Não foi possível gravar %s: %s" % [temp_path, error_string(FileAccess.get_open_error())]
	file.store_string(JSON.stringify(HeroSerializer.to_dict(player), "  "))
	file.close()
	var rename_error := DirAccess.rename_absolute(temp_path, save_path)
	if rename_error != OK:
		return "Não foi possível substituir %s: %s" % [save_path, error_string(rename_error)]
	return ""


func _read_save() -> LoadResult:
	var fields := JsonFields.new()
	var root := fields.read_object(save_path)
	# Saves sem "version" são da versão 1.
	if fields.error == "" and root.has("version"):
		fields.integer(root, "version", "", 1)
		if fields.error == "" and int(root["version"]) > HeroSerializer.VERSION:
			fields.error = "Save da versão %d; este jogo lê até a versão %d" % [
				int(root["version"]), HeroSerializer.VERSION]
	if fields.error != "":
		return LoadResult.failure(fields.error)
	return LocalHeroRepository.parse_player(root, save_path)


func _new_game() -> LoadResult:
	return LocalHeroRepository.new(template_path).load_player()


## save.json -> save.corrompido-20260924-213000.json, na mesma pasta.
func _backup_path() -> String:
	var now := Time.get_datetime_dict_from_system()
	var stamp := "%04d%02d%02d-%02d%02d%02d" % [now.year, now.month, now.day, now.hour, now.minute, now.second]
	return "%s/%s.corrompido-%s.json" % [save_path.get_base_dir(), save_path.get_file().get_basename(), stamp]
