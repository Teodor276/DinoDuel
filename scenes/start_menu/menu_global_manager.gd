extends Node

var default_screen = "Menu"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(has_node("Menu"))
	call_deferred("loadScene");


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func loadScene(toLoad: String = default_screen) -> void:
	get_node("Menu").visible = false
	get_node("AiChoice").visible = false
	get_node("GameType").visible = false
	get_node("Help").visible = false
	get_node("Settings").visible = false
	get_node("PlayGameLocal").visible = false
	get_node("PlayGameAI").visible = false
	get_node("PlayGameOnline").visible = false
	
	get_node(toLoad).visible = true
	
func transition(toLoad: String) -> void:
	#run transitionOut
	loadScene(toLoad)
	#run transitionIn
