class_name Overworld
extends Node2D


const VIEW_DISTANCE := 768.0
const MAP_EXPLORATION_TRAVEL_INTERVAL := 350.0
const EXPIRY_TIME := 3.0

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
		SectionDescriptor.new(500)
			.add_level_gen(TerrainGen.new(_seed, terrain_mesh))
			.add_level_gen(CheckpointGen.new(_seed, 300)),
	]
	
	for i in range(_section_descriptors.size() - 1):
		_section_descriptors[i].set_max_distance(_section_descriptors[i + 1].min_distance)
	
	_section_descriptors.back().set_max_distance(50000)
	
	_section_descriptors[1].level_gens["checkpoints"].get_feature_map(
		Rect2i(Vector2i(-1000, -1000), Vector2i(2000, 1000)),
		1000
	).save_png("lmaozer.png")
	_section_descriptors[1].level_gens["terrain"].get_feature_map(
		Rect2i(Vector2i(-1000, -1000), Vector2i(2000, 1000)),
		1000
	).save_png("lmao1.png")


func _process(_delta: float) -> void:
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


func get_whole_map() -> Image:
	var bounds := Rect2i()
	bounds.position.x = ThisUser.min_map_x
	bounds.position.y = ThisUser.min_map_y
	bounds.end.x = ThisUser.max_map_x
	bounds.end.y = 0
	
	var single_view_mask := preload("res://circle.png").get_image()
	var single_view_mask_width := VIEW_DISTANCE / maxi(bounds.size.x, bounds.size.y) * 8192 * 2
	print_debug(single_view_mask_width)
	single_view_mask.resize(single_view_mask_width, single_view_mask_width, Image.INTERPOLATE_NEAREST)
	var explored_mask := Image.create(8192, 8192 / bounds.size.aspect(), false, Image.FORMAT_RGBA8)
	ThisUser.bake_path()
	for path in ThisUser.baked_paths:
		for i in range(ceili(path.get_baked_length() / MAP_EXPLORATION_TRAVEL_INTERVAL)):
			var point := path.sample_baked(i * MAP_EXPLORATION_TRAVEL_INTERVAL)
			var img_point := Vector2i(((point - Vector2(bounds.position)) / Vector2(bounds.size) * 8192).round())
			explored_mask.blit_rect_mask(single_view_mask, single_view_mask, Rect2i(Vector2.ZERO, single_view_mask.get_size()), img_point)

	for section in _section_descriptors:
		if "terrain" in section.level_gens:
			pass

	return explored_mask


func _exit_tree() -> void:
	get_whole_map().save_png("lwfwhe.png")
