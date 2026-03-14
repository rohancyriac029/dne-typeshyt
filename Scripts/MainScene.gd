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

	# ── Start game ──────────────────────────────────────────────
	gsm.change_state(gsm.State.ROUND_START)
