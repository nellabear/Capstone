extends Control

@onready var code_input: LineEdit = $CodeInput
@onready var join_button: Button = $JoinButton
@onready var error_label: Label = $ErrorLabel


func _on_join_button_pressed() -> void:
	var lobby_code = code_input.text.strip_edges()
	
	if lobby_code.is_empty():
		error_label.text = "Please enter a valid code."
		return
		
	var host_ip = get_host_ip_from_code(lobby_code)
	
	if host_ip == "":
		error_label.text = "Invalid or expired lobby code."
		return
		
	if await NetworkManager.join_game(host_ip):
		print("✅ Successfully joined the game")
		var player_name = "Player" + str(randi() % 1000)
		NetworkManager.join_lobby.rpc(player_name)
		get_tree().change_scene_to_file("res://LOBBY.tscn")
	else:
		error_label.text = "Failed to connect to the lobby."

func get_host_ip_from_code(code: String) -> String:
	return "127.0.0.1"
	
