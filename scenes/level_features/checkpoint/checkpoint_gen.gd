class_name CheckpointGen
extends LevelGen


const TERRAIN_DISTANCE := 300
const CHECKPOINT_DISTANCE := 20
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


func get_feature_map(bounds: Rect2i, img_width: int) -> Image:
	var aspect := bounds.size.aspect()
	bounds.position.x /= 150
	bounds.position.y /= 90
	bounds.end.x = ceili(bounds.end.x as float / 150)
	bounds.end.y = ceili(bounds.end.y as float / 90)
	var img := Image.create(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.BLACK)
	for pos in checkpoints:
		var x: int = pos.x - bounds.position.x
		var y: int = - pos.y + bounds.position.y
		if x < 0 or y < 0 or x >= bounds.size.x or y >= bounds.size.y:
			continue
		img.set_pixel(x, y, Color.WHITE)
	@warning_ignore("narrowing_conversion")
	if img_width < bounds.size.x:
		img.resize(img_width, img_width / aspect, Image.INTERPOLATE_LANCZOS)
	else:
		img.resize(img_width, img_width / aspect, Image.INTERPOLATE_NEAREST)
	return img
