extends Control

@onready var pause_menu = $"."

func _ready() -> void:
	pause_menu.visible = false

func pause():
	get_tree().paused = true
	pause_menu.visible = true
	
func resume():
	get_tree().paused = false
	pause_menu.visible = false
	
func togglePauseMenu():
	if Input.is_action_just_pressed("pause") && !get_tree().paused:
		pause()
		print("pause")
	elif Input.is_action_just_pressed("pause") && get_tree().paused:
		resume()
		print("unpause")


func _on_resume_pressed() -> void:
	resume()


func _on_save_game_pressed() -> void:
	# Not sure how were approaching this
	print("Game Totally Saved :>")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _process(delta: float) -> void:
	togglePauseMenu()
