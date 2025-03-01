extends VBoxContainer

const MAIN_SCENE = preload("res://node_3d.tscn")
@onready var bg_music = $"../AudioStreamPlayer_bgMusic"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !bg_music.playing:
		bg_music.play()

# Start Game
func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_packed(MAIN_SCENE)

# End Game
func _on_quit_button_pressed() -> void:
	get_tree().quit()

# Networking Functions
func _on_host_button_pressed() -> void:
	pass # Replace with function body.

func _on_join_button_pressed() -> void:
	pass # Replace with function body.
