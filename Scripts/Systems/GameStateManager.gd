## GameStateManager.gd
## Central state machine. Controls turn flow, shot resolution, and round transitions.
extends Node

enum State {
	INIT,
	ROUND_START,
	LOAD_SHELLS,
	PLAYER_TURN,
	DEALER_TURN,
	RESOLVE_SHOT,
	WIN,
	LOSE,
}

var current_state: State = State.INIT

# Set by MainScene._ready()
var shotgun_system: Node
var round_system: Node
var player: Node
var dealer: Node
var player_controller: Node
var dealer_logic: Node
var ui_manager: Node
var item_system: Node

var shotgun_sprite: Node2D

var pending_shooter: String = ""
var pending_target: String  = ""

# ── Item-driven flags ─────────────────────────────────────────────────
var player_cuffed: bool  = false
var dealer_cuffed: bool  = false
var shotgun_damage: int  = 1   # reset to 1 after every shot

signal state_changed(new_state: State)


func change_state(new_state: State) -> void:
	current_state = new_state
	print("[GSM] → ", State.keys()[new_state])
	emit_signal("state_changed", new_state)
	_on_state_entered(new_state)


func _on_state_entered(state: State) -> void:
	match state:
		State.INIT:
			pass  # MainScene calls change_state(ROUND_START) after wiring

		State.ROUND_START:
			player_cuffed  = false
			dealer_cuffed  = false
			shotgun_damage = 1
			round_system.load_round()

		State.LOAD_SHELLS:
			# Shells loaded. Show the intro sequence, then advance.
			if ui_manager:
				var title: String
				if round_system.is_reloading:
					title = "RELOAD"
				else:
					title = "ROUND " + str(round_system.current_round + 1)
				await ui_manager.show_intro_sequence(title, shotgun_system.live_count(), shotgun_system.blank_count())
			change_state(State.PLAYER_TURN)

		State.PLAYER_TURN:
			pass  # Wait for player button press

		State.DEALER_TURN:
			await get_tree().create_timer(1.8).timeout
			dealer_logic.take_turn()

		State.RESOLVE_SHOT:
			_resolve_shot()

		State.WIN:
			pass  # UIManager listens and switches scene

		State.LOSE:
			pass  # UIManager listens and switches scene


func _resolve_shot() -> void:
	var shell: String = shotgun_system.fire()
	var damage: int = shotgun_damage
	shotgun_damage = 1  # Reset multiplier regardless of shell type

	print("[GSM] Shell: %s | Shooter: %s | Target: %s | Damage: %d" % [shell, pending_shooter, pending_target, damage])

	if shotgun_sprite:
		# ── 1. Point gun at target ──────────────────────────────────
		var target_rotation: float = -PI/2.0 if pending_target == "dealer" else PI/2.0
		var point_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		point_tween.tween_property(shotgun_sprite, "rotation", target_rotation, 0.25)
		await point_tween.finished
		await get_tree().create_timer(0.25).timeout   # tension pause

		var dir_y: float = -1.0 if pending_target == "dealer" else 1.0
		var start_pos: Vector2 = shotgun_sprite.position
		var start_scale: Vector2 = shotgun_sprite.scale

		if shell == "LIVE":
			# ── 2a. LIVE — muzzle flash + heavy recoil + screen shake ──
			# Quick white flash (muzzle)
			var flash = get_tree().create_tween()
			flash.tween_property(shotgun_sprite, "modulate", Color(3, 3, 2.5), 0.03)
			flash.tween_property(shotgun_sprite, "modulate", Color.RED, 0.06)
			await flash.finished

			# Heavy recoil: kick back + slight random horizontal offset
			var kick_offset := Vector2(randf_range(-8, 8), 60 * -dir_y)
			var recoil = get_tree().create_tween()
			recoil.tween_property(shotgun_sprite, "position", start_pos + kick_offset, 0.04).set_ease(Tween.EASE_OUT)
			recoil.parallel().tween_property(shotgun_sprite, "scale", start_scale * 1.08, 0.04)
			await recoil.finished

			# Screen shake
			_screen_shake(shotgun_sprite, 6.0, 0.25)

			# Settle back
			var settle = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
			settle.tween_property(shotgun_sprite, "position", start_pos, 0.35)
			settle.parallel().tween_property(shotgun_sprite, "scale", start_scale, 0.25)
			settle.parallel().tween_property(shotgun_sprite, "modulate", Color.WHITE, 0.3)
			await settle.finished
			await get_tree().create_timer(0.2).timeout

		else:
			# ── 2b. BLANK — soft click, barely any recoil ────────────
			var click = get_tree().create_tween()
			click.tween_property(shotgun_sprite, "modulate", Color(0.6, 0.6, 0.6), 0.06)
			click.parallel().tween_property(shotgun_sprite, "position", start_pos + Vector2(0, 8 * -dir_y), 0.06)
			click.parallel().tween_property(shotgun_sprite, "scale", start_scale * 0.97, 0.06)
			click.tween_property(shotgun_sprite, "position", start_pos, 0.2).set_ease(Tween.EASE_IN_OUT)
			click.parallel().tween_property(shotgun_sprite, "scale", start_scale, 0.15)
			click.parallel().tween_property(shotgun_sprite, "modulate", Color.WHITE, 0.2)
			await click.finished
			await get_tree().create_timer(0.15).timeout

		# ── 3. Reset rotation ───────────────────────────────────────
		var reset_tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		reset_tween.tween_property(shotgun_sprite, "rotation", 0.0, 0.3)
		await reset_tween.finished

	if shell == "LIVE":
		var target_node: Node = player if pending_target == "player" else dealer
		target_node.take_damage(damage)

		if player.current_hp <= 0:
			change_state(State.LOSE)
			return
		if dealer.current_hp <= 0:
			round_system.on_dealer_killed()
			return
		_check_reload_then_switch_turn()
	else:
		# Blank shot at self → shooter keeps turn
		var shot_self: bool = (pending_shooter == pending_target)
		if shot_self:
			print("[GSM] BLANK (self) — ", pending_shooter, " shoots again.")
			if shotgun_system.is_empty():
				round_system.reload_shells()
				return
			
			await get_tree().create_timer(1.0).timeout
			if pending_shooter == "player":
				change_state(State.PLAYER_TURN)
			else:
				change_state(State.DEALER_TURN)
		else:
			print("[GSM] BLANK (opponent) — turn passes.")
			_check_reload_then_switch_turn()


func _check_reload_then_switch_turn() -> void:
	if shotgun_system.is_empty():
		round_system.reload_shells()
		return

	# Add a delay so players can see the turn switch UI
	await get_tree().create_timer(1.0).timeout

	# Apply cuffed logic — skip the next turn if cuffed
	if pending_shooter == "player":
		if dealer_cuffed:
			print("[GSM] Dealer is cuffed — skipping their turn")
			dealer_cuffed = false
			change_state(State.PLAYER_TURN)
		else:
			change_state(State.DEALER_TURN)
	else:
		if player_cuffed:
			print("[GSM] Player is cuffed — skipping their turn")
			player_cuffed = false
			change_state(State.DEALER_TURN)
		else:
			change_state(State.PLAYER_TURN)


func player_shoot(target: String) -> void:
	if current_state != State.PLAYER_TURN:
		return
	pending_shooter = "player"
	pending_target  = target
	change_state(State.RESOLVE_SHOT)


func dealer_shoot(target: String) -> void:
	pending_shooter = "dealer"
	pending_target  = target
	change_state(State.RESOLVE_SHOT)


func _screen_shake(node: Node2D, strength: float, duration: float) -> void:
	var tween = get_tree().create_tween()
	var steps = int(duration * 60) # roughly 60fps
	var delay = duration / float(steps)
	
	for i in range(steps):
		var offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * strength
		# decay strength over time
		var current_strength = strength * (1.0 - float(i)/float(steps)) 
		offset = offset.normalized() * current_strength
		
		var target_pos = Vector2(0, 0) + offset  # relative to its stable center which we handle via its position property
		tween.tween_property(node, "offset", target_pos, delay)
		
	tween.tween_property(node, "offset", Vector2.ZERO, delay)
