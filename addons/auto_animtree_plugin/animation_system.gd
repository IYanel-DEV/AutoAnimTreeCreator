@tool
class_name AnimationSystem
##
## Core engine that builds the AnimationTree state machine, blend spaces,
## transitions, and generates the PlayerController script.
##
## Flow:
##  1. Load the target scene and locate the AnimationPlayer
##  2. Scan available animations from the AnimationPlayer
##  3. Create AnimationNodeStateMachine with organised state nodes
##  4. Add smart transitions between related animation groups
##  5. Set up aerial transitions (jump→fall→land) with proper advance modes
##  6. Create blend spaces (walk / run / crouch) when directional anims exist
##  7. Generate PlayerController.gd from the template by injecting state lists
##
## Usage (called from plugin_main.gd):
##  [codeblock]
##  var system = AnimationSystem.new()
##  system.editor_interface = get_editor_interface()
##  system.create_animation_system(scene_path, anim_options, anim_player_path)
##  [/codeblock]

var editor_interface: EditorInterface

func create_animation_system(scene_path: String, anim_options: Dictionary, selected_anim_player_path: String):
	## Entry point. Builds the entire animation system and saves the scene.
	## [param scene_path] — path to the .tscn to modify
	## [param anim_options] — dict of anim_type → OptionButton for selecting which anim clips to use
	## [param selected_anim_player_path] — node path to the AnimationPlayer in the scene
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
	
	# Get selected animations from the options (only non-empty ones)
	var selected_anims = {}
	for anim_type in anim_options:
		var option = anim_options[anim_type]
		if option.selected > 0 and option.selected < option.get_item_count():
			selected_anims[anim_type] = option.get_item_text(option.selected)
	
	if selected_anims.is_empty():
		push_error("Please select at least one animation")
		scene_instance.queue_free()
		return
	
	# Remove existing AnimationTree if present (prevents duplicates)
	var anim_player_parent = anim_player.get_parent()
	for child in anim_player_parent.get_children():
		if child is AnimationTree:
			anim_player_parent.remove_child(child)
			child.queue_free()
	
	# Create AnimationTree as sibling of AnimationPlayer
	var anim_tree = AnimationTree.new()
	anim_tree.name = "AnimationTree"
	
	# Add AnimationTree as sibling to AnimationPlayer
	anim_player_parent.add_child(anim_tree)
	anim_tree.owner = scene_instance
	
	# Set the animation_player property correctly - use relative path from AnimationTree to AnimationPlayer
	var relative_path = anim_tree.get_path_to(anim_player)
	anim_tree.anim_player = relative_path
	anim_tree.active = true
	
	# Create state machine
	var state_machine = AnimationNodeStateMachine.new()
	anim_tree.tree_root = state_machine
	
	# Create states for selected animations with organized positioning
	_create_organized_states(state_machine, selected_anims)
	
	# Set start node and connect it properly
	var start_node_name = _determine_start_node(selected_anims)
	
	# Set the start node by creating a transition from Start
	if start_node_name in selected_anims:
		var start_transition = AnimationNodeStateMachineTransition.new()
		start_transition.xfade_time = 0.0
		state_machine.add_transition("Start", start_node_name, start_transition)
	
	# Get state names for transitions
	var state_names = []
	for anim_type in selected_anims:
		state_names.append(anim_type)

	# Create smart transitions between related states
	_create_smart_transitions(state_machine, selected_anims, state_names)
	
	# Setup proper aerial transitions (jump->fall->land chain with correct advance modes)
	_setup_aerial_transitions(state_machine, selected_anims)
	
	# Create blend spaces for directional movement if needed
	_create_movement_blend_spaces(state_machine, selected_anims)
	
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
	
	# Force immediate editor refresh
	_force_editor_refresh(scene_path)

func _create_organized_states(state_machine: AnimationNodeStateMachine, selected_anims: Dictionary):
	## Place animation state nodes into the state machine, grouped by category
	## (basic, walking, running, crouching, aerial, combat, special) with visual
	## vertical spacing so the graph is readable in the AnimationTree editor.
	var categories = {
		"basic": ["idle"],
		"walking": ["walk_forward", "walk_backward", "walk_left", "walk_right"],
		"running": ["run_forward", "run_backward", "run_left", "run_right"],
		"crouching": ["crouch_idle", "crouch_forward", "crouch_backward", "crouch_left", "crouch_right"],
		"aerial": ["jump", "fall", "land"],
		"combat": ["attack_1", "attack_2", "attack_3", "block", "dodge"],
		"special": ["climb", "swim", "slide"]
	}
	
	var base_position = Vector2(100, 100)
	var category_offset = Vector2(0, 150)  # Vertical spacing between categories
	var anim_offset = Vector2(120, 0)     # Horizontal spacing between animations
	
	var current_category_position = base_position
	
	for category_name in categories:
		var animations_in_category = categories[category_name]
		var current_position = current_category_position
		
		var has_animations_in_category = false
		
		for anim_name in animations_in_category:
			if anim_name in selected_anims:
				var state = AnimationNodeAnimation.new()
				state.animation = selected_anims[anim_name]
				state_machine.add_node(anim_name, state, current_position)
				current_position += anim_offset
				has_animations_in_category = true
		
		# Only move to next category position if we had animations
		if has_animations_in_category:
			current_category_position += category_offset

func _determine_start_node(selected_anims: Dictionary) -> String:
	## Pick which animation node the state machine should start on.
	## Priority: idle → crouch_idle → walk_forward → run_forward → first available.
	var priority_nodes = ["idle", "crouch_idle", "walk_forward", "run_forward"]
	
	for node_name in priority_nodes:
		if node_name in selected_anims:
			return node_name
	
	# If no priority node, use first available
	if selected_anims.size() > 0:
		return selected_anims.keys()[0]
	
	return ""

func _create_smart_transitions(state_machine: AnimationNodeStateMachine, selected_anims: Dictionary, state_names: Array):
	## Wire up transitions between animations within the same group (e.g. all walk
	## directions cross-fade to each other, idle connects to crouch_idle, etc.).
	## Uses different crossfade durations: instant (0.0s), normal (0.2s), slow (0.5s).
	var transition_groups = [
		# Basic locomotion
		["idle", "walk_forward", "walk_backward", "walk_left", "walk_right"],
		["idle", "run_forward", "run_backward", "run_left", "run_right"],
		
		# Crouching
		["crouch_idle", "crouch_forward", "crouch_backward", "crouch_left", "crouch_right"],
		["idle", "crouch_idle"],  # Transition between standing and crouching
		
		# Aerial - handled entirely by _setup_aerial_transitions to prevent auto-advance conflicts
		
		# Combat
		["idle", "attack_1", "attack_2", "attack_3", "block", "dodge"],
		
		# Special
		["idle", "climb", "swim", "slide"]
	]
	
	# Create transitions based on groups
	for group in transition_groups:
		var valid_states_in_group = []
		for state_name in group:
			if state_name in selected_anims:
				valid_states_in_group.append(state_name)
		
		# Create transitions between all valid states in this group
		for i in range(valid_states_in_group.size()):
			for j in range(valid_states_in_group.size()):
				if i != j:
					var from_state = valid_states_in_group[i]
					var to_state = valid_states_in_group[j]
					
					# Check if transition already exists
					if not state_machine.has_transition(from_state, to_state):
						var transition = AnimationNodeStateMachineTransition.new()
						
						# Set different transition times based on animation types
						if _is_instant_transition(from_state, to_state):
							transition.xfade_time = 0.0
						elif _is_slow_transition(from_state, to_state):
							transition.xfade_time = 0.5
						else:
							transition.xfade_time = 0.2
						
						state_machine.add_transition(from_state, to_state, transition)

func _is_instant_transition(from_state: String, to_state: String) -> bool:
	## Returns true if the pair should crossfade instantly (0.0s).
	## Used for idle/walk/run → jump so the jump kicks in without delay.
	var instant_pairs = [
		["idle", "jump"],
		["walk_forward", "jump"],
		["run_forward", "jump"]
	]
	
	for pair in instant_pairs:
		if (pair[0] == from_state and pair[1] == to_state) or (pair[1] == from_state and pair[0] == to_state):
			return true
	
	return false

func _is_slow_transition(from_state: String, to_state: String) -> bool:
	## Returns true if the pair should use a longer crossfade (0.5s).
	## Used for posture changes like idle ↔ crouch_idle.
	var slow_pairs = [
		["idle", "crouch_idle"],
		["crouch_idle", "idle"]
	]
	
	for pair in slow_pairs:
		if (pair[0] == from_state and pair[1] == to_state) or (pair[1] == from_state and pair[0] == to_state):
			return true
	
	return false

func _setup_aerial_transitions(state_machine: AnimationNodeStateMachine, selected_anims: Dictionary):
	## Configure jump/fall/land transitions with correct advance modes so the
	## controller script can control the timing (jump protection timer, landing
	## detection) instead of relying on auto-advance.
	##
	## - jump → fall: manual (triggered when jump_protection expires)
	## - fall → land: manual (triggered by ground contact)
	## - land → idle: auto (waits for land animation to finish)
	
	# IDLE -> JUMP etc: Instant transition for initiating jump
	if "jump" in selected_anims:
		for from_state in ["idle", "walk_forward", "run_forward"]:
			if from_state in selected_anims and not state_machine.has_transition(from_state, "jump"):
				var to_jump = AnimationNodeStateMachineTransition.new()
				to_jump.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
				to_jump.auto_advance_time = 0.0
				to_jump.xfade_time = 0.0
				state_machine.add_transition(from_state, "jump", to_jump)
	
	# JUMP -> FALL: manual - controller handles timing via jump_protection_timer
	if "jump" in selected_anims and "fall" in selected_anims:
		var jump_to_fall = AnimationNodeStateMachineTransition.new()
		jump_to_fall.advance_mode = 1  # ADVANCE_MODE_ENABLED (manual)
		jump_to_fall.xfade_time = 0.05
		state_machine.add_transition("jump", "fall", jump_to_fall)
	
	# FALL -> LAND: Manual control (triggered by ground detection)
	if "fall" in selected_anims and "land" in selected_anims:
		var fall_to_land = AnimationNodeStateMachineTransition.new()
		fall_to_land.advance_mode = 1  # ADVANCE_MODE_MANUAL
		fall_to_land.xfade_time = 0.05
		state_machine.add_transition("fall", "land", fall_to_land)
	
	# LAND -> IDLE: Wait for land animation to finish
	if "land" in selected_anims:
		var land_to_idle = AnimationNodeStateMachineTransition.new()
		land_to_idle.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
		land_to_idle.auto_advance_time = 0.0
		land_to_idle.xfade_time = 0.1
		
		if "idle" in selected_anims:
			state_machine.add_transition("land", "idle", land_to_idle)
		elif "crouch_idle" in selected_anims:
			state_machine.add_transition("land", "crouch_idle", land_to_idle)

func _create_movement_blend_spaces(state_machine: AnimationNodeStateMachine, selected_anims: Dictionary):
	## Create AnimationNodeBlendSpace2D nodes for walk, run, and crouch when
	## directional animations are available. Each blend space maps a Vector2
	## input (from the controller script) to the appropriate directional clip.
	##
	## Point mapping:
	##   forward = (0, -1), backward = (0, 1)
	##   left    = (-1, 0), right   = (1, 0)
	var walk_anims = ["walk_forward", "walk_backward", "walk_left", "walk_right"]
	var has_walk_anims = false
	for anim in walk_anims:
		if anim in selected_anims:
			has_walk_anims = true
			break
	
	if has_walk_anims:
		_create_walk_blend_space(state_machine, selected_anims)
	
	# Create blend space for running if we have directional run animations
	var run_anims = ["run_forward", "run_backward", "run_left", "run_right"]
	var has_run_anims = false
	for anim in run_anims:
		if anim in selected_anims:
			has_run_anims = true
			break
	
	if has_run_anims:
		_create_run_blend_space(state_machine, selected_anims)
	
	# Create blend space for crouching if we have directional crouch animations
	var crouch_anims = ["crouch_forward", "crouch_backward", "crouch_left", "crouch_right"]
	var has_crouch_anims = false
	for anim in crouch_anims:
		if anim in selected_anims:
			has_crouch_anims = true
			break
	
	if has_crouch_anims:
		_create_crouch_blend_space(state_machine, selected_anims)

func _create_walk_blend_space(state_machine: AnimationNodeStateMachine, selected_anims: Dictionary):
	## Build the walk blend space and connect it to idle.
	var blend_space = AnimationNodeBlendSpace2D.new()
	blend_space.blend_mode = AnimationNodeBlendSpace2D.BLEND_MODE_INTERPOLATED
	
	var points = {
		"walk_forward": Vector2(0, -1),
		"walk_backward": Vector2(0, 1),
		"walk_left": Vector2(-1, 0),
		"walk_right": Vector2(1, 0)
	}
	
	for anim_type in points:
		if anim_type in selected_anims:
			var anim_node = AnimationNodeAnimation.new()
			anim_node.animation = selected_anims[anim_type]
			blend_space.add_blend_point(anim_node, points[anim_type])
	
	# Position the blend space node
	state_machine.add_node("walk_blend_space", blend_space, Vector2(400, 100))
	
	# Create transitions to/from blend space
	if "idle" in selected_anims:
		var to_walk = AnimationNodeStateMachineTransition.new()
		to_walk.xfade_time = 0.2
		state_machine.add_transition("idle", "walk_blend_space", to_walk)
		
		var from_walk = AnimationNodeStateMachineTransition.new()
		from_walk.xfade_time = 0.2
		state_machine.add_transition("walk_blend_space", "idle", from_walk)

func _create_run_blend_space(state_machine: AnimationNodeStateMachine, selected_anims: Dictionary):
	## Build the run blend space and connect it to idle.
	var blend_space = AnimationNodeBlendSpace2D.new()
	blend_space.blend_mode = AnimationNodeBlendSpace2D.BLEND_MODE_INTERPOLATED
	
	var points = {
		"run_forward": Vector2(0, -1),
		"run_backward": Vector2(0, 1),
		"run_left": Vector2(-1, 0),
		"run_right": Vector2(1, 0)
	}
	
	for anim_type in points:
		if anim_type in selected_anims:
			var anim_node = AnimationNodeAnimation.new()
			anim_node.animation = selected_anims[anim_type]
			blend_space.add_blend_point(anim_node, points[anim_type])
	
	# Position the blend space node
	state_machine.add_node("run_blend_space", blend_space, Vector2(400, 250))
	
	# Create transitions to/from blend space
	if "idle" in selected_anims:
		var to_run = AnimationNodeStateMachineTransition.new()
		to_run.xfade_time = 0.1
		state_machine.add_transition("idle", "run_blend_space", to_run)
		
		var from_run = AnimationNodeStateMachineTransition.new()
		from_run.xfade_time = 0.2
		state_machine.add_transition("run_blend_space", "idle", from_run)

func _create_crouch_blend_space(state_machine: AnimationNodeStateMachine, selected_anims: Dictionary):
	## Build the crouch blend space and connect it to crouch_idle.
	var blend_space = AnimationNodeBlendSpace2D.new()
	blend_space.blend_mode = AnimationNodeBlendSpace2D.BLEND_MODE_INTERPOLATED
	
	var points = {
		"crouch_forward": Vector2(0, -1),
		"crouch_backward": Vector2(0, 1),
		"crouch_left": Vector2(-1, 0),
		"crouch_right": Vector2(1, 0)
	}
	
	for anim_type in points:
		if anim_type in selected_anims:
			var anim_node = AnimationNodeAnimation.new()
			anim_node.animation = selected_anims[anim_type]
			blend_space.add_blend_point(anim_node, points[anim_type])
	
	# Position the blend space node
	state_machine.add_node("crouch_blend_space", blend_space, Vector2(400, 400))
	
	# Create transitions to/from blend space
	if "crouch_idle" in selected_anims:
		var to_crouch_move = AnimationNodeStateMachineTransition.new()
		to_crouch_move.xfade_time = 0.2
		state_machine.add_transition("crouch_idle", "crouch_blend_space", to_crouch_move)
		
		var from_crouch_move = AnimationNodeStateMachineTransition.new()
		from_crouch_move.xfade_time = 0.2
		state_machine.add_transition("crouch_blend_space", "crouch_idle", from_crouch_move)

func auto_bind_input_actions():
	## Register default input actions (move_left, move_right, etc.) in the
	## Project Settings Input Map so they appear immediately and can be
	## remapped by the user. Does not overwrite existing actions.
	var actions_to_create = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT], 
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE],
		"run": [KEY_SHIFT],
		"crouch": [KEY_C],
		"attack": [KEY_E],
		"block": [KEY_Q],
		"dodge": [KEY_X]
	}
	
	var created_actions = []
	
	for action_name in actions_to_create:
		# Check if action already exists in project settings
		var input_path = "input/" + action_name
		if ProjectSettings.has_setting(input_path):
			print("Action already exists: ", action_name)
			continue
		
		# Create input events for this action
		var events = []
		for key in actions_to_create[action_name]:
			var event = InputEventKey.new()
			event.keycode = key
			events.append(event)
		
		# Create the action data structure
		var action_data = {
			"deadzone": 0.5,
			"events": events
		}
		
		# Save to project settings
		ProjectSettings.set_setting(input_path, action_data)
		created_actions.append(action_name)
	
	# Save project settings to persist changes
	ProjectSettings.save()
	
	if created_actions.size() > 0:
		print("Created input actions: ", created_actions)
		print("You may need to restart the Project to see them in the Input Map tab")
	else:
		print("No new actions were created")
	
	# Refresh the filesystem
	if editor_interface:
		editor_interface.get_resource_filesystem().scan()

func _create_player_controller_script(anims: Dictionary, anim_player_name: String, anim_tree_name: String, states: Array):
	## Generate PlayerController.gd from the template by injecting the list of
	## available animation state names. The template placeholder #ANIMATION_STATES#
	## is replaced with the actual state list including blend spaces.
	var template_path = "res://addons/auto_animtree_plugin/PlayerController-AnimTree.gd"
	var script_path = "res://AnimTreeList/PlayerController.gd"
	
	# Read the template script
	var template_file = FileAccess.open(template_path, FileAccess.READ)
	if not template_file:
		push_error("Failed to open template script: " + template_path)
		return
	
	var template_content = template_file.get_as_text()
	template_file.close()
	
	# Generate the state list for replacement
	var state_list = ""
	for state in states:
		state_list += '\t"%s",\n' % state
	
	# Add blend spaces to states if they were created
	if _has_directional_animations(anims, ["walk_forward", "walk_backward", "walk_left", "walk_right"]):
		state_list += '\t"walk_blend_space",\n'
	if _has_directional_animations(anims, ["run_forward", "run_backward", "run_left", "run_right"]):
		state_list += '\t"run_blend_space",\n'
	if _has_directional_animations(anims, ["crouch_forward", "crouch_backward", "crouch_left", "crouch_right"]):
		state_list += '\t"crouch_blend_space",\n'
	
	# Replace the placeholder with actual states
	var final_content = template_content.replace("#ANIMATION_STATES#", state_list)
	
	# Ensure the AnimTreeList directory exists
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("AnimTreeList"):
		dir.make_dir("AnimTreeList")
		print("Created AnimTreeList directory")
	
	# Write the updated content to the destination file
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	if file:
		file.store_string(final_content)
		file.close()
		print("Player controller script created/updated: " + script_path)
		
		# Force immediate filesystem refresh to make the file visible
		_force_filesystem_refresh()
	else:
		push_error("Failed to create/update player controller script: " + script_path)

func _has_directional_animations(anims: Dictionary, directions: Array) -> bool:
	## Check if at least one of the named animations exists in the selection.
	for anim in directions:
		if anim in anims:
			return true
	return false

func _force_filesystem_refresh():
	## Refresh the editor filesystem so newly created/updated files appear
	## in the FileSystem dock immediately.
	if editor_interface:
		# Refresh the filesystem to make new files visible
		var filesystem = editor_interface.get_resource_filesystem()
		filesystem.scan()
		
		# Additional refresh to ensure everything updates
		filesystem.scan_sources()
		print("Filesystem refreshed - new files should be visible!")

func _force_editor_refresh(scene_path: String):
	## Force the editor to reload the scene if it's currently open and
	## refresh the filesystem to show changes.
	if not editor_interface:
		return
	
	# Refresh filesystem
	var filesystem = editor_interface.get_resource_filesystem()
	filesystem.scan()
	
	# If the scene is currently open, reload it
	var current_scene = editor_interface.get_edited_scene_root()
	if current_scene and current_scene.scene_file_path == scene_path:
		editor_interface.reload_scene_from_path(scene_path)
	
	# Force filesystem update
	call_deferred("_deferred_filesystem_refresh")

func _deferred_filesystem_refresh():
	## One‑frame deferred filesystem scan to catch any pending changes.
	if editor_interface:
		editor_interface.get_resource_filesystem().scan_sources()
		print("Editor refreshed - changes should be visible now!")

func _find_nodes_by_type(node: Node, type: String, results: Array = []) -> Array:
	if node.get_class() == type:
		results.append(node)
	
	for child in node.get_children():
		_find_nodes_by_type(child, type, results)
	
	return results
