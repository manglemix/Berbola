extends Node


const BAKE_SIZE := 300


var username := "manglemix"
var bloodline := 0
# Set of Vector2i
var activated_checkpoints := {}
var last_activated_checkpoint: Vector2i
var max_terrain_blocks_visible := 6144

var min_map_x := 0
var max_map_x := 0
var min_map_y := 0
var baked_paths: Array[Curve2D] = []
var current_path := Curve2D.new()


func _ready() -> void:
	current_path.bake_interval = 1000


func add_path_point(pos: Vector2i) -> void:
	if pos.y > 0:
		bake_path()
		return
	min_map_x = mini(min_map_x, pos.x)
	max_map_x = maxi(max_map_x, pos.x)
	min_map_y = mini(min_map_y, pos.y)
	current_path.add_point(pos)
	if current_path.point_count >= BAKE_SIZE:
		bake_path()


func _on_local_player_died() -> void:
	bake_path()


func bake_path() -> void:
	if current_path.point_count == 0:
		return
	var baked_path := Curve2D.new()
	for point in current_path.get_baked_points():
		baked_path.add_point(point)
	baked_paths.append(baked_path)
	current_path.clear_points()
