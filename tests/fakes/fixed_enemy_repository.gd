class_name FixedEnemyRepository
extends EnemyRepository
## Repositório de teste que devolve sempre os mesmos inimigos.

var enemies: Array[Enemy]


func _init(p_enemies: Array[Enemy]) -> void:
	enemies = p_enemies


func load_enemies() -> EnemyLoadResult:
	return EnemyLoadResult.success(enemies)


## Um inimigo fraco (morre com um golpe do Aldric) e um forte (derrota o Aldric).
static func weak_and_strong() -> FixedEnemyRepository:
	var weak := Enemy.new("weak", "Fraco", 1, 10, 1, 0, 0, 1, 70, 15)
	var strong := Enemy.new("strong", "Forte", 9, 5000, 999, 0, 0, 999, 500, 200)
	return FixedEnemyRepository.new([weak, strong])
