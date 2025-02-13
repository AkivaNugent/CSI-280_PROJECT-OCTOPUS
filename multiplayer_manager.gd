extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"

# will likeley be called using a button press
func become_host():
	print("Starting host!")
	
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	
	multiplayer.multiplayer_peer = server_peer
	
	multiplayer.peer_connected.connect(_add_player_to_game)
	
func join_as_player_2():
	print("Player 2 joining")
	

func _add_player_to_game(id: int):
	print("Player %s joined the game!" % id)

func _del_player(id: int):
	print("Player %s left the game!" % id)
	
