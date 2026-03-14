extends "res://Scripts/Items/BaseItem.gd"


func _init() -> void:
	item_name    = "Handcuffs"
	texture_path = "res://Assets/Objects/handcuffs_sprite.png"


## Cuffs the *opponent*.
## actor == the entity USING the item (player or dealer HealthComponent node).
## target == the opponent HealthComponent node.
## We compare actor against gsm.player / gsm.dealer to figure out who's who.
func execute(actor: Node, _target: Node, _shotgun: Node, gsm: Node, ui: Node) -> void:
	# actor IS the player → cuff the dealer
	if actor == gsm.player:
		gsm.dealer_cuffed = true
		print("[Item] Handcuffs → dealer's next turn skipped")
		if ui:
			ui.show_item_used("Dealer cuffed!")
	else:
		gsm.player_cuffed = true
		print("[Item] Handcuffs → player's next turn skipped")
		if ui:
			ui.show_item_used("You've been cuffed!")
