extends Control

@onready var room_code_input = $RoomCodeInput
@onready var error_label = $ErrorLabel
@onready var custom_multiplayer = get_tree().get_multiplayer()

func _on_join_button_pressed() -> void:
	var room_code = room_code_input.text.strip_edges()
	
	if room_code.length() != 6:
		error_label.text = "Invalid code!"
		return
		
	join_lobby(room_code)
	
	
func join_lobby(room_code: String):
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client("127.0.0.1", 9999)  
	
	if result != OK:
		error_label.text = "Failed to connect to host!"
		print("Error: Unable to create client connection!")
		return  
	
	multiplayer.multiplayer_peer = peer
	print("Trying to connect to host...")

	await multiplayer.connected_to_server 
	
	print("Connected! Requesting lobby entry...")

	var host_id = 1 
	rpc_id(host_id, "request_lobby_entry", multiplayer.get_unique_id())
	
	print("LineEdit Editable:", room_code_input.editable)
	print("LineEdit Visible:", room_code_input.visible)
	print("Parent Mouse Filter:", room_code_input.get_parent().mouse_filter)
	room_code_input.grab_focus()

func _on_connected_to_server():
	print("Successfully connected to server!")
	error_label.text = ""
	
func _on_connection_failed():
	error_label.text = "Failed to connect to host!"
	print("Connection failed!")
