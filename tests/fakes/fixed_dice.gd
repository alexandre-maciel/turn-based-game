class_name FixedDice
extends Dice
## Sorteio de teste: devolve sempre os valores escolhidos.
## Padrão: nunca crítico e sem variação.

var percent := 100.0
var variance_value := 1.0


func _init(p_percent: float = 100.0, p_variance: float = 1.0) -> void:
	percent = p_percent
	variance_value = p_variance


func roll_percent() -> float:
	return percent


func variance() -> float:
	return variance_value
