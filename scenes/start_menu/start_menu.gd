extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AiChoice.easy_selected = false
	AiChoice.med_selected = false
	AiChoice.hard_selected = false
	
	if GlobalVars.instance_script and GlobalVars.instance_script.get_parent():
		GlobalVars.instance_script.get_parent().remove_child(GlobalVars.instance_script)
		GlobalVars.instance_script.queue_free()
		GlobalVars.instance_script = null
	
	GlobalVars.lobby_phase = true 
	GlobalVars.game_play_phase = false

	GlobalVars.is_networking_game_started = false

	GlobalVars.is_instance_server = false
	GlobalVars.instance_first = false

	GlobalVars.instance_script = null

	GlobalVars.local_ip = null
	GlobalVars.other_instance_local_ip = null
	GlobalVars.room_name = null


	GlobalVars.send_room_name = false
	GlobalVars.flag_stop_room_name = false

	GlobalVars.selected_room_to_join = null

	GlobalVars.found_other_instance = false
	GlobalVars.going_back_to_main_menu = false

	# lobbying
	GlobalVars.room_names = []
	GlobalVars.room_ip = []
	GlobalVars.goes_first = []
	GlobalVars.last_room_size = 0
	GlobalVars.c_sent_at = null

	
	# 2) Kick off its default animation (the one set in the Inspector's Animation dropdown):
	
	# and if you still have an AnimationPlayer for other stuff:
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("GameType")


func _on_help_button_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("Help")


func _on_settings_button_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("Settings")


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_button_hover() -> void:
	get_parent().get_node("ButtonHoverSound").play()
