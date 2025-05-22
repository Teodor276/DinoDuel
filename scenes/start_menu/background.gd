extends Control

var background
var background2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	background = get_node("background")
	background2 = get_node("background2")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (background.position.x == -1920):
		background.position.x = 1920
	if (background2.position.x == -1920):
		background2.position.x = 1920
	background.position.x -= 0.5
	background2.position.x -= 0.5
