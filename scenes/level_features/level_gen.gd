class_name LevelGen
extends RefCounted


var min_distance: float
var max_distance: float
var level_gens: Dictionary
var last_cells_rect: Rect2i


@warning_ignore("shadowed_variable")
func set_level_gens(level_gens: Dictionary) -> void:
	@warning_ignore("static_called_on_instance")
	level_gens[_get_name()] = self
	self.level_gens = level_gens


static func _get_name() -> String:
	return "none"


@warning_ignore("shadowed_variable")
func set_bounds(min_distance: float, max_distance: float) -> void:
	self.min_distance = min_distance
	self.max_distance = max_distance


func _sample(_cell_pos: Vector2i) -> BoundedNode2D:
	return null


static func _get_cell_dimensions() -> Vector2:
	return Vector2.ZERO


func generate_inside(rect: Rect2, action: Callable) -> void:
	var cells_rect := Rect2i()
	@warning_ignore("static_called_on_instance")
	cells_rect.position = Vector2i(rect.position / _get_cell_dimensions())
	@warning_ignore("static_called_on_instance")
	cells_rect.end = Vector2i((rect.end / _get_cell_dimensions()).ceil())
	
	if last_cells_rect == cells_rect:
		return
	
	for x in range(cells_rect.position.x, cells_rect.end.x + 1):
		for y in range(cells_rect.position.y, cells_rect.end.y + 1):
			if y > 0:
				# Underworld
				continue
			var pos := Vector2i(x, y)
			if last_cells_rect.has_point(pos):
				continue
			@warning_ignore("static_called_on_instance")
			var distance := (Vector2(pos) * _get_cell_dimensions()).length()
			if distance < min_distance:
				# Leave space for spawn
				continue
			if distance > max_distance:
				# Past max distance
				continue
			var node := _sample(pos)
			if node == null:
				continue
			action.call(node)
	
	last_cells_rect = cells_rect


func get_feature_map(bounds: Rect2i, img_width: int) -> Image:
	var img := Image.create(img_width, img_width / bounds.size.aspect(), false, Image.FORMAT_RGBA8)
	return img


func get_distance_mask() -> Image:
	var img := preload("res://circle.png").get_image()
	var inner_img := preload("res://anti_circle.png").get_image()
	var inner_size := 2048 * min_distance / max_distance
	inner_img.resize(inner_size, inner_size, Image.INTERPOLATE_BILINEAR)
	img.blit_rect(inner_img, Rect2i(Vector2i.ZERO, inner_img.get_size()), Vector2.ONE * (2048 - inner_size) / 2)
	return img
