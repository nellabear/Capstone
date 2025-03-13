extends Node

@export var port: int = 12345  # Default port for hosting
@export var max_players: int = 4  # Max number of players in a lobby


var peer = null 
var selected_difficulty: String
var lobby_code: String = ""  # Store the randomly generated lobby code
var player_list = {}
var game_difficulty = ""

signal lobby_updated 

func host_game():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_players)
	
	if error != OK:
		print("Failed to start server:", error)
		return false

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	var host_id = multiplayer.get_unique_id()
	player_list[host_id] = "Host"
	update_lobby.rpc(player_list)
	
	lobby_code = str(randi() % 90000 + 10000)
	
	print("Hosting started on port", port, "with lobby code:", lobby_code)
	return true 
	
	
func join_game(ip_address: String):
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_address, port)
	
	if error != OK:
		print("Failed to join server:", error)
		return false
	
	multiplayer.multiplayer_peer = peer
	
	await get_tree().create_timer(0.5).timeout
	
	var player_name = "Player" + str(randi() % 1000)
	join_lobby.rpc(player_name)
	
	return true
	
@rpc("any_peer", "reliable")
func join_lobby(player_name):
	var peer_id = multiplayer.get_remote_sender_id()
	print("📥 Receiving join_lobby RPC from:", peer_id, "with name:", player_name)
	
	if multiplayer.is_server():
		player_list[peer_id] = player_name
		print(player_name, "joined the lobby")
		
		update_lobby.rpc(player_list)
		
		update_lobby.rpc_id(peer_id, player_list)
		
		lobby_updated.emit()
		print("Player added to list:", player_list)
	else:
		print("Error: Non-server tried to modify the lobby!")
		
	
@rpc("authority", "reliable")
func update_lobby(updated_list):
	player_list = updated_list
	print("🔄 Updated player list received:", player_list)
	lobby_updated.emit()
	
@rpc("authority", "reliable")
func send_lobby_code(new_peer_id):
	if multiplayer.is_server():
		send_lobby_code.rpc_id(new_peer_id, lobby_code)
		
	
func set_difficulty(difficulty):
	game_difficulty = difficulty
	print("⚙️ Attempting to set difficulty:", difficulty)
	
	if difficulty == "" or difficulty.strip_edges() == "":
		print("⚠️ Error: Attempted to set empty difficulty!")
		return
		
	
	selected_difficulty = difficulty
	print("✅ Difficulty successfully set to:", selected_difficulty)
	
	if multiplayer.is_server():
		print("📡 Broadcasting difficulty to clients:", difficulty)
		sync_difficulty.rpc(difficulty)
	
	
func start_game_wrapper():
	print("📢 Attempting to start game. Current difficulty:", selected_difficulty)

	if selected_difficulty == "" or selected_difficulty.strip_edges() == "":
		print("⚠️ Error: No difficulty set before starting the game!")
		
		if multiplayer.is_server():
			print("📡 Re-broadcasting difficulty to clients...")
			sync_difficulty.rpc(selected_difficulty)

		return 
		
	print("🚀 Starting game with difficulty:", selected_difficulty)
	start_game.rpc(selected_difficulty)


@rpc("any_peer", "reliable")
func start_game(selected_difficulty):
	print("🚀 Attempting to start game. Difficulty:", selected_difficulty)
	
	if game_difficulty == "":
		print("⚠️ Error: No difficulty set before starting the game!")
		return
		
	get_tree().change_scene_to_file("res://EASYMODE(TRUEORFALSE).tscn")
	
		
	if selected_difficulty == "" or selected_difficulty.strip_edges() == "":
		print("⚠️ Error: No difficulty set before starting the game!")
		return  # Prevents the game from starting
	
	print("✅ Starting game with difficulty:", selected_difficulty)
	
	var scene_path = ""
	match selected_difficulty:
		"Easy":
			scene_path = "res://EASYMODE(TRUEORFALSE).tscn"
		"Average":
			scene_path = "res://AVERAGEMODE(MULTIPLECHOICES).tscn"
		"Hard":
			scene_path = "res://HARDMODE(IDENTIFICATION).tscn"
			
	if scene_path != "":
		change_scene.rpc(scene_path)
	else:
		print("⚠️ Error: Invalid difficulty mode selected!")

func _ready():
	print("🚀 Game started! Difficulty is:", NetworkManager.game_difficulty)
	
@rpc("any_peer", "reliable")
func change_scene(scene_path: String):
	print("🟢 Executing change_scene() for", scene_path)
	var error = get_tree().change_scene_to_file(scene_path)
	
	if error != OK:
		print("❌ Scene change failed with error:", error)
		
		
@rpc("authority", "reliable")
func sync_difficulty(difficulty):
	print("🔄 sync_difficulty() received:", difficulty)
	selected_difficulty = difficulty
	print("✅ Difficulty updated to:", selected_difficulty)

func _on_player_connected(id):
	print("Player connected", id)
	if multiplayer.is_server():
		await get_tree().create_timer(0.5).timeout
		send_lobby_code.rpc_id(id, lobby_code)
		
		
func _on_player_disconnected(id):
	print("Player disconnected" , id)
		
	if multiplayer.is_server():
		if id in player_list:
			player_list.erase(id)
			update_lobby.rpc(player_list)
	 
