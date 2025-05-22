extends Control


@onready var dino_list := [$layout/"p1 character select"/"char preview"/olaf,
						   $layout/"p1 character select"/"char preview"/mort,
						   $layout/"p1 character select"/"char preview"/loki,
						   $layout/"p1 character select"/"char preview"/nico]

var active_index: int = 0
@onready var loading_screen = get_node("LoadingScreenLayer/LoadingScreen")



func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("AiChoice")


func _on_start_button_pressed() -> void:
	loading_screen.play_animation()
	print(AiChoice.easy_selected)
	print(AiChoice.med_selected)
	print(AiChoice.hard_selected)
	print(AiChoice.train_selected)
	get_parent().get_node("ButtonClickSound").play()
	GlobalVars.left_choice = active_index
	GlobalVars.right_choice = 4
	await get_tree().create_timer(2.65).timeout
	get_tree().change_scene_to_file("res://scenes/play_game_ai_net/play_game_ai_net.tscn")


func _on_button_hover() -> void:
	get_parent().get_node("ButtonHoverSound").play()


func update_active_dino() -> void:
	for i in dino_list.size():
		dino_list[i].visible = (i == active_index)


func _on_move_right_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	active_index = (active_index + 1) % dino_list.size()
	update_active_dino()


func _on_move_left_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	active_index = (active_index - 1 + dino_list.size()) % dino_list.size()
	update_active_dino()
