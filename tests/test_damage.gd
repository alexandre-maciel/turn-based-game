extends BaseTest
## Fórmula de dano (spec do combate, seção 3).


func _damage(attack: int, defense: int, multiplier: float = 1.0, variance: float = 1.0,
		critical: bool = false, defending: bool = false) -> int:
	return StatFormulas.damage(attack, defense, multiplier, variance, critical, defending)


func test_reference_table() -> void:
	# Aldric (ataque 29, defesa 17) contra os inimigos do Treino.
	assert_eq(_damage(29, 6), 26, "Aldric no Rato")
	assert_eq(_damage(29, 6, 1.6), 41, "Bola de Fogo no Rato")
	assert_eq(_damage(29, 10), 24, "Aldric no Lobo")
	assert_eq(_damage(29, 10, 1.6), 38, "Bola de Fogo no Lobo")
	assert_eq(_damage(29, 20), 19, "Aldric no Ogro")
	assert_eq(_damage(29, 20, 1.6), 30, "Bola de Fogo no Ogro")
	assert_eq(_damage(20, 17), 12, "Rato no Aldric")
	assert_eq(_damage(30, 17), 22, "Lobo no Aldric")
	assert_eq(_damage(45, 17), 37, "Ogro no Aldric")


func test_minimum_damage_is_one() -> void:
	assert_eq(_damage(1, 100), 1)
	assert_eq(_damage(0, 0), 1)
	assert_eq(_damage(1, 0, 1.0, 0.9, false, true), 1)


func test_critical_multiplies_by_one_and_a_half() -> void:
	assert_eq(_damage(29, 6, 1.0, 1.0, true), 39)


func test_defending_halves_damage() -> void:
	assert_eq(_damage(30, 17, 1.0, 1.0, false, true), 11)


func test_variance_extremes() -> void:
	assert_eq(_damage(30, 0, 1.0, 0.9), 27)
	assert_eq(_damage(30, 0, 1.0, 1.1), 33)


func test_rounds_down() -> void:
	# 26 × 1,5 × 0,5 = 19,5
	assert_eq(_damage(29, 6, 1.0, 1.0, true, true), 19)


func test_mage_skill_is_fireball() -> void:
	var skill := StatFormulas.skill_for("mage")
	assert_eq(skill["id"], "fireball")
	assert_eq(skill["multiplier"], 1.6)
	assert_eq(skill["cooldown"], 3)
