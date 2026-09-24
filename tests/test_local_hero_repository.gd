extends BaseTest
## Carregamento e validação do JSON do jogador (spec, seção 4).

const FIXTURES := "res://tests/fixtures/"


func _load(file_name: String) -> LoadResult:
	return LocalHeroRepository.new(FIXTURES + file_name).load_player()


func _assert_error_contains(result: LoadResult, text: String) -> void:
	assert_false(result.is_ok(), "deveria falhar")
	assert_true(result.error.contains(text), "erro '%s' deveria conter '%s'" % [result.error, text])


func test_loads_sample_hero() -> void:
	var result := LocalHeroRepository.new().load_player()
	assert_true(result.is_ok(), result.error)
	if not result.is_ok():
		return
	var hero := result.player.hero
	assert_eq(hero.id, "hero-001")
	assert_eq(hero.hero_name, "Aldric")
	assert_eq(hero.hero_class, "mage")
	assert_eq(hero.level, 1)
	assert_eq(hero.xp, 35)
	assert_eq(hero.current_hp, 240)
	assert_eq(hero.attributes.strength, 5)
	assert_eq(hero.attributes.agility, 8)
	assert_eq(hero.attributes.intelligence, 14)
	assert_eq(hero.attributes.vitality, 12)
	assert_eq(result.player.gold, 1250)
	assert_eq(result.player.gems, 20)


func test_missing_file() -> void:
	_assert_error_contains(_load("nao_existe.json"), "não encontrado")


func test_malformed_json() -> void:
	_assert_error_contains(_load("malformed.json"), "JSON inválido")


func test_root_must_be_object() -> void:
	_assert_error_contains(_load("array_root.json"), "deve ser um objeto")


func test_missing_field() -> void:
	_assert_error_contains(_load("missing_level.json"), "hero.level")


func test_invalid_class() -> void:
	_assert_error_contains(_load("invalid_class.json"), "warrior")


func test_level_zero() -> void:
	_assert_error_contains(_load("level_zero.json"), "hero.level")


func test_fractional_attribute() -> void:
	_assert_error_contains(_load("fractional_attribute.json"), "hero.attributes.intelligence")


func test_number_written_as_text() -> void:
	_assert_error_contains(_load("text_number.json"), "hero.attributes.intelligence")


func test_negative_gold() -> void:
	_assert_error_contains(_load("negative_gold.json"), "currencies.gold")


func test_current_hp_above_max_is_clamped() -> void:
	var result := _load("hp_over_max.json")
	assert_true(result.is_ok(), result.error)
	if result.is_ok():
		assert_eq(result.player.hero.current_hp, 240)


func test_negative_current_hp_is_clamped_to_zero() -> void:
	var result := _load("hp_negative.json")
	assert_true(result.is_ok(), result.error)
	if result.is_ok():
		assert_eq(result.player.hero.current_hp, 0)


func test_extra_fields_are_ignored() -> void:
	var result := _load("extra_fields.json")
	assert_true(result.is_ok(), result.error)


func test_utf8_bom_from_notepad_is_accepted() -> void:
	var result := _load("bom.json")
	assert_true(result.is_ok(), result.error)
	if result.is_ok():
		assert_eq(result.player.hero.hero_name, "Aldric")
