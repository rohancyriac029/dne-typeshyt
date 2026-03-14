extends Node

# Injected by MainScene
var gsm: Node


func take_turn() -> void:
	# 0 = shoot player, 1 = shoot self
	if randi() % 2 == 0:
		print("[Dealer] Shoots PLAYER")
		gsm.dealer_shoot("player")
	else:
		print("[Dealer] Shoots SELF")
		gsm.dealer_shoot("dealer")
