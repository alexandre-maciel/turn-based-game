class_name Battle
extends RefCounted
## Combate 1×1 por rodadas. O jogador escolhe a ação do herói, play_round()
## resolve a rodada inteira e devolve o que aconteceu, em ordem.
## Não conhece o Player: quem aplica o resultado é o GameState.

enum Action { ATTACK, SKILL, DEFEND, FLEE }
enum Outcome { ONGOING, VICTORY, DEFEAT, FLED }

var hero: Combatant
var enemy: Combatant
var enemy_data: Enemy
var skill: Dictionary
var round := 1
var outcome := Outcome.ONGOING
var skill_cooldown := 0  ## Rodadas que faltam para a habilidade voltar.
var _dice: Dice


func _init(p_hero: Hero, p_enemy: Enemy, p_dice: Dice = Dice.new()) -> void:
	hero = Combatant.from_hero(p_hero)
	enemy = Combatant.from_enemy(p_enemy)
	enemy_data = p_enemy
	skill = StatFormulas.skill_for(p_hero.hero_class)
	_dice = p_dice


func is_over() -> bool:
	return outcome != Outcome.ONGOING


func can_use_skill() -> bool:
	return not is_over() and skill_cooldown == 0


## Resolve uma rodada. Fugir e Defender valem antes dos ataques; os ataques
## seguem a velocidade (empate: herói). Ação inválida devolve lista vazia.
func play_round(action: Action) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	if is_over() or (action == Action.SKILL and not can_use_skill()):
		return events
	if action == Action.FLEE:
		outcome = Outcome.FLED
		events.append(BattleEvent.new(BattleEvent.Kind.FLEE, hero))
		return events
	var defending := action == Action.DEFEND
	if defending:
		events.append(BattleEvent.new(BattleEvent.Kind.DEFEND, hero))
	if action == Action.SKILL:
		skill_cooldown = skill["cooldown"]
	var order := [hero, enemy] if hero.speed >= enemy.speed else [enemy, hero]
	for attacker: Combatant in order:
		var target := enemy if attacker == hero else hero
		if attacker == hero:
			if defending:
				continue
			events.append(_hit(hero, enemy, action == Action.SKILL, false))
		else:
			events.append(_hit(enemy, hero, false, defending))
		if not target.is_alive():
			events.append(BattleEvent.new(BattleEvent.Kind.DEFEATED, target))
			outcome = Outcome.VICTORY if target == enemy else Outcome.DEFEAT
			return events
	skill_cooldown = maxi(0, skill_cooldown - 1)
	round += 1
	return events


func _hit(attacker: Combatant, target: Combatant, is_skill: bool, defending: bool) -> BattleEvent:
	var critical := _dice.roll_percent() < attacker.crit_chance
	var multiplier: float = skill["multiplier"] if is_skill else 1.0
	var damage := StatFormulas.damage(attacker.attack, target.defense, multiplier,
		_dice.variance(), critical, defending)
	target.hp = maxi(0, target.hp - damage)
	var event := BattleEvent.new(BattleEvent.Kind.HIT, attacker, target)
	event.damage = damage
	event.critical = critical
	event.skill = is_skill
	return event
