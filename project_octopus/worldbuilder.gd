extends Node

const MAP_RAD = 90
const MAX_HEIGHT = 40
const MAX_HEIGHT2 = 100
var tileScene = load("res://tile.tscn")
var noisegen = FastNoiseLite.new()
var noisegen2 = FastNoiseLite.new()
var heightMap = []
const PriorityQueue = preload("res://PriorityQueue.gd")

func _makeBlankSquareArray(size) -> Array:
	# Generates a blank 2d array of the given size on both dimensions
	# Currently only used for initializing the heightmap
	var result = []
	for x in range(size):
		var row = []
		for z in range(size):
			row.append(-1)
		result.append(row)
	return result

func neighbor(point) -> Array:
	# List all non-diagonal neighbors of a tile
	var result = []
	for x in [-1,1]:
		result.append(Vector2i(point.x + x, point.y))
	for y in [-1,1]:
		result.append(Vector2i(point.x, point.y + y))
		
	return result
	
func _tracePath(cameFrom, current) -> Array:
	# Trace back the followed path to get our final sequence
	var path = [current]
	while current in cameFrom:
		current = cameFrom[current]
		path.push_front(current)
	return path

func aStarNavigation(start,finish) -> Array:
	# Calculate a path between two points over the heightmap using A*
	
	# Note that because start and finish should be Vector2i type, they use x and y as indices, even though we're accessing things on the xz plane.
	# Just keep in mind for this function y variable means z worldspace
	
	# If one of the points is off the map, give up
	if ((start.x ** 2) + (start.y ** 2) > (MAP_RAD - 1) ** 2) or \
		((finish.x ** 2) + (finish.y ** 2) > (MAP_RAD - 1) ** 2):
		return []
	
	
	var toExplore = PriorityQueue.PriorityQueue.new([])
	var cameFrom = {}
	var bestScores = {start:0}
	toExplore.insert(0,start)
	
	# While there are unchecked tiles
	while !toExplore.isEmpty:
		# Find the next priority
		# (a combined score from actual distance + the heuristic, in this case, crow-flies Euclidian distance to goal)
		var current = toExplore.get_root_value()
		toExplore.remove_root()
		
		# If that next node is the goal, we're done
		# (any node that reaches the top of the search queue we can be sure we've found the shortest path to)
		if current == finish:
			return _tracePath(cameFrom, current)
		
		# If this node is not blocked
		var myHeight = getHeight(current.x,current.y)
		if myHeight != -1:
			# Check all its neighbors
			for n in neighbor(current):
				var neighborHeight = getHeight(n.x, n.y)
				var heightDifference = abs(myHeight - neighborHeight)
				
				# If this neighbor is not blocked and witin the STEP_HEIGHT, the connection is valid
				if (neighborHeight != -1 and heightDifference < get_node("../Player").MAX_STEP_HEIGHT):
					
					# Calculate the new score for getting here (including the vertical travel)
					var newScore = bestScores[current] + 1 + heightDifference
					# If this is a new best way to get to the tile, or if this tile has not been found before at all
					if (n not in bestScores or newScore < bestScores[n]):
						# Note how we got here and what the real score is
						bestScores[n] = newScore
						cameFrom[n] = current
						
						# If it has not already been added to the search queue, add it
						if !toExplore.has(n):
							toExplore.insert(newScore + dist(n, finish), n)
	return []

func dist(pos1, pos2):
	# Euclidian distance function
	return sqrt(((pos1.x - pos2.x) ** 2) + ((pos1.y - pos2.y) ** 2))

func getHeight(x, z) -> float:
	# Get the height of the ground at some position, returning -1 if the position is blocked
	# Automatically converts worldspace into array indices
	if (abs(x) > MAP_RAD or abs(z) > MAP_RAD):
		return -1
	return heightMap[x + MAP_RAD][z + MAP_RAD]

func _placeCube(x, z) -> void:
	#Find the tile height from the noisemap, normalized to all be non-negative. Scale them to half that height (since scale extends out in both directions). They extend from the center, so we then move them +y so all that height goes up
	var tileHeight = (noisegen.get_noise_2d(x,z) * (MAX_HEIGHT / 2)) + (MAX_HEIGHT / 2)
	tileHeight += (noisegen2.get_noise_2d(x,z) * (MAX_HEIGHT2 / 2)) + (MAX_HEIGHT2 / 2)
	
	#record data to heightmap for easy reference
	heightMap[x + MAP_RAD][z + MAP_RAD] = tileHeight;
	
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
	
	#Initialize the heightMap array
	heightMap = _makeBlankSquareArray((MAP_RAD * 2) + 1)
	
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
		
		z += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
