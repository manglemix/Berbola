class_name Terrain
extends BoundedNode2D


#const OCCLUDER_SHRINK := 0.5
#const OCCLUDER_SHRINK_DISTANCE := 10 * OCCLUDER_SHRINK

var gen: TerrainGen

#
#func set_multi_mesh(mesh: MultiMesh) -> void:
#	$MultiMeshInstance2D.multimesh = mesh


#func _ready() -> void:
#	var occluder: LightOccluder2D = $LightOccluder2D
#
#	if not gen.is_cell_occupied(cell_pos + Vector2i.UP) or not gen.is_cell_occupied(cell_pos + Vector2i.UP + Vector2i.LEFT) or not gen.is_cell_occupied(cell_pos + Vector2i.UP + Vector2i.LEFT):
#		occluder.position -= Vector2i.UP * OCCLUDER_SHRINK_DISTANCE
#		occluder.scale.y -= OCCLUDER_SHRINK
#	if not gen.is_cell_occupied(cell_pos + Vector2i.DOWN) or not gen.is_cell_occupied(cell_pos + Vector2i.DOWN + Vector2i.LEFT) or not gen.is_cell_occupied(cell_pos + Vector2i.DOWN + Vector2i.LEFT):
#		occluder.position -= Vector2i.DOWN * OCCLUDER_SHRINK_DISTANCE
#		occluder.scale.y -= OCCLUDER_SHRINK
#
#	if not gen.is_cell_occupied(cell_pos + Vector2i.LEFT) or not gen.is_cell_occupied(cell_pos + Vector2i.UP + Vector2i.LEFT) or not gen.is_cell_occupied(cell_pos + Vector2i.DOWN + Vector2i.LEFT):
#		occluder.position -= Vector2i.LEFT * OCCLUDER_SHRINK_DISTANCE
#		occluder.scale.x -= OCCLUDER_SHRINK
#	if not gen.is_cell_occupied(cell_pos + Vector2i.RIGHT) or not gen.is_cell_occupied(cell_pos + Vector2i.UP + Vector2i.RIGHT) or not gen.is_cell_occupied(cell_pos + Vector2i.DOWN + Vector2i.RIGHT):
#		occluder.position -= Vector2i.RIGHT * OCCLUDER_SHRINK_DISTANCE
#		occluder.scale.x -= OCCLUDER_SHRINK
#
#	if is_zero_approx(occluder.scale.y) or is_zero_approx(occluder.scale.x):
#		occluder.queue_free()
