extends Node2D

signal finished_move_animation
var camera_moving = false
var fliped = false
var current_player

var dino_tile_offset = Vector2(-16, -1)

var left_user = 0
var right_ai_net = 1

var left_user_move = ""
var right_ai_net_move = ""

var left_user_idle = ""
var right_ai_net_idle = ""

var left_user_jump = ""
var right_ai_net_jump = ""

var left_user_born = ""
var right_ai_net_born = ""

var left_user_egg = ""
var right_ai_net_egg = ""

var left_user_hurt = ""
var right_ai_net_hurt = ""

func _ready():
	if GlobalVars.left_choice == 0:
		left_user_move = "olaf_move" 
		left_user_idle = "olaf_idle"
		left_user_jump = "olaf_jump"
		left_user_born = "olaf_born"
		left_user_egg = "olaf_back_to_egg"
		left_user_hurt = "olaf_hurt"
	elif GlobalVars.left_choice == 1:
		left_user_move = "mort_move" 
		left_user_idle = "mort_idle"
		left_user_jump = "mort_jump"
		left_user_born = "mort_born"
		left_user_egg = "mort_back_to_egg"
		left_user_hurt = "mort_hurt"
	elif GlobalVars.left_choice == 2:
		left_user_move = "loki_move" 
		left_user_idle = "loki_idle"
		left_user_jump = "loki_jump"
		left_user_born = "loki_born"
		left_user_egg = "loki_back_to_egg"
		left_user_hurt = "loki_hurt"
	elif GlobalVars.left_choice == 3:
		left_user_move = "nico_move" 
		left_user_idle = "nico_idle"
		left_user_jump = "nico_jump"
		left_user_born = "nico_born"
		left_user_egg = "nico_back_to_egg"
		left_user_hurt = "nico_hurt"
	elif GlobalVars.left_choice == 4:
		left_user_move = "kuro_move"
		left_user_idle = "kuro_idle"
		left_user_jump = "kuro_jump"
		left_user_born = "kuro_born"
		left_user_egg = "kuro_back_to_egg"
		left_user_hurt = "kuro_hurt"
	else:  # just a fallback, no actual selection possible
		left_user_move = "olaf_move" 
		left_user_idle = "olaf_idle"
		left_user_jump = "olaf_jump"
		left_user_born = "olaf_born"
		left_user_egg = "olaf_back_to_egg"
		left_user_hurt = "olaf_hurt"
	
	
	
	if GlobalVars.right_choice == 0:
		right_ai_net_move = "olaf_move" 
		right_ai_net_idle = "olaf_idle"
		right_ai_net_jump = "olaf_jump"
		right_ai_net_born = "olaf_born"
		right_ai_net_egg = "olaf_back_to_egg"
		right_ai_net_hurt = "olaf_hurt"
	elif GlobalVars.right_choice == 1:
		right_ai_net_move = "mort_move" 
		right_ai_net_idle = "mort_idle"
		right_ai_net_jump = "mort_jump"
		right_ai_net_born = "mort_born"
		right_ai_net_egg = "mort_back_to_egg"
		right_ai_net_hurt = "mort_hurt"
	elif GlobalVars.right_choice == 2:
		right_ai_net_move = "loki_move" 
		right_ai_net_idle = "loki_idle"
		right_ai_net_jump = "loki_jump"
		right_ai_net_born = "loki_born"
		right_ai_net_egg = "loki_back_to_egg"
		right_ai_net_hurt = "loki_hurt"
	elif GlobalVars.right_choice == 3:
		right_ai_net_move = "nico_move" 
		right_ai_net_idle = "nico_idle"
		right_ai_net_jump = "nico_jump"
		right_ai_net_born = "nico_born"
		right_ai_net_egg = "nico_back_to_egg"
		right_ai_net_hurt = "nico_hurt"
	elif GlobalVars.right_choice == 4:
		right_ai_net_move = "kuro_move"
		right_ai_net_idle = "kuro_idle"
		right_ai_net_jump = "kuro_jump"
		right_ai_net_born = "kuro_born"
		right_ai_net_egg = "kuro_back_to_egg"
		right_ai_net_hurt = "kuro_hurt"
	else: # just a fallback, no actual selection possible
		right_ai_net_move = "loki_move" 
		right_ai_net_idle = "loki_idle"
		right_ai_net_jump = "loki_jump"
		right_ai_net_born = "loki_born"
		right_ai_net_egg = "loki_back_to_egg"
		right_ai_net_hurt = "loki_hurt"
	
	
	
		

		
		

func move_dino(start_position: Vector2, target_position: Vector2, player: int): # 0 for left or user, 1 for right or ai/net
	position = start_position + dino_tile_offset
	target_position += dino_tile_offset
	
	current_player = player
	camera_moving = true

	# If moving left, flip the sprite; otherwise, ensure it faces right.
	if target_position.x < position.x:
		$AnimatedSprite2D.flip_h = true
		fliped = true
	else:
		$AnimatedSprite2D.flip_h = false
	
	if current_player == left_user:
		$AnimatedSprite2D.play(left_user_move)
	elif current_player == right_ai_net:
		$AnimatedSprite2D.play(right_ai_net_move)
	
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, 2.0)
	tween.finished.connect(_on_move_finished)
	
	if not is_inside_tree():
		return
	await finished_move_animation
	return

func _on_move_finished():
	if fliped:
		fliped = false
		$AnimatedSprite2D.flip_h = false

	camera_moving = false
	if current_player == left_user:
		$AnimatedSprite2D.play(left_user_idle)
	elif current_player == right_ai_net:
		$AnimatedSprite2D.play(right_ai_net_idle)
		
	emit_signal("finished_move_animation")


func kill_dino():
	if current_player == left_user:
		$AnimatedSprite2D.play(left_user_hurt)
	elif current_player == right_ai_net:
		$AnimatedSprite2D.play(right_ai_net_hurt)
	
		
func dino_give_birth(target_position: Vector2, player: int):
	position = target_position + dino_tile_offset
	
	current_player = player
	camera_moving = true
	if current_player == left_user:
		$AnimatedSprite2D.play(left_user_born)
	elif current_player == right_ai_net:
		$AnimatedSprite2D.play(right_ai_net_born)
	
	if not is_inside_tree():
		return
	await get_tree().create_timer(2.0).timeout
	
	camera_moving = false
	if current_player == left_user:
		$AnimatedSprite2D.play(left_user_idle)
	elif current_player == right_ai_net:
		$AnimatedSprite2D.play(right_ai_net_idle)

func on_select_jump():
	if current_player == left_user:
		$AnimatedSprite2D.play(left_user_jump)
	elif current_player == right_ai_net:
		$AnimatedSprite2D.play(right_ai_net_jump)

func back_to_idle():
	if current_player == left_user:
		$AnimatedSprite2D.play(left_user_idle)
	elif current_player == right_ai_net:
		$AnimatedSprite2D.play(right_ai_net_idle)

func back_to_egg():
	position += Vector2(2, 6)
	if current_player == left_user:
		$AnimatedSprite2D.play(left_user_egg)
	elif current_player == right_ai_net:
		$AnimatedSprite2D.play(right_ai_net_egg)
	
