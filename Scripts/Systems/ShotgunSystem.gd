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


## Ejects the top shell blindly (Soda item). Returns it for logging but callers may ignore.
func eject() -> String:
	if shells.is_empty():
		return ""
	var s: String = shells.pop_front()
	print("[Shotgun] Ejected (blind): ", s)
	return s


func peek_next() -> String:
	return shells[0] if not shells.is_empty() else ""


## Peek at a specific index (0 = current, 1 = next, etc.)
func peek_at(index: int) -> String:
	if index >= 0 and index < shells.size():
		return shells[index]
	return ""


func is_empty() -> bool:
	return shells.is_empty()


func remaining_count() -> int:
	return shells.size()


func live_count() -> int:
	return shells.count("LIVE")


func blank_count() -> int:
	return shells.count("BLANK")

