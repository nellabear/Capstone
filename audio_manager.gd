extends Node

var master_bus_index = AudioServer.get_bus_index("Master")
var sfx_bus_index = AudioServer.get_bus_index("sfx")

func _ready():
	print("🔊 AudioManager Loaded. Master bus index:", master_bus_index)


func set_master_volume(value: float):
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))
	print("🎚️ Master volume set to:", value)

func set_sfx_volume(value: float):
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value))
	print("🎚️ SFX volume set to:", value)
	
func _on_master_value_changed(value: float) -> void:
	AudioManager.set_master_volume(value) 

func _on_sfx_value_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value) 
	
func get_master_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(master_bus_index))
	
func get_sfx_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_index))
	
func save_volume():
	var file = FileAccess.open("user://audio_settings.cfg", FileAccess.WRITE)
	file.store_line(str(get_master_volume()))

func load_volume():
	if FileAccess.file_exists("user://audio_settings.cfg"):
		var file = FileAccess.open("user://audio_settings.cfg", FileAccess.READ)
		var saved_value = float(file.get_line())
		set_master_volume(saved_value)  # Apply saved volume
