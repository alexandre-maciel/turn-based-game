extends BaseTest
## Andares da Torre (spec da Torre, seção 2).


func _stats(enemy: Enemy) -> Array:
	return [enemy.max_hp, enemy.attack, enemy.defense, enemy.speed, enemy.crit_chance,
		enemy.xp_reward, enemy.gold_reward, enemy.level]


func test_floor_1() -> void:
	var enemy := Tower.enemy_for_floor(1)
	assert_eq(enemy.enemy_name, "Esqueleto")
	assert_eq(_stats(enemy), [70, 18, 2, 91, 3, 16, 13, 1])


func test_floor_5_is_boss() -> void:
	var enemy := Tower.enemy_for_floor(5)
	assert_eq(enemy.id, "tower_guardian")
	assert_eq(enemy.enemy_name, "Guardião")
	assert_eq(_stats(enemy), [240, 40, 10, 103, 3, 80, 66, 3])


func test_floor_10_is_boss() -> void:
	assert_eq(_stats(Tower.enemy_for_floor(10)), [400, 64, 20, 118, 3, 140, 116, 6])


func test_names_cycle_on_common_floors() -> void:
	var names: Array[String] = []
	for n in range(1, 10):
		names.append(Tower.enemy_for_floor(n).enemy_name)
	assert_eq(names, ["Esqueleto", "Goblin", "Aranha Gigante", "Cultista", "Guardião",
		"Goblin", "Aranha Gigante", "Cultista", "Esqueleto"])


func test_boss_only_on_multiples_of_five() -> void:
	for n in range(1, 21):
		assert_eq(Tower.is_boss(n), n % 5 == 0, "andar %d" % n)


func test_regen_is_twenty_percent() -> void:
	assert_eq(Tower.regen(240), 48)
	assert_eq(Tower.regen(259), 51)


func test_new_player_starts_fresh_climb() -> void:
	var hero := Hero.new("h", "Aldric", "mage", 1, 0, 240, Attributes.new(5, 8, 14, 12))
	var tower := Player.new(hero, 0, 0).tower
	assert_eq([tower.floor_number, tower.hp, tower.best_floor], [1, 240, 0])
