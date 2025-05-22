extends Control

@onready var dino_list_1 := [$layout/"p1 character select"/"char preview"/olaf,
						   $layout/"p1 character select"/"char preview"/mort,
						   $layout/"p1 character select"/"char preview"/loki,
						   $layout/"p1 character select"/"char preview"/nico,
							$layout/"p1 character select"/"char preview"/kuro]

@onready var dino_list_2 := [$layout/"p2 character select"/"char preview"/olaf,
						   $layout/"p2 character select"/"char preview"/mort,
						   $layout/"p2 character select"/"char preview"/loki,
						   $layout/"p2 character select"/"char preview"/nico,
							$layout/"p2 character select"/"char preview"/kuro]

@onready var start_button := $"start game"/Button
@onready var loading_screen = get_node("LoadingScreenLayer/LoadingScreen")

var active_index_1: int = 0
var active_index_2: int = 1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if active_index_1 == active_index_2:
		start_button.disabled = true
	else:
		start_button.disabled = false


func _on_back_button_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("GameType")


func _on_start_button_pressed() -> void:
	loading_screen.play_animation()
	get_parent().get_node("ButtonClickSound").play()
	GlobalVars.left_choice = active_index_1
	GlobalVars.right_choice = active_index_2
	await get_tree().create_timer(2.65).timeout
	get_tree().change_scene_to_file("res://scenes/local_game/local_game.tscn")


func _on_button_hover() -> void:
	get_parent().get_node("ButtonHoverSound").play()


func update_active_dino() -> void:
	for i in dino_list_1.size():
		dino_list_1[i].visible = (i == active_index_1)
	
	for i in dino_list_2.size():
		dino_list_2[i].visible = (i == active_index_2)


func _on_move_right_left_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	active_index_1 = (active_index_1 + 1) % dino_list_1.size()
	update_active_dino()


func _on_move_left_left_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	active_index_1 = (active_index_1 - 1 + dino_list_1.size()) % dino_list_1.size()
	update_active_dino()


func _on_move_right_right_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	active_index_2 = (active_index_2 + 1) % dino_list_2.size()
	update_active_dino()


func _on_move_left_right_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	active_index_2 = (active_index_2 - 1 + dino_list_2.size()) % dino_list_2.size()
	update_active_dino()


func _on_button_mouse_entered_start() -> void:
	if start_button.disabled == true:
		return
	get_parent().get_node("ButtonHoverSound").play()
