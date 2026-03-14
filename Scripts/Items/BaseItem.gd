## BaseItem.gd
## Abstract base class for all items.
## Subclasses must override execute().
extends RefCounted

var item_name: String = "Unknown"
var texture_path: String = ""


## Called when the item is used.
## actor  — the HealthComponent of the user (player or dealer)
## target — the HealthComponent of the opponent
## shotgun — ShotgunSystem node
## gsm    — GameStateManager node
## ui     — UIManager node (for visual feedback)
func execute(actor: Node, target: Node, shotgun: Node, gsm: Node, ui: Node) -> void:
	push_error("[Item] execute() not overridden in: " + item_name)
