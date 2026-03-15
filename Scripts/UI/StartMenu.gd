extends Control


func _on_classic_pressed() -> void:
	_start_game("classic", 0)


func _on_level1_pressed() -> void:
	_start_game("single", 0)


func _on_level2_pressed() -> void:
	_start_game("single", 1)


func _on_level3_pressed() -> void:
	_start_game("single", 2)


func _on_ghost_pressed() -> void:
	_start_game("ghost", 3)


func _start_game(mode: String, round_idx: int) -> void:
	var gsm = get_node("/root/GameStateManager")
	gsm.game_mode       = mode
	gsm.start_round_idx = round_idx
	get_tree().change_scene_to_file("res://Scenes/MainScene.tscn")
