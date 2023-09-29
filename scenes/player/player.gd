class_name Player
extends RigidBody2D


const THUMP := preload("res://sfx/536789__egomassive__thumps.wav")

signal died
#signal respawned

var max_floor_angle_degrees := 60.0

var initial_jump_velocity := 500.0
var jump_acceleration := 250.0
var jump_duration := 0.75
var jump_direction: float
var dead := false

var _jumping := false
var _jump_timer := 0.0

var _velocity_set_is_queued := false
var _queued_velocity_set: Vector2
var _queued_velocity_addition: Vector2
var _position_set_is_queued := false
var _queued_position_set: Vector2
var trying_to_jump := false:
	set = set_trying_to_jump

@onready var playback: AudioStreamPlayer2D = $Playback

func set_trying_to_jump(value: bool) -> void:
	if value == trying_to_jump:
		return
	
	trying_to_jump = value
	
	if value:
		var jump_vector := Vector2.RIGHT.rotated(jump_direction)
		_jump_timer = jump_duration
		_jumping = true
		var current_velocity_dot = linear_velocity.dot(jump_vector)

		if current_velocity_dot > 0:
			queue_velocity_set(linear_velocity.project(jump_vector) + jump_vector * initial_jump_velocity)
		
		else:
			queue_velocity_set(jump_vector * initial_jump_velocity)
		
	elif _jumping:
		_jumping = false


func queue_position_set(new_position: Vector2):
	_queued_position_set = new_position
	_position_set_is_queued = true


func queue_velocity_addition(velocity_addition: Vector2):
	_queued_velocity_addition += velocity_addition


func queue_velocity_set(new_velocity: Vector2):
	_queued_velocity_set = new_velocity
	_velocity_set_is_queued = true


func _process(delta):
	if _jumping:
		_queued_velocity_addition += Vector2.RIGHT.rotated(jump_direction) * jump_acceleration * delta
		_jump_timer -= delta

		if _jump_timer <= 0:
			_jumping = false
	
	if global_position.y > 600 and not dead:
		dead = true
		died.emit()
#		if global_position.y > 1000:
#			queue_position_set(Vector2.ZERO)
#			queue_velocity_set(Vector2.ZERO)
#			dead = false
#			respawned.emit()


func respawn_at(pos: Vector2) -> void:
	queue_position_set(pos)
	queue_velocity_set(Vector2.ZERO)
	await get_tree().physics_frame
	dead = false


func _integrate_forces(state: PhysicsDirectBodyState2D):
	if _position_set_is_queued:
		state.transform.origin = _queued_position_set
		_position_set_is_queued = false
		
	if _velocity_set_is_queued:
		state.linear_velocity = _queued_velocity_set
		_velocity_set_is_queued = false

	state.linear_velocity += _queued_velocity_addition
	_queued_velocity_addition = Vector2.ZERO
	
	if state.get_contact_count() > 0:
		var max_speed := 0.0
		for i in range(state.get_contact_count()):
			max_speed = maxf(state.get_contact_local_velocity_at_position(i).dot(state.get_contact_local_normal(i)), max_speed)
		if max_speed >= 100:
			play_sound(THUMP, sqrt(max_speed / 10), 0.97 + 0.06 * randf())


@rpc("unreliable", "call_remote", "any_peer")
@warning_ignore("shadowed_variable_base_class")
func network_update(velocity: Vector2, position: Vector2, rotation: float, angular_velocity: float):
	queue_velocity_set(velocity)
	queue_position_set(position)
	self.rotation = rotation
	self.angular_velocity = angular_velocity


func play_sound(stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> void:
	playback.get_stream_playback().play_stream(stream, 0, volume_db, pitch)
