extends Control

var start_game
var ai_easy
var ai_med
var ai_hard
var ai_train
var easy_selected = false
var med_selected = false
var hard_selected = false
var train_selected = false
var online_selected = false
var ai_selected = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_game = get_node("layout/game options/start game")
	ai_easy = get_node("layout/game options/ai easy")
	ai_med = get_node("layout/game options/ai medium")
	ai_hard = get_node("layout/game options/ai hard")
	ai_train = get_node("layout/game options/ai train")
	
	ai_easy.visible = false
	ai_med.visible = false
	ai_hard.visible = false
	ai_train.visible = false
	start_game.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_button_pressed() -> void:
	if (easy_selected):
		get_tree().change_scene_to_file("res://scenes/fake_ai/fake_ai.tscn")
	elif (med_selected):
		get_tree().change_scene_to_file("res://scenes/medium_ai/medium_ai.tscn")
	elif (hard_selected):
		get_tree().change_scene_to_file("res://scenes/hard_ai/hard_ai.tscn")
	elif (train_selected):
		get_tree().change_scene_to_file("res://scenes/train_ai/train_ai.tscn")
	elif (online_selected):
		pass
	

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu/game_type.tscn")

func _on_online_button_pressed() -> void:
	start_game.visible = true
	online_selected = true
	
	ai_easy.visible = false
	ai_med.visible = false
	ai_hard.visible = false
	ai_train.visible = false
	ai_selected = false
	easy_selected = false
	med_selected = false
	hard_selected = false
	train_selected = false


func _on_ai_versus_button_pressed() -> void:
	ai_selected = true
	start_game.visible = false
	ai_easy.visible = true
	ai_med.visible = true
	ai_hard.visible = true
	ai_train.visible = true
	online_selected = false


func _on_easy_button_pressed() -> void:
	start_game.visible = true
	easy_selected = true


func _on_med_button_pressed() -> void:
	start_game.visible = true
	med_selected = true


func _on_hard_button_pressed() -> void:
	start_game.visible = true
	hard_selected = true


func _on_train_button_pressed() -> void:
	start_game.visible = true
	train_selected = true
