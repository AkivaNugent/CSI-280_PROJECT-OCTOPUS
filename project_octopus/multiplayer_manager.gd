extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"

# will likeley be called using a button press
func become_host():
	print("Starting host!")
	
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	
	multiplayer.multiplayer_peer = server_peer
	
	#detect a player is added to the server so we can add them to the game
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_connected.connect(_del_player)
	
func join_as_player_2():
	print("Player 2 joining")
	
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_IP, SERVER_PORT)
	
	multiplayer.multiplayer_peer = client_peer
	

func _add_player_to_game(id: int):
	print("Player %s joined the game!" % id)

func _del_player(id: int):
	print("Player %s left the game!" % id)
	
