extends Node

var current_round: int = 0
var is_reloading: bool = false

# Injected by MainScene
var gsm: Node
var shotgun: Node
var player: Node
var dealer: Node


func load_round() -> void:
	is_reloading = false
	var cfg := _get_config(current_round)
	print("[Round] Starting round %d: %s" % [current_round + 1, str(cfg)])
	player.reset(cfg.hp)
	dealer.reset(cfg.hp)
	shotgun.load_shells(cfg.live, cfg.blank)
	gsm.change_state(gsm.State.LOAD_SHELLS)


func reload_shells() -> void:
	is_reloading = true
	var cfg := _get_config(current_round)
	print("[Round] Reloading shells mid-round")
	shotgun.load_shells(cfg.live, cfg.blank)
	gsm.change_state(gsm.State.LOAD_SHELLS)


func end_round() -> void:
	current_round += 1
	if current_round >= 3:
		gsm.change_state(gsm.State.WIN)
	else:
		gsm.change_state(gsm.State.ROUND_START)


func _get_config(idx: int) -> Dictionary:
	match idx:
		0: return {live = randi_range(1, 3), blank = randi_range(1, 3), hp = 2}
		1: return {live = randi_range(2, 4), blank = randi_range(2, 4), hp = 4}
		2: return {live = randi_range(3, 6), blank = randi_range(2, 6), hp = 6}
		_: return {live = randi_range(1, 3), blank = randi_range(1, 3), hp = 2}
