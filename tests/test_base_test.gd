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
