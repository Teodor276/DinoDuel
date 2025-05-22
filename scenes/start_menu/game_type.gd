extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("Menu")


func _on_local_button_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("PlayGameLocal")


func _on_online_button_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("PlayGameOnline")


func _on_ai_button_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("AiChoice")


func _on_button_hover() -> void:
	get_parent().get_node("ButtonHoverSound").play()
