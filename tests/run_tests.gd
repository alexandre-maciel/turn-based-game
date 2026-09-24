extends SceneTree
## Executor de testes sem plugins. Roda todos os tests/test_*.gd.
## Uso: bash run_tests.sh [--only=parte_do_nome]

const TESTS_DIR := "res://tests"


## Captura erros de script (acesso a null, chave inexistente...). Sem isto, o
## Godot só aborta a função de teste e ela apareceria como "ok".
## push_error() (ex.: GameState em testes de falha) não é erro de script e é ignorado.
class ScriptErrorCatcher extends Logger:
	var errors: Array[String] = []

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_SCRIPT:
			errors.append("erro de script: %s (%s:%d)" % [rationale if rationale != "" else code, file, line])


var _catcher := ScriptErrorCatcher.new()


func _initialize() -> void:
	OS.add_logger(_catcher)
	# Espera um frame para os autoloads terminarem o _ready().
	await process_frame
	var filter := _read_filter()
	var total := 0
	var failed := 0
	for file_name in _test_files(filter):
		var script: GDScript = load(TESTS_DIR + "/" + file_name)
		if script == null or not script.can_instantiate():
			print("FALHOU  %s: não foi possível carregar o script (erro de sintaxe?)" % file_name)
			total += 1
			failed += 1
			continue
		if not script.new() is BaseTest:
			# Sem esta checagem, chamar before_each trava o executor.
			print("FALHOU  %s: o script não estende BaseTest (ou BaseTest não compilou)" % file_name)
			total += 1
			failed += 1
			continue
		for method in _test_methods(script):
			total += 1
			var test: BaseTest = script.new()
			test.tree = self
			_catcher.errors.clear()
			await test.call("before_each")
			await test.call(method)
			await test.call("after_each")
			test.cleanup()
			test.failures.append_array(_catcher.errors)
			if test.failures.is_empty():
				print("ok      %s::%s" % [file_name, method])
			else:
				failed += 1
				print("FALHOU  %s::%s" % [file_name, method])
				for failure in test.failures:
					print("        - " + failure)
	print("\n%d testes, %d falhas" % [total, failed])
	quit(1 if failed > 0 or total == 0 else 0)


func _read_filter() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			return arg.trim_prefix("--only=")
	return ""


func _test_files(filter: String) -> Array[String]:
	var result: Array[String] = []
	for file_name in DirAccess.get_files_at(TESTS_DIR):
		# Atenção: no Godot, "abc".contains("") é false; por isso o teste de filtro vazio.
		var matches_filter := filter == "" or file_name.contains(filter)
		if file_name.begins_with("test_") and file_name.ends_with(".gd") and matches_filter:
			result.append(file_name)
	result.sort()
	return result


func _test_methods(script: GDScript) -> Array[String]:
	var result: Array[String] = []
	for method in script.get_script_method_list():
		var method_name: String = method["name"]
		if method_name.begins_with("test_") and not result.has(method_name):
			result.append(method_name)
	return result
