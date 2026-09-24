class_name Attributes
extends RefCounted
## Atributos base do herói. Só dados; as regras ficam em StatFormulas.

const NAMES: Array[String] = ["strength", "agility", "intelligence", "vitality"]

var strength: int
var agility: int
var intelligence: int
var vitality: int


func _init(p_strength: int = 0, p_agility: int = 0, p_intelligence: int = 0, p_vitality: int = 0) -> void:
	strength = p_strength
	agility = p_agility
	intelligence = p_intelligence
	vitality = p_vitality


## Lê um atributo pelo nome (um dos NAMES).
func get_value(attribute_name: String) -> int:
	assert(NAMES.has(attribute_name), "Atributo desconhecido: " + attribute_name)
	return get(attribute_name)
