extends CharacterBody3D

@onready var animation_tree: AnimationTree = $THREEDMODEL/AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")


@onready var camera: Camera3D = $THREEDMODEL/Node/Skeleton3D/BoneAttachment3D/Camera3D  # Make sure you have a Camera3D node as a child
var mouse_sensitivity: float = 0.002
var vertical_look_limit: float = 90.0  # Degrees
var mouse_captured: bool = false


# Movement parameters
var speed: float = 5.0
var run_speed_multiplier: float = 2.0
var crouch_speed_multiplier: float = 0.5
var jump_force: float = 12.0
var gravity: float = 20.0

# Animation parameters
var is_moving: bool = false
var is_running: bool = false
var is_crouching: bool = false
var is_jumping: bool = false
var is_falling: bool = false
var is_attacking: bool = false
var is_blocking: bool = false

# Available states - WILL BE AUTO-GENERATED
var available_states = [
	"idle",
	"walk_forward",
	"walk_backward",
	"walk_left",
	"walk_right",
	"run_forward",
	"run_backward",
	"run_left",
	"run_right",
	"crouch_idle",
	"crouch_forward",
	"crouch_backward",
	"crouch_left",
	"crouch_right",
	"jump",
	"fall",
	"land",
	"slide",
	"walk_blend_space",
	"run_blend_space",
	"crouch_blend_space",

]

# Animation timers
var attack_timer: float = 0.0
var attack_duration: float = 0.5
var dodge_timer: float = 0.0
var dodge_duration: float = 0.3

func _ready():
		# Add this to your existing _ready() function
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true
	
	# Make sure you have a Camera3D node
	if not camera:
		# Try to find any Camera3D in children
		camera = find_child("Camera3D")
		if not camera:
			push_error("No Camera3D node found for first-person controller!")
	if animation_tree:
		animation_tree.active = true
		# Start with idle if available, otherwise use first available state
		if "idle" in available_states:
			state_machine.start("idle")
		elif "crouch_idle" in available_states:
			state_machine.start("crouch_idle")
		elif available_states.size() > 0:
			state_machine.start(available_states[0])
	else:
		push_error("AnimationTree not found! Make sure the path is correct.")

func _physics_process(delta):
	_handle_timers(delta)
	_handle_input()
	_handle_movement(delta)
	_handle_gravity(delta)
	_handle_jump()
	move_and_slide()
	_update_animations()

func _handle_timers(delta):
	# Attack timer
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
	
	# Dodge timer
	if dodge_timer > 0:
		dodge_timer -= delta

func _handle_input():
	# Combat inputs
	if Input.is_action_just_pressed("attack") and not is_attacking and is_on_floor():
		is_attacking = true
		attack_timer = attack_duration
	
	if Input.is_action_just_pressed("dodge") and not is_attacking and dodge_timer <= 0:
		dodge_timer = dodge_duration
		_perform_dodge()
	
	# Blocking
	is_blocking = Input.is_action_pressed("block") and not is_attacking and is_on_floor()
	
	# Crouching
	is_crouching = Input.is_action_pressed("crouch") and is_on_floor() and not is_attacking
	
	# Running
	is_running = Input.is_action_pressed("run") and not is_crouching and not is_attacking

func _handle_movement(delta):
	# Don't move if attacking or blocking
	if is_attacking or is_blocking:
		velocity.x = move_toward(velocity.x, 0, speed * 2)
		velocity.z = move_toward(velocity.z, 0, speed * 2)
		is_moving = false
		return
	
	var input_dir = Input.get_vector("move_right", "move_left", "move_back", "move_forward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Calculate current speed based on state
	var current_speed = speed
	if is_crouching:
		current_speed *= crouch_speed_multiplier
	elif is_running:
		current_speed *= run_speed_multiplier
	
	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		is_moving = true
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		is_moving = false

func _handle_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
		is_falling = velocity.y < 0
	else:
		is_falling = false
		if velocity.y < 0:
			velocity.y = 0

func _handle_jump():
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching and not is_attacking:
		velocity.y = jump_force
		is_jumping = true
		is_crouching = false  # Cancel crouch when jumping
	else:
		is_jumping = false

func _perform_dodge():
	# Simple dodge implementation - you can enhance this
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir != Vector2.ZERO:
		var dodge_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		velocity.x = dodge_direction.x * speed * 3
		velocity.z = dodge_direction.z * speed * 3

func _update_animations():
	if not state_machine:
		return
	
	# Get input direction for blend spaces
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Priority: attacking > dodging > jumping > falling > blocking > crouching > moving > idle
	
	# Combat animations
	if is_attacking:
		if "attack_1" in available_states:
			state_machine.travel("attack_1")
		return
	
	if is_blocking and "block" in available_states:
		state_machine.travel("block")
		return
	
	if dodge_timer > 0 and "dodge" in available_states:
		state_machine.travel("dodge")
		return
	
	# Aerial animations
	if is_jumping and "jump" in available_states:
		state_machine.travel("jump")
		return
	
	if is_falling and "fall" in available_states:
		state_machine.travel("fall")
		return
	
	if is_on_floor() and was_falling() and "land" in available_states:
		state_machine.travel("land")
		return
	
	# Ground movement animations
	if is_crouching:
		if is_moving:
			# Try crouch blend space first
			if "crouch_blend_space" in available_states:
				state_machine.travel("crouch_blend_space")
				animation_tree.set("parameters/crouch_blend_space/blend_position", input_dir)
			else:
				# Use individual crouch animations
				_play_directional_animation("crouch", input_dir)
		else:
			# Crouch idle
			if "crouch_idle" in available_states:
				state_machine.travel("crouch_idle")
	
	elif is_moving:
		if is_running:
			# Try run blend space first
			if "run_blend_space" in available_states:
				state_machine.travel("run_blend_space")
				animation_tree.set("parameters/run_blend_space/blend_position", input_dir)
			else:
				# Use individual run animations
				_play_directional_animation("run", input_dir)
		else:
			# Try walk blend space first
			if "walk_blend_space" in available_states:
				state_machine.travel("walk_blend_space")
				animation_tree.set("parameters/walk_blend_space/blend_position", input_dir)
			else:
				# Use individual walk animations
				_play_directional_animation("walk", input_dir)
	
	else:
		# Idle
		if "idle" in available_states:
			state_machine.travel("idle")

func _play_directional_animation(movement_type: String, input_dir: Vector2):
	# Determine direction based on input
	var anim_name = ""
	
	if abs(input_dir.y) > abs(input_dir.x):
		# Forward/backward movement
		if input_dir.y < -0.1:
			anim_name = movement_type + "_forward"
		elif input_dir.y > 0.1:
			anim_name = movement_type + "_backward"
	else:
		# Left/right movement
		if input_dir.x < -0.1:
			anim_name = movement_type + "_left"
		elif input_dir.x > 0.1:
			anim_name = movement_type + "_right"
	
	# Fallback to forward if specific direction not available
	if anim_name == "" or anim_name not in available_states:
		anim_name = movement_type + "_forward"
	
	# Final fallback
	if anim_name not in available_states and movement_type + "_forward" in available_states:
		anim_name = movement_type + "_forward"
	
	if anim_name in available_states:
		state_machine.travel(anim_name)

var was_in_air: bool = false

func was_falling() -> bool:
	# Check if we just landed
	var just_landed = was_in_air and is_on_floor()
	was_in_air = not is_on_floor()
	return just_landed

func _input(event):
	# Handle any additional input events here
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				if "attack_1" in available_states:
					_force_play_animation("attack_1")
			KEY_2:
				if "attack_2" in available_states:
					_force_play_animation("attack_2")
			KEY_3:
				if "attack_3" in available_states:
					_force_play_animation("attack_3")
	# Handle any additional input events here
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				if "attack_1" in available_states:
					_force_play_animation("attack_1")
			KEY_2:
				if "attack_2" in available_states:
					_force_play_animation("attack_2")
			KEY_3:
				if "attack_3" in available_states:
					_force_play_animation("attack_3")
			KEY_ESCAPE:
				# Toggle mouse capture
				if mouse_captured:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
					mouse_captured = false
				else:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
					mouse_captured = true
	
	# Handle mouse look
	if event is InputEventMouseMotion and mouse_captured:
		_handle_mouse_look(event)

func _handle_mouse_look(event: InputEventMouseMotion):
	# Horizontal rotation - rotate the entire character
	rotate_y(-event.relative.x * mouse_sensitivity)
	
	# Vertical rotation - only rotate the camera
	if camera:
		var current_tilt = camera.rotation.x
		var new_tilt = current_tilt - event.relative.y * mouse_sensitivity
		
		# Clamp the vertical rotation to prevent over-rotation
		new_tilt = clamp(new_tilt, 
			deg_to_rad(-vertical_look_limit), 
			deg_to_rad(vertical_look_limit))
		
		camera.rotation.x = new_tilt
# Helper functions
func has_animation_state(state_name: String) -> bool:
	return state_name in available_states

func _force_play_animation(state_name: String):
	if has_animation_state(state_name) and state_machine:
		state_machine.travel(state_name)
		is_attacking = true
		attack_timer = attack_duration

func play_animation(state_name: String):
	if has_animation_state(state_name) and state_machine:
		state_machine.travel(state_name)

# Combat system helpers
func can_attack() -> bool:
	return not is_attacking and is_on_floor()

func can_block() -> bool:
	return not is_attacking and is_on_floor()

func can_dodge() -> bool:
	return dodge_timer <= 0 and not is_attacking

# Movement state queries
func is_in_air() -> bool:
	return not is_on_floor()

func get_current_animation_state() -> String:
	if state_machine:
		return state_machine.get_current_node()
	return ""

# Debug function
func print_current_state():
	print("Current State: ", get_current_animation_state())
	print("Moving: ", is_moving, " | Running: ", is_running, " | Crouching: ", is_crouching)
	print("Jumping: ", is_jumping, " | Falling: ", is_falling)
	print("Attacking: ", is_attacking, " | Blocking: ", is_blocking)
