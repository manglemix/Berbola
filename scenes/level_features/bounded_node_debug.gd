class_name BoundedNodeDebug
extends Node


const ACCESS_TIME := 2.0

var _access_timer := 0.0


func _ready() -> void:
	get_parent().modulate.b = 0
	create_tween().tween_property(get_parent(), "modulate:b", 1, 2.0)


func intersected():
	get_parent().modulate.r = 0
	_access_timer = ACCESS_TIME


func _process(delta: float) -> void:
	if _access_timer < 0:
		_access_timer = 0
		get_parent().modulate.r = 1
	else:
		get_parent().modulate.r = (ACCESS_TIME - _access_timer) / ACCESS_TIME
		_access_timer -= delta
