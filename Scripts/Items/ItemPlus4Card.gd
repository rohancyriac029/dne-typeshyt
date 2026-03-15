extends "res://Scripts/Items/BaseItem.gd"


func _init() -> void:
	item_name    = "+4 Card"
	texture_path = "res://Assets/Objects/4card Background Removed.png"


## Inserts 4 shells (3 BLANK + 1 LIVE, shuffled) at the TOP of the barrel.
## If total shells exceed 8, shells are discarded from the BOTTOM (back of array).
func execute(_actor: Node, _target: Node, shotgun: Node, _gsm: Node, ui: Node) -> void:
	# Build the 4 new shells: exactly 3 blank + 1 live
	var new_shells: Array[String] = ["LIVE", "BLANK", "BLANK", "BLANK"]
	new_shells.shuffle()

	# Insert at the front (top of barrel)
	var combined: Array[String] = []
	combined.append_array(new_shells)
	combined.append_array(shotgun.shells)

	# Enforce max barrel capacity of 8 — trim from the BACK (bottom)
	while combined.size() > 8:
		var discarded: String = combined.pop_back()
		print("[Item] +4 Card — overflow discarded from bottom: ", discarded)

	shotgun.shells = combined
	print("[Item] +4 Card → barrel now: ", str(shotgun.shells))

	if ui:
		ui.show_item_used("+4 CARD!")
