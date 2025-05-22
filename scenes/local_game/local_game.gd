extends TileMap

var board_renders = load("res://scripts/renders_and_pop_ups/board_renders.gd").new()  # Create an instance
var grid_calculations = load("res://scripts/game_helpers/GridCalculations.gd").new()
var game_rules = load("res://scripts/game_helpers/game_rules_logic.gd").new()

var current_instruction = 0

@onready var help_banner = get_node("../CanvasLayer/Background/HelpBanner")
@onready var help_banner_text = get_node("../CanvasLayer/Background/HelpBanner/HelpText")

var _drag_offset: Vector2 = Vector2.ZERO # for slider
@export var scroll_speed: float = 500
@export var edge_margin: int = 10
var middle_of_screen = Vector2(900, 550)
var scroll_offset: Vector2 = Vector2.ZERO  
var labels := {}

@onready var screen_dimmer = get_node("../CanvasLayer/Background/ScreenDimmer")
@onready var sidebar_menu = get_node("../CanvasLayer/Background/Menu")
@onready var how_to_play_popup = get_node("../CanvasLayer/Background/HowToPlayPanel")
@onready var how_to_play_instructions = get_node("../CanvasLayer/Background/HowToPlayPanel/InstructionsLabel")
@onready var video_player = get_node("../CanvasLayer/Background/HowToPlayPanel/VideoPlayer")
@onready var mort_animation = get_node("../CanvasLayer/Background/HowToPlayPanel/Mort")
@onready var kuro_animation = get_node("../CanvasLayer/Background/HowToPlayPanel/Kuro")
@onready var how_to_play_swipe_left = get_node("../CanvasLayer/Background/HowToPlayPanel/SwipeLeft")
@onready var how_to_play_swipe_right = get_node("../CanvasLayer/Background/HowToPlayPanel/SwipeRight")
@onready var settings_popup = get_node("../CanvasLayer/Background/SettingsPanel")
@onready var menu_button = get_node("../CanvasLayer/Background/MenuButton")
@onready var help_button = get_node("../CanvasLayer/Background/HelpButton")

@onready var loading_screen = get_node("../LoadingScreenLayer/LoadingScreen")

var canvas_layer = null
var conf_dialog_panel = null

@onready var player_1_turn_banner = get_node("../Banners/Player1Turn")
@onready var player_2_turn_banner = get_node("../Banners/Player2Turn")

@onready var player_1_won_top_banner = get_node("../Banners/Player1WonTop")
@onready var player_2_won_top_banner = get_node("../Banners/Player2WonTop")
@onready var you_tied_top_banner = get_node("../Banners/YouTiedTop")


@onready var player_1_won_banner = get_node("../Banners/Player1Won")
@onready var player_2_won_banner = get_node("../Banners/Player2Won")
@onready var you_tied_big_banner = get_node("../Banners/YouTied")

@onready var musicBusID = AudioServer.get_bus_index("music")
@onready var sfxBusID = AudioServer.get_bus_index("sfx")

var confirmation_dialog_rendering = false


var camera_movement_factor = 0.3
var camera_movement_offset = Vector2(-3, -3)
var tile_outside_offset = Vector2(-995, -650)

# differentiate input
var human_zero_make_move = []
var human_one_make_move = []

var human_zero_previously_hovered_cell = Vector2i(-999, -999)
var human_one_previously_hovered_cell = Vector2i(-999, -999)

var human_zero_strategic_previous_phase_hover = Vector2i(-999, -999)
var human_one_strategic_previous_phase_hover = Vector2i(-999, -999)

var human_one_mouse_on_hex
var human_zero_mouse_on_hex

var human_zero_previous_preview = []
var human_one_previous_preview = []

var human_zero_possible_moves = []
var human_one_possible_moves = []

var human_zero_previously_clicked = Vector2i(-999, -999)
var human_one_previously_clicked = Vector2i(-999, -999)

var for_move = []

var render_zero_click = false
var render_one_click = false
var render_hex = Vector2i(-999, -999)

var trying_to_place_tiles = false

# for game logic
var first_tile_placed = false

var human_zero_turn
var human_one_turn

var first_human_zero
var first_human_one

var human_zero_can_move = true
var human_one_can_move = true
var game_over = false

var board_placement_phase = true
var game_strategy_phase = false

var human_zero_initial_stack_placed = false
var human_one_initial_stack_placed = false
var initial_stacks_placed = false

var human_zero_never_goes_again = false
var human_one_never_goes_again = false

var board_size = 0
var board = {}  

var directions = ["north_east", "east", "south_east"]
 
var curr_direction_placement_index = 1

# for animations
var current_tween: Tween = null
var dino_instance
var dinos_left_user = []
var dinos_right_user =  []

var camera_pos: Vector2
var cam_executed: bool = false
var dino_tile_offset = Vector2(-16, -1)
var dino_currently_jumping = false
var dino_currently_jumping_instance
var game_has_ended = false
var animation_running = false
var dino_running = false
var slider_rendering = false

var going_back = false

func _ready():
	print("local")
	$Camera2D.enabled = true
	
	# show_move_slider(Vector2(500, 500), 15)
	
	initial_centering_tilemap(middle_of_screen)
	change_tile_size(Vector2i(128, 128))
	
	randomize()  
	var coin_flip = randi() % 2  # to see who goes first
	
	if coin_flip == 0:
		first_human_zero = true
		first_human_one = false
	else:
		first_human_zero = false
		first_human_one = true
	
	
	human_zero_turn = true if first_human_zero else false
	human_one_turn = true if first_human_one else false
	
	if human_zero_turn:
		first_tile_calc_shape_human_zero()
	if human_one_turn:
		first_tile_calc_shape_human_one()
		
	get_parent().get_node("CanvasLayer/Background/SettingsPanel/SettingsBox/MusicVolumeSlider").value = db_to_linear(AudioServer.get_bus_volume_db(musicBusID))
	get_parent().get_node("CanvasLayer/Background/SettingsPanel/SettingsBox/SfxVolumeSlider").value = db_to_linear(AudioServer.get_bus_volume_db(sfxBusID))
	

func _process(delta):
	if not is_inside_tree() or going_back:
		return
		
	if slider_rendering or confirmation_dialog_rendering or player_1_won_banner.visible == true or player_2_won_banner.visible == true or you_tied_big_banner.visible == true:
		if player_1_won_banner.visible == true or player_2_won_banner.visible == true or you_tied_big_banner.visible == true:
			help_banner.visible = false
		
			if confirmation_dialog_rendering:
				_on_dialog_canceled()
		
		screen_dimmer.visible = false
		how_to_play_popup.visible = false
		sidebar_menu.visible = false
		settings_popup.visible = false
		
		menu_button.disabled = true
		help_button.disabled = true
		

	else:
		if how_to_play_popup.visible == false and settings_popup.visible == false:
			menu_button.disabled = false
			help_button.disabled = false
		
		
	var viewport_size = get_viewport_rect().size
	var board_rect = get_board_bounding_rect()
	
	if is_instance_valid(dino_instance) and dino_instance and dino_instance.camera_moving:
		dino_running = true
		$Camera2D.position = $Camera2D.position.lerp(dino_instance.global_position, camera_movement_factor * delta) + camera_movement_offset
	elif animation_running == false:
		if dino_running == true:
			animation_running = true
			await _center_board_horizontally()
			animation_running = false
		dino_running = false
		# Edge scrolling
		var mouse_pos = get_viewport().get_mouse_position()
		var scroll_velocity = Vector2.ZERO
		
		var overshoot = 450 if board_placement_phase else 135
		
		var cam_offset = $Camera2D.position - (viewport_size / 2)
		
		var board_left_screen = board_rect.position.x - cam_offset.x - overshoot
		var board_right_screen = board_rect.position.x + board_rect.size.x - cam_offset.x + overshoot
		var board_top_screen = board_rect.position.y - cam_offset.y - overshoot
		var board_bottom_screen = board_rect.position.y + board_rect.size.y - cam_offset.y + overshoot
		
		if mouse_pos.x < edge_margin and board_left_screen < 0:  
			scroll_velocity.x = -scroll_speed
		elif mouse_pos.x > viewport_size.x - edge_margin and board_right_screen > viewport_size.x: 
			scroll_velocity.x = scroll_speed
		
		if mouse_pos.y < edge_margin and board_top_screen < 0: 
			scroll_velocity.y = -scroll_speed
		elif mouse_pos.y > viewport_size.y - edge_margin and board_bottom_screen > viewport_size.y: 
			scroll_velocity.y = scroll_speed
		
		$Camera2D.position += scroll_velocity * delta
	
	
	if game_has_ended == false:
		if board_size == 32:
			board_placement_phase = false
			game_strategy_phase = true
			help_banner_text.text = "Click a pasture tile along the outer edge of the territory to place your dino herd."
		
		if human_one_never_goes_again == true:
			human_zero_turn = true
			human_one_turn = false
		
		if human_zero_never_goes_again == true:
			human_zero_turn = false
			human_one_turn = true
		
		if game_rules.game_over_upgraded(board, initial_stacks_placed, human_zero_never_goes_again, human_one_never_goes_again):
			game_over = true
		
		if human_zero_initial_stack_placed and human_one_initial_stack_placed:
			initial_stacks_placed = true
			help_banner_text.text = "Click one of your dino groups, choose a highlighted destination tile, and select how many dinos you'd like to move."
		
		if human_zero_turn:
			player_1_turn_banner.visible = true
			player_2_turn_banner.visible = false
		
		if human_one_turn:
			player_1_turn_banner.visible = false
			player_2_turn_banner.visible = true
		
		if game_over:
			game_has_ended = true
			human_zero_turn = false
			human_one_turn = false
			
			while animation_running == true and going_back == false:
				if not is_inside_tree():
					return
				await get_tree().process_frame
			
			help_banner_text.text = "Game over! Go back to the menu and start a new game."
			
			animation_running = false
			board_cell_rendering()
			
			player_1_turn_banner.visible = false
			player_2_turn_banner.visible = false
			
			# return 0 for tie, 2 for human, 1 for ai
			var winner = game_rules.get_winner(board)
			if winner == 0:
				you_tied_top_banner.visible = true
				you_tied_big_banner.visible = true
				_animation_dinos_back_to_egg()
				get_parent().get_node("Sound/Music").stop()
				get_parent().get_node("Sound/LoseJingle").play()
			elif winner == 1:
				player_2_won_banner.visible = true
				player_2_won_top_banner.visible = true
				_aniamtion_remove_loser(0)
				get_parent().get_node("Sound/Music").stop()
				get_parent().get_node("Sound/WinJingle").play()
			elif winner == 2:
				player_1_won_banner.visible = true
				player_1_won_top_banner.visible = true
				_aniamtion_remove_loser(1)
				get_parent().get_node("Sound/Music").stop()
				get_parent().get_node("Sound/WinJingle").play()
				

		if initial_stacks_placed:
			var can_human_zero_move = game_rules.can_move_be_made(board, 0)
			if can_human_zero_move == false:
				human_zero_never_goes_again = true
			
			var can_human_one_move = game_rules.can_move_be_made(board, 1)
			if can_human_one_move == false:
				human_one_never_goes_again = true

func board_cell_rendering() -> void:
	if animation_running or slider_rendering:
		return
	
	if dino_currently_jumping:
		dino_currently_jumping_instance.back_to_idle()
		dino_currently_jumping = false
		
	for tile_id in board:
		var pieces = board[tile_id]["pieces"]
		
		set_cell(0, tile_id, 0, Vector2i(0, 0))


# If there are pieces on this tile, show (or create) a label with their count
		if pieces > 0:
			board_renders.create_or_update_label(tile_id, str(pieces), labels, self)
		else:
			board_renders.remove_label(tile_id, labels)
	

func _is_mouse_on_banners():
	var _mouse_pos = get_viewport().get_mouse_position()
	
	# top banner
	if (_mouse_pos.x >= 755 and  _mouse_pos.x <= 1188) and (_mouse_pos.y >= -1 and  _mouse_pos.y <= 103):
		return true
	
	# menu button
	if (_mouse_pos.x >= 1795 and  _mouse_pos.x <= 1921) and (_mouse_pos.y >= -1 and  _mouse_pos.y <= 115):
		return true
	
	# help button
	if (_mouse_pos.x >= 1792 and  _mouse_pos.x <= 1921) and (_mouse_pos.y >= 944 and  _mouse_pos.y <= 1081):
		return true
	
	if help_banner.visible == true:
		if _mouse_pos.y >= 950:
			return true
	
	return false
	
func _input(event):	
	if animation_running or game_has_ended or going_back or confirmation_dialog_rendering or slider_rendering:
		return
		
	if human_zero_turn:
		if _is_mouse_on_banners() and board_size != 0:
			clear_highlight_human_zero()
			return
		_do_human_zero_move(event)
	elif human_one_turn:
		if _is_mouse_on_banners() and board_size != 0:
			clear_highlight_human_one()
			return
		_do_human_one_move(event)

func _do_human_zero_move(event):
	var is_menu_focused = screen_dimmer.visible
	
	if event is InputEventMouseMotion and !is_menu_focused:
		var mouse_pos = get_local_mouse_position()
		human_zero_mouse_on_hex = local_to_map(mouse_pos)
		
		if human_zero_turn and game_strategy_phase and human_zero_mouse_on_hex in board and human_zero_mouse_on_hex != human_zero_strategic_previous_phase_hover:
			human_zero_strategic_previous_phase_hover = human_zero_mouse_on_hex

		if first_tile_placed == true and board_size != 32 and trying_to_place_tiles == false: # and human_zero_mouse_on_hex != human_zero_previously_hovered_cell:
			clear_highlight_human_zero()
			calc_shape_human_zero()
		
	# andles strategy phase logic
	elif human_zero_initial_stack_placed and event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and !is_menu_focused:
		human_zero_mouse_on_hex = local_to_map(get_local_mouse_position())
		if human_zero_turn and game_strategy_phase and human_zero_mouse_on_hex in board and human_zero_never_goes_again == false:
			#render them, to be printed, if true it will be calcualted and printed
			if human_zero_possible_moves.size() == 0 and board[human_zero_mouse_on_hex]["player"] == 0 and board[human_zero_mouse_on_hex]["pieces"] > 1:
				if human_zero_possible_moves.size() == 0:
					human_zero_possible_moves = game_rules.move_possible(board, human_zero_mouse_on_hex)
					human_zero_previously_clicked = human_zero_mouse_on_hex
					if human_zero_possible_moves.size() != 0:
						_animation_on_select_jump(0, human_zero_mouse_on_hex)
					for t in human_zero_possible_moves:
						set_cell(0, t, 2, Vector2i(0, 0))  # Change tile rendering
			elif board[human_zero_mouse_on_hex]["player"] == -1:
				if human_zero_mouse_on_hex in human_zero_possible_moves:
					human_zero_make_move = [human_zero_previously_clicked, human_zero_mouse_on_hex]
					render_zero_click = true
					render_hex = human_zero_mouse_on_hex
					for tile in human_zero_possible_moves:
							if tile == human_zero_make_move[1]:
								set_cell(0, tile, 2, Vector2i(0, 0))  # Change tile rendering
							else:
								set_cell(0, tile, 0, Vector2i(0, 0))  # Change tile rendering
					show_move_slider(get_viewport().get_mouse_position(), board[human_zero_previously_clicked]["pieces"] - 1)
				board_cell_rendering()
				human_zero_possible_moves = []
			elif human_zero_mouse_on_hex == human_zero_previously_clicked:
				board_cell_rendering()
				human_zero_possible_moves = []
			else:
				board_cell_rendering()
				human_zero_possible_moves = []
		elif human_zero_mouse_on_hex not in board:
			board_cell_rendering()
			human_zero_possible_moves = []
		else:
			board_cell_rendering()
			human_zero_possible_moves = []

	
	elif human_zero_initial_stack_placed == false and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and !is_menu_focused:
		if human_zero_turn and game_strategy_phase:
			var outside_border = grid_calculations.get_possible_positions_to_place_board(board)
			var board_margin = game_rules.get_board_margins(board, outside_border)
			human_zero_mouse_on_hex = local_to_map(get_local_mouse_position())
			
			if human_zero_mouse_on_hex in board_margin and board[human_zero_mouse_on_hex]["player"] == -1:
				board[human_zero_mouse_on_hex]["player"] = 0
				board[human_zero_mouse_on_hex]["pieces"] = 16
				await _animation_born_dino(0, human_zero_mouse_on_hex)
				board_cell_rendering()
				switch_turns()
				human_zero_initial_stack_placed = true

	#elif human_initial_stack_placed == true and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#if human_turn and game_strategy_phase:
			#pass

	if event is InputEventKey and event.pressed and !is_menu_focused:
		human_zero_mouse_on_hex = local_to_map(get_local_mouse_position())
		if first_tile_placed == true and event.keycode == KEY_R and human_zero_turn and board_placement_phase and board_size != 32:
			switch_direction()
			clear_highlight_human_zero()
			calc_shape_human_zero()
		elif first_tile_placed == false and event.keycode == KEY_R and human_zero_turn and board_placement_phase and board_size != 32:
			switch_direction()
			first_tile_clear_highlight_human_zero()
			first_tile_calc_shape_human_zero()
			
				
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and !is_menu_focused:
		human_zero_mouse_on_hex = local_to_map(get_local_mouse_position())
		if first_tile_placed == false and human_zero_turn and board_placement_phase and board_size != 32:
			switch_direction()
			first_tile_clear_highlight_human_zero()
			first_tile_calc_shape_human_zero()
			
		if first_tile_placed == true and human_zero_turn and board_placement_phase and board_size != 32 and trying_to_place_tiles == false:
			switch_direction()
			clear_highlight_human_zero()
			calc_shape_human_zero()
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and board_size != 32 and !is_menu_focused:
		human_zero_mouse_on_hex = local_to_map(get_local_mouse_position())
		if first_tile_placed == false and _is_click_on_highlight(human_zero_mouse_on_hex) and human_zero_turn and board_placement_phase and board_size != 32:
			first_tile_try_to_place_tiles_human_zero()
			
		if first_tile_placed == true and human_zero_turn and board_placement_phase and board_size != 32:
			try_to_place_tiles_human_zero()


func _do_human_one_move(event):
	var is_menu_focused = screen_dimmer.visible
	
	if event is InputEventMouseMotion and !is_menu_focused:
		#if first == false:
			# var mouse_delta = event.relative
			# position -= mouse_delta * 0.05 # movement of the board 
		
		var mouse_pos = get_local_mouse_position()
		human_one_mouse_on_hex = local_to_map(mouse_pos)
		
		if human_one_turn and game_strategy_phase and human_one_mouse_on_hex in board and human_one_mouse_on_hex != human_one_strategic_previous_phase_hover:
			human_one_strategic_previous_phase_hover = human_one_mouse_on_hex

		if first_tile_placed == true and board_size != 32 and trying_to_place_tiles == false: # and human_one_mouse_on_hex != human_one_previously_hovered_cell:
			clear_highlight_human_one()
			calc_shape_human_one()
		

		
	# andles strategy phase logic	
	elif human_one_initial_stack_placed and event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and !is_menu_focused:
		human_one_mouse_on_hex = local_to_map(get_local_mouse_position())
		if human_one_turn and game_strategy_phase and human_one_mouse_on_hex in board and human_one_never_goes_again == false:
			#render them, to be printed, if true it will be calcualted and printed
			if human_one_possible_moves.size() == 0 and board[human_one_mouse_on_hex]["player"] == 1 and board[human_one_mouse_on_hex]["pieces"] > 1:
				if human_one_possible_moves.size() == 0:
					human_one_possible_moves = game_rules.move_possible(board, human_one_mouse_on_hex)
					human_one_previously_clicked = human_one_mouse_on_hex
					if human_one_possible_moves.size() != 0:
						_animation_on_select_jump(1, human_one_mouse_on_hex)
					for t in human_one_possible_moves:
						set_cell(0, t, 2, Vector2i(0, 0)) 
			elif board[human_one_mouse_on_hex]["player"] == -1:
				if human_one_mouse_on_hex in human_one_possible_moves:
					human_one_make_move = [human_one_previously_clicked, human_one_mouse_on_hex]
					render_one_click = true
					render_hex = human_one_mouse_on_hex
					for tile in human_one_possible_moves:
							if tile == human_one_make_move[1]:
								set_cell(0, tile, 2, Vector2i(0, 0)) 
							else:
								set_cell(0, tile, 0, Vector2i(0, 0))
					show_move_slider(get_viewport().get_mouse_position(), board[human_one_previously_clicked]["pieces"] - 1)
				board_cell_rendering()
				human_one_possible_moves = []
			elif human_one_mouse_on_hex == human_one_previously_clicked:
				board_cell_rendering()
				human_one_possible_moves = []
			else:
				board_cell_rendering()
				human_one_possible_moves = []
		elif human_one_mouse_on_hex not in board:
			board_cell_rendering()
			human_one_possible_moves = []
		else:
			board_cell_rendering()
			human_one_possible_moves = []
		#elif human_turn and game_strategy_phase:
			#print(2)
			#render_pos_moves = not render_pos_moves
			#board_cell_rendering()
	
	elif human_one_initial_stack_placed == false and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and !is_menu_focused:
		if human_one_turn and game_strategy_phase:
			var outside_border = grid_calculations.get_possible_positions_to_place_board(board)
			var board_margin = game_rules.get_board_margins(board, outside_border)
			human_one_mouse_on_hex = local_to_map(get_local_mouse_position())
			
			if human_one_mouse_on_hex in board_margin and board[human_one_mouse_on_hex]["player"] == -1:
				board[human_one_mouse_on_hex]["player"] = 1
				board[human_one_mouse_on_hex]["pieces"] = 16
				await _animation_born_dino(1, human_one_mouse_on_hex)
				board_cell_rendering()
				switch_turns()
				human_one_initial_stack_placed = true

	#elif human_initial_stack_placed == true and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#if human_turn and game_strategy_phase:
			#pass

	if event is InputEventKey and event.pressed and !is_menu_focused:
		human_one_mouse_on_hex = local_to_map(get_local_mouse_position())
		if first_tile_placed == true and event.keycode == KEY_R and human_one_turn and board_placement_phase and board_size != 32:
			switch_direction()
			clear_highlight_human_one()
			calc_shape_human_one()
		elif first_tile_placed == false and event.keycode == KEY_R and human_one_turn and board_placement_phase and board_size != 32:
			switch_direction()
			first_tile_clear_highlight_human_one()
			first_tile_calc_shape_human_one()

				
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and !is_menu_focused:
		human_one_mouse_on_hex = local_to_map(get_local_mouse_position())
		
		if first_tile_placed == false and human_one_turn and board_placement_phase and board_size != 32:
			switch_direction()
			first_tile_clear_highlight_human_one()
			first_tile_calc_shape_human_one()
			
		if first_tile_placed == true and human_one_turn and board_placement_phase and board_size != 32 and trying_to_place_tiles == false:
			switch_direction()
			clear_highlight_human_one()
			calc_shape_human_one()
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and board_size != 32 and !is_menu_focused:
		human_one_mouse_on_hex = local_to_map(get_local_mouse_position())
		if first_tile_placed == false and _is_click_on_highlight(human_one_mouse_on_hex) and human_one_turn and board_placement_phase and board_size != 32:
			first_tile_try_to_place_tiles_human_one()
			
		if first_tile_placed == true and human_one_turn and board_placement_phase and board_size != 32:
			try_to_place_tiles_human_one()



func _animation_place_board(tiles, move_cam):
	animation_running = true
	var animas = []
	for tile in tiles:
		var tile_scene = preload("res://scenes/board_in_game_animations/board_in_game_animations.tscn")
		var tile_instance = tile_scene.instantiate()
		add_child(tile_instance)
		animas.append(tile_instance)
		var target_position = map_to_local(tile)
		tile_instance.play_board_smoke(target_position)
	
	var total_position = Vector2.ZERO
	for tile in tiles:
		total_position += map_to_local(tile)
	var center_position = total_position / tiles.size()
	
	if not is_inside_tree() or going_back:
		return
	current_tween = get_tree().create_tween()
	current_tween.tween_property($Camera2D, "position", center_position, 1.6) 
	
	if not is_inside_tree() or going_back:
		return
	await get_tree().create_timer(2.00).timeout
	animation_running = false
	
	for anima in animas:
		anima.queue_free()
	

	
	
		
func _animation_dinos_back_to_egg():
	animation_running = true
	for dino in dinos_left_user:
		dino.back_to_egg()
	
	for dino in dinos_right_user:
		dino.back_to_egg()
	
	animation_running = false
		
	
func _aniamtion_remove_loser(loser_player):
	animation_running = true
	if loser_player == 0:
		for dino in dinos_left_user:
			dino.kill_dino()
	elif loser_player == 1:
		for dino in dinos_right_user:
			dino.kill_dino()
	
	animation_running = false

		

func _animation_on_select_jump(player, tile):
	var tile_pos = map_to_local(tile)
	tile_pos = Vector2(tile_pos)  + dino_tile_offset
	if player == 0:
		for dino in dinos_left_user:
			if dino.position.is_equal_approx(tile_pos):
				dino.on_select_jump()
				dino_currently_jumping_instance = dino
				dino_currently_jumping = true
				return
	if player == 1:
		for dino in dinos_right_user:
			if dino.position.is_equal_approx(tile_pos):
				dino.on_select_jump()
				dino_currently_jumping_instance = dino
				dino_currently_jumping = true
				return

func _animation_born_dino(curr_player, tile):
	while animation_running == true and going_back == false:
		if not is_inside_tree():
			continue
		await get_tree().process_frame
		
	animation_running = true
	var target_position = map_to_local(tile)
	var tp = map_to_local(tile)
	var tile_center_local = tp + (Vector2(tile_set.tile_size) / 2)
	var target_global = self.to_global(tile_center_local)
	if not is_inside_tree():
		return
	var viewport_size = get_viewport_rect().size
	var margin = 125
	var adjusted_size = viewport_size - Vector2(2 * margin, 2 * margin)
	var safe_zone = Rect2($Camera2D.global_position - (adjusted_size / 2), adjusted_size)

	if not safe_zone.has_point(target_global):
		if not is_inside_tree() or going_back:
			return
		await center_camera_on_target(target_global + tile_outside_offset)
		if not is_inside_tree() or going_back:
			return
		await get_tree().create_timer(0.6).timeout
	var dino_scene = preload("res://scenes/dino_in_game_animations/dino_in_game_animations.tscn")
	dino_instance = dino_scene.instantiate()
	add_child(dino_instance)
	await dino_instance.dino_give_birth(target_position, curr_player)
	if curr_player == 0:
		dinos_left_user.append(dino_instance)
	if curr_player == 1:
		dinos_right_user.append(dino_instance)
	animation_running = false
	return


func _animation_move_dinos(tile_from, tile_to, curr_player):
	while animation_running == true and going_back == false:
		if not is_inside_tree():
			continue
		await get_tree().process_frame
	animation_running = true
	set_cell(0, tile_to, 2, Vector2i(0, 0))  # Change tile rendering

	var start_position = map_to_local(tile_from)
	var target_position = map_to_local(tile_to)

	# Compute the target position for the tile (use the tile's center)
	var tp = map_to_local(tile_from)
	var tile_center_local = tp + (Vector2(tile_set.tile_size) / 2)
	var target_global = self.to_global(tile_center_local)
	var margin = 145
	if not is_inside_tree():
		return
	var viewport_size = get_viewport_rect().size
	var adjusted_size = viewport_size - Vector2(2 * margin, 2 * margin)
	var safe_zone = Rect2($Camera2D.global_position - (adjusted_size / 2), adjusted_size)

	if not safe_zone.has_point(target_global):
		var hex_distance = abs(tile_to.x - tile_from.x) + abs(tile_to.y - tile_from.y)
		var num_offset = hex_distance * 0.95
		# camera_movement_offset = Vector2(-num_offset, -num_offset)
		# camera_movement_factor = 0.5 + hex_distance * 0.15
		await center_camera_on_target(target_global + tile_outside_offset)
		if not is_inside_tree() or going_back:
			return
		await get_tree().create_timer(0.6).timeout

	var dino_scene = preload("res://scenes/dino_in_game_animations/dino_in_game_animations.tscn")
	dino_instance = dino_scene.instantiate()
	add_child(dino_instance)
	get_parent().get_node("Sound/WalkSound").play()
	await dino_instance.move_dino(start_position, target_position, curr_player)

	tp = map_to_local(tile_to)
	tile_center_local = tp + (Vector2(tile_set.tile_size) / 2)
	target_global = self.to_global(tile_center_local)
	if not is_inside_tree():
		return
	viewport_size = get_viewport_rect().size
	adjusted_size = viewport_size - Vector2(2 * margin, 2 * margin)
	safe_zone = Rect2($Camera2D.global_position - (adjusted_size / 2), adjusted_size)

	if not safe_zone.has_point(target_global):
		await center_camera_on_target(target_global + tile_outside_offset)
		if not is_inside_tree() or going_back:
			return
		await get_tree().create_timer(0.6).timeout


	if curr_player == 0:
		dinos_left_user.append(dino_instance)
	if curr_player == 1:
		dinos_right_user.append(dino_instance)
	camera_movement_factor = 0.3
	camera_movement_offset = Vector2(-3,-3)
	animation_running = false
	return

func _is_click_on_highlight(mouse_on_hex):
	var four_tiles = grid_calculations.get_shape_for_first_tile(curr_direction_placement_index, Vector2i(0, 0))

	if four_tiles.size() == 0:
		return
	
	for tile in four_tiles:
		if tile == mouse_on_hex:
			return true
	
	return false
	
func place_on_board(four_tiles: Array):
	for tile in four_tiles:
		board[tile] = {
		"player": -1,  
		"pieces": 0
		}


func first_tile_try_to_place_tiles_human_zero():
	if trying_to_place_tiles or animation_running:
		return
	
	trying_to_place_tiles = true
	
	var four_tiles = grid_calculations.get_shape_for_first_tile(curr_direction_placement_index, Vector2i(0, 0))

	if four_tiles.size() == 0:
		trying_to_place_tiles = false
		return

	if grid_calculations.is_touching_grid(four_tiles, board, first_tile_placed):
		animation_running = true
		board_size += 4
		place_on_board(four_tiles)
		first_tile_placed = true
		
		_human_zero_clear_highlight_for_animation()
		_animation_place_board(four_tiles, false)
		if not is_inside_tree() or going_back:
			return
		await get_tree().create_timer(2.05).timeout
		
		switch_turns()  # Place text inside the tile
		animation_running = false
		board_cell_rendering()
	
	trying_to_place_tiles = false

func _human_zero_clear_highlight_for_animation():
	for tile in human_zero_previous_preview:
		set_cell(0, tile, -1, Vector2i(0,0))

func _human_one_clear_highlight_for_animation():
	for tile in human_one_previous_preview:
		set_cell(0, tile, -1, Vector2i(0,0))

func first_tile_try_to_place_tiles_human_one():
	if trying_to_place_tiles or animation_running:
		return
		
	trying_to_place_tiles = true
	var four_tiles = grid_calculations.get_shape_for_first_tile(curr_direction_placement_index, Vector2i(0, 0))

	if four_tiles.size() == 0:
		trying_to_place_tiles = false
		return

	if grid_calculations.is_touching_grid(four_tiles, board, first_tile_placed):
		animation_running = true
		board_size += 4
		place_on_board(four_tiles)
		first_tile_placed = true
		
		_human_one_clear_highlight_for_animation()
		_animation_place_board(four_tiles, false)
		if not is_inside_tree() or going_back:
			return
		await get_tree().create_timer(2.05).timeout
		
		switch_turns()  # Place text inside the tile
		animation_running = false
		board_cell_rendering()
	
	trying_to_place_tiles = false
		
func try_to_place_tiles_human_zero():
	if trying_to_place_tiles or animation_running:
		return
	
	trying_to_place_tiles = true
	var four_tiles = grid_calculations.get_user_friendly_mouse_tiles(curr_direction_placement_index, human_zero_mouse_on_hex, board)

	if four_tiles.size() == 0:
		trying_to_place_tiles = false
		return

	if grid_calculations.is_touching_grid(four_tiles, board, first_tile_placed):
		animation_running = true
		board_size += 4
		place_on_board(four_tiles)
		first_tile_placed = true
		
		_human_zero_clear_highlight_for_animation()
		_animation_place_board(four_tiles, false)
		if not is_inside_tree() or going_back:
			return
		await get_tree().create_timer(2.05).timeout
		
		switch_turns()  # Place text inside the tile
		animation_running = false
		board_cell_rendering()
	
	trying_to_place_tiles = false

func try_to_place_tiles_human_one():
	if trying_to_place_tiles or animation_running:
		return
	
	trying_to_place_tiles = true
	var four_tiles = grid_calculations.get_user_friendly_mouse_tiles(curr_direction_placement_index, human_one_mouse_on_hex, board)

	if four_tiles.size() == 0:
		trying_to_place_tiles = false
		return

	if grid_calculations.is_touching_grid(four_tiles, board, first_tile_placed):
		animation_running = true
		board_size += 4
		place_on_board(four_tiles)
		first_tile_placed = true
		
		_human_one_clear_highlight_for_animation()
		_animation_place_board(four_tiles, false)
		if not is_inside_tree() or going_back:
			return
		await get_tree().create_timer(2.05).timeout
		
		switch_turns()  # Place text inside the tile
		animation_running = false
		board_cell_rendering()
	
	trying_to_place_tiles = false
		


func initial_centering_tilemap(target_screen_position: Vector2i):
	position = target_screen_position

func change_tile_size(new_size: Vector2i):
	if tile_set:
		tile_set.tile_size = new_size
		

func first_tile_calc_shape_human_zero():
	var four_tiles = grid_calculations.get_shape_for_first_tile(curr_direction_placement_index, Vector2i(0, 0))

	if four_tiles.size() == 0:
		return

	for tile in four_tiles:
		set_cell(0, tile, 1, Vector2i(0, 0))

	human_zero_previous_preview = four_tiles
	
func first_tile_calc_shape_human_one():
	var four_tiles = grid_calculations.get_shape_for_first_tile(curr_direction_placement_index, Vector2i(0, 0))

	if four_tiles.size() == 0:
		return

	for tile in four_tiles:
		set_cell(0, tile, 1, Vector2i(0, 0))

	human_one_previous_preview = four_tiles

func calc_shape_human_zero():
	var four_tiles = grid_calculations.get_user_friendly_mouse_tiles(curr_direction_placement_index, human_zero_mouse_on_hex, board)

	if four_tiles.size() == 0:
		return

	for tile in four_tiles:
		set_cell(0, tile, 1, Vector2i(0, 0))

	human_zero_previous_preview = four_tiles

func calc_shape_human_one():
	var four_tiles = grid_calculations.get_user_friendly_mouse_tiles(curr_direction_placement_index, human_one_mouse_on_hex, board)

	if four_tiles.size() == 0:
		return

	for tile in four_tiles:
		set_cell(0, tile, 1, Vector2i(0, 0))

	human_one_previous_preview = four_tiles
	
	
func first_tile_clear_highlight_human_zero():
	for tile in human_zero_previous_preview:
		# Prevent clearing permanent tiles
		if tile not in board:
			set_cell(0, tile, -1, Vector2i(0,0))
			


func first_tile_clear_highlight_human_one():
	for tile in human_one_previous_preview:
		# Prevent clearing permanent tiles
		if tile not in board:
			set_cell(0, tile, -1, Vector2i(0,0))
	

func clear_highlight_human_zero():
	for tile in human_zero_previous_preview:
		# Prevent clearing permanent tiles
		if tile not in board:
			set_cell(0, tile, -1, Vector2i(0,0))


func clear_highlight_human_one():
	for tile in human_one_previous_preview:
		# Prevent clearing permanent tiles
		if tile not in board:
			set_cell(0, tile, -1, Vector2i(0,0))

func switch_direction():
	curr_direction_placement_index = (curr_direction_placement_index + 1) % directions.size()

func switch_turns():
	board_cell_rendering()
	human_zero_turn = not human_zero_turn
	human_one_turn = not human_one_turn
	
	#reset vars
	human_zero_make_move = []
	human_one_make_move = []

	human_zero_previously_hovered_cell = Vector2i(-999, -999)
	human_one_previously_hovered_cell = Vector2i(-999, -999)

	human_zero_strategic_previous_phase_hover = Vector2i(-999, -999)
	human_one_strategic_previous_phase_hover = Vector2i(-999, -999)

	human_zero_previous_preview = []
	human_one_previous_preview = []

	human_zero_possible_moves = []
	human_one_possible_moves = []

	human_zero_previously_clicked = Vector2i(-999, -999)
	human_one_previously_clicked = Vector2i(-999, -999)
	
	for_move = []
	
	render_zero_click = false
	render_one_click = false
	render_hex = Vector2i(-999, -999)
	
	if board_size < 32:
		if human_one_turn:
			human_one_mouse_on_hex = local_to_map(get_local_mouse_position())
			if !screen_dimmer.visible and !confirmation_dialog_rendering:
				calc_shape_human_one()
		elif human_zero_turn:
			human_zero_mouse_on_hex = local_to_map(get_local_mouse_position())
			if !screen_dimmer.visible and !confirmation_dialog_rendering:
				calc_shape_human_zero()

func create_color_texture(color: Color, size := Vector2i(16, 16)) -> Texture2D:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)

func show_move_slider(_global_position: Vector2, max_value: int) -> void:
	slider_rendering = true
	var custom_font = preload("res://assets/Toriko.ttf")
	var font_size = 35
	
	if canvas_layer:
		canvas_layer.queue_free()
		canvas_layer = null
		
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)

	var background_panel = Panel.new()
	background_panel.size = Vector2(400, 175)

	var style = StyleBoxTexture.new()
	var texture = preload("res://assets/ui/04_Stone_Theme/Sprites/UI_Stone_Button_Large_Lock_01a2.png")
	style.texture = texture

	background_panel.add_theme_stylebox_override("panel", style)
	
	canvas_layer.add_child(background_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER 
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	main_vbox.set("theme_override_constants/separation", 10)

	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_panel.add_child(main_vbox)


	var header := HBoxContainer.new()
	header.set("theme_override_constants/separation", 8)
	header.custom_minimum_size = Vector2(0, 50)
	main_vbox.add_child(header)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	
	
	var margin_container := MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_right", 15)
	margin_container.add_theme_constant_override("margin_top", 10)
	margin_container.add_theme_constant_override("margin_bottom", 0)

	var value_label := Label.new()
	value_label.text = "Move 1 dino"
	value_label.add_theme_font_size_override("font_size", font_size)
	value_label.add_theme_font_override("font", custom_font)
	value_label.set("theme_override_colors/font_color", Color.BLACK)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	margin_container.add_child(value_label)


	header.add_child(margin_container)
	header.connect("gui_input", func(event): _on_slider_header_input(event, background_panel))

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set("theme_override_constants/separation", 8)
	main_vbox.add_child(vbox)

	var slider_margin := MarginContainer.new()
	slider_margin.add_theme_constant_override("margin_top", -10)
	slider_margin.add_theme_constant_override("margin_left", 20)
	slider_margin.add_theme_constant_override("margin_right", 20)

	var slider := HSlider.new()
	slider.min_value = 1
	slider.max_value = max_value
	slider.step = 1
	slider.value = 1
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	
	slider_margin.add_child(slider)
	vbox.add_child(slider_margin)

	slider.connect("value_changed", func(value):
		var int_val = int(value)
		var suffix = ""
		if int_val > 1:
			suffix = "s"
		value_label.text = "Move %d dino%s" % [int_val, suffix]
	)

	var confirm_button := Button.new()
	confirm_button.text = "Confirm"
	confirm_button.focus_mode = Control.FOCUS_NONE
	confirm_button.flat = true
	confirm_button.custom_minimum_size = Vector2(80, 28)
	confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


	confirm_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	confirm_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	confirm_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())

	confirm_button.add_theme_constant_override("hseparation", 0)
	confirm_button.add_theme_constant_override("outline_size", 0)
	confirm_button.add_theme_constant_override("content_margin_left", 0)
	confirm_button.add_theme_constant_override("content_margin_right", 0)
	confirm_button.add_theme_constant_override("content_margin_top", 0)
	confirm_button.add_theme_constant_override("content_margin_bottom", 0)
	confirm_button.add_theme_font_size_override("font_size", font_size)
	confirm_button.add_theme_font_override("font", custom_font)
	confirm_button.set("theme_override_colors/font_color", Color.BLACK)
	confirm_button.set("theme_override_colors/font_hover_color", Color.DIM_GRAY)
	
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.flat = true
	close_button.custom_minimum_size = Vector2(80, 28)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


	close_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	close_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	close_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())

	close_button.add_theme_constant_override("hseparation", 0)
	close_button.add_theme_constant_override("outline_size", 0)
	close_button.add_theme_constant_override("content_margin_left", 0)
	close_button.add_theme_constant_override("content_margin_right", 0)
	close_button.add_theme_constant_override("content_margin_top", 0)
	close_button.add_theme_constant_override("content_margin_bottom", 0)
	close_button.add_theme_font_size_override("font_size", font_size)
	close_button.add_theme_font_override("font", custom_font)
	
	close_button.set("theme_override_colors/font_color", Color.BLACK)
	close_button.set("theme_override_colors/font_hover_color", Color.DIM_GRAY)
	
	var button_margin := MarginContainer.new()
	button_margin.add_theme_constant_override("margin_top", 10)

	var button_hbox := HBoxContainer.new()
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button_hbox.set("theme_override_constants/separation", 20) # spacing between buttons

	button_hbox.add_child(confirm_button)
	button_hbox.add_child(close_button)

	button_margin.add_child(button_hbox)
	vbox.add_child(button_margin)

	if not is_inside_tree():
		return
	var popup_size = main_vbox.get_combined_minimum_size()
	var viewport_size = get_viewport_rect().size
	var pos = _global_position

	if pos.x + popup_size.x > viewport_size.x:
		pos.x = viewport_size.x - popup_size.x
	if pos.y + popup_size.y > viewport_size.y:
		pos.y = viewport_size.y - popup_size.y
	pos.x = max(pos.x, 0)
	pos.y = max(pos.y, 0)

	background_panel.position = pos - Vector2(20, 20)
	
	confirm_button.connect("pressed", func():_on_slider_confirmed(slider, background_panel))
	background_panel.connect("tree_exited", func():_on_slider_popup_closed(background_panel))
	close_button.connect("pressed", func():_on_slider_popup_closed(background_panel))
	slider.connect("mouse_entered", func():_on_slider_mouse_entered())
	confirm_button.connect("mouse_entered", func(): _on_confirm_button_mouse_entered())
	close_button.connect("mouse_entered", func(): _on_close_button_mouse_entered())

func _on_slider_popup_closed(slider_popup) -> void:
	get_parent().get_node("Sound/ButtonClickSound").play()
	render_zero_click = false
	render_one_click = false
	slider_rendering = false
	board_cell_rendering()
	slider_popup.hide()
	slider_popup.queue_free()
	
	if canvas_layer != null:
		canvas_layer.queue_free()
	canvas_layer = null
	


func _on_slider_header_input(event: InputEvent, slider_popup) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_drag_offset = Vector2(slider_popup.position) - event.global_position
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			slider_popup.position = Vector2(slider_popup.position) + event.relative

func _on_slider_confirmed(slider: HSlider, slider_popup) -> void:
	get_parent().get_node("Sound/ButtonClickSound").play()
	var selected_value = int(slider.value)

	if human_zero_turn:
		validate_do_human_move_zero(selected_value)
	elif human_one_turn:
		validate_do_human_move_one(selected_value)

	slider_popup.hide()
	slider_popup.queue_free()
	
	if canvas_layer != null:
		canvas_layer.queue_free()
		
	canvas_layer = null



func validate_do_human_move_zero(value):
	
	if not(value < 16 and value > 0):
		return
	
	var make_move = human_zero_make_move

	var old_value = board[make_move[0]]["pieces"]
	var new_home_tile_value = board[make_move[0]]["pieces"] - value
	var new_traveling_tile_value  = board[make_move[1]]["pieces"] + value
	
	if new_home_tile_value < 1 or new_traveling_tile_value > 15:
		return
	
	if (new_home_tile_value + new_traveling_tile_value) != old_value:
		return
	
	board[make_move[0]]["pieces"] -= value
	board[make_move[1]]["pieces"] += value
	board[make_move[0]]["player"] = 0
	board[make_move[1]]["player"] = 0
	

	await _animation_move_dinos(make_move[0], make_move[1], 0)
	
	board_cell_rendering()
	switch_turns()
	animation_running = false

	human_zero_make_move = []


func validate_do_human_move_one(value):
	
	if not(value < 16 and value > 0):
		return
		
	
	var make_move = human_one_make_move
	
	var old_value = board[make_move[0]]["pieces"]
	var new_home_tile_value = board[make_move[0]]["pieces"] - value
	var new_traveling_tile_value  = board[make_move[1]]["pieces"] + value
	
	if new_home_tile_value < 1 or new_traveling_tile_value > 15:
		return
	
	if (new_home_tile_value + new_traveling_tile_value) != old_value:
		return
	
	board[make_move[0]]["pieces"] -= value
	board[make_move[1]]["pieces"] += value
	board[make_move[0]]["player"] = 1
	board[make_move[1]]["player"] = 1

	await _animation_move_dinos(make_move[0], make_move[1], 1)
	
	board_cell_rendering()
	switch_turns()

	animation_running = false
	
	human_one_make_move = []


func center_camera_on_target(target_position: Vector2):
	if not is_inside_tree() or going_back:
		return
	current_tween = get_tree().create_tween()
	current_tween.tween_property($Camera2D, "position", target_position, 1.0)
	return current_tween.finished



func get_board_bounding_rect() -> Rect2:
	if board.is_empty():
		return Rect2()
		
	var min_local = Vector2(INF, INF)
	var max_local = Vector2(-INF, -INF)
	for tile in board:
		var local_pos = map_to_local(tile)
		min_local.x = min(min_local.x, local_pos.x)
		min_local.y = min(min_local.y, local_pos.y)
		max_local.x = max(max_local.x, local_pos.x)
		max_local.y = max(max_local.y, local_pos.y)
	var tile_size = Vector2(tile_set.tile_size)
	return Rect2(min_local - tile_size / 2, max_local - min_local + tile_size)

func _center_board_horizontally(duration := 1.0):
	
	var board_rect = get_board_bounding_rect()
	var board_center_x = (board_rect.position + board_rect.size * 0.5).x
	var old_position = $Camera2D.position

	# If a previous tween is running, kill it so they don't conflict:
	if current_tween:
		current_tween.kill()

	# Create a new tween
	if not is_inside_tree() or going_back:
		return
	
	current_tween = get_tree().create_tween()

	# Tween just the camera's X-position from its current value to board_center_x
	current_tween.tween_property(
		$Camera2D,
		"position",
		Vector2(board_center_x, old_position.y),
		duration
	)
	
	return current_tween.finished


func show_remove_confirmation_dialog():
	if !is_inside_tree() or going_back or confirmation_dialog_rendering:
		return
	
	var custom_font = preload("res://assets/Toriko.ttf")
	var font_size = 35
	
	confirmation_dialog_rendering = true
	sidebar_menu.visible = false
	screen_dimmer.visible = false
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)
	
	if conf_dialog_panel and !is_inside_tree() or going_back:
		conf_dialog_panel.queue_free()

	conf_dialog_panel = Panel.new()
	conf_dialog_panel.name = "CustomConfirmationDialog"
	conf_dialog_panel.custom_minimum_size = Vector2(595, 235)
	conf_dialog_panel.position = get_viewport().get_visible_rect().size / 2 - conf_dialog_panel.custom_minimum_size / 2
	canvas_layer.add_child(conf_dialog_panel)
	
	var texture = preload("res://assets/ui/04_Stone_Theme/Sprites/UI_Stone_Frame_Standard_02a.png")
	var stylebox = StyleBoxTexture.new()
	stylebox.texture = texture
	conf_dialog_panel.add_theme_stylebox_override("panel", stylebox)

	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 33)
	outer_margin.add_theme_constant_override("margin_right", 27)
	outer_margin.add_theme_constant_override("margin_top", 50)
	outer_margin.add_theme_constant_override("margin_bottom", 60)
	outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	conf_dialog_panel.add_child(outer_margin)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	outer_margin.add_child(vbox) 

	var label = Label.new()
	label.text = "Are you sure you want to quit the game?\nThe game will not be saved."
	label.set("theme_override_colors/font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_font_override("font", custom_font)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(label)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 20)

	var confirm_button = Button.new()
	confirm_button.text = "Confirm"
	confirm_button.focus_mode = Control.FOCUS_NONE
	confirm_button.flat = true
	confirm_button.custom_minimum_size = Vector2(80, 28)
	confirm_button.add_theme_font_size_override("font_size", font_size)
	confirm_button.add_theme_font_override("font", custom_font)
	confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_button.set("theme_override_colors/font_color", Color.WHITE)
	confirm_button.set("theme_override_colors/font_hover_color", Color.DIM_GRAY)
	confirm_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	confirm_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	confirm_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	hbox.add_child(confirm_button)

	var close_button = Button.new()
	close_button.text = "Cancel"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.flat = true
	close_button.custom_minimum_size = Vector2(80, 28)
	close_button.add_theme_font_size_override("font_size", font_size)
	close_button.add_theme_font_override("font", custom_font)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.set("theme_override_colors/font_color", Color.WHITE)
	close_button.set("theme_override_colors/font_hover_color", Color.DIM_GRAY)
	close_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	close_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	close_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	hbox.add_child(close_button)

	vbox.add_child(hbox)

	confirm_button.connect("pressed", func(): dialog_confirmed())
	confirm_button.connect("mouse_entered", func(): _on_confirm_button_mouse_entered())
	close_button.connect("pressed", func(): _on_dialog_canceled())
	close_button.connect("mouse_entered", func(): _on_close_button_mouse_entered())


func _on_dialog_canceled():
	get_parent().get_node("Sound/ButtonClickSound").play()
	if !is_inside_tree() or going_back:
		return
	
	conf_dialog_panel.queue_free()
	confirmation_dialog_rendering = false

func dialog_confirmed():
	loading_screen.play_animation()
	going_back = true
	GlobalVars.going_back_to_main_menu = true

	if GlobalVars.instance_script and GlobalVars.instance_script.get_parent():
		GlobalVars.instance_script.get_parent().remove_child(GlobalVars.instance_script)
		GlobalVars.instance_script.queue_free()
		GlobalVars.instance_script = null
	if current_tween:
		current_tween.kill()
		current_tween = null
	AiChoice.easy_selected = false
	AiChoice.med_selected = false
	AiChoice.hard_selected = false
	
	conf_dialog_panel.queue_free()
	await get_tree().create_timer(2.65).timeout
	get_tree().change_scene_to_file("res://scenes/start_menu/menu_global_manager.tscn")
	

# HELP BANNER FUNCTIONS
func _on_help_button_pressed() -> void:
	get_parent().get_node("Sound/ButtonClickSound").play()
	if confirmation_dialog_rendering:
		return
	
	if help_banner.visible == false:
		help_banner.visible = true
	else:
		help_banner.visible = false
		
#MENU FUNCTIONS
func _on_menu_button_pressed() -> void:
	get_parent().get_node("Sound/ButtonClickSound").play()
	if confirmation_dialog_rendering:
		return
	
	if canvas_layer:
		canvas_layer.queue_free()
		canvas_layer = null
		
	if sidebar_menu.visible != true:
		sidebar_menu.visible = true
		screen_dimmer.visible = true
	else:
		sidebar_menu.visible = false
		screen_dimmer.visible = false

func _on_menu_return_button_pressed() -> void:
	get_parent().get_node("Sound/ButtonClickSound").play()
	show_remove_confirmation_dialog()
	
func _on_how_to_play_button_pressed() -> void:
	get_parent().get_node("Sound/ButtonClickSound").play()
	sidebar_menu.visible = false
	menu_button.disabled = true
	help_button.disabled = true
	help_banner.visible = false
	settings_popup.visible = false
	how_to_play_popup.visible = true
	
	how_to_play_instructions.text = GlobalVars.game_instructions[current_instruction]
	
func _on_how_to_play_ok_button_pressed() -> void:
	get_parent().get_node("Sound/ButtonClickSound").play()
	how_to_play_popup.visible = false
	sidebar_menu.visible = true
	menu_button.disabled = false
	help_button.disabled = false
	
	current_instruction = 0
	video_player.stop()
	mort_animation.visible = true
	kuro_animation.visible = true
	how_to_play_instructions.text = GlobalVars.game_instructions[current_instruction]
	
	how_to_play_swipe_left.disabled = true
	how_to_play_swipe_right.disabled = false
	
func _on_settings_button_pressed() -> void:
	get_parent().get_node("Sound/ButtonClickSound").play()
	sidebar_menu.visible = false
	how_to_play_popup.visible = false
	settings_popup.visible = true
	menu_button.disabled = true
	
func _on_settings_ok_button_pressed() -> void:
	get_parent().get_node("Sound/ButtonClickSound").play()
	settings_popup.visible = false
	sidebar_menu.visible = true
	menu_button.disabled = false

func _on_screen_dimmer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and settings_popup.visible == false and how_to_play_popup.visible == false:
		screen_dimmer.visible = false
		sidebar_menu.visible = false
		menu_button.disabled = false
		
		screen_dimmer.accept_event()


func _on_how_to_play_ok_button_mouse_entered() -> void:
	get_parent().get_node("Sound/ButtonHoverSound").play()


func _on_settings_ok_button_mouse_entered() -> void:
	get_parent().get_node("Sound/ButtonHoverSound").play()


func _on_music_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(musicBusID, linear_to_db(value))
	AudioServer.set_bus_mute(musicBusID, value < 0.05)


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfxBusID, linear_to_db(value))
	AudioServer.set_bus_mute(sfxBusID, value < 0.05)


func _on_help_button_mouse_entered() -> void:
	if help_button.disabled == true:
		return
	get_parent().get_node("Sound/ButtonHoverSound").play()


func _on_menu_return_button_mouse_entered() -> void:
	get_parent().get_node("Sound/ButtonHoverSound").play()


func _on_how_to_play_button_mouse_entered() -> void:
	get_parent().get_node("Sound/ButtonHoverSound").play()


func _on_settings_button_mouse_entered() -> void:
	get_parent().get_node("Sound/ButtonHoverSound").play()


func _on_menu_button_mouse_entered() -> void:
	if menu_button.disabled == true:
		return
	get_parent().get_node("Sound/ButtonHoverSound").play()


func _on_win_jingle_finished() -> void:
	get_parent().get_node("Sound/WinMusic").play()


func _on_lose_jingle_finished() -> void:
	get_parent().get_node("Sound/LoseMusic").play()


func _on_swipe_right_pressed() -> void:
	get_parent().get_node("Sound/ButtonClickSound").play()
	if how_to_play_swipe_left.disabled == true:
		how_to_play_swipe_left.disabled = false
	
	if current_instruction < GlobalVars.game_instructions.size() - 1:
		current_instruction += 1
	
	if current_instruction == GlobalVars.game_instructions.size() - 1:
		how_to_play_swipe_right.disabled = true
		
	how_to_play_instructions.text = GlobalVars.game_instructions[current_instruction]
	
	if current_instruction:
		mort_animation.visible = false
		kuro_animation.visible = false
		video_player.stream = GlobalVars.help_videos[current_instruction - 1]
		video_player.play()
	else:
		video_player.stop()
		mort_animation.visible = true
		kuro_animation.visible = true

func _on_swipe_left_pressed() -> void:
	get_parent().get_node("Sound/ButtonClickSound").play()
	if how_to_play_swipe_right.disabled == true:
		how_to_play_swipe_right.disabled = false
		
	if current_instruction > 0:
		current_instruction -= 1
	
	if current_instruction == 0:
		how_to_play_swipe_left.disabled = true
		
	how_to_play_instructions.text = GlobalVars.game_instructions[current_instruction]
	
	if current_instruction:
		mort_animation.visible = false
		kuro_animation.visible = false
		video_player.stream = GlobalVars.help_videos[current_instruction - 1]
		# from video at: https://www.reddit.com/r/godot/comments/pv3irp/loading_videos_into_the_video_player_by_code/?rdt=64730
		video_player.play()
	else:
		video_player.stop()
		mort_animation.visible = true
		kuro_animation.visible = true


func _on_swipe_left_mouse_entered() -> void:
	if how_to_play_swipe_left.disabled == false:
		get_parent().get_node("Sound/ButtonHoverSound").play()


func _on_swipe_right_mouse_entered() -> void:
	if how_to_play_swipe_right.disabled == false:
		get_parent().get_node("Sound/ButtonHoverSound").play()


func _on_music_volume_slider_mouse_entered() -> void:
	get_parent().get_node("Sound/ButtonHoverSound").play()


func _on_sfx_volume_slider_mouse_entered() -> void:
	get_parent().get_node("Sound/ButtonHoverSound").play()


func _on_confirm_button_mouse_entered() -> void:
	get_parent().get_node("Sound/ButtonHoverSound").play()


func _on_close_button_mouse_entered() -> void:
	get_parent().get_node("Sound/ButtonHoverSound").play()


func _on_slider_mouse_entered() -> void:
	get_parent().get_node("Sound/ButtonHoverSound").play()
