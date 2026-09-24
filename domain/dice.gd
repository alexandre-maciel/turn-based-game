class_name Dice
extends RefCounted
## Sorteios do combate. O Battle recebe um Dice para os testes poderem trocar
## por um FixedDice e ter resultados previsíveis.

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


## Número entre 0 e 100. Crítico quando fica abaixo da chance de crítico.
func roll_percent() -> float:
	return _rng.randf() * 100.0


## Multiplicador de variação do dano, entre 0,9 e 1,1.
func variance() -> float:
	return _rng.randf_range(0.9, 1.1)
