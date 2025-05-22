extends Node

var lobby_phase = true 
var game_play_phase = false

var is_networking_game_started = false

var is_instance_server = false
var instance_first = false

var instance_script = null

var local_ip = null
var other_instance_local_ip = null
var room_name = null


var send_room_name = false
var flag_stop_room_name = false

var selected_room_to_join = null

var found_other_instance = false
var going_back_to_main_menu = false

# lobbying
var room_names = []
var room_ip = []
var goes_first = []
var last_room_size = 0

var c_sent_at = null

var left_choice = null
var right_choice = null

# help
var game_instructions = [
	"Welcome to Dino Duel! A hostile herd of dinos is trying to take over your prehistoric pasture. Save your herd by reclaiming your rightful territory!",
	"Alternate with your opponent to place pasture tiles together and form your territory.",
	"Place your dino herd on a pasture tile along the outer border of the territory.",
	"Divide and conquer! Split your herd by moving a group in a straight line across the territory until it reaches the outer border or another group of dinos. You must leave at least 1 dino on the pasture tile you choose to move from.",
	"Once all of your dinos have been blocked, you can no longer make any moves. The player who has claimed the most territory wins! In case of a tie, the player who controls the most consecutive pasture tiles wins."
]

var help_videos = [
	preload("res://assets/help_videos/help_phase_1.ogv"),
	preload("res://assets/help_videos/help_phase_2.ogv"),
	preload("res://assets/help_videos/help_phase_3.ogv"),
	preload("res://assets/help_videos/help_phase_4.ogv")
]
