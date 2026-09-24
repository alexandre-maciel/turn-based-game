extends BaseTest
## Regras da rodada (spec do combate, seção 3). Sorteio fixo: sem crítico e sem variação.

const ATTACK := Battle.Action.ATTACK
const SKILL := Battle.Action.SKILL
const DEFEND := Battle.Action.DEFEND
const FLEE := Battle.Action.FLEE


func _aldric() -> Hero:
	return Hero.new("hero-001", "Aldric", "mage", 1, 35, 240, Attributes.new(5, 8, 14, 12))


func _enemy(speed: int = 95, max_hp: int = 80, attack: int = 20, defense: int = 6) -> Enemy:
	return Enemy.new("giant_rat", "Rato Gigante", 1, max_hp, attack, defense, 2, speed, 20, 15)


func _battle(enemy: Enemy = _enemy(), dice: Dice = FixedDice.new()) -> Battle:
	return Battle.new(_aldric(), enemy, dice)


func _hits(events: Array[BattleEvent]) -> Array[String]:
	var result: Array[String] = []
	for event in events:
		if event.kind == BattleEvent.Kind.HIT:
			result.append("%s>%d" % [event.actor.combatant_name, event.damage])
	return result


func test_starts_from_hero_and_enemy_stats() -> void:
	var battle := _battle()
	assert_eq(battle.hero.max_hp, 240)
	assert_eq(battle.hero.hp, 240)
	assert_eq(battle.hero.attack, 29)
	assert_eq(battle.hero.speed, 108)
	assert_eq(battle.enemy.hp, 80)
	assert_eq(battle.round, 1)
	assert_eq(battle.outcome, Battle.Outcome.ONGOING)


func test_faster_hero_acts_first() -> void:
	var events := _battle().play_round(ATTACK)
	assert_eq(_hits(events), ["Aldric>26", "Rato Gigante>12"])


func test_faster_enemy_acts_first() -> void:
	var events := _battle(_enemy(112)).play_round(ATTACK)
	assert_eq(_hits(events), ["Rato Gigante>12", "Aldric>26"])


func test_speed_tie_favors_hero() -> void:
	var events := _battle(_enemy(108)).play_round(ATTACK)
	assert_eq(_hits(events)[0], "Aldric>26")


func test_events_carry_hp_after_hit() -> void:
	var events := _battle().play_round(ATTACK)
	assert_eq(events[0].target_hp_after, 54)
	assert_eq(events[1].target_hp_after, 228)


func test_defeated_combatant_does_not_act() -> void:
	var battle := _battle(_enemy(95, 20))
	var events := battle.play_round(ATTACK)
	assert_eq(_hits(events), ["Aldric>26"])
	assert_eq(events[-1].kind, BattleEvent.Kind.DEFEATED)
	assert_eq(battle.outcome, Battle.Outcome.VICTORY)
	assert_eq(battle.enemy.hp, 0)


func test_defend_works_even_when_hero_is_slower() -> void:
	var battle := _battle(_enemy(200))
	var events := battle.play_round(DEFEND)
	assert_eq(events[0].kind, BattleEvent.Kind.DEFEND)
	assert_eq(_hits(events), ["Rato Gigante>6"])
	# Só vale na rodada em que defendeu.
	assert_eq(_hits(battle.play_round(ATTACK)), ["Rato Gigante>12", "Aldric>26"])


func test_flee_ends_before_enemy_acts() -> void:
	var battle := _battle(_enemy(200))
	var events := battle.play_round(FLEE)
	assert_eq(events.size(), 1)
	assert_eq(events[0].kind, BattleEvent.Kind.FLEE)
	assert_eq(battle.outcome, Battle.Outcome.FLED)
	assert_eq(battle.hero.hp, 240)


func test_fireball_damage_and_cooldown() -> void:
	var battle := _battle(_enemy(95, 1000))
	assert_true(battle.can_use_skill())
	var events := battle.play_round(SKILL)
	assert_eq(_hits(events)[0], "Aldric>41")
	assert_true(events[0].skill)
	for expected_cooldown in [2, 1]:
		assert_eq(battle.skill_cooldown, expected_cooldown)
		assert_false(battle.can_use_skill())
		assert_eq(battle.play_round(SKILL).size(), 0, "em recarga não faz nada")
		battle.play_round(ATTACK)
	assert_eq(battle.round, 4)
	assert_true(battle.can_use_skill())


func test_defeat() -> void:
	var battle := _battle(_enemy(200, 1000, 500))
	var events := battle.play_round(ATTACK)
	assert_eq(battle.outcome, Battle.Outcome.DEFEAT)
	assert_eq(battle.hero.hp, 0)
	assert_eq(_hits(events), ["Rato Gigante>492"])


func test_critical_hit() -> void:
	var events := _battle(_enemy(), FixedDice.new(0.0)).play_round(ATTACK)
	assert_true(events[0].critical)
	assert_eq(events[0].damage, 39)


func test_play_round_after_end_does_nothing() -> void:
	var battle := _battle()
	battle.play_round(FLEE)
	assert_eq(battle.play_round(ATTACK).size(), 0)
	assert_eq(battle.round, 1)


func test_original_hero_is_not_changed() -> void:
	var hero := _aldric()
	var battle := Battle.new(hero, _enemy(95, 1000), FixedDice.new())
	battle.play_round(ATTACK)
	assert_eq(hero.current_hp, 240)
	assert_eq(battle.hero.hp, 228)


func test_hero_with_zero_hp_starts_with_one() -> void:
	var hero := _aldric()
	hero.current_hp = 0
	assert_eq(Battle.new(hero, _enemy(), FixedDice.new()).hero.hp, 1)
