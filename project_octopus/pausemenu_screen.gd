extends Control

@onready var pause_menu = $"."
@onready var keybind_menu = $KeybindMenu
@onready var paused_label = $Label
@onready var music_menu = $musicMenu 
@onready var pause_settings = $VBoxContainer

func _ready() -> void:
	pause_menu.visible = false
	keybind_menu.visible = false

	# Init volume values
	$musicMenu/master_hslider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	$musicMenu/music_hslider.value = db_to_linear(AudioServer.get_bus_volume_db(1))
	$musicMenu/sfx_hslider.value = db_to_linear(AudioServer.get_bus_volume_db(2))

func pause():
	get_tree().paused = true
	pause_menu.visible = true
	paused_label.visible = true
	music_menu.visible = true
	pause_settings.visible = true
	
func resume():
	# Applies Volume Changes
	AudioServer.set_bus_volume_db(0, linear_to_db($musicMenu/master_hslider.value))
	AudioServer.set_bus_volume_db(1, linear_to_db($musicMenu/music_hslider.value))
	AudioServer.set_bus_volume_db(2, linear_to_db($musicMenu/sfx_hslider.value))
	
	keybind_menu.visible = false
	get_tree().paused = false
	pause_menu.visible = false
	
func togglePauseMenu():
	if Input.is_action_just_pressed("pause") && !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("pause") && get_tree().paused:
		resume()

func toggle_keybind_menu():
	paused_label.visible = false
	music_menu.visible = false
	pause_settings.visible = false
	keybind_menu.visible = true

func _on_resume_pressed() -> void:
	resume()


func _on_save_game_pressed() -> void:
	# Not sure how were approaching this
	print("Game Totally Saved :>")
	
func _on_keybinds_pressed() -> void:
	toggle_keybind_menu()
	keybind_menu.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		togglePauseMenu()

# Release on Volume Sliders
func _on_master_hslider_mouse_exited() -> void:
	release_focus()


func _on_music_hslider_mouse_exited() -> void:
	release_focus()


func _on_sfx_hslider_mouse_exited() -> void:
	release_focus()
