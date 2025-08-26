extends CharacterBody3D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")

# Movement parameters
var speed: float = 5.0
var jump_force: float = 10.0
var gravity: float = 20.0

# Animation parameters
var is_moving: bool = false
var is_jumping: bool = false
var is_falling: bool = false

# Available states - WILL BE AUTO-GENERATED
var available_states = [
	#ANIMATION_STATES#
]

func _ready():
	if animation_tree:
		animation_tree.active = true
		# Start with idle animation if available
		if "idle" in available_states:
			state_machine.start("idle")
		elif available_states.size() > 0:
			state_machine.start(available_states[0])

func _physics_process(delta):
	# Handle movement and physics
	_handle_movement(delta)
	_handle_gravity(delta)
	_handle_jump()
	
	move_and_slide()
	_update_animations()

func _handle_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
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
		velocity.y = 0

func _handle_jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		is_jumping = true
	else:
		is_jumping = false

func _update_animations():
	if not state_machine:
		return
	
	# Update animation states based on character state
	if is_jumping and "jump" in available_states:
		state_machine.travel("jump")
	elif is_falling and "fall" in available_states:
		state_machine.travel("fall")
	elif is_moving:
		# Handle directional animations or default to walk/run
		if "blend_space" in available_states:
			state_machine.travel("blend_space")
		elif "walk" in available_states:
			state_machine.travel("walk")
		elif "run" in available_states:
			state_machine.travel("run")
	else:
		if "idle" in available_states:
			state_machine.travel("idle")

# Input actions setup reminder
func _input(event):
	# Remember to set up these input actions in Project Settings:
	# - move_left (A/Left Arrow)
	# - move_right (D/Right Arrow) 
	# - move_forward (W/Up Arrow)
	# - move_back (S/Down Arrow)
	# - jump (Space)
	pass
