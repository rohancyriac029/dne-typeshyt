extends "res://Scripts/Items/BaseItem.gd"


func _init() -> void:
	item_name    = "Cigarette"
	texture_path = "res://Assets/Objects/cig_sprite.png"


func execute(actor: Node, _target: Node, _shotgun: Node, _gsm: Node, ui: Node) -> void:
	actor.heal(1)
	print("[Item] Cigarette → healed actor by 1")
	if ui:
		ui.show_item_used("Cigarette +1")
