class_name RecordingHeroRepository
extends FixedHeroRepository
## Repositório de teste que devolve o Aldric e guarda cada save_player() recebido.
## Com `save_error` preenchido, finge que a gravação falhou.

var saved: Array[Dictionary] = []  ## HeroSerializer.to_dict() de cada gravação
var save_error := ""
var warning := ""


func _init() -> void:
	super(FixedHeroRepository.aldric().player)


func load_player() -> LoadResult:
	var result := super()
	result.warning = warning
	return result


func save_player(p_player: Player) -> String:
	saved.append(HeroSerializer.to_dict(p_player))
	return save_error
