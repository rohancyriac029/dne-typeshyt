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


func setup_item_system(p_item_system: Node) -> void:
	item_system = p_item_system
	item_system.player_items_changed.connect(update_player_items)
	item_system.dealer_items_changed.connect(update_dealer_items)


# ── Intro sequence ────────────────────────────────────────────────────

func show_intro_sequence(title: String, live: int, blank: int) -> void:
	shell_container.hide()

	round_label.text = title
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
	_update_hp_container(player_hp_container, regular if regular >= 0 else current, faded)
	_animate_container(player_hp_container)
	_update_shell_counter()


func _on_dealer_hp_changed(current: int, _maximum: int, regular: int = -1, faded: int = 0) -> void:
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
			_show_turn_indicator("YOUR TURN", Color(0.2, 0.9, 0.3))
		gsm.State.DEALER_TURN:
			_show_turn_indicator("DEALER'S TURN", Color(0.9, 0.2, 0.2))
		gsm.State.RESOLVE_SHOT:
			_hide_turn_indicator()
		gsm.State.WIN:
			_hide_turn_indicator()
			await get_tree().process_frame
			get_tree().change_scene_to_file("res://Scenes/WinScreen.tscn")
		gsm.State.LOSE:
			_hide_turn_indicator()
			await get_tree().process_frame
			get_tree().change_scene_to_file("res://Scenes/LoseScreen.tscn")


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
