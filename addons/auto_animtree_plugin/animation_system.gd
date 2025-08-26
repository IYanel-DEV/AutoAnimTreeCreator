@tool
class_name AnimationSystem

func create_animation_system(scene_path: String, anim_options: Dictionary, selected_anim_player_path: String):
	var scene = load(scene_path)
	
	if not scene or not scene is PackedScene:
		push_error("Failed to load scene: " + scene_path)
		return
	
	var scene_instance = scene.instantiate()
	if not scene_instance:
		push_error("Failed to instantiate scene: " + scene_path)
		return
	
	# Get the AnimationPlayer using the provided path
	var anim_player = scene_instance.get_node(selected_anim_player_path)
	if not anim_player or not anim_player is AnimationPlayer:
		push_error("AnimationPlayer not found at path: " + selected_anim_player_path)
		scene_instance.queue_free()
		return
	
	var animation_names = anim_player.get_animation_list()
	
	# Get selected animations from the options
	var selected_anims = {}
	for anim_type in anim_options:
		var option = anim_options[anim_type]
		if option.selected > 0 and option.selected < option.get_item_count():
			selected_anims[anim_type] = option.get_item_text(option.selected)
	
	if selected_anims.is_empty():
		push_error("Please select at least one animation")
		scene_instance.queue_free()
		return
	
	# Create AnimationTree as sibling of AnimationPlayer
	var anim_tree = AnimationTree.new()
	anim_tree.name = "AnimationTree"
	
	# Add AnimationTree as sibling to AnimationPlayer
	var anim_player_parent = anim_player.get_parent()
	anim_player_parent.add_child(anim_tree)
	anim_tree.owner = scene_instance
	
	# Set the animation_player property correctly - use relative path from AnimationTree to AnimationPlayer
	var relative_path = anim_tree.get_path_to(anim_player)
	anim_tree.anim_player = relative_path
	anim_tree.active = true
	
	# Create state machine
	var state_machine = AnimationNodeStateMachine.new()
	anim_tree.tree_root = state_machine
	
	# Create states for selected animations
	for anim_type in selected_anims:
		var anim_name = selected_anims[anim_type]
		var state = AnimationNodeAnimation.new()
		state.animation = anim_name
		state_machine.add_node(anim_type, state)
	
	# Set start node - FIXED: Don't set start_node directly, let the state machine handle it
	# The start node is automatically set to the first node added, or we can use travel() later
	var start_node_name = "idle"
	if start_node_name in selected_anims:
		# Don't set start_node directly - it will be handled by the state machine
		pass
	elif selected_anims.size() > 0:
		start_node_name = selected_anims.keys()[0]
	else:
		push_error("No animations selected for state machine")
		scene_instance.queue_free()
		return
	
	# Add transitions between all states
	var states = state_machine.get_nodes()
	for i in range(states.size()):
		for j in range(states.size()):
			if i != j:
				var transition = AnimationNodeStateMachineTransition.new()
				transition.xfade_time = 0.2  # Set a default cross-fade time
				state_machine.add_transition(states[i], states[j], transition)
	
	# Create blend space for directional movement if needed
	if _has_directional_animations(selected_anims):
		_create_blend_space(state_machine, selected_anims)
	
	# Save the scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(scene_instance)
	var error = ResourceSaver.save(packed_scene, scene_path)
	
	if error != OK:
		push_error("Failed to save scene: " + str(error))
		scene_instance.queue_free()
		return
	
	# Create player controller script - UPDATED: Use proper state machine playback
	_create_player_controller_script(selected_anims, anim_player.name, anim_tree.name, states)
	
	print("Animation system created successfully!")
	print("AnimationTree path: " + str(anim_tree.get_path()))
	print("AnimationPlayer path: " + str(anim_player.get_path()))
	print("Start node: " + start_node_name)
	print("Animations: ", selected_anims)
	
	scene_instance.queue_free()	
	
	


func _has_directional_animations(anims: Dictionary) -> bool:
	var directional_anims = ["walk_forward", "walk_backward", "walk_left", "walk_right",
						   "run_forward", "run_backward"]
	for anim in directional_anims:
		if anim in anims:
			return true
	return false

func _create_blend_space(state_machine: AnimationNodeStateMachine, anims: Dictionary):
	# Create blend space for directional movement
	var blend_space = AnimationNodeBlendSpace2D.new()
	blend_space.blend_mode = AnimationNodeBlendSpace2D.BLEND_MODE_INTERPOLATED
	
	# Points for directional movement
	var points = {
		"walk_forward": Vector2(0, -1),
		"walk_backward": Vector2(0, 1),
		"walk_left": Vector2(-1, 0),
		"walk_right": Vector2(1, 0),
		"run_forward": Vector2(0, -2),
		"run_backward": Vector2(0, 2)
	}
	
	# Add blend points
	for anim_type in points:
		if anim_type in anims:
			# Create animation node for this point
			var anim_node = AnimationNodeAnimation.new()
			anim_node.animation = anims[anim_type]
			
			# Add the blend point directly using add_blend_point method
			blend_space.add_blend_point(anim_node, points[anim_type])
	
	state_machine.add_node("blend_space", blend_space)

func _create_player_controller_script(anims: Dictionary, anim_player_name: String, anim_tree_name: String, states: Array):
	# Create AnimTreeList directory if it doesn't exist
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("AnimTreeList"):
		dir.make_dir("AnimTreeList")
	
	var script_path = "res://AnimTreeList/PlayerController.gd"
	var script_content = _generate_controller_script(anims, anim_player_name, anim_tree_name, states)
	
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	if file:
		file.store_string(script_content)
		file.close()
		print("Player controller script created: " + script_path)
	else:
		push_error("Failed to save player controller script")

func _generate_controller_script(anims: Dictionary, anim_player_name: String, anim_tree_name: String, states: Array) -> String:
	var state_machine_code = ""
	for state in states:
		state_machine_code += '	"%s",\n' % state
	
	return """
extends CharacterBody3D

@onready var animation_tree: AnimationTree = $%s
@onready var state_machine = animation_tree.get("parameters/playback")

# Movement parameters
var speed: float = 5.0
var jump_force: float = 10.0
var gravity: float = 20.0

# Animation parameters
var is_moving: bool = false
var is_jumping: bool = false
var is_falling: bool = false

# Available states
var available_states = [
%s]

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
""" % [anim_tree_name, state_machine_code]


func _find_nodes_by_type(node: Node, type: String, results: Array = []) -> Array:
	if node.get_class() == type:
		results.append(node)
	
	for child in node.get_children():
		_find_nodes_by_type(child, type, results)
	
	return results
