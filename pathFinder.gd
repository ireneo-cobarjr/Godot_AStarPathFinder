class_name pathFinder
extends TileMap


###############################################
#* Member variables #

## Creating the Astar2D Node
var path_find = AStar2D.new()

## This sets the variable to half the size of a tile's height.
## We will use this to get the midpoint of each cell/tile.
var half_y := (cell_size / 2).y

## This variable gets the starting point of the map size.
## This is in anticipation that the tilemap may not start at point (0,0)
## which is possible in a isometric tilemap.
var map_start_point setget __find_map_start_point


## This variable gets the end most point of the tilemap
## which will be used to determine if points is out of bounds.
var map_end_point setget __find_map_end_point

var active_cells = []

###############################################################
#* These variable is exported to the editor for convenience #
###############################################################
## Set the bounds of the map. Default is 0,0 w/c forces you to add your
## own value.

## Set the tile ids for obstacles, that is, tiles which is not a path.
export var Obstacles : PoolIntArray = [0]
var obstacles = []

###############################################


## Called when the node enters the scene tree for the first time.
func _ready() -> void:

	## Gather all cells with tiles on it
	active_cells = get_used_cells()

	__set_obstacles(Obstacles)

	## Get the top-left most point of the tilemap enclosing the cells with tiles
	__find_map_start_point(active_cells)

	## Get the bottom-right most point of the tilemap enclosing the cells with tiles
	__find_map_end_point(active_cells)

	## Add the paths to the Astar2D Node
	var registered_paths := __add_paths(active_cells)

	## Connect the paths on the Astar2D Node
	__connect_paths(registered_paths)

## Called every frame. 'delta' is the elapsed time since the previous frame.
## func _process(delta: float) -> void:
##	pass

###############################################
#* Public Member Functions #

func request_path(from : Vector2, to : Vector2) -> Object:
	var result = {"path_found": false, "paths": PoolVector2Array()}
	var created_path := PoolVector2Array([])
	var from_tile = world_to_map(from)
	var to_tile = world_to_map(to)

	if __is_valid_point(from_tile) and __is_valid_point(to_tile):
		var x = __set_path_index(from_tile)
		var y = __set_path_index(to_tile)
		var raw_paths = path_find.get_point_path(x, y)

		for path in raw_paths:
			var valid_path = map_to_world(path)
			valid_path.y += half_y
			created_path.append(valid_path)
		
		result.path_found = true
		result.paths = created_path
		return result
	else:
		result.path_found = false
		result.paths = created_path
		return result

###############################################
#* Pseudo Private Member Functions #

## Adds all tiles that are considered as 'walkable'
func __add_paths(cells) -> Array:
	var paths := []
	for a_path in cells:
		if obstacles.find(a_path) == -1:
			paths.append(a_path)
			var path_index :=  __set_path_index(a_path)
			path_find.add_point(path_index, a_path)
	return paths

## Connect the paths
func __connect_paths(paths : Array) -> void:
	for path in paths:
		var path_index = __set_path_index(path)
		for local_y in range(3):
			for local_x in range(3):
				var point_relative = Vector2(path.x + local_x - 1, path.y + local_y - 1)
				var point_relative_index = __set_path_index(point_relative)

				if point_relative == path or __is_out_bound(point_relative):
					continue
				if path_find.has_point(point_relative_index):
					if path_index != point_relative_index:
						path_find.connect_points(path_index, point_relative_index)


## Using a function to calculate the index from a point's coordinates
## ensures we always get the same index with the same input point
func __set_path_index(a_path : Vector2) -> float:
	var exact_width = (map_end_point.x - map_start_point.x) + 1
	var index = ((a_path.y - map_start_point.y) * exact_width) + (a_path .x - map_start_point.x)
	return index

## Getter function for map_start_point
func __find_map_start_point(cells : Array) -> void:
	var start_point := Vector2(0,0)
	start_point.y = cells[0].y
	start_point.x = (cells.min()).x
	map_start_point = start_point

## Getter function for map_end_point
func __find_map_end_point(cells : Array) -> void:
	var end_point := Vector2(0,0)
	end_point.y = cells[-1].y
	end_point.x = (cells.max()).x
	map_end_point = end_point

## Check if the given point is within the bounds of map
func __is_out_bound(point : Vector2) -> bool:
	if map_start_point.x <= point.x and map_start_point.y <= point.y:
		if map_end_point.x >= point.x and map_end_point.y >= point.y:
			return false
		else:
			return true
	else:
		return true

## Helper function if point/path request is valid
func __is_valid_point(point : Vector2) -> bool:
	if not __is_out_bound(point):
		var found = obstacles.find(point)
		if found == -1:
			return true
	return false

## Helper function to create ids for the AStar2D Node

func __get_map_length(start : int, end : int) -> int:
	var counter = 1
	while start < end:
		start += counter
		counter += 1
	return counter

func __set_obstacles(obs : Array):
	for obstacle in obs:
		var obs_set = get_used_cells_by_id(obstacle)
		for set in obs_set:
			obstacles.append(set)
