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
	# Single-round mode — always WIN after this round
	if gsm.game_mode == "single":
		gsm.change_state(gsm.State.WIN)
		return

	current_round += 1
	if current_round >= 3:
		# All 3 rounds cleared → WIN
		gsm.change_state(gsm.State.WIN)
	else:
		# More rounds to go
		gsm.change_state(gsm.State.ROUND_START)


## Loads the Ghost Round (Round 4). Fixed 8 shells, max 2 live, 1 HP player, ∞ dealer.
func load_ghost_round() -> void:
	is_reloading = false
	var live_count: int = randi_range(1, 2)
	var blank_count: int = 8 - live_count
	print("[Round] Loading Ghost Round 4: %d LIVE + %d BLANK" % [live_count, blank_count])

	# Ghost has 1 "Glowing Orb" HP; Dealer has ∞ (999)
	player.reset(1, 0)
	dealer.reset(999, 0)

	shotgun.load_shells(live_count, blank_count)

	# Distribute ghost-specific items (1x +4 Card each)
	if item_system and item_system.has_method("distribute_ghost_items"):
		item_system.distribute_ghost_items()

	gsm.change_state(gsm.State.LOAD_SHELLS)


## Starts Resurrected Round 3 after winning Round 4.
func start_resurrected_round3() -> void:
	print("[Round] Starting Resurrected Round 3")
	current_round = 2  # Round 3 is index 2
	gsm.is_ghost_round = false
	gsm.is_resurrected_round3 = true
	load_round()  # Uses existing Round 3 config (4+2 HP, 4 items)


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
