extends "res://Scripts/Items/BaseItem.gd"


func _init() -> void:
	item_name    = "Handsaw"
	texture_path = "res://Assets/Objects/handsaw_sprite.png"


func execute(_actor: Node, _target: Node, _shotgun: Node, gsm: Node, ui: Node) -> void:
	gsm.shotgun_damage = 2
	print("[Item] Handsaw → next shot deals 2 damage")
	if ui:
		ui.show_item_used("Handsaw — double damage!")
