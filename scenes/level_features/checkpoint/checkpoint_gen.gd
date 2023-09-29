class_name CheckpointGen
extends LevelGen


const TERRAIN_DISTANCE := 300
const CHECKPOINT_DISTANCE := 10
const MAX_ATTEMPS := 500


var checkpoints := {}
var gap_from_end: int
var gap_from_start: int
var count: int
@warning_ignore("shadowed_global_identifier")
var seed: int


static func _get_name() -> String:
	return "checkpoints"


@warning_ignore("shadowed_variable")
func _init(seed: int, count: int, gap_from_start := 1000, gap_from_end := 1000):
	self.seed = seed
	self.count = count
	self.gap_from_start = gap_from_start
	self.gap_from_end = gap_from_end


@warning_ignore("shadowed_variable")
func set_bounds(min_distance: float, max_distance: float) -> void:
	super(min_distance, max_distance)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for _i in range(count):
		var pos: Vector2i
		for j in range(MAX_ATTEMPS):
			var tmp := Vector2(
				rng.randf_range(-max_distance, max_distance),
				rng.randf_range(-max_distance, 0),
			)
			var distance := tmp.length()
			if distance >= min_distance + gap_from_start and distance <= max_distance - gap_from_end:
				@warning_ignore("static_called_on_instance")
				pos = Vector2i(tmp / _get_cell_dimensions())
				
				var failed := false
				for other_pos in checkpoints:
					if (pos - other_pos).length() < CHECKPOINT_DISTANCE:
						failed = true
						break
				if not failed:
					break
			
			if j == MAX_ATTEMPS - 1:
				push_error("Ran out of space for checkpoints")
				return
		
		checkpoints[pos] = null


static func _get_cell_dimensions() -> Vector2:
	return Vector2(150, 90)


func _sample(cell_pos: Vector2i) -> BoundedNode2D:
	if not cell_pos in checkpoints or checkpoints[cell_pos] != null:
		return null
	
	var node: BoundedNode2D = preload("res://scenes/level_features/checkpoint/checkpoint.tscn").instantiate()
	checkpoints[cell_pos] = node
	
	@warning_ignore("static_called_on_instance")
	node.position = Vector2(cell_pos) * _get_cell_dimensions()
	node.cell_pos = cell_pos
	node.tree_exited.connect(
		func():
			checkpoints[cell_pos] = null
	)
	return node
