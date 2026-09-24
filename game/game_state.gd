extends Node
## Autoload "GameState": dono do Player atual e da lista de inimigos. A UI só
## lê daqui e escuta os sinais; mudanças no Player passam pelos métodos daqui,
## e todo método que altera o Player termina com _save().

signal player_changed(player: Player)
signal load_failed(error: String)
signal save_failed(error: String)

var repository: HeroRepository = _default_repository()
var player: Player = null
var load_error := ""
## Aviso do último carregamento (ex.: save danificado trocado por um jogo novo).
var load_warning := ""
var enemy_repository: EnemyRepository = LocalEnemyRepository.new()
var enemies: Array[Enemy] = []
var enemies_error := ""


func _ready() -> void:
	reload()
	reload_enemies()


## Jogo normal: o save do jogador. Rodando por --script (testes, ferramentas),
## o SceneTree tem script próprio: usa o herói de exemplo, só leitura, para
## nunca ler nem gravar o save de verdade.
static func _default_repository() -> HeroRepository:
	if Engine.get_main_loop().get_script() != null:
		return LocalHeroRepository.new()
	return SaveGameRepository.new()


func reload() -> void:
	var result := repository.load_player()
	load_warning = result.warning
	if load_warning != "":
		push_warning("GameState: " + load_warning)
	if result.is_ok():
		player = result.player
		load_error = ""
		player_changed.emit(player)
	else:
		player = null
		load_error = result.error
		push_error("GameState: " + load_error)
		load_failed.emit(load_error)


## Sem inimigos o jogo continua; o painel do Treino mostra o erro.
func reload_enemies() -> void:
	var result := enemy_repository.load_enemies()
	enemies = result.enemies
	enemies_error = result.error
	if not result.is_ok():
		push_error("GameState: " + enemies_error)


func has_player() -> bool:
	return player != null


## Aplica o fim de um combate: na vitória, XP e ouro. Em qualquer caso o HP
## volta ao máximo (regra do Treino). Devolve quantos níveis o herói subiu.
func apply_battle_result(battle: Battle) -> int:
	if player == null or not battle.is_over():
		push_error("GameState: apply_battle_result sem herói ou com combate em andamento")
		return 0
	var levels_gained := _give_rewards(battle)
	player.hero.current_hp = StatFormulas.max_hp(player.hero)
	player_changed.emit(player)
	_save()
	return levels_gained


## Fim de um combate da Torre. Vitória: recompensas, próximo andar e 20% de HP
## de volta. Derrota: a escalada recomeça (o recorde fica). Fuga: mantém o
## andar com o HP que sobrou. Devolve quantos níveis o herói subiu.
func apply_tower_result(battle: Battle) -> int:
	if player == null or not battle.is_over():
		push_error("GameState: apply_tower_result sem herói ou com combate em andamento")
		return 0
	var levels_gained := _give_rewards(battle)
	var tower := player.tower
	var max_hp := StatFormulas.max_hp(player.hero)
	match battle.outcome:
		Battle.Outcome.VICTORY:
			tower.best_floor = maxi(tower.best_floor, tower.floor_number)
			tower.floor_number += 1
			tower.hp = mini(max_hp, battle.hero.hp + Tower.regen(max_hp))
		Battle.Outcome.DEFEAT:
			player.tower = TowerProgress.fresh(player.hero, tower.best_floor)
		Battle.Outcome.FLED:
			tower.hp = clampi(battle.hero.hp, 1, max_hp)
	player_changed.emit(player)
	_save()
	return levels_gained


## Abandona a escalada: andar 1 com HP cheio; o recorde fica.
func reset_tower() -> void:
	if player == null:
		return
	player.tower = TowerProgress.fresh(player.hero, player.tower.best_floor)
	player_changed.emit(player)
	_save()


## XP e ouro da vitória (nada na derrota e na fuga). Devolve os níveis ganhos.
func _give_rewards(battle: Battle) -> int:
	if battle.outcome != Battle.Outcome.VICTORY:
		return 0
	player.gold += battle.enemy_data.gold_reward
	return Progression.apply_xp(player.hero, battle.enemy_data.xp_reward)


func _save() -> void:
	var error := repository.save_player(player)
	if error != "":
		push_error("GameState: " + error)
		save_failed.emit(error)
