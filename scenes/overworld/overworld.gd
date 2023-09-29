class_name Overworld
extends Node2D


const EXPIRY_TIME := 3.0
#const CELL_WIDTH := 20
#const ORIGIN_CLEARING_DISTANCE := 400

var _section_descriptors: Array[SectionDescriptor]
var _seed: int


func _ready() -> void:
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	var data := ThisUser.username.to_utf8_buffer()
	var string_size := data.size()
	data.append_array(PackedByteArray([0, 0, 0, 0, 0, 0, 0, 0]))
	data.encode_s32(string_size, ThisUser.bloodline)
	hasher.update(data)
	var numbers := hasher.finish().to_int64_array()
	_seed = numbers[0]
	for i in range(1, numbers.size()):
		_seed ^= numbers[i]
	
	var terrain_mesh: MultiMesh = $MultiMeshInstance2D.multimesh
	terrain_mesh.instance_count = ThisUser.max_terrain_blocks_visible
	
	_section_descriptors = [
		SectionDescriptor.new(0)
			.add_level_gen(LevelGen.new()),
		SectionDescriptor.new(300)
			.add_level_gen(TerrainGen.new(_seed, terrain_mesh))
			.add_level_gen(CheckpointGen.new(_seed, 300)),
	]
	
	for i in range(_section_descriptors.size() - 1):
		_section_descriptors[i].set_max_distance(_section_descriptors[i + 1].min_distance)
	
	_section_descriptors.back().set_max_distance(50000)
	
	_update_player_view()


func _process(_delta: float) -> void:
	_update_player_view()
	var visible_rect := get_viewport().canvas_transform.affine_inverse() * get_viewport().get_visible_rect()
	visible_rect = visible_rect.grow(200)
	
	var min_i := 0
	var max_i := _section_descriptors.size() - 1
	
	var i := get_section_descriptor(visible_rect.position)
	min_i = mini(min_i, i)
	max_i = maxi(max_i, i)
	
	i = get_section_descriptor(visible_rect.position + Vector2(visible_rect.size.x, 0))
	min_i = mini(min_i, i)
	max_i = maxi(max_i, i)
	
	i = get_section_descriptor(visible_rect.position + Vector2(visible_rect.size.y, 0))
	min_i = mini(min_i, i)
	max_i = maxi(max_i, i)
	
	i = get_section_descriptor(visible_rect.end)
	min_i = mini(min_i, i)
	max_i = maxi(max_i, i)
	
	for j in range(min_i, max_i + 1):
		_section_descriptors[j].generate_inside(visible_rect, on_generation)


#func get_cells_rect() -> Rect2i:
#	var cell_position := (visible_rect.position / CELL_WIDTH).floor()
#	var cell_end := (visible_rect.end / CELL_WIDTH).ceil()
#	return Rect2i(cell_position, cell_end - cell_position)


func _update_player_view() -> void:
	pass
#	for x in range(cells_rect.position.x, cells_rect.end.x + 1):
#		for y in range(cells_rect.position.y, cells_rect.end.y + 1):
#			if y > 0:
#				# Underworld
#				continue
#			var pos := Vector2i(x, y)
#			if _last_cells_rect.has_point(pos):
#				continue
#			if (pos * CELL_WIDTH).length() <= ORIGIN_CLEARING_DISTANCE:
#				# Leave space for spawn
#				continue
#			var node := sample_level_gen(pos)
#			if node == null:
#				continue
#			add_child(node)
#
#	_last_cells_rect = cells_rect


func on_generation(node: BoundedNode2D) -> void:
	add_child(node)


func get_section_descriptor(pos: Vector2) -> int:
	var distance := pos.length()
	var desc_i := 0

	for i in range(_section_descriptors.size() - 1, -1, -1):
		var current_desc: SectionDescriptor = _section_descriptors[i]
		if current_desc.min_distance < distance:
			desc_i = i
			break

	return desc_i


class SectionDescriptor:
	var min_distance: int
	var level_gens := {}
	
	@warning_ignore("shadowed_variable")
	func _init(min_distance: int) -> void:
		self.min_distance = min_distance
	
	func set_max_distance(max_distance: float) -> void:
		for lvl_gen in level_gens.values():
			lvl_gen.set_bounds(min_distance, max_distance)
	
	func add_level_gen(level_gen: LevelGen) -> SectionDescriptor:
		level_gen.set_level_gens(level_gens)
		return self
	
	func generate_inside(rect: Rect2, action: Callable) -> void:
		for level_gen in level_gens.values():
			level_gen.generate_inside(rect, action)
	
#	func sample(cell_pos: Vector2i) -> BoundedNode2D:
#		assert((cell_pos * CELL_WIDTH).length() >= min_distance)
#		var nodes: Array[BoundedNode2D] = []
#		for lvl_gen in level_gens.values():
#			var node: BoundedNode2D = lvl_gen.sample(cell_pos)
#			if node == null:
#				continue
#			nodes.push_back(node)
#
#		var reducer := func(_accum: BoundedNode2D, current: BoundedNode2D):
#			# TODO Improve
#			return current
#
#		return nodes.reduce(reducer)
