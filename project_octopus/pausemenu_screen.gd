extends Control

@onready var pause_menu = $"."

func _ready() -> void:
	pause_menu.visible = false

	# Init volume values
	$musicMenu/master_hslider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	$musicMenu/music_hslider.value = db_to_linear(AudioServer.get_bus_volume_db(1))
	$musicMenu/sfx_hslider.value = db_to_linear(AudioServer.get_bus_volume_db(2))

func pause():
	get_tree().paused = true
	pause_menu.visible = true
	
func resume():
	AudioServer.set_bus_volume_db(0, linear_to_db($musicMenu/master_hslider.value))
	AudioServer.set_bus_volume_db(1, linear_to_db($musicMenu/music_hslider.value))
	AudioServer.set_bus_volume_db(2, linear_to_db($musicMenu/sfx_hslider.value))
	get_tree().paused = false
	pause_menu.visible = false
	
func togglePauseMenu():
	if Input.is_action_just_pressed("pause") && !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("pause") && get_tree().paused:
		resume()


func _on_resume_pressed() -> void:
	resume()


func _on_save_game_pressed() -> void:
	# Not sure how were approaching this
	print("Game Totally Saved :>")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _process(delta: float) -> void:
	togglePauseMenu()

# Release on Volume Sliders
func _on_master_hslider_mouse_exited() -> void:
	release_focus()


func _on_music_hslider_mouse_exited() -> void:
	release_focus()


func _on_sfx_hslider_mouse_exited() -> void:
	release_focus()
