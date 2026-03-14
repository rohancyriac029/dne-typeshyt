extends Node

# Injected by MainScene
var gsm: Node


func on_shoot_self_pressed() -> void:
	gsm.player_shoot("player")


func on_shoot_dealer_pressed() -> void:
	gsm.player_shoot("dealer")
