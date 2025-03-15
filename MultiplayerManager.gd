extends Node

var peer = null
var room_code = ""  
var quiz_difficulty = ""
var question_count = 0  
var quiz_questions = []  
var current_question_index = 0 
var player_scores = {}
var answer_order = []
var lobby = null

@onready var custom_multiplayer = get_tree().get_multiplayer()
@export var players: Dictionary = {}

signal lobby_updated

const MAX_PLAYERS = 4

func _ready():
	custom_multiplayer = get_tree().get_multiplayer()
	players = {} 
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	MultiplayerManager.lobby_updated.connect(update_player_list_display)
	
	lobby = preload("res://LOBBY.tscn").instantiate()
	add_child(lobby)

func generate_room_code():
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var code = ""
	for i in range(6):
		code += chars[randi() % chars.length()]
	return code

func create_lobby():
	peer = ENetMultiplayerPeer.new()
	
	var result = peer.create_server(10500 + randi() % 100, MAX_PLAYERS)
	var retries = 3
	while result != OK and retries > 0:
		retries -= 1
		print("Port 9999 failed. Retrying on next port...")
		result = peer.create_server(9999 + randi() % 100, MAX_PLAYERS)
		
	if result != OK:
		print("Failed to start server!")
		return
	
	multiplayer.multiplayer_peer = peer
	
	if multiplayer.get_unique_id() != 1:
		print("🔀 Remapping host ID to 1...")
		var remap_result = peer.set_local_peer_id(1)
		if remap_result != OK:
			print("❌ Failed to remap host ID! Using existing ID.")
		else:
			print("✅ Host ID remapped to 1!")
		
		players[1] = "Player 1"

	room_code = generate_room_code()
	lobby_updated.emit()
	
@rpc("any_peer", "reliable")
func go_to_lobby():
	print("Entering Lobby Scene...")
	get_tree().change_scene_to_file("res://LOBBY.tscn")
	
func _on_player_connected(id):
	print("Player", id, "connected!")

	if multiplayer.is_server():
		if id == multiplayer.get_unique_id():
			players[id] = "Player 1"
		else:
			var player_number = players.size() + 1
			players[id] = "Player " + str(player_number)
			
		rpc("update_player_list", players) 

		if players.size() >= 2:
			rpc("go_to_lobby")

func _on_player_disconnected(id):
	if id in players:
		players.erase(id)
		if multiplayer.is_server():
			rpc("update_player_list", players)

@rpc("any_peer", "reliable")
func request_lobby_entry(player_id):
	if multiplayer.is_server():
		var player_number = players.size() + 1
		players[player_id] = "Player " + str(player_number)
		lobby_updated.emit()
		print("Player", player_id, "added to the lobby!")
		
		rpc("update_player_list", players)
		
		rpc_id(player_id, "go_to_lobby")

@rpc("authority", "reliable")
func update_player_list(new_players):
	var updated_players = {}
	var index = 1

	var sorted_ids = new_players.keys()
	sorted_ids.sort()
	
	for id in sorted_ids:
		updated_players[id] = "Player " + str(index)
		index += 1

	players = updated_players
	lobby_updated.emit()

func update_player_list_display():
	if lobby == null:
		print("Lobby is not instantiated yet!")
		return

	for child in lobby.get_children():
		if child is Label:
			lobby.remove_child(child)
			child.queue_free()

	var sorted_players = players.values()
	sorted_players.sort_custom(func(a, b): return a < b)

	for player_name in sorted_players:
		var player_label = Label.new()
		player_label.text = player_name
		lobby.add_child.call_deferred(player_label)
	
	var start_button = lobby.find_child("start_button", true)
	if start_button:
		start_button.visible = multiplayer.is_server() and players.size() >= 2
		start_button.disabled = not (multiplayer.is_server() and quiz_difficulty != "" and question_count > 0)
		
		if not multiplayer.is_server():
			start_button.visible = false

@rpc("authority", "reliable")
func host_go_to_game_selection():
	if multiplayer.is_server():
		print("Host is transitioning to game selection scene...")
		get_tree().change_scene_to_file("res://HOST.tscn")
		
@rpc("any_peer", "reliable")
func go_to_game_selection_scene():
	get_tree().change_scene_to_file("res://HOST.tscn")
	
@rpc("any_peer", "reliable")
func sync_settings(difficulty: String, questions: int):
	quiz_difficulty = difficulty
	question_count = questions
	print("Game Settings Updated:", quiz_difficulty, question_count)
	
	rpc("receive_settings", quiz_difficulty, question_count)
	
	if quiz_difficulty == "":
		print("Error: quiz_difficulty not set!")
		return

@rpc("any_peer", "reliable")
func receive_settings(difficulty: String, questions: int):
	quiz_difficulty = difficulty
	question_count = questions
	print("Received Game Settings:", quiz_difficulty, question_count)

@rpc("authority", "reliable")
func confirm_game_settings(difficulty: String, questions: int):
	quiz_difficulty = difficulty
	question_count = questions
	print("Game Settings Confirmed:", quiz_difficulty, question_count)
	
	rpc("go_to_game_scene")

@rpc("authority", "reliable")

func start_game():
	print("is_server:", multiplayer.is_server()) 
	if !multiplayer.is_server():
		print("Error: Only host can start the game!")
		return
		
	if quiz_difficulty == "" or question_count <= 0:
		print("Error: Game settings are not complete!")
		return
		
	
	print("Host is starting the game...")
	rpc("go_to_game_selection_scene")
	
@rpc("any_peer", "reliable")
func go_to_game_scene():
	print("Transitioning to game scene...")
	
	var scene_path = ""
	match quiz_difficulty:
		"Easy":
			scene_path = "res://EASYMODE(TRUEORFALSE).tscn"
		"Average":
			scene_path = "res://AVERAGEMODE(MULTIPLECHOICES).tscn"
		"Hard":
			scene_path = "res://HARDMODE(IDENTIFICATION).tscn"
	
	if scene_path != "":
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Error: Invalid game mode selected!")

@rpc("authority", "reliable")
func send_questions(questions: Array):
	quiz_questions = questions
	current_question_index = 0

@rpc("any_peer", "reliable")
func receive_questions(questions: Array):
	quiz_questions = questions
	current_question_index = 0
	load_question()

func load_question():
	if current_question_index < quiz_questions.size():
		print("Displaying Question:", quiz_questions[current_question_index])
	else:
		print("Quiz Over - Show Final Scores")

@rpc("any_peer", "reliable")
func submit_answer(player_id: int, answer: String):
	if player_id in answer_order:
		return

	var correct_answer = quiz_questions[current_question_index]["correct"]
	if answer == correct_answer:
		answer_order.append(player_id)

	var points = [5, 4, 3, 2]
	if answer_order.size() <= points.size():
		player_scores[player_id] = player_scores.get(player_id, 0) + points[min(answer_order.size() - 1, players.size() - 1)]

	if answer_order.size() == players.size():
		if multiplayer.is_server():
			rpc("next_question")

@rpc("authority", "reliable")
func next_question():
	current_question_index += 1
	answer_order.clear()
	if current_question_index < quiz_questions.size():
		rpc("receive_questions", quiz_questions)
	else:
		await get_tree().create_timer(3).timeout
		rpc("show_final_scores")

@rpc("any_peer", "reliable")
func show_final_scores():
	get_tree().change_scene_to_file("res://RANKING(ENDGAME).tscn")
