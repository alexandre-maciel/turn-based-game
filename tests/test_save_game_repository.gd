extends BaseTest
## Save do jogador (spec do salvamento, seção 2). Tudo em user://test_saves.

const DIR := "user://test_saves"
const SAVE := DIR + "/save.json"


func after_each() -> void:
	FileHelper.remove_dir(DIR)


func _repository() -> SaveGameRepository:
	return SaveGameRepository.new(SAVE)


func _leveled_player() -> Player:
	var hero := Hero.new("hero-001", "Aldric", "mage", 2, 5, 260, Attributes.new(5, 8, 14, 12))
	return Player.new(hero, 1265, 20)


func _files() -> PackedStringArray:
	return DirAccess.get_files_at(DIR)


func test_without_save_starts_from_template() -> void:
	var result := _repository().load_player()
	assert_true(result.is_ok(), result.error)
	assert_eq(result.player.hero.hero_name, "Aldric")
	assert_eq(result.player.hero.level, 1)
	assert_eq(result.warning, "")


func test_save_and_load_back() -> void:
	assert_eq(_repository().save_player(_leveled_player()), "")
	var result := _repository().load_player()
	assert_true(result.is_ok(), result.error)
	assert_eq(result.player.hero.level, 2)
	assert_eq(result.player.hero.xp, 5)
	assert_eq(result.player.gold, 1265)
	assert_eq(result.warning, "")


func test_save_overwrites_previous_save() -> void:
	_repository().save_player(FixedHeroRepository.aldric().player)
	_repository().save_player(_leveled_player())
	assert_eq(_repository().load_player().player.gold, 1265)


func test_no_temp_file_left_behind() -> void:
	_repository().save_player(_leveled_player())
	assert_eq(_files(), PackedStringArray(["save.json"]))


func test_corrupted_save_is_kept_and_game_restarts() -> void:
	FileHelper.write(SAVE, "{ isto não é json")
	var result := _repository().load_player()
	assert_true(result.is_ok(), result.error)
	assert_eq(result.player.hero.level, 1)
	assert_true(result.warning.contains("danificado"), result.warning)
	var files := _files()
	assert_eq(files.size(), 1)
	assert_true(files[0].begins_with("save.corrompido-"), files[0])
	assert_eq(FileAccess.get_file_as_string(DIR + "/" + files[0]), "{ isto não é json")


func test_invalid_field_counts_as_corrupted() -> void:
	var data := HeroSerializer.to_dict(_leveled_player())
	data["hero"]["level"] = 0
	FileHelper.write(SAVE, JSON.stringify(data))
	var result := _repository().load_player()
	assert_true(result.is_ok(), result.error)
	assert_true(result.warning.contains("hero.level"), result.warning)


func test_future_version_counts_as_corrupted() -> void:
	var data := HeroSerializer.to_dict(_leveled_player())
	data["version"] = 99
	FileHelper.write(SAVE, JSON.stringify(data))
	var result := _repository().load_player()
	assert_true(result.warning.contains("versão 99"), result.warning)
	assert_eq(result.player.hero.level, 1)


func test_save_without_version_is_accepted() -> void:
	var data := HeroSerializer.to_dict(_leveled_player())
	data.erase("version")
	FileHelper.write(SAVE, JSON.stringify(data))
	var result := _repository().load_player()
	assert_eq(result.warning, "")
	assert_eq(result.player.hero.level, 2)


func test_unwritable_path_returns_error() -> void:
	# Um arquivo no lugar onde deveria haver uma pasta.
	FileHelper.write(DIR + "/blocker", "x")
	var error := SaveGameRepository.new(DIR + "/blocker/save.json").save_player(_leveled_player())
	assert_true(error.begins_with("Não foi possível gravar"), error)
