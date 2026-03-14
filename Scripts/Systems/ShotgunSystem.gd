extends Node

var shells: Array[String] = []


func load_shells(live: int, blank: int) -> void:
	shells.clear()
	for i in live:
		shells.append("LIVE")
	for i in blank:
		shells.append("BLANK")
	shells.shuffle()
	print("[Shotgun] Loaded %d LIVE + %d BLANK | %s" % [live, blank, str(shells)])


func fire() -> String:
	if shells.is_empty():
		push_error("[Shotgun] fire() with empty chamber!")
		return "BLANK"
	return shells.pop_front()


func peek_next() -> String:
	return shells[0] if not shells.is_empty() else ""


func is_empty() -> bool:
	return shells.is_empty()


func remaining_count() -> int:
	return shells.size()


func live_count() -> int:
	return shells.count("LIVE")


func blank_count() -> int:
	return shells.count("BLANK")
