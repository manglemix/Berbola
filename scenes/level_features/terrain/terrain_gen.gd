class_name TerrainGen
extends LevelGen


var threshold: float
var instantiated := {}
var rng := FastNoiseLite.new()
var multimesh: MultiMesh
var free_indices := PackedInt32Array()


static func _get_name() -> String:
	return "terrain"


@warning_ignore("shadowed_global_identifier", "shadowed_variable")
func _init(seed: int, multimesh: MultiMesh, noise_type := FastNoiseLite.TYPE_VALUE, frequency := 0.1, threshold := 0.2):
	rng.seed = seed
	rng.noise_type = noise_type
	rng.frequency = frequency
	self.threshold = threshold
	self.multimesh = multimesh


func is_cell_occupied(cell_pos: Vector2i) -> bool:
	if rng.get_noise_2dv(cell_pos) < threshold:
		return false
	
	if cell_pos.y > 0:
		return false
	
	@warning_ignore("static_called_on_instance")
	var distance := (Vector2(cell_pos) * _get_cell_dimensions()).length()
	if distance < min_distance:
		return false
	if distance > max_distance:
		return false
	
	if "checkpoints" in level_gens:
		var checkpoint: CheckpointGen = level_gens["checkpoints"]
		for pos in checkpoint.checkpoints:
			pos = Vector2(pos) * CheckpointGen._get_cell_dimensions()
#			print(pos)
			@warning_ignore("static_called_on_instance")
			if (Vector2(cell_pos) * _get_cell_dimensions() - pos).length() < CheckpointGen.TERRAIN_DISTANCE:
				return false
	
	return true


func _sample(cell_pos: Vector2i) -> BoundedNode2D:
	if not is_cell_occupied(cell_pos):
		return
	
	if cell_pos in instantiated:
		instantiated[cell_pos].intersected()
		return
	
	@warning_ignore("static_called_on_instance")
	var final_pos := cell_pos * Vector2i(_get_cell_dimensions())
	var mesh := preload("res://scenes/level_features/terrain/terrain.tscn").instantiate()
	mesh.cell_pos = cell_pos
	mesh.position = final_pos
	mesh.gen = self
	instantiated[cell_pos] = mesh
	var current_index: int
	
	if free_indices.is_empty():
		current_index = multimesh.visible_instance_count
	
		if multimesh.visible_instance_count == multimesh.instance_count:
			var old_buffer := multimesh.buffer
			multimesh.instance_count *= 2
			old_buffer.resize(multimesh.buffer.size())
			for i in range(multimesh.buffer.size() - old_buffer.size()):
				old_buffer.append(0)
			multimesh.buffer = old_buffer
	
		multimesh.visible_instance_count += 1
		ThisUser.max_terrain_blocks_visible = maxi(ThisUser.max_terrain_blocks_visible, multimesh.visible_instance_count)
		
	else:
		current_index = free_indices[free_indices.size() - 1]
		free_indices.remove_at(free_indices.size() - 1)
	
	multimesh.set_instance_transform_2d(current_index, mesh.transform)
	multimesh.set_instance_color(current_index, Color.WHITE)
	mesh.tree_exited.connect(
		func():
			instantiated.erase(cell_pos)
			multimesh.set_instance_color(current_index, Color(0, 0, 0, 0))
			free_indices.append(current_index)
	)
	return mesh


static func _get_cell_dimensions() -> Vector2:
	return Vector2(20, 20)


func get_feature_map(bounds: Rect2i, img_width: int) -> Image:
	var aspect := bounds.size.aspect()
	bounds.position.x /= 20
	bounds.position.y /= 20
	bounds.end.x = ceili(bounds.end.x as float / 20)
	bounds.end.y = ceili(bounds.end.y as float / 20)
	rng.offset = Vector3(- bounds.size.x / 2, - bounds.size.y, 0)
	var img := rng.get_image(bounds.size.x, bounds.size.y, false, false, false)
	rng.offset = Vector3.ZERO
	var normalized_threshold := (threshold + 1) / 2
	img.adjust_bcs(1 / normalized_threshold / 2, 1, 1)
	img.adjust_bcs(1, 1000, 1)
	img.convert(Image.FORMAT_RGBA8)
	
	var furthest_distance := bounds.position.length()
	furthest_distance = maxf(furthest_distance, bounds.end.length())
	furthest_distance = maxf(furthest_distance, (bounds.position + Vector2i(bounds.size.x, 0)).length())
	furthest_distance = maxf(furthest_distance, (bounds.position + Vector2i(0, bounds.size.y)).length())
	
	if max_distance / furthest_distance > 5:
		var min_distance_img := preload("res://circle.png").get_image()
		var width := min_distance / 10
		min_distance_img.resize(width, width, Image.INTERPOLATE_NEAREST)
		min_distance_img.adjust_bcs(0, 1, 1)
		img.blit_rect_mask(min_distance_img, min_distance_img, Rect2i(Vector2i.ZERO, min_distance_img.get_size()), - bounds.position + Vector2i.DOWN * min_distance_img.get_size().y / 2)
	
	else:
		var mask := get_distance_mask()
	
	@warning_ignore("narrowing_conversion")
	if img_width < bounds.size.x:
		img.resize(img_width, img_width / aspect, Image.INTERPOLATE_LANCZOS)
	else:
		img.resize(img_width, img_width / aspect, Image.INTERPOLATE_NEAREST)
	return img
