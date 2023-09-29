class_name LocalPlayer
extends Player


const HEARING_RAYCASTS := 4
const HEARING_SPREAD := 60
const HEARING_DISTANCE := 300

var max_jumps := 2
var playback2: AudioStreamPlayer2D

var _left_raycasts: Array[RayCast2D] = []
var _right_raycasts: Array[RayCast2D] = []
var _network_update_timer := 0.0

@onready var _current_jumps := max_jumps
@onready var _reverb_left: AudioEffectReverb = AudioServer.get_bus_effect(AudioServer.get_bus_index("ReverbLeft"), 0)
@onready var _reverb_right: AudioEffectReverb = AudioServer.get_bus_effect(AudioServer.get_bus_index("ReverbRight"), 0)


func _ready() -> void:
	playback2 = AudioStreamPlayer2D.new()
	playback2.stream = AudioStreamPolyphonic.new()
	playback2.bus = "ReverbRight"
	playback2.autoplay = true
	add_child(playback2)
	playback.bus = "ReverbLeft"
	max_contacts_reported = 3
	var player_origin: Node2D = $"Node/PlayerOrigin"
	
	for x_sign in range(-1, 2, 2):
		for angle in range(- HEARING_SPREAD, HEARING_SPREAD + 1, HEARING_SPREAD / HEARING_RAYCASTS):
			var raycast := RayCast2D.new()
			raycast.target_position = Vector2(x_sign * HEARING_DISTANCE, 0).rotated(deg_to_rad(angle))
			player_origin.add_child(raycast)
			if x_sign < 0:
				_left_raycasts.append(raycast)
			else:
				_right_raycasts.append(raycast)


func set_trying_to_jump(value: bool) -> void:
	if value == trying_to_jump:
		return
	
	trying_to_jump = value
	
	if value:
		if _current_jumps <= 0:
			return
		
		var jump_vector := Vector2.RIGHT.rotated(jump_direction)
		_current_jumps -= 1
		_jump_timer = jump_duration
		_jumping = true
		var current_velocity_dot = linear_velocity.dot(jump_vector)

		if current_velocity_dot > 0:
			queue_velocity_set(linear_velocity.project(jump_vector) + jump_vector * initial_jump_velocity)
		
		else:
			queue_velocity_set(jump_vector * initial_jump_velocity)
		
	elif _jumping:
		_jumping = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		trying_to_jump = true
	elif event.is_action_released("jump"):
		trying_to_jump = false


func _process(delta: float) -> void:
	super(delta)
	jump_direction = (get_global_mouse_position() - global_position).angle()
	
	_network_update_timer -= delta
	if _network_update_timer <= 0.0:
		_network_update_timer = NETWORK_UPDATE_DELAY
		network_update.rpc(linear_velocity, position, rotation, angular_velocity)


func _physics_process(_delta: float) -> void:
	var distance := 0.0
	
	for raycast in _left_raycasts:
		if raycast.is_colliding():
			distance += raycast.get_collision_point().distance_to(global_position)
		else:
			distance += HEARING_DISTANCE
	
	var distance_factor := distance / HEARING_DISTANCE / (HEARING_RAYCASTS * 2 + 1)
	_reverb_left.room_size = 0.8 * distance_factor
	_reverb_left.damping = 0.6 - 0.5 * distance_factor
	distance = 0
	
	for raycast in _right_raycasts:
		if raycast.is_colliding():
			distance += raycast.get_collision_point().distance_to(global_position)
		else:
			distance += raycast.target_position.length()
	
	distance_factor = distance / HEARING_DISTANCE / (HEARING_RAYCASTS * 2 + 1)
	_reverb_right.room_size = 0.8 * distance_factor
	_reverb_right.damping = 0.6 - 0.5 * distance_factor


func _integrate_forces(state: PhysicsDirectBodyState2D):
	super(state)
	
	var normal_sum := Vector2.ZERO
	
	if state.get_contact_count() > 0:
		if is_zero_approx(linear_velocity.length_squared()):
			_current_jumps = max_jumps
		
		else:
			for i in range(state.get_contact_count()):
				normal_sum += state.get_contact_local_normal(i)
			
			if normal_sum.length_squared() > 0:
				if abs(normal_sum.angle_to(Vector2.UP)) <= deg_to_rad(max_floor_angle_degrees) and _current_jumps != max_jumps:
					_current_jumps = max_jumps
	
#		var collision_speed := absf(linear_velocity.dot(normal_sum.normalized()))
#		if collision_speed > _variable_volume.min_stimuli_value:
#			add_child(_variable_volume.produce_player(THUMP_SOUND, collision_speed))


func play_sound(stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> void:
	playback.get_stream_playback().play_stream(stream, 0, volume_db, pitch)
	playback2.get_stream_playback().play_stream(stream, 0, volume_db, pitch)
