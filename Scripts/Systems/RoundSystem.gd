## RoundSystem.gd
## Data-driven round config. Drives player/dealer reset and shell loading.
extends Node

var current_round: int = 0
var is_reloading: bool = false

# Injected by MainScene
var gsm: Node
var shotgun: Node
var player: Node
var dealer: Node
var item_system: Node


func load_round() -> void:
	is_reloading = false
	var cfg := _get_config(current_round)
	print("[Round] Starting round %d: %s" % [current_round + 1, str(cfg)])

	# Reset health (supports faded charges from Round 3)
	player.reset(cfg.hp_regular, cfg.get("hp_faded", 0))
	dealer.reset(cfg.hp_regular, cfg.get("hp_faded", 0))

	# Load shells
	shotgun.load_shells(cfg.live, cfg.blank)

	# Distribute items (0 in round 1)
	if item_system:
		var item_count: int = cfg.get("items_per_player", 0)
		item_system.distribute_items(item_count)

	gsm.change_state(gsm.State.LOAD_SHELLS)


func reload_shells() -> void:
	is_reloading = true
	var cfg := _get_config(current_round)
	print("[Round] Reloading shells mid-round")
	shotgun.load_shells(cfg.live, cfg.blank)
	gsm.change_state(gsm.State.LOAD_SHELLS)


## Called when the dealer is killed. Advances to the next round or triggers WIN.
func on_dealer_killed() -> void:
	current_round += 1
	if current_round >= 3:
		# All 3 rounds cleared → WIN
		gsm.change_state(gsm.State.WIN)
	else:
		# More rounds to go
		gsm.change_state(gsm.State.ROUND_START)


func _get_config(idx: int) -> Dictionary:
	match idx:
		0: return {
			live            = randi_range(1, 3),
			blank           = randi_range(1, 3),
			hp_regular      = 2,
			hp_faded        = 0,
			items_per_player = 0,
		}
		1: return {
			live            = randi_range(2, 4),
			blank           = randi_range(2, 4),
			hp_regular      = 4,
			hp_faded        = 0,
			items_per_player = 2,
		}
		2: return {
			live            = randi_range(3, 6),
			blank           = randi_range(2, 6),
			hp_regular      = 4,
			hp_faded        = 2,
			items_per_player = 4,
		}
		_: return {
			live            = randi_range(1, 3),
			blank           = randi_range(1, 3),
			hp_regular      = 2,
			hp_faded        = 0,
			items_per_player = 0,
		}
