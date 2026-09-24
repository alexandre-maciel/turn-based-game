extends BaseTest
## Fórmulas de status (spec, seção 4). Aldric: Mago nv 1, For 5, Agi 8, Int 14, Vit 12.


func _mage(level: int = 1, attributes: Attributes = Attributes.new(5, 8, 14, 12)) -> Hero:
	return Hero.new("hero-001", "Aldric", "mage", level, 35, 240, attributes)


func test_aldric_max_hp() -> void:
	assert_eq(StatFormulas.max_hp(_mage()), 240)


func test_aldric_attack() -> void:
	assert_eq(StatFormulas.attack(_mage()), 29)


func test_aldric_defense() -> void:
	assert_eq(StatFormulas.defense(_mage()), 17)


func test_aldric_crit_chance() -> void:
	assert_eq(StatFormulas.crit_chance(_mage()), 4.0)


func test_aldric_speed() -> void:
	assert_eq(StatFormulas.speed(_mage()), 108)


func test_mage_attack_uses_intelligence_not_strength() -> void:
	var brute := _mage(1, Attributes.new(50, 0, 1, 0))
	assert_eq(StatFormulas.attack(brute), 3)


func test_defense_rounds_half_agility_down() -> void:
	var hero := _mage(1, Attributes.new(0, 9, 0, 0))
	assert_eq(StatFormulas.defense(hero), 5)


func test_zero_attributes() -> void:
	var hero := _mage(1, Attributes.new(0, 0, 0, 0))
	assert_eq(StatFormulas.max_hp(hero), 120)
	assert_eq(StatFormulas.attack(hero), 1)
	assert_eq(StatFormulas.defense(hero), 1)
	assert_eq(StatFormulas.crit_chance(hero), 0.0)
	assert_eq(StatFormulas.speed(hero), 100)


func test_level_scales_hp_attack_and_defense() -> void:
	var hero := _mage(5)
	assert_eq(StatFormulas.max_hp(hero), 320)
	assert_eq(StatFormulas.attack(hero), 33)
	assert_eq(StatFormulas.defense(hero), 21)


func test_xp_to_next_level() -> void:
	assert_eq(StatFormulas.xp_to_next_level(1), 100)
	assert_eq(StatFormulas.xp_to_next_level(2), 283)
	assert_eq(StatFormulas.xp_to_next_level(5), 1118)
	assert_eq(StatFormulas.xp_to_next_level(10), 3162)


func test_only_mage_class_exists() -> void:
	assert_true(StatFormulas.is_valid_class("mage"))
	assert_false(StatFormulas.is_valid_class("warrior"))
	assert_eq(StatFormulas.main_attribute("mage"), "intelligence")


func test_attributes_get_value_by_name() -> void:
	var attributes := Attributes.new(5, 8, 14, 12)
	assert_eq(attributes.get_value("strength"), 5)
	assert_eq(attributes.get_value("agility"), 8)
	assert_eq(attributes.get_value("intelligence"), 14)
	assert_eq(attributes.get_value("vitality"), 12)
