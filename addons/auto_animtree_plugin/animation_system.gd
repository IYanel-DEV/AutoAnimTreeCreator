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
	
	# Set start node
	var start_node_name = "idle"
	if start_node_name in selected_anims:
		pass
	elif selected_anims.size() > 0:
		start_node_name = selected_anims.keys()[0]
	else:
		push_error("No animations selected for state machine")
		scene_instance.queue_free()
		return
	
	# Get state names for transitions
	var state_names = []
	for anim_type in selected_anims:
		state_names.append(anim_type)

	# Create transitions between all states
	for i in range(state_names.size()):
		for j in range(state_names.size()):
			if i != j:
				var transition = AnimationNodeStateMachineTransition.new()
				transition.xfade_time = 0.2
				state_machine.add_transition(state_names[i], state_names[j], transition)
	
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
	
	# Create player controller script
	_create_player_controller_script(selected_anims, anim_player.name, anim_tree.name, state_names)
	
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
	var blend_space = AnimationNodeBlendSpace2D.new()
	blend_space.blend_mode = AnimationNodeBlendSpace2D.BLEND_MODE_INTERPOLATED
	
	var points = {
		"walk_forward": Vector2(0, -1),
		"walk_backward": Vector2(0, 1),
		"walk_left": Vector2(-1, 0),
		"walk_right": Vector2(1, 0),
		"run_forward": Vector2(0, -2),
		"run_backward": Vector2(0, 2)
	}
	
	for anim_type in points:
		if anim_type in anims:
			var anim_node = AnimationNodeAnimation.new()
			anim_node.animation = anims[anim_type]
			blend_space.add_blend_point(anim_node, points[anim_type])
	
	state_machine.add_node("blend_space", blend_space)

func _create_player_controller_script(anims: Dictionary, anim_player_name: String, anim_tree_name: String, states: Array):
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("AnimTreeList"):
		dir.make_dir("AnimTreeList")
	
	var script_path = "res://AnimTreeList/PlayerController.gd"
	
	var template_path = "res://addons/auto_animtree_plugin/PlayerController-AnimTree.gd"
	var template_file = FileAccess.open(template_path, FileAccess.READ)
	
	if not template_file:
		push_error("Template file not found: " + template_path)
		return
	
	var template_content = template_file.get_as_text()
	template_file.close()
	
	var state_machine_code = ""
	for state in states:
		state_machine_code += '\t"%s",\n' % state
	
	var final_content = template_content.replace("#ANIMATION_STATES#", state_machine_code)
	
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	if file:
		file.store_string(final_content)
		file.close()
		print("Player controller script created from template: " + script_path)
	else:
		push_error("Failed to save player controller script")

func _find_nodes_by_type(node: Node, type: String, results: Array = []) -> Array:
	if node.get_class() == type:
		results.append(node)
	
	for child in node.get_children():
		_find_nodes_by_type(child, type, results)
	
	return results
