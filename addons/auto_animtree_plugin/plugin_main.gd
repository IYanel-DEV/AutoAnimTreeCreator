@tool
extends EditorPlugin

var dialog: Window
var create_button: Button
var scene_file_edit: OptionButton
var anim_player_edit: OptionButton
var anim_options: Dictionary = {}
var create_btn: Button
var auto_bind_btn: Button
var scroll_container: ScrollContainer

func _enter_tree():
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
	dialog.popup_centered(Vector2i(700, 900))

func _create_dialog():
	if dialog and is_instance_valid(dialog):
		dialog.queue_free()
		
	dialog = Window.new()
	dialog.title = "Auto AnimationTree Creator"
	dialog.size = Vector2i(700, 900)
	dialog.min_size = Vector2i(650, 800)
	dialog.close_requested.connect(_on_dialog_close)
	
	# Main container
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 10)
	dialog.add_child(main_vbox)
	
	# Title
	var title_label = Label.new()
	title_label.text = "Auto AnimationTree Creator"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	main_vbox.add_child(title_label)
	
	main_vbox.add_child(HSeparator.new())
	
	# Scene selection group
	var scene_group = VBoxContainer.new()
	scene_group.add_theme_constant_override("separation", 5)
	main_vbox.add_child(scene_group)
	
	var scene_title = Label.new()
	scene_title.text = "═══ Scene Selection ═══"
	scene_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene_title.add_theme_font_size_override("font_size", 14)
	scene_group.add_child(scene_title)
	
	var scene_hbox = HBoxContainer.new()
	scene_group.add_child(scene_hbox)
	
	var scene_label = Label.new()
	scene_label.text = "Player Scene:"
	scene_label.custom_minimum_size.x = 120
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
	scene_group.add_child(anim_player_hbox)
	
	var anim_player_label = Label.new()
	anim_player_label.text = "AnimationPlayer:"
	anim_player_label.custom_minimum_size.x = 120
	anim_player_hbox.add_child(anim_player_label)
	
	anim_player_edit = OptionButton.new()
	anim_player_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	anim_player_edit.disabled = true
	anim_player_edit.item_selected.connect(_on_anim_player_selected)
	anim_player_hbox.add_child(anim_player_edit)
	
	main_vbox.add_child(HSeparator.new())
	
	# Auto Bind Section
	var auto_bind_group = VBoxContainer.new()
	auto_bind_group.add_theme_constant_override("separation", 5)
	main_vbox.add_child(auto_bind_group)
	
	var auto_bind_title = Label.new()
	auto_bind_title.text = "═══ Input Actions ═══"
	auto_bind_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	auto_bind_title.add_theme_font_size_override("font_size", 14)
	auto_bind_group.add_child(auto_bind_title)
	
	auto_bind_btn = Button.new()
	auto_bind_btn.text = "Auto Generate Input Actions"
	auto_bind_btn.pressed.connect(_on_auto_bind_pressed)
	auto_bind_group.add_child(auto_bind_btn)
	
	var info_label = Label.new()
	info_label.text = "Creates: move_left, move_right, move_forward, move_back, jump, run, crouch, attack, block, dodge
	IMPORTANT: After generating the input action, please save everything and reload the project so the input will be applied."
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_size_override("font_size", 18)
	auto_bind_group.add_child(info_label)
	
	main_vbox.add_child(HSeparator.new())
	
	# Animation Selection Section
	var anim_title = Label.new()
	anim_title.text = "═══ Animation Selection ═══"
	anim_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_title.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(anim_title)
	
	# Scroll container for animations
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll_container)
	
	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(scroll_vbox)
	
	# Create animation categories
	_create_animation_categories(scroll_vbox)
	
	main_vbox.add_child(HSeparator.new())
	
	# Create button
	create_btn = Button.new()
	create_btn.text = "Create AnimationTree & Controller"
	create_btn.pressed.connect(_create_animation_system)
	create_btn.disabled = true
	create_btn.custom_minimum_size.y = 40
	main_vbox.add_child(create_btn)
	
	# Add to editor after everything is set up
	get_editor_interface().get_base_control().add_child(dialog)
	_refresh_scene_files()

func _create_animation_categories(parent: VBoxContainer):
	anim_options = {}
	
	var categories = {
		"Basic States": {
			"idle": "Idle Animation"
		},
		"Walking": {
			"walk_forward": "Walk Forward",
			"walk_backward": "Walk Backward", 
			"walk_left": "Walk Left",
			"walk_right": "Walk Right"
		},
		"Running": {
			"run_forward": "Run Forward",
			"run_backward": "Run Backward",
			"run_left": "Run Left",
			"run_right": "Run Right"
		},
		"Crouching": {
			"crouch_idle": "Crouch Idle",
			"crouch_forward": "Crouch Forward",
			"crouch_backward": "Crouch Backward",
			"crouch_left": "Crouch Left",
			"crouch_right": "Crouch Right"
		},
		"Aerial": {
			"jump": "Jump Animation",
			"fall": "Fall Animation",
			"land": "Land Animation"
		},
		"Combat": {
			"attack_1": "Attack 1",
			"attack_2": "Attack 2",
			"attack_3": "Attack 3",
			"block": "Block",
			"dodge": "Dodge"
		},
		"Special": {
			"climb": "Climb Animation",
			"swim": "Swim Animation",
			"slide": "Slide Animation"
		}
	}
	
	for category_name in categories:
		var category_data = categories[category_name]
		
		# Category container
		var category_container = VBoxContainer.new()
		category_container.add_theme_constant_override("separation", 5)
		parent.add_child(category_container)
		
		# Category header
		var category_header = HBoxContainer.new()
		category_container.add_child(category_header)
		
		var category_label = Label.new()
		category_label.text = "▼ " + category_name
		category_label.add_theme_font_size_override("font_size", 12)
		category_label.modulate = Color.CYAN
		category_header.add_child(category_label)
		
		var separator = HSeparator.new()
		separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		category_header.add_child(separator)
		
		# Animation grid for this category
		var anim_grid = GridContainer.new()
		anim_grid.columns = 2
		anim_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		anim_grid.add_theme_constant_override("h_separation", 10)
		anim_grid.add_theme_constant_override("v_separation", 5)
		category_container.add_child(anim_grid)
		
		# Add animations for this category
		for anim_name in category_data:
			var label = Label.new()
			label.text = category_data[anim_name] + ":"
			label.custom_minimum_size.x = 150
			anim_grid.add_child(label)
			
			var option = OptionButton.new()
			option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			option.add_item("None", 0)
			option.disabled = true
			anim_grid.add_child(option)
			anim_options[anim_name] = option
		
		# Add spacing between categories
		var spacer = Control.new()
		spacer.custom_minimum_size.y = 15
		parent.add_child(spacer)

func _on_dialog_close():
	if dialog:
		dialog.hide()

func _on_auto_bind_pressed():
	var animation_system = AnimationSystem.new()
	animation_system.editor_interface = get_editor_interface()
	animation_system.auto_bind_input_actions()

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
	animation_system.editor_interface = get_editor_interface()
	animation_system.create_animation_system(scene_path, anim_options, anim_player_path)
	
	if dialog:
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
