class_name BattleEvent
extends RefCounted
## Uma coisa que aconteceu na rodada. A tela exibe os eventos um por um;
## `target_hp_after` guarda o HP do alvo naquele momento.

enum Kind { HIT, DEFEND, FLEE, DEFEATED }

var kind: Kind
var actor: Combatant
var target: Combatant
var damage := 0
var critical := false
var skill := false
var target_hp_after := 0


func _init(p_kind: Kind, p_actor: Combatant, p_target: Combatant = null) -> void:
	kind = p_kind
	actor = p_actor
	target = p_target
	if target != null:
		target_hp_after = target.hp
