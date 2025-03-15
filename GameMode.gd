extends Control

@onready var start_button = $StartButton
@onready var question_count_box = $QuestionCount
var selected_difficulty = ""
var selected_answer = ""

func _ready():
	start_button.disabled = true
	
	
func _on_easy_pressed() -> void:
	selected_difficulty = "Easy"
	check_start_ready()
	
	
func _on_average_pressed() -> void:
	selected_difficulty = "Average"
	check_start_ready()
	
	
func _on_hard_pressed() -> void:
	selected_difficulty = "Hard"
	check_start_ready()
	
	
func _on_question_count_value_changed(value):
	check_start_ready()
	
	
func check_start_ready():
	var question_count = int(question_count_box.value)
	if selected_difficulty != "" and question_count > 0:
		start_button.disabled = false
		
		
func _on_start_button_pressed() -> void:
	if multiplayer.is_server():
		var question_count = int(question_count_box.value)
		MultiplayerManager.rpc("sync_settings", selected_difficulty, question_count)
		MultiplayerManager.rpc("start_game")
	
	
func _on_answer_pressed(answer: String):
	selected_answer = answer
	MultiplayerManager.rpc("submit_answer", multiplayer.get_unique_id(), selected_answer)
	
	
@rpc("any_peer", "reliable")
func submit_answer(player_id: int, answer: String):
	print("Player", player_id, "chose", answer)
		
	if MultiplayerManager.quiz_questions[MultiplayerManager.current_question_index]["correct"] == answer:
		MultiplayerManager.player_scores[player_id] += 1  
	
	
	if multiplayer.is_server():
		MultiplayerManager.rpc("next_question")
	
	
	
	
	
	
	
