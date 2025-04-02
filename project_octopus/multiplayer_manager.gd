extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"

var multiplayer_scene = preload("res://multiplayer_player.tscn")

var _players_spawn_node
var gameplay_scene = preload("res://node_3d.tscn")

# will likeley be called using a button press
func become_host():
	print("Starting host!")
	
	var scene_instance = gameplay_scene.instantiate()
	get_tree().current_scene.add_child(scene_instance)
	_players_spawn_node = scene_instance.get_node("Players")
	
	if _players_spawn_node == null:
		print("Error: the 'Players' node cannot be found... :(")
		return
	
	#Create a new ENet server 
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	#var result = server_peer.create_server(SERVER_PORT)
	
	#debug: print result of server creation
	#print("Server creation result: ", result)
	
	#if result != OK:
#		print("Failed to start server")
#		return
	
	#set multiplayer peer to server
	#get_tree().get_multiplayer().multiplayer_peer = server_peer
	multiplayer.multiplayer_peer = server_peer

	#detect a player is added to the server so we can add them to the game
	#get_tree().get_multiplayer().peer_connected.connect(_add_player_to_game)
	#get_tree().get_multiplayer().peer_disconnected.connect(_del_player)
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)
	_remove_single_player()
	_add_player_to_game(1)
	
	#if not OS.has_feature("dedicated_server"):
	#	_add_player_to_game(1)

func join_as_player_2():
	print("Player 2 joining")
	
	var client_peer = ENetMultiplayerPeer.new()
	var result = client_peer.create_client(SERVER_IP, SERVER_PORT)
	
	if result != OK:
		print("Failed to start server")
		return
	
	get_tree().get_multiplayer().multiplayer_peer = client_peer
	var connected = get_tree().get_multiplayer().is_connected("peer_connected", Callable(self, "_add_player_to_game"))
	if not connected:
		get_tree().get_multiplayer().peer_connected.connect(_add_player_to_game)
	var disconnected = get_tree().get_multiplayer().is_connected("peer_disconnected", Callable(self, "_del_player"))
	if not disconnected:
		get_tree().get_multiplayer().peer_disconnected.connect(_del_player)
	_remove_single_player()
func _add_player_to_game(id: int):
	print("Player %s joined the game!" % id)
	
	var player_to_add = multiplayer_scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	_players_spawn_node.add_child(player_to_add, true)
	
	
func _del_player(id: int):
	print("Player %s left the game!" % id)
	if not _players_spawn_node.has_node(str(id)):
		return
	_players_spawn_node.get_node(str(id)).queue_free()
func _remove_single_player():
	print("Remove single player")
	
	var scene_instance = gameplay_scene.instantiate()
	get_tree().current_scene.add_child(scene_instance)
	var player_to_remove = scene_instance.get_node("Player")
	player_to_remove.queue_free()
