class_name JsonFields
extends RefCounted
## Leitura e validação de campos de um JSON. Guarda o primeiro erro em `error`;
## depois dele, cada método vira no-op e devolve um valor vazio.

var error := ""


## Lê o arquivo e devolve o objeto raiz ({} se der erro).
func read_object(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		error = "Arquivo não encontrado: %s" % path
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		error = "JSON inválido em %s (linha %d): %s" % [
			path, json.get_error_line(), json.get_error_message()]
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		error = "O JSON em %s deve ser um objeto" % path
		return {}
	return json.data


func dict(data: Dictionary, key: String, prefix: String) -> Dictionary:
	if error != "":
		return {}
	if typeof(data.get(key)) != TYPE_DICTIONARY:
		error = "Campo '%s%s' ausente ou não é um objeto" % [prefix, key]
		return {}
	return data[key]


func array(data: Dictionary, key: String, prefix: String) -> Array:
	if error != "":
		return []
	if typeof(data.get(key)) != TYPE_ARRAY:
		error = "Campo '%s%s' ausente ou não é uma lista" % [prefix, key]
		return []
	return data[key]


func string(data: Dictionary, key: String, prefix: String) -> String:
	if error != "":
		return ""
	var value: Variant = data.get(key)
	if typeof(value) != TYPE_STRING or (value as String).strip_edges() == "":
		error = "Campo '%s%s' ausente ou vazio" % [prefix, key]
		return ""
	return value


## O JSON do Godot entrega números como float: aceita 12 e 12.0, recusa 12.5 e "12".
## min_value = null significa sem mínimo.
func integer(data: Dictionary, key: String, prefix: String, min_value: Variant) -> int:
	if error != "":
		return 0
	var field := prefix + key
	var value: Variant = data.get(key)
	if typeof(value) == TYPE_FLOAT and value == floorf(value):
		value = int(value)
	if typeof(value) != TYPE_INT:
		error = "Campo '%s' ausente ou não é um número inteiro" % field
		return 0
	if min_value != null and value < min_value:
		error = "Campo '%s' deve ser no mínimo %d (recebido %d)" % [field, min_value, value]
		return 0
	return value
