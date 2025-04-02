extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.has_feature("dedicated_server"):
		print("Starting dedicated server...")
		MultiplayerManager.become_host()
