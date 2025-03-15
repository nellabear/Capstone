extends Control

@onready var room_code_label = $room_code_label
@onready var player_list = $VBoxContainer/PlayerList
@onready var start_button = $start_button
@onready var custom_multiplayer = get_tree().get_multiplayer()


var room_code = ""  

func _ready():
	if not multiplayer.is_server():
		room_code_label.text = "Waiting for host..."
		
	start_server()
	create_lobby()
	MultiplayerManager.lobby_updated.connect(update_lobby)
	update_lobby()
	multiplayer.peer_connected.connect(on_player_connected)
	
func start_server():
	var port = 9999
	var max_players = 4
	
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(port, max_players)  
	
	if result != OK:
		print("❌ Failed to start server on port", port, "Error code:", result)
		return
	
	multiplayer.multiplayer_peer = peer
	print("Server started on port 9999")
	print("✅ Peer set: ", multiplayer.multiplayer_peer != null)
	print("✅ Unique ID: ", multiplayer.get_unique_id())
	print("✅ Is server: ", multiplayer.is_server())
	
	MultiplayerManager.players[1] = "Player 1"
	MultiplayerManager.lobby_updated.emit()
	
func on_player_connected(player_id):  
	if not get_tree():
		print("Error: get_tree() is NULL!")
		return
	print("Player", player_id, "has connected!")
	
	if multiplayer.is_server():
		var player_number = MultiplayerManager.players.size() + 1
		MultiplayerManager.players[player_id] = "Player " + str(player_number)
		MultiplayerManager.lobby_updated.emit() 
	
	
@rpc("reliable", "call_local")  
func set_lobby_code(code: String):
	room_code = code
	room_code_label.text = "Lobby Code: " + room_code
	
	
func create_lobby():
	if multiplayer.is_server():
		room_code = generate_room_code() 
		set_lobby_code.rpc(room_code)
	else:
		print("Waiting for host to provide the room code...")
	
	
func generate_room_code():
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var code = ""
	for i in range(6):
		code += chars[randi() % chars.length()]
	
	print("Generated Room Code:", code)  # Debugging output
	return code
	
	
@rpc("reliable", "authority")
func sync_player_list(new_players):
	MultiplayerManager.players = new_players
	update_lobby()
	
	
func update_lobby():
	player_list.text = ""
	print("Players in lobby:", MultiplayerManager.players)
	
	if multiplayer.is_server():
		sync_player_list.rpc(MultiplayerManager.players)
		
	for id in MultiplayerManager.players.keys():
		player_list.text += MultiplayerManager.players[id] + "\n"
	
	start_button.visible = multiplayer.is_server() and MultiplayerManager.players.size() >= 2
	
	if MultiplayerManager.players.is_empty():
		print("MultiplayerManager.players is empty or not initialized!")
		return  
	
	var sorted_players = MultiplayerManager.players.keys()
	sorted_players.sort()
	
	player_list.text = "" 
	for id in sorted_players:
		player_list.text += MultiplayerManager.players[id] + "\n"
	
	start_button.visible = multiplayer.is_server() and MultiplayerManager.players.size() >= 2
	
	
func _on_start_button_pressed() -> void:
	if multiplayer.is_server():
		if MultiplayerManager.players.size() >= 2:
			print("Starting game...")
			MultiplayerManager.start_game.rpc()
		else:
			print("Not enough players to start the game!")
	else:
		print("Error: Only host can start the game!")
