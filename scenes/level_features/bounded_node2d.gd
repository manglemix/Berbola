class_name BoundedNode2D
extends VisibleOnScreenNotifier2D

const MAX_OUT_OF_SCREEN_TIME := 5.0

var cell_pos: Vector2i
var _life_timer := 0.0
var _debugger: BoundedNodeDebug


#func _ready() -> void:
#	add_debugger()


func add_debugger():
	_debugger = BoundedNodeDebug.new()
	add_child(_debugger)


func intersected():
	if _debugger != null:
		_debugger.intersected()


func _process(delta: float) -> void:
	if is_on_screen():
		_life_timer = 0
	else:
		_life_timer += delta
		if _life_timer >= MAX_OUT_OF_SCREEN_TIME:
			queue_free()
