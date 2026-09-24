class_name FailingHeroRepository
extends HeroRepository
## Repositório de teste que sempre falha.

const ERROR := "falha de teste"


func load_player() -> LoadResult:
	return LoadResult.failure(ERROR)
