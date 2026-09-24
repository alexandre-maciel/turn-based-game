extends BaseTest
## Formato do save (spec do salvamento, seção 3).

const DIR := "user://test_saves"


func after_each() -> void:
	FileHelper.remove_dir(DIR)


func _player() -> Player:
	var hero := Hero.new("hero-001", "Aldric", "mage", 2, 5, 260, Attributes.new(5, 8, 14, 12))
	return Player.new(hero, 1265, 20)


func test_dict_has_expected_format() -> void:
	assert_eq(HeroSerializer.to_dict(_player()), {
		"version": 1,
		"hero": {
			"id": "hero-001", "name": "Aldric", "class": "mage",
			"level": 2, "xp": 5, "current_hp": 260,
			"attributes": {"strength": 5, "agility": 8, "intelligence": 14, "vitality": 12},
		},
		"currencies": {"gold": 1265, "gems": 20},
	})


func test_round_trip_through_validator() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var path := DIR + "/round_trip.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(HeroSerializer.to_dict(_player())))
	file.close()
	var result := LocalHeroRepository.new(path).load_player()
	assert_true(result.is_ok(), result.error)
	if result.is_ok():
		assert_eq(HeroSerializer.to_dict(result.player), HeroSerializer.to_dict(_player()))
