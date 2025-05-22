extends Control

var input_popup: InputPopup

var contacting_popup: Panel = null
var not_available_popup: Panel = null
var wait_popup: Panel = null
var connect_timer := Timer.new()

@onready var loading_screen = get_node("LoadingScreenLayer/LoadingScreen")


@onready var dino_list := [$layout/"p1 character select"/"char preview"/olaf,
						   $layout/"p1 character select"/"char preview"/mort,
						   $layout/"p1 character select"/"char preview"/loki,
						   $layout/"p1 character select"/"char preview"/nico]

var active_index: int = 0


var lobby_scene = preload("res://scenes/lobby_scene/lobby_scene.tscn")
var lobby_instance = null

var lobby_final_connection_confirmation_sent = false
var game_scene_loaded = false

var reseting = false

signal room_name_submitted

@onready var create_room_button = get_node("create_room")
@onready var join_room_button = get_node("join_room")
@onready var create_room_input = get_node("CreateRoomInput")
@onready var room_name_chars_remaining = get_node("CreateRoomInput/CharsRemainingLabel")
@onready var create_room_input_button = get_node("CreateRoomInput/CreateRoomButton")
@onready var create_room_input_text = get_node("CreateRoomInput/CreateRoomText")

func _ready():
	pass
	
func _process(delta):
	if reseting:
		return
		
	if GlobalVars.lobby_phase == true:
		if GlobalVars.is_instance_server == false and GlobalVars.last_room_size != GlobalVars.room_names.size() and lobby_instance:
			lobby_instance.update_server_list()
			
		if GlobalVars.is_instance_server == false and lobby_final_connection_confirmation_sent == false and GlobalVars.selected_room_to_join:
			var room_to_join = GlobalVars.room_names[GlobalVars.selected_room_to_join[0]]
			GlobalVars.other_instance_local_ip = GlobalVars.room_ip[GlobalVars.selected_room_to_join[0]]
			
			var msg = "C" + "|" + room_to_join

			GlobalVars.instance_script.send_broadcast(msg)
			lobby_final_connection_confirmation_sent = true
			_contacting_server()
			GlobalVars.c_sent_at = Time.get_ticks_msec()
			create_response_timer()
			
		
		
		if GlobalVars.found_other_instance == true and GlobalVars.is_instance_server == true and not GlobalVars.c_sent_at:
			var msg = "S"
			GlobalVars.instance_script.send_broadcast(msg)
			lobby_final_connection_confirmation_sent = true
			GlobalVars.lobby_phase = false
		
		
		
	if GlobalVars.lobby_phase == false and game_scene_loaded == false:
		loading_screen.play_animation()
		if GlobalVars.is_instance_server == false:
			if GlobalVars.goes_first[GlobalVars.selected_room_to_join[0]] == "T":
				GlobalVars.instance_first = true
		
		AiChoice.easy_selected = false
		AiChoice.med_selected = false
		AiChoice.hard_selected = false
		
		GlobalVars.left_choice = active_index
		GlobalVars.right_choice = 4
		await get_tree().create_timer(2.65).timeout
		get_tree().change_scene_to_file("res://scenes/play_game_ai_net/play_game_ai_net.tscn")
		game_scene_loaded = true
		

func create_response_timer():
	connect_timer = Timer.new()
	connect_timer.wait_time = 2.0
	connect_timer.one_shot = true
	connect_timer.autostart = true
	add_child(connect_timer)
	connect_timer.connect("timeout", Callable(self, "_on_connect_timeout"))

func _on_connect_timeout():
	connect_timer.autostart = false

	reseting = true
	show_not_available_popup()	


func _start_broadcasting_server_name():
	var msg = "R" + "|" + GlobalVars.room_name + "|"
	if GlobalVars.instance_first == true:
		msg += "F"
	else:
		msg += "T"
	
	print("room")
	while GlobalVars.lobby_phase == true:
		if GlobalVars.instance_script == null:
			break
		GlobalVars.instance_script.send_broadcast(msg)
		if is_inside_tree():
			await get_tree().create_timer(1.0).timeout


func _on_back_button_pressed() -> void:		
	if GlobalVars.instance_script and GlobalVars.instance_script.get_parent():
		GlobalVars.instance_script.get_parent().remove_child(GlobalVars.instance_script)
		GlobalVars.instance_script.queue_free()
		GlobalVars.instance_script = null
		GlobalVars.lobby_phase = true
	
	GlobalVars.game_play_phase = false

	GlobalVars.is_networking_game_started = false

	GlobalVars.is_instance_server = false
	GlobalVars.instance_first = false

	GlobalVars.local_ip = null
	GlobalVars.other_instance_local_ip = null
	GlobalVars.room_name = null


	GlobalVars.send_room_name = false
	GlobalVars.flag_stop_room_name = false

	GlobalVars.selected_room_to_join = null

	GlobalVars.found_other_instance = false
	GlobalVars.going_back_to_main_menu = false

	# lobbying
	GlobalVars.room_names = []
	GlobalVars.room_ip = []
	GlobalVars.goes_first = []
	GlobalVars.last_room_size = 0

	GlobalVars.c_sent_at = null
	
	connect_timer = Timer.new()
	
	create_room_button.visible = true
	join_room_button.visible = true
	create_room_input.visible = false
	get_parent().get_node("ButtonClickSound").play()



	if is_instance_valid(lobby_instance) and lobby_instance is Node and lobby_instance.get_parent():
		lobby_instance.get_parent().remove_child(lobby_instance)
		lobby_instance.queue_free()
		
	lobby_instance = null

	lobby_scene = preload("res://scenes/lobby_scene/lobby_scene.tscn")
	lobby_final_connection_confirmation_sent = false
	game_scene_loaded = false
	
	hide_contacting_server_popup()
	
	if wait_popup:
		wait_popup.queue_free()
		wait_popup = null
	
	create_room_input_text.text = ""
	create_room_input_button.disabled = true
	room_name_chars_remaining.text = "0/25"
	
	
	contacting_popup = null
	not_available_popup = null
	wait_popup = null

	reseting = false
	
	
	get_parent().transition("GameType")




func _on_create_room_pressed() -> void:
	create_room_button.visible = false
	join_room_button.visible = false
	
	get_parent().get_node("ButtonClickSound").play()
	
	if is_instance_valid(lobby_instance) and lobby_instance is Node and lobby_instance.get_parent():
		lobby_instance.get_parent().remove_child(lobby_instance)
		lobby_instance.queue_free()
	
	if GlobalVars.instance_script and GlobalVars.instance_script.get_parent():
		GlobalVars.instance_script.get_parent().remove_child(GlobalVars.instance_script)
		GlobalVars.instance_script.queue_free()
		GlobalVars.instance_script = null
		GlobalVars.lobby_phase = true
		
	
	# set ai's to false
	AiChoice.easy_selected = false
	AiChoice.med_selected = false
	AiChoice.hard_selected = false
	# Create and store the instance
	GlobalVars.lobby_phase = true
	GlobalVars.instance_script = load("res://scripts/networking/udp_script.gd").new()
	if is_inside_tree():
		get_tree().get_root().add_child.call_deferred(GlobalVars.instance_script)
	
	GlobalVars.local_ip = GlobalVars.instance_script.get_valid_local_ip()
	
	create_room_input.visible = true
	

func _on_join_room_pressed() -> void:
	join_room_button.visible = false
	create_room_button.visible = false
	
	get_parent().get_node("ButtonClickSound").play()
	
	if is_instance_valid(lobby_instance) and lobby_instance is Node and lobby_instance.get_parent():
		lobby_instance.get_parent().remove_child(lobby_instance)
		lobby_instance.queue_free()
	
	if GlobalVars.instance_script and GlobalVars.instance_script.get_parent():
		GlobalVars.instance_script.get_parent().remove_child(GlobalVars.instance_script)
		GlobalVars.instance_script.queue_free()
		GlobalVars.instance_script = null
		GlobalVars.lobby_phase = true
	
		# set ai's to false
	AiChoice.easy_selected = false
	AiChoice.med_selected = false
	AiChoice.hard_selected = false
	# Create and store the instance
	GlobalVars.lobby_phase = true
	GlobalVars.instance_script = load("res://scripts/networking/udp_script.gd").new()
	get_tree().get_root().add_child.call_deferred(GlobalVars.instance_script)
	
	GlobalVars.local_ip = GlobalVars.instance_script.get_valid_local_ip()
		
	lobby_instance = lobby_scene.instantiate() 
	add_child(lobby_instance)


func _contacting_server() -> void:
	if contacting_popup == null:
		contacting_popup = Panel.new()
		
		contacting_popup.name = "ContactingPopup"
		contacting_popup.custom_minimum_size = Vector2(475, 150)
		contacting_popup.position = get_viewport().get_visible_rect().size / 2 - contacting_popup.custom_minimum_size / 2 + Vector2(400, 0)
		
		var texture = preload("res://assets/ui/04_Stone_Theme/Sprites/UI_Stone_Banner_Upward_01a.png")
		var stylebox = StyleBoxTexture.new()
		stylebox.texture = texture
		contacting_popup.add_theme_stylebox_override("panel", stylebox)

		var outer_margin := MarginContainer.new()
		outer_margin.add_theme_constant_override("margin_left", 33)
		outer_margin.add_theme_constant_override("margin_right", 27)
		outer_margin.add_theme_constant_override("margin_top", 50)
		outer_margin.add_theme_constant_override("margin_bottom", 60)
		outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		contacting_popup.add_child(outer_margin)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 10)
		outer_margin.add_child(vbox) 

		var label = Label.new()
		label.text = "Waiting for connection..."
		label.set("theme_override_colors/font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 40)
		var custom_font = preload("res://assets/Toriko.ttf")
		label.add_theme_font_override("font", custom_font)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(label)

		add_child(contacting_popup)

func hide_contacting_server_popup() -> void:
	if contacting_popup:
		contacting_popup.queue_free()
		contacting_popup = null

func show_waiting_for_join():
	if wait_popup == null:
		wait_popup = Panel.new()
		
		wait_popup.name = "WaitPopup"
		wait_popup.custom_minimum_size = Vector2(475, 150)
		if is_inside_tree():
			wait_popup.position = get_viewport().get_visible_rect().size / 2 - wait_popup.custom_minimum_size / 2 + Vector2(400, 0)
		
		var texture = preload("res://assets/ui/04_Stone_Theme/Sprites/UI_Stone_Banner_Upward_01a.png")
		var stylebox = StyleBoxTexture.new()
		stylebox.texture = texture
		wait_popup.add_theme_stylebox_override("panel", stylebox)

		var outer_margin := MarginContainer.new()
		outer_margin.add_theme_constant_override("margin_left", 33)
		outer_margin.add_theme_constant_override("margin_right", 27)
		outer_margin.add_theme_constant_override("margin_top", 50)
		outer_margin.add_theme_constant_override("margin_bottom", 60)
		outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		wait_popup.add_child(outer_margin)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 10)
		outer_margin.add_child(vbox) 

		var label = Label.new()
		label.text = "Waiting for connection..."
		label.set("theme_override_colors/font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 40)
		var custom_font = preload("res://assets/Toriko.ttf")
		label.add_theme_font_override("font", custom_font)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(label)
		
		add_child(wait_popup)

func show_not_available_popup() -> void:
	hide_contacting_server_popup()
	
	var popup_panel = Panel.new()
	
	popup_panel.custom_minimum_size = Vector2(475, 350)
	popup_panel.position = (get_viewport_rect().size - popup_panel.custom_minimum_size) / 2 + Vector2(400, 0)
	popup_panel.name = "NotAvailablePopup"
	
	var texture = preload("res://assets/ui/04_Stone_Theme/Sprites/UI_Stone_Banner_Upward_01a.png")
	var stylebox = StyleBoxTexture.new()
	stylebox.texture = texture
	popup_panel.add_theme_stylebox_override("panel", stylebox)

	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 35)
	outer_margin.add_theme_constant_override("margin_right", 35)
	outer_margin.add_theme_constant_override("margin_top", 125)
	outer_margin.add_theme_constant_override("margin_bottom", 125)
	outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_panel.add_child(outer_margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	outer_margin.add_child(vbox) 
	
	var message_label = Label.new()
	message_label.set("theme_override_colors/font_color", Color.WHITE)
	message_label.add_theme_font_size_override("font_size", 40)
	var custom_font = preload("res://assets/Toriko.ttf")
	message_label.add_theme_font_override("font", custom_font)
	message_label.text = "Connection lost. Press OK to return to game selection."
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(message_label)
	
	var ok_button = Button.new()
	ok_button.focus_mode = Control.FOCUS_NONE
	ok_button.flat = true
	ok_button.add_theme_font_override("font", custom_font)
	ok_button.text = "OK"
	ok_button.custom_minimum_size = Vector2(100, 40)
	ok_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	ok_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	ok_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())

	ok_button.add_theme_constant_override("hseparation", 0)
	ok_button.add_theme_constant_override("outline_size", 0)
	ok_button.add_theme_constant_override("content_margin_left", 0)
	ok_button.add_theme_constant_override("content_margin_right", 0)
	ok_button.add_theme_constant_override("content_margin_top", 0)
	ok_button.add_theme_constant_override("content_margin_bottom", 0)
	ok_button.add_theme_font_size_override("font_size", 40)
	ok_button.add_theme_font_override("font", custom_font)
	ok_button.set("theme_override_colors/font_color", Color.WHITE)
	ok_button.set("theme_override_colors/font_hover_color", Color.DIM_GRAY)
	vbox.add_child(ok_button)
	
	add_child(popup_panel)

	ok_button.connect("pressed", Callable(self, "_on_ok_button_pressed").bind(popup_panel))
	ok_button.connect("mouse_entered", func(): _on_button_hover())


func _on_ok_button_pressed(popup) -> void:
	get_parent().get_node("ButtonClickSound").play()
	if popup:
		popup.queue_free()
	_on_back_button_pressed()


func _on_create_room_button_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	create_room_input.visible = false
	
	if create_room_input_text.text == "CaP_4#ijk276!": #password
		get_tree().change_scene_to_file("res://scenes/ai_vs_ai_over_networking/ai_vs_ai_over_networking.tscn")
		return
		
	
	randomize()
	var rand_num = randi() % 2
	if rand_num == 0:
		GlobalVars.instance_first = true
	
	GlobalVars.room_name = create_room_input_text.text
	show_waiting_for_join()
	emit_signal("room_name_submitted")
	
	GlobalVars.is_instance_server = true
	GlobalVars.send_room_name = true
	_start_broadcasting_server_name()


func _on_create_room_text_text_changed(new_text: String) -> void:
	var is_only_spaces = true
	
	for char in create_room_input_text.text:
		if (char != " "):
			is_only_spaces = false
	
	if len(create_room_input_text.text) > 0 and len(create_room_input_text.text) <=25 and !is_only_spaces:
		create_room_input_button.disabled = false
	else:
		create_room_input_button.disabled = true
		
	# str() solution found at: https://godotforums.org/d/32997-int-to-string-conversion
	room_name_chars_remaining.text = str(len(create_room_input_text.text)) + "/25"


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


func _on_create_room_button_mouse_entered() -> void:
	if (!get_node("CreateRoomInput/CreateRoomButton").disabled):
		get_parent().get_node("ButtonHoverSound").play()
