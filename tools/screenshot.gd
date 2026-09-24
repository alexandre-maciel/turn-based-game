extends SceneTree
## Tira prints da cidade, das janelas e do combate para conferência visual.
## Uso (precisa de janela; NÃO use --headless):
##   Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/screenshot.gd
## Saída: screenshots/city.png, character_panel.png, training_panel.png,
## battle.png e battle_result.png

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
	main.character_panel.close()
	main.city.buildings["training"].clicked.emit()
	for _i in 5:
		await process_frame
	_save("training_panel.png")
	main.training_panel.fight_buttons["giant_rat"].pressed.emit()
	# Sem tipo: este script compila antes do autoload GameState, que o BattleScreen usa.
	var battle_screen = main.battle_screen
	battle_screen.event_delay = 0.0
	await battle_screen.play(Battle.Action.SKILL)
	for _i in 5:
		await process_frame
	_save("battle.png")
	while not battle_screen.battle.is_over():
		await battle_screen.play(Battle.Action.ATTACK)
	for _i in 60:
		await process_frame
	_save("battle_result.png")
	quit(0)


func _save(file_name: String) -> void:
	var image := root.get_texture().get_image()
	image.save_png(OUTPUT_DIR + "/" + file_name)
	print("salvo %s/%s (%dx%d)" % [OUTPUT_DIR, file_name, image.get_width(), image.get_height()])
