extends VBoxContainer

const MAIN_SCENE = preload("res://node_3d.tscn")
@onready var bg_music = $"../AudioStreamPlayer_bgMusic"

# Fade Anim Vars
@onready var fade_anim_overlay = $"../FadeOverlay"
@onready var is_dying = false
@onready var fade_time = 1.5
@onready var gameStart = false
@onready var menuContainer = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !bg_music.playing:
		bg_music.play()
		
	if gameStart:
		var current_alpha = fade_anim_overlay.color.a
		if current_alpha < 1.0:
			bg_music.volume_db -= current_alpha
			fade_anim_overlay.color.a += delta / fade_time
			menuContainer.modulate.a -= delta / fade_time
			if fade_anim_overlay.color.a >= 1.0:
				# Fade complete, change to game over scene
				get_tree().change_scene_to_packed(MAIN_SCENE)
		return

# Start Game
func _on_start_button_pressed() -> void:
	gameStart = true

# End Game
func _on_quit_button_pressed() -> void:
	get_tree().quit()

# Networking Functions
func _on_host_button_pressed() -> void:
	pass # Replace with function body.

func _on_join_button_pressed() -> void:
	pass # Replace with function body.
