extends TileMap

var networking  = load("res://scripts/networking/ai_vs_ai_networking.gd").new()
var grid_calculations = load("res://scripts/game_helpers/GridCalculations.gd").new()
var game_logic = load("res://scripts/game_helpers/game_rules_logic.gd").new()
var board_renders = load("res://scripts/renders_and_pop_ups/board_renders.gd").new()

var labels := {}
var board = {}
var middle_of_screen = Vector2(900, 550)
var move = ""
var uuid = ""

var ai_running = false
var ai_thread = Thread.new()
var ai_mutex = Mutex.new()
signal ai_move_completed


func _ready() -> void:
	add_child(networking)
	initial_centering_tilemap(middle_of_screen)
	change_tile_size(Vector2i(128, 128))
	GlobalVars.going_back_to_main_menu = false
	_play_ai_vs_ai()

func _input(event) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_W:  # Move UP
			position.y += 50  
		elif event.keycode == KEY_S:  # Move DOWN
			position.y -= 50  
		elif event.keycode == KEY_A:  # Move LEFT
			position.x += 50  
		elif event.keycode == KEY_D:  # Move RIGHT
			position.x -= 50 
		elif event.keycode == KEY_C:
			board_renders.center_board(self, middle_of_screen) # do i need this or not

func _process(_delta: float) -> void:
	pass

func _play_ai_vs_ai():
	#var s = "0,0|0,1|0,2|0,3|1,0|1,1|1,2|1,3|h"
	#var board = networking._parse_state(s) # -1,-1|1,-2|0,-2|0,-1
	
	
	#var move_axial = [ Vector2i(-1,-1), Vector2i(1,-2), Vector2i(0,-2), Vector2i(0,-1) ]
	#var move_oddq = []
	
	#for move in move_axial:
	#	var oddq = networking.axial_to_oddq(move.x, move.y)
	#	move_oddq.append(oddq)
	
	#for tile in board:
	#	set_cell(0, tile, 0, Vector2i(0, 0))
	#	
	#await get_tree().create_timer(2.0).timeout
	
	#or tile in move_oddq:
	#	set_cell(0, tile, 0, Vector2i(0, 0))
	
	#await get_tree().create_timer(10.0).timeout
	while true:
		if GlobalVars.going_back_to_main_menu:
			break
			
		print()
		print()
		
		move = null
		un_render_board()
		board = {}
		print("Requesting new state...")

		var board_and_id = await networking.get_networking_board()
		board = board_and_id[0]
		var action_id = board_and_id[1]



		# Possibly check game over

		# Render the board
		board_cell_rendering()
		# 3) Get and make the AI move
		
		
		if game_logic.game_over(board, _initial_stacks_placed()):
			print("Game has ended")
			continue
			
		get_and_make_ai_move()

		await ai_move_completed

		print("Sending move with action_id:", action_id, " move:", move)
		var winner = await networking.send_networking_move(move, action_id)
		
		if winner:
			if winner == "h" or winner == "t" or winner == "draw":
				print("game is done")
				for tile in board:
					create_or_update_label_1(tile, "", labels, self)

		# un_render_board()
		
		
func _initial_stacks_placed():
	var h = false
	var a = false
	
	for tile in board:
		if board[tile]["player"] == 1:
			a = true
		elif board[tile]["player"] == 0:
			h = true
	
	return (h and a)



func change_tile_size(new_size: Vector2i):
	if tile_set:
		tile_set.tile_size = new_size


func initial_centering_tilemap(target_screen_position: Vector2i):
	position = target_screen_position

func board_cell_rendering() -> void:
	for tile_id in board:
		var player = board[tile_id]["player"]
		var pieces = board[tile_id]["pieces"]
	

		if player == -1:
			set_cell(0, tile_id, 0, Vector2i(0, 0))
		elif player == 0:
			set_cell(0, tile_id, 4, Vector2i(0, 0))
		elif player == 1:
			set_cell(0, tile_id, 3, Vector2i(0, 0))

		if pieces > 0:
			create_or_update_label_1(tile_id, str(pieces), labels, self)
		else:
			remove_label_1(tile_id, labels)

func un_render_board():
	for tile_id in board:
		create_or_update_label_1(tile_id, str(""), labels, self)
	
	labels = {}
	clear()


func get_and_make_ai_move():
	if ai_running == true:
		return
		
	ai_running = true 

	if ai_thread and ai_thread.is_started():
		ai_thread.wait_to_finish() 
		ai_thread = null 

	ai_thread = Thread.new()  
	call_deferred("_start_ai_thread") 

func _start_ai_thread():
	var err = ai_thread.start(Callable(self, "_execute_ai_move_threaded"))
	if err != OK:
		print("Error starting AI thread:", err)
		ai_running = false


func _execute_ai_move_threaded():
	ai_mutex.lock()  # Lock access to AI calculations
	var hard_ai = load("res://scripts/ai/hard_ai.gd").new()
	var move_from_ai = hard_ai.get_ai_move(board) 
	
	var current_phase = _get_current_phase()
	
	if current_phase == "board_placement":
		var placement_coordinates = move_from_ai[0] + "|" + str(move_from_ai[1].x) + "|" + str(move_from_ai[1].y) + "|"
		move_from_ai = grid_calculations.convert_string_to_coordinates(placement_coordinates)
		for tile in move_from_ai:
			board[tile] = {
			"player": -1,  
			"pieces": 0
			}
		move = networking.board_placement_string(move_from_ai)
	elif current_phase == "initial_stack":
		board[move_from_ai]["player"] = 1
		board[move_from_ai]["pieces"] = 16
		move = networking.initial_stack_string(move_from_ai)
		
	elif current_phase == "strategy":
		board[move_from_ai[0]]["player"] = 1
		board[move_from_ai[1]]["player"] = 1
		board[move_from_ai[0]]["pieces"] -= move_from_ai[2]
		board[move_from_ai[1]]["pieces"] += move_from_ai[2]
		move = networking.strategic_move_string(move_from_ai)

	ai_mutex.unlock()  # Unlock AI calculations

	call_deferred("_finalize_ai_move")

func _finalize_ai_move():
	ai_running = false  
	
	if ai_thread:
		if ai_thread.is_started():
			ai_thread.wait_to_finish()
		ai_thread = null
	
	emit_signal("ai_move_completed")

func _get_current_phase():
	if board.size() < 32:
		return "board_placement"
		
	var ai_stack_placed = true
	for tile in board:
		if board[tile]["player"] == 1:
			ai_stack_placed = false
			break
	
	if ai_stack_placed:
		return "initial_stack"
		
	return "strategy"
	
	
func _check_initial_palcements() -> bool:
	var ai_placed = false
	var human_placed = false
	
	for tile in board:
		if board[tile]["player"] == 0:
			human_placed = true
		elif board[tile]["player"] == 1:
			ai_placed = true
	
	return (ai_placed and human_placed)


func _on_back_pressed() -> void:
	GlobalVars.going_back_to_main_menu = true
	
	if ai_running and ai_thread.is_alive():
		ai_thread.wait_to_finish()
	
	
	get_tree().change_scene_to_file("res://scenes/start_menu/menu_global_manager.tscn")



func create_or_update_label_1(tile_id: Vector2i, new_text: String, labels, tree) -> void:
	var label = Label

	if labels.has(tile_id):
		label = labels[tile_id]
	else:
		label = Label.new()
		label.name = "PiecesLabel_%s" % tile_id
		tree.add_child(label)
		labels[tile_id] = label

	label.text = new_text
	label.add_theme_color_override("font_color", Color.BLACK) 


	var world_pos = tree.map_to_local(tile_id) 
	label.position = world_pos + Vector2(-40, -5)

func remove_label_1(tile_id: Vector2, labels) -> void:
	if labels.has(tile_id):
		labels[tile_id].queue_free()
		labels.erase(tile_id)
