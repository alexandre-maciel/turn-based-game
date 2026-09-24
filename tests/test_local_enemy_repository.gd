extends BaseTest
## Carregamento e validação do JSON de inimigos (spec do combate, seção 4).

const FIXTURES := "res://tests/fixtures/enemies/"


func _load(file_name: String) -> EnemyLoadResult:
	return LocalEnemyRepository.new(FIXTURES + file_name).load_enemies()


func _assert_error_contains(result: EnemyLoadResult, text: String) -> void:
	assert_false(result.is_ok(), "deveria falhar")
	assert_true(result.error.contains(text), "erro '%s' deveria conter '%s'" % [result.error, text])
	assert_eq(result.enemies.size(), 0)


func test_loads_training_enemies() -> void:
	var result := LocalEnemyRepository.new().load_enemies()
	assert_true(result.is_ok(), result.error)
	var ids: Array[String] = []
	for enemy in result.enemies:
		ids.append(enemy.id)
	assert_eq(ids, ["giant_rat", "wolf", "ogre"])
	var rat := result.enemies[0]
	assert_eq(rat.enemy_name, "Rato Gigante")
	assert_eq(rat.level, 1)
	assert_eq(rat.max_hp, 80)
	assert_eq(rat.attack, 20)
	assert_eq(rat.defense, 6)
	assert_eq(rat.crit_chance, 2)
	assert_eq(rat.speed, 95)
	assert_eq(rat.xp_reward, 20)
	assert_eq(rat.gold_reward, 15)


func test_missing_file() -> void:
	_assert_error_contains(_load("nao_existe.json"), "não encontrado")


func test_malformed_json() -> void:
	# Reaproveita o fixture malformado do herói.
	var result := LocalEnemyRepository.new("res://tests/fixtures/malformed.json").load_enemies()
	_assert_error_contains(result, "JSON inválido")


func test_enemies_must_be_a_list() -> void:
	_assert_error_contains(_load("not_a_list.json"), "não é uma lista")


func test_empty_list() -> void:
	_assert_error_contains(_load("empty_list.json"), "vazio")


func test_entry_must_be_object() -> void:
	_assert_error_contains(_load("entry_not_object.json"), "enemies[0]")


func test_missing_field() -> void:
	_assert_error_contains(_load("missing_attack.json"), "enemies[0].attack")


func test_max_hp_must_be_positive() -> void:
	_assert_error_contains(_load("zero_max_hp.json"), "enemies[0].max_hp")


func test_negative_reward() -> void:
	_assert_error_contains(_load("negative_reward.json"), "enemies[0].rewards.gold")


func test_duplicate_id() -> void:
	_assert_error_contains(_load("duplicate_id.json"), "giant_rat")


func test_one_invalid_entry_invalidates_file() -> void:
	_assert_error_contains(_load("second_entry_invalid.json"), "enemies[1].level")
