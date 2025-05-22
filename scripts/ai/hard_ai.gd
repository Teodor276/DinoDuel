extends RefCounted
class_name HardAI

var game_rules = load("res://scripts/game_helpers/game_rules_logic.gd").new()
var grid_calc  = load("res://scripts/game_helpers/GridCalculations.gd").new()


class ReadWriteLock:
	var _reader_mutex := Mutex.new()
	var _writer_mutex := Mutex.new()
	var _readers: int = 0
	var _writers_waiting: int = 0  # Count writers to prevent starvation
	
	func acquire_read() -> void:
		_reader_mutex.lock()
		# Wait until no writers are waiting
		while _writers_waiting > 0:
			_reader_mutex.unlock()
			OS.delay_msec(1)  # Still not ideal, but GDScript lacks better primitives
			_reader_mutex.lock()
		_readers += 1
		if _readers == 1:
			_writer_mutex.lock()  # First reader locks writers out
		_reader_mutex.unlock()
	
	func release_read() -> void:
		_reader_mutex.lock()
		_readers -= 1
		if _readers == 0:
			_writer_mutex.unlock()  # Last reader releases writers
		_reader_mutex.unlock()
	
	func acquire_write() -> void:
		_reader_mutex.lock()
		_writers_waiting += 1
		_reader_mutex.unlock()
		_writer_mutex.lock()
		# Writer has exclusive access now
	
	func release_write() -> void:
		_reader_mutex.lock()
		_writers_waiting -= 1
		_reader_mutex.unlock()
		_writer_mutex.unlock()


# MCTS Node Definition
class MCTSNode:
	var parent: MCTSNode = null
	var children: Array[MCTSNode] = []

	var move_taken
	var current_player
	var board_state

	var visit_count: int = 0
	var win_count: float = 0.0
	
	var ai_instance

	func _init(parent_node, move, player, board_copy, ai_ref):
		parent = parent_node
		move_taken = move
		current_player = player
		board_state = board_copy.duplicate(true)
		ai_instance = ai_ref

	func is_fully_expanded() -> bool:
		var possible_actions = ai_instance._get_all_actions(board_state, current_player)
		return children.size() >= possible_actions.size()

# grid_calc for ai
var even_coordinates_neighbors = [
	Vector2i(0, -1), # north
	Vector2i(1, -1), # north east
	Vector2i(1, 0), # south east
	
	Vector2i(0, 1), # south 
	Vector2i(-1, 0), # south west
	Vector2i(-1, -1) # north west
]

var odd_coordinates_neighbors = [
	Vector2i(0, -1), # north
	Vector2i(1, 0), # north east
	Vector2i(1, 1), # south east
	
	Vector2i(0, 1), # south 
	Vector2i(-1, 1), # south west
	Vector2i(-1, 0) # north west
]
#----------------
# HARD AI CLASS
#----------------
var exploration_constant: float = 1.2
var mcts_time_limit: float = 3.8

var ai_player: int = 1
var human_player: int = 0


var board_size_threshold: int = 32
var current_phase: String = ""

# hold last board so u can get what human did
var previous_move_board: Dictionary = {}

# thread handling
var rw_lock = ReadWriteLock.new()
var start_time = 0
var num_threads = max(OS.get_processor_count() - 1, 2)

var thread_pool_created = false
var thread_pool = []
var stop_flag = false


func create_threads():
	for i in range(num_threads):
		var thread = Thread.new()
		thread_pool.append(thread)
		
	thread_pool_created = true
	
#----------------------
# gets called with this
#----------------------
func get_ai_move(board):
	print("hard")
	previous_move_board = board.duplicate(true)

	var board_copy = board.duplicate(true)
	
	if board_copy.size() == 0:
		return _board_pos_starting_zero()
		
	if thread_pool_created == false:
		create_threads()
	
	current_phase = _get_current_phase(board_copy)
	
	var move
	if current_phase == "board_placement":
		move = _run_mcts(board_copy, ai_player)
	elif current_phase == "initial_stack":
		move = _run_mcts(board_copy, ai_player)
	else:
		move = _run_mcts(board_copy, ai_player)
		
	stop_flag = true
	
	return move
	
#--------------------------------
# first calles from above fuction
#---------------------------------
func _run_mcts(board: Dictionary, player: int):
	
	var root_node = MCTSNode.new(null, null, player, board, self);
	
	start_time = Time.get_ticks_msec()
	
	stop_flag = false
	for thread in thread_pool:
		thread.start(_threaded_mcts_loop.bind(root_node))
		
	for thread in thread_pool:
		thread.wait_to_finish()
	

	var best_child = null
	var best_score = -INF
	
	for child in root_node.children:
		var avg_score = child.win_count / float(child.visit_count + 0.001)
		
		if avg_score > best_score:
			best_score = avg_score
			best_child = child
	
	return best_child.move_taken # myb add what if it does not work

func _threaded_mcts_loop(root_node: MCTSNode) -> void:
	
	while true:
		if stop_flag == true:
			return
		
		var now_time = Time.get_ticks_msec()
		var elapsed_secs = float(now_time - start_time) / 1000.0
		
		if elapsed_secs >= mcts_time_limit:
			break
		
		
			
		var selected = _mcts_select(root_node)
		var expanded = _mcts_expand(selected)
		var result = _mcts_simulate(expanded)
		_mcts_backpropagate(expanded, result)
		

func _mcts_select(node: MCTSNode) -> MCTSNode:
	rw_lock.acquire_read()
	var current_node = node;
	
	while current_node.is_fully_expanded() and current_node.children.size() > 0:
		
		var now_time = Time.get_ticks_msec()
		var elapsed_secs = float(now_time - start_time) / 1000.0
		
		if elapsed_secs >= mcts_time_limit:
			break
			
		var best = current_node.children[0]
		
		var best_score = -INF
		
		for c in current_node.children:
			var exploitation_value = c.win_count / (c.visit_count + 0.001)
			var exploration_value = sqrt(log(max(current_node.visit_count, 1)) / (c.visit_count + 0.001))
			var uct = exploitation_value + exploration_constant * exploration_value
			
			if uct > best_score:
				best_score = uct
				best = c
		
		current_node = best
	
	rw_lock.release_read()
	return current_node
	
	
func _mcts_expand(node: MCTSNode) -> MCTSNode:	
	# for board placement phase: return all possible square placements x posible rotations 
	# for strategy phase: return all possible moves without how many chips you are moving there, only directions
	rw_lock.acquire_write()
	var actions = _get_all_actions(node.board_state, node.current_player)
	
	if actions.is_empty():
		rw_lock.release_write()
		return node
	
	var unexpanded_actions = []
	for action in actions:
		var used = false
		for c in node.children:
			if c.move_taken == action:
				used = true
				break
		if not used:
			unexpanded_actions.append(action)
			
	if unexpanded_actions.size() > 0:
		var action = _select_strongest_move(unexpanded_actions, node.board_state, node.current_player)

		var act = action
		if current_phase != "board_placement" and current_phase != "initial_stack":
			var pieces = _how_many_pieces_to_move(node.board_state, act) # action here is beg tile and target tile
			act.append(pieces)
		
		var next_board = _apply_action(node.board_state, act, node.current_player)
		var next_player = (node.current_player + 1) % 2
		var child_node = MCTSNode.new(node, action, next_player, next_board, self)
		node.children.append(child_node)
		
		rw_lock.release_write()
		return child_node
	
	rw_lock.release_write()
	return node.children[randi() % node.children.size()] if node.children.size() > 0 else node



func _mcts_simulate(node: MCTSNode) -> float:
	rw_lock.acquire_read()
	var sim_board = node.board_state.duplicate(true)
	var sim_player = node.current_player
	var first_move = node.move_taken
	rw_lock.release_read()
	var executed = false

		
	while not game_rules.game_over_upgraded(sim_board, _both_initial_stacks_placed(sim_board), !game_rules.can_move_be_made(sim_board, human_player), !game_rules.can_move_be_made(sim_board, ai_player)):
		if current_phase == "board_placement":
			if sim_board.size() >= 32:
				break
		elif current_phase == "initial_stack":
			if _human_and_ai_placed_initial_stacks(sim_board):
				break
		else: # idea here is that if somebody does not have a move possible, give the turn to somebody else
			if not game_rules.can_move_be_made(sim_board, ai_player) and sim_player == ai_player: # can ai make move
				sim_player = (sim_player + 1) % 2
			elif not game_rules.can_move_be_made(sim_board, human_player) and sim_player == human_player: # can human make move
				sim_player = (sim_player + 1) % 2
		
		
		var now_time = Time.get_ticks_msec()
		var elapsed_secs = float(now_time - start_time) / 1000.0
		if elapsed_secs >= mcts_time_limit:
			break
		
		
		var possible_actions = _get_all_actions(sim_board, sim_player)
		
		if possible_actions.size() == 0:
			sim_player = (sim_player + 1) % 2
			continue
				
		var action;
		
		executed = true
		
		action = _select_strongest_move(possible_actions, sim_board, sim_player)
		
		var act = action
		if current_phase != "board_placement" and current_phase != "initial_stack":
			var pieces = _how_many_pieces_to_move(sim_board, action) # action here is beg tile and target tile
			act.append(pieces)
			
		sim_board = _apply_action(sim_board, act, sim_player)
		sim_player = (sim_player + 1) % 2
		
	if current_phase == "initial_stack" and executed == false: # what happens if the ai goes second, we want this eval
		return _special_eval_initial_stack(sim_board, first_move) # gets executed when ai goes second
	else:
		return _evaluate_result(sim_board)



func _mcts_backpropagate(node: MCTSNode, result: float) -> void:
	rw_lock.acquire_write()
	var current = node
	while current != null:
		current.visit_count += 1
		current.win_count += result
		current = current.parent
	rw_lock.release_write()

#-----------------------
# general funciton calls
#-----------------------
	
func _get_current_phase(board: Dictionary) -> String:
	if board.size() < board_size_threshold:
		return "board_placement"
	
	if not _check_if_ai_placed_initial_stack(board):
		return "initial_stack"
		
	return "strategy"
	
func _get_all_actions(board: Dictionary, player: int) -> Array:
	if current_phase == "board_placement":
		return _generate_possible_board_tile_placements(board)
	elif current_phase == "initial_stack":
		return _generate_initial_stack_positions(board)
	else:
		return _generate_strategy_moves(board, player)

func _apply_action(board: Dictionary, action, player: int):
	var new_board = board.duplicate(true)
	
	if current_phase == "board_placement":
		var placement_coordinates = action[0] + "|" + str(action[1].x) + "|" + str(action[1].y) + "|"
		var hexs_to_place = grid_calc.convert_string_to_coordinates(placement_coordinates)
		for hex in hexs_to_place:
			new_board[hex] = {
			"player": -1,  
			"pieces": 0
			}
		return new_board
	elif current_phase == "initial_stack":
		new_board[action]["player"] = player
		new_board[action]["pieces"] = 16
		return new_board
	else:
		new_board[action[0]]["player"] = 1
		new_board[action[1]]["player"] = 1
		new_board[action[0]]["pieces"] -= action[2]
		new_board[action[1]]["pieces"] += action[2]
		return new_board

func _check_if_human_placed_initial_stack(board):
	for tile in board:
		if board[tile]["player"] == human_player:
			return true
	return false
			
func _check_if_ai_placed_initial_stack(board):
	for tile in board:
		if board[tile]["player"] == ai_player:
			return true
	return false
		
func _both_initial_stacks_placed(board):
	
	if _check_if_ai_placed_initial_stack(board) and _check_if_human_placed_initial_stack(board):
		return true
	
	return false

func _select_strongest_move(actions: Array, board: Dictionary, player: int) -> Variant:
	var best_action: Variant = null
	var best_score = -INF
	var board_copy = board.duplicate(true)

	for action in actions:
		var act = action
		if current_phase != "board_placement" and current_phase != "initial_stack":
			var pieces = _how_many_pieces_to_move(board, action) # action here is beg tile and target tile
			act.append(pieces)
			
		var new_board = _apply_action(board_copy, act, player)
		var score = _heuristic_evaluation(board_copy, new_board, player, act)
		
		if score > best_score:
			best_score = score
			best_action = act
		
		var now_time = Time.get_ticks_msec()
		var elapsed_secs = float(now_time - start_time) / 1000.0
		
		if elapsed_secs >= mcts_time_limit:
			break
			

	return best_action

func _heuristic_evaluation(old_board: Dictionary, new_board: Dictionary, player, action):
	if current_phase == "board_placement":
		return _board_in_placement_phase_move_evaluation(old_board, new_board, player, action)
	elif current_phase == "initial_stack":
		return _board_in_initial_stack_phase_move_evaluation(old_board, new_board, player, action)
	else:
		return _board_in_strategy_phase_move_evaluation(old_board, new_board, player, action)

func _human_and_ai_placed_initial_stacks(board):
	var count = 0
	for tile in board:
		if board[tile]["player"] != -1:
			count += 1
	
	return count >= 2
	
func _evaluate_result(board):
	if current_phase == "board_placement":
		return _board_placement_phase_result_evaluation(board)
	elif current_phase == "initial_stack":
		return _initial_stack_phase_result_evaluation(board)
	else:
			return _strategy_phase_result_evaluation(board)


func _get_who_places_initial_stack_first():
	var size = previous_move_board.size() % 4
	if (size % 2 == 1):
		return human_player
	return ai_player

#-----------------------------
# board placement evaluations
#-----------------------------
func _board_pos_starting_zero():
	var possible = [
		[
			"SE", Vector2i(0,0)
		],
		[
			"E", Vector2i(0, 0)
		],
		[
			"SW", Vector2i(1, -2)
		]
	]
	return possible[randi() % possible.size()]  # Return a random option

	
func _generate_possible_board_tile_placements(board):
	var outside_border = grid_calc.get_possible_positions_to_place_board(board)
	var return_value = grid_calc.get_all_possible_roations(board, outside_border)
	return_value.shuffle()
	return return_value

func _board_in_placement_phase_move_evaluation(old_board, new_board, _player, action):
	var total_score = 0
	
	# pathway scoring
	var places_initial_first = _get_who_places_initial_stack_first()
	var longest_pathway = _get_longest_path_way(new_board)
	if places_initial_first == ai_player:  # Good for AI
		if longest_pathway > 7:
			total_score += 15
		elif longest_pathway > 5:
			total_score += 30
		elif longest_pathway > 4:
			total_score += 25
		elif longest_pathway > 3:
			total_score += 5
	else:  # Bad for AI (human goes first)
		if longest_pathway > 7:
			total_score -= 20
		elif longest_pathway > 5:
			total_score -= 30
		elif longest_pathway > 4:
			total_score -= 25
		elif longest_pathway > 3:
			total_score -= 5
	
	# width - height scoring
	var x_minus_y = _get_x_minus_y(new_board)
	if x_minus_y < 3:
		total_score += 15  # Narrow board is good
	elif x_minus_y < 5:
		total_score += 10  # Narrow board is good
	else:
		total_score -= 15  # Too wide is bad
	
	
	var distance_to_center = _get_distance_to_center(old_board, action[1])
	if distance_to_center < 3:
		total_score += 20
	elif distance_to_center < 5:
		total_score += 10
	elif distance_to_center < 7:
		total_score -= 10
	else:
		total_score -= 30
	
	
	#num ofneighbors
	var total_neighbors = _get_total_num_of_neighbors(old_board, action)
	if total_neighbors == 1:
		total_score -= 5
	elif total_neighbors == 2:
		total_score += 4
	elif total_neighbors == 3:
		total_score += 6
	elif total_neighbors == 4:
		total_score += 8
	elif total_neighbors == 5:
		total_score += 10
	elif total_neighbors == 6:
		total_score += 12
	elif total_neighbors == 7:
		total_score += 14
	elif total_neighbors == 8:
		total_score += 16
	elif total_neighbors == 9:
		total_score += 18
	elif total_neighbors == 10:
		total_score += 20
	else:
		total_score += 40
	
	return total_score
	
func _board_placement_phase_result_evaluation(board):
	var board_evaluation = 0;
	var size = board.size()
	
	var longest_path = _get_longest_path_way(board)
	if size <= 8:
		if longest_path > 1 and longest_path < 5:
			board_evaluation += 5
		else:
			board_evaluation -= 30
	elif size <= 16:
		if longest_path > 1 and longest_path < 5:
			board_evaluation += 5 
		elif longest_path < 8:
			board_evaluation += 6
		else:
			board_evaluation -= 30
	else:
		if longest_path > 1 and longest_path < 5:
			board_evaluation += 5 
		elif longest_path == 5:
			board_evaluation += 6
		elif longest_path < 8:
			board_evaluation += 7
		else:
			board_evaluation -= 30
	
	
	var x_minus_y = _get_x_minus_y(board)	
	if size <= 8:
		if x_minus_y < 3:
			board_evaluation += 4
		elif x_minus_y < 5:
			board_evaluation += 2
		else:
			board_evaluation -= 10
	elif size <= 16:
		if x_minus_y < 5:
			board_evaluation += 6
		elif x_minus_y < 7:
			board_evaluation += 4
		else:
			board_evaluation -= 10
	else:
		if x_minus_y < 9:
			board_evaluation += 12
		elif x_minus_y < 13:
			board_evaluation += 8
		else:
			board_evaluation -= 10
	
	var center_score = 0
	for tile in board.keys():
		var dist = _get_distance_to_center(board, tile)
		if dist < 2:
			center_score += 8
		elif dist < 4:
			center_score += 4
		else:
			center_score -= 5
	board_evaluation += center_score
	
	var connectivity_score = 0
	for tile in board.keys():
		var neighbors = grid_calc.get_neighbors(tile)
		for neighbor in neighbors:
			if neighbor in board:
				connectivity_score += 1
	board_evaluation += connectivity_score

	# add choke point finding

	return board_evaluation




#----------------------------------------
#functions for board placement evaluation
#----------------------------------------
func _get_longest_path_way(new_board):	
	var longest_path = 0
	
	for tile in new_board:
		for i in range(6):
			var directions = even_coordinates_neighbors if abs(tile.x) % 2 == 0 else odd_coordinates_neighbors
			
			var next_tile = tile + directions[i]

			var new_path = 0
			while next_tile in new_board:
				new_path += 1
				var dir = even_coordinates_neighbors if abs(next_tile.x) % 2 == 0 else odd_coordinates_neighbors
				next_tile += dir[i]
			
			if new_path > longest_path:
				longest_path = new_path
	
	return longest_path
			

func _get_distance_to_center(old_board, tile):
	var center_tile = grid_calc.get_board_center(old_board)
	
	var x_dist = abs(center_tile[0] - tile[0])
	var y_dist = abs(center_tile[1] - tile[1])
	
	return min(x_dist, y_dist)


func _get_total_num_of_neighbors(old_board, action):
	var placement_coordinates = action[0] + "|" + str(action[1].x) + "|" + str(action[1].y) + "|"
	var tiles = grid_calc.convert_string_to_coordinates(placement_coordinates)
	var board_neighbors = 0

	for tile in tiles:
		var neighbors = grid_calc.get_neighbors(tile)
		
		for neighbor in neighbors:
			if neighbor in old_board:
				board_neighbors += 1
	
	return board_neighbors
	
func _get_x_minus_y(board):
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF

	for tile in board.keys():
		min_x = min(min_x, tile.x)
		min_y = min(min_y, tile.y)
		max_x = max(max_x, tile.x)
		max_y = max(max_y, tile.y)
	
	var width = max_x - min_x
	var height = max_y - min_y
	
	return abs(width - height)





#-----------------------------------
# initial stack placement main calls
#-----------------------------------
func _special_eval_initial_stack(board, _action): # ai places the stack second
	var board_evaluation = 0
	
	var ai_stack: Vector2i;
	var human_stack: Vector2i;
		
	for tile in board.keys():
		if board[tile]["player"] == ai_player and board[tile]["pieces"] >= 16:
			ai_stack = tile
		elif board[tile]["player"] == human_player and board[tile]["pieces"] >= 16:
			human_stack = tile
	
	var choke_points = _get_all_choke_points(board)
	
	var possible_human_moves = game_rules.move_possible(board, human_stack)
	var possible_ai_moves = game_rules.move_possible(board, ai_stack)
	
	var human_neighbors = grid_calc.get_neighbors(human_stack)
	var ai_neighbors = grid_calc.get_neighbors(ai_stack)
	
	var valid_human_neighbors = []
	var valid_ai_neighbors = []
	
	for tile in human_neighbors:
		if tile in board:
			valid_human_neighbors.append(tile)
	
	for tile in ai_neighbors:
		if tile in board:
			valid_ai_neighbors.append(tile)
	
	board_evaluation += (possible_ai_moves.size() - possible_human_moves.size()) * 15
	
	for move in possible_human_moves:
		var x_diff = abs(human_stack.x - move.x)
		var y_diff = abs(human_stack.y - move.y)
		
		board_evaluation -= (x_diff + y_diff) * 2
	
	for move in possible_ai_moves:
		var x_diff = abs(ai_stack.x - move.x)
		var y_diff = abs(ai_stack.y - move.y)
		
		board_evaluation += (x_diff + y_diff) * 2
	
	if _is_tile_choke_point(board, ai_stack):
		var smaller_region = _num_of_smaller_part_after_choke_point(board, ai_stack)
		if smaller_region < 5:
			board_evaluation += smaller_region * 5
		elif smaller_region < 9:
			board_evaluation += smaller_region * 7			
		elif smaller_region < 13:
			board_evaluation += smaller_region * 9			
		elif smaller_region < 16:
			board_evaluation += smaller_region * 11
		
		var regions = _get_regions_after_removing_choke(board, ai_stack)
		if regions.size() == 2:
			
			var sizeA = regions[0].size()
			var sizeB = regions[1].size()
			
			var larger_region = regions[0] if sizeA >= sizeB else regions[1]
			smaller_region = regions[1] if sizeA >= sizeB else regions[0]
			
			if larger_region.has(human_stack):
				board_evaluation -= 25
				if ai_stack in valid_human_neighbors:
					board_evaluation -= 50
			elif smaller_region.has(human_stack):
				board_evaluation += 50
				if ai_stack in valid_human_neighbors:
					board_evaluation += 50
				
		
	if _is_tile_choke_point(board, human_stack):
		var smaller_region = _num_of_smaller_part_after_choke_point(board, human_stack)
		if smaller_region < 5:
			board_evaluation -= smaller_region * 10
		elif smaller_region < 9:
			board_evaluation -= smaller_region * 15			
		elif smaller_region < 13:
			board_evaluation -= smaller_region * 20			
		elif smaller_region < 16:
			board_evaluation -= smaller_region * 25
		else:
			board_evaluation -= smaller_region * 2
		
		var regions = _get_regions_after_removing_choke(board, human_stack)
		if regions.size() == 2:
			
			var sizeA = regions[0].size()
			var sizeB = regions[1].size()
			
			var larger_region = regions[0] if sizeA >= sizeB else regions[1]
			smaller_region = regions[1] if sizeA >= sizeB else regions[0]
			
			if larger_region.has(ai_stack):
				board_evaluation += 50
				if human_stack in valid_ai_neighbors:
					board_evaluation += 50
			elif smaller_region.has(ai_stack):
				board_evaluation -= 50
				if human_stack in valid_ai_neighbors:
					board_evaluation -= 50
	
	var no_human_board = board.duplicate(true)
	if human_stack in board:
		no_human_board[human_stack]["player"] = -1
	if _is_tile_choke_point(board, ai_stack):
		if ai_stack in valid_human_neighbors:
			board_evaluation += 45
	
	
	# check if u can go to the choke point from there
	for choke in choke_points:
		if choke in possible_ai_moves:
			board_evaluation += 15
	
	for neighbor in ai_neighbors:
		if neighbor in board:
			if board[neighbor]["player"] == human_player:
				if _check_if_human_placed_initial_stack(board):
					board_evaluation += 20
				else:
					board_evaluation += 10
	
	# check if human is in the place of its longest before move
	var longest_move = null
	var longest_distance = 0
	var possible_ai_moves2 = game_rules.move_possible(no_human_board, ai_stack)
	for move in possible_ai_moves2:
		var x_diff = abs(ai_stack.x - move.x)
		var y_diff = abs(ai_stack.y - move.y)
		
		if (x_diff + y_diff) > longest_distance:
			longest_move = move
			longest_distance = (x_diff + y_diff)
	
	var board_clear = board.duplicate(true)
	if human_stack in board:
		board_clear[human_stack]["player"] = -1
	if human_stack in board:
		board_clear[ai_stack]["player"] = -1
	
	var stack_position_places = _generate_initial_stack_positions(board_clear)
	var move_line = _get_the_line(ai_stack, longest_move, no_human_board)
	for tile in move_line:
		if tile in valid_human_neighbors and tile in stack_position_places:
			board_evaluation += -40
	
	var veritcal_lines = _calc_vertical_lines(board)
	var horizontal_lines = _calc_horizontal_lines(board)
	
	var human_on_line = null
	
	for line in veritcal_lines + horizontal_lines:
		if human_stack in line and line.size() == 2:
			human_on_line = null
			break
	
	if human_on_line:
		if ai_stack in human_on_line:
			board_evaluation += 35 + (possible_ai_moves - possible_human_moves) * 15

	var dist_to_center_human = _get_distance_to_center(board, human_stack)
	board_evaluation += dist_to_center_human * 5

	var dist_to_center_ai = _get_distance_to_center(board, ai_stack)
	board_evaluation -= dist_to_center_ai * 5
	 
	
	return board_evaluation
	
	
	
func _generate_initial_stack_positions(board):
	var outside_border = grid_calc.get_possible_positions_to_place_board(board)
	var board_margin = game_rules.get_board_margins(board, outside_border)
	
	var initial_stack_possible_placements = []
	
	for hex in board_margin:
		if board[hex]["player"] == -1:
			initial_stack_possible_placements.append(hex)
	
	initial_stack_possible_placements.shuffle()
	return initial_stack_possible_placements

func _board_in_initial_stack_phase_move_evaluation(old_board, new_board, _player, action): # just evaluate the move without the ai piece
	var move_evaluation = 0
	if _is_tile_choke_point(old_board, action):
		var smaller_region = _num_of_smaller_part_after_choke_point(old_board, action)
		if smaller_region < 5:
			move_evaluation += smaller_region * 5
		elif smaller_region < 9:
			move_evaluation += smaller_region * 7		
		elif smaller_region < 13:
			move_evaluation += smaller_region * 9			
		elif smaller_region < 16:
			move_evaluation += smaller_region * 11


	
	var possible_moves = game_rules.move_possible(new_board, action)
	move_evaluation += possible_moves.size() * 15
	
	var human_neighbors = grid_calc.get_neighbors(action)
	var valid_human_neighbors = []
	for neighbor in human_neighbors:
		if neighbor in old_board:
			valid_human_neighbors.append(neighbor)
			
	
	var longest_move = null
	var longest_distance = 0
	for move in possible_moves:
		var x_diff = abs(action.x - move.x)
		var y_diff = abs(action.y - move.y)
		
		if (x_diff + y_diff) > longest_distance:
			longest_move = move
			longest_distance = (x_diff + y_diff)
		move_evaluation += (x_diff + y_diff) * 3
	
	# check if the opponent can block the longest move
	var stack_position_places = _generate_initial_stack_positions(old_board)
	var move_line = _get_the_line(action, longest_move, old_board)
	for tile in move_line:
		if tile in valid_human_neighbors and tile in stack_position_places:
			move_evaluation += -35
	
	var dist_to_center = _get_distance_to_center(old_board, action)
	move_evaluation -= dist_to_center * 3
	

	
	return move_evaluation
	
	


func _initial_stack_phase_result_evaluation(board): # if ai went first, then evaluate the board based on where the user can have the best placement, less favorable outcome for ai
	var board_evaluation = 0
	
	
	var ai_stack: Vector2i;
	var human_stack: Vector2i;
	
	for tile in board.keys():
		if board[tile]["player"] == ai_player and board[tile]["pieces"] >= 16:
			ai_stack = tile
		elif board[tile]["player"] == human_player and board[tile]["pieces"] >= 16:
			human_stack = tile
	
	
	var board_clean = board.duplicate(true)
	board_clean[human_stack]["player"] = -1
	board_clean[ai_stack]["player"] = -1
	
	var possible_human_moves = game_rules.move_possible(board, human_stack)
	var possibile_ai_moves = game_rules.move_possible(board, ai_stack)
	
	var no_ai_board = board.duplicate(true)
	no_ai_board[ai_stack]["player"] = -1
	var possible_human_moves_before_ai = game_rules.move_possible(no_ai_board, human_stack)
	
	var no_human_board = board.duplicate(true)
	no_ai_board[human_stack]["player"] = -1
	var possible_ai_moves_before_human = game_rules.move_possible(no_human_board, ai_stack)
	
	board_evaluation += possibile_ai_moves.size() * 40 + possible_human_moves.size() * -15
	
	# remove the opponent and get the longest moves for them before opponent placed the stack
	var longest_human_move_before_ai = null
	var longest_human_distance = 0
	for move in possible_human_moves_before_ai:
		var x_diff = abs(ai_stack.x - move.x)
		var y_diff = abs(ai_stack.y - move.y)
		if (x_diff + y_diff) > longest_human_distance:
			longest_human_move_before_ai = move
			longest_human_distance = (x_diff + y_diff)
			
		
	var longest_ai_move_before_human = null
	var longest_ai_distance = 0
	for move in possible_ai_moves_before_human:
		var x_diff = abs(ai_stack.x - move.x)
		var y_diff = abs(ai_stack.y - move.y)
		if (x_diff + y_diff) > longest_ai_distance:
			longest_ai_move_before_human = move
			longest_ai_distance = (x_diff + y_diff)
				
	# check blocking of each others longest line move
	# is ai blecked by human
	var move_line1 = _get_the_line(ai_stack, longest_ai_move_before_human, no_human_board)
	for tile in move_line1:
		if tile == human_stack:
			board_evaluation -= 60
			break
	
	# is human blocked by ai
	var move_line2 = _get_the_line(human_stack, longest_human_move_before_ai, no_ai_board)
	for tile in move_line2:
		if tile == ai_stack:
			board_evaluation += 45
			break
	
		
	for move in possible_human_moves:
		var x_diff = abs(human_stack.x - move.x)
		var y_diff = abs(human_stack.y - move.y)
		
		board_evaluation -= (x_diff + y_diff) * 2
	
	for move in possibile_ai_moves:
		var x_diff = abs(ai_stack.x - move.x)
		var y_diff = abs(ai_stack.y - move.y)
		
		board_evaluation += (x_diff + y_diff) * 2
	
	var human_neighbors = grid_calc.get_neighbors(human_stack)
	var ai_neighbors = grid_calc.get_neighbors(ai_stack)
	
	var valid_human_neighbors = []
	var valid_ai_neighbors = []
	
	for tile in human_neighbors:
		if tile in board:
			valid_human_neighbors.append(tile)
	
	for tile in ai_neighbors:
		if tile in board:
			valid_ai_neighbors.append(tile)
			
	if _is_tile_choke_point(board, ai_stack):
		var smaller_region = _num_of_smaller_part_after_choke_point(board, ai_stack)
		if smaller_region < 5:
			board_evaluation += smaller_region * 5
		elif smaller_region < 9:
			board_evaluation += smaller_region * 7			
		elif smaller_region < 13:
			board_evaluation += smaller_region * 9			
		elif smaller_region < 16:
			board_evaluation += smaller_region * 11
		
		var regions = _get_regions_after_removing_choke(board, ai_stack)
		if regions.size() == 2:
			
			var sizeA = regions[0].size()
			var sizeB = regions[1].size()
			
			var larger_region = regions[0] if sizeA >= sizeB else regions[1]
			smaller_region = regions[1] if sizeA >= sizeB else regions[0]
			
			if larger_region.has(human_stack):
				board_evaluation -= 25
				if ai_stack in valid_human_neighbors:
					board_evaluation -= 50
			elif smaller_region.has(human_stack):
				board_evaluation += 50
				if ai_stack in valid_human_neighbors:
					board_evaluation += 50
				
		
	if _is_tile_choke_point(board, human_stack):
		var smaller_region = _num_of_smaller_part_after_choke_point(board, human_stack)
		if smaller_region < 5:
			board_evaluation -= smaller_region * 10
		elif smaller_region < 9:
			board_evaluation -= smaller_region * 15			
		elif smaller_region < 13:
			board_evaluation -= smaller_region * 20			
		elif smaller_region < 16:
			board_evaluation -= smaller_region * 25
		else:
			board_evaluation -= smaller_region * 2
		
		var regions = _get_regions_after_removing_choke(board, human_stack)
		if regions.size() == 2:
			
			var sizeA = regions[0].size()
			var sizeB = regions[1].size()
			
			var larger_region = regions[0] if sizeA >= sizeB else regions[1]
			smaller_region = regions[1] if sizeA >= sizeB else regions[0]
			
			if larger_region.has(ai_stack):
				board_evaluation += 50
				if human_stack in valid_ai_neighbors:
					board_evaluation += 50
			elif smaller_region.has(ai_stack):
				board_evaluation -= 50
				if human_stack in valid_ai_neighbors:
					board_evaluation -= 50
	
	var veritcal_lines = _calc_vertical_lines(board)
	var horizontal_lines = _calc_horizontal_lines(board)
	
	var human_on_line = null
	
	for line in veritcal_lines + horizontal_lines:
		if human_stack in line and line.size() == 2:
			human_on_line = null
			break
	
	if human_on_line:
		if ai_stack in human_on_line:
			board_evaluation += 35 + (possibile_ai_moves - possible_human_moves) * 15
	
	var dist_to_center_ai = _get_distance_to_center(board, ai_stack)
	board_evaluation -= dist_to_center_ai * 5
	
	return board_evaluation

#-----------------------------------------
# initial stack placement helper functions
#-----------------------------------------
func _is_tile_choke_point(board: Dictionary, tile: Vector2i) -> bool:
	var new_board = board.duplicate(true)
	for t in new_board:
		if new_board[t]["player"] != -1:
			new_board.erase(t)
		
	var all_neighbors = grid_calc.get_neighbors(tile)
	var valid_neighbors = []
	
	for n in all_neighbors:
		if new_board.has(n):
			valid_neighbors.append(n)
	
	if valid_neighbors.size() < 2:
		return false
	
	
	var ignored_tile = tile

	var visited = {}
	var q = []

	q.append(valid_neighbors[0])
	visited[valid_neighbors[0]] = true
	
	while q.size() > 0:
		var current = q.pop_front()
		var neighbors = grid_calc.get_neighbors(current)
		
		for neighbor in neighbors:
			if neighbor != ignored_tile and new_board.has(neighbor) and not visited.has(neighbor):
				visited[neighbor] = true
				q.append(neighbor)
	
	for i in range(1, valid_neighbors.size()):
		if not visited.has(valid_neighbors[i]):
			return true
			  
	return false


func _num_of_smaller_part_after_choke_point(board: Dictionary, choke_tile: Vector2i) -> int:
	var new_board = board.duplicate(true)
	new_board.erase(choke_tile)

	var all_neighbors = grid_calc.get_neighbors(choke_tile)
	var valid_neighbors = []
	for n in all_neighbors:
		if new_board.has(n):
			valid_neighbors.append(n)
			
			
	var visited = {}
	var q = []
	q.append(valid_neighbors[0])
	visited[valid_neighbors[0]] = true

	while q.size() > 0:
		var current = q.pop_front()
		var neighbors = grid_calc.get_neighbors(current)
		
		for neighbor in neighbors:
			if new_board.has(neighbor) and not visited.has(neighbor):
				visited[neighbor] = true
				q.append(neighbor)
	
	var comp_size = visited.size()

	var other_size = new_board.size() - comp_size
	
	return min(comp_size, other_size)


func _get_regions_after_removing_choke(board: Dictionary, choke_tile: Vector2i) -> Array:
	var new_board = board.duplicate(true)
	new_board.erase(choke_tile)
	
	var all_neighbors = grid_calc.get_neighbors(choke_tile)
	var valid_neighbors = []
	for n in all_neighbors:
		if new_board.has(n):
			valid_neighbors.append(n)

	var regionA = {}
	var q = []
	q.append(valid_neighbors[0])
	regionA[valid_neighbors[0]] = true
	
	while q.size() > 0:
		var current = q.pop_front()
		var neighbors = grid_calc.get_neighbors(current)
		
		for neighbor in neighbors:
			if new_board.has(neighbor) and not regionA.has(neighbor):
				regionA[neighbor] = true
				q.append(neighbor)
				
	var regionB = []
	
	for tile in new_board.keys():
		if not regionA.has(tile):
			regionB.append(tile)
			
	return [regionA.keys(), regionB]
		
	
	


#-------------------------------------
# strategic phase
#-------------------------------------
# this returns all possible moves and how many pieces is on that tile rn
func _generate_strategy_moves(board, player):
	var move_array = []

	for beg_tile in board:
		if board[beg_tile]["player"] == player and board[beg_tile]["pieces"] > 1:
			var possible_moves =  game_rules.move_possible(board, beg_tile)
			
			if possible_moves.size() > 0:
				for target in possible_moves:
							move_array.append([beg_tile, target])
	
	move_array.shuffle()
	return move_array # use: [move_array[0][0], move_array[0][1], move_array[0][2]] # last thing actually not added here yet it will be calculated after



func _how_many_pieces_to_move(board, action): 
	# if pieces at tile == return 1...
	# u get player num and pieces at beginning at first
	var beg_tile = action[0]
	var target = action[1]
	
	var player = board[beg_tile]["player"]
	var opponent_player = (player + 1) % 2
	
	var beg_tile_pos_moves = game_rules.move_possible(board, beg_tile).size()
	var target_tile_pos_moves = game_rules.move_possible(board, target).size()
		
	var pieces_available_to_move = board[beg_tile]["pieces"] - 1
	
	if pieces_available_to_move == 1:
		return 1
	
	if target_tile_pos_moves == 0:
		return 1
	
	if beg_tile_pos_moves == 1:
		return pieces_available_to_move
	
	if beg_tile_pos_moves == 1 and _can_opponent_block_me(board, beg_tile, opponent_player):
		return pieces_available_to_move
			
	
	# checks if the opponent is about to close one side on the board
	var line = _get_the_line(beg_tile, target, board)
	var board_no_palyers = board.duplicate(true)
	for tile in board_no_palyers:
		if board_no_palyers[tile]["player"] != -1:
			board_no_palyers.erase(tile)
		
	var choke_point_on_line
	for tile in line:
		if _is_tile_choke_point(board_no_palyers, tile):
			choke_point_on_line = tile
			break
		
	if choke_point_on_line:
		var regions = _get_regions_after_removing_choke(board_no_palyers, choke_point_on_line)
		
		var regionA = regions[0]
		
		var a_size = regionA.size()
		var b_size = regions[1].size()
		
		var beg_tile_in_a = beg_tile in regionA
		
		var diff = abs(a_size - b_size)
		
		var fraction = 1.0/2.0
		
		if a_size > b_size:
			fraction =  (1.0/3.0) if beg_tile_in_a else (2.0/3.0)
		elif b_size > a_size:
			fraction = (2.0/3.0)  if beg_tile_in_a else (1.0/3.0)
		
		if diff < 3:
			fraction = 1.0/2.0
		elif diff < 6:
			if a_size > b_size:
				fraction = (1.0/3.0) if beg_tile_in_a else (2.0/3.0)
			elif b_size > a_size:
				fraction =  (2.0/3.0) if beg_tile_in_a else (1.0/3.0)
		
		return int(clamp(pieces_available_to_move * fraction, 1, pieces_available_to_move))
	
	

	if _is_tile_choke_point(board, target):
		var res = _get_small_region_and_opponent_peices(board, target, opponent_player) # returns [smaller_size_available, opponent_count, opponent_total_pieces]
		var smaller_size = res[0]         
		var opponent_pieces = res[2]
		
		if opponent_pieces <= 1:
			return clamp(smaller_size - opponent_pieces, 1, pieces_available_to_move)
		
		if target_tile_pos_moves <= 1 or _can_opponent_block_me(board, target, opponent_player):
			return 1
		
		if target_tile_pos_moves >= 2:
			return clamp(smaller_size, 1, pieces_available_to_move)

	
	var phase = _get_strategic_phase(board, player)
	
	const MAX_MOVES = 4
	var commit_fraction = 0.0
	
	match target_tile_pos_moves:
		1:
			commit_fraction = 0.1
		2:
			if phase == "early":
				commit_fraction = 0.4
			elif phase == "middle_early":
				commit_fraction = 0.5
			elif phase == "middle_late":
				commit_fraction = 0.4
			else:  # late game
				commit_fraction = 0.2
		3:
			if phase == "early":
				commit_fraction = 0.6
			elif phase == "middle_early":
				commit_fraction = 0.7
			elif phase == "middle_late":
				commit_fraction = 0.5
			else:
				commit_fraction = 0.6
		4:
			if phase == "early":
				commit_fraction = 0.75
			elif phase == "middle_early":
				commit_fraction = 0.70
			elif phase == "middle_late":
				commit_fraction = 0.80
			else:
				commit_fraction = 0.7
		_:
			commit_fraction = 0.85
	
	if phase == "late" and target_tile_pos_moves >= beg_tile_pos_moves:
		# var act = action
		# act.append(int(pieces_available_to_move * commit_fraction))
		# var board_applied_action = _apply_action(board, act, player)
		return pieces_available_to_move
		
	
	var chosen_move = int(pieces_available_to_move * commit_fraction)
	
	# Safety checks:
	if target_tile_pos_moves <= 1:
		if _can_opponent_block_me(board, target, opponent_player):
			chosen_move = 1
	elif target_tile_pos_moves == MAX_MOVES and (phase == "early" or phase == "middle_early"):
		chosen_move = pieces_available_to_move
	
	return clamp(chosen_move, 1, pieces_available_to_move)


func _board_in_strategy_phase_move_evaluation(old_board, new_board, player, action):
	var move_evaluation = 0.0
	
	var source = action[0]
	var target = action[1]
	var opponent_player = (player + 1) % 2
	
	var board_no_pieces = old_board.duplicate(true)
	for tile in old_board:
		if old_board[tile]["player"] != -1:
			board_no_pieces.erase(tile)
			
	var board_no_opp = old_board.duplicate(true)
	for tile in old_board:
		if old_board[tile]["player"] == opponent_player:
			board_no_opp.erase(tile)
	
	var source_tile_pos_moves = game_rules.move_possible(old_board, source)
	var target_tile_pos_moves = game_rules.move_possible(old_board, target)
	
	var _source_neighbors = grid_calc.get_neighbors(source)
	var target_neighbors = grid_calc.get_neighbors(target)
	
	# if opponent can block the target multiple times, it is bad
	var times_opponent_can_block_target = _on_how_many_places_can_opponent_block_me(old_board, target, opponent_player)
	move_evaluation += times_opponent_can_block_target * -5
	
	# if one pos move on target and opponent can block it = bad move
	if times_opponent_can_block_target != 0 and target_tile_pos_moves.size() == 1:
		move_evaluation += times_opponent_can_block_target * -8
	elif times_opponent_can_block_target != 0 and target_tile_pos_moves.size() == 2:
		move_evaluation += times_opponent_can_block_target * -3
		
	# if opponent can block source move from there
	var times_opponent_can_block_source = _on_how_many_places_can_opponent_block_me(old_board, source, opponent_player)
	move_evaluation += times_opponent_can_block_source * 8
	
	if source_tile_pos_moves.size() == 1:
		move_evaluation += 20
	
	# prefer block opponent on the target
	var on_how_many_places_can_I_block_opponent_from_target = on_how_many_places_can_I_block_opponent(old_board, target, player)
	move_evaluation += on_how_many_places_can_I_block_opponent_from_target * 10
	
	
	var opponent_pieces_aiming_on_target = _get_opponents_aiming_on_tile(old_board, target, opponent_player)
	if opponent_pieces_aiming_on_target == 1: # might be very smart strategic placement, a corner, go there
		move_evaluation += 30
	elif opponent_pieces_aiming_on_target == 2:
		move_evaluation += 17
	elif opponent_pieces_aiming_on_target == 0:
		move_evaluation += 35
		
		
	# if this is to get us out of being locked on one side of the board
	var movement_line = _get_the_line(source, target, old_board)
	var board_no_palyers = old_board.duplicate(true)
	for tile in board_no_palyers:
		if board_no_palyers[tile]["player"] != -1:
			board_no_palyers.erase(tile)
	
	var board_with_no_pieces_on_line = old_board.duplicate(true)
	for move in movement_line:
		if old_board.has(move) and old_board[move]["player"] != -1:
			board_with_no_pieces_on_line.erase(move)
	
	var choke_point_on_line = null
	for tile in movement_line:
		if _is_tile_choke_point(board_with_no_pieces_on_line, tile):
			choke_point_on_line = tile
			break
			
	if choke_point_on_line:
		move_evaluation += 65
		
		# ensure that the pieces get additional points for moving to the other side of the board
		var regions = _get_regions_after_removing_choke(board_with_no_pieces_on_line, choke_point_on_line)
		
		var regionA = regions[0]
		var regionB = regions[1]
		
		var a_size = regionA.size()
		var b_size = regions[1].size()
		
		if a_size > b_size:
			if regionA.has(target):
				move_evaluation += 25
		elif a_size < b_size:
			if regionB.has(target):
				move_evaluation += 25
		elif a_size == b_size:
			move_evaluation += 25
			
	
	# prefer moves with a lot of moves available
	move_evaluation +=  target_tile_pos_moves.size() * 3
	
		
	var distance = abs(target.x - source.x) + abs(target.y - source.y)
	var phase = _get_strategic_phase(old_board, player)
	var executed = false
	
	if _is_first_or_second_move(old_board, player): # this is only the first move after the stack palcement
		executed = true
		move_evaluation += 40 + distance * 20
		
		if target_tile_pos_moves.size() <= 2:
			move_evaluation += -50

	if phase == "early":
		if executed == false: 
			move_evaluation += distance * 3.5
	elif phase == "middle_early":
		move_evaluation += distance * 2.5


	# if the tile is a choke point
	if _is_tile_choke_point(old_board, target):
		var res = _get_small_region_and_opponent_peices(old_board, target, opponent_player) # returns [smaller_size_available, opponent_count, opponent_total_pieces]
		var smaller_size = res[0]         
		var opponent_pieces = res[2]
		
		
		if opponent_pieces == 0 or opponent_pieces == 1:
			move_evaluation += (smaller_size - opponent_pieces) * 3 # good
		
		if target_tile_pos_moves.size() <= 1 or _can_opponent_block_me(old_board, target, opponent_player):
			move_evaluation += 5 # decent
		
		if target_tile_pos_moves.size() >= 2: # very good
			move_evaluation += smaller_size * 5
	
	# see if ai or opponent controls a line that splits the board in half
	var veritcal_lines = _calc_vertical_lines(new_board)
	var horizontal_lines = _calc_horizontal_lines(new_board)
	var opp_controled_lines = 0
	var ai_controled_lines = 0
	
	for line in veritcal_lines:
		var opp_count_on_line = 0
		var ai_count_on_line = 0
		for hex in line:
			if new_board[hex]["player"] == 0:
				opp_count_on_line += 1
			if new_board[hex]["player"] == 1:
				ai_count_on_line += 1
				
		if opp_count_on_line == line.size():
			opp_controled_lines += 1
		if ai_count_on_line == line.size():
			ai_controled_lines += 1
			
		if ai_count_on_line == line.size():
			move_evaluation += 15  
		elif opp_count_on_line == line.size():
			move_evaluation -= 15
			
		if ai_count_on_line > opp_count_on_line:
			move_evaluation += 10  
		elif ai_count_on_line < opp_count_on_line:
			move_evaluation -= 5
		else:
			move_evaluation += 8
	
	for line in horizontal_lines:
		var opp_count_on_line = 0
		var ai_count_on_line = 0
		for hex in line:
			if new_board[hex]["player"] == 0:
				opp_count_on_line += 1
			if new_board[hex]["player"] == 1:
				ai_count_on_line += 1
				
		if opp_count_on_line == line.size():
			opp_controled_lines += 1
		if ai_count_on_line == line.size():
			ai_controled_lines += 1
			
		if ai_count_on_line == line.size():
			move_evaluation += 15  
		elif opp_count_on_line == line.size():
			move_evaluation -= 15
			
		if ai_count_on_line > opp_count_on_line:
			move_evaluation += 10  
		elif ai_count_on_line < opp_count_on_line:
			move_evaluation -= 5
		else:
			move_evaluation += 8
	
	move_evaluation += opp_controled_lines * -5 + ai_controled_lines * 10
	
	# how many opponents pieces is target neighboring 
	var total_neigh_pieces_opp = 0
	var total_neigh_pieces_player = 0
	var biggest_distance = 0
	
	for tile in target_neighbors:
		if new_board.has(tile) and new_board[tile]["player"] == opponent_player:
			total_neigh_pieces_opp += new_board[tile]["pieces"]
			
			# find how long of a line is the player blocking
			var possible_moves_opponent = game_rules.move_possible(new_board, tile)
			for move in possible_moves_opponent:
				var move_line = _get_the_line(tile, move, new_board)
				var move_line_size = move_line.size()
				if target in move_line and move_line_size > biggest_distance:
					biggest_distance = move_line_size
		elif new_board.has(tile) and new_board[tile]["player"] == player:
			total_neigh_pieces_player += new_board[tile]["pieces"] 
	
		
	if total_neigh_pieces_opp != 0:
		var block_bonus = 25
				
		if _is_first_or_second_move(old_board, player) == false:
			move_evaluation += total_neigh_pieces_opp * 5 + biggest_distance * 3
			block_bonus = 20
					
			if _is_tile_choke_point(board_no_opp, target):
				block_bonus += 35
				
		else:
			move_evaluation += total_neigh_pieces_opp * 12 + biggest_distance * 3
			
		if phase == "late":
			total_neigh_pieces_opp += total_neigh_pieces_opp * 5
			
		if phase == "early":
			move_evaluation += total_neigh_pieces_player * -10
			move_evaluation += times_opponent_can_block_target * -15
		elif phase == "late":
			move_evaluation += total_neigh_pieces_player * -18
			move_evaluation += times_opponent_can_block_target * -10
		else:
			move_evaluation += total_neigh_pieces_player * -16
			move_evaluation += times_opponent_can_block_target * -8
			
		if _is_important_to_block_opponent(old_board, player): # important to block at the beginning 1, and 2, move after palcing ai
			block_bonus += 40
			move_evaluation -= total_neigh_pieces_player * 25
			
		if _is_tile_choke_point_on_full_board(board_no_pieces, target):
			block_bonus += 35  # Double bonus if blocking a choke point
			move_evaluation -= total_neigh_pieces_player * 18
			
		move_evaluation += block_bonus
		
		move_evaluation += times_opponent_can_block_target * -10
	
	# if it moves there, will it lock some of own pieces??
	for tile in target_neighbors:
		if new_board.has(tile):
			if new_board[tile]["player"] == player and new_board[tile]["pieces"] > 1:
				var p_moves_after_placing = game_rules.move_possible(new_board, tile).size()
				var p_move_possible_before_placing = game_rules.move_possible(old_board, tile).size()
				
				if p_move_possible_before_placing == 1 and p_moves_after_placing == 0:
					move_evaluation -= 45 + new_board[tile]["pieces"] * -10
					
					if phase == "late":
						move_evaluation += -50 # locking yourself is extremely bad in the last phases
					elif phase == "middle_late":
						move_evaluation += -25

				
			elif new_board[tile]["player"] == opponent_player and new_board[tile]["pieces"] > 1:
				var p_moves_after_placing = game_rules.move_possible(new_board, tile).size()
				var p_move_possible_before_placing = game_rules.move_possible(old_board, tile).size()
				
				if p_move_possible_before_placing == 1 and p_moves_after_placing == 0:
					move_evaluation += 15 # maybe we can add that if it is reducing, then add even more points
	
	# is the tile on a choke point? go to the larger region on the first move
	if _is_first_move_after_stack(old_board, player) and _is_tile_choke_point(board_no_opp, source):
		var regions = _get_regions_after_removing_choke(board_with_no_pieces_on_line, source)
		
		var regionA = regions[0]
		var regionB = regions[1]
		
		var a_size = regionA.size()
		var b_size = regionB.size()
		
		if a_size > b_size:
			if regionA.has(target):
				move_evaluation += 35
		elif a_size < b_size:
			if regionB.has(target):
				move_evaluation += 35
		elif a_size == b_size:
			move_evaluation += 35
	
	# is source about to get blocked??
	var threats = _get_opponents_aiming_on_tile(new_board, source, opponent_player)
	var count_num_threats = 0
	for threat in threats:
		if threat == source:
			count_num_threats += 1
	
	var moves_pos_from_source_after_action = game_rules.move_possible(new_board, source).size()
	
	move_evaluation += count_num_threats * -10 + moves_pos_from_source_after_action * 7
	
	
	# if phase is late then include herd size
	if phase == "late":
		var old_herd_size = _get_herd_size(old_board, source, player)
		var new_herd_size = _get_herd_size(new_board, target, player)
		move_evaluation += (new_herd_size - old_herd_size) * 10.0
		
		
	var mobility_player = _get_all_possible_opponent_moves_strategic_phase(new_board, player).size()
	var mobility_opp = _get_all_possible_opponent_moves_strategic_phase(new_board, opponent_player).size()
	move_evaluation += (mobility_player - mobility_opp) * 5.0
	
	


	return move_evaluation

	
	
	
func _strategy_phase_result_evaluation(board):
	var total_score = 0
	
	# check how many choke points have been taken by ai and  human
	var all_choke_points = []
	for tile in board:
		if _is_tile_choke_point_on_full_board(board, tile):
			all_choke_points.append(tile)
	
	var human_choke_points = 0
	var ai_choke_points = 0
	
	for tile in board:
		if tile in all_choke_points:
			if board[tile]["player"] == 0:
				human_choke_points += 1
			elif board[tile]["player"] == 1:
				ai_choke_points += 1
	
	total_score += human_choke_points * -3 + ai_choke_points * 5
	

	
	# see if ai or opponent controls a line that splits the board in half
	var veritcal_lines = _calc_vertical_lines(board)
	var horizontal_lines = _calc_horizontal_lines(board)
	var opp_controled_lines = 0
	var ai_controled_lines = 0
	
	for line in veritcal_lines:
		var opp_count_on_line = 0
		var ai_count_on_line = 0
		for hex in line:
			if board[hex]["player"] == 0:
				opp_count_on_line += 1
			if board[hex]["player"] == 1:
				ai_count_on_line += 1
				
		if opp_count_on_line == line.size():
			opp_controled_lines += 1
		if ai_count_on_line == line.size():
			ai_controled_lines += 1
	
	for line in horizontal_lines:
		var opp_count_on_line = 0
		var ai_count_on_line = 0
		for hex in line:
			if board[hex]["player"] == 0:
				opp_count_on_line += 1
			if board[hex]["player"] == 1:
				ai_count_on_line += 1
				
		if opp_count_on_line == line.size():
			opp_controled_lines += 1
		if ai_count_on_line == line.size():
			ai_controled_lines += 1
	
	total_score += opp_controled_lines * -15 + ai_controled_lines * 20
	
	# get all possibilities of blocking each other in the future
	var total_human_possibilities_of_blocking = 0
	var total_ai_possibilities_of_blocking = 0
	for tile in board:
		if board[tile]["player"] == 1:
			var neighbors = grid_calc.get_neighbors(tile)
			for n in neighbors:
				if board.has(n) and board[n]["player"] == -1:
					var opponent_aims = _get_opponents_aiming_on_tile(board, tile, 0)
					total_human_possibilities_of_blocking += opponent_aims
		elif board[tile]["player"] == 0:
			var neighbors = grid_calc.get_neighbors(tile)
			for n in neighbors:
				if board.has(n) and board[n]["player"] == -1:
					var opponent_aims = _get_opponents_aiming_on_tile(board, tile, 1)
					total_ai_possibilities_of_blocking += opponent_aims
	
	total_score += (total_ai_possibilities_of_blocking - total_human_possibilities_of_blocking) * 5
	
	# get current total_blocing
	var humans_blocked = 0
	var ais_blocked = 0
	for tile in board:
		if board[tile]["player"] == 0:
			var neighbors = grid_calc.get_neighbors(tile)
			for neighbor in neighbors:
				if board.has(neighbor) and board[neighbor]["player"] == 1:
					humans_blocked += 1
		elif board[tile]["player"] == 1:
			var neighbors = grid_calc.get_neighbors(tile)
			for neighbor in neighbors:
				if board.has(neighbor) and board[neighbor]["player"] == 0:
					ais_blocked += 1
	
	total_score += (ais_blocked - humans_blocked) * 10
	
	## check how many pieces r locked
	var human_total_locked_pieces = 0
	var ai_total_locked_pieces = 0
	for tile in board:
		var ai_count = 0
		var human_count = 0
		
		var neighbors = grid_calc.get_neighbors(tile)
		var in_board_neighbors = []
		
		for n in neighbors:
			if board.has(n):
				in_board_neighbors.append(n)
				if board[n]["player"] == 0:
					human_count += 1
				elif board[n]["player"] == 1:
					ai_count += 1
					
		
		if ai_count + human_count == in_board_neighbors.size():
			if board[tile]["player"] == 1:
				ai_total_locked_pieces += board[tile]["pieces"]
			elif board[tile]["player"] == 0:
				human_total_locked_pieces += board[tile]["pieces"]
	
	total_score += (human_total_locked_pieces - ai_total_locked_pieces) * 5

	var ai_herd_max = 0
	var human_herd_max = 0
	
	var ai_mobility = 0
	var human_mobility = 0
	
	for tile in board:
		if board[tile]["player"] == ai_player:
			ai_mobility += game_rules.move_possible(board, tile).size()
			var herd_size = _get_herd_size(board, tile, ai_player)
			if herd_size > ai_herd_max:
				ai_herd_max = herd_size
		else:
			human_mobility += game_rules.move_possible(board, tile).size()
			var herd_size = _get_herd_size(board, tile, human_player)
			if herd_size > human_herd_max:
				human_herd_max = herd_size
				
	var connectivity_score = (ai_herd_max - human_herd_max) * 2
	var mobility_score = (ai_mobility - human_mobility) * 3
	
	total_score += connectivity_score + mobility_score

		
	if game_rules.game_over_upgraded(board, _both_initial_stacks_placed(board), !game_rules.can_move_be_made(board, human_player), !game_rules.can_move_be_made(board, ai_player)):
		var winner = game_rules.get_winner(board)
		if winner == 0:
			total_score += 50
		elif winner == 1:
			total_score += 100
		elif winner == 2:
			total_score -= 100
	

		

	return total_score
	


#-----------------------------------
#strategic phase helper calculations
#-----------------------------------
func _is_important_to_block_opponent(board, player):
	var player_count = 0
	for tile in board:
		if board[tile]["player"] == player:
			player_count += 1
	
	if player_count <= 2 and player_count >= 1: # on the first 2 moves
		return true
	
	
	return false

func _is_tile_choke_point_on_full_board(board: Dictionary, tile: Vector2i) -> bool:
	var new_board = board.duplicate(true)
		
	var all_neighbors = grid_calc.get_neighbors(tile)
	var valid_neighbors = []
	
	for n in all_neighbors:
		if new_board.has(n):
			valid_neighbors.append(n)
	
	if valid_neighbors.size() < 2:
		return false
	
	
	var ignored_tile = tile

	var visited = {}
	var q = []

	q.append(valid_neighbors[0])
	visited[valid_neighbors[0]] = true
	
	while q.size() > 0:
		var current = q.pop_front()
		var neighbors = grid_calc.get_neighbors(current)
		
		for neighbor in neighbors:
			if neighbor != ignored_tile and new_board.has(neighbor) and not visited.has(neighbor):
				visited[neighbor] = true
				q.append(neighbor)
	
	for i in range(1, valid_neighbors.size()):
		if not visited.has(valid_neighbors[i]):
			return true
			  
	return false
	
func _get_opponents_aiming_on_tile(board, tile, opponent_player):
	var count = 0
	
	var opponent_moves = _get_all_possible_opponent_moves_strategic_phase(board, opponent_player)
	
	for move in opponent_moves:
		if move == tile:
			count += 1
	
	return count
	
func on_how_many_places_can_I_block_opponent(board, tile, me_player):
	var count = 0
	var opponent_player = (me_player + 1) % 2
	
	var possible_moves_from_tile = game_rules.move_possible(board, tile)
	for move in possible_moves_from_tile:
		var neighbors = grid_calc.get_neighbors(move)
		for neighbor in neighbors:
			if board.has(neighbor) and board[neighbor]["player"] == opponent_player:
				count += 1
	
	return count
	
	
	
func _on_how_many_places_can_opponent_block_me(board, tile, opponent_player):
	var count = 0
	
	var opponent_moves = _get_all_possible_opponent_moves_strategic_phase(board, opponent_player)
	var neighbors = grid_calc.get_neighbors(tile)
	
	for neighbor in neighbors:
		if board.has(neighbor):
			for move in opponent_moves:
				if neighbor == move:
					count += 1
	
	return count
	
	
	
func _can_opponent_block_me(board, my_tile, opponent_player):
	var opponent_moves = _get_all_possible_opponent_moves_strategic_phase(board, opponent_player)
	var neighbors = grid_calc.get_neighbors(my_tile)
	
	for neighbor in neighbors:
		if board.has(neighbor):
			if neighbor in opponent_moves:
				return true
	
	return false
	
	
func _get_all_possible_opponent_moves_strategic_phase(board, opponent_player):
	var move_array = []

	for beg_tile in board:
		if board[beg_tile]["player"] == opponent_player and board[beg_tile]["pieces"] > 1:
			var possible_moves =  game_rules.move_possible(board, beg_tile)
			
			for target in possible_moves:
				move_array.append(target)
	
	return move_array
	
func _get_the_line(_start_tile, _end_tile, board):
	
	for i in range(6):
		var directions = even_coordinates_neighbors if abs(_start_tile.x) % 2 == 0 else odd_coordinates_neighbors

		var next_tile = _start_tile + directions[i]
		var furthest_tile = _start_tile
		var start_tile = _start_tile
		
		var curr_line = [start_tile]
		while next_tile in board and board[next_tile]["player"] == -1:
			var dir = even_coordinates_neighbors if abs(next_tile.x) % 2 == 0 else odd_coordinates_neighbors
			furthest_tile = next_tile
			curr_line.append(next_tile)
			next_tile += dir[i]
			
		
		if(furthest_tile == _end_tile):
			return curr_line

	return []
	

func _get_small_region_and_opponent_peices(board, choke_tile, opponent_player):
	var new_board = board.duplicate(true)
	new_board.erase(choke_tile)
	
	var all_neighbors = grid_calc.get_neighbors(choke_tile)
	var valid_neighbors = []
	for neighbor in all_neighbors:
		if new_board.has(neighbor):
			valid_neighbors.append(neighbor)
	
	if valid_neighbors.size() == 0:
		return Vector2i(0,0)
	
	var visitedA = {}
	var q = []
	q.append(valid_neighbors[0])
	visitedA[valid_neighbors[0]] = true
	
	while q.size() > 0:
		var current = q.pop_front()
		var neighbors = grid_calc.get_neighbors(current)
		for neighbor in neighbors:
			if new_board.has(neighbor) and not visitedA.has(neighbor):
				visitedA[neighbor] = true
				q.append(neighbor)
		
	var regionA = visitedA
	var regionB = {}
	for tile in new_board.keys():
		if not regionA.has(tile):
			regionB[tile] = true
	
	var smaller_region = regionA if (regionA.size() <= regionB.size()) else regionB
	
	var smaller_size_available = 0
	for tile in board.keys():
		if smaller_region.has(tile):
			smaller_size_available += 1
	
	var opponent_count = 0
	var opponent_total_pieces = 0
	for tile in smaller_region.keys():
		if new_board.has(tile) and new_board[tile]["player"] == opponent_player:
			opponent_count += 1
			opponent_total_pieces += new_board[tile]["pieces"]
	
	return [smaller_size_available, opponent_count, opponent_total_pieces]
		

func _is_first_move_after_stack(board, player): # only the first move and second move
	var player_moves = 0
	for tile in board:
		if board[tile]["player"] == player:
			player_moves += 1
			
	if player_moves <= 1:
		return true
	
	return false
	
func _is_first_or_second_move(board, player): # only the first move and second move
	var player_moves = 0
	for tile in board:
		if board[tile]["player"] == player:
			player_moves += 1
			
	if player_moves <= 2:
		return true
	
	return false
	
func _get_strategic_phase(board, player):
	var player_moves = 0
	for tile in board:
		if board[tile]["player"] == player:
			player_moves += 1
			
	if player_moves <= 3:
		return "early"
	elif player_moves <= 6:
		return "middle_early"
	elif player_moves <= 9:
		return "middle_late"
	return "late"

func _get_all_choke_points(board):
	var choke_pts = []
	for tile in board:
		if _is_tile_choke_point(board, tile):
			choke_pts.append(tile)
	
	return choke_pts
			

func _calc_vertical_lines(board):
	var even_coordinates_up_side = Vector2i(-1, -1)
	var odd_coordinates_up_side = Vector2i(-1, 0)

	var even_coordinates_down_side = Vector2i(1, 0)
	var odd_coordinates_down_side = Vector2i(1, 1)
	
	# going up and down line
	var lines = []
	var already_found_a_line = []
	for tile in board:
		if tile in already_found_a_line:
			continue
		
		var up_move = even_coordinates_up_side if abs(tile.x) % 2 == 0 else odd_coordinates_up_side
		
		var next_tile = tile + up_move
		var start_tile = tile
		
		var curr_line = [start_tile]
		while next_tile in board:
			var up_move1 = even_coordinates_up_side if abs(next_tile.x) % 2 == 0 else odd_coordinates_up_side
			curr_line.append(next_tile)
			next_tile += up_move1
		
		
		
		
		var down_move = even_coordinates_down_side if abs(tile.x) % 2 == 0 else odd_coordinates_down_side
		
		var next_tile1 = tile + down_move
		while next_tile1 in board:
			var down_move1 = even_coordinates_down_side if abs(next_tile1.x) % 2 == 0 else odd_coordinates_down_side
			if not (next_tile1 in curr_line):
				curr_line.append(next_tile1)
			next_tile1 += down_move1

		
		lines.append(curr_line)
		for c in curr_line:
			already_found_a_line.append(c)
		

	return lines
	

func _calc_horizontal_lines(board):
	var even_coordinates_up = Vector2i(0, -1)
	var odd_coordinates_up = Vector2i(0, -1)

	var even_coordinates_down = Vector2i(0, 1)
	var odd_coordinates_down = Vector2i(0, 1)
	
	# going up and down line
	var lines = []
	var already_found_a_line = []
	for tile in board:
		if tile in already_found_a_line:
			continue
		
		var up_move = even_coordinates_up if abs(tile.x) % 2 == 0 else odd_coordinates_up
		
		var next_tile = tile + up_move
		var start_tile = tile
		
		var curr_line = [start_tile]
		while next_tile in board:
			var up_move1 = even_coordinates_up if abs(next_tile.x) % 2 == 0 else odd_coordinates_up
			curr_line.append(next_tile)
			next_tile += up_move1
		
		
		
		
		var down_move = even_coordinates_down if abs(tile.x) % 2 == 0 else odd_coordinates_down
		
		var next_tile1 = tile + down_move
		while next_tile1 in board:
			var down_move1 = even_coordinates_down if abs(next_tile1.x) % 2 == 0 else odd_coordinates_down
			if not (next_tile1 in curr_line):
				curr_line.append(next_tile1)
			next_tile1 += down_move1

		
		lines.append(curr_line)
		for c in curr_line:
			already_found_a_line.append(c)
		
	
	return lines

func _get_herd_size(board, start_tile, player):
	var herd_size = 0
	var visited = {} 
	var q = [start_tile]

	while q.size() > 0:
		var current = q.pop_back()
		
		if visited.get(current, false) or board[current]["player"] != player:
			continue
		
		visited[current] = true
		herd_size += 1
		
		var neighbors = grid_calc.get_neighbors(current)
		for neighbor in neighbors:
			if board.has(neighbor) and not visited.get(neighbor, false):
				q.append(neighbor)
				
	return herd_size
	
