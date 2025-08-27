@tool
extends EditorPlugin

var dialog: AcceptDialog
var main_panel: Panel  # Add reference to main panel for animations
var create_button: Button
var scene_file_edit: OptionButton
var anim_player_edit: OptionButton
var anim_options: Dictionary = {}
var create_btn: Button
var auto_bind_btn: Button
var scroll_container: ScrollContainer
var theme_resource: Theme
var animation_tween: Tween

func _enter_tree():
	# Create dark theme first
	_create_dark_theme()
	
	create_button = Button.new()
	create_button.text = "🎭 Auto AnimTree"
	create_button.pressed.connect(_on_create_button_pressed)
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, create_button)
	
	print("Auto AnimationTree Creator Plugin loaded!")

func _exit_tree():
	if create_button:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, create_button)
		create_button.queue_free()
	
	if dialog and is_instance_valid(dialog):
		dialog.queue_free()
	
	if animation_tween:
		animation_tween.kill()  # Fixed: use kill() instead of queue_free()
	
	print("Auto AnimationTree Creator Plugin unloaded!")

func _create_dark_theme():
	theme_resource = Theme.new()
	
	# Base colors - Modern dark theme
	var bg_dark = Color(0.13, 0.13, 0.15, 1.0)      # #212226
	var bg_medium = Color(0.17, 0.17, 0.20, 1.0)    # #2B2B33
	var bg_light = Color(0.21, 0.21, 0.25, 1.0)     # #353540
	var accent_blue = Color(0.26, 0.59, 0.98, 1.0)  # #4296F5
	var accent_purple = Color(0.61, 0.35, 0.71, 1.0) # #9C59B5
	var text_primary = Color(0.95, 0.95, 0.97, 1.0) # #F2F2F7
	var text_secondary = Color(0.7, 0.7, 0.75, 1.0) # #B2B2BF
	
	# Panel theme
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = bg_dark
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.3, 0.3, 0.35, 0.8)
	theme_resource.set_stylebox("panel", "Panel", panel_style)
	
	# Button themes
	var button_normal = StyleBoxFlat.new()
	button_normal.bg_color = bg_medium
	button_normal.corner_radius_top_left = 8
	button_normal.corner_radius_top_right = 8
	button_normal.corner_radius_bottom_left = 8
	button_normal.corner_radius_bottom_right = 8
	button_normal.border_width_left = 1
	button_normal.border_width_right = 1
	button_normal.border_width_top = 1
	button_normal.border_width_bottom = 1
	button_normal.border_color = Color(0.4, 0.4, 0.45, 0.6)
	button_normal.content_margin_left = 16
	button_normal.content_margin_right = 16
	button_normal.content_margin_top = 8
	button_normal.content_margin_bottom = 8
	
	var button_hover = StyleBoxFlat.new()
	button_hover.bg_color = bg_light
	button_hover.corner_radius_top_left = 8
	button_hover.corner_radius_top_right = 8
	button_hover.corner_radius_bottom_left = 8
	button_hover.corner_radius_bottom_right = 8
	button_hover.border_width_left = 1
	button_hover.border_width_right = 1
	button_hover.border_width_top = 1
	button_hover.border_width_bottom = 1
	button_hover.border_color = accent_blue
	button_hover.content_margin_left = 16
	button_hover.content_margin_right = 16
	button_hover.content_margin_top = 8
	button_hover.content_margin_bottom = 8
	
	var button_pressed = StyleBoxFlat.new()
	button_pressed.bg_color = accent_blue
	button_pressed.corner_radius_top_left = 8
	button_pressed.corner_radius_top_right = 8
	button_pressed.corner_radius_bottom_left = 8
	button_pressed.corner_radius_bottom_right = 8
	button_pressed.content_margin_left = 16
	button_pressed.content_margin_right = 16
	button_pressed.content_margin_top = 8
	button_pressed.content_margin_bottom = 8
	
	theme_resource.set_stylebox("normal", "Button", button_normal)
	theme_resource.set_stylebox("hover", "Button", button_hover)
	theme_resource.set_stylebox("pressed", "Button", button_pressed)
	theme_resource.set_color("font_color", "Button", text_primary)
	theme_resource.set_color("font_hover_color", "Button", Color.WHITE)
	theme_resource.set_color("font_pressed_color", "Button", Color.WHITE)
	
	# OptionButton theme
	var option_normal = StyleBoxFlat.new()
	option_normal.bg_color = bg_medium
	option_normal.corner_radius_top_left = 6
	option_normal.corner_radius_top_right = 6
	option_normal.corner_radius_bottom_left = 6
	option_normal.corner_radius_bottom_right = 6
	option_normal.border_width_left = 1
	option_normal.border_width_right = 1
	option_normal.border_width_top = 1
	option_normal.border_width_bottom = 1
	option_normal.border_color = Color(0.4, 0.4, 0.45, 0.4)
	option_normal.content_margin_left = 12
	option_normal.content_margin_right = 32
	option_normal.content_margin_top = 6
	option_normal.content_margin_bottom = 6
	
	var option_hover = StyleBoxFlat.new()
	option_hover.bg_color = bg_light
	option_hover.corner_radius_top_left = 6
	option_hover.corner_radius_top_right = 6
	option_hover.corner_radius_bottom_left = 6
	option_hover.corner_radius_bottom_right = 6
	option_hover.border_width_left = 1
	option_hover.border_width_right = 1
	option_hover.border_width_top = 1
	option_hover.border_width_bottom = 1
	option_hover.border_color = accent_purple
	option_hover.content_margin_left = 12
	option_hover.content_margin_right = 32
	option_hover.content_margin_top = 6
	option_hover.content_margin_bottom = 6
	
	theme_resource.set_stylebox("normal", "OptionButton", option_normal)
	theme_resource.set_stylebox("hover", "OptionButton", option_hover)
	theme_resource.set_stylebox("pressed", "OptionButton", option_hover)
	theme_resource.set_color("font_color", "OptionButton", text_primary)
	theme_resource.set_color("font_hover_color", "OptionButton", Color.WHITE)
	
	# Label theme
	theme_resource.set_color("font_color", "Label", text_primary)
	theme_resource.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))
	
	# ScrollContainer theme
	var scroll_bg = StyleBoxFlat.new()
	scroll_bg.bg_color = Color(bg_dark.r, bg_dark.g, bg_dark.b, 0.3)
	scroll_bg.corner_radius_top_left = 8
	scroll_bg.corner_radius_top_right = 8
	scroll_bg.corner_radius_bottom_left = 8
	scroll_bg.corner_radius_bottom_right = 8
	theme_resource.set_stylebox("bg", "ScrollContainer", scroll_bg)
	
	# VScrollBar theme
	var scrollbar_style = StyleBoxFlat.new()
	scrollbar_style.bg_color = Color(0.4, 0.4, 0.45, 0.3)
	scrollbar_style.corner_radius_top_left = 4
	scrollbar_style.corner_radius_top_right = 4
	scrollbar_style.corner_radius_bottom_left = 4
	scrollbar_style.corner_radius_bottom_right = 4
	
	var scrollbar_grabber = StyleBoxFlat.new()
	scrollbar_grabber.bg_color = accent_blue
	scrollbar_grabber.corner_radius_top_left = 4
	scrollbar_grabber.corner_radius_top_right = 4
	scrollbar_grabber.corner_radius_bottom_left = 4
	scrollbar_grabber.corner_radius_bottom_right = 4
	
	theme_resource.set_stylebox("scroll", "VScrollBar", scrollbar_style)
	theme_resource.set_stylebox("grabber", "VScrollBar", scrollbar_grabber)
	theme_resource.set_stylebox("grabber_highlight", "VScrollBar", scrollbar_grabber)
	theme_resource.set_stylebox("grabber_pressed", "VScrollBar", scrollbar_grabber)

func _on_create_button_pressed():
	_create_dialog()
	# Animate dialog popup using the main panel instead of the dialog
	main_panel.modulate.a = 0.0
	main_panel.scale = Vector2(0.8, 0.8)
	dialog.popup_centered(Vector2i(750, 950))
	
	# Create smooth entrance animation
	if animation_tween:
		animation_tween.kill()
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	animation_tween.tween_property(main_panel, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	animation_tween.tween_property(main_panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _create_dialog():
	if dialog and is_instance_valid(dialog):
		dialog.queue_free()
	
	# Use AcceptDialog instead of Window to get Godot's default window bar
	dialog = AcceptDialog.new()
	dialog.title = "🎭 Auto AnimationTree Creator"
	dialog.size = Vector2i(800, 1000)  # Increased size
	dialog.min_size = Vector2i(750, 900)
	dialog.theme = theme_resource
	dialog.close_requested.connect(_on_dialog_close)
	dialog.confirmed.connect(_on_dialog_close)
	
	# Main container with custom panel - store reference for animations
	main_panel = Panel.new()
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_panel.theme = theme_resource
	dialog.add_child(main_panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 15)
	main_panel.add_child(main_vbox)
	
	# Add padding to main container
	main_vbox.add_theme_constant_override("margin_left", 20)
	main_vbox.add_theme_constant_override("margin_right", 20)
	main_vbox.add_theme_constant_override("margin_top", 20)
	main_vbox.add_theme_constant_override("margin_bottom", 20)
	
	# Header with animated title
	var header_container = VBoxContainer.new()
	header_container.add_theme_constant_override("separation", 10)
	main_vbox.add_child(header_container)
	
	var title_label = Label.new()
	title_label.text = "✨ AnimationTree Creator Studio"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.26, 0.59, 0.98, 1.0))
	header_container.add_child(title_label)
	
	var subtitle_label = Label.new()
	subtitle_label.text = "Create sophisticated animation systems with ease"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 12)
	subtitle_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	header_container.add_child(subtitle_label)
	
	# Animated separator
	var separator1 = _create_animated_separator()
	main_vbox.add_child(separator1)
	
	# Scene selection with animated header
	var scene_group = _create_animated_section("🎬 Scene Selection", main_vbox)
	
	var scene_content = VBoxContainer.new()
	scene_content.add_theme_constant_override("separation", 10)
	scene_group.add_child(scene_content)
	
	var scene_hbox = HBoxContainer.new()
	scene_hbox.add_theme_constant_override("separation", 10)
	scene_content.add_child(scene_hbox)
	
	var scene_label = Label.new()
	scene_label.text = "Player Scene:"
	scene_label.custom_minimum_size.x = 120
	scene_label.add_theme_font_size_override("font_size", 12)
	scene_hbox.add_child(scene_label)
	
	scene_file_edit = OptionButton.new()
	scene_file_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_file_edit.theme = theme_resource
	scene_file_edit.item_selected.connect(_on_scene_selected)
	scene_hbox.add_child(scene_file_edit)
	
	var scene_refresh_btn = Button.new()
	scene_refresh_btn.text = "🔄 Refresh"
	scene_refresh_btn.theme = theme_resource
	scene_refresh_btn.pressed.connect(_refresh_scene_files)
	scene_hbox.add_child(scene_refresh_btn)
	
	# AnimationPlayer selection
	var anim_player_hbox = HBoxContainer.new()
	anim_player_hbox.add_theme_constant_override("separation", 10)
	scene_content.add_child(anim_player_hbox)
	
	var anim_player_label = Label.new()
	anim_player_label.text = "AnimationPlayer:"
	anim_player_label.custom_minimum_size.x = 120
	anim_player_label.add_theme_font_size_override("font_size", 12)
	anim_player_hbox.add_child(anim_player_label)
	
	anim_player_edit = OptionButton.new()
	anim_player_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	anim_player_edit.theme = theme_resource
	anim_player_edit.disabled = true
	anim_player_edit.item_selected.connect(_on_anim_player_selected)
	anim_player_hbox.add_child(anim_player_edit)
	
	# Animated separator
	var separator2 = _create_animated_separator()
	main_vbox.add_child(separator2)
	
	# Auto Bind Section
	var auto_bind_group = _create_animated_section("⌨️ Input Actions", main_vbox)
	
	auto_bind_btn = Button.new()
	auto_bind_btn.text = "🚀 Auto Generate Input Actions"
	auto_bind_btn.theme = theme_resource
	auto_bind_btn.custom_minimum_size.y = 35
	auto_bind_btn.pressed.connect(_on_auto_bind_pressed)
	auto_bind_group.add_child(auto_bind_btn)
	
	var info_label = Label.new()
	info_label.text = "📋 Creates: move_left, move_right, move_forward, move_back, jump, run, crouch, attack, block, dodge\n⚠️ Save project and reload after generation for inputs to apply."
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_size_override("font_size", 11)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	auto_bind_group.add_child(info_label)
	
	# Animated separator
	var separator3 = _create_animated_separator()
	main_vbox.add_child(separator3)
	
	# Animation Selection Section
	var anim_section = _create_animated_section("🎨 Animation Selection", main_vbox)
	
	# Scroll container for animations - FIXED SCROLL CONTAINER
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.custom_minimum_size.y = 350  # Fixed height
	scroll_container.theme = theme_resource
	anim_section.add_child(scroll_container)
	
	# Container for scroll content
	var scroll_content = VBoxContainer.new()
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_content.add_theme_constant_override("separation", 10)
	scroll_container.add_child(scroll_content)
	
	# Create animation categories with animations
	_create_animation_categories(scroll_content)
	
	# Final separator
	var separator4 = _create_animated_separator()
	main_vbox.add_child(separator4)
	
	# Create button with special styling
	create_btn = Button.new()
	create_btn.text = "🎭 Create AnimationTree & Controller"
	create_btn.disabled = true
	create_btn.custom_minimum_size.y = 45
	create_btn.theme = theme_resource
	create_btn.add_theme_font_size_override("font_size", 14)
	create_btn.pressed.connect(_create_animation_system)
	main_vbox.add_child(create_btn)
	
	# Add to editor
	get_editor_interface().get_base_control().add_child(dialog)
	_refresh_scene_files()

func _create_animated_section(title: String, parent: VBoxContainer) -> VBoxContainer:
	var section_container = VBoxContainer.new()
	section_container.add_theme_constant_override("separation", 12)
	parent.add_child(section_container)
	
	# Section header with gradient background
	var header_panel = Panel.new()
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.21, 0.21, 0.25, 0.8)
	header_style.corner_radius_top_left = 8
	header_style.corner_radius_top_right = 8
	header_style.corner_radius_bottom_left = 8
	header_style.corner_radius_bottom_right = 8
	header_style.border_width_left = 2
	header_style.border_color = Color(0.26, 0.59, 0.98, 0.6)
	header_panel.add_theme_stylebox_override("panel", header_style)
	header_panel.custom_minimum_size.y = 40
	section_container.add_child(header_panel)
	
	var header_label = Label.new()
	header_label.text = title
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header_label.add_theme_font_size_override("font_size", 14)
	header_label.add_theme_color_override("font_color", Color(0.26, 0.59, 0.98, 1.0))
	header_panel.add_child(header_label)
	
	return section_container

func _create_animated_separator() -> Control:
	var separator_container = Control.new()
	separator_container.custom_minimum_size.y = 2
	
	var separator_panel = Panel.new()
	separator_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var separator_style = StyleBoxFlat.new()
	separator_style.bg_color = Color(0.26, 0.59, 0.98, 0.3)
	separator_style.corner_radius_top_left = 1
	separator_style.corner_radius_top_right = 1
	separator_style.corner_radius_bottom_left = 1
	separator_style.corner_radius_bottom_right = 1
	separator_panel.add_theme_stylebox_override("panel", separator_style)
	separator_container.add_child(separator_panel)
	
	return separator_container

func _create_animation_categories(parent: VBoxContainer):
	anim_options = {}
	
	var categories = {
		"Basic States": {
			"emoji": "🧘",
			"anims": {"idle": "Idle Animation"}
		},
		"Walking": {
			"emoji": "🚶",
			"anims": {
				"walk_forward": "Walk Forward",
				"walk_backward": "Walk Backward", 
				"walk_left": "Walk Left",
				"walk_right": "Walk Right"
			}
		},
		"Running": {
			"emoji": "🏃",
			"anims": {
				"run_forward": "Run Forward",
				"run_backward": "Run Backward",
				"run_left": "Run Left",
				"run_right": "Run Right"
			}
		},
		"Crouching": {
			"emoji": "🦆",
			"anims": {
				"crouch_idle": "Crouch Idle",
				"crouch_forward": "Crouch Forward",
				"crouch_backward": "Crouch Backward",
				"crouch_left": "Crouch Left",
				"crouch_right": "Crouch Right"
			}
		},
		"Aerial": {
			"emoji": "🦅",
			"anims": {
				"jump": "Jump Animation",
				"fall": "Fall Animation",
				"land": "Land Animation"
			}
		},
		"Combat": {
			"emoji": "⚔️",
			"anims": {
				"attack_1": "Attack 1",
				"attack_2": "Attack 2",
				"attack_3": "Attack 3",
				"block": "Block",
				"dodge": "Dodge"
			}
		},
		"Special": {
			"emoji": "✨",
			"anims": {
				"climb": "Climb Animation",
				"swim": "Swim Animation",
				"slide": "Slide Animation"
			}
		}
	}
	
	for category_name in categories:
		var category_data = categories[category_name]
		
		# SIMPLIFIED Category container - remove complex styling
		var category_container = VBoxContainer.new()
		category_container.add_theme_constant_override("separation", 8)
		parent.add_child(category_container)
		
		# Category header - simplified
		var category_header = HBoxContainer.new()
		category_header.add_theme_constant_override("separation", 8)
		category_container.add_child(category_header)
		
		var category_label = Label.new()
		category_label.text = category_data.emoji + " " + category_name
		category_label.add_theme_font_size_override("font_size", 14)
		category_label.add_theme_color_override("font_color", Color(0.61, 0.35, 0.71, 1.0))
		category_header.add_child(category_label)
		
		var separator = HSeparator.new()
		separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		separator.add_theme_color_override("color", Color(0.61, 0.35, 0.71, 0.3))
		category_header.add_child(separator)
		
		# Animation grid for this category - FIXED layout
		var anim_grid = GridContainer.new()
		anim_grid.columns = 2
		anim_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		anim_grid.add_theme_constant_override("h_separation", 20)  # Increased horizontal spacing
		anim_grid.add_theme_constant_override("v_separation", 8)   # Increased vertical spacing
		category_container.add_child(anim_grid)
		
		# Add animations for this category
		for anim_name in category_data.anims:
			var label = Label.new()
			label.text = category_data.anims[anim_name] + ":"
			label.custom_minimum_size.x = 140  # Fixed width for alignment
			label.add_theme_font_size_override("font_size", 11)
			anim_grid.add_child(label)
			
			var option = OptionButton.new()
			option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			option.theme = theme_resource
			option.add_item("None", 0)
			option.disabled = true
			anim_grid.add_child(option)
			anim_options[anim_name] = option
		
		# Add some spacing between categories
		var spacer = Control.new()
		spacer.custom_minimum_size.y = 15
		parent.add_child(spacer)

func _on_dialog_close():
	if dialog and main_panel:
		# Animate dialog close using main panel
		if animation_tween:
			animation_tween.kill()  # Fixed: use kill() instead of queue_free()
		animation_tween = create_tween()
		animation_tween.set_parallel(true)
		animation_tween.tween_property(main_panel, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
		animation_tween.tween_property(main_panel, "scale", Vector2(0.8, 0.8), 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		animation_tween.tween_callback(dialog.hide).set_delay(0.2)

func _on_auto_bind_pressed():
	# Button press animation
	_animate_button_press(auto_bind_btn)
	var animation_system = AnimationSystem.new()
	animation_system.editor_interface = get_editor_interface()
	animation_system.auto_bind_input_actions()
func _animate_options_enable():
	# Animate the scroll container content appearing
	if animation_tween:
		animation_tween.kill()  # Fixed: use kill() instead of queue_free()
	animation_tween = create_tween()
	
	scroll_container.modulate.a = 0.5
	animation_tween.tween_property(scroll_container, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
func _show_creation_progress():
	# Change button text and animate
	create_btn.text = "✨ Creating Animation System..."
	create_btn.disabled = true
	
	if animation_tween:
		animation_tween.kill()  # Fixed: use kill() instead of queue_free()
	animation_tween = create_tween()
	animation_tween.set_loops()
	animation_tween.tween_property(create_btn, "modulate", Color(0.8, 1.2, 0.8, 1.0), 0.5)
	animation_tween.tween_property(create_btn, "modulate", Color.WHITE, 0.5)
func _animate_button_press(button: Button):
	if animation_tween:
		animation_tween.kill()  # Fixed: use kill() instead of queue_free()
	animation_tween = create_tween()
	animation_tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
	animation_tween.tween_property(button, "scale", Vector2.ONE, 0.1)

func _refresh_scene_files():
	_animate_button_press(scene_file_edit.get_parent().get_children()[2]) # Refresh button
	
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
