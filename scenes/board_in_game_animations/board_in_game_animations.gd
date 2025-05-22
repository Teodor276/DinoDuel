extends Node2D

var camera_moving = false
var fliped = false
var current_player


func _ready():
	pass

func play_board_smoke(target_position: Vector2):
	position = target_position
	$AnimatedSprite2D.play("board_smoke")
