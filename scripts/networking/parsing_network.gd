extends Node

class_name ParsingNetwork


func parse_room_string(msg):
	var parts = msg.split("|")
	return parts

func parse_connection_string(msg):
	var parts = msg.split("|")
	return parts


func tiles_placement_to_string(move: Array) -> String:
	var string = ""
	
	for tile in move:
		string += str(tile.x) + "," + str(tile.y) + "|"
	
	return string



func string_to_tiles_coordinates(string: String) -> Array:
	var tiles = []
	
	var tile_strings = string.split("|", false)  # 'false' to ignore trailing empty strings
	
	for tile_str in tile_strings:
		if tile_str == "":
			continue

		var coords = tile_str.split(",")  # Split x and y
		if coords.size() == 2:
			var x = int(coords[0]) 
			var y = int(coords[1]) 
			tiles.append(Vector2i(x, y))  
	
	return tiles


func tile_to_string(tile) -> String:
	return str(str(tile.x) + "," + str(tile.y))

func string_tile_to_tile(string):
	var coords = string.split(",")
	
	if coords.size() == 2:
		var x = int(coords[0]) 
		var y = int(coords[1])
		return Vector2i(x, y)
	
	return null

func string_to_strategic_move(msg: String):
	var parts = msg.split("|")
	
	if parts.size() != 3:
		push_error("Invalid message format: " + msg)
		return null  # Handle incorrect data

	var move_from = parts[0].split(",")
	var move_to = parts[1].split(",")
	var value = int(parts[2])  # Ensure correct integer conversion

	if move_from.size() != 2 or move_to.size() != 2:
		push_error("Invalid move format in message: " + msg)
		return null

	var parsed_move = [ Vector2i( int(move_from[0] ), int( move_from[1]) ), 
					   Vector2i( int( move_to[0] ), int( move_to[1]) ), value]
	
	return parsed_move


	
	
