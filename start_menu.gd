extends Control

var background
var background2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	background = get_node("background")
	background2 = get_node("background2")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if (background.position.x == -1920):
		background.position.x = 1920
	if (background2.position.x == -1920):
		background2.position.x = 1920
	background.position.x -= 0.5
	background2.position.x -= 0.5


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu/game_type.tscn")


func _on_help_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu/help.tscn")


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu/settings.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
