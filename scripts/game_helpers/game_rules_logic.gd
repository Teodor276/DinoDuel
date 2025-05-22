extends RefCounted  # does not inherit from anything

class_name GameLogic

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

func get_neighbors(tile: Vector2i) -> Array:
	var neighbors = []
	var offsets = even_coordinates_neighbors if abs(tile.x) % 2 == 0 else odd_coordinates_neighbors
	
	for offset in offsets:
		neighbors.append(tile + offset)
	
	return neighbors

func get_board_margins(board,outside_air):
	var outside_border = []
	
	for tile in outside_air:
		var neighbors = get_neighbors(tile)
		
		for neighbor in neighbors:
			if neighbor in board:
				outside_border.append(neighbor)
	
	return outside_border
				

# returns possible moves from this	
func move_possible(board, tile):
	var possible_moves = []

	for i in range(6):
		var directions = even_coordinates_neighbors if abs(tile.x) % 2 == 0 else odd_coordinates_neighbors

		var next_tile = tile + directions[i]
		var furthest_tile = tile
		var start_tile = tile
		
		while next_tile in board and board[next_tile]["player"] == -1:
			var dir = even_coordinates_neighbors if abs(next_tile.x) % 2 == 0 else odd_coordinates_neighbors
			furthest_tile = next_tile
			next_tile += dir[i]
		
		if(furthest_tile != start_tile):
			possible_moves.append(furthest_tile)

	return possible_moves

		
func get_empty_next_to_board(board_copy) -> Array:
	var empty_tiles = []

	for tile in board_copy:
		var neighbors = get_neighbors(tile)
		for neighbor in neighbors:
			if neighbor not in board_copy and neighbor not in empty_tiles:
				empty_tiles.append(neighbor)
	
	return empty_tiles


# gets 0 for HUMAN, and 1 for AI
func can_move_be_made(board, turn) -> bool:
	var ai_human_pieces = 0 if turn == 0 else 1
	for tile in board:
		if board[tile]["player"] == ai_human_pieces and board[tile]["pieces"] > 1: # leaves the minimum on with 1
			var possible_moves = move_possible(board, tile)
			if possible_moves.size() != 0:
				return true
	return false

func game_over(board, initial_stacks_placed) -> bool:
	if not initial_stacks_placed:
		return false
	
	# check if ai can make move
	var ai_possible_move = can_move_be_made(board, 1)
	if ai_possible_move:
		return false
		
	# check if human can make move
	var human_possible_move = can_move_be_made(board, 0)
	if human_possible_move:
		return false

	
	return true

func game_over_upgraded(board, initial_stacks_placed, user_never_goes_again, ai_never_goes_again) -> bool:
	if not initial_stacks_placed:
		return false
	
	var ai_count = 0
	var human_count = 0
	
	for tile in board:
		if board[tile]["player"] == 0:
			human_count += 1
		elif board[tile]["player"] == 1:
			ai_count += 1
	
	if user_never_goes_again and (ai_count > human_count):
		return true
		
	if ai_never_goes_again and (human_count > ai_count):
		return true
	
	var ai_possible_move = can_move_be_made(board, 1)
	if ai_possible_move:
		return false
		
	# check if human can make move
	var human_possible_move = can_move_be_made(board, 0)
	if human_possible_move:
		return false
		
	return true

func find_herd(start_tile: Vector2i, player: int, visited, board) -> int:
	var herd_size = 0
	var queue = [start_tile]

	while not queue.is_empty():
		var current = queue.pop_back()
		if visited.get(current, false) || board[current]["player"] != player:
			continue
			
		visited[current] = true
		herd_size += 1
		
		# Get all neighbors using existing game logic
		var neighbors = get_neighbors(current)
		for neighbor in neighbors:
			if board.has(neighbor) && !visited.get(neighbor, false):
				queue.append(neighbor)
	
	return herd_size

func get_most_connected_herd_player(board) -> int:
	var visited := {}
	var max_human = 0
	var max_ai = 0
	for tile in board:
		if visited.has(tile) || board[tile]["player"] == -1 || board[tile]["pieces"] == 0:
			continue

		var player = board[tile]["player"]
		var herd_size = find_herd(tile, player, visited, board)

		if player == 0:  # Human
			max_human = max(max_human, herd_size)
		elif player == 1:  # AI
			max_ai = max(max_ai, herd_size)

	# Determine winner
	if max_ai > max_human:
		return 1
	elif max_human > max_ai:
		return 2
	else:
		return 0  
	
	
	
	
		
# return 0 for tie, 2 for human, 1 for ai
#i am calculating unplaced stacks, i am not calculating the who gets more tiles
func get_winner(board) -> int:
	var ai_over_stacks = 0
	var human_over_stacks = 0
	
	for tile in board:
		var pieces = board[tile]["pieces"]
		var player = board[tile]["player"]
		
		if pieces > 1:
			if player == 0:
				human_over_stacks += pieces - 1
			if player == 1:
				ai_over_stacks += pieces - 1
			
	if ai_over_stacks < human_over_stacks:
		return 1
	elif human_over_stacks < ai_over_stacks:
		return 2
	
	
	
	return get_most_connected_herd_player(board)
	
	
	
