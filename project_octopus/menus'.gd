extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.





func _on_start_button_pressed():
	get_tree().change_scene_to_file("node_3d.tscn")



func _on_host_pressed():
	MultiplayerManager.become_host()


func _on_join_pressed() -> void:
	MultiplayerManager.join_as_player_2()
