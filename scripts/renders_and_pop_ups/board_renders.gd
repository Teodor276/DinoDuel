extends RefCounted  # Not attached to the scene tree

class_name BoardRenders

var grid_calculations = load("res://scripts/game_helpers/GridCalculations.gd").new()

func center_board(tilemap: TileMap, middle_of_screen: Vector2, board_rect) -> void:
	if board_rect == Rect2():
		return 

	var board_center_local: Vector2 = board_rect.position + board_rect.size / 2

	tilemap.position = middle_of_screen - board_center_local


func create_or_update_label(tile_id: Vector2i, new_text: String, labels, tree) -> void:
	var label: Label

	if labels.has(tile_id):
		label = labels[tile_id]
	else:
		label = Label.new()
		label.name = "PiecesLabel_%s" % tile_id
		tree.add_child(label)
		labels[tile_id] = label

	label.text = new_text

	var f = load("res://assets/Toriko.ttf")
	label.add_theme_font_override("font", f)
	label.add_theme_font_size_override("font_size", 40)
	
	label.add_theme_color_override("font_color", Color(255, 255, 255))  
	
	var world_pos = tree.map_to_local(tile_id)

	if new_text.length() == 2:
		label.position = world_pos + Vector2(12, 8)  
	else:
		label.position = world_pos + Vector2(20, 8)


func remove_label(tile_id: Vector2, labels) -> void:
	if labels.has(tile_id):
		labels[tile_id].queue_free()
		labels.erase(tile_id)
