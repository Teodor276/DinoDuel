extends Node


class_name AI_vs_AI_networking

var board = {}
var uuid = ""
var http_request
var send_request

var url_get = 'https://softserve.harding.edu/aivai/play-state'
var header_get = ['accept: application/json']

var url_send = 'https://softserve.harding.edu/aivai/submit-action'
var header_send = ["accept: application/json", "Content-Type: application/json"]

signal got_board
signal sent_move

#-----------------------------------
#function call from the other file
#----------------------------------
func get_networking_board():
	board = {}
	uuid = ""
	http_request = HTTPRequest.new()
	
	_request_board()
	
	await got_board
	return [board, uuid]


func send_networking_move(move, uuid_gotten):
	send_request = HTTPRequest.new()
	add_child(send_request)
	send_request.request_completed.connect(_on_send_move_completed)
	call_deferred("_do_send_move", move, uuid_gotten)
	
	await sent_move
	return

#----------------
#sending the move
#----------------
func _do_send_move(move, uuid_gotten):
	# Build the JSON payload.
	var data = {
		"action": move,
		"uuid": uuid_gotten
	}
	var json_send = JSON.stringify(data)
	var error = send_request.request(url_send, header_send, HTTPClient.METHOD_POST, json_send)
	
	if error != OK:
		print("An error occurred in the send_move HTTP request:", error)

func _on_send_move_completed(_result, response_code, _headers, body):
	print("Send move completed with response code:", response_code)
	
	if response_code != 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		print(json)
		
	send_request.queue_free()
	send_request = null
	emit_signal("sent_move")



#------------------
#getting the state
#------------------

func _request_board():
	self.add_child(http_request)
	http_request.request_completed.connect(_on_request_board_completed)
	call_deferred("_do_request_board")

func _do_request_board():

	var error = http_request.request(url_get, header_get, HTTPClient.METHOD_POST, "")

	if error != OK:
		print("An error occurred in the HTTP request, error code: ", error)
		http_request.queue_free()  # Clean up on error
		http_request = null
		await get_tree().create_timer(2.0).timeout
		http_request = HTTPRequest.new()
		_request_board()

func _on_request_board_completed(_result, response_code, _headers, body):
	var http_req = get_node_or_null("http_request") 
	if http_req:
		http_req.queue_free()
		http_request = null
		
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		var state = json["state"]
		print(state)
		uuid = str(json["uuid"])
		_parse_state(state)
	elif response_code == 204:
		await get_tree().create_timer(2.0).timeout
		http_request = HTTPRequest.new()
		_request_board()
	else:
		print("Unexpected response code: ", response_code)
		print("Body: ", body.get_string_from_utf8())
		
		await get_tree().create_timer(2.0).timeout  # Retry after delay
		http_request = HTTPRequest.new()
		_request_board()



#------------
#calculations
#------------
func _parse_state(state_string):
	var pairs = state_string.split("|")  
	
	var size = state_string.length()
	var ai_tiles = state_string[size - 1]
	
	for pair in pairs: # "0,3 or 4,4h16
		
		if pair == "h" or pair == "t":
			continue
			
		if pair.find("h") != -1:
			# var index_h = pair.find("h")
			var num_pieces = pair.split("h")
			
			var pieces_after_comma
			var count
			
			for p in num_pieces:
				if p.find(",") != -1:
					pieces_after_comma = p.split(",")
				else:
					count = int(p)
			
			var tile = axial_to_oddq(int(pieces_after_comma[0]), int(pieces_after_comma[1]))
			if ai_tiles == "h":
				board[tile] = {
				"player": 1,  
				"pieces": count
				}
			else:
				board[tile] = {
				"player": 0,  
				"pieces": count
				}
			
			# print({"x": pieces_after_comma[0], "y": pieces_after_comma[1], "count": count, "player": "h"})
		elif pair.find("t") != -1:
			# var index_h = pair.find("t")
			var num_pieces = pair.split("t")
			
			var pieces_after_comma
			var count
			
			for p in num_pieces:
				if p.find(",") != -1:
					pieces_after_comma = p.split(",")
				else:
					count = int(p)
			
			var tile = axial_to_oddq(int(pieces_after_comma[0]), int(pieces_after_comma[1]))
			if ai_tiles == "t":
				board[tile] = {
				"player": 1,  
				"pieces": count
				}
			else:
				board[tile] = {
				"player": 0,  
				"pieces": count
				}
			
			# print({"x": pieces_after_comma[0], "y": pieces_after_comma[1], "count": count, "player": "t"})
		else:
			var pieces_after_comma = pair.split(",")
			
			var tile = axial_to_oddq(int(pieces_after_comma[0]), int(pieces_after_comma[1]))
			board[tile] = {
				"player": -1,  
				"pieces": 0
				}
			# print({"x": pieces_after_comma[0], "y": pieces_after_comma[1]})
	
	emit_signal("got_board")

func board_placement_string(move_from_ai):
	var axial_coordinates_move = []
	
	for tile in move_from_ai:
		var t = oddq_to_axial(tile.x, tile.y)
		axial_coordinates_move.append(t)
	
	var return_string = str(axial_coordinates_move[0].x) + "," + str(axial_coordinates_move[0].y) + "|" + str(axial_coordinates_move[1].x) + "," + str(axial_coordinates_move[1].y) + "|" + str(axial_coordinates_move[2].x) + "," + str(axial_coordinates_move[2].y) + "|" + str(axial_coordinates_move[3].x) + "," + str(axial_coordinates_move[3].y) 
	
	return return_string
	
		

func initial_stack_string(move_from_ai):
	var t = oddq_to_axial(move_from_ai.x, move_from_ai.y)
	var return_string = str(t.x) + "," + str(t.y)
	return return_string

func strategic_move_string(move_from_ai):
	var t1 = oddq_to_axial(move_from_ai[0].x, move_from_ai[0].y)
	var t2 = oddq_to_axial(move_from_ai[1].x, move_from_ai[1].y)
	
	var return_string = str(t1.x) + "," + str(t1.y) + "|" + str(move_from_ai[2]) + "|" + str(t2.x) + "," + str(t2.y)
	
	return return_string
	
func axial_to_oddq(q: int, r: int) -> Vector2i:
	var col = q
	var row = r + int((q + (q & 1)) / 2)
	
	if abs(col) % 2 == 1:
		row -= 1
		return Vector2i(col, row)
		
	return Vector2i(col, row)

func oddq_to_axial(col: int, row: int) -> Vector2i:
	var q = col
	var r = row - int((col + (col & 1)) / 2)
	
	if abs(col) % 2 == 1:
		r += 1
		return Vector2i(q, r)
		
	return Vector2i(q, r)
	
