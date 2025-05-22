extends RefCounted  
class_name QuitDialog

var t
var ai_running

func dialog_confirmed(node: Node):
	GlobalVars.going_back_to_main_menu = true
	if ai_running and t.is_started():
			t.wait_to_finish()  # Make sure the previous thread has finished before starting a new one
	
	
	if GlobalVars.instance_script and GlobalVars.instance_script.get_parent():
		GlobalVars.instance_script.get_parent().remove_child(GlobalVars.instance_script)
		GlobalVars.instance_script.queue_free()
		GlobalVars.instance_script = null
	
	AiChoice.easy_selected = false
	AiChoice.med_selected = false
	AiChoice.hard_selected = false

	node.get_tree().change_scene_to_file("res://scenes/start_menu/start_menu.tscn")

func show_remove_confirmation_dialog(parent: Node, ai_thread, ai_running2): # for files with one thread
	t = ai_thread
	ai_running = ai_running2
	
	var dialog = ConfirmationDialog.new()
	
	dialog.title = "Quit the game?" 
	dialog.dialog_text = "Are you sure you want to quit the game?\nThe game will not be saved."
	dialog.get_ok_button().text = "Yes"
	dialog.min_size = Vector2(300, 100)

	await parent.get_tree().process_frame
	
	var label = dialog.get_label()
	if label:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER  
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	dialog.confirmed.connect(func(): dialog_confirmed(parent)) 
		
	parent.add_child(dialog)
	dialog.popup_centered()  
	dialog.show()
