class_name HeroRepository
extends RefCounted
## Fonte dos dados do jogador. Hoje: LocalHeroRepository (JSON local).
## Futuro online: uma versão remota com o mesmo load_player().


func load_player() -> LoadResult:
	return LoadResult.failure("HeroRepository.load_player() não implementado")
