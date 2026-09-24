class_name FailingEnemyRepository
extends EnemyRepository
## Repositório de teste que sempre falha.

const ERROR := "falha de teste dos inimigos"


func load_enemies() -> EnemyLoadResult:
	return EnemyLoadResult.failure(ERROR)
