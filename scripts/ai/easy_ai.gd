extends RefCounted
class_name EasyAI

var game_rules = load("res://scripts/game_helpers/game_rules_logic.gd").new()
var grid_calc  = load("res://scripts/game_helpers/GridCalculations.gd").new()

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

#----------------
# EASY AI CLASS
#----------------
var exploration_constant: float = 1.4
var mcts_time_limit: float = 3.8

var ai_player: int = 1
var human_player: int = 0

var initial_stack_placed_ai: bool = false
var initial_stack_placed_human: bool = false

var board_size_threshold: int = 32
var current_phase: String = ""

# hold last board so u can get what human did
var previous_move_board: Dictionary = {}

# track stuff from ai
var num_of_ai_blockings: int = 0

# track stuff from opponents
var opponent_agressiveness: int = 0
var num_of_human_blockings: int = 0

var start_time = 0
var num_threads = max(OS.get_processor_count() - 3, 2)  
var threads = []
var tree_mutex = Mutex.new()
var time_mutex = Mutex.new()

#----------------------
# gets called with this
#----------------------
func get_ai_move(board):
	print("easy")
	previous_move_board = board.duplicate(true)
	
	_check_if_ai_placed_initial_stack(board)
	_check_if_human_placed_initial_stack(board)
	
	var board_copy = board.duplicate(true)
	
	if board_copy.size() == 0:
		return _board_pos_starting_zero()
		
	current_phase = _get_current_phase(board_copy)
	
	if current_phase == "board_placement":
		return _run_mcts(board_copy, ai_player)
	elif current_phase == "initial_stack":
		return _run_mcts(board_copy, ai_player)
	else:
		return _run_mcts(board_copy, ai_player)
	
#--------------------------------
# first calles from above fuction
#---------------------------------
func _run_mcts(board: Dictionary, player: int):
	
	var root_node = MCTSNode.new(null, null, player, board, self);
	
	start_time = Time.get_ticks_msec()
	
	threads.clear()
	for i in range(num_threads):
		var thread = Thread.new()
		thread.start(_threaded_mcts_loop.bind(root_node))
		threads.append(thread)
	
	for thread in threads:
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
		time_mutex.lock()
		var now_time = Time.get_ticks_msec()
		var elapsed_secs = float(now_time - start_time) / 1000.0
		
		if elapsed_secs >= mcts_time_limit:
			time_mutex.unlock()
			break
		
		time_mutex.unlock()
		
			
		var selected = _mcts_select(root_node)
		var expanded = _mcts_expand(selected)
		var result = _mcts_simulate(expanded)
		_mcts_backpropagate(expanded, result)
		

func _mcts_select(node: MCTSNode) -> MCTSNode:
	tree_mutex.lock()
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
	
	tree_mutex.unlock()
	return current_node
	
	
func _mcts_expand(node: MCTSNode) -> MCTSNode:	
	# for board placement phase: return all possible square placements x posible rotations 
	# for strategy phase: return all possible moves without how many chips you are moving there, only directions
	tree_mutex.lock()
	var actions = _get_all_actions(node.board_state, node.current_player)
	
	if actions.is_empty():
		tree_mutex.unlock()
		return node
	
	for action in actions:
		var used = false
		
		for c in node.children:
			if c.move_taken == action:
				used = true
				break
				
		if not used: # expand by choosing the best move ig, this needs to be changed
			var act = action
			if current_phase != "board_placement" and current_phase != "initial_stack":
				var pieces = _how_many_pieces_to_move(node.board_state, action) # action here is beg tile and target tile
				act.append(pieces)
			
			var next_board = _apply_action(node.board_state, act, node.current_player)
			var next_player = (node.current_player + 1) % 2
			var child_node = MCTSNode.new(node, action, next_player, next_board, self)
			node.children.append(child_node)
			
			tree_mutex.unlock()
			return child_node
	
	tree_mutex.unlock()
	return node.children[randi() % node.children.size()] if node.children.size() > 0 else node



func _mcts_simulate(node: MCTSNode) -> float:
	tree_mutex.lock()
	var sim_board = node.board_state.duplicate(true)
	var sim_player = node.current_player
	tree_mutex.unlock()

	var max_depth = 20 # maybe change that
		
	var depth = 0
	while not game_rules.game_over(sim_board, _both_initial_stacks_placed()) and depth < max_depth:
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
				
		time_mutex.lock()
		
		var now_time = Time.get_ticks_msec()
		var elapsed_secs = float(now_time - start_time) / 1000.0
		if elapsed_secs >= mcts_time_limit:
			time_mutex.unlock()
			break
		
		time_mutex.unlock()

		depth += 1
		
		var possible_actions = _get_all_actions(sim_board, sim_player)
		
		if possible_actions.size() == 0:
			sim_player = (sim_player + 1) % 2
			continue
				
		var action;
		
		if randf() < 0.8 or depth < 5:  
			action = _select_strongest_move(possible_actions, sim_board, sim_player)
		else: 
			action = possible_actions[randi() % possible_actions.size()]
		
		var act = action
		if current_phase != "board_placement" and current_phase != "initial_stack":
			var pieces = _how_many_pieces_to_move(sim_board, action) # action here is beg tile and target tile
			act.append(pieces)
			
		sim_board = _apply_action(sim_board, act, sim_player)
		sim_player = (sim_player + 1) % 2
		
	return _evaluate_result(sim_board)



func _mcts_backpropagate(node: MCTSNode, result: float) -> void:
	tree_mutex.lock()
	var current = node
	while current != null:
		current.visit_count += 1
		current.win_count += result
		current = current.parent
	tree_mutex.unlock()

	
	
	
#-----------------------
# general funciton calls
#-----------------------
func _get_current_phase(board: Dictionary) -> String:
	if board.size() < board_size_threshold:
		return "board_placement"
	
	if not initial_stack_placed_ai:
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
		initial_stack_placed_ai = true
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
			initial_stack_placed_human = true
			break
			
func _check_if_ai_placed_initial_stack(board):
	for tile in board:
		if board[tile]["player"] == ai_player:
			initial_stack_placed_ai = true
			break
		
func _both_initial_stacks_placed():
	if initial_stack_placed_ai and initial_stack_placed_human:
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
	
	var traps = _detect_traps(new_board)
	total_score -= traps * 3
	
	
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

	var traps = _detect_traps(board)
	board_evaluation -= traps * 2 

	return board_evaluation




#----------------------------------------
#functions for board placement evaluation
#----------------------------------------
func _get_longest_path_way(new_board):	
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


func _detect_traps(board: Dictionary) -> int: # tiles with one exit 
	var trap_count = 0

	for tile in board.keys():
		var neighbors = grid_calc.get_neighbors(tile)
		var open_paths = 0

		for neighbor in neighbors:
			if neighbor in board:
				open_paths += 1

		if open_paths == 1:
			trap_count += 1

	return trap_count




#-----------------------------------
# initial stack placement main calls
#-----------------------------------
func _generate_initial_stack_positions(board):
	var outside_border = grid_calc.get_possible_positions_to_place_board(board)
	var board_margin = game_rules.get_board_margins(board, outside_border)
	
	var initial_stack_possible_placements = []
	
	for hex in board_margin:
		if board[hex]["player"] == -1:
			initial_stack_possible_placements.append(hex)
	
	initial_stack_possible_placements.shuffle()
	return initial_stack_possible_placements

func _board_in_initial_stack_phase_move_evaluation(old_board, new_board, _player, action):
	var move_evaluation = 0
	if _is_tile_choke_point(old_board, action):
		var smaller_region = _num_of_smaller_part_after_choke_point(old_board, action)
		if initial_stack_placed_human == false:
			if smaller_region < 5:
				move_evaluation += smaller_region * 10
			elif smaller_region < 9:
				move_evaluation += smaller_region * 15			
			elif smaller_region < 13:
				move_evaluation += smaller_region * 20			
			elif smaller_region < 16:
				move_evaluation += smaller_region * 25
			else:
				move_evaluation += smaller_region * 2
		else:
			if smaller_region < 5:
				move_evaluation += smaller_region * 10
			elif smaller_region < 9:
				move_evaluation += smaller_region * 15			
			elif smaller_region < 13:
				move_evaluation += smaller_region * 20
			elif smaller_region < 16:
				move_evaluation += smaller_region * 25
			else:
				move_evaluation -= smaller_region * 15		
	
	var possible_moves = game_rules.move_possible(old_board, action)
	move_evaluation += possible_moves.size() * 25
	
	for move in possible_moves:
		var x_diff = abs(action.x - move.x)
		var y_diff = abs(action.y - move.y)
		
		move_evaluation += (x_diff + y_diff) * 2
	
	var tile_neighbors = grid_calc.get_neighbors(action)
	for neighbor in tile_neighbors:
		if neighbor in new_board:
			if new_board[neighbor]["player"] == ai_player:
				move_evaluation += 20
				break
	
	var dist_to_center = _get_distance_to_center(old_board, action)
	if dist_to_center < 2:
		move_evaluation += 15
	elif dist_to_center < 4:
		move_evaluation += 7
	else:
		move_evaluation -= 5
	

	
	return move_evaluation
	
	


func _initial_stack_phase_result_evaluation(board):
	var board_evaluation = 0
	
	var ai_stack: Vector2i;
	var human_stack: Vector2i;
	
	for tile in board.keys():
		if board[tile]["player"] == ai_player and board[tile]["pieces"] >= 16:
			ai_stack = tile
		elif board[tile]["player"] == human_player and board[tile]["pieces"] >= 16:
			human_stack = tile
	
	var possible_human_moves = game_rules.move_possible(board, human_stack)
	var possbile_ai_moves = game_rules.move_possible(board, ai_stack)
	
	board_evaluation += possbile_ai_moves.size() * 15 + possible_human_moves.size() * -15
	
	for move in possible_human_moves:
		var x_diff = abs(human_stack.x - move.x)
		var y_diff = abs(human_stack.y - move.y)
		
		board_evaluation -= (x_diff + y_diff) * 2
	
	for move in possbile_ai_moves:
		var x_diff = abs(ai_stack.x - move.x)
		var y_diff = abs(ai_stack.y - move.y)
		
		board_evaluation += (x_diff + y_diff) * 2
	
	var ai_dist = _get_distance_to_center(board, ai_stack)
	var human_dist = _get_distance_to_center(board, human_stack)
	
	if ai_dist < 2:
		board_evaluation += 15
	elif ai_dist < 4:
		board_evaluation += 7
	else:
		board_evaluation -= 5
	
	if human_dist < 2:
		board_evaluation -= 15
	elif human_dist < 4:
		board_evaluation -= 7
	else:
		board_evaluation += 15
	
	if _is_tile_choke_point(board, ai_stack):
		var smaller_region = _num_of_smaller_part_after_choke_point(board, ai_stack)
		if smaller_region < 5:
			board_evaluation += smaller_region * 10
		elif smaller_region < 9:
			board_evaluation += smaller_region * 15			
		elif smaller_region < 13:
			board_evaluation += smaller_region * 20			
		elif smaller_region < 16:
			board_evaluation += smaller_region * 25
		else:
			board_evaluation += smaller_region * 2
		
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
	
	var ai_neighbors = grid_calc.get_neighbors(ai_stack)
	for neighbor in ai_neighbors:
		if neighbor in board:
			if board[neighbor]["player"] == human_player:
				if initial_stack_placed_human:
					board_evaluation += 20
				else:
					board_evaluation += 10
	
	return board_evaluation

#-----------------------------------------
# initial stack placement helper functions
#-----------------------------------------
func _is_tile_choke_point(board: Dictionary, tile: Vector2i) -> bool:
	var all_neighbors = grid_calc.get_neighbors(tile)
	var valid_neighbors = []
	
	for n in all_neighbors:
		if board.has(n):
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
			if neighbor != ignored_tile and board.has(neighbor) and not visited.has(neighbor):
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



func _how_many_pieces_to_move(board, action): # action is move from to move to
	# if pieces at tile == return 1...
	# u get player num and pieces at beginning at first
	var beg_tile = action[0]
	var target = action[1]
	
	var player = board[beg_tile]["player"]
	var opponent_player = (player + 1) % 2
	
	var pieces_available_to_move = board[beg_tile]["pieces"] - 1
	
	if pieces_available_to_move == 1:
		return 1
	
	if _is_tile_choke_point(board, target):
		var res = _get_small_region_and_opponent_peices(board, target, opponent_player)
		var smaller_size = res.x
		var opponent_count = res.y
		var half_of_small = smaller_size / 2
		
		if opponent_count < half_of_small:
			var return_value = smaller_size
			
			while(return_value > pieces_available_to_move):
				return_value -= 1
			
			return clamp(return_value, 1, pieces_available_to_move)
			
	
	if randf() < 0.25: # just get some randomness in testing
		return randi_range(1, pieces_available_to_move)
	
	var phase = _get_strategic_phase(board) # return early, middle, end
	var phase_value = 0
	if phase == "early":
		phase_value = 	int(pieces_available_to_move / 2)
	elif phase ==  "middle":
		phase_value = 2 if pieces_available_to_move > 3 else 1
	else:
		phase_value = 1
	
	var moves_from_target = game_rules.move_possible(board, target).size()
	var mobility_value = clamp(moves_from_target, 1, pieces_available_to_move) # just ensures that the value is between 1 and max avialabitiy to move
	
	var chosen_move = int((phase_value + mobility_value) / 2)
	
	return clamp(chosen_move, 1, pieces_available_to_move)


func _board_in_strategy_phase_move_evaluation(old_board, new_board, player, action):
	var move_evaluation = 0.0
	
	var source = action[0]
	var target = action[1]
	var opponent_player = (player + 1) % 2
	
	# prefer moves with a lot of moves available
	move_evaluation +=  game_rules.move_possible(old_board, target).size() * 10.0
	
	#blocking potential
	var target_neighbors = grid_calc.get_neighbors(target)
	for neighbor in target_neighbors:
		if old_board.has(neighbor) and old_board[neighbor]["player"] == opponent_player:
			move_evaluation += 15
			break
	
	#prefer bigger explansions at the beginning to get more control of the board
	var phase = _get_strategic_phase(old_board)
	var distance = abs(target.x - source.x) + abs(target.y - source.y)
	match phase:
		"early":
			move_evaluation += distance * 3.0
		"middle":
			move_evaluation += distance * 2.0
		"end":
			move_evaluation += distance * 1.0
	
	#prefer close to center to kinda control it
	var dist_center = _get_distance_to_center(old_board, target)
	if dist_center < 2:
		move_evaluation += 8
	elif dist_center < 4:
		move_evaluation += 4
	else:
		move_evaluation += -2
	
	if _is_tile_choke_point(old_board, target):
		var smaller_reg_size = _num_of_smaller_part_after_choke_point(old_board, source)
		move_evaluation += smaller_reg_size * 10
	
	var old_herd_size = _get_herd_size(old_board, source, player)
	var new_herd_size = _get_herd_size(new_board, target, player)
	move_evaluation += (new_herd_size - old_herd_size) * 10.0
	
	return move_evaluation
	

	
	
	
	
func _strategy_phase_result_evaluation(board):
	var ai_mobility = 0
	var human_mobility = 0
	
	var ai_herd_max = 0
	var human_herd_max = 0
	
	var ai_dist_total = 0.0
	var human_dist_total = 0.0
	
	var ai_count = 0
	var human_count = 0
	
	for tile in board:
		if board[tile]["player"] == ai_player:
			ai_mobility += game_rules.move_possible(board, tile).size()
			var herd_size = _get_herd_size(board, tile, ai_player)
			if herd_size > ai_herd_max:
				ai_herd_max = herd_size
			ai_dist_total += _get_distance_to_center(board, tile)
			ai_count += 1
		else:
			human_mobility += game_rules.move_possible(board, tile).size()
			var herd_size = _get_herd_size(board, tile, human_player)
			if herd_size > human_herd_max:
				human_herd_max = herd_size
			human_dist_total += _get_distance_to_center(board, tile)
			human_count += 1
	
	
	var ai_avg_dist = ai_dist_total / ai_count
	var human_avg_dist = human_dist_total / human_count
	
	var mobility_score = (ai_mobility - human_mobility) * 5.0
	var connectivity_score = (ai_herd_max - human_herd_max) * 10.0
	var center_score = (human_avg_dist - ai_avg_dist) * 6.0
	
	var phase = _get_strategic_phase(board)
	if phase == "early" or phase == "middle":
		mobility_score *= 1.5
		connectivity_score *= 1.2
	else:
		mobility_score *= 0.5
		connectivity_score *= 1.4
		center_score *= 0.7
	
	var total_score = mobility_score + connectivity_score + center_score
	
	total_score += _count_blocking_advantage(board)
	
	if game_rules.game_over(board, _both_initial_stacks_placed()):
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
	var smaller_size = smaller_region.size()
	
	var opponent_count = 0
	for tile in smaller_region.keys():
		if new_board.has(tile) and new_board[tile]["player"] == opponent_player:
			opponent_count += 1
	
	return Vector2i(smaller_size, opponent_count)
		
	
	
	
func _get_strategic_phase(board):
	var ai_moves_made = 0
	for tile in board:
		if board[tile]["player"] == ai_player:
			ai_moves_made += 1
			
	if ai_moves_made <= 4:
		return "early"
	elif ai_moves_made <= 9:
		return "middle"
	
	return "end"
	



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
	

func _count_blocking_advantage(board):
	var score = 0.0
	for tile in board.keys():
		if board[tile]["player"] == ai_player:
			var neighbors = grid_calc.get_neighbors(tile)
			
			for n in neighbors:
				if board.has(n) and board[n]["player"] == human_player:
					score += 2.0
	return score
