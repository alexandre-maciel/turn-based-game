# MVP Cidade + Painel do Personagem: plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Um jogo Godot 4.7.2 que abre na cidade de Eldoria (6 construções clicáveis, HUD do herói, chat visual, barra de menu no canto inferior direito). Clicar em "Personagem" abre um painel com os status do Mago Aldric, calculados por fórmulas testadas.

**Architecture:** Três camadas com dependência em uma só direção. `domain/` tem classes GDScript puras (`RefCounted`) com as regras. `data/` tem um repositório trocável que lê e valida o JSON. `game/game_state.gd` é um autoload que guarda o `Player` e avisa a UI por sinais. A UI (`ui/`) só lê e exibe, nunca altera dados. Cada componente de UI monta seus nós filhos em código; `ui/main.tscn` guarda só a árvore principal.

**Tech Stack:** Godot 4.7.2 (GDScript tipado, renderer Compatibility) e um executor de testes próprio em headless, sem plugins.

**Spec:** `docs/superpowers/specs/2026-09-24-mvp-cidade-personagem-design.md`

## Global Constraints

- Engine: Godot **4.7.2**. Executável de console: `Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe` (é uma **pasta** com esse nome, contendo os `.exe`).
- Renderer `gl_compatibility`; viewport base **1280×720**; `window/stretch/mode="canvas_items"`; `window/stretch/aspect="expand"`.
- Todo texto visível ao jogador fica em `ui/texts.gd` (classe `Texts`), em português. Não escreva textos soltos em outros arquivos.
- `domain/` não usa `Node`, cenas nem `Texts`. Só `RefCounted`.
- A UI nunca altera `Player`/`Hero` e nunca guarda uma cópia própria. Ela lê `GameState.player` e se redesenha nos sinais `player_changed` / `load_failed`.
- Conecte sinais do `GameState` a **métodos** (`_on_player_changed`), nunca a lambdas. Assim a conexão cai sozinha quando o nó é liberado; com lambdas, os testes quebram.
- Só existe a classe `mage` (Mago, atributo principal `intelligence`).
- Construções: `castle`, `tower`, `blacksmith`, `market`, `arena`, `training`. Não existe taverna.
- Números vindos do JSON chegam como `float` no Godot. Aceite `12` e `12.0`, recuse `12.5` e `"12"`.
- GDScript com **tabs**, tipagem estática, e `## doc-comment` curto no topo de cada classe.
- Rodar testes: `bash run_tests.sh` (tudo) ou `bash run_tests.sh --only=<parte do nome do arquivo>`. O script roda `--import` antes, o que é necessário para o Godot registrar `class_name` novos. Saída final: `N testes, F falhas`; código de saída 0 só se F = 0 e N > 0.
- Mensagens `ERROR: ... falha de teste` / `Arquivo não encontrado` no log durante os testes são **esperadas** (vêm de `push_error` em testes de falha). Só o resumo final decide.
- Faça commit dos arquivos `.uid` e `.import` que o Godot gera ao lado dos seus arquivos. `.godot/` é ignorado.
- Todo commit termina com a linha `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (use um segundo `-m`).

## Desvios conscientes da spec

- `CityScreen` e `Building` são `Control` (não `Node2D`/`Area2D`). O clique vem por `_gui_input` e dá para testar sem física. O comportamento é o mesmo da spec.
- O tema é montado em código (`ui/theme/game_theme.gd`), não em `.tres`. Assim ele troca sozinho para `assets/ui/panel_frame.png` quando a arte existir.
- Não existe `building.tscn`: `building.gd` desenha a construção.
- A base dos testes se chama `BaseTest` (`tests/base_test.gd`), não `test_case.gd`, porque o executor roda todo `test_*.gd`. O "teste de fumaça" da spec virou `test_city_screen`, `test_hud`, `test_character_panel` e `test_layout`.
- Em componentes que já estão na árvore, `set_anchors_preset()` recalcula os offsets. Por isso eles sempre redefinem os quatro `offset_*` logo em seguida.

## Review Focus

1. **Janela maior ou ultrawide** (ex.: 1920×1080, 2560×1080): o HUD fica preso aos cantos, a barra no canto inferior direito, e as construções centralizadas no palco de 1280×720. Teste: `test_layout.gd` (Task 8).
2. **Nome de herói longo** (ex.: "Bartholomew Maximilian Von Eldoria"): o HUD não estica pela tela, o nome é cortado com reticências. Teste em `test_hud.gd` (Task 7).
3. **Números grandes** (ouro 1.234.567): exibidos com separador de milhar, sem quebrar o layout. Testes em `test_texts.gd` (Task 5) e `test_hud.gd` (Task 7).
4. **JSON editado à mão no Bloco de Notas**: BOM UTF-8 no início, número digitado como texto (`"14"`) e campos extras. BOM e extras são aceitos; texto no lugar de número gera erro claro com o nome do campo. Testes em `test_local_hero_repository.gd` (Task 3).
5. **Interações repetidas**: Esc com o painel fechado, abrir o painel já aberto, clicar em construções em sequência. Nada quebra, e o aviso mostra o último texto e reinicia o tempo. Testes em `test_city_screen.gd` (Task 6) e `test_character_panel.gd` (Task 8).

## Mapa de arquivos

```
project.godot                      config (Task 1; autoload na Task 4; cena principal na Task 6)
run_tests.sh / run_tests.cmd       atalhos para rodar os testes (Task 1)
domain/attributes.gd               Attributes (Task 2)
domain/hero.gd                     Hero (Task 2)
domain/player.gd                   Player (Task 2)
domain/stat_formulas.gd            StatFormulas: fórmulas + tabela de classes (Task 2)
data/load_result.gd                LoadResult (Task 3)
data/hero_repository.gd            HeroRepository: interface (Task 3)
data/local_hero_repository.gd      LocalHeroRepository: lê e valida o JSON (Task 3)
data/sample_hero.json              Aldric (Task 3)
game/game_state.gd                 autoload GameState (Task 4)
ui/texts.gd                        Texts (Task 5)
ui/art_loader.gd                   ArtLoader (Task 5)
ui/theme/game_theme.gd             GameTheme (Task 5)
ui/city/building.gd                Building (Task 6)
ui/city/city_screen.gd             CityScreen (Task 6)
ui/hud/toast.gd                    Toast (Task 6)
ui/main.tscn, ui/main.gd           cena principal (Task 6, ampliada nas Tasks 7 e 8)
ui/common/icon_view.gd             IconView (Task 7)
ui/hud/portrait.gd                 Portrait (Task 7)
ui/hud/hero_hud.gd                 HeroHud (Task 7)
ui/hud/currency_hud.gd             CurrencyHud (Task 7)
ui/hud/chat_box.gd                 ChatBox (Task 7)
ui/bottom_bar/bottom_bar.gd        BottomBar (Task 8)
ui/character_panel/character_panel.gd  CharacterPanel (Task 8)
assets/README.md + pastas          lista de artes (Task 9)
tools/screenshot.gd                captura de tela para conferência (Task 9)
tests/base_test.gd, tests/run_tests.gd   executor (Task 1)
tests/fakes/*.gd                   repositórios falsos (Task 4)
tests/fixtures/*                   JSONs e SVG de teste (Tasks 3 e 5)
tests/test_*.gd                    testes
```

---

### Task 1: Projeto Godot + executor de testes

**Files:**
- Create: `project.godot`
- Create: `run_tests.sh`
- Create: `run_tests.cmd`
- Create: `tests/base_test.gd`
- Create: `tests/run_tests.gd`
- Test: `tests/test_base_test.gd`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: nada
- Produces:
  - `class_name BaseTest extends RefCounted` com `var tree: SceneTree`, `var failures: Array[String]`, `before_each()`, `after_each()`, `cleanup()`, `assert_eq(actual: Variant, expected: Variant, message: String = "")`, `assert_true(condition: bool, message: String = "")`, `assert_false(condition: bool, message: String = "")`, `add_to_tree(node: Node) -> Node`, `left_click() -> InputEventMouseButton`, `press_key(keycode: Key) -> void` (coroutine: use `await`).
  - Executor: roda `tests/test_*.gd`. Cada método `test_*` recebe uma instância nova, e a ordem é `before_each` → teste → `after_each` → `cleanup`.

- [ ] **Step 1: Criar `project.godot`**

```ini
; Engine configuration file.
config_version=5

[application]

config/name="Primeiro Jogo"
config/features=PackedStringArray("4.7", "GL Compatibility")

[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[rendering]

renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

- [ ] **Step 2: Criar os atalhos de teste**

`run_tests.sh`:
```bash
#!/usr/bin/env bash
# Roda os testes em modo headless. Uso: bash run_tests.sh [--only=parte_do_nome]
set -u
cd "$(dirname "$0")"
GODOT="Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
# Importa antes (registra class_name novos e arte nova).
"$GODOT" --headless --path . --import >/dev/null 2>&1
"$GODOT" --headless --path . --script res://tests/run_tests.gd -- "$@"
```

`run_tests.cmd` (para rodar com duplo clique ou pelo PowerShell):
```bat
@echo off
rem Roda os testes em modo headless. Uso: run_tests.cmd [--only=parte_do_nome]
cd /d "%~dp0"
set GODOT=Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe
"%GODOT%" --headless --path . --import >nul 2>&1
"%GODOT%" --headless --path . --script res://tests/run_tests.gd -- %*
```

- [ ] **Step 3: Escrever o teste das ferramentas de teste**

`tests/test_base_test.gd`:
```gdscript
extends BaseTest
## Testa as próprias ferramentas de teste.


class KeyCatcher extends Node:
	var pressed_keys: Array[Key] = []

	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed:
			pressed_keys.append(event.keycode)


func test_assert_eq_accepts_equal_values() -> void:
	var probe := BaseTest.new()
	probe.assert_eq(29, 29)
	probe.assert_eq("Aldric", "Aldric")
	assert_eq(probe.failures.size(), 0)


func test_assert_eq_rejects_different_types() -> void:
	var probe := BaseTest.new()
	probe.assert_eq(4, 4.0)
	assert_eq(probe.failures.size(), 1)


func test_assert_eq_rejects_different_values_and_keeps_message() -> void:
	var probe := BaseTest.new()
	probe.assert_eq(28, 29, "ataque")
	assert_eq(probe.failures.size(), 1)
	assert_true(probe.failures[0].contains("ataque"), probe.failures[0])


func test_assert_true_and_false() -> void:
	var probe := BaseTest.new()
	probe.assert_true(false)
	probe.assert_false(true)
	assert_eq(probe.failures.size(), 2)


func test_add_to_tree_and_cleanup_frees_node() -> void:
	var node := Node.new()
	add_to_tree(node)
	assert_true(node.is_inside_tree())
	cleanup()
	assert_false(is_instance_valid(node))


func test_left_click_is_pressed_left_button() -> void:
	var event := left_click()
	assert_eq(event.button_index, MOUSE_BUTTON_LEFT)
	assert_true(event.pressed)


func test_press_key_reaches_unhandled_input() -> void:
	var catcher := KeyCatcher.new()
	add_to_tree(catcher)
	await press_key(KEY_ESCAPE)
	assert_eq(catcher.pressed_keys.size(), 1)
	if catcher.pressed_keys.size() == 1:
		assert_eq(catcher.pressed_keys[0], KEY_ESCAPE)
```

- [ ] **Step 4: Rodar e confirmar que falha**

Run: `bash run_tests.sh`
Expected: erro ao carregar `res://tests/run_tests.gd` (o arquivo ainda não existe) e **nenhuma** linha `testes, ... falhas`.

- [ ] **Step 5: Implementar `tests/base_test.gd`**

```gdscript
class_name BaseTest
extends RefCounted
## Base dos testes. O executor (tests/run_tests.gd) preenche `tree`,
## chama before_each → teste → after_each → cleanup e lê `failures`.

var tree: SceneTree
var failures: Array[String] = []
var _nodes: Array[Node] = []


func before_each() -> void:
	pass


func after_each() -> void:
	pass


## Libera os nós adicionados com add_to_tree(). Chamado pelo executor.
func cleanup() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


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
```

- [ ] **Step 6: Implementar `tests/run_tests.gd`**

```gdscript
extends SceneTree
## Executor de testes sem plugins. Roda todos os tests/test_*.gd.
## Uso: bash run_tests.sh [--only=parte_do_nome]

const TESTS_DIR := "res://tests"


func _initialize() -> void:
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
		for method in _test_methods(script):
			total += 1
			var test: BaseTest = script.new()
			test.tree = self
			await test.call("before_each")
			await test.call(method)
			await test.call("after_each")
			test.cleanup()
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
		if file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name.contains(filter):
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
```

- [ ] **Step 7: Rodar e confirmar que passa**

Run: `bash run_tests.sh`
Expected: 7 linhas `ok      test_base_test.gd::...` e `7 testes, 0 falhas`; código de saída 0 (`echo $?` → `0`).

- [ ] **Step 8: Confirmar que o executor detecta falha**

Crie temporariamente `tests/test_zz_should_fail.gd`:
```gdscript
extends BaseTest


func test_fails_on_purpose() -> void:
	assert_eq(1, 2, "falha proposital")
```
Run: `bash run_tests.sh; echo "exit=$?"`
Expected: `FALHOU  test_zz_should_fail.gd::test_fails_on_purpose`, `8 testes, 1 falhas`, `exit=1`.
Depois apague: `rm tests/test_zz_should_fail.gd tests/test_zz_should_fail.gd.uid 2>/dev/null; true`

- [ ] **Step 9: Ignorar capturas de tela**

Adicione ao final de `.gitignore`:
```gitignore

# Capturas geradas por tools/screenshot.gd
screenshots/
```

- [ ] **Step 10: Commit**

```bash
git add project.godot run_tests.sh run_tests.cmd .gitignore tests/
git commit -m "chore: projeto Godot e executor de testes headless" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Domínio (atributos, herói, jogador, fórmulas)

**Files:**
- Create: `domain/attributes.gd`
- Create: `domain/hero.gd`
- Create: `domain/player.gd`
- Create: `domain/stat_formulas.gd`
- Test: `tests/test_stat_formulas.gd`

**Interfaces:**
- Consumes: `BaseTest` (Task 1)
- Produces:
  - `Attributes.new(strength: int, agility: int, intelligence: int, vitality: int)`; propriedades com esses nomes; `const NAMES: Array[String]`; `get_value(attribute_name: String) -> int`
  - `Hero.new(id: String, hero_name: String, hero_class: String, level: int, xp: int, current_hp: int, attributes: Attributes)`; propriedades `id, hero_name, hero_class, level, xp, current_hp, attributes`
  - `Player.new(hero: Hero, gold: int, gems: int)`; propriedades `hero, gold, gems`
  - `StatFormulas` (tudo `static`): `CLASSES`, `is_valid_class(hero_class: String) -> bool`, `main_attribute(hero_class: String) -> String`, `max_hp(hero: Hero) -> int`, `attack(hero: Hero) -> int`, `defense(hero: Hero) -> int`, `crit_chance(hero: Hero) -> float`, `speed(hero: Hero) -> int`, `xp_to_next_level(level: int) -> int`

- [ ] **Step 1: Escrever o teste que falha**

`tests/test_stat_formulas.gd`:
```gdscript
extends BaseTest
## Fórmulas de status (spec, seção 4). Aldric: Mago nv 1, For 5, Agi 8, Int 14, Vit 12.


func _mage(level: int = 1, attributes: Attributes = Attributes.new(5, 8, 14, 12)) -> Hero:
	return Hero.new("hero-001", "Aldric", "mage", level, 35, 240, attributes)


func test_aldric_max_hp() -> void:
	assert_eq(StatFormulas.max_hp(_mage()), 240)


func test_aldric_attack() -> void:
	assert_eq(StatFormulas.attack(_mage()), 29)


func test_aldric_defense() -> void:
	assert_eq(StatFormulas.defense(_mage()), 17)


func test_aldric_crit_chance() -> void:
	assert_eq(StatFormulas.crit_chance(_mage()), 4.0)


func test_aldric_speed() -> void:
	assert_eq(StatFormulas.speed(_mage()), 108)


func test_mage_attack_uses_intelligence_not_strength() -> void:
	var brute := _mage(1, Attributes.new(50, 0, 1, 0))
	assert_eq(StatFormulas.attack(brute), 3)


func test_defense_rounds_half_agility_down() -> void:
	var hero := _mage(1, Attributes.new(0, 9, 0, 0))
	assert_eq(StatFormulas.defense(hero), 5)


func test_zero_attributes() -> void:
	var hero := _mage(1, Attributes.new(0, 0, 0, 0))
	assert_eq(StatFormulas.max_hp(hero), 120)
	assert_eq(StatFormulas.attack(hero), 1)
	assert_eq(StatFormulas.defense(hero), 1)
	assert_eq(StatFormulas.crit_chance(hero), 0.0)
	assert_eq(StatFormulas.speed(hero), 100)


func test_level_scales_hp_attack_and_defense() -> void:
	var hero := _mage(5)
	assert_eq(StatFormulas.max_hp(hero), 320)
	assert_eq(StatFormulas.attack(hero), 33)
	assert_eq(StatFormulas.defense(hero), 21)


func test_xp_to_next_level() -> void:
	assert_eq(StatFormulas.xp_to_next_level(1), 100)
	assert_eq(StatFormulas.xp_to_next_level(2), 283)
	assert_eq(StatFormulas.xp_to_next_level(5), 1118)
	assert_eq(StatFormulas.xp_to_next_level(10), 3162)


func test_only_mage_class_exists() -> void:
	assert_true(StatFormulas.is_valid_class("mage"))
	assert_false(StatFormulas.is_valid_class("warrior"))
	assert_eq(StatFormulas.main_attribute("mage"), "intelligence")


func test_attributes_get_value_by_name() -> void:
	var attributes := Attributes.new(5, 8, 14, 12)
	assert_eq(attributes.get_value("strength"), 5)
	assert_eq(attributes.get_value("agility"), 8)
	assert_eq(attributes.get_value("intelligence"), 14)
	assert_eq(attributes.get_value("vitality"), 12)
```

- [ ] **Step 2: Rodar e confirmar que falha**

Run: `bash run_tests.sh --only=stat_formulas`
Expected: `FALHOU  test_stat_formulas.gd: não foi possível carregar o script` (as classes `Hero`/`Attributes`/`StatFormulas` ainda não existem) e código de saída 1.

- [ ] **Step 3: Implementar `domain/attributes.gd`**

```gdscript
class_name Attributes
extends RefCounted
## Atributos base do herói. Só dados; as regras ficam em StatFormulas.

const NAMES: Array[String] = ["strength", "agility", "intelligence", "vitality"]

var strength: int
var agility: int
var intelligence: int
var vitality: int


func _init(p_strength: int = 0, p_agility: int = 0, p_intelligence: int = 0, p_vitality: int = 0) -> void:
	strength = p_strength
	agility = p_agility
	intelligence = p_intelligence
	vitality = p_vitality


## Lê um atributo pelo nome (um dos NAMES).
func get_value(attribute_name: String) -> int:
	assert(NAMES.has(attribute_name), "Atributo desconhecido: " + attribute_name)
	return get(attribute_name)
```

- [ ] **Step 4: Implementar `domain/hero.gd`**

```gdscript
class_name Hero
extends RefCounted
## Um herói do jogador. Só dados; as regras ficam em StatFormulas.

var id: String
var hero_name: String
var hero_class: String
var level: int
var xp: int
var current_hp: int
var attributes: Attributes


func _init(p_id: String, p_hero_name: String, p_hero_class: String, p_level: int, p_xp: int, p_current_hp: int, p_attributes: Attributes) -> void:
	id = p_id
	hero_name = p_hero_name
	hero_class = p_hero_class
	level = p_level
	xp = p_xp
	current_hp = p_current_hp
	attributes = p_attributes
```

- [ ] **Step 5: Implementar `domain/player.gd`**

```gdscript
class_name Player
extends RefCounted
## A conta do jogador: o herói e as moedas (que no online pertencem à conta).

var hero: Hero
var gold: int
var gems: int


func _init(p_hero: Hero, p_gold: int, p_gems: int) -> void:
	hero = p_hero
	gold = p_gold
	gems = p_gems
```

- [ ] **Step 6: Implementar `domain/stat_formulas.gd`**

```gdscript
class_name StatFormulas
extends RefCounted
## Regras de cálculo dos status. Funções puras: mesmo herói, mesmo resultado.
## Todo o balanceamento mora aqui.

## Classes jogáveis. Para criar outra classe, acrescente uma entrada.
const CLASSES := {
	"mage": {"main_attribute": "intelligence"},
}


static func is_valid_class(hero_class: String) -> bool:
	return CLASSES.has(hero_class)


static func main_attribute(hero_class: String) -> String:
	return CLASSES[hero_class]["main_attribute"]


static func max_hp(hero: Hero) -> int:
	return 100 + hero.attributes.vitality * 10 + hero.level * 20


static func attack(hero: Hero) -> int:
	return hero.attributes.get_value(main_attribute(hero.hero_class)) * 2 + hero.level


static func defense(hero: Hero) -> int:
	return hero.attributes.vitality + floori(hero.attributes.agility / 2.0) + hero.level


## Chance de crítico em porcentagem (4.0 = 4%).
static func crit_chance(hero: Hero) -> float:
	return hero.attributes.agility * 0.5


static func speed(hero: Hero) -> int:
	return 100 + hero.attributes.agility


static func xp_to_next_level(level: int) -> int:
	return roundi(100.0 * pow(level, 1.5))
```

- [ ] **Step 7: Rodar e confirmar que passa**

Run: `bash run_tests.sh`
Expected: todas as linhas `ok`, `19 testes, 0 falhas`.

- [ ] **Step 8: Commit**

```bash
git add domain/ tests/test_stat_formulas.gd tests/*.uid
git commit -m "feat: domínio do herói e fórmulas de status" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Repositório local (JSON + validação)

**Files:**
- Create: `data/load_result.gd`
- Create: `data/hero_repository.gd`
- Create: `data/local_hero_repository.gd`
- Create: `data/sample_hero.json`
- Create: `tests/fixtures/*.json` (listados no Step 1)
- Test: `tests/test_local_hero_repository.gd`

**Interfaces:**
- Consumes: `Attributes`, `Hero`, `Player`, `StatFormulas.is_valid_class`, `StatFormulas.max_hp` (Task 2)
- Produces:
  - `LoadResult`: `var player: Player`, `var error: String`, `static success(player: Player) -> LoadResult`, `static failure(message: String) -> LoadResult`, `is_ok() -> bool`
  - `HeroRepository` (base): `load_player() -> LoadResult`
  - `LocalHeroRepository extends HeroRepository`: `const DEFAULT_PATH := "res://data/sample_hero.json"`, `_init(path: String = DEFAULT_PATH)`, `load_player() -> LoadResult`. As mensagens de erro citam o campo no formato `hero.level`, `hero.attributes.intelligence`, `currencies.gold`.

- [ ] **Step 1: Criar os dados e os fixtures**

`data/sample_hero.json`:
```json
{
  "hero": {
    "id": "hero-001", "name": "Aldric", "class": "mage",
    "level": 1, "xp": 35, "current_hp": 240,
    "attributes": { "strength": 5, "agility": 8, "intelligence": 14, "vitality": 12 }
  },
  "currencies": { "gold": 1250, "gems": 20 }
}
```

`tests/fixtures/malformed.json`:
```json
{ "hero": { "name": "Aldric",
```

`tests/fixtures/array_root.json`:
```json
[1, 2]
```

`tests/fixtures/missing_level.json`:
```json
{"hero": {"id": "hero-001", "name": "Aldric", "class": "mage", "xp": 35, "current_hp": 240, "attributes": {"strength": 5, "agility": 8, "intelligence": 14, "vitality": 12}}, "currencies": {"gold": 1250, "gems": 20}}
```

`tests/fixtures/invalid_class.json`:
```json
{"hero": {"id": "hero-001", "name": "Aldric", "class": "warrior", "level": 1, "xp": 35, "current_hp": 240, "attributes": {"strength": 5, "agility": 8, "intelligence": 14, "vitality": 12}}, "currencies": {"gold": 1250, "gems": 20}}
```

`tests/fixtures/level_zero.json`:
```json
{"hero": {"id": "hero-001", "name": "Aldric", "class": "mage", "level": 0, "xp": 35, "current_hp": 240, "attributes": {"strength": 5, "agility": 8, "intelligence": 14, "vitality": 12}}, "currencies": {"gold": 1250, "gems": 20}}
```

`tests/fixtures/fractional_attribute.json`:
```json
{"hero": {"id": "hero-001", "name": "Aldric", "class": "mage", "level": 1, "xp": 35, "current_hp": 240, "attributes": {"strength": 5, "agility": 8, "intelligence": 14.5, "vitality": 12}}, "currencies": {"gold": 1250, "gems": 20}}
```

`tests/fixtures/text_number.json`:
```json
{"hero": {"id": "hero-001", "name": "Aldric", "class": "mage", "level": 1, "xp": 35, "current_hp": 240, "attributes": {"strength": 5, "agility": 8, "intelligence": "14", "vitality": 12}}, "currencies": {"gold": 1250, "gems": 20}}
```

`tests/fixtures/negative_gold.json`:
```json
{"hero": {"id": "hero-001", "name": "Aldric", "class": "mage", "level": 1, "xp": 35, "current_hp": 240, "attributes": {"strength": 5, "agility": 8, "intelligence": 14, "vitality": 12}}, "currencies": {"gold": -1, "gems": 20}}
```

`tests/fixtures/hp_over_max.json`:
```json
{"hero": {"id": "hero-001", "name": "Aldric", "class": "mage", "level": 1, "xp": 35, "current_hp": 9999, "attributes": {"strength": 5, "agility": 8, "intelligence": 14, "vitality": 12}}, "currencies": {"gold": 1250, "gems": 20}}
```

`tests/fixtures/hp_negative.json`:
```json
{"hero": {"id": "hero-001", "name": "Aldric", "class": "mage", "level": 1, "xp": 35, "current_hp": -5, "attributes": {"strength": 5, "agility": 8, "intelligence": 14, "vitality": 12}}, "currencies": {"gold": 1250, "gems": 20}}
```

`tests/fixtures/extra_fields.json`:
```json
{"version": 2, "hero": {"id": "hero-001", "name": "Aldric", "class": "mage", "title": "Novato", "level": 1, "xp": 35, "current_hp": 240, "attributes": {"strength": 5, "agility": 8, "intelligence": 14, "vitality": 12, "luck": 3}}, "currencies": {"gold": 1250, "gems": 20}}
```

O fixture com BOM (Bloco de Notas) é gerado a partir do exemplo:
```bash
printf '\xEF\xBB\xBF' | cat - data/sample_hero.json > tests/fixtures/bom.json
```

- [ ] **Step 2: Escrever o teste que falha**

`tests/test_local_hero_repository.gd`:
```gdscript
extends BaseTest
## Carregamento e validação do JSON do jogador (spec, seção 4).

const FIXTURES := "res://tests/fixtures/"


func _load(file_name: String) -> LoadResult:
	return LocalHeroRepository.new(FIXTURES + file_name).load_player()


func _assert_error_contains(result: LoadResult, text: String) -> void:
	assert_false(result.is_ok(), "deveria falhar")
	assert_true(result.error.contains(text), "erro '%s' deveria conter '%s'" % [result.error, text])


func test_loads_sample_hero() -> void:
	var result := LocalHeroRepository.new().load_player()
	assert_true(result.is_ok(), result.error)
	if not result.is_ok():
		return
	var hero := result.player.hero
	assert_eq(hero.id, "hero-001")
	assert_eq(hero.hero_name, "Aldric")
	assert_eq(hero.hero_class, "mage")
	assert_eq(hero.level, 1)
	assert_eq(hero.xp, 35)
	assert_eq(hero.current_hp, 240)
	assert_eq(hero.attributes.strength, 5)
	assert_eq(hero.attributes.agility, 8)
	assert_eq(hero.attributes.intelligence, 14)
	assert_eq(hero.attributes.vitality, 12)
	assert_eq(result.player.gold, 1250)
	assert_eq(result.player.gems, 20)


func test_missing_file() -> void:
	_assert_error_contains(_load("nao_existe.json"), "não encontrado")


func test_malformed_json() -> void:
	_assert_error_contains(_load("malformed.json"), "JSON inválido")


func test_root_must_be_object() -> void:
	_assert_error_contains(_load("array_root.json"), "deve ser um objeto")


func test_missing_field() -> void:
	_assert_error_contains(_load("missing_level.json"), "hero.level")


func test_invalid_class() -> void:
	_assert_error_contains(_load("invalid_class.json"), "warrior")


func test_level_zero() -> void:
	_assert_error_contains(_load("level_zero.json"), "hero.level")


func test_fractional_attribute() -> void:
	_assert_error_contains(_load("fractional_attribute.json"), "hero.attributes.intelligence")


func test_number_written_as_text() -> void:
	_assert_error_contains(_load("text_number.json"), "hero.attributes.intelligence")


func test_negative_gold() -> void:
	_assert_error_contains(_load("negative_gold.json"), "currencies.gold")


func test_current_hp_above_max_is_clamped() -> void:
	var result := _load("hp_over_max.json")
	assert_true(result.is_ok(), result.error)
	if result.is_ok():
		assert_eq(result.player.hero.current_hp, 240)


func test_negative_current_hp_is_clamped_to_zero() -> void:
	var result := _load("hp_negative.json")
	assert_true(result.is_ok(), result.error)
	if result.is_ok():
		assert_eq(result.player.hero.current_hp, 0)


func test_extra_fields_are_ignored() -> void:
	var result := _load("extra_fields.json")
	assert_true(result.is_ok(), result.error)


func test_utf8_bom_from_notepad_is_accepted() -> void:
	var result := _load("bom.json")
	assert_true(result.is_ok(), result.error)
	if result.is_ok():
		assert_eq(result.player.hero.hero_name, "Aldric")
```

- [ ] **Step 3: Rodar e confirmar que falha**

Run: `bash run_tests.sh --only=local_hero_repository`
Expected: `FALHOU  test_local_hero_repository.gd: não foi possível carregar o script`, código 1.

- [ ] **Step 4: Implementar `data/load_result.gd`**

```gdscript
class_name LoadResult
extends RefCounted
## Resultado de carregar o jogador: ou `player` preenchido, ou `error`.

var player: Player
var error: String = ""


static func success(p_player: Player) -> LoadResult:
	var result := LoadResult.new()
	result.player = p_player
	return result


static func failure(message: String) -> LoadResult:
	var result := LoadResult.new()
	result.error = message
	return result


func is_ok() -> bool:
	return player != null
```

- [ ] **Step 5: Implementar `data/hero_repository.gd`**

```gdscript
class_name HeroRepository
extends RefCounted
## Fonte dos dados do jogador. Hoje: LocalHeroRepository (JSON local).
## Futuro online: uma versão remota com o mesmo load_player().


func load_player() -> LoadResult:
	return LoadResult.failure("HeroRepository.load_player() não implementado")
```

- [ ] **Step 6: Implementar `data/local_hero_repository.gd`**

```gdscript
class_name LocalHeroRepository
extends HeroRepository
## Carrega o jogador de um JSON local e valida cada campo.

const DEFAULT_PATH := "res://data/sample_hero.json"

var path: String
var _error := ""


func _init(p_path: String = DEFAULT_PATH) -> void:
	path = p_path


func load_player() -> LoadResult:
	_error = ""
	if not FileAccess.file_exists(path):
		return LoadResult.failure("Arquivo não encontrado: %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return LoadResult.failure("JSON inválido em %s (linha %d): %s" % [
			path, json.get_error_line(), json.get_error_message()])
	if typeof(json.data) != TYPE_DICTIONARY:
		return LoadResult.failure("O JSON em %s deve ser um objeto" % path)
	var player := _parse_player(json.data)
	if player == null:
		return LoadResult.failure("%s: %s" % [path, _error])
	return LoadResult.success(player)


## Lê o jogador; em caso de problema, preenche _error e devolve null.
## Cada helper vira no-op depois do primeiro erro.
func _parse_player(root: Dictionary) -> Player:
	var hero_data := _dict(root, "hero", "")
	var attribute_data := _dict(hero_data, "attributes", "hero.")
	var currency_data := _dict(root, "currencies", "")
	var hero_class := _string(hero_data, "class", "hero.")
	if _error == "" and not StatFormulas.is_valid_class(hero_class):
		_error = "Classe desconhecida: '%s'" % hero_class
	var attributes := Attributes.new(
		_int(attribute_data, "strength", "hero.attributes.", 0),
		_int(attribute_data, "agility", "hero.attributes.", 0),
		_int(attribute_data, "intelligence", "hero.attributes.", 0),
		_int(attribute_data, "vitality", "hero.attributes.", 0))
	var hero := Hero.new(
		_string(hero_data, "id", "hero."),
		_string(hero_data, "name", "hero."),
		hero_class,
		_int(hero_data, "level", "hero.", 1),
		_int(hero_data, "xp", "hero.", 0),
		_int(hero_data, "current_hp", "hero.", null),
		attributes)
	var gold := _int(currency_data, "gold", "currencies.", 0)
	var gems := _int(currency_data, "gems", "currencies.", 0)
	if _error != "":
		return null
	hero.current_hp = clampi(hero.current_hp, 0, StatFormulas.max_hp(hero))
	return Player.new(hero, gold, gems)


func _dict(data: Dictionary, key: String, prefix: String) -> Dictionary:
	if _error != "":
		return {}
	if typeof(data.get(key)) != TYPE_DICTIONARY:
		_error = "Campo '%s%s' ausente ou não é um objeto" % [prefix, key]
		return {}
	return data[key]


func _string(data: Dictionary, key: String, prefix: String) -> String:
	if _error != "":
		return ""
	var value: Variant = data.get(key)
	if typeof(value) != TYPE_STRING or (value as String).strip_edges() == "":
		_error = "Campo '%s%s' ausente ou vazio" % [prefix, key]
		return ""
	return value


## O JSON do Godot entrega números como float: aceita 12 e 12.0, recusa 12.5 e "12".
## min_value = null significa sem mínimo.
func _int(data: Dictionary, key: String, prefix: String, min_value: Variant) -> int:
	if _error != "":
		return 0
	var field := prefix + key
	var value: Variant = data.get(key)
	if typeof(value) == TYPE_FLOAT and value == floorf(value):
		value = int(value)
	if typeof(value) != TYPE_INT:
		_error = "Campo '%s' ausente ou não é um número inteiro" % field
		return 0
	if min_value != null and value < min_value:
		_error = "Campo '%s' deve ser no mínimo %d (recebido %d)" % [field, min_value, value]
		return 0
	return value
```

- [ ] **Step 7: Rodar e confirmar que passa**

Run: `bash run_tests.sh`
Expected: todas `ok`, `33 testes, 0 falhas`.

- [ ] **Step 8: Commit**

```bash
git add data/ tests/
git commit -m "feat: repositório local do herói com validação do JSON" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Autoload `GameState` + repositórios falsos

**Files:**
- Create: `game/game_state.gd`
- Modify: `project.godot` (seção `[autoload]`)
- Create: `tests/fakes/failing_hero_repository.gd`
- Create: `tests/fakes/fixed_hero_repository.gd`
- Modify: `tests/base_test.gd` (novo `use_repository`, `cleanup` restaura)
- Test: `tests/test_game_state.gd`

**Interfaces:**
- Consumes: `HeroRepository`, `LocalHeroRepository`, `LoadResult` (Task 3); `Player`, `Hero`, `Attributes` (Task 2)
- Produces:
  - Autoload `GameState` (sem `class_name`): `signal player_changed(player: Player)`, `signal load_failed(error: String)`, `var repository: HeroRepository`, `var player: Player` (null se falhou), `var load_error: String`, `reload() -> void`, `has_player() -> bool`. Carrega em `_ready()`.
  - `FailingHeroRepository.new()`: `const ERROR := "falha de teste"`
  - `FixedHeroRepository.new(player: Player)` e `FixedHeroRepository.aldric(level: int = 1, hero_name: String = "Aldric", gold: int = 1250) -> FixedHeroRepository`
  - `BaseTest.use_repository(repository: HeroRepository) -> void`: troca a fonte e recarrega; o `cleanup()` volta para `LocalHeroRepository` e recarrega.

- [ ] **Step 1: Criar os repositórios falsos**

`tests/fakes/failing_hero_repository.gd`:
```gdscript
class_name FailingHeroRepository
extends HeroRepository
## Repositório de teste que sempre falha.

const ERROR := "falha de teste"


func load_player() -> LoadResult:
	return LoadResult.failure(ERROR)
```

`tests/fakes/fixed_hero_repository.gd`:
```gdscript
class_name FixedHeroRepository
extends HeroRepository
## Repositório de teste que devolve sempre o mesmo jogador.

var player: Player


func _init(p_player: Player) -> void:
	player = p_player


func load_player() -> LoadResult:
	return LoadResult.success(player)


## O Aldric da spec, com ajustes opcionais para testes.
static func aldric(level: int = 1, hero_name: String = "Aldric", gold: int = 1250) -> FixedHeroRepository:
	var hero := Hero.new("hero-001", hero_name, "mage", level, 35, 240, Attributes.new(5, 8, 14, 12))
	return FixedHeroRepository.new(Player.new(hero, gold, 20))
```

- [ ] **Step 2: Estender `tests/base_test.gd`**

Adicione a variável logo abaixo de `var _nodes: Array[Node] = []`:
```gdscript
var _repository_swapped := false
```

Substitua a função `cleanup()` inteira por:
```gdscript
## Libera os nós de add_to_tree() e restaura a fonte de dados real do GameState.
## Chamado pelo executor.
func cleanup() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()
	if _repository_swapped:
		_repository_swapped = false
		GameState.repository = LocalHeroRepository.new()
		GameState.reload()
```

Adicione depois de `add_to_tree()`:
```gdscript
## Troca a fonte de dados do GameState durante o teste e recarrega.
func use_repository(repository: HeroRepository) -> void:
	_repository_swapped = true
	GameState.repository = repository
	GameState.reload()
```

- [ ] **Step 3: Escrever o teste que falha**

`tests/test_game_state.gd`:
```gdscript
extends BaseTest
## Autoload GameState: carrega via repositório e avisa por sinais.


func test_loads_sample_player_on_startup() -> void:
	assert_true(GameState.has_player())
	assert_eq(GameState.player.hero.hero_name, "Aldric")
	assert_eq(GameState.load_error, "")


func test_reload_emits_player_changed() -> void:
	var received: Array = []
	var on_changed := func(player: Player) -> void: received.append(player)
	GameState.player_changed.connect(on_changed)
	GameState.reload()
	GameState.player_changed.disconnect(on_changed)
	assert_eq(received.size(), 1)
	assert_true(received[0] is Player)


func test_failure_clears_player_and_emits_load_failed() -> void:
	var errors: Array = []
	var on_failed := func(error: String) -> void: errors.append(error)
	GameState.load_failed.connect(on_failed)
	use_repository(FailingHeroRepository.new())
	GameState.load_failed.disconnect(on_failed)
	assert_false(GameState.has_player())
	assert_true(GameState.player == null)
	assert_eq(GameState.load_error, FailingHeroRepository.ERROR)
	assert_eq(errors, [FailingHeroRepository.ERROR])


func test_recovers_after_failure() -> void:
	use_repository(FailingHeroRepository.new())
	use_repository(FixedHeroRepository.aldric(5))
	assert_true(GameState.has_player())
	assert_eq(GameState.player.hero.level, 5)
	assert_eq(GameState.load_error, "")
```

- [ ] **Step 4: Rodar e confirmar que falha**

Run: `bash run_tests.sh --only=game_state`
Expected: `FALHOU  test_game_state.gd: não foi possível carregar o script` (identificador `GameState` não declarado), código 1.

- [ ] **Step 5: Implementar `game/game_state.gd`**

```gdscript
extends Node
## Autoload "GameState": dono do Player atual. A UI só lê daqui e escuta
## os sinais; nunca altera os dados diretamente.

signal player_changed(player: Player)
signal load_failed(error: String)

var repository: HeroRepository = LocalHeroRepository.new()
var player: Player = null
var load_error := ""


func _ready() -> void:
	reload()


func reload() -> void:
	var result := repository.load_player()
	if result.is_ok():
		player = result.player
		load_error = ""
		player_changed.emit(player)
	else:
		player = null
		load_error = result.error
		push_error("GameState: " + load_error)
		load_failed.emit(load_error)


func has_player() -> bool:
	return player != null
```

- [ ] **Step 6: Registrar o autoload em `project.godot`**

Adicione entre `[application]` e `[display]`:
```ini
[autoload]

GameState="*res://game/game_state.gd"

```

- [ ] **Step 7: Rodar e confirmar que passa**

Run: `bash run_tests.sh`
Expected: todas `ok`, `37 testes, 0 falhas`. Linhas `ERROR: GameState: falha de teste` no log são esperadas.

- [ ] **Step 8: Commit**

```bash
git add game/ project.godot tests/
git commit -m "feat: autoload GameState com repositório trocável" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Base da UI (textos, carregador de arte, tema)

**Files:**
- Create: `ui/texts.gd`
- Create: `ui/art_loader.gd`
- Create: `ui/theme/game_theme.gd`
- Create: `tests/fixtures/pixel.svg`
- Test: `tests/test_texts.gd`
- Test: `tests/test_art_loader.gd`
- Test: `tests/test_game_theme.gd`

**Interfaces:**
- Consumes: nada de UI; só constantes.
- Produces:
  - `Texts`: consts `LOAD_ERROR`, `CHAT_TEXT`, `PANEL_TITLE`, `SECTION_ATTRIBUTES`, `SECTION_COMBAT`, `HP`, `XP`, dicionários `CLASS_LABELS`, `BUILDINGS`, `MENU`, `ATTRIBUTES`, `COMBAT_STATS`, `SLOTS` (ids → rótulos em português); funções `static coming_soon(display_name: String) -> String`, `class_label(hero_class: String) -> String`, `class_and_level(hero_class: String, level: int) -> String`, `short_level(level: int) -> String`, `fraction(current: int, maximum: int) -> String`, `percent(value: float) -> String`, `thousands(value: int) -> String`
  - `ArtLoader.texture_or_null(path: String) -> Texture2D`
  - `GameTheme`: consts de cor `BROWN`, `BROWN_DARK`, `GOLD`, `GOLD_LIGHT`, `TEXT`, `HP_RED`, `PANEL_FRAME_PATH`; `static get_theme() -> Theme` (mesma instância sempre), `static panel_style() -> StyleBox`, `static box(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat`, `static make_bar(fill: Color, min_width: float) -> ProgressBar`

- [ ] **Step 1: Escrever os testes que falham**

`tests/test_texts.gd`:
```gdscript
extends BaseTest
## Formatação de textos exibidos ao jogador.


func test_coming_soon() -> void:
	assert_eq(Texts.coming_soon("Torre"), "Torre — em breve")


func test_class_and_level() -> void:
	assert_eq(Texts.class_and_level("mage", 1), "Mago · Nível 1")
	assert_eq(Texts.short_level(7), "Nv 7")


func test_unknown_class_label_falls_back_to_id() -> void:
	assert_eq(Texts.class_label("druid"), "druid")


func test_fraction() -> void:
	assert_eq(Texts.fraction(35, 100), "35 / 100")


func test_percent_hides_zero_decimal_and_uses_comma() -> void:
	assert_eq(Texts.percent(4.0), "4%")
	assert_eq(Texts.percent(4.5), "4,5%")
	assert_eq(Texts.percent(0.0), "0%")


func test_thousands_separator() -> void:
	assert_eq(Texts.thousands(0), "0")
	assert_eq(Texts.thousands(20), "20")
	assert_eq(Texts.thousands(1250), "1.250")
	assert_eq(Texts.thousands(1234567), "1.234.567")
	assert_eq(Texts.thousands(-1250), "-1.250")


func test_six_buildings_without_tavern() -> void:
	assert_eq(Texts.BUILDINGS.keys(), ["castle", "tower", "blacksmith", "market", "arena", "training"])
	assert_eq(Texts.BUILDINGS["tower"], "Torre")
```

`tests/test_art_loader.gd`:
```gdscript
extends BaseTest
## Arte opcional: null quando o arquivo não existe.


func test_missing_file_returns_null() -> void:
	assert_true(ArtLoader.texture_or_null("res://assets/nao_existe.png") == null)


func test_existing_image_returns_texture() -> void:
	var texture := ArtLoader.texture_or_null("res://tests/fixtures/pixel.svg")
	assert_true(texture != null, "o fixture pixel.svg deveria carregar")
	assert_true(texture is Texture2D)
```

`tests/test_game_theme.gd`:
```gdscript
extends BaseTest
## Tema visual único.


func test_theme_is_shared_instance() -> void:
	assert_true(GameTheme.get_theme() == GameTheme.get_theme())


func test_label_uses_text_color() -> void:
	assert_eq(GameTheme.get_theme().get_color("font_color", "Label"), GameTheme.TEXT)


func test_panel_style_follows_frame_art() -> void:
	# Sem assets/ui/panel_frame.png: moldura desenhada. Com a arte: 9-slice da imagem.
	if ResourceLoader.exists(GameTheme.PANEL_FRAME_PATH):
		assert_true(GameTheme.panel_style() is StyleBoxTexture)
	else:
		assert_true(GameTheme.panel_style() is StyleBoxFlat)


func test_make_bar() -> void:
	var bar := GameTheme.make_bar(GameTheme.HP_RED, 150.0)
	assert_false(bar.show_percentage)
	assert_eq(bar.custom_minimum_size.x, 150.0)
	bar.free()
```

`tests/fixtures/pixel.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" width="4" height="4"><rect width="4" height="4" fill="#c9a24a"/></svg>
```

- [ ] **Step 2: Rodar e confirmar que falha**

Run: `bash run_tests.sh`
Expected: `FALHOU` para `test_art_loader.gd`, `test_game_theme.gd` e `test_texts.gd` (os scripts não carregam), os testes anteriores continuam `ok`, código 1.

- [ ] **Step 3: Implementar `ui/texts.gd`**

```gdscript
class_name Texts
extends RefCounted
## Todos os textos visíveis ao jogador ficam aqui (facilita traduzir depois).

const LOAD_ERROR := "Erro ao carregar personagem"
const CHAT_TEXT := "[Sistema] Bem-vindo a Eldoria!\n[Mundo] O chat chegará em breve."
const PANEL_TITLE := "Personagem"
const SECTION_ATTRIBUTES := "Atributos"
const SECTION_COMBAT := "Combate"
const HP := "HP"
const XP := "XP"

const CLASS_LABELS := {"mage": "Mago"}

const BUILDINGS := {
	"castle": "Castelo",
	"tower": "Torre",
	"blacksmith": "Ferreiro",
	"market": "Mercado",
	"arena": "Arena",
	"training": "Treino",
}

const MENU := {
	"character": "Personagem",
	"bag": "Mochila",
	"skills": "Habilidades",
	"quests": "Missões",
	"guild": "Guilda",
	"settings": "Config",
}

const ATTRIBUTES := {
	"strength": "Força",
	"agility": "Agilidade",
	"intelligence": "Inteligência",
	"vitality": "Vitalidade",
}

const COMBAT_STATS := {
	"attack": "Ataque",
	"defense": "Defesa",
	"crit_chance": "Crítico",
	"speed": "Velocidade",
}

const SLOTS := {
	"helmet": "Elmo",
	"armor": "Armadura",
	"boots": "Botas",
	"necklace": "Colar",
	"ring": "Anel",
	"cape": "Capa",
	"weapon": "Arma",
	"shield": "Escudo",
}


static func coming_soon(display_name: String) -> String:
	return "%s — em breve" % display_name


static func class_label(hero_class: String) -> String:
	return CLASS_LABELS.get(hero_class, hero_class)


static func class_and_level(hero_class: String, level: int) -> String:
	return "%s · Nível %d" % [class_label(hero_class), level]


static func short_level(level: int) -> String:
	return "Nv %d" % level


static func fraction(current: int, maximum: int) -> String:
	return "%d / %d" % [current, maximum]


## 4.0 → "4%", 4.5 → "4,5%".
static func percent(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d%%" % roundi(value)
	return ("%.1f%%" % value).replace(".", ",")


## 1234567 → "1.234.567".
static func thousands(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	while digits.length() > 3:
		grouped = "." + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + grouped
```

- [ ] **Step 4: Implementar `ui/art_loader.gd`**

```gdscript
class_name ArtLoader
extends RefCounted
## Carrega arte opcional de assets/. Se o arquivo não existir, devolve null e o
## componente desenha seu placeholder. Arte nova: coloque o PNG com o nome da
## lista (assets/README.md) e abra o projeto no editor uma vez para importar.


static func texture_or_null(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
```

- [ ] **Step 5: Implementar `ui/theme/game_theme.gd`**

```gdscript
class_name GameTheme
extends RefCounted
## Tema visual único (marrom e dourado). CanvasLayer não repassa tema, então
## main.gd aplica get_theme() em cada Control raiz. Se
## assets/ui/panel_frame.png existir, as janelas usam essa moldura (9-slice, bordas de 24 px).

const BROWN := Color("#3d2a16")
const BROWN_DARK := Color("#2a1c0e")
const GOLD := Color("#c9a24a")
const GOLD_LIGHT := Color("#e8c56a")
const TEXT := Color("#f3e2b3")
const HP_RED := Color("#c0392b")
const PANEL_FRAME_PATH := "res://assets/ui/panel_frame.png"
const FRAME_BORDER := 24

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


static func panel_style() -> StyleBox:
	var frame := ArtLoader.texture_or_null(PANEL_FRAME_PATH)
	if frame == null:
		return box(BROWN, GOLD, 3, 8)
	var style := StyleBoxTexture.new()
	style.texture = frame
	style.texture_margin_left = FRAME_BORDER
	style.texture_margin_top = FRAME_BORDER
	style.texture_margin_right = FRAME_BORDER
	style.texture_margin_bottom = FRAME_BORDER
	style.set_content_margin_all(FRAME_BORDER / 2.0)
	return style


static func box(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(6)
	return style


static func make_bar(fill: Color, min_width: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(min_width, 10)
	bar.add_theme_stylebox_override("fill", box(fill, Color.TRANSPARENT, 0, 3))
	return bar


static func _build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16
	theme.set_color("font_color", "Label", TEXT)
	theme.set_stylebox("panel", "PanelContainer", panel_style())
	theme.set_stylebox("panel", "Panel", panel_style())
	theme.set_stylebox("normal", "Button", box(BROWN, GOLD, 2, 6))
	theme.set_stylebox("hover", "Button", box(BROWN.lightened(0.15), GOLD_LIGHT, 2, 6))
	theme.set_stylebox("pressed", "Button", box(BROWN_DARK, GOLD_LIGHT, 2, 6))
	theme.set_stylebox("disabled", "Button", box(BROWN_DARK, GOLD.darkened(0.5), 2, 6))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", GOLD_LIGHT)
	theme.set_color("font_pressed_color", "Button", GOLD_LIGHT)
	theme.set_color("font_disabled_color", "Button", Color(TEXT, 0.4))
	theme.set_stylebox("background", "ProgressBar", box(Color("#222222"), Color.TRANSPARENT, 0, 3))
	theme.set_stylebox("fill", "ProgressBar", box(GOLD, Color.TRANSPARENT, 0, 3))
	return theme
```

- [ ] **Step 6: Rodar e confirmar que passa**

Run: `bash run_tests.sh`
Expected: todas `ok`, `50 testes, 0 falhas`.

- [ ] **Step 7: Commit**

```bash
git add ui/ tests/
git commit -m "feat: textos, carregador de arte e tema visual" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Cidade, construções, aviso e cena principal

**Files:**
- Create: `ui/city/building.gd`
- Create: `ui/city/city_screen.gd`
- Create: `ui/hud/toast.gd`
- Create: `ui/main.gd`
- Create: `ui/main.tscn`
- Modify: `project.godot` (cena principal)
- Test: `tests/test_city_screen.gd`

**Interfaces:**
- Consumes: `Texts.BUILDINGS`, `Texts.coming_soon`, `ArtLoader.texture_or_null`, `GameTheme.get_theme` (Task 5)
- Produces:
  - `Building extends Control`: `signal clicked`, `var building_id: String`, `var display_name: String`, `setup(id: String, display_name: String, rect: Rect2) -> void`, `is_hovered() -> bool`
  - `CityScreen extends Control`: `signal building_clicked(building_id: String, display_name: String)`, `const STAGE_SIZE := Vector2(1280, 720)`, `const LAYOUT` (id → `Rect2`), `var buildings: Dictionary` (id → `Building`), `var stage: Control`
  - `Toast extends PanelContainer`: `const DURATION := 2.0`, `var label: Label`, `var hide_timer: Timer`, `show_message(text: String) -> void`
  - `ui/main.tscn`: nós `CityScreen`, `HUDLayer/HUD/Toast`, `WindowLayer`. `main.gd` expõe `city`, `toast`.

- [ ] **Step 1: Escrever o teste que falha**

`tests/test_city_screen.gd`:
```gdscript
extends BaseTest
## Cidade: 6 construções nas posições da spec; clique mostra "em breve".

var main: Node


func before_each() -> void:
	main = add_to_tree(load("res://ui/main.tscn").instantiate())
	await tree.process_frame


func test_six_buildings_in_spec_positions() -> void:
	var city: CityScreen = main.city
	assert_eq(city.buildings.keys(), ["castle", "tower", "blacksmith", "market", "arena", "training"])
	var tower: Building = city.buildings["tower"]
	assert_eq(tower.position, Vector2(138, 206))
	assert_eq(tower.size, Vector2(120, 190))
	var castle: Building = city.buildings["castle"]
	assert_eq(castle.position, Vector2(512, 173))
	assert_eq(castle.size, Vector2(230, 187))


func test_click_building_shows_coming_soon_toast() -> void:
	var tower: Building = main.city.buildings["tower"]
	tower._gui_input(left_click())
	assert_true(main.toast.visible)
	assert_eq(main.toast.label.text, "Torre — em breve")


func test_right_click_does_nothing() -> void:
	var event := left_click()
	event.button_index = MOUSE_BUTTON_RIGHT
	main.city.buildings["arena"]._gui_input(event)
	assert_false(main.toast.visible)


func test_toast_hides_when_timer_ends() -> void:
	main.toast.show_message("x")
	main.toast.hide_timer.timeout.emit()
	assert_false(main.toast.visible)


func test_clicking_again_shows_latest_text_and_restarts_timer() -> void:
	main.city.buildings["tower"]._gui_input(left_click())
	main.city.buildings["market"]._gui_input(left_click())
	assert_eq(main.toast.label.text, "Mercado — em breve")
	assert_true(main.toast.hide_timer.time_left > Toast.DURATION - 0.2)


func test_hover_highlights_building() -> void:
	var market: Building = main.city.buildings["market"]
	market.mouse_entered.emit()
	assert_true(market.is_hovered())
	assert_true(market.modulate != Color.WHITE)
	market.mouse_exited.emit()
	assert_false(market.is_hovered())
	assert_eq(market.modulate, Color.WHITE)


func test_buildings_use_pointing_hand_cursor() -> void:
	for building: Building in main.city.buildings.values():
		assert_eq(building.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND, building.building_id)
```

- [ ] **Step 2: Rodar e confirmar que falha**

Run: `bash run_tests.sh --only=city_screen`
Expected: `FALHOU  test_city_screen.gd: não foi possível carregar o script`, código 1.

- [ ] **Step 3: Implementar `ui/city/building.gd`**

```gdscript
class_name Building
extends Control
## Uma construção clicável da cidade. Usa assets/city/<id>.png se existir;
## senão desenha um placeholder (paredes, telhado e porta). O nome aparece embaixo.

signal clicked

const WALL := Color("#8a6a4a")
const WALL_BORDER := Color("#3b2a1a")
const ROOF := Color("#a33a2a")
const DOOR := Color("#4a3020")
const HOVER_TINT := Color(1.25, 1.2, 1.0)
const NAME_FONT_SIZE := 14

var building_id: String
var display_name: String
var _texture: Texture2D
var _hovered := false


func setup(p_id: String, p_display_name: String, rect: Rect2) -> void:
	building_id = p_id
	display_name = p_display_name
	position = rect.position
	size = rect.size
	tooltip_text = p_display_name
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_texture = ArtLoader.texture_or_null("res://assets/city/%s.png" % p_id)


func _ready() -> void:
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))


func is_hovered() -> bool:
	return _hovered


func _set_hovered(value: bool) -> void:
	_hovered = value
	modulate = HOVER_TINT if value else Color.WHITE


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
		accept_event()


func _draw() -> void:
	if _texture != null:
		draw_texture_rect(_texture, _fit(_texture.get_size()), false)
	else:
		_draw_placeholder()
	_draw_name()


func _draw_placeholder() -> void:
	var roof_height := size.y * 0.35
	var walls := Rect2(0, roof_height, size.x, size.y - roof_height)
	draw_rect(walls, WALL)
	draw_rect(walls, WALL_BORDER, false, 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x / 2.0, 0), Vector2(size.x, roof_height), Vector2(0, roof_height)]), ROOF)
	var door_size := Vector2(size.x * 0.18, walls.size.y * 0.45)
	draw_rect(Rect2(Vector2((size.x - door_size.x) / 2.0, size.y - door_size.y), door_size), DOOR)


func _draw_name() -> void:
	var font := get_theme_default_font()
	var text_width := font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE).x
	var baseline := Vector2((size.x - text_width) / 2.0, size.y - 6)
	draw_string_outline(font, baseline, display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE, 4, Color.BLACK)
	draw_string(font, baseline, display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE, Color.WHITE)


## Encaixa a arte na caixa mantendo a proporção, alinhada embaixo e no centro.
func _fit(texture_size: Vector2) -> Rect2:
	var factor := minf(size.x / texture_size.x, size.y / texture_size.y)
	var draw_size := texture_size * factor
	return Rect2(Vector2((size.x - draw_size.x) / 2.0, size.y - draw_size.y), draw_size)
```

- [ ] **Step 4: Implementar `ui/city/city_screen.gd`**

```gdscript
class_name CityScreen
extends Control
## Tela da cidade: fundo + construções clicáveis. As construções ficam num
## "palco" fixo de 1280×720 centralizado; telas largas só ganham céu/grama nas laterais.

signal building_clicked(building_id: String, display_name: String)

const STAGE_SIZE := Vector2(1280, 720)
const BACKGROUND_PATH := "res://assets/city/background.png"
const SKY := Color("#9cc3e6")
const GRASS := Color("#5f8a47")
const HORIZON := 0.39  ## Fração da altura do palco onde o céu vira grama.

## Posição e tamanho de cada construção no palco (spec, seção 5).
const LAYOUT := {
	"castle": Rect2(512, 173, 230, 187),
	"tower": Rect2(138, 206, 120, 190),
	"blacksmith": Rect2(320, 360, 141, 108),
	"market": Rect2(819, 317, 154, 115),
	"arena": Rect2(1024, 216, 166, 130),
	"training": Rect2(602, 410, 154, 94),
}

var buildings: Dictionary = {}  ## building_id -> Building
var stage: Control
var _background: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background = ArtLoader.texture_or_null(BACKGROUND_PATH)
	resized.connect(queue_redraw)
	stage = Control.new()
	stage.name = "Stage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.set_anchors_preset(Control.PRESET_CENTER)
	stage.offset_left = -STAGE_SIZE.x / 2.0
	stage.offset_top = -STAGE_SIZE.y / 2.0
	stage.offset_right = STAGE_SIZE.x / 2.0
	stage.offset_bottom = STAGE_SIZE.y / 2.0
	add_child(stage)
	for building_id in LAYOUT:
		var building := Building.new()
		building.setup(building_id, Texts.BUILDINGS[building_id], LAYOUT[building_id])
		building.clicked.connect(_on_building_clicked.bind(building_id))
		stage.add_child(building)
		buildings[building_id] = building


func _on_building_clicked(building_id: String) -> void:
	building_clicked.emit(building_id, Texts.BUILDINGS[building_id])


func _draw() -> void:
	if _background != null:
		# Cobre a tela toda mantendo a proporção (corta as sobras).
		var factor := maxf(size.x / _background.get_width(), size.y / _background.get_height())
		var draw_size := _background.get_size() * factor
		draw_texture_rect(_background, Rect2((size - draw_size) / 2.0, draw_size), false)
		return
	var horizon_y := (size.y - STAGE_SIZE.y) / 2.0 + STAGE_SIZE.y * HORIZON
	draw_rect(Rect2(0, 0, size.x, horizon_y), SKY)
	draw_rect(Rect2(0, horizon_y, size.x, size.y - horizon_y), GRASS)
```

- [ ] **Step 5: Implementar `ui/hud/toast.gd`**

```gdscript
class_name Toast
extends PanelContainer
## Aviso curto no topo da tela (ex.: "Torre — em breve"). Some sozinho.

const DURATION := 2.0

var label: Label
var hide_timer: Timer


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Já dentro da árvore, set_anchors_preset recalcula os offsets: redefina os quatro.
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_left = 0
	offset_right = 0
	offset_top = 96
	offset_bottom = 96
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	hide_timer = Timer.new()
	hide_timer.one_shot = true
	hide_timer.timeout.connect(hide)
	add_child(hide_timer)


func show_message(text: String) -> void:
	label.text = text
	visible = true
	hide_timer.start(DURATION)
```

- [ ] **Step 6: Criar `ui/main.gd`**

```gdscript
extends Node
## Cena principal: liga a cidade, o HUD e as janelas entre si.

@onready var city: CityScreen = $CityScreen
@onready var toast: Toast = $HUDLayer/HUD/Toast


func _enter_tree() -> void:
	# CanvasLayer não repassa tema: aplica em cada Control raiz.
	var theme := GameTheme.get_theme()
	for path in ["CityScreen", "HUDLayer/HUD"]:
		(get_node(path) as Control).theme = theme


func _ready() -> void:
	city.building_clicked.connect(_on_building_clicked)


func _on_building_clicked(_building_id: String, display_name: String) -> void:
	_show_coming_soon(display_name)


func _show_coming_soon(display_name: String) -> void:
	toast.show_message(Texts.coming_soon(display_name))
```

- [ ] **Step 7: Criar `ui/main.tscn`**

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://ui/main.gd" id="1_main"]
[ext_resource type="Script" path="res://ui/city/city_screen.gd" id="2_city"]
[ext_resource type="Script" path="res://ui/hud/toast.gd" id="3_toast"]

[node name="Main" type="Node"]
script = ExtResource("1_main")

[node name="CityScreen" type="Control" parent="."]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("2_city")

[node name="HUDLayer" type="CanvasLayer" parent="."]
layer = 1

[node name="HUD" type="Control" parent="HUDLayer"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="Toast" type="PanelContainer" parent="HUDLayer/HUD"]
layout_mode = 1
script = ExtResource("3_toast")

[node name="WindowLayer" type="CanvasLayer" parent="."]
layer = 2
```

- [ ] **Step 8: Definir a cena principal em `project.godot`**

Na seção `[application]`, abaixo de `config/name=...`, adicione:
```ini
run/main_scene="res://ui/main.tscn"
```

- [ ] **Step 9: Rodar e confirmar que passa**

Run: `bash run_tests.sh`
Expected: todas `ok`, `57 testes, 0 falhas`.

- [ ] **Step 10: Commit**

```bash
git add ui/ project.godot tests/
git commit -m "feat: tela da cidade com construções clicáveis e aviso" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: HUD (retrato, herói, moedas, chat)

**Files:**
- Create: `ui/common/icon_view.gd`
- Create: `ui/hud/portrait.gd`
- Create: `ui/hud/hero_hud.gd`
- Create: `ui/hud/currency_hud.gd`
- Create: `ui/hud/chat_box.gd`
- Modify: `ui/main.tscn` (substituir inteiro, ver Step 8)
- Modify: `ui/main.gd` (substituir inteiro, ver Step 9)
- Test: `tests/test_hud.gd`

**Interfaces:**
- Consumes: `GameState` (Task 4); `FixedHeroRepository.aldric`, `FailingHeroRepository`, `BaseTest.use_repository` (Task 4); `Texts`, `ArtLoader`, `GameTheme` (Task 5); `StatFormulas` (Task 2)
- Produces:
  - `IconView extends Control`: `setup(path: String, placeholder_color: Color, letter: String, icon_size: Vector2) -> IconView`, `has_art() -> bool`
  - `Portrait extends Control`: `var initial: String`, `set_hero(hero: Hero) -> void`, `clear() -> void`, `has_art() -> bool`
  - `HeroHud extends PanelContainer`: `portrait`, `name_label`, `level_label`, `hp_bar`, `xp_bar`, `error_label`
  - `CurrencyHud extends HBoxContainer`: `gold_label`, `gems_label`
  - `ChatBox extends PanelContainer`: `log_label`
  - `main.gd` expõe também `hero_hud`, `currency_hud`, `chat_box`

- [ ] **Step 1: Escrever o teste que falha**

`tests/test_hud.gd`:
```gdscript
extends BaseTest
## HUD: herói, moedas, chat e o estado de erro.

var main: Node


func before_each() -> void:
	main = add_to_tree(load("res://ui/main.tscn").instantiate())
	await tree.process_frame


func test_hero_hud_shows_sample_hero() -> void:
	var hud: HeroHud = main.hero_hud
	assert_eq(hud.name_label.text, "Aldric")
	assert_eq(hud.level_label.text, "Nv 1")
	assert_eq(hud.hp_bar.max_value, 240.0)
	assert_eq(hud.hp_bar.value, 240.0)
	assert_eq(hud.xp_bar.max_value, 100.0)
	assert_eq(hud.xp_bar.value, 35.0)
	assert_eq(hud.portrait.initial, "A")
	assert_false(hud.error_label.visible)


func test_currency_hud_formats_values() -> void:
	assert_eq(main.currency_hud.gold_label.text, "1.250")
	assert_eq(main.currency_hud.gems_label.text, "20")


func test_currency_hud_large_values() -> void:
	use_repository(FixedHeroRepository.aldric(1, "Aldric", 1234567))
	assert_eq(main.currency_hud.gold_label.text, "1.234.567")


func test_chat_box_shows_welcome() -> void:
	assert_true(main.chat_box.log_label.text.contains("Bem-vindo a Eldoria!"))


func test_load_failure_shows_error_and_hides_currencies() -> void:
	use_repository(FailingHeroRepository.new())
	assert_true(main.hero_hud.error_label.visible)
	assert_eq(main.hero_hud.error_label.text, Texts.LOAD_ERROR)
	assert_false(main.currency_hud.visible)
	assert_eq(main.hero_hud.portrait.initial, "?")


func test_hud_recovers_when_player_loads_again() -> void:
	use_repository(FailingHeroRepository.new())
	use_repository(FixedHeroRepository.aldric(5))
	assert_false(main.hero_hud.error_label.visible)
	assert_true(main.currency_hud.visible)
	assert_eq(main.hero_hud.level_label.text, "Nv 5")


func test_long_name_does_not_stretch_hud() -> void:
	use_repository(FixedHeroRepository.aldric(1, "Bartholomew Maximilian Von Eldoria"))
	await tree.process_frame
	assert_eq(main.hero_hud.name_label.text, "Bartholomew Maximilian Von Eldoria")
	assert_true(main.hero_hud.get_combined_minimum_size().x < 400.0,
		"largura mínima do HUD: %s" % main.hero_hud.get_combined_minimum_size().x)


func test_chat_box_does_not_block_clicks() -> void:
	assert_eq(main.chat_box.mouse_filter, Control.MOUSE_FILTER_IGNORE)
```

- [ ] **Step 2: Rodar e confirmar que falha**

Run: `bash run_tests.sh --only=hud`
Expected: `FALHOU` em todos os testes de `test_hud.gd` (`main.hero_hud` não existe), código 1.

- [ ] **Step 3: Implementar `ui/common/icon_view.gd`**

```gdscript
class_name IconView
extends Control
## Ícone de assets/ se existir; senão, um círculo colorido com uma letra.

var _texture: Texture2D
var _color: Color
var _letter: String


func setup(path: String, placeholder_color: Color, letter: String, icon_size: Vector2) -> IconView:
	_texture = ArtLoader.texture_or_null(path)
	_color = placeholder_color
	_letter = letter
	custom_minimum_size = icon_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self


func has_art() -> bool:
	return _texture != null


func _draw() -> void:
	if _texture != null:
		draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false)
		return
	var radius := minf(size.x, size.y) / 2.0
	draw_circle(size / 2.0, radius, _color)
	var font := get_theme_default_font()
	var font_size := int(radius)
	var text_size := font.get_string_size(_letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := Vector2((size.x - text_size.x) / 2.0,
		(size.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0)
	draw_string(font, baseline, _letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
```

- [ ] **Step 4: Implementar `ui/hud/portrait.gd`**

```gdscript
class_name Portrait
extends Control
## Retrato redondo do herói. Usa assets/portraits/<classe>_face.png se existir
## (recortado em círculo); senão, um círculo com a inicial do nome.

const FILL := Color("#7a5230")
const SEGMENTS := 48

var initial := "?"
var _texture: Texture2D


func set_hero(hero: Hero) -> void:
	_texture = ArtLoader.texture_or_null("res://assets/portraits/%s_face.png" % hero.hero_class)
	initial = hero.hero_name.left(1).to_upper()
	queue_redraw()


func clear() -> void:
	_texture = null
	initial = "?"
	queue_redraw()


func has_art() -> bool:
	return _texture != null


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in SEGMENTS:
		var angle := TAU * i / SEGMENTS
		var point := center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
		uvs.append(point / size)
	if _texture != null:
		draw_colored_polygon(points, Color.WHITE, uvs, _texture)
	else:
		draw_colored_polygon(points, FILL)
		_draw_initial(center, radius)
	draw_circle(center, radius - 1.0, GameTheme.GOLD_LIGHT, false, 2.0)


func _draw_initial(center: Vector2, radius: float) -> void:
	var font := get_theme_default_font()
	var font_size := int(radius)
	var text_size := font.get_string_size(initial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := center + Vector2(-text_size.x / 2.0,
		(font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0)
	draw_string(font, baseline, initial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
```

- [ ] **Step 5: Implementar `ui/hud/hero_hud.gd`**

```gdscript
class_name HeroHud
extends PanelContainer
## Canto superior esquerdo: retrato, nome, nível e barras de HP/XP do herói.

const BAR_WIDTH := 150.0
const NAME_WIDTH := 100.0

var portrait: Portrait
var name_label: Label
var level_label: Label
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var error_label: Label
var _info: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(16, 16)
	_build()
	GameState.player_changed.connect(_on_player_changed)
	GameState.load_failed.connect(_on_load_failed)
	_render()


func _build() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	portrait = Portrait.new()
	portrait.custom_minimum_size = Vector2(56, 56)
	row.add_child(portrait)
	_info = VBoxContainer.new()
	_info.add_theme_constant_override("separation", 3)
	row.add_child(_info)
	var title := HBoxContainer.new()
	_info.add_child(title)
	name_label = Label.new()
	name_label.custom_minimum_size.x = NAME_WIDTH
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_child(name_label)
	level_label = Label.new()
	level_label.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	title.add_child(level_label)
	hp_bar = GameTheme.make_bar(GameTheme.HP_RED, BAR_WIDTH)
	_info.add_child(hp_bar)
	xp_bar = GameTheme.make_bar(GameTheme.GOLD, BAR_WIDTH)
	_info.add_child(xp_bar)
	error_label = Label.new()
	error_label.text = Texts.LOAD_ERROR
	row.add_child(error_label)


func _on_player_changed(_player: Player) -> void:
	_render()


func _on_load_failed(_error: String) -> void:
	_render()


func _render() -> void:
	var player: Player = GameState.player
	_info.visible = player != null
	error_label.visible = player == null
	if player == null:
		portrait.clear()
		return
	var hero := player.hero
	portrait.set_hero(hero)
	name_label.text = hero.hero_name
	level_label.text = Texts.short_level(hero.level)
	hp_bar.max_value = StatFormulas.max_hp(hero)
	hp_bar.value = hero.current_hp
	xp_bar.max_value = StatFormulas.xp_to_next_level(hero.level)
	xp_bar.value = hero.xp
```

- [ ] **Step 6: Implementar `ui/hud/currency_hud.gd`**

```gdscript
class_name CurrencyHud
extends HBoxContainer
## Canto superior direito: ouro e gemas do jogador.

const GOLD_COLOR := Color("#d4a017")
const GEMS_COLOR := Color("#3aa0d8")

var gold_label: Label
var gems_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_left = -16
	offset_right = -16
	offset_top = 16
	offset_bottom = 16
	add_theme_constant_override("separation", 8)
	gold_label = _add_pill("res://assets/icons/gold.png", GOLD_COLOR, "O")
	gems_label = _add_pill("res://assets/icons/gems.png", GEMS_COLOR, "G")
	GameState.player_changed.connect(_on_player_changed)
	GameState.load_failed.connect(_on_load_failed)
	_render()


func _add_pill(icon_path: String, color: Color, letter: String) -> Label:
	var pill := PanelContainer.new()
	add_child(pill)
	var row := HBoxContainer.new()
	pill.add_child(row)
	row.add_child(IconView.new().setup(icon_path, color, letter, Vector2(24, 24)))
	var label := Label.new()
	row.add_child(label)
	return label


func _on_player_changed(_player: Player) -> void:
	_render()


func _on_load_failed(_error: String) -> void:
	_render()


func _render() -> void:
	var player: Player = GameState.player
	visible = player != null
	if player == null:
		return
	gold_label.text = Texts.thousands(player.gold)
	gems_label.text = Texts.thousands(player.gems)
```

- [ ] **Step 7: Implementar `ui/hud/chat_box.gd`**

```gdscript
class_name ChatBox
extends PanelContainer
## Caixa de chat do canto inferior esquerdo. Só visual no MVP (não bloqueia cliques).

const BOX_SIZE := Vector2(420, 140)

var log_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	offset_left = 16
	offset_right = 16 + BOX_SIZE.x
	offset_top = -16 - BOX_SIZE.y
	offset_bottom = -16
	add_theme_stylebox_override("panel", GameTheme.box(Color(0, 0, 0, 0.45), Color.TRANSPARENT, 0, 4))
	log_label = Label.new()
	log_label.text = Texts.CHAT_TEXT
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_label.add_theme_font_size_override("font_size", 13)
	add_child(log_label)
```

- [ ] **Step 8: Substituir `ui/main.tscn` inteiro**

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://ui/main.gd" id="1_main"]
[ext_resource type="Script" path="res://ui/city/city_screen.gd" id="2_city"]
[ext_resource type="Script" path="res://ui/hud/toast.gd" id="3_toast"]
[ext_resource type="Script" path="res://ui/hud/hero_hud.gd" id="4_hero_hud"]
[ext_resource type="Script" path="res://ui/hud/currency_hud.gd" id="5_currency_hud"]
[ext_resource type="Script" path="res://ui/hud/chat_box.gd" id="6_chat_box"]

[node name="Main" type="Node"]
script = ExtResource("1_main")

[node name="CityScreen" type="Control" parent="."]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("2_city")

[node name="HUDLayer" type="CanvasLayer" parent="."]
layer = 1

[node name="HUD" type="Control" parent="HUDLayer"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="HeroHud" type="PanelContainer" parent="HUDLayer/HUD"]
layout_mode = 1
script = ExtResource("4_hero_hud")

[node name="CurrencyHud" type="HBoxContainer" parent="HUDLayer/HUD"]
layout_mode = 1
script = ExtResource("5_currency_hud")

[node name="ChatBox" type="PanelContainer" parent="HUDLayer/HUD"]
layout_mode = 1
script = ExtResource("6_chat_box")

[node name="Toast" type="PanelContainer" parent="HUDLayer/HUD"]
layout_mode = 1
script = ExtResource("3_toast")

[node name="WindowLayer" type="CanvasLayer" parent="."]
layer = 2
```

- [ ] **Step 9: Substituir `ui/main.gd` inteiro**

```gdscript
extends Node
## Cena principal: liga a cidade, o HUD e as janelas entre si.

@onready var city: CityScreen = $CityScreen
@onready var hero_hud: HeroHud = $HUDLayer/HUD/HeroHud
@onready var currency_hud: CurrencyHud = $HUDLayer/HUD/CurrencyHud
@onready var chat_box: ChatBox = $HUDLayer/HUD/ChatBox
@onready var toast: Toast = $HUDLayer/HUD/Toast


func _enter_tree() -> void:
	# CanvasLayer não repassa tema: aplica em cada Control raiz.
	var theme := GameTheme.get_theme()
	for path in ["CityScreen", "HUDLayer/HUD"]:
		(get_node(path) as Control).theme = theme


func _ready() -> void:
	city.building_clicked.connect(_on_building_clicked)


func _on_building_clicked(_building_id: String, display_name: String) -> void:
	_show_coming_soon(display_name)


func _show_coming_soon(display_name: String) -> void:
	toast.show_message(Texts.coming_soon(display_name))
```

- [ ] **Step 10: Rodar e confirmar que passa**

Run: `bash run_tests.sh`
Expected: todas `ok`, `65 testes, 0 falhas`.

- [ ] **Step 11: Commit**

```bash
git add ui/ tests/
git commit -m "feat: HUD do herói, moedas e chat visual" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Barra de menu + painel do personagem

**Files:**
- Create: `ui/bottom_bar/bottom_bar.gd`
- Create: `ui/character_panel/character_panel.gd`
- Modify: `ui/main.tscn` (substituir inteiro, ver Step 6)
- Modify: `ui/main.gd` (substituir inteiro, ver Step 7)
- Test: `tests/test_character_panel.gd`
- Test: `tests/test_layout.gd`

**Interfaces:**
- Consumes: `GameState`, `FixedHeroRepository.aldric`, `FailingHeroRepository`, `BaseTest.use_repository`, `BaseTest.press_key`, `BaseTest.left_click` (Tasks 1 e 4); `Texts`, `ArtLoader`, `GameTheme` (Task 5); `IconView` (Task 7); `StatFormulas`, `Attributes.NAMES` (Task 2)
- Produces:
  - `BottomBar extends HBoxContainer`: `signal character_pressed`, `signal unavailable_pressed(display_name: String)`, `const BUTTON_IDS: Array[String]`, `var buttons: Dictionary` (id → `Button`)
  - `CharacterPanel extends Control`: `open()`, `close()`, `is_open() -> bool`, `dim: ColorRect`, `window: PanelContainer`, `close_button: Button`, `name_label`, `class_level_label`, `hp_label`, `xp_label`, `hp_bar`, `xp_bar`, `value_labels: Dictionary` (chaves: `strength, agility, intelligence, vitality, attack, defense, crit_chance, speed`), `slots: Dictionary` (8 ids de `Texts.SLOTS`)
  - `main.gd` expõe também `bottom_bar`, `character_panel`

- [ ] **Step 1: Escrever os testes que falham**

`tests/test_character_panel.gd`:
```gdscript
extends BaseTest
## Barra de menu + painel do personagem (spec, seção 5).

var main: Node
var panel: CharacterPanel
var bar: BottomBar


func before_each() -> void:
	main = add_to_tree(load("res://ui/main.tscn").instantiate())
	await tree.process_frame
	panel = main.character_panel
	bar = main.bottom_bar


func _open_with_button() -> void:
	bar.buttons["character"].pressed.emit()


func test_panel_starts_closed() -> void:
	assert_false(panel.is_open())


func test_bar_has_six_buttons_in_order() -> void:
	assert_eq(bar.buttons.keys(), ["character", "bag", "skills", "quests", "guild", "settings"])


func test_character_button_opens_panel_with_aldric_stats() -> void:
	_open_with_button()
	assert_true(panel.is_open())
	assert_eq(panel.name_label.text, "Aldric")
	assert_eq(panel.class_level_label.text, "Mago · Nível 1")
	assert_eq(panel.hp_label.text, "240 / 240")
	assert_eq(panel.xp_label.text, "35 / 100")
	assert_eq(panel.xp_bar.value, 35.0)
	assert_eq(panel.value_labels["strength"].text, "5")
	assert_eq(panel.value_labels["agility"].text, "8")
	assert_eq(panel.value_labels["intelligence"].text, "14")
	assert_eq(panel.value_labels["vitality"].text, "12")
	assert_eq(panel.value_labels["attack"].text, "29")
	assert_eq(panel.value_labels["defense"].text, "17")
	assert_eq(panel.value_labels["crit_chance"].text, "4%")
	assert_eq(panel.value_labels["speed"].text, "108")


func test_eight_empty_equipment_slots() -> void:
	assert_eq(panel.slots.keys(), ["helmet", "armor", "boots", "necklace", "ring", "cape", "weapon", "shield"])


func test_escape_closes_panel() -> void:
	_open_with_button()
	await press_key(KEY_ESCAPE)
	assert_false(panel.is_open())


func test_escape_with_panel_closed_does_nothing() -> void:
	await press_key(KEY_ESCAPE)
	assert_false(panel.is_open())


func test_close_button_closes_panel() -> void:
	_open_with_button()
	panel.close_button.pressed.emit()
	assert_false(panel.is_open())


func test_click_on_dim_background_closes_panel() -> void:
	_open_with_button()
	panel.dim.gui_input.emit(left_click())
	assert_false(panel.is_open())


func test_dim_blocks_clicks_to_city() -> void:
	assert_eq(panel.dim.mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_eq(panel.dim.anchor_right, 1.0)
	assert_eq(panel.dim.anchor_bottom, 1.0)


func test_open_twice_keeps_panel_open() -> void:
	_open_with_button()
	panel.open()
	assert_true(panel.is_open())


func test_unavailable_buttons_show_coming_soon() -> void:
	bar.buttons["bag"].pressed.emit()
	assert_eq(main.toast.label.text, "Mochila — em breve")
	assert_false(panel.is_open())


func test_unavailable_buttons_look_faded_but_clickable() -> void:
	for id in ["bag", "skills", "quests", "guild", "settings"]:
		var button: Button = bar.buttons[id]
		assert_false(button.disabled, id)
		assert_true(button.modulate.a < 1.0, id)


func test_panel_refreshes_when_player_changes() -> void:
	_open_with_button()
	use_repository(FixedHeroRepository.aldric(5))
	assert_eq(panel.class_level_label.text, "Mago · Nível 5")
	assert_eq(panel.value_labels["attack"].text, "33")
	assert_eq(panel.hp_label.text, "240 / 320")
	assert_eq(panel.xp_label.text, "35 / 1118")


func test_load_failure_disables_character_button_and_closes_panel() -> void:
	_open_with_button()
	use_repository(FailingHeroRepository.new())
	assert_false(panel.is_open())
	assert_true(bar.buttons["character"].disabled)
	panel.open()
	assert_false(panel.is_open(), "não deve abrir sem jogador")


func test_character_button_enabled_again_after_recovery() -> void:
	use_repository(FailingHeroRepository.new())
	use_repository(FixedHeroRepository.aldric())
	assert_false(bar.buttons["character"].disabled)
```

`tests/test_layout.gd`:
```gdscript
extends BaseTest
## Telas maiores/ultrawide: HUD preso aos cantos, cidade e janela centralizadas.

var main: Node


func before_each() -> void:
	main = add_to_tree(load("res://ui/main.tscn").instantiate())
	await tree.process_frame


func test_bottom_bar_anchored_bottom_right() -> void:
	var bar: BottomBar = main.bottom_bar
	assert_eq(bar.anchor_left, 1.0)
	assert_eq(bar.anchor_top, 1.0)
	assert_eq(bar.grow_horizontal, Control.GROW_DIRECTION_BEGIN)
	assert_eq(bar.grow_vertical, Control.GROW_DIRECTION_BEGIN)


func test_currency_anchored_top_right() -> void:
	assert_eq(main.currency_hud.anchor_left, 1.0)
	assert_eq(main.currency_hud.anchor_top, 0.0)


func test_chat_anchored_bottom_left() -> void:
	assert_eq(main.chat_box.anchor_left, 0.0)
	assert_eq(main.chat_box.anchor_top, 1.0)


func test_hero_hud_anchored_top_left() -> void:
	assert_eq(main.hero_hud.anchor_left, 0.0)
	assert_eq(main.hero_hud.anchor_top, 0.0)


func test_city_stage_centered() -> void:
	var stage: Control = main.city.stage
	assert_eq(stage.anchor_left, 0.5)
	assert_eq(stage.anchor_top, 0.5)
	assert_eq(stage.offset_left, -640.0)
	assert_eq(stage.offset_top, -360.0)


func test_panel_window_centered() -> void:
	var window: PanelContainer = main.character_panel.window
	assert_eq(window.anchor_left, 0.5)
	assert_eq(window.anchor_top, 0.5)
```

- [ ] **Step 2: Rodar e confirmar que falha**

Run: `bash run_tests.sh`
Expected: os testes anteriores continuam `ok`; `FALHOU` nos testes de `test_character_panel.gd` e `test_layout.gd` (`main.character_panel`/`main.bottom_bar` não existem), código 1.

- [ ] **Step 3: Implementar `ui/bottom_bar/bottom_bar.gd`**

```gdscript
class_name BottomBar
extends HBoxContainer
## Barra de menu do canto inferior direito. Só "Personagem" funciona no MVP;
## os outros botões ficam esmaecidos e avisam "em breve".

signal character_pressed
signal unavailable_pressed(display_name: String)

const BUTTON_IDS: Array[String] = ["character", "bag", "skills", "quests", "guild", "settings"]
const BUTTON_SIZE := Vector2(76, 76)
const ICON_SIZE := Vector2(36, 36)
const ICON_COLOR := Color("#7a5230")
const UNAVAILABLE_ALPHA := 0.45

var buttons: Dictionary = {}  ## id -> Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = -16
	offset_right = -16
	offset_top = -16
	offset_bottom = -16
	add_theme_constant_override("separation", 6)
	for id in BUTTON_IDS:
		var button := _make_button(id)
		buttons[id] = button
		add_child(button)
	GameState.player_changed.connect(_on_player_changed)
	GameState.load_failed.connect(_on_load_failed)
	_refresh_character_button()


func _make_button(id: String) -> Button:
	var display_name: String = Texts.MENU[id]
	var button := Button.new()
	button.custom_minimum_size = BUTTON_SIZE
	button.tooltip_text = display_name
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)
	var icon := IconView.new().setup("res://assets/icons/%s.png" % id, ICON_COLOR, display_name.left(1), ICON_SIZE)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(icon)
	var caption := Label.new()
	caption.text = display_name
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_theme_font_size_override("font_size", 11)
	content.add_child(caption)
	if id == "character":
		button.pressed.connect(_on_character_pressed)
	else:
		button.modulate.a = UNAVAILABLE_ALPHA
		button.pressed.connect(_on_unavailable_pressed.bind(display_name))
	return button


func _on_character_pressed() -> void:
	character_pressed.emit()


func _on_unavailable_pressed(display_name: String) -> void:
	unavailable_pressed.emit(display_name)


func _on_player_changed(_player: Player) -> void:
	_refresh_character_button()


func _on_load_failed(_error: String) -> void:
	_refresh_character_button()


func _refresh_character_button() -> void:
	buttons["character"].disabled = not GameState.has_player()
```

- [ ] **Step 4: Implementar `ui/character_panel/character_panel.gd`**

```gdscript
class_name CharacterPanel
extends Control
## Janela "Personagem" (layout A da spec): herói e 8 slots à esquerda;
## HP/XP, atributos e combate à direita. Só exibe dados do GameState.
## Fecha no X, com Esc ou com clique no fundo escurecido.

const WINDOW_SIZE := Vector2(900, 560)
const SLOT_SIZE := Vector2(64, 64)
const FIGURE_SIZE := Vector2(140, 230)
const FIGURE_CENTER := Vector2(0.5, 0.52)
const FIGURE_FILL := Color("#7a5230")
const SLOT_TEXT := Color("#b99c5e")
const INNER_BORDER := Color("#6b5020")
const SLOT_ART_PATH := "res://assets/ui/slot_empty.png"
## Centro de cada slot, em fração da área do retrato.
const SLOT_ANCHORS := {
	"helmet": Vector2(0.14, 0.30),
	"armor": Vector2(0.14, 0.52),
	"boots": Vector2(0.14, 0.74),
	"necklace": Vector2(0.86, 0.30),
	"ring": Vector2(0.86, 0.52),
	"cape": Vector2(0.86, 0.74),
	"weapon": Vector2(0.36, 0.90),
	"shield": Vector2(0.64, 0.90),
}

var dim: ColorRect
var window: PanelContainer
var close_button: Button
var name_label: Label
var class_level_label: Label
var hp_label: Label
var xp_label: Label
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var value_labels: Dictionary = {}  ## strength..speed -> Label
var slots: Dictionary = {}  ## helmet..shield -> Panel
var _figure_art: TextureRect
var _figure_placeholder: Panel


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	GameState.player_changed.connect(_on_player_changed)
	GameState.load_failed.connect(_on_load_failed)


func open() -> void:
	if not GameState.has_player():
		return
	_render()
	visible = true


func close() -> void:
	visible = false


func is_open() -> bool:
	return visible


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()


func _on_player_changed(_player: Player) -> void:
	_render()


func _on_load_failed(_error: String) -> void:
	close()


func _render() -> void:
	var player: Player = GameState.player
	if player == null:
		return
	var hero := player.hero
	name_label.text = hero.hero_name
	class_level_label.text = Texts.class_and_level(hero.hero_class, hero.level)
	var max_hp := StatFormulas.max_hp(hero)
	hp_label.text = Texts.fraction(hero.current_hp, max_hp)
	hp_bar.max_value = max_hp
	hp_bar.value = hero.current_hp
	var xp_next := StatFormulas.xp_to_next_level(hero.level)
	xp_label.text = Texts.fraction(hero.xp, xp_next)
	xp_bar.max_value = xp_next
	xp_bar.value = hero.xp
	for attribute in Attributes.NAMES:
		value_labels[attribute].text = str(hero.attributes.get_value(attribute))
	value_labels["attack"].text = str(StatFormulas.attack(hero))
	value_labels["defense"].text = str(StatFormulas.defense(hero))
	value_labels["crit_chance"].text = Texts.percent(StatFormulas.crit_chance(hero))
	value_labels["speed"].text = str(StatFormulas.speed(hero))
	var figure := ArtLoader.texture_or_null("res://assets/portraits/%s_full.png" % hero.hero_class)
	_figure_art.texture = figure
	_figure_art.visible = figure != null
	_figure_placeholder.visible = figure == null


func _build() -> void:
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_gui_input)
	add_child(dim)
	window = PanelContainer.new()
	window.set_anchors_preset(Control.PRESET_CENTER)
	window.offset_left = -WINDOW_SIZE.x / 2.0
	window.offset_right = WINDOW_SIZE.x / 2.0
	window.offset_top = -WINDOW_SIZE.y / 2.0
	window.offset_bottom = WINDOW_SIZE.y / 2.0
	add_child(window)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	window.add_child(layout)
	layout.add_child(_build_title_bar())
	layout.add_child(HSeparator.new())
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	layout.add_child(body)
	body.add_child(_build_paperdoll())
	body.add_child(_build_stats())


func _build_title_bar() -> Control:
	var bar := HBoxContainer.new()
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(36, 0)
	bar.add_child(spacer)
	var title := Label.new()
	title.text = Texts.PANEL_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	bar.add_child(title)
	close_button = Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(36, 36)
	close_button.pressed.connect(close)
	bar.add_child(close_button)
	return bar


func _build_paperdoll() -> Control:
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_stretch_ratio = 1.1
	frame.add_theme_stylebox_override("panel", _inner_box())
	var area := Control.new()
	frame.add_child(area)
	var header := VBoxContainer.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	area.add_child(header)
	name_label = _centered_label(20)
	header.add_child(name_label)
	class_level_label = _centered_label(15)
	class_level_label.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
	header.add_child(class_level_label)
	_figure_placeholder = Panel.new()
	var figure_style := GameTheme.box(FIGURE_FILL, GameTheme.GOLD_LIGHT, 2, 12)
	figure_style.corner_radius_top_left = 60
	figure_style.corner_radius_top_right = 60
	_figure_placeholder.add_theme_stylebox_override("panel", figure_style)
	_place(area, _figure_placeholder, FIGURE_CENTER, FIGURE_SIZE)
	_figure_art = TextureRect.new()
	_figure_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_figure_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_figure_art.visible = false
	_place(area, _figure_art, FIGURE_CENTER, FIGURE_SIZE * 1.3)
	for slot_id in SLOT_ANCHORS:
		var slot := _make_slot(Texts.SLOTS[slot_id])
		_place(area, slot, SLOT_ANCHORS[slot_id], SLOT_SIZE)
		slots[slot_id] = slot
	return frame


func _build_stats() -> Control:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	var vitals := _section(column, "")
	hp_label = _add_row(vitals, Texts.HP)
	hp_bar = GameTheme.make_bar(GameTheme.HP_RED, 0.0)
	vitals.add_child(hp_bar)
	xp_label = _add_row(vitals, Texts.XP)
	xp_bar = GameTheme.make_bar(GameTheme.GOLD, 0.0)
	vitals.add_child(xp_bar)
	var attributes := _section(column, Texts.SECTION_ATTRIBUTES)
	for key in Texts.ATTRIBUTES:
		value_labels[key] = _add_row(attributes, Texts.ATTRIBUTES[key])
	var combat := _section(column, Texts.SECTION_COMBAT)
	for key in Texts.COMBAT_STATS:
		value_labels[key] = _add_row(combat, Texts.COMBAT_STATS[key])
	return column


## Bloco com fundo escuro (e título, se houver). Devolve a coluna interna.
func _section(parent: Control, title: String) -> VBoxContainer:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _inner_box())
	parent.add_child(box)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 2)
	box.add_child(inner)
	if title != "":
		var heading := Label.new()
		heading.text = title.to_upper()
		heading.add_theme_font_size_override("font_size", 13)
		heading.add_theme_color_override("font_color", GameTheme.GOLD_LIGHT)
		inner.add_child(heading)
	return inner


## Linha "Nome ........ valor". Devolve o Label do valor.
func _add_row(parent: Control, caption: String) -> Label:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var caption_label := Label.new()
	caption_label.text = caption
	caption_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(caption_label)
	var value := Label.new()
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(value)
	return value


func _make_slot(caption: String) -> Panel:
	var slot := Panel.new()
	var art := ArtLoader.texture_or_null(SLOT_ART_PATH)
	if art != null:
		var style := StyleBoxTexture.new()
		style.texture = art
		slot.add_theme_stylebox_override("panel", style)
	else:
		slot.add_theme_stylebox_override("panel", GameTheme.box(Color(0, 0, 0, 0.35), GameTheme.GOLD.darkened(0.2), 1, 4))
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", SLOT_TEXT)
	slot.add_child(label)
	return slot


## Coloca `child` centralizado no ponto `anchor` (fração do tamanho de `parent`).
func _place(parent: Control, child: Control, anchor: Vector2, child_size: Vector2) -> void:
	child.anchor_left = anchor.x
	child.anchor_right = anchor.x
	child.anchor_top = anchor.y
	child.anchor_bottom = anchor.y
	child.offset_left = -child_size.x / 2.0
	child.offset_right = child_size.x / 2.0
	child.offset_top = -child_size.y / 2.0
	child.offset_bottom = child_size.y / 2.0
	parent.add_child(child)


func _centered_label(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _inner_box() -> StyleBoxFlat:
	return GameTheme.box(Color(0, 0, 0, 0.25), INNER_BORDER, 1, 4)
```

- [ ] **Step 5: Conferir o nome do slot do Mago**

Não mude nada: a spec mantém "Escudo" como 8º slot. Anote na descrição do commit que o nome pode mudar quando a classe for definida.

- [ ] **Step 6: Substituir `ui/main.tscn` inteiro**

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://ui/main.gd" id="1_main"]
[ext_resource type="Script" path="res://ui/city/city_screen.gd" id="2_city"]
[ext_resource type="Script" path="res://ui/hud/toast.gd" id="3_toast"]
[ext_resource type="Script" path="res://ui/hud/hero_hud.gd" id="4_hero_hud"]
[ext_resource type="Script" path="res://ui/hud/currency_hud.gd" id="5_currency_hud"]
[ext_resource type="Script" path="res://ui/hud/chat_box.gd" id="6_chat_box"]
[ext_resource type="Script" path="res://ui/bottom_bar/bottom_bar.gd" id="7_bottom_bar"]
[ext_resource type="Script" path="res://ui/character_panel/character_panel.gd" id="8_character_panel"]

[node name="Main" type="Node"]
script = ExtResource("1_main")

[node name="CityScreen" type="Control" parent="."]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("2_city")

[node name="HUDLayer" type="CanvasLayer" parent="."]
layer = 1

[node name="HUD" type="Control" parent="HUDLayer"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="HeroHud" type="PanelContainer" parent="HUDLayer/HUD"]
layout_mode = 1
script = ExtResource("4_hero_hud")

[node name="CurrencyHud" type="HBoxContainer" parent="HUDLayer/HUD"]
layout_mode = 1
script = ExtResource("5_currency_hud")

[node name="ChatBox" type="PanelContainer" parent="HUDLayer/HUD"]
layout_mode = 1
script = ExtResource("6_chat_box")

[node name="BottomBar" type="HBoxContainer" parent="HUDLayer/HUD"]
layout_mode = 1
script = ExtResource("7_bottom_bar")

[node name="Toast" type="PanelContainer" parent="HUDLayer/HUD"]
layout_mode = 1
script = ExtResource("3_toast")

[node name="WindowLayer" type="CanvasLayer" parent="."]
layer = 2

[node name="CharacterPanel" type="Control" parent="WindowLayer"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
script = ExtResource("8_character_panel")
```

- [ ] **Step 7: Substituir `ui/main.gd` inteiro**

```gdscript
extends Node
## Cena principal: liga a cidade, o HUD, a barra de menu e o painel entre si.

@onready var city: CityScreen = $CityScreen
@onready var hero_hud: HeroHud = $HUDLayer/HUD/HeroHud
@onready var currency_hud: CurrencyHud = $HUDLayer/HUD/CurrencyHud
@onready var chat_box: ChatBox = $HUDLayer/HUD/ChatBox
@onready var bottom_bar: BottomBar = $HUDLayer/HUD/BottomBar
@onready var toast: Toast = $HUDLayer/HUD/Toast
@onready var character_panel: CharacterPanel = $WindowLayer/CharacterPanel


func _enter_tree() -> void:
	# CanvasLayer não repassa tema: aplica em cada Control raiz.
	var theme := GameTheme.get_theme()
	for path in ["CityScreen", "HUDLayer/HUD", "WindowLayer/CharacterPanel"]:
		(get_node(path) as Control).theme = theme


func _ready() -> void:
	city.building_clicked.connect(_on_building_clicked)
	bottom_bar.character_pressed.connect(character_panel.open)
	bottom_bar.unavailable_pressed.connect(_show_coming_soon)


func _on_building_clicked(_building_id: String, display_name: String) -> void:
	_show_coming_soon(display_name)


func _show_coming_soon(display_name: String) -> void:
	toast.show_message(Texts.coming_soon(display_name))
```

- [ ] **Step 8: Rodar e confirmar que passa**

Run: `bash run_tests.sh`
Expected: todas `ok`, `86 testes, 0 falhas`.

- [ ] **Step 9: Commit**

```bash
git add ui/ tests/
git commit -m "feat: barra de menu e painel de status do personagem" -m "O 8º slot se chama Escudo como na spec; pode mudar quando a classe Mago for detalhada." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Lista de artes, captura de tela e verificação final

**Files:**
- Create: `assets/README.md`
- Create: `assets/city/.gitkeep`, `assets/icons/.gitkeep`, `assets/portraits/.gitkeep`, `assets/ui/.gitkeep`
- Create: `tools/screenshot.gd`

**Interfaces:**
- Consumes: `ui/main.tscn` com `character_panel` (Task 8)
- Produces: `screenshots/city.png` e `screenshots/character_panel.png` (ignorados pelo git)

- [ ] **Step 1: Criar as pastas de arte**

```bash
mkdir -p assets/city assets/icons assets/portraits assets/ui
touch assets/city/.gitkeep assets/icons/.gitkeep assets/portraits/.gitkeep assets/ui/.gitkeep
```

- [ ] **Step 2: Criar `assets/README.md`**

```markdown
# Arte do jogo

O jogo funciona sem nenhuma destas imagens: cada uma tem um placeholder desenhado.
Para usar arte de verdade, salve o PNG **com o nome exato** na pasta indicada e
abra o projeto no editor do Godot uma vez (ele importa o arquivo). Não precisa mexer em código.

Estilo de referência: fantasia medieval ilustrada, paleta quente de marrom e dourado, como no Legend Online.

| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `city/background.png` | 1280×720 | Fundo da cidade sem as construções |
| `city/castle.png` | até 230×187, fundo transparente | Castelo |
| `city/tower.png` | até 120×190, fundo transparente | Torre (futuro modo de andares) |
| `city/blacksmith.png` | até 141×108, fundo transparente | Ferreiro |
| `city/market.png` | até 154×115, fundo transparente | Mercado |
| `city/arena.png` | até 166×130, fundo transparente | Arena |
| `city/training.png` | até 154×94, fundo transparente | Campo de treino |
| `icons/character.png`, `bag.png`, `skills.png`, `quests.png`, `guild.png`, `settings.png` | 64×64, transparente | Ícones da barra de menu |
| `icons/gold.png`, `icons/gems.png` | 32×32, transparente | Moedas |
| `portraits/mage_face.png` | 128×128 | Rosto do Mago para o HUD (o jogo recorta em círculo) |
| `portraits/mage_full.png` | 300×450, transparente | Mago de corpo inteiro para o painel |
| `ui/panel_frame.png` | 96×96, 9-slice com bordas de 24 px | Moldura das janelas |
| `ui/slot_empty.png` | 64×64 | Slot de equipamento vazio |

Posição de cada construção no palco de 1280×720 (canto superior esquerdo x, y):
castelo (512, 173), torre (138, 206), ferreiro (320, 360), mercado (819, 317),
arena (1024, 216), treino (602, 410). A arte é encaixada na caixa mantendo a
proporção, alinhada embaixo e no centro.
```

- [ ] **Step 3: Criar `tools/screenshot.gd`**

```gdscript
extends SceneTree
## Tira prints da cidade e do painel aberto para conferência visual.
## Uso (precisa de janela; NÃO use --headless):
##   Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/screenshot.gd
## Saída: screenshots/city.png e screenshots/character_panel.png

const OUTPUT_DIR := "res://screenshots"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var main: Node = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	for _i in 10:
		await process_frame
	_save("city.png")
	main.character_panel.open()
	for _i in 5:
		await process_frame
	_save("character_panel.png")
	quit(0)


func _save(file_name: String) -> void:
	var image := root.get_texture().get_image()
	image.save_png(OUTPUT_DIR + "/" + file_name)
	print("salvo %s/%s (%dx%d)" % [OUTPUT_DIR, file_name, image.get_width(), image.get_height()])
```

- [ ] **Step 4: Rodar a suíte completa**

Run: `bash run_tests.sh; echo "exit=$?"`
Expected: `86 testes, 0 falhas` e `exit=0`.

- [ ] **Step 5: Tirar as capturas e conferir visualmente**

Run: `"Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe" --path . --script res://tools/screenshot.gd`
Expected: duas linhas `salvo res://screenshots/... (1280x720)`. Se o tamanho sair diferente, anote no relatório (não é falha).

Abra `screenshots/city.png` e confira:
- céu azul em cima, grama verde embaixo;
- 6 construções com nome (Castelo, Torre, Ferreiro, Mercado, Arena, Treino), com a Torre alta e estreita à esquerda;
- HUD no canto superior esquerdo com círculo "A", "Aldric", "Nv 1" e barras vermelha e dourada;
- "1.250" e "20" no canto superior direito;
- caixa de chat translúcida no canto inferior esquerdo;
- 6 botões no canto inferior direito, com "Personagem" mais forte que os outros.

Abra `screenshots/character_panel.png` e confira: fundo escurecido, janela marrom com borda dourada, título "Personagem", X, "Aldric" / "Mago · Nível 1", figura central com 8 slots rotulados ao redor, e à direita HP 240 / 240, XP 35 / 100, Atributos (5, 8, 14, 12) e Combate (29, 17, 4%, 108).

Se algo estiver sobreposto ou cortado, ajuste as constantes de layout do componente (`WINDOW_SIZE`, `SLOT_ANCHORS`, `BOX_SIZE` etc.), rode os testes de novo e tire novas capturas.

- [ ] **Step 6: Commit**

```bash
git add assets/ tools/
git commit -m "docs: lista de artes e ferramenta de captura de tela" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 7: Verificação manual (para o dono do projeto)**

Abra o jogo com duplo clique em `Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe`, importe a pasta do projeto e aperte F5. Ou, pelo terminal: `"Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe" --path .`
Confira: passar o mouse numa construção a ilumina e mostra a mão; clicar mostra "<Nome> — em breve"; "Personagem" abre o painel; Esc, X e clique fora fecham; os outros botões mostram "em breve"; maximizar a janela mantém o HUD nos cantos.

- [ ] **Step 8: Fechar o companheiro visual do brainstorming**

```bash
bash "C:/Users/andre/.claude/plugins/cache/claude-plugins-official/superpowers/6.4.1/skills/brainstorming/scripts/stop-server.sh" .superpowers/brainstorm/655-1790274051
```
