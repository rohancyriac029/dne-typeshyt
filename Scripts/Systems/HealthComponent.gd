## HealthComponent.gd
## Supports regular charges + faded charges (Round 3).
## When regular_charges hit 0 → cables cut (no more healing, next hit = instant death).
extends Node

signal hp_changed(current: int, maximum: int, regular: int, faded: int)
signal entity_died
signal cable_cut

# Max pools (set by reset())
var max_regular: int = 2
var max_faded: int   = 0

# Current pools
var regular_charges: int = 0
var faded_charges: int   = 0

# Cable-cut state (Round 3)
var cables_cut: bool = false

# For backwards-compat: total current HP
var current_hp: int:
	get: return regular_charges + faded_charges

var max_hp: int:
	get: return max_regular + max_faded


func _ready() -> void:
	regular_charges = max_regular
	faded_charges   = max_faded


## Called at the start of every round.
func reset(normal: int, faded: int = 0) -> void:
	max_regular     = normal
	max_faded       = faded
	regular_charges = normal
	faded_charges   = faded
	cables_cut      = false
	_emit()


## Heal +amount regular charges. Blocked if cables are cut or at max regular.
func heal(amount: int) -> void:
	if cables_cut:
		print("[Health] heal() blocked — cables cut")
		return
	regular_charges = min(regular_charges + amount, max_regular)
	_emit()


func take_damage(amount: int) -> void:
	if cables_cut:
		# Cables already cut — any damage is instant death
		regular_charges = 0
		faded_charges   = 0
		_emit()
		emit_signal("entity_died")
		return

	# Drain regular charges first
	var drain: int = min(amount, regular_charges)
	regular_charges -= drain
	amount          -= drain

	# Remaining damage spills into faded charges
	if amount > 0:
		faded_charges = max(0, faded_charges - amount)

	print("[Health] %s → regular=%d faded=%d" % [name, regular_charges, faded_charges])
	_emit()

	# Trigger cable cut when regular charges are depleted
	if regular_charges <= 0 and not cables_cut:
		cables_cut = true
		print("[Health] %s — CABLES CUT" % name)
		emit_signal("cable_cut")

	if current_hp <= 0:
		emit_signal("entity_died")


func _emit() -> void:
	emit_signal("hp_changed", current_hp, max_hp, regular_charges, faded_charges)
