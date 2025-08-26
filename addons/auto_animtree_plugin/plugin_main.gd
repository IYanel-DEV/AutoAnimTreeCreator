@tool
extends EditorPlugin

var dialog: Window
var create_button: Button
var scene_file_edit: OptionButton
var anim_player_edit: OptionButton
var anim_options: Dictionary = {}
var create_btn: Button

func _enter_tree():
	# Create toolbar button
	create_button = Button.new()
	create_button.text = "Auto AnimTree"
	create_button.pressed.connect(_on_create_button_pressed)
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, create_button)
	
	print("Auto AnimationTree Creator Plugin loaded!")

func _exit_tree():
	if create_button:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, create_button)
		create_button.queue_free()
	
	if dialog and is_instance_valid(dialog):
		dialog.queue_free()
	
	print("Auto AnimationTree Creator Plugin unloaded!")

func _on_create_button_pressed():
	_create_dialog()
	dialog.popup_centered(Vector2i(600, 800))

func _create_dialog():
	dialog = Window.new()
	dialog.title = "Auto AnimationTree Creator"
	dialog.size = Vector2i(600, 800)
	dialog.min_size = Vector2i(550, 700)
	dialog.close_requested.connect(_on_dialog_close)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog.add_child(vbox)
	
	# Scene selection
	var scene_hbox = HBoxContainer.new()
	vbox.add_child(scene_hbox)
	
	var scene_label = Label.new()
	scene_label.text = "Player Scene:"
	scene_hbox.add_child(scene_label)
	
	scene_file_edit = OptionButton.new()
	scene_file_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_file_edit.item_selected.connect(_on_scene_selected)
	scene_hbox.add_child(scene_file_edit)
	
	var scene_refresh_btn = Button.new()
	scene_refresh_btn.text = "Refresh"
	scene_refresh_btn.pressed.connect(_refresh_scene_files)
	scene_hbox.add_child(scene_refresh_btn)
	
	# AnimationPlayer selection
	var anim_player_hbox = HBoxContainer.new()
	vbox.add_child(anim_player_hbox)
	
	var anim_player_label = Label.new()
	anim_player_label.text = "AnimationPlayer:"
	anim_player_hbox.add_child(anim_player_label)
	
	anim_player_edit = OptionButton.new()
	anim_player_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	anim_player_edit.disabled = true
	anim_player_edit.item_selected.connect(_on_anim_player_selected)
	anim_player_hbox.add_child(anim_player_edit)
	
	# Animation selection grid
	var anim_grid = GridContainer.new()
	anim_grid.columns = 2
	anim_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(anim_grid)
	
	var animations = {
		"idle": "Idle Animation",
		"walk_forward": "Walk Forward",
		"walk_backward": "Walk Backward", 
		"walk_left": "Walk Left",
		"walk_right": "Walk Right",
		"run_forward": "Run Forward",
		"run_backward": "Run Backward",
		"jump": "Jump Animation",
		"fall": "Fall Animation"
	}
	
	anim_options = {}
	
	for anim_name in animations:
		var label = Label.new()
		label.text = animations[anim_name] + ":"
		anim_grid.add_child(label)
		
		var option = OptionButton.new()
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.add_item("None", 0)
		option.disabled = true
		anim_grid.add_child(option)
		anim_options[anim_name] = option
	
	# Separator
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
	# Create button
	create_btn = Button.new()
	create_btn.text = "Create AnimationTree & Controller"
	create_btn.pressed.connect(_create_animation_system)
	create_btn.disabled = true
	vbox.add_child(create_btn)
	
	get_editor_interface().get_base_control().add_child(dialog)
	_refresh_scene_files()

func _on_dialog_close():
	dialog.hide()

func _refresh_scene_files():
	scene_file_edit.clear()
	scene_file_edit.add_item("Select Player Scene", 0)
	
	var scene_files = _find_scene_files("res://")
	for i in range(scene_files.size()):
		var scene_path = scene_files[i]
		var scene_name = scene_path.get_file().get_basename()
		scene_file_edit.add_item(scene_name, i+1)
		scene_file_edit.set_item_metadata(i+1, scene_path)

func _on_scene_selected(index):
	if index == 0:
		anim_player_edit.disabled = true
		anim_player_edit.clear()
		anim_player_edit.add_item("Select AnimationPlayer", 0)
		_disable_animation_options()
		return
	
	var scene_path = scene_file_edit.get_item_metadata(index)
	_populate_animation_player_options(scene_path)

func _populate_animation_player_options(scene_path: String):
	var scene = load(scene_path)
	
	if not scene or not scene is PackedScene:
		push_error("Failed to load scene: " + scene_path)
		return
	
	var scene_instance = scene.instantiate()
	if not scene_instance:
		push_error("Failed to instantiate scene: " + scene_path)
		return
	
	# Find AnimationPlayers
	var anim_players = _find_nodes_by_type(scene_instance, "AnimationPlayer")
	
	anim_player_edit.clear()
	anim_player_edit.disabled = false
	anim_player_edit.add_item("Select AnimationPlayer", 0)
	
	if anim_players.size() == 0:
		push_error("No AnimationPlayer found in scene")
		anim_player_edit.disabled = true
	else:
		for i in range(anim_players.size()):
			var anim_player = anim_players[i]
			var path = scene_instance.get_path_to(anim_player)
			anim_player_edit.add_item(anim_player.name + " (" + str(path) + ")", i+1)
			anim_player_edit.set_item_metadata(i+1, str(path))
	
	scene_instance.queue_free()

func _on_anim_player_selected(index):
	if index == 0:
		_disable_animation_options()
		return
	
	var scene_index = scene_file_edit.selected
	if scene_index == 0:
		return
	
	var scene_path = scene_file_edit.get_item_metadata(scene_index)
	var anim_player_path = anim_player_edit.get_item_metadata(index)
	_populate_animation_options(scene_path, anim_player_path)

func _populate_animation_options(scene_path: String, anim_player_path: String):
	var scene = load(scene_path)
	
	if not scene or not scene is PackedScene:
		push_error("Failed to load scene: " + scene_path)
		return
	
	var scene_instance = scene.instantiate()
	if not scene_instance:
		push_error("Failed to instantiate scene: " + scene_path)
		return
	
	var anim_player = scene_instance.get_node(anim_player_path)
	if not anim_player or not anim_player is AnimationPlayer:
		push_error("AnimationPlayer not found at path: " + anim_player_path)
		scene_instance.queue_free()
		return
	
	var animation_names = anim_player.get_animation_list()
	
	# Enable and populate animation options
	for option in anim_options.values():
		option.disabled = false
		option.clear()
		option.add_item("None", 0)
		
		for anim_name in animation_names:
			option.add_item(anim_name)
	
	# Enable create button
	create_btn.disabled = false
	
	scene_instance.queue_free()

func _disable_animation_options():
	for option in anim_options.values():
		option.disabled = true
		option.clear()
		option.add_item("None", 0)
	
	create_btn.disabled = true

func _create_animation_system():
	var scene_index = scene_file_edit.selected
	if scene_index == 0:
		push_error("Please select a player scene")
		return
	
	var anim_player_index = anim_player_edit.selected
	if anim_player_index == 0:
		push_error("Please select an AnimationPlayer")
		return
	
	var scene_path = scene_file_edit.get_item_metadata(scene_index)
	var anim_player_path = anim_player_edit.get_item_metadata(anim_player_index)
	
	# Use AnimationSystem class to handle the creation
	var animation_system = AnimationSystem.new()
	animation_system.create_animation_system(scene_path, anim_options, anim_player_path)
	
	dialog.hide()

func _find_scene_files(path: String, files: Array = []) -> Array:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "." and file_name != ".." and file_name != "addons":
					_find_scene_files(path.path_join(file_name), files)
			else:
				if file_name.ends_with(".tscn"):
					files.append(path.path_join(file_name))
			file_name = dir.get_next()
	return files

func _find_nodes_by_type(node: Node, type: String, results: Array = []) -> Array:
	if node.get_class() == type:
		results.append(node)
	
	for child in node.get_children():
		_find_nodes_by_type(child, type, results)
	
	return results
