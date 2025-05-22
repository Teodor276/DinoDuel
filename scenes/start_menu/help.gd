extends Control

var instructions_panel
var instructions_panel_text
var video_player
var mort_animation
var kuro_animation
var swipe_left_button
var swipe_right_button

var current_instruction = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	# Code modeled after suggestion by Google's AI overview in response to:
	# "how to access children node's visibility properties godot"
	instructions_panel = get_node("InstructionsPanel")
	instructions_panel_text = get_node("InstructionsPanel/InstructionsLabel")
	video_player = get_node("InstructionsPanel/VideoPlayer")
	mort_animation = get_node("InstructionsPanel/Mort")
	kuro_animation = get_node("InstructionsPanel/Kuro")
	swipe_left_button = get_node("InstructionsPanel/SwipeLeft")
	swipe_right_button = get_node("InstructionsPanel/SwipeRight")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	current_instruction = 0
	video_player.stop()
	mort_animation.visible = true
	kuro_animation.visible = true
	instructions_panel_text.text = GlobalVars.game_instructions[current_instruction]
	
	swipe_left_button.disabled = true
	swipe_right_button.disabled = false
	
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("Menu")
	

func _on_swipe_left_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	
	if swipe_right_button.disabled == true:
		swipe_right_button.disabled = false
		
	if current_instruction > 0:
		current_instruction -= 1
	
	if current_instruction == 0:
		swipe_left_button.disabled = true
		
	instructions_panel_text.text = GlobalVars.game_instructions[current_instruction]
	
	if current_instruction:
		mort_animation.visible = false
		kuro_animation.visible = false
		video_player.stream = GlobalVars.help_videos[current_instruction - 1]
		# from video at: https://www.reddit.com/r/godot/comments/pv3irp/loading_videos_into_the_video_player_by_code/?rdt=64730
		video_player.play()
	else:
		video_player.stop()
		mort_animation.visible = true
		kuro_animation.visible = true


func _on_swipe_right_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	
	if swipe_left_button.disabled == true:
		swipe_left_button.disabled = false
	
	if current_instruction < GlobalVars.game_instructions.size() - 1:
		current_instruction += 1
	
	if current_instruction == GlobalVars.game_instructions.size() - 1:
		swipe_right_button.disabled = true
		
	instructions_panel_text.text = GlobalVars.game_instructions[current_instruction]
	
	if current_instruction:
		mort_animation.visible = false
		kuro_animation.visible = false
		video_player.stream = GlobalVars.help_videos[current_instruction - 1]
		video_player.play()
	else:
		video_player.stop()
		mort_animation.visible = true
		kuro_animation.visible = true
	

func _on_swipe_right_mouse_entered() -> void:
	if swipe_right_button.disabled == false:
		get_parent().get_node("ButtonHoverSound").play()


func _on_swipe_left_mouse_entered() -> void:
	if swipe_left_button.disabled == false:
		get_parent().get_node("ButtonHoverSound").play()


func _on_back_button_mouse_entered() -> void:
	get_parent().get_node("ButtonHoverSound").play()
