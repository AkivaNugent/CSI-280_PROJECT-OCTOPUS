extends Node

const GRID_SIZE = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	var noisegen = FastNoiseLite.new()
	noisegen.seed = randi()
	var tileScene = load("res://tile.tscn")
	# Build tiles in a grid
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			var newTile = tileScene.instantiate()
			add_child(newTile)
			newTile.position = Vector3(x - (GRID_SIZE / 2), 0.0, z - (GRID_SIZE / 2))
			newTile.scale = Vector3(1.0, (noisegen.get_noise_2d(x,z) * 80) + 1.0, 1.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
