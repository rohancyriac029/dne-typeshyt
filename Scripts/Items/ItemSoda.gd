extends "res://Scripts/Items/BaseItem.gd"


func _init() -> void:
	item_name    = "Soda"
	texture_path = "res://Assets/Objects/soda_sprite.png"


func execute(_actor: Node, _target: Node, shotgun: Node, _gsm: Node, ui: Node) -> void:
	if shotgun.is_empty():
		return
	# Eject shell blindly — no reveal
	var _ejected: String = shotgun.eject()
	print("[Item] Soda → ejected a shell (hidden)")
	if ui:
		ui.show_item_used("Soda — ejected!")
