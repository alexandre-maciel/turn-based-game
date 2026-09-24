class_name BaseTest
extends RefCounted
## Base dos testes. O executor (tests/run_tests.gd) preenche `tree`,
## chama before_each → teste → after_each → cleanup e lê `failures`.

var tree: SceneTree
var failures: Array[String] = []
var _nodes: Array[Node] = []
var _repository_swapped := false


func before_each() -> void:
	pass


func after_each() -> void:
	pass


## Libera os nós de add_to_tree() e restaura a fonte de dados real do GameState.
## Chamado pelo executor.
func cleanup() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()
	if _repository_swapped:
		_repository_swapped = false
		var game_state = _game_state()
		game_state.repository = LocalHeroRepository.new()
		game_state.reload()


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) == typeof(expected) and actual == expected:
		return
	_fail("esperado <%s> (%s), obtido <%s> (%s). %s" % [
		str(expected), type_string(typeof(expected)),
		str(actual), type_string(typeof(actual)), message])


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		_fail("esperado verdadeiro. " + message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		_fail("esperado falso. " + message)


## Adiciona o nó à árvore; ele é liberado no cleanup().
func add_to_tree(node: Node) -> Node:
	tree.root.add_child(node)
	_nodes.append(node)
	return node


## Troca a fonte de dados do GameState durante o teste e recarrega.
func use_repository(repository: HeroRepository) -> void:
	_repository_swapped = true
	var game_state = _game_state()
	game_state.repository = repository
	game_state.reload()


## O autoload pela árvore: este script é compilado junto com o executor,
## antes de o nome global "GameState" existir.
func _game_state() -> Node:
	return tree.root.get_node("GameState")


func left_click() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	return event


## Simula apertar e soltar uma tecla. Use com await.
func press_key(keycode: Key) -> void:
	for is_pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		event.pressed = is_pressed
		Input.parse_input_event(event)
	await tree.process_frame
	await tree.process_frame


func _fail(text: String) -> void:
	failures.append(text)
