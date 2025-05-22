extends RefCounted  # does not inherit from anything

class_name GridCalculations

func get_neighbors(tile: Vector2i) -> Array:
	var neighbors = []
	
	if abs(tile.x) % 2 == 1:
		neighbors = [
			tile + Vector2i(0, -1),  # Top
			tile + Vector2i(-1, 0),  # Top left
			tile + Vector2i(1, 0),  # Top right
			tile + Vector2i(0, 1),  # Bottom
			tile + Vector2i(-1, 1),  # Bottom left
			tile + Vector2i(1, 1)  # Bottom right
		]
	else:
		neighbors = [
			tile + Vector2i(0, -1),  # Top
			tile + Vector2i(-1, -1),  # Top left
			tile + Vector2i(1, -1),  # Top right
			tile + Vector2i(0, 1),  # Bottom
			tile + Vector2i(-1, 0),  # Bottom left
			tile + Vector2i(1, 0)  # Bottom right
		]
	
	return neighbors

func convert_string_to_coordinates(placement: String) -> Array:
	var parts = placement.split("|")
	
	if parts.size() != 4:
		print("Invalid input format:", placement)
		return []
	
	var direction = parts[0]
	var row = int(parts[1])
	var col = int(parts[2])

	# Determine placement index
	var placement_index = -1
	match direction:
		"E": placement_index = 0
		"SE": placement_index = 1
		"SW": placement_index = 2
		_: 
			return []	
	var four_coordinates = get_ai_tile_coordinates(placement_index, Vector2i(row, col))
	return four_coordinates

	
	
	
	
# can be used for networking
# var directions = ["east", "south_east", "south_west"]  
func get_ai_tile_coordinates(curr_direction_placement_index, position) -> Array:
	var selection = []

	# south-west = 2
	if curr_direction_placement_index == 2:
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(-1 , 1), # left
				position + Vector2i(0, 1), # right
				position + Vector2i(-1, 2) # bottom
			]
		else:
			selection = [
				position,
				position + Vector2i(-1, 0), # left
				position + Vector2i(0, 1),	# right
				position + Vector2i(-1, 1) # bottom
			]

	# south_east = 1
	if curr_direction_placement_index == 1:
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(0, 1), # left
				position + Vector2i(1, 1), # right
				position + Vector2i(1, 2) # bottom
			]
		else:
			selection = [
				position,
				position + Vector2i(0, 1), # left 
				position + Vector2i(1, 0), # right
				position + Vector2i(1, 1) # bottom
			]
	
	# east = 0
	if curr_direction_placement_index == 0:
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(2, 0), # right
				position + Vector2i(1, 0), # top
				position + Vector2i(1, 1) # bottom
			]
		else:
			selection = [
				position,
				position + Vector2i(2, 0), # right
				position + Vector2i(1, -1), # top
				position + Vector2i(1, 0) # bottom
			]

	return selection


func get_mouse_pos_tiles(curr_direction_placement_index, position) -> Array:
	var selection = []
	
	# south-west = 11
	if curr_direction_placement_index == 11:
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(-1 , 1),
				position + Vector2i(0, 1),
				position + Vector2i(-1, 2)
			]
		else:
			selection = [
				position,
				position + Vector2i(-1, 0),
				position + Vector2i(0, 1),
				position + Vector2i(-1, 1)
			]

	# south_east = 10
	if curr_direction_placement_index == 10:
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(0, 1),
				position + Vector2i(1, 1),
				position + Vector2i(1, 2)
			]
		else:
			selection = [
				position,
				position + Vector2i(0, 1),
				position + Vector2i(1, 0),
				position + Vector2i(1, 1)
			]
	# east_top 8
	if curr_direction_placement_index == 8:
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(0, 1), # bottom
				position + Vector2i(-1, 1), # left
				position + Vector2i(1, 1) # right
			]
		else:
			selection = [
				position,
				position + Vector2i(0, 1), # bottom
				position + Vector2i(-1, 0), # left
				position + Vector2i(1, 0) # right
			]
			
	# east_bottom 9
	if curr_direction_placement_index == 9:
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(0, -1), # top
				position + Vector2i(-1, 0), # left
				position + Vector2i(1,0) # right
			]
		else:
			selection = [
				position,
				position + Vector2i(0, -1), # top
				position + Vector2i(-1, -1), # left
				position + Vector2i(1, -1) # right
			]
	
	
	# north_west_left 3
	if curr_direction_placement_index == 3:
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(0, -1), # top
				position + Vector2i(1, 0), # across
				position + Vector2i(1, 1) # bottom right
			]
		else:
			selection = [
				position,
				position + Vector2i(0, -1), # top
				position + Vector2i(1, -1), # across
				position + Vector2i(1, 0) # bottom right
			]
	
	# north_west_right 4
	if curr_direction_placement_index == 4:
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(-1, 0), # top
				position + Vector2i(-1, 1), # across
				position + Vector2i(0, 1) # bottom
			]
		else:
			selection = [
				position,
				position + Vector2i(-1, -1), # top
				position + Vector2i(-1, 0), # across
				position + Vector2i(0, 1) # bottom
			]
	
	# north-west_bottom = 2
	if curr_direction_placement_index == 2:
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(-1, -1), # top
				position + Vector2i(-1, 0), # top left
				position + Vector2i(0, -1) # top right
			]
		else:
			selection = [
				position,
				position + Vector2i(-1 , -2), # top
				position + Vector2i(-1, -1), # top left
				position + Vector2i(0, -1) # top right
			]

	# north_east_left 6
	if curr_direction_placement_index == 6:
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(1, 0), # top
				position + Vector2i(1, 1), # across
				position + Vector2i(0, 1) # bottom
			]
		else:
			selection = [
				position,
				position + Vector2i(1, -1), # top
				position + Vector2i(1, 0), # across
				position + Vector2i(0, 1) # bottom
			]
	
	# north_east_right 7
	if curr_direction_placement_index == 7:
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(0, -1), # top
				position + Vector2i(-1, 0), # across
				position + Vector2i(-1, 1) # bottom
			]
		else:
			selection = [
				position,
				position + Vector2i(0, -1), # top
				position + Vector2i(-1, -1), # across
				position + Vector2i(-1, 0) # bottom
			]
	
	# north_east_bottom 5
	if curr_direction_placement_index == 5:
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(1, -1), # top
				position + Vector2i(0, -1), # top left
				position + Vector2i(1, 0) # top right
			]
		else:
			selection = [
				position,
				position + Vector2i(1, -2), # top
				position + Vector2i(0, -1), # top left
				position + Vector2i(1, -1) # top right
			]
	
	# west = 1
	if curr_direction_placement_index == 1:
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(-2, 0), # far left
				position + Vector2i(-1, 1), # bottom
				position + Vector2i(-1, 0) # top
			]
		else:
			selection = [
				position,
				position + Vector2i(-2, 0), # far left
				position + Vector2i(-1, 0), # bottom
				position + Vector2i(-1, -1) # top
			]
	
	# east = 0
	if curr_direction_placement_index == 0:
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(2, 0),
				position + Vector2i(1, 0),
				position + Vector2i(1,1)
			]
		else:
			selection = [
				position,
				position + Vector2i(2, 0),
				position + Vector2i(1, -1),
				position + Vector2i(1, 0)
			]

	return selection
	

func get_board_center(board) -> Vector2:
	if board.size() == 0:
		return Vector2(0, 0)  # Default center if no tiles are placed

	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF

	for tile in board.keys():
		min_x = min(min_x, tile.x)
		min_y = min(min_y, tile.y)
		max_x = max(max_x, tile.x)
		max_y = max(max_y, tile.y)

	# Calculate the average position (center of board)
	var center_x = (min_x + max_x) / 2.0
	var center_y = (min_y + max_y) / 2.0
	
	return(Vector2(center_x, center_y))

func is_touching_grid(four_tiles: Array, board, first) -> bool:
	for tile in four_tiles:
		var neighbors = get_neighbors(tile)
		for neighbor in neighbors:
			if not first or neighbor in board:
				return true
	return false


func get_board_neighbors(board, tile):
	var board_neighbors = []
	
	var neighbors = get_neighbors(tile)

	for neighbor in neighbors:
		if neighbor in board:
			board_neighbors.append(neighbor)
	
	return board_neighbors

# not in use rn
func update_board_neighbors(board):
	for tile in board:
		var board_neighbors = []
		
		var neighbors = get_board_neighbors(board, tile)

		for neighbor in neighbors:
			if neighbor in board:
				board_neighbors.append(neighbor)
		
		board[tile]["neighbors"] = board_neighbors
	
	return board

func get_board_bounding_box(board: Dictionary) -> Array:
	# Return [min_vec2i, max_vec2i]
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF

	for tile in board:
		min_x = min(min_x, tile.x)
		min_y = min(min_y, tile.y)
		max_x = max(max_x, tile.x)
		max_y = max(max_y, tile.y)

	return [Vector2i(min_x, min_y), Vector2i(max_x, max_y)]


func flood_fill_external_air(board) -> Array:
	# This will find “outside” and list the tiles that border the board.
	var external_line = []
	var queue = []
	var visited = {}

	# 1. Compute bounding box
	var bounding_box = get_board_bounding_box(board)
	var min_pos = bounding_box[0]
	var max_pos = bounding_box[1]

	# 2. Pick a “guaranteed outside” start tile:
	# e.g. 2 tiles left/up from the bounding box
	var start_tile = Vector2i(min_pos.x - 2, min_pos.y - 2)

	# 3. Initialize BFS
	queue.append(start_tile)
	visited[start_tile] = true

	# 4. BFS within a safe region
	while queue.size() > 0:
		var current = queue.pop_front()

		# If you want, skip if “way outside” a safe margin
		# This prevents infinite wandering if your board is small.
		if current.x < min_pos.x - 20: 
			continue
		if current.x > max_pos.x + 20: 
			continue
		if current.y < min_pos.y - 20: 
			continue
		if current.y > max_pos.y + 20: 
			continue

		# Check neighbors
		for neighbor in get_neighbors(current):
			# If neighbor is part of the board, current is external
			if neighbor in board and current not in board:
				external_line.append(current)

			# If neighbor is NOT in the board and not visited, BFS continues
			if neighbor not in board and neighbor not in visited:
				visited[neighbor] = true
				queue.append(neighbor)

	return external_line
	

func get_possible_positions_to_place_board(board):
	var true_outside_border = flood_fill_external_air(board)
	return true_outside_border

func get_board_margins(board,outside_air):
	var outside_border = []
	
	for tile in outside_air:
		var neighbors = get_neighbors(tile)
		
		for neighbor in neighbors:
			if neighbor in board:
				outside_border.append(neighbor)
	
	return outside_border

func get_tile_orientation(board,outside_border):
	var copy_border = outside_border.duplicate()
	copy_border.shuffle()
	
	for tile in copy_border:
		var indices = range(10)
		indices.shuffle()
		
		# i is current direction placement index 
		for i in indices:
			var four_tiles = get_mouse_pos_tiles(i, tile)
			
			var b = is_touching_grid(four_tiles, board, false)
			if not b:
				continue
			
			var is_valid = true
			for t in four_tiles:
				if t in board:
					is_valid = false
					break
			
			if not is_valid:
				continue  
				
			if i == 0:
				return ["E", tile]
			elif i == 1:
				return ["E", tile + Vector2i(-2, 0)]				
			elif i == 2:
				if abs(tile.x) % 2 == 1:
					return ["SE", tile + Vector2i(-1, -1)]
				else:
					return ["SE", tile + Vector2i(-1, -2)]
			elif i == 3:
				return ["SE", tile + Vector2i(0, -1)]
			elif i == 4:
				if abs(tile.x) % 2 == 1:
					return ["SE", tile + Vector2i(-1, 0)]
				else:
					return ["SE", tile + Vector2i(-1, -1)]
			elif i == 5:
				if abs(tile.x) % 2 == 1:
					return ["SW", tile + Vector2i(1, -1)]
				else:
					return ["SW", tile + Vector2i(1, -2)]
			elif i == 6:
				if abs(tile.x) % 2 == 1:
					return ["SW", tile + Vector2i(1, 0)]
				else:
					return ["SW", tile + Vector2i(1, -1)]
			elif i == 7:
				return ["SW", tile + Vector2i(0, -1)]
			elif i == 8:
				if abs(tile.x) % 2 == 1:
					return ["E", tile + Vector2i(-1, 1)]
				else:
					return ["E", tile + Vector2i(-1, 0)]
			elif i == 9:
				if abs(tile.x) % 2 == 1:
					return ["E", tile + Vector2i(-1, 0)]
				else:
					return ["E", tile + Vector2i(-1, -1)]
			else:
				return []



func get_all_possible_roations(board, outside_border):
	var return_value = []
	var copy_border = outside_border.duplicate()
	copy_border.shuffle()
	
	for tile in copy_border:
		var indices = range(10)
		indices.shuffle() 
		for i in indices:
			var four_tiles = get_mouse_pos_tiles(i, tile)
			
			var b = is_touching_grid(four_tiles, board, false) # false bcs something already exists in board
			if not b:
				continue
			
			var is_valid = true
			for t in four_tiles:
				if t in board:
					is_valid = false
					break
			
			if not is_valid:
				continue  
				
			if i == 0:
				return_value.append(["E", tile])
			elif i == 1:
				return_value.append(["E", tile + Vector2i(-2, 0)])				
			elif i == 2:
				if abs(tile.x) % 2 == 1:
					return_value.append(["SE", tile + Vector2i(-1, -1)])
				else:
					return_value.append(["SE", tile + Vector2i(-1, -2)])
			elif i == 3:
				return_value.append(["SE", tile + Vector2i(0, -1)])
			elif i == 4:
				if abs(tile.x) % 2 == 1:
					return_value.append(["SE", tile + Vector2i(-1, 0)])
				else:
					return_value.append(["SE", tile + Vector2i(-1, -1)])
			elif i == 5:
				if abs(tile.x) % 2 == 1:
					return_value.append(["SW", tile + Vector2i(1, -1)])
				else:
					return_value.append(["SW", tile + Vector2i(1, -2)])
			elif i == 6:
				if abs(tile.x) % 2 == 1:
					return_value.append(["SW", tile + Vector2i(1, 0)])
				else:
					return_value.append(["SW", tile + Vector2i(1, -1)])
			elif i == 7:
				return_value.append(["SW", tile + Vector2i(0, -1)])
			elif i == 8:
				if abs(tile.x) % 2 == 1:
					return_value.append(["E", tile + Vector2i(-1, 1)])
				else:
					return_value.append(["E", tile + Vector2i(-1, 0)])
			elif i == 9:
				if abs(tile.x) % 2 == 1:
					return_value.append(["E", tile + Vector2i(-1, 0)])
				else:
					return_value.append(["E", tile + Vector2i(-1, -1)])
	return return_value













func _is_valid_selection(selection, board):
	for tile in selection:
		if tile in board:  
			return false
	
	
	var first_tile_placed = true if board.size() > 0 else false
	if is_touching_grid(selection, board, first_tile_placed):
		return true
	
	return false

	






func get_user_friendly_mouse_tiles(curr_direction_placement_index, position, board):
	if position == null:
		return []
		
	var selection = []
	
	# north_east == 0
	if curr_direction_placement_index == 0:
		# north_east_left
		selection = []
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(1, 0), # top
				position + Vector2i(1, 1), # across
				position + Vector2i(0, 1) # bottom
			]
		else:
			selection = [
				position,
				position + Vector2i(1, -1), # top
				position + Vector2i(1, 0), # across
				position + Vector2i(0, 1) # bottom
			]
		
		if _is_valid_selection(selection, board):
			return selection
			
		
		# north_east_right 
		selection = []
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(0, -1), # top
				position + Vector2i(-1, 0), # across
				position + Vector2i(-1, 1) # bottom
			]
		else:
			selection = [
				position,
				position + Vector2i(0, -1), # top
				position + Vector2i(-1, -1), # across
				position + Vector2i(-1, 0) # bottom
			]
		
		if _is_valid_selection(selection, board):
			return selection
		
		# north_east_bottom
		selection = []
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(1, -1), # top
				position + Vector2i(0, -1), # top left
				position + Vector2i(1, 0) # top right
			]
		else:
			selection = [
				position,
				position + Vector2i(1, -2), # top
				position + Vector2i(0, -1), # top left
				position + Vector2i(1, -1) # top right
			]
			
		if _is_valid_selection(selection, board):
			return selection
		
		# north_east_top
		selection = []
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(-1, 2), # bottom
				position + Vector2i(-1, 1), # bottom left
				position + Vector2i(0, 1) # bottom right
			]
		else:
			selection = [
				position,
				position + Vector2i(-1, 1), # bottom
				position + Vector2i(-1, 0), # bottom left
				position + Vector2i(0, 1) # bottom right
			]
			
		if _is_valid_selection(selection, board):
			return selection
		
		return []
	
	# east == 1
	if curr_direction_placement_index == 1:
		# east far right
		selection = []
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(-2, 0), # far left
				position + Vector2i(-1, 1), # bottom
				position + Vector2i(-1, 0) # top
			]
		else:
			selection = [
				position,
				position + Vector2i(-2, 0), # far left
				position + Vector2i(-1, 0), # bottom
				position + Vector2i(-1, -1) # top
			]
		
		if _is_valid_selection(selection, board):
			return selection
		
		# east far left
		selection = []
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(2, 0), # far right
				position + Vector2i(1, 0), # top
				position + Vector2i(1, 1) # bottom
			]
		else:
			selection = [
				position,
				position + Vector2i(2, 0), # far right
				position + Vector2i(1, -1), # top
				position + Vector2i(1, 0) # bottom
			]
		
		if _is_valid_selection(selection, board):
			return selection
		
		#east top
		selection = []
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(0, 1), # bottom
				position + Vector2i(-1, 1), # left
				position + Vector2i(1, 1) # right
			]
		else:
			selection = [
				position,
				position + Vector2i(0, 1), # bottom
				position + Vector2i(-1, 0), # left
				position + Vector2i(1, 0) # right
			]
		
		if _is_valid_selection(selection, board):
			return selection
			
		# east_bottom
		selection = []
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(0, -1), # top
				position + Vector2i(-1, 0), # left
				position + Vector2i(1,0) # right
			]
		else:
			selection = [
				position,
				position + Vector2i(0, -1), # top
				position + Vector2i(-1, -1), # left
				position + Vector2i(1, -1) # right
			]
	
		if _is_valid_selection(selection, board):
			return selection
	
		
		
		return []
	
	# south_east == 2
	if curr_direction_placement_index == 2:
		# south_east_left
		selection = []
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(0, -1), # top
				position + Vector2i(1, 0), # across
				position + Vector2i(1, 1) # bottom
			]
		else:
			selection = [
				position,
				position + Vector2i(0, -1), # top
				position + Vector2i(1, -1), # across
				position + Vector2i(1, 0) # bottom
			]
		
		if _is_valid_selection(selection, board):
			return selection
			
		
		# south_east_right 
		selection = []
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(-1, 0), # top
				position + Vector2i(-1, 1), # across
				position + Vector2i(0, 1) # bottom
			]
		else:
			selection = [
				position,
				position + Vector2i(-1, -1), # top
				position + Vector2i(-1, 0), # across
				position + Vector2i(0, 1) # bottom
			]
		
		if _is_valid_selection(selection, board):
			return selection
		
		# south_east_bottom
		selection = []
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(-1, -1), # top
				position + Vector2i(-1, 0), # top left
				position + Vector2i(0, -1) # top right
			]
		else:
			selection = [
				position,
				position + Vector2i(-1, -2), # top
				position + Vector2i(-1, -1), # top left
				position + Vector2i(0, -1) # top right
			]
			
		if _is_valid_selection(selection, board):
			return selection
		
		# south_east_top
		selection = []
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(1, 2), # bottom
				position + Vector2i(0, 1), # bottom left
				position + Vector2i(1, 1) # bottom right
			]
		else:
			selection = [
				position,
				position + Vector2i(1, 1), # bottom
				position + Vector2i(0, 1), # bottom left
				position + Vector2i(1, 0) # bottom right
			]
			
		if _is_valid_selection(selection, board):
			return selection
		
		return []
		
	return selection




func get_shape_for_first_tile(curr_direction_placement_index, position):
	
	var selection = []
	if curr_direction_placement_index == 0:
	# north_east_bottom
		selection = []
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(1, -1), # top
				position + Vector2i(0, -1), # top left
				position + Vector2i(1, 0) # top right
			]
		else:
			selection = [
				position,
				position + Vector2i(1, -2), # top
				position + Vector2i(0, -1), # top left
				position + Vector2i(1, -1) # top right
			]
			
		return selection
	
	if curr_direction_placement_index == 1:
		# east far left
		selection = []
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(2, 0), # far right
				position + Vector2i(1, 0), # top
				position + Vector2i(1, 1) # bottom
			]
		else:
			selection = [
				position,
				position + Vector2i(2, 0), # far right
				position + Vector2i(1, -1), # top
				position + Vector2i(1, 0) # bottom
			]
		return selection
	
	if curr_direction_placement_index == 2:
	# south_east_top
		selection = []
		if abs(position.x) % 2 == 1:
			selection = [
				position,
				position + Vector2i(1, 2), # bottom
				position + Vector2i(0, 1), # bottom left
				position + Vector2i(1, 1) # bottom right
			]
		else:
			selection = [
				position,
				position + Vector2i(1, 1), # bottom
				position + Vector2i(0, 1), # bottom left
				position + Vector2i(1, 0) # bottom right
			]
		return selection
	
	return []
