extends Node

const GRID_SIZE = 100
const MAX_HEIGHT = 40

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
			
			#Find the tile height from the noisemap, normalized to all be non-negative. Scale them to half that height (since scale extends out in both directions). They extend from the center, so we then move them +y so all that height goes up
			var tileHeight = (noisegen.get_noise_2d(x,z) * (MAX_HEIGHT / 2)) + (MAX_HEIGHT / 2)
			newTile.scale = Vector3(1.0, tileHeight + 1.0, 1.0)
			newTile.position = Vector3(x - (GRID_SIZE / 2), 0.0 + (tileHeight / 2), z - (GRID_SIZE / 2))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
