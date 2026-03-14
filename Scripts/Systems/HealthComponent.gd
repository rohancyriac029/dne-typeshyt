extends Node

@export var max_hp: int = 2
var current_hp: int = 0

signal hp_changed(current: int, maximum: int)
signal entity_died


func _ready() -> void:
	current_hp = max_hp


func reset(new_max: int) -> void:
	max_hp = new_max
	current_hp = new_max
	emit_signal("hp_changed", current_hp, max_hp)


func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	print("[Health] %s → %d/%d" % [name, current_hp, max_hp])
	emit_signal("hp_changed", current_hp, max_hp)
	if current_hp <= 0:
		emit_signal("entity_died")
