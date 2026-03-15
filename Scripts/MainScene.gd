extends Node2D

@onready var shotgun_system: Node    = $ShotgunSystem
@onready var round_system: Node      = $RoundSystem
@onready var item_system: Node       = $ItemSystem
@onready var player: Node            = $Player
@onready var dealer: Node            = $Dealer
@onready var player_controller: Node = $PlayerController
@onready var dealer_logic: Node      = $DealerTurnLogic
@onready var ui_manager              = $CanvasLayer

var gsm: Node

# Visual references for ghost theme
var _background_sprite: Sprite2D
var _shotgun_sprite: Sprite2D
var _vignette_overlay: ColorRect
var _ghost_ally_sprite: Sprite2D = null  # Created on resurrection
var _shotgun_glow_tween: Tween = null

# Original values for theme reset
var _original_bg_modulate: Color
var _original_vignette_strength: float
var _original_vignette_radius: float
var _original_vignette_softness: float

# Ghost textures
var _ghost_hands_texture: Texture2D = null
var _ghost_ally_texture: Texture2D = null


func _ready() -> void:
	gsm = get_node("/root/GameStateManager")

	# ── Inject references into systems ──────────────────────────
	gsm.shotgun_system    = shotgun_system
	gsm.shotgun_sprite    = $ShotgunSprite
	gsm.round_system      = round_system
	gsm.player            = player
	gsm.dealer            = dealer
	gsm.player_controller = player_controller
	gsm.dealer_logic      = dealer_logic
	gsm.ui_manager        = ui_manager
	gsm.item_system       = item_system

	round_system.gsm        = gsm
	round_system.shotgun    = shotgun_system
	round_system.player     = player
	round_system.dealer     = dealer
	round_system.item_system = item_system

	player_controller.gsm = gsm
	dealer_logic.gsm      = gsm
	dealer_logic.shotgun  = shotgun_system
	dealer_logic.player   = player
	dealer_logic.dealer   = dealer
	dealer_logic.item_system = item_system

	item_system.gsm    = gsm
	item_system.shotgun = shotgun_system
	item_system.player  = player
	item_system.dealer  = dealer
	item_system.ui      = ui_manager

	# ── Wire UI ─────────────────────────────────────────────────
	ui_manager.setup(gsm, shotgun_system, player_controller)
	ui_manager.setup_item_system(item_system)
	ui_manager.connect_player(player)
	ui_manager.connect_dealer(dealer)

	# ── Store visual references for ghost theme ─────────────────
	_background_sprite = get_node_or_null("Main")
	_shotgun_sprite    = $ShotgunSprite
	_vignette_overlay  = get_node_or_null("CanvasLayer/VignetteOverlay")

	if _background_sprite:
		_original_bg_modulate = _background_sprite.modulate

	if _vignette_overlay and _vignette_overlay.material:
		_original_vignette_strength = _vignette_overlay.material.get_shader_parameter("vignette_strength")
		_original_vignette_radius   = _vignette_overlay.material.get_shader_parameter("vignette_radius")
		_original_vignette_softness = _vignette_overlay.material.get_shader_parameter("softness")

	# Preload ghost textures
	if ResourceLoader.exists("res://Assets/Characters/ghost_hands Background Removed.png"):
		_ghost_hands_texture = load("res://Assets/Characters/ghost_hands Background Removed.png")
	if ResourceLoader.exists("res://Assets/Characters/ghost_whisperer.png"):
		_ghost_ally_texture = load("res://Assets/Characters/ghost_whisperer.png")

	# ── Listen for state changes to apply/revert ghost theme ────
	gsm.state_changed.connect(_on_gsm_state_changed)

	# ── Start game ──────────────────────────────────────────────
	gsm.change_state(gsm.State.ROUND_START)


# ── Ghost Theme ─────────────────────────────────────────────────────

func _on_gsm_state_changed(new_state) -> void:
	if new_state == gsm.State.GHOST_ROUND_START:
		apply_ghost_theme()
	elif new_state == gsm.State.RESURRECTION:
		pass  # Theme revert happens after resurrection animation
	elif new_state == gsm.State.ROUND_START and gsm.is_resurrected_round3:
		_revert_ghost_theme()
		_spawn_ghost_ally()


func apply_ghost_theme() -> void:
	print("[MainScene] Applying ghost theme")

	# Darken background to eerie blue-grey
	if _background_sprite:
		var tween := get_tree().create_tween()
		tween.tween_property(_background_sprite, "modulate", Color(0.15, 0.15, 0.25, 1.0), 1.5)

	# Tighten vignette — darker, more oppressive
	if _vignette_overlay and _vignette_overlay.material:
		var mat = _vignette_overlay.material
		var v_tween := get_tree().create_tween()
		v_tween.tween_method(func(v): mat.set_shader_parameter("vignette_strength", v), _original_vignette_strength, 0.55, 1.5)
		v_tween.parallel().tween_method(func(v): mat.set_shader_parameter("vignette_radius", v), _original_vignette_radius, 0.55, 1.5)

	# Add pulsing glow to shotgun
	_start_shotgun_glow()


func _revert_ghost_theme() -> void:
	print("[MainScene] Reverting ghost theme for Resurrected Round 3")

	# Restore background (with a slight ghostly tint as reminder)
	if _background_sprite:
		var tween := get_tree().create_tween()
		tween.tween_property(_background_sprite, "modulate", Color(0.85, 0.85, 0.95, 1.0), 1.0)

	# Restore vignette
	if _vignette_overlay and _vignette_overlay.material:
		var mat = _vignette_overlay.material
		var v_tween := get_tree().create_tween()
		v_tween.tween_method(func(v): mat.set_shader_parameter("vignette_strength", v), 0.55, _original_vignette_strength, 1.0)
		v_tween.parallel().tween_method(func(v): mat.set_shader_parameter("vignette_radius", v), 0.55, _original_vignette_radius, 1.0)

	# Stop shotgun glow
	_stop_shotgun_glow()


func _start_shotgun_glow() -> void:
	if not _shotgun_sprite:
		return
	_stop_shotgun_glow()
	_shotgun_glow_tween = get_tree().create_tween().set_loops()
	_shotgun_glow_tween.tween_property(_shotgun_sprite, "modulate", Color(0.6, 0.8, 1.2, 1.0), 1.2).set_ease(Tween.EASE_IN_OUT)
	_shotgun_glow_tween.tween_property(_shotgun_sprite, "modulate", Color(0.4, 0.5, 0.9, 1.0), 1.2).set_ease(Tween.EASE_IN_OUT)


func _stop_shotgun_glow() -> void:
	if _shotgun_glow_tween:
		_shotgun_glow_tween.kill()
		_shotgun_glow_tween = null
	if _shotgun_sprite:
		_shotgun_sprite.modulate = Color.WHITE


func _spawn_ghost_ally() -> void:
	if _ghost_ally_sprite or not _ghost_ally_texture:
		return
	print("[MainScene] Spawning Ghost Ally behind dealer")
	_ghost_ally_sprite = Sprite2D.new()
	_ghost_ally_sprite.texture = _ghost_ally_texture
	_ghost_ally_sprite.position = Vector2(568, 120)  # Behind dealer area
	_ghost_ally_sprite.scale    = Vector2(0.12, 0.12)
	_ghost_ally_sprite.modulate = Color(0.6, 0.8, 1.0, 0.0)  # Start invisible
	_ghost_ally_sprite.z_index  = 2
	add_child(_ghost_ally_sprite)

	# Fade in gently
	var tween := get_tree().create_tween()
	tween.tween_property(_ghost_ally_sprite, "modulate:a", 0.5, 2.0).set_ease(Tween.EASE_IN_OUT)

