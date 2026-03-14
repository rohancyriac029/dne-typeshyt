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

var shotgun_sprite: Node2D

var pending_shooter: String = ""
var pending_target: String = ""

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
			round_system.load_round()

		State.LOAD_SHELLS:
			# Shells loaded. Show the intro sequence, then advance.
			if ui_manager:
				var title = "RELOAD" if round_system.is_reloading else "ROUND " + str(round_system.current_round + 1)
				await ui_manager.show_intro_sequence(title, shotgun_system.live_count(), shotgun_system.blank_count())
			change_state(State.PLAYER_TURN)

		State.PLAYER_TURN:
			pass  # Wait for player button press

		State.DEALER_TURN:
			await get_tree().create_timer(1.0).timeout
			dealer_logic.take_turn()

		State.RESOLVE_SHOT:
			_resolve_shot()

		State.WIN:
			pass  # UIManager listens and switches scene

		State.LOSE:
			pass  # UIManager listens and switches scene


func _resolve_shot() -> void:
	var shell: String = shotgun_system.fire()
	print("[GSM] Shell: ", shell, " | Shooter: ", pending_shooter, " | Target: ", pending_target)

	if shotgun_sprite:
		# 1. Point Gun
		# The gun's default sprite points right (0 degrees).
		# To point at dealer (top of screen): -90 degrees (-PI/2)
		# To point at player (bottom): +90 degrees (PI/2)
		var target_rotation: float = -PI/2.0 if pending_target == "dealer" else PI/2.0
		var point_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		point_tween.tween_property(shotgun_sprite, "rotation", target_rotation, 0.3)
		await point_tween.finished
		
		# Small delay before firing
		await get_tree().create_timer(0.2).timeout
		
		# 2. Fire Effect
		var dir_y: float = -1.0 if pending_target == "dealer" else 1.0
		var fire_tween = get_tree().create_tween()
		
		# Save original position to return to
		var start_pos = shotgun_sprite.position
		
		if shell == "LIVE":
			# Heavy recoil and red flash
			fire_tween.tween_property(shotgun_sprite, "position", start_pos + Vector2(0, 50 * -dir_y), 0.05).set_ease(Tween.EASE_OUT)
			fire_tween.parallel().tween_property(shotgun_sprite, "modulate", Color.RED, 0.05)
			fire_tween.tween_property(shotgun_sprite, "position", start_pos, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
			fire_tween.parallel().tween_property(shotgun_sprite, "modulate", Color.WHITE, 0.2)
		else:
			# Weak recoil and gray flash for blank
			fire_tween.tween_property(shotgun_sprite, "position", start_pos + Vector2(0, 10 * -dir_y), 0.1).set_ease(Tween.EASE_OUT)
			fire_tween.parallel().tween_property(shotgun_sprite, "modulate", Color.GRAY, 0.1)
			fire_tween.tween_property(shotgun_sprite, "position", start_pos, 0.2).set_ease(Tween.EASE_IN_OUT)
			fire_tween.parallel().tween_property(shotgun_sprite, "modulate", Color.WHITE, 0.2)
			
		await fire_tween.finished
		await get_tree().create_timer(0.3).timeout
		
		# Reset rotation
		var reset_tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		reset_tween.tween_property(shotgun_sprite, "rotation", 0.0, 0.3)
		await reset_tween.finished

	if shell == "LIVE":
		var target_node: Node = player if pending_target == "player" else dealer
		target_node.take_damage(1)
		# Death checked via entity_died signal connected in MainScene
		if player.current_hp <= 0:
			change_state(State.LOSE)
			return
		if dealer.current_hp <= 0:
			change_state(State.WIN)
			return
		_check_reload_then_switch_turn()
	else:
		# Extra turn only when the shooter aimed at THEMSELVES.
		# Blank aimed at the opponent → turn passes normally.
		var shot_self: bool = (pending_shooter == pending_target)
		if shot_self:
			print("[GSM] BLANK (self) — ", pending_shooter, " shoots again.")
			if shotgun_system.is_empty():
				round_system.reload_shells()
				return  # Skip straight to load sequence
				
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
		return  # Skip straight to load sequence
		
	if pending_shooter == "player":
		change_state(State.DEALER_TURN)
	else:
		change_state(State.PLAYER_TURN)


func player_shoot(target: String) -> void:
	if current_state != State.PLAYER_TURN:
		return
	pending_shooter = "player"
	pending_target = target
	change_state(State.RESOLVE_SHOT)


func dealer_shoot(target: String) -> void:
	pending_shooter = "dealer"
	pending_target = target
	change_state(State.RESOLVE_SHOT)

