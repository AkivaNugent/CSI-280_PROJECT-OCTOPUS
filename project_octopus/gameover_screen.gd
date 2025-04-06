extends Control

@onready var gameover_menu = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gameover_menu.visible = true
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	gameover_menu.visible = true


func _on_reset_button_pressed() -> void:
	pass
