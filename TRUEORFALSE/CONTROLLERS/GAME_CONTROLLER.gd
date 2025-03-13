extends Node

@export var quiz: QuizTheme
@export var color_right: Color
@export var color_wrong: Color

var buttons: Array[Button]
var index: int
var correct: int
var selected_questions: Array[QuizQuestion]

var current_quiz: QuizQuestion:
	get: return quiz.theme[index]


@onready var question_texts: Label = $Content/QuestionInfo/QuestionText
@onready var question_image: TextureRect = $Content/QuestionInfo/ImageHolder/QuestionImage
@onready var question_video: VideoStreamPlayer = $Content/QuestionInfo/ImageHolder/QuestionVideo
@onready var question_audio: AudioStreamPlayer = $Content/QuestionInfo/ImageHolder/QuestionAudio


func _ready() -> void:
	for button in $Content/QuestionHolder.get_children():
		buttons.append(button)
		
		randomize_array(quiz.theme)
		quiz.theme = quiz.theme.slice(0, 5)  
		load_quiz()
		
		
func _on_question_timer_timeout() -> void:
	$QuestionTimer.stop()
	
	var correct: Button = null
	
	for button in buttons:
		if button.text.strip_edges().to_lower() == current_quiz.correct.strip_edges().to_lower():
			correct = button
			break
			
	for button in buttons:
		if button == correct:
			button.modulate = color_right 
			$AudioIncorrect.play()
		else:
			button.modulate = color_wrong 
			$AudioIncorrect.play()
			print("Correct Answer:", current_quiz.correct)
			
	_next_question()
	await get_tree().create_timer(1).timeout
	load_quiz()


func update_question_display():
	$QuestionTimer/QuestionLabel.text = quiz.theme[index].question_info


func load_quiz() -> void:
	if index >= quiz.theme.size():
		_game_over()
		return
		
	update_question_display()
	$QuestionTimer.start(10.00)
	
	question_texts.text = current_quiz.question_info
	
	var options = current_quiz.options
	for i in buttons.size():
		buttons[i].text = options[i]
		buttons[i].pressed.connect(_buttons_answer.bind(buttons[i]))
		
	match current_quiz.type:
		Enum.QuestionType.TEXT:
			$Content/QuestionInfo/ImageHolder.hide()

		Enum.QuestionType.IMAGE:
			$Content/QuestionInfo/ImageHolder.show()
			question_image.texture = current_quiz.question_image

		Enum.QuestionType.VIDEO:
			$Content/QuestionInfo/ImageHolder.show()
			question_video.stream = current_quiz.question_video
			question_video.play()

		Enum.QuestionType.AUDIO:
			$Content/QuestionInfo/ImageHolder.show()
			question_image.texture = current_quiz.question_image
			question_audio.stream = current_quiz.question_audio
			question_audio.play()


func _process(delta):
	$QuestionTimer/QuestionLabel.text = "%.2f " % $QuestionTimer.time_left


func _buttons_answer(button) -> void:
	$QuestionTimer.stop()
	
	if current_quiz.correct == button.text:
		button.modulate = color_right
		$AudioCorrect.play()
	else:
		button.modulate = color_wrong
		$AudioIncorrect.play()

		for btn in $Content/QuestionHolder.get_children():
			if btn.text == current_quiz.correct:
				btn.modulate = color_right
				break
				
	await get_tree().create_timer(1).timeout
	_next_question()


func _next_question() -> void:
	for bt in buttons:
		bt.pressed.disconnect(_buttons_answer)
		
	await get_tree().create_timer(1).timeout
	
	for bt in buttons:
		bt.modulate = Color.WHITE
	
	question_audio.stop()
	question_video.stop()
	question_audio.stream = null
	question_video.stream = null  
	
	index += 1
	load_quiz() 
	
	
func randomize_array(array: Array) -> Array:
	var array_temp := array
	array_temp.shuffle()
	return array_temp


func _game_over() -> void:
	print("DONE")
