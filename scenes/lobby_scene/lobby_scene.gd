extends Node

@onready var item_list = $Panel/ItemList
@onready var connect_button = $Panel/Button

var servers = []  # Stores available servers

func _ready():
	connect_button.disabled = true  # Disable until a selection is made
	connect_button.connect("pressed", Callable(self, "_on_connect_pressed"))
	item_list.connect("item_selected", Callable(self, "_on_item_selected"))

func update_server_list():
	servers = GlobalVars.room_names
	
	item_list.clear()
	
	for server in servers:
		item_list.add_item(server)
	
	GlobalVars.last_room_size = servers.size()

func _on_item_selected(index):
	connect_button.disabled = false

func _on_connect_pressed():
	get_parent().get_parent().get_node("ButtonClickSound").play()
	var selected_index = item_list.get_selected_items()
	print(item_list.get_selected_items())
	if selected_index.size() > 0:
		GlobalVars.selected_room_to_join = selected_index
		queue_free()


func _on_button_mouse_entered() -> void:
	if (!connect_button.disabled):
		get_parent().get_parent().get_node("ButtonHoverSound").play()
