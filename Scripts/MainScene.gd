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

	# ── Start game based on selected mode ───────────────────────
	# Reset GSM flags for fresh game
	gsm.is_ghost_round        = false
	gsm.is_resurrected_round3 = false
	gsm.player_cuffed         = false
	gsm.dealer_cuffed         = false
	gsm.shotgun_damage        = 1

	match gsm.game_mode:
		"ghost":
			# Jump directly to Ghost Round 4
			gsm.change_state(gsm.State.GHOST_ROUND_START)
		"single":
			# Play a single round at the specified index
			round_system.current_round = gsm.start_round_idx
			gsm.change_state(gsm.State.ROUND_START)
		_:
			# Classic mode — start from the specified round (default 0)
			round_system.current_round = gsm.start_round_idx
			gsm.change_state(gsm.State.ROUND_START)


# ── Ghost Theme ─────────────────────────────────────────────────────

func _on_gsm_state_changed(new_state) -> void:
	if new_state == gsm.State.GHOST_ROUND_START:
		apply_ghost_theme()
	elif new_state == gsm.State.RESURRECTION:
		# Revert ghost theme DURING resurrection — so by the time
		# Round 3 loads (via LOAD_SHELLS), visuals are already normal.
		_revert_ghost_theme()
		_spawn_ghost_ally()


func apply_ghost_theme() -> void:
	print("[MainScene] Applying ghost theme — the other side")

	# ── 1) Desaturate world sprites — grey/pale, not dark ──────────────
	#    Background stays its original brightness but goes grey/desaturated
	if _background_sprite:
		var tween := get_tree().create_tween()
		tween.tween_property(_background_sprite, "modulate", Color(0.65, 0.65, 0.7, 1.0), 2.0)

	# Item sprites on the table become pale & ghostly
	var _world_sprites := ["CigBackgroundRemoved", "CanBackgroundRemoved",
		"LensBackgroundRemoved", "HsawBackgroundRemoved", "CuffsBackgroundRemoved",
		"4CardBackgroundRemoved", "CigSprite", "MagnifyingGlassSprite",
		"SodaSprite", "HandsawSprite"]
	for sprite_name in _world_sprites:
		var sprite = get_node_or_null(sprite_name)
		if sprite:
			var s_tween := get_tree().create_tween()
			s_tween.tween_property(sprite, "modulate", Color(0.6, 0.65, 0.7, 0.85), 2.0)

	# Shotgun goes slightly desaturated but NO glow/pulse
	if _shotgun_sprite:
		var sg_tween := get_tree().create_tween()
		sg_tween.tween_property(_shotgun_sprite, "modulate", Color(0.7, 0.7, 0.75, 1.0), 2.0)

	# ── 2) Soft vignette — like light diffused through fog ─────────────
	if _vignette_overlay and _vignette_overlay.material:
		var mat = _vignette_overlay.material
		var v_tween := get_tree().create_tween()
		# Gentle, not aggressive — softens the edges like fog
		v_tween.tween_method(func(v): mat.set_shader_parameter("vignette_strength", v),
			_original_vignette_strength, 0.4, 2.0)
		v_tween.parallel().tween_method(func(v): mat.set_shader_parameter("vignette_radius", v),
			_original_vignette_radius, 0.6, 2.0)
		v_tween.parallel().tween_method(func(v): mat.set_shader_parameter("softness", v),
			_original_vignette_softness, 0.7, 2.0)

	# ── 3) Fog overlay — translucent grey wash over everything ─────────
	_create_fog_overlay()

	# ── 4) Floating wisps — small pale circles drifting slowly ─────────
	_create_ghost_wisps()


func _revert_ghost_theme() -> void:
	print("[MainScene] Reverting ghost theme — returning to the living")

	# Restore background
	if _background_sprite:
		var tween := get_tree().create_tween()
		tween.tween_property(_background_sprite, "modulate", _original_bg_modulate, 1.5)

	# Restore all world sprites
	var _world_sprites := ["CigBackgroundRemoved", "CanBackgroundRemoved",
		"LensBackgroundRemoved", "HsawBackgroundRemoved", "CuffsBackgroundRemoved",
		"4CardBackgroundRemoved", "CigSprite", "MagnifyingGlassSprite",
		"SodaSprite", "HandsawSprite"]
	for sprite_name in _world_sprites:
		var sprite = get_node_or_null(sprite_name)
		if sprite:
			var s_tween := get_tree().create_tween()
			s_tween.tween_property(sprite, "modulate", Color.WHITE, 1.0)

	# Restore shotgun
	if _shotgun_sprite:
		var sg_tween := get_tree().create_tween()
		sg_tween.tween_property(_shotgun_sprite, "modulate", Color.WHITE, 1.0)

	# Restore vignette
	if _vignette_overlay and _vignette_overlay.material:
		var mat = _vignette_overlay.material
		var v_tween := get_tree().create_tween()
		v_tween.tween_method(func(v): mat.set_shader_parameter("vignette_strength", v),
			mat.get_shader_parameter("vignette_strength"), _original_vignette_strength, 1.5)
		v_tween.parallel().tween_method(func(v): mat.set_shader_parameter("vignette_radius", v),
			mat.get_shader_parameter("vignette_radius"), _original_vignette_radius, 1.5)
		v_tween.parallel().tween_method(func(v): mat.set_shader_parameter("softness", v),
			mat.get_shader_parameter("softness"), _original_vignette_softness, 1.5)

	# Remove fog overlay
	_remove_fog_overlay()

	# Remove wisps
	_remove_ghost_wisps()


# ── Fog overlay ───────────────────────────────────────────────────────

var _fog_overlay: ColorRect = null

func _create_fog_overlay() -> void:
	if _fog_overlay:
		return
	_fog_overlay = ColorRect.new()
	_fog_overlay.name = "GhostFogOverlay"
	_fog_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_fog_overlay.color = Color(0.55, 0.55, 0.6, 0.0)  # Start invisible
	_fog_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog_overlay.z_index = 90

	var canvas = get_node_or_null("CanvasLayer")
	if canvas:
		canvas.add_child(_fog_overlay)
	else:
		add_child(_fog_overlay)

	# Fade in to a subtle translucent fog
	var tween := get_tree().create_tween()
	tween.tween_property(_fog_overlay, "color:a", 0.12, 3.0).set_ease(Tween.EASE_IN_OUT)


func _remove_fog_overlay() -> void:
	if not _fog_overlay:
		return
	var tween := get_tree().create_tween()
	tween.tween_property(_fog_overlay, "color:a", 0.0, 1.0)
	tween.tween_callback(_fog_overlay.queue_free)
	_fog_overlay = null


# ── Ghost wisps (floating particles) ──────────────────────────────────

var _wisp_particles: CPUParticles2D = null

func _create_ghost_wisps() -> void:
	if _wisp_particles:
		return
	_wisp_particles = CPUParticles2D.new()
	_wisp_particles.name = "GhostWisps"
	_wisp_particles.emitting = true
	_wisp_particles.amount = 20
	_wisp_particles.lifetime = 8.0
	_wisp_particles.position = Vector2(568, 400)  # Center of screen
	_wisp_particles.z_index = 3

	# Emission shape — spread across the whole screen
	_wisp_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_wisp_particles.emission_rect_extents = Vector2(600, 400)

	# Movement — slow drift upward with slight spread
	_wisp_particles.direction = Vector2(0, -1)
	_wisp_particles.spread = 45.0
	_wisp_particles.initial_velocity_min = 8.0
	_wisp_particles.initial_velocity_max = 20.0
	_wisp_particles.gravity = Vector2(0, 0)

	# Size — small orbs
	_wisp_particles.scale_amount_min = 1.5
	_wisp_particles.scale_amount_max = 4.0

	# Color — pale white/blue-grey, fading in and out
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0.7, 0.75, 0.85, 0.0))
	gradient.add_point(0.2, Color(0.7, 0.75, 0.85, 0.25))
	gradient.add_point(0.8, Color(0.6, 0.65, 0.75, 0.15))
	gradient.add_point(1.0, Color(0.6, 0.65, 0.75, 0.0))
	_wisp_particles.color_ramp = gradient

	add_child(_wisp_particles)


func _remove_ghost_wisps() -> void:
	if not _wisp_particles:
		return
	_wisp_particles.emitting = false
	# Let existing particles finish, then remove
	get_tree().create_timer(_wisp_particles.lifetime).timeout.connect(
		func(): 
			if _wisp_particles:
				_wisp_particles.queue_free()
				_wisp_particles = null
	)


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

