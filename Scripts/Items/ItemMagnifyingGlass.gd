extends "res://Scripts/Items/BaseItem.gd"


func _init() -> void:
	item_name    = "Magnifying Glass"
	texture_path = "res://Assets/Objects/magnifying_glass_sprite.png.png"


func execute(actor: Node, _target: Node, shotgun: Node, _gsm: Node, ui: Node) -> void:
	var shell: String = shotgun.peek_next()
	print("[Item] Magnifying Glass → next shell: ", shell)
	if ui:
		ui.show_peek_result(shell)
