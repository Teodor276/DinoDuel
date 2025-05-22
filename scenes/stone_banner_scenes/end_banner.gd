extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu/menu_global_manager.tscn")


func _on_close_pressed() -> void:
	get_node("ButtonClickSound").play()
	visible = false


func _on_main_menu_mouse_entered() -> void:
	get_node("ButtonHoverSound").play()


func _on_close_mouse_entered() -> void:
	get_node("ButtonHoverSound").play()
