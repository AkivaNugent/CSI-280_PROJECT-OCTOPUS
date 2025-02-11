extends Node

const MAP_RAD = 90
const MAX_HEIGHT = 40
const MAX_HEIGHT2 = 100
var tileScene = load("res://tile.tscn")
var noisegen = FastNoiseLite.new()
var noisegen2 = FastNoiseLite.new()

func _placeCube(x, z) -> void:
	#Find the tile height from the noisemap, normalized to all be non-negative. Scale them to half that height (since scale extends out in both directions). They extend from the center, so we then move them +y so all that height goes up
	var tileHeight = (noisegen.get_noise_2d(x,z) * (MAX_HEIGHT / 2)) + (MAX_HEIGHT / 2)
	tileHeight += (noisegen2.get_noise_2d(x,z) * (MAX_HEIGHT2 / 2)) + (MAX_HEIGHT2 / 2)
	
	_placeCubeSpecific(x, z, tileHeight)

func _placeCubeSpecific(x, z, tileHeight) -> void:
	var newTile = tileScene.instantiate()
	add_child(newTile)
	newTile.scale = Vector3(1.0, tileHeight + 1.0, 1.0)
	newTile.position = Vector3(x, 0.0 + (tileHeight / 2), z)

func _placeChord(x, z) -> void:
	var lineX = x #hehe lineX. is that an Open Source Software reference??
	while lineX > -x:
		_placeCube(lineX, z)
		lineX -= 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Seed the noise generator
	randomize()
	noisegen.seed = randi()
	noisegen.frequency = 0.005
	noisegen2.seed = randi()
	noisegen2.frequency = 0.001
	# Build tiles in a circle using the Midpoint Circle algorithm

	var x = MAP_RAD
	var z = 1
	var P = 1 - MAP_RAD
	_placeChord(MAP_RAD, 0)
	_placeCubeSpecific(MAP_RAD, 0, 1000)
	_placeCubeSpecific(0, -MAP_RAD, 1000)
	while x > z:
		if P <= 0:
			P = P + (2 * z) + 1
		else:
			x -= 1
			P = P + (2 * z) - (2 * x) + 1
			if (x != z):
				_placeChord(z, x)
				_placeChord(z, -x)
		_placeChord(x, z)
		_placeChord(x, -z)
		
		#Build ice cliffs around back half of map
		_placeCubeSpecific(x, z, 1000)
		_placeCubeSpecific(x, -z, 1000)
		if (x != z):
			_placeCubeSpecific(z, -x, 1000)
			_placeCubeSpecific(-z, -x, 1000)
		z += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
