extends CanvasLayer

# Injected via setup()
var gsm: Node
var shotgun: Node
var player_controller: Node
var item_system: Node

@onready var intro_panel: ColorRect        = $IntroPanel
@onready var round_label: Label            = $IntroPanel/RoundLabel
@onready var count_label: Label            = $IntroPanel/CountLabel
@onready var slots_overlay: Control        = $IntroPanel/TrayContainer/SlotsOverlay

@onready var player_hp_container: HBoxContainer  = $UI/PlayerHPContainer
@onready var dealer_hp_container: HBoxContainer  = $UI/DealerHPContainer
@onready var shell_container: VBoxContainer      = $UI/ShellContainer
@onready var shoot_self_btn: TextureButton       = $UI/ShootSelfButton
@onready var shoot_dealer_btn: TextureButton     = $UI/ShootDealerButton

# Item rows — populated in setup() since they may not exist in old scenes
var player_item_container: HBoxContainer = null
var dealer_item_container: HBoxContainer = null
var feedback_label: Label = null
var turn_label: Label = null

var hp_texture          = preload("res://Assets/UI/hp_icon.png")
var live_shell_texture  = preload("res://Assets/Objects/live_shell_icon.png")
var blank_shell_texture = preload("res://Assets/Objects/blank_shell_icon.png")

# Ghost Round 4 textures
var _orb_texture: Texture2D = null
var _infinite_texture: Texture2D = null
var _ghost_whisper_texture: Texture2D = null
var _orb_glow_tween: Tween = null

# Item textures mapped by item_name
var _item_textures: Dictionary = {}


func setup(p_gsm: Node, p_shotgun: Node, p_controller: Node) -> void:
	gsm              = p_gsm
	shotgun          = p_shotgun
	player_controller = p_controller

	# Resolve optional nodes via get_node_or_null (safe for any scene version)
	player_item_container = get_node_or_null("UI/PlayerItemContainer")
	dealer_item_container = get_node_or_null("UI/DealerItemContainer")
	feedback_label        = get_node_or_null("UI/FeedbackLabel")
	turn_label            = get_node_or_null("UI/TurnLabel")

	gsm.state_changed.connect(_on_state_changed)
	shoot_self_btn.pressed.connect(player_controller.on_shoot_self_pressed)
	shoot_dealer_btn.pressed.connect(player_controller.on_shoot_dealer_pressed)

	_set_buttons_visible(false)
	intro_panel.modulate.a = 0.0

	# Preload ghost textures
	if ResourceLoader.exists("res://Assets/UI/orb Background Removed.png"):
		_orb_texture = load("res://Assets/UI/orb Background Removed.png")
	if ResourceLoader.exists("res://Assets/UI/infinite_symbol Background Removed.png"):
		_infinite_texture = load("res://Assets/UI/infinite_symbol Background Removed.png")
	if ResourceLoader.exists("res://Assets/Characters/ghost_whisperer.png"):
		_ghost_whisper_texture = load("res://Assets/Characters/ghost_whisperer.png")


func setup_item_system(p_item_system: Node) -> void:
	item_system = p_item_system
	item_system.player_items_changed.connect(update_player_items)
	item_system.dealer_items_changed.connect(update_dealer_items)


# ── Intro sequence ────────────────────────────────────────────────────

func show_intro_sequence(title: String, live: int, blank: int) -> void:
	shell_container.hide()

	# Ghost round: special intro theming
	var is_ghost: bool = gsm and gsm.is_ghost_round
	if is_ghost:
		round_label.text = "THE OTHER SIDE"
		if round_label.has_theme_color_override("font_color"):
			round_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		intro_panel.color = Color(0.02, 0.02, 0.08, 0.92)
	else:
		round_label.text = title
		if round_label.has_theme_color_override("font_color"):
			round_label.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
		intro_panel.color = Color(0.05, 0, 0, 0.85)

	if count_label:
		count_label.text = str(live) + " LIVE, " + str(blank) + " BLANK"

	_update_intro_tray(live, blank)

	var fade_in = get_tree().create_tween()
	fade_in.tween_property(intro_panel, "modulate:a", 1.0, 0.5)
	await fade_in.finished

	await get_tree().create_timer(3.0).timeout

	var fade_out = get_tree().create_tween()
	fade_out.tween_property(intro_panel, "modulate:a", 0.0, 0.5)
	await fade_out.finished

	for child in slots_overlay.get_children():
		child.queue_free()

	# Reset intro panel color for next round
	if is_ghost:
		intro_panel.color = Color(0.05, 0, 0, 0.85)


# ── HP display ────────────────────────────────────────────────────────

func connect_player(player: Node) -> void:
	player.hp_changed.connect(_on_player_hp_changed)
	_on_player_hp_changed(player.current_hp, player.max_hp,
		player.regular_charges, player.faded_charges)


func connect_dealer(dealer: Node) -> void:
	dealer.hp_changed.connect(_on_dealer_hp_changed)
	_on_dealer_hp_changed(dealer.current_hp, dealer.max_hp,
		dealer.regular_charges, dealer.faded_charges)


func _on_player_hp_changed(current: int, _maximum: int, regular: int = -1, faded: int = 0) -> void:
	if gsm and gsm.is_ghost_round:
		_update_ghost_player_hp(current)
	else:
		_update_hp_container(player_hp_container, regular if regular >= 0 else current, faded)
	_animate_container(player_hp_container)
	_update_shell_counter()


func _on_dealer_hp_changed(current: int, _maximum: int, regular: int = -1, faded: int = 0) -> void:
	if gsm and gsm.is_ghost_round:
		_update_ghost_dealer_hp()
	else:
		_update_hp_container(dealer_hp_container, regular if regular >= 0 else current, faded)
	_animate_container(dealer_hp_container)
	_update_shell_counter()


## Renders regular charges (full brightness) then faded charges (dimmed).
func _update_hp_container(container: Control, regular: int, faded: int) -> void:
	for child in container.get_children():
		child.queue_free()

	for i in range(regular):
		var tex_rect := TextureRect.new()
		tex_rect.texture = hp_texture
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.custom_minimum_size = Vector2(22, 22)
		container.add_child(tex_rect)

	for i in range(faded):
		var tex_rect := TextureRect.new()
		tex_rect.texture = hp_texture
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.custom_minimum_size = Vector2(22, 22)
		tex_rect.modulate = Color(0.45, 0.45, 0.45, 0.8)  # dimmed / cracked
		container.add_child(tex_rect)


# ── Item display ──────────────────────────────────────────────────────

func update_player_items(items: Array) -> void:
	if not player_item_container:
		return
	_rebuild_item_row(player_item_container, items, true)


func update_dealer_items(items: Array) -> void:
	if not dealer_item_container:
		return
	_rebuild_item_row(dealer_item_container, items, false)


func _rebuild_item_row(container: HBoxContainer, items: Array, is_player: bool) -> void:
	for child in container.get_children():
		child.queue_free()

	for idx in range(items.size()):
		var item = items[idx]
		var tex: Texture2D = _load_item_texture(item.texture_path)
		var btn := TextureButton.new()
		btn.texture_normal = tex
		btn.ignore_texture_size = true
		btn.custom_minimum_size = Vector2(48, 48)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		if is_player:
			var capture_idx = idx
			btn.pressed.connect(func(): _on_player_item_pressed(capture_idx))
		else:
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE  # dealer items — display only
			btn.modulate = Color(0.7, 0.7, 0.7)

		container.add_child(btn)


func _on_player_item_pressed(index: int) -> void:
	if gsm.current_state != gsm.State.PLAYER_TURN:
		return
	if item_system:
		item_system.player_use_item(index)


func _load_item_texture(path: String) -> Texture2D:
	if _item_textures.has(path):
		return _item_textures[path]
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		_item_textures[path] = tex
		return tex
	return hp_texture  # fallback


# ── Feedback labels ───────────────────────────────────────────────────

func show_peek_result(shell: String) -> void:
	var text := "⚪ BLANK" if shell == "BLANK" else "🔴 LIVE!"
	_flash_feedback(text, Color.RED if shell == "LIVE" else Color.SILVER)


func show_item_used(message: String) -> void:
	_flash_feedback(message, Color.YELLOW)


func _flash_feedback(text: String, color: Color) -> void:
	if not feedback_label:
		print("[UI] Feedback: ", text)
		return
	feedback_label.text   = text
	feedback_label.modulate = color
	feedback_label.modulate.a = 1.0
	feedback_label.visible = true
	var t := get_tree().create_tween()
	t.tween_interval(1.5)
	t.tween_property(feedback_label, "modulate:a", 0.0, 0.5)


# ── Shell counter ─────────────────────────────────────────────────────

func _update_shell_counter() -> void:
	if shotgun:
		_update_shell_container(shell_container, shotgun.live_count(), shotgun.blank_count())
		if shell_container.visible:
			_animate_container(shell_container)


func _update_icon_container(container: Control, tex: Texture2D, count: int) -> void:
	for child in container.get_children():
		child.queue_free()
	for i in range(count):
		var tex_rect := TextureRect.new()
		tex_rect.texture = tex
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.custom_minimum_size = Vector2(22, 22)
		container.add_child(tex_rect)


func _update_intro_tray(live: int, blank: int) -> void:
	for child in slots_overlay.get_children():
		child.queue_free()

	const MAX_SLOTS := 8
	var total: int = min(live + blank, MAX_SLOTS)

	var shell_types: Array[String] = []
	for i in range(min(live, MAX_SLOTS)):
		shell_types.append("live")
	var blank_slots: int = min(blank, MAX_SLOTS - shell_types.size())
	for i in range(blank_slots):
		shell_types.append("blank")
	shell_types.shuffle()

	slots_overlay.clip_contents = true
	await get_tree().process_frame

	var tw: float = slots_overlay.size.x
	var th: float = slots_overlay.size.y

	const USABLE_LEFT_FRAC   := 0.035
	const USABLE_RIGHT_FRAC  := 0.965
	const SLOT_CENTER_Y_FRAC := 0.42
	const SLOT_OPEN_H_FRAC   := 0.62

	var usable_w: float   = (USABLE_RIGHT_FRAC - USABLE_LEFT_FRAC) * tw
	var slot_w: float     = usable_w / float(MAX_SLOTS)
	var icon_display_w: float = slot_w * 0.70
	var icon_display_h: float = th * SLOT_OPEN_H_FRAC * 0.85
	var rect_w: float = icon_display_h
	var rect_h: float = icon_display_w

	for i in range(total):
		var tex_rect := TextureRect.new()
		tex_rect.texture      = live_shell_texture if shell_types[i] == "live" else blank_shell_texture
		tex_rect.expand_mode  = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.size         = Vector2(rect_w, rect_h)
		tex_rect.pivot_offset = Vector2(rect_w / 2.0, rect_h / 2.0)
		tex_rect.rotation     = PI / 2.0

		var slot_left: float = USABLE_LEFT_FRAC * tw + i * slot_w
		var slot_cx: float   = slot_left + slot_w / 2.0
		var slot_cy: float   = SLOT_CENTER_Y_FRAC * th
		var target_x: float  = slot_cx - rect_w / 2.0
		var target_y: float  = slot_cy - rect_h / 2.0

		tex_rect.position = Vector2(target_x, target_y - th * 1.5)
		slots_overlay.add_child(tex_rect)

		var tween := get_tree().create_tween()
		tween.tween_interval(i * 0.07)
		tween.tween_property(tex_rect, "position", Vector2(target_x, target_y), 0.30) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)


func _update_shell_container(container: Control, live_count: int, blank_count: int) -> void:
	for child in container.get_children():
		child.queue_free()

	var shell_types := []
	for i in range(live_count):
		shell_types.append("live")
	for i in range(blank_count):
		shell_types.append("blank")
	shell_types.shuffle()

	for stype in shell_types:
		var tex_rect := TextureRect.new()
		tex_rect.texture = live_shell_texture if stype == "live" else blank_shell_texture
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.custom_minimum_size = Vector2(10, 25)
		container.add_child(tex_rect)


func _animate_container(container: Control) -> void:
	container.pivot_offset = container.size / 2.0
	var tween := get_tree().create_tween()
	tween.tween_property(container, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	tween.parallel().tween_property(container, "modulate", Color(1.5, 1.5, 1.5), 0.1)
	tween.parallel().tween_property(container, "modulate", Color.WHITE, 0.3)


# ── State changes ─────────────────────────────────────────────────────

func _on_state_changed(new_state) -> void:
	_set_buttons_visible(new_state == gsm.State.PLAYER_TURN)
	_update_shell_counter()

	match new_state:
		gsm.State.PLAYER_TURN:
			if gsm.is_ghost_round:
				_show_turn_indicator("YOUR TURN", Color(0.4, 0.8, 1.0))  # Ghostly cyan
			else:
				_show_turn_indicator("YOUR TURN", Color(0.2, 0.9, 0.3))
		gsm.State.DEALER_TURN:
			if gsm.is_ghost_round:
				_show_turn_indicator("DEALER'S TURN", Color(0.7, 0.3, 0.3))  # Muted red
			else:
				_show_turn_indicator("DEALER'S TURN", Color(0.9, 0.2, 0.2))
		gsm.State.RESOLVE_SHOT:
			_hide_turn_indicator()
		gsm.State.WIN:
			_hide_turn_indicator()
			await get_tree().process_frame
			get_tree().change_scene_to_file("res://Scenes/WinScreen.tscn")
		gsm.State.LOSE:
			_hide_turn_indicator()
			# Don't switch to LoseScreen if GSM is about to transition to ghost round
			# (only happens in classic mode, Round 3 death, not already ghost/resurrected)
			if gsm.game_mode == "classic" and gsm.round_system.current_round == 2 and not gsm.is_ghost_round and not gsm.is_resurrected_round3:
				return  # GSM will transition to GHOST_ROUND_START
			await get_tree().process_frame
			get_tree().change_scene_to_file("res://Scenes/LoseScreen.tscn")
		gsm.State.GHOST_ROUND_START:
			_hide_turn_indicator()
		gsm.State.RESURRECTION:
			_hide_turn_indicator()


func _show_turn_indicator(text: String, color: Color) -> void:
	if not turn_label:
		return
	turn_label.text = text
	turn_label.modulate = color
	turn_label.modulate.a = 0.0
	turn_label.visible = true
	var t := get_tree().create_tween()
	t.tween_property(turn_label, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	# Gentle pulsing glow
	t.tween_property(turn_label, "modulate:a", 0.7, 0.6).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(turn_label, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_IN_OUT)


func _hide_turn_indicator() -> void:
	if not turn_label:
		return
	var t := get_tree().create_tween()
	t.tween_property(turn_label, "modulate:a", 0.0, 0.15)


func _set_buttons_visible(visible_state: bool) -> void:
	shoot_self_btn.visible   = visible_state
	shoot_dealer_btn.visible = visible_state


# ── Ghost Round 4 HP display ──────────────────────────────────────────

## Player HP in ghost round: single glowing orb with pulsing animation.
## Color/brightness changes based on orb charge state.
func _update_ghost_player_hp(current: int) -> void:
	for child in player_hp_container.get_children():
		child.queue_free()

	# Stop any existing orb glow
	if _orb_glow_tween:
		_orb_glow_tween.kill()
		_orb_glow_tween = null

	if current <= 0:
		return  # Orb is shattered — show nothing

	# Determine orb appearance based on charge state
	var orb_charge: int = gsm.ghost_orb_charge if gsm else 0
	var orb_stable: bool = gsm.ghost_orb_stabilized if gsm else false

	var base_color: Color
	var pulse_bright: Color
	var pulse_dim: Color
	var orb_size: float = 32.0

	if orb_stable:
		# Stabilized: bright golden-cyan glow, larger
		base_color   = Color(0.8, 1.0, 0.4, 1.0)
		pulse_bright = Color(1.0, 1.2, 0.6, 1.0)
		pulse_dim    = Color(0.6, 0.9, 0.3, 0.9)
		orb_size     = 38.0
	elif orb_charge == 2:
		# 2 charges: brighter, almost ready
		base_color   = Color(0.6, 1.0, 0.8, 1.0)
		pulse_bright = Color(0.8, 1.15, 1.0, 1.0)
		pulse_dim    = Color(0.45, 0.85, 0.7, 0.9)
		orb_size     = 36.0
	elif orb_charge == 1:
		# 1 charge: slightly brighter cyan
		base_color   = Color(0.5, 0.95, 1.1, 1.0)
		pulse_bright = Color(0.7, 1.1, 1.3, 1.0)
		pulse_dim    = Color(0.35, 0.75, 0.9, 0.85)
		orb_size     = 34.0
	else:
		# 0 charges: dim, fragile
		base_color   = Color(0.4, 0.9, 1.0, 1.0)
		pulse_bright = Color(0.6, 1.0, 1.2, 1.0)
		pulse_dim    = Color(0.3, 0.7, 0.9, 0.8)
		orb_size     = 32.0

	var tex_rect := TextureRect.new()
	if _orb_texture:
		tex_rect.texture = _orb_texture
	else:
		tex_rect.texture = hp_texture  # fallback
	tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex_rect.custom_minimum_size = Vector2(orb_size, orb_size)
	tex_rect.modulate = base_color
	player_hp_container.add_child(tex_rect)

	# Pulsing glow animation (speed varies by state)
	var pulse_speed: float = 0.5 if orb_stable else 0.8
	_orb_glow_tween = get_tree().create_tween().set_loops()
	_orb_glow_tween.tween_property(tex_rect, "modulate", pulse_bright, pulse_speed).set_ease(Tween.EASE_IN_OUT)
	_orb_glow_tween.tween_property(tex_rect, "modulate", pulse_dim, pulse_speed).set_ease(Tween.EASE_IN_OUT)
	var scale_tween := get_tree().create_tween().set_loops()
	scale_tween.tween_property(tex_rect, "custom_minimum_size", Vector2(orb_size + 4, orb_size + 4), pulse_speed).set_ease(Tween.EASE_IN_OUT)
	scale_tween.tween_property(tex_rect, "custom_minimum_size", Vector2(orb_size, orb_size), pulse_speed).set_ease(Tween.EASE_IN_OUT)


## Visual feedback when orb absorbs a blank (partial charge).
func show_orb_charge(charge: int) -> void:
	_flash_feedback("ORB CHARGE: %d/3" % charge, Color(0.4, 0.9, 1.0))
	# Refresh the player HP display to show updated orb appearance
	if gsm and gsm.player:
		_update_ghost_player_hp(gsm.player.current_hp)


## Visual feedback when the orb stabilizes (2/2 charges reached).
func show_orb_stabilized() -> void:
	# Flash a dramatic message
	_flash_feedback("★ ORB STABILIZED ★", Color(1.0, 1.0, 0.3))
	# Refresh orb visual
	if gsm and gsm.player:
		_update_ghost_player_hp(gsm.player.current_hp)


## Dealer HP in ghost round: single ∞ symbol
func _update_ghost_dealer_hp() -> void:
	for child in dealer_hp_container.get_children():
		child.queue_free()

	var tex_rect := TextureRect.new()
	if _infinite_texture:
		tex_rect.texture = _infinite_texture
	else:
		# Fallback: use a label
		var lbl := Label.new()
		lbl.text = "∞"
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.modulate = Color(0.9, 0.3, 0.3)
		dealer_hp_container.add_child(lbl)
		return
	tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex_rect.custom_minimum_size = Vector2(36, 28)
	tex_rect.modulate = Color(0.9, 0.3, 0.3, 1.0)  # Red tint
	dealer_hp_container.add_child(tex_rect)


# ── Resurrection animation ────────────────────────────────────────────

func play_resurrection_animation() -> void:
	# Create a full-screen overlay for the animation
	var overlay := ColorRect.new()
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.color = Color(1, 1, 1, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 100
	get_node("UI").add_child(overlay)

	# Create the "YOU HAVE RETURNED" label
	var rez_label := Label.new()
	rez_label.text = "YOU HAVE RETURNED"
	rez_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rez_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	rez_label.anchors_preset = Control.PRESET_FULL_RECT
	rez_label.add_theme_font_size_override("font_size", 52)
	if ResourceLoader.exists("res://Assets/UI/Creepster-Regular.ttf"):
		rez_label.add_theme_font_override("font", load("res://Assets/UI/Creepster-Regular.ttf"))
	rez_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	rez_label.add_theme_color_override("font_shadow_color", Color(0, 0.2, 0.3))
	rez_label.add_theme_constant_override("shadow_offset_x", 3)
	rez_label.add_theme_constant_override("shadow_offset_y", 3)
	rez_label.modulate.a = 0.0
	rez_label.z_index = 101
	get_node("UI").add_child(rez_label)

	# Phase 1: White flash
	var flash_tween := get_tree().create_tween()
	flash_tween.tween_property(overlay, "color:a", 1.0, 0.15)
	await flash_tween.finished
	await get_tree().create_timer(0.3).timeout

	# Phase 2: Fade to dark
	var dark_tween := get_tree().create_tween()
	dark_tween.tween_property(overlay, "color", Color(0.02, 0.05, 0.08, 1.0), 0.5)
	await dark_tween.finished

	# Phase 3: Show text
	var text_tween := get_tree().create_tween()
	text_tween.tween_property(rez_label, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	await text_tween.finished
	await get_tree().create_timer(2.0).timeout

	# Phase 4: Fade everything out
	var out_tween := get_tree().create_tween()
	out_tween.tween_property(overlay, "color:a", 0.0, 0.8)
	out_tween.parallel().tween_property(rez_label, "modulate:a", 0.0, 0.8)
	await out_tween.finished

	# Cleanup
	overlay.queue_free()
	rez_label.queue_free()


# ── Ghost Ally Whisper (Resurrected Round 3) ──────────────────────────

func show_ghost_whisper(shell: String) -> void:
	if not _ghost_whisper_texture:
		# Fallback: just use the feedback label
		var text := "👻 Next: " + ("🔴 LIVE" if shell == "LIVE" else "⚪ BLANK")
		_flash_feedback(text, Color(0.4, 0.8, 1.0))
		return

	# Create whisper visual overlay
	var whisper_container := Control.new()
	whisper_container.anchors_preset = Control.PRESET_FULL_RECT
	whisper_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	whisper_container.z_index = 50
	get_node("UI").add_child(whisper_container)

	# Ghost sprite
	var ghost_tex := TextureRect.new()
	ghost_tex.texture = _ghost_whisper_texture
	ghost_tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	ghost_tex.custom_minimum_size = Vector2(60, 80)
	ghost_tex.position = Vector2(100, 50)
	ghost_tex.modulate = Color(0.5, 0.8, 1.0, 0.0)
	whisper_container.add_child(ghost_tex)

	# Shell icon next to ghost
	var shell_icon := TextureRect.new()
	shell_icon.texture = live_shell_texture if shell == "LIVE" else blank_shell_texture
	shell_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	shell_icon.custom_minimum_size = Vector2(20, 20)
	shell_icon.position = Vector2(170, 80)
	shell_icon.modulate = Color(1, 1, 1, 0)
	whisper_container.add_child(shell_icon)

	# "NEXT:" label
	var next_label := Label.new()
	next_label.text = "NEXT"
	next_label.add_theme_font_size_override("font_size", 16)
	next_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	next_label.position = Vector2(160, 60)
	next_label.modulate.a = 0.0
	whisper_container.add_child(next_label)

	# Fade in
	var fade_in := get_tree().create_tween()
	fade_in.tween_property(ghost_tex, "modulate:a", 0.6, 0.4).set_ease(Tween.EASE_OUT)
	fade_in.parallel().tween_property(shell_icon, "modulate:a", 1.0, 0.4)
	fade_in.parallel().tween_property(next_label, "modulate:a", 0.8, 0.4)
	await fade_in.finished

	# Hold for 2 seconds
	await get_tree().create_timer(2.0).timeout

	# Fade out
	var fade_out := get_tree().create_tween()
	fade_out.tween_property(whisper_container, "modulate:a", 0.0, 0.5)
	await fade_out.finished

	whisper_container.queue_free()
