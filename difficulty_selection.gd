extends Control

var selected_difficulty = ""  


func _on_easy_pressed() -> void:
	NetworkManager.set_difficulty("Easy")
	start_host()

func _on_average_pressed() -> void:
	NetworkManager.set_difficulty("Average")
	start_host()


func _on_hard_pressed() -> void:
	NetworkManager.set_difficulty("Hard")
	start_host()


func start_host():
	if NetworkManager.game_difficulty == "" or NetworkManager.game_difficulty.strip_edges() == "":
		print("⚠️ Error: No difficulty selected before starting host!")
		return
		
	print("🎮 Starting host with difficulty:", NetworkManager.game_difficulty)
	
	if NetworkManager.host_game():
		get_tree().change_scene_to_file("res://LOBBY.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://PLAY.tscn")
