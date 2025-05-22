extends Node

class_name UDP_Script

var BROADCAST_ADDRESS: String
const PORT: int = 80

var extracted_subnet_mask
var udp: PacketPeerUDP
var parse_helper = load("res://scripts/networking/parsing_network.gd").new()

func _ready() -> void:
	get_subnet_mask_windows()
	BROADCAST_ADDRESS = calculate_broadcast_address()
	print(BROADCAST_ADDRESS)
	udp = PacketPeerUDP.new()
	udp.bind(PORT, "*")
	
	
	# Allow sending broadcast traffic
	udp.set_broadcast_enabled(true)

	print("created")

func get_subnet_mask_windows():
	var output = []
	OS.execute("ipconfig", [], output )  # Run ipconfig and capture output
	
	var ipv4_pattern = RegEx.new()
	ipv4_pattern.compile("IPv4 Address[ .:]+([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)")
	
	var subnet_pattern = RegEx.new()
	subnet_pattern.compile("Subnet Mask[ .:]+([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)")
	
	var found_ip = false
	var subnet_mask = ""

	for line in output:
		var line_str = line.strip_edges()

		# Look for a valid IPv4 address first
		var ip_match = ipv4_pattern.search(line_str)
		if ip_match:
			found_ip = true  # We've found an active interface

		# Once an IP is found, look for the subnet mask
		var subnet_match = subnet_pattern.search(line_str)
		if found_ip and subnet_match:
			subnet_mask = subnet_match.get_string(1)
			extracted_subnet_mask = subnet_mask
			return subnet_mask

	print("No subnet mask found.")
	return ""

func calculate_broadcast_address() -> String:
	var ip = get_valid_local_ip()
	
	var ip_parts = ip.split(".")  # Example: "192.168.1.10" -> ["192", "168", "1", "10"]
	var mask_parts = extracted_subnet_mask.split(".")  # Example: "255.255.255.0"

	if ip_parts.size() != 4 or mask_parts.size() != 4:
		print("Invalid IP or subnet mask format")
		return ""

	var broadcast_parts = []

	for i in range(4):
		var ip_octet = int(ip_parts[i])  # Convert to integer
		var mask_octet = int(mask_parts[i])  # Convert to integer
		
		var inverted_mask = 255 - mask_octet  # Invert the subnet mask
		var broadcast_octet = ip_octet | inverted_mask  # Perform bitwise OR
		
		broadcast_parts.append(str(broadcast_octet))  # Store the result

	return ".".join(broadcast_parts)  # Return final broadcast address


func get_valid_local_ip() -> String:
	var addresses = IP.get_local_addresses()
	for address in addresses:
		if address.begins_with("192.") or address.begins_with("10.") or address.begins_with("172."): 
			return address  # Return the first valid private IP
	return "127.0.0.1"  # Fallback (loopback)

var ip = get_valid_local_ip()  # Get the correct local IP



				
func _process(_delta: float) -> void:
	if GlobalVars.lobby_phase == true:
		while udp.get_available_packet_count() > 0 and GlobalVars.lobby_phase:
			var packet_data: PackedByteArray = udp.get_packet()
			var sender_ip: String = udp.get_packet_ip()
			var sender_port: int = udp.get_packet_port()
			var received_msg: String = packet_data.get_string_from_utf8()
			
			if received_msg.length() == 0 or sender_ip == GlobalVars.local_ip:
				continue
			
			print(received_msg)
			
			if GlobalVars.found_other_instance == false:
				if received_msg[0] == "R" and GlobalVars.is_instance_server == false:
					var parsed_packet = parse_helper.parse_room_string(received_msg)
					if parsed_packet[1] in GlobalVars.room_names:
						return
					
					GlobalVars.room_names.append(parsed_packet[1])
					GlobalVars.room_ip.append(sender_ip)
					GlobalVars.goes_first.append(parsed_packet[2])
				
				if received_msg[0] == "C" and GlobalVars.is_instance_server == true:
					var parsed_packet = parse_helper.parse_room_string(received_msg)
					
					if parsed_packet[1] == GlobalVars.room_name:
						GlobalVars.found_other_instance = true
						GlobalVars.other_instance_local_ip = sender_ip
				
				if received_msg[0] == "S" and GlobalVars.is_instance_server == false:
					if sender_ip == GlobalVars.other_instance_local_ip:
						GlobalVars.lobby_phase = false
	
	
			
		

func send_broadcast(msg: String) -> void:
	# Convert the string into a PackedByteArray
	var packet: PackedByteArray = msg.to_utf8_buffer()

	# 1) Set the broadcast address/port
	udp.set_dest_address(BROADCAST_ADDRESS, PORT)

	# 2) Send the packet with put_packet()
	var err: int = udp.put_packet(packet)
	if err != OK:
		push_error("Failed to broadcast message: %s (Error: %d)" % [msg, err])
	else:
		print("Broadcast sent: %s" % msg)


func receive_move():
	var received_move
	print(GlobalVars.local_ip)
	print(GlobalVars.other_instance_local_ip)
	print(udp)
	print(GlobalVars.instance_script == null)

	while true:
		while udp.get_available_packet_count() > 0 and GlobalVars.lobby_phase == false:
			var packet_data: PackedByteArray = udp.get_packet()
			var sender_ip: String = udp.get_packet_ip()
			var sender_port: int = udp.get_packet_port()
			var received_msg: String = packet_data.get_string_from_utf8()
			print(true)
			
			if received_msg.length() == 0 or sender_ip == GlobalVars.local_ip:
				continue
			
			if GlobalVars.going_back_to_main_menu == true:
				break
			
			if sender_ip == GlobalVars.other_instance_local_ip:
				received_move = received_msg
				print(received_msg)
				break
		
		if received_move or GlobalVars.going_back_to_main_menu == true:
			break
			
	
	return received_move
