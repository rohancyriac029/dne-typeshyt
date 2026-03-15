## ItemSystem.gd
## Manages item inventories for player and dealer.
## Distributes randomised items at round start.
extends Node

# Injected by MainScene
var gsm: Node
var shotgun: Node
var player: Node
var dealer: Node
var ui: Node

# Inventories — arrays of BaseItem instances
var player_items: Array = []
var dealer_items: Array = []

signal player_items_changed(items: Array)
signal dealer_items_changed(items: Array)

# Pool of item constructors
const ITEM_SCRIPTS := [
	preload("res://Scripts/Items/ItemMagnifyingGlass.gd"),
	preload("res://Scripts/Items/ItemCigarette.gd"),
	preload("res://Scripts/Items/ItemSoda.gd"),
	preload("res://Scripts/Items/ItemHandcuffs.gd"),
	preload("res://Scripts/Items/ItemHandsaw.gd"),
]


func distribute_items(count: int) -> void:
	player_items.clear()
	dealer_items.clear()
	for i in range(count):
		player_items.append(_random_item())
		dealer_items.append(_random_item())
	print("[ItemSystem] Player items: ", _names(player_items))
	print("[ItemSystem] Dealer items: ", _names(dealer_items))
	emit_signal("player_items_changed", player_items)
	emit_signal("dealer_items_changed", dealer_items)


## Ghost Round 4: exactly 1x +4 Card each. No other items.
func distribute_ghost_items() -> void:
	var plus4_script = preload("res://Scripts/Items/ItemPlus4Card.gd")
	player_items.clear()
	dealer_items.clear()
	player_items.append(plus4_script.new())
	dealer_items.append(plus4_script.new())
	print("[ItemSystem] Ghost items — Player: ", _names(player_items))
	print("[ItemSystem] Ghost items — Dealer: ", _names(dealer_items))
	emit_signal("player_items_changed", player_items)
	emit_signal("dealer_items_changed", dealer_items)


func player_use_item(index: int) -> void:
	if index < 0 or index >= player_items.size():
		return
	var item = player_items[index]
	item.execute(player, dealer, shotgun, gsm, ui)
	player_items.remove_at(index)
	emit_signal("player_items_changed", player_items)


## Dealer uses an item by reference directly
func dealer_use_item(item) -> void:
	var idx: int = dealer_items.find(item)
	if idx == -1:
		return
	item.execute(dealer, player, shotgun, gsm, ui)
	dealer_items.remove_at(idx)
	emit_signal("dealer_items_changed", dealer_items)


func _random_item() -> Object:
	var script = ITEM_SCRIPTS[randi() % ITEM_SCRIPTS.size()]
	return script.new()


func _names(items: Array) -> Array:
	var out: Array = []
	for item in items:
		out.append(item.item_name)
	return out
