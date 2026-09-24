extends BaseTest
## Ganho de XP e subida de nível (spec do combate, seção 3).


func _hero(level: int, xp: int) -> Hero:
	return Hero.new("h", "Aldric", "mage", level, xp, 240, Attributes.new(5, 8, 14, 12))


func test_gain_without_level_up() -> void:
	var hero := _hero(1, 35)
	assert_eq(Progression.apply_xp(hero, 45), 0)
	assert_eq(hero.level, 1)
	assert_eq(hero.xp, 80)


func test_level_up_exactly_at_threshold() -> void:
	var hero := _hero(1, 80)
	assert_eq(Progression.apply_xp(hero, 20), 1)
	assert_eq(hero.level, 2)
	assert_eq(hero.xp, 0)


func test_leftover_xp_is_kept() -> void:
	var hero := _hero(1, 90)
	Progression.apply_xp(hero, 20)
	assert_eq(hero.level, 2)
	assert_eq(hero.xp, 10)


func test_two_levels_at_once() -> void:
	# Nível 1 precisa de 100, nível 2 precisa de 283.
	var hero := _hero(1, 0)
	assert_eq(Progression.apply_xp(hero, 400), 2)
	assert_eq(hero.level, 3)
	assert_eq(hero.xp, 17)


func test_after_xp_does_not_change_hero() -> void:
	var hero := _hero(1, 80)
	assert_eq(Progression.after_xp(hero.level, hero.xp, 20), Vector2i(2, 0))
	assert_eq(hero.level, 1)
	assert_eq(hero.xp, 80)
