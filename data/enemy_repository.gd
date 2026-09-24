class_name EnemyRepository
extends RefCounted
## Fonte dos inimigos. Hoje: LocalEnemyRepository (JSON local).
## Futuro online: uma versão remota com o mesmo load_enemies().


func load_enemies() -> EnemyLoadResult:
	return EnemyLoadResult.failure("EnemyRepository.load_enemies() não implementado")
