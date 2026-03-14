extends CanvasLayer

# Injected via setup()
var gsm: Node
var shotgun: Node
var player_controller: Node

@onready var intro_panel: ColorRect = $IntroPanel
@onready var round_label: Label = $IntroPanel/RoundLabel
@onready var count_label: Label = $IntroPanel/CountLabel
@onready var slots_overlay: Control = $IntroPanel/TrayContainer/SlotsOverlay

@onready var player_hp_container: HBoxContainer = $UI/PlayerHPContainer
@onready var dealer_hp_container: HBoxContainer = $UI/DealerHPContainer
@onready var shell_container: VBoxContainer = $UI/ShellContainer
@onready var shoot_self_btn: TextureButton = $UI/ShootSelfButton
@onready var shoot_dealer_btn: TextureButton = $UI/ShootDealerButton

var hp_texture = preload("res://Assets/UI/hp_icon.png")
var live_shell_texture = preload("res://Assets/Objects/live_shell_icon.png")
var blank_shell_texture = preload("res://Assets/Objects/blank_shell_icon.png")

func setup(p_gsm: Node, p_shotgun: Node, p_controller: Node) -> void:
	gsm = p_gsm
	shotgun = p_shotgun
	player_controller = p_controller

	gsm.state_changed.connect(_on_state_changed)
	shoot_self_btn.pressed.connect(player_controller.on_shoot_self_pressed)
	shoot_dealer_btn.pressed.connect(player_controller.on_shoot_dealer_pressed)

	_set_buttons_visible(false)
	intro_panel.modulate.a = 0.0 # Hide intro panel by default


func show_intro_sequence(title: String, live: int, blank: int) -> void:
	# Hide main UI shell counter during intro just to be safe
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
	
	# Clear the intro shells so they don't linger in memory unseen
	for child in slots_overlay.get_children():
		child.queue_free()


func connect_player(player: Node) -> void:
	player.hp_changed.connect(_on_player_hp_changed)
	_on_player_hp_changed(player.current_hp, player.max_hp)


func connect_dealer(dealer: Node) -> void:
	dealer.hp_changed.connect(_on_dealer_hp_changed)
	_on_dealer_hp_changed(dealer.current_hp, dealer.max_hp)


func _on_player_hp_changed(current: int, _maximum: int) -> void:
	_update_icon_container(player_hp_container, hp_texture, current)
	_animate_container(player_hp_container)
	_update_shell_counter()


func _on_dealer_hp_changed(current: int, _maximum: int) -> void:
	_update_icon_container(dealer_hp_container, hp_texture, current)
	_animate_container(dealer_hp_container)
	_update_shell_counter()


func _update_shell_counter() -> void:
	if shotgun:
		_update_shell_container(shell_container, shotgun.live_count(), shotgun.blank_count())
		# Don't animate the main UI shell counter if it's currently hidden (e.g., during intro)
		if shell_container.visible:
			_animate_container(shell_container)


func _update_icon_container(container: Control, tex: Texture2D, count: int) -> void:
	# Clear old icons
	for child in container.get_children():
		child.queue_free()
		
	# Add new icons up to 'count'
	for i in range(count):
		var tex_rect = TextureRect.new()
		tex_rect.texture = tex
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.custom_minimum_size = Vector2(40, 40)
		container.add_child(tex_rect)


func _update_intro_tray(live: int, blank: int) -> void:
	# Clear existing shell icons
	for child in slots_overlay.get_children():
		child.queue_free()

	const MAX_SLOTS := 8
	var total: int = min(live + blank, MAX_SLOTS)

	# Build a shuffled list of which slots get live vs blank
	var shell_types: Array[String] = []
	for i in range(min(live, MAX_SLOTS)):
		shell_types.append("live")
	var blank_slots: int = min(blank, MAX_SLOTS - shell_types.size())
	for i in range(blank_slots):
		shell_types.append("blank")
	shell_types.shuffle()

	# Clip children to prevent shells from overflowing tray edges
	slots_overlay.clip_contents = true

	# Wait one frame so layout sizes are computed properly
	await get_tree().process_frame

	var tw: float = slots_overlay.size.x  # total tray width in pixels
	var th: float = slots_overlay.size.y  # total tray height in pixels

	# -------------------------------------------------------------------
	# Analysis of shell_trey.jpeg:
	#   Outer horizontal border : ~3.5% each side  → usable starts at 3.5%, ends at 96.5%
	#   8 equal slots occupy that 93% span       → each slot = 93%/8 = 11.625% wide
	#   Dividers between slots are very thin (~0.3% each), absorbed into equal spacing
	#   Vertical slot opening center              : ~42% from top of image
	#   Height of slot opening region             : ~65% of total height
	# -------------------------------------------------------------------
	const USABLE_LEFT_FRAC  := 0.035   # where slot area begins (fraction of tray width)
	const USABLE_RIGHT_FRAC := 0.965   # where slot area ends
	const SLOT_CENTER_Y_FRAC := 0.42   # vertical center of the slot openings
	const SLOT_OPEN_H_FRAC  := 0.62   # fraction of tray height the openings span

	var usable_w: float = (USABLE_RIGHT_FRAC - USABLE_LEFT_FRAC) * tw
	var slot_w: float   = usable_w / float(MAX_SLOTS)

	# Icon displayed size:  ~70% of one slot wide, 85% of the slot opening height
	var icon_display_w: float = slot_w * 0.70
	var icon_display_h: float = th * SLOT_OPEN_H_FRAC * 0.85

	# Because the shell texture is horizontal (lying flat), we rotate 90° to stand it up.
	# TextureRect.size must use the SWAPPED dimensions before rotation.
	var rect_w: float = icon_display_h  # this becomes the visual HEIGHT after 90° rotation
	var rect_h: float = icon_display_w  # this becomes the visual WIDTH  after 90° rotation

	for i in range(total):
		var tex_rect := TextureRect.new()
		tex_rect.texture = live_shell_texture if shell_types[i] == "live" else blank_shell_texture
		tex_rect.expand_mode   = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		tex_rect.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.size          = Vector2(rect_w, rect_h)
		tex_rect.pivot_offset  = Vector2(rect_w / 2.0, rect_h / 2.0)
		tex_rect.rotation      = PI / 2.0

		# Centre of this slot in overlay-local pixel coords
		var slot_left: float   = USABLE_LEFT_FRAC * tw + i * slot_w
		var slot_cx: float     = slot_left + slot_w / 2.0
		var slot_cy: float     = SLOT_CENTER_Y_FRAC * th

		# Position so the pivot (centre of rect) lands at the slot centre
		var target_x: float    = slot_cx - rect_w / 2.0
		var target_y: float    = slot_cy - rect_h / 2.0

		# Start above the tray for drop-in animation
		tex_rect.position = Vector2(target_x, target_y - th * 1.5)
		slots_overlay.add_child(tex_rect)

		# Staggered bounce drop-in
		var tween := get_tree().create_tween()
		tween.tween_interval(i * 0.07)
		tween.tween_property(tex_rect, "position", Vector2(target_x, target_y), 0.30) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)


func _update_shell_container(container: Control, live_count: int, blank_count: int) -> void:
	for child in container.get_children():
		child.queue_free()
		
	# Create an array of shell types and shuffle it so the visual order is random
	var shell_types = []
	for i in range(live_count):
		shell_types.append("live")
	for i in range(blank_count):
		shell_types.append("blank")
		
	shell_types.shuffle()
		
	for stype in shell_types:
		var tex_rect = TextureRect.new()
		tex_rect.texture = live_shell_texture if stype == "live" else blank_shell_texture
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.custom_minimum_size = Vector2(10, 25) # Made smaller for a vertical stack
		container.add_child(tex_rect)


func _animate_container(container: Control) -> void:
	container.pivot_offset = container.size / 2.0
	
	var tween = get_tree().create_tween()
	tween.tween_property(container, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	
	# Small brightness flash
	tween.parallel().tween_property(container, "modulate", Color(1.5, 1.5, 1.5), 0.1) 
	tween.parallel().tween_property(container, "modulate", Color.WHITE, 0.3)


func _on_state_changed(new_state) -> void:
	_set_buttons_visible(new_state == gsm.State.PLAYER_TURN)
	_update_shell_counter()

	match new_state:
		gsm.State.WIN:
			await get_tree().process_frame
			get_tree().change_scene_to_file("res://Scenes/WinScreen.tscn")
		gsm.State.LOSE:
			await get_tree().process_frame
			get_tree().change_scene_to_file("res://Scenes/LoseScreen.tscn")


func _set_buttons_visible(visible_state: bool) -> void:
	shoot_self_btn.visible = visible_state
	shoot_dealer_btn.visible = visible_state
