extends Node

@export var max_players = 4
var lobby_code: String
var players = {}

@onready var network_manager = get_node("/root/NetworkManager")
@onready var player_list: ItemList = $player_list
@onready var start_button: Button = $start_button
@onready var lobby_code_label: Label = $lobby_code_label
@onready var difficulty_label: Label = $difficulty_label
@onready var player_list_label: Label = $player_list/player_list_label
@export var selected_difficulty: String = ""


func set_difficulty(difficulty):
	selected_difficulty = difficulty
	difficulty_label.text = "Difficulty: " + difficulty
	network_manager.selected_difficulty = difficulty  


func _on_start_button_pressed():
	if !multiplayer.is_server():
		print("❌ You are not the host!")
		return
		
	print("📜 Current player list:", network_manager.player_list)
	print("🔢 Number of players:", network_manager.player_list.size())
	
	if multiplayer.is_server() and network_manager.player_list.size() >= 2:
		print("Game Starting with difficulty:", selected_difficulty)
		network_manager.start_game.rpc(selected_difficulty)
	else:
		print("❌ Not enough players to start the game.")


func _ready():
	await get_tree().process_frame
	print("✅ Network Manager:", network_manager)
	print("Network Manager Node Path:", get_tree().get_nodes_in_group("network_manager"))
	player_list = get_node_or_null("player_list")
	print("Player list after waiting:", player_list)
	var found_nodes = []
	get_tree().call_group("player_list_group", "add_to_found_nodes")
	print("Start button:", start_button)
	
	if start_button:
		start_button.disabled = (network_manager.player_list.size() >= 2)
	else:
		print("ERROR: start_button is NULL")

	
	if has_node("player_list"):
		player_list = get_node("player_list")
		print("✅ player_list found:", player_list)
	else:
		print("❌ ERROR: player_list node NOT found!")
	
	await get_tree().process_frame
	player_list = get_node("player_list")
	player_list = find_child("player_list", true, false)
	print("player_list:", player_list) 
	
	if player_list == null:
		print("❌ player_list is NULL - Check node path!")

	var game_difficulty = network_manager.selected_difficulty
	print("Game started with difficulty:", game_difficulty)
	
	if network_manager == null:
		print("❌ Error: NetworkManager not found!")
		return
		
	if lobby_code_label:
		lobby_code_label.text = "Lobby Code: " + str(network_manager.lobby_code)
	else:
		print("❌ Error: LobbyCodeLabel not found!")
		
	network_manager.lobby_updated.connect(_update_lobby_display)
	print("✅ Lobby code:", network_manager.lobby_code)
	
	if !start_button:
		print("❌ Error: Start_Button not found!")
		return
		
	if !multiplayer.is_server():
		start_button.hide()
		var player_game = "Player" + str(randi() % 1000)
		network_manager.join_lobby.rpc(player_game)
	else:
		start_button.show()
	
	network_manager.lobby_updated.connect(_update_lobby_display)
	
func _update_lobby_display():
	print("DEBUG: player_list =", player_list)
	if player_list != null:
		player_list.clear()
		for peer_id in network_manager.player_list:
			var player_name = network_manager.player_list[peer_id]
			player_list.add_item(str(peer_id) + " - " + player_name)
	else:
		print("ERROR: player_list is NULL!")

	if multiplayer.is_server() and start_button:
		start_button.disabled = !(network_manager.player_list.size() >= 2)
		
	print("✅ Updated lobby display:", network_manager.player_list)
