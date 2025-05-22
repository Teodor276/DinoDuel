extends Control

var easy_selected = false
var med_selected = false
var hard_selected = false
var train_selected = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("GameType")


func _on_easy_button_pressed() -> void:
	AiChoice.easy_selected = true
	AiChoice.med_selected = false
	AiChoice.hard_selected = false
	AiChoice.train_selected = false
	print(AiChoice.easy_selected)
	print(AiChoice.med_selected)
	print(AiChoice.hard_selected)
	print(AiChoice.train_selected)
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("PlayGameAI")


func _on_med_button_pressed() -> void:
	AiChoice.easy_selected = false
	AiChoice.med_selected = true
	AiChoice.hard_selected = false
	AiChoice.train_selected = false
	print(AiChoice.easy_selected)
	print(AiChoice.med_selected)
	print(AiChoice.hard_selected)
	print(AiChoice.train_selected)
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("PlayGameAI")


func _on_hard_button_pressed() -> void:
	AiChoice.easy_selected = false
	AiChoice.med_selected = false
	AiChoice.hard_selected = true
	AiChoice.train_selected = false
	print(AiChoice.easy_selected)
	print(AiChoice.med_selected)
	print(AiChoice.hard_selected)
	print(AiChoice.train_selected)
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("PlayGameAI")


func _on_train_button_pressed() -> void:
	AiChoice.easy_selected = false
	AiChoice.med_selected = false
	AiChoice.hard_selected = false
	AiChoice.train_selected = true
	print(AiChoice.easy_selected)
	print(AiChoice.med_selected)
	print(AiChoice.hard_selected)
	print(AiChoice.train_selected)
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("PlayGameAI")


func _on_button_hover() -> void:
	get_parent().get_node("ButtonHoverSound").play()
