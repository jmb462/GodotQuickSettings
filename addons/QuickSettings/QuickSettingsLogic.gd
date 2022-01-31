tool
extends Control
class_name QuickSettings

enum MODE { PROJECT, EDITOR }

# Base plugin properties
var settings : Array = []
var settings_names : Array = []

# Editor Settings
var editor_plugin : EditorPlugin

# Save text when input field is loosing focus
var text_dirty : bool = false

# Edited Property
var edited_property : String
var edited_property_dict : Dictionary

var request_restart_properties : Array = []

onready var config_save_location : String = String(self.get_script().get_path()).get_base_dir()

# Base plugin interface
onready var project_property_selector_button : Button = $VBoxContainer/HBoxContainer/ProjectPropertySelectorButton
onready var editor_property_selector_button : Button = $VBoxContainer/HBoxContainer/EditorPropertySelectorButton
onready var restart_label : Label = $VBoxContainer/RestartLabel
onready var grid : GridContainer = $VBoxContainer/ScrollContainer/GridContainer

# Popups
onready var array_editor : ArrayEditor= $ArrayEditor
onready var file_dialog = $FileDialog
onready var property_selector = $PropertySelector
onready var context_menu : ContextMenu = $ContextMenu
onready var rename_dialog : RenamePropertyDialog = $RenameDialog
# Vector editor
onready var vector_editor_packed_scene : PackedScene = preload("VectorEditor.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_button(project_property_selector_button, "Add", "on_property_selector_button_pressed", {}, MODE.PROJECT)
	setup_button(editor_property_selector_button, "Add", "on_property_selector_button_pressed", {}, MODE.EDITOR)
	restart_label.add_color_override("font_color", restart_label.get_color("warning_color", "Editor"))
	property_selector.connect("confirmed", self, "on_property_selector_confirmed")
	array_editor.connect("confirmed", self, "on_array_editor_confirmed")
	rename_dialog.connect("confirmed", self, "on_rename_confirmed")
	
func setup_button(p_control : Control, p_icon : String, p_callback : String, p_property : Dictionary = {}, p_mode : int = MODE.PROJECT):
	var parameters : Array = []
	if p_control is TextureButton:
		p_control.texture_normal = grid.get_icon(p_icon, "EditorIcons")
		p_control.size_flags_vertical = SIZE_EXPAND_FILL
		p_control.size_flags_horizontal = SIZE_FILL
		p_control.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
		p_control.rect_min_size.x = 20
		p_control.expand = true
		p_control.set_meta("property_name", p_property["name"])
		parameters.append(p_property)
	else:
		p_control.icon = grid.get_icon(p_icon, "EditorIcons")
		parameters.append(p_mode)
	p_control.connect("mouse_entered", self, "on_hover_control", [p_control, true])
	p_control.connect("mouse_exited", self, "on_hover_control", [p_control, false])
	p_control.connect("pressed", self, p_callback, parameters)
	p_control.modulate.a = 0.7

func add_property_from_string(property_string : String, display_name : String = String(), loading_config = false):
	var mode : int = get_mode(property_string)
	if mode == -1:
		print("QuickSetting : Property %s not found" % [property_string])
		return

	var property_list : Array = get_properties_from_settings(mode)
	
	for each_setting in settings:
		if each_setting["name"] == property_string:
			print("QuickSetting : Property %s is already added" % [property_string])
			return
	var value = get_value(property_string)
	
	for property in property_list:
		if property["name"] == property_string:
			settings.append(property)
			if not loading_config:
				var dict_setting : Dictionary = {}
				dict_setting["name"] = property["name"]
				dict_setting["display_name"] = display_name
				settings_names.append(dict_setting)
	if not loading_config:
		save_config()
	update_view()
	

func on_property_selector_button_pressed(mode : int):
	property_selector.reset(mode)
	property_selector.popup_centered_clamped(Vector2(400,500), 1.1)
	property_selector.searchbar_grab_focus()

func update_view():
	clear_grid()
	for property in settings:
		property = Dictionary(property)
		add_to_grid(property)

func clear_grid():
	for child in grid.get_children():
		if is_instance_valid(child):
			child.queue_free()
			
func add_to_grid(property : Dictionary):
	var property_name : String = property["name"]
	
	var hbox_left : HBoxContainer = HBoxContainer.new()
	hbox_left.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox_left.set_meta("property_name", property_name)
	hbox_left.hint_tooltip = get_tooltip_text(property_name)
	
	var property_label : Label = Label.new()
	property_label.size_flags_horizontal = SIZE_EXPAND_FILL
	property_label.mouse_filter = Control.MOUSE_FILTER_STOP
	property_label.hint_tooltip = get_tooltip_text(property_name)
	property_label.connect("gui_input", self, "on_mouse_input_over_property_label", [property])
	property_label.text = get_display_name(property_name)
	hbox_left.add_child(property_label)
	
	var revert_icon : TextureButton = TextureButton.new()
	setup_button(revert_icon, "Reload", "on_revert_button_pressed", property)
	revert_icon.set_meta("revert_button", true)
	revert_icon.visible =  property_can_revert(property_name)
	revert_icon.hint_tooltip = "Revert to default value"
	hbox_left.add_child(revert_icon)
	
	grid.add_child(hbox_left)
	
	var hbox_right : HBoxContainer = HBoxContainer.new()
	var value_placeholder : PanelContainer = PanelContainer.new()
	
	hbox_right.size_flags_horizontal = SIZE_EXPAND_FILL
	
	value_placeholder.size_flags_horizontal = SIZE_EXPAND_FILL

	hbox_right.add_child(value_placeholder)
	
	match property["type"]:
			TYPE_BOOL:
				var checkbox : CheckBox = CheckBox.new()
				checkbox.pressed = get_value(property_name)
				checkbox.text = "On" if checkbox.pressed else "Off"
				checkbox.size_flags_horizontal = SIZE_EXPAND_FILL
				checkbox.connect("pressed", self, "on_check_changed", [checkbox, property_name])				
				value_placeholder.add_child(checkbox)
			TYPE_INT, TYPE_REAL:
				if property["hint"] == PROPERTY_HINT_ENUM:
					var option_button : OptionButton = OptionButton.new()
					option_button.size_flags_horizontal = SIZE_EXPAND_FILL
					var hints = String(property["hint_string"]).split(",")
					for hint in hints:
						option_button.add_item(String(hint).capitalize())
					option_button.select(get_value(property_name))
					option_button.connect("item_selected", self, "on_option_num", [option_button, property_name])
					value_placeholder.add_child(option_button)
				elif property["hint"] == PROPERTY_HINT_NONE:
					var spin_box : SpinBox = SpinBox.new()
					spin_box.size_flags_horizontal = SIZE_EXPAND_FILL
					spin_box.min_value = - 99999999
					spin_box.max_value = 99999999
					if property['type'] == TYPE_REAL:
						spin_box.step = 0.01
						spin_box.rounded = false
					else:
						spin_box.step = 1
						spin_box.rounded = true
					spin_box.value = get_value(property_name)
					spin_box.connect("value_changed", self, "on_spinbox_value_changed", [property_name])
					value_placeholder.add_child(spin_box)
				elif property["hint"] == PROPERTY_HINT_RANGE:
					var spin_box : SpinBox = SpinBox.new()
					spin_box.size_flags_horizontal = SIZE_EXPAND_FILL
					
					var hints = String(property["hint_string"]).split(",")
					if hints.size() > 0:
						spin_box.min_value = float(hints[0])
					if hints.size() > 1:
						spin_box.max_value = float(hints[1])
					if hints.size() > 2 and hints[2].is_valid_float():
							spin_box.step = float(hints[2])
					spin_box.allow_lesser = "or_lesser" in hints
					spin_box.allow_greater = "or_greater" in hints
					spin_box.value = get_value(property_name)
					spin_box.connect("value_changed", self, "on_spinbox_value_changed", [property_name])
					value_placeholder.add_child(spin_box)
			TYPE_STRING:
				if property["hint"] == PROPERTY_HINT_ENUM:
					var option_button : OptionButton = OptionButton.new()
					option_button.size_flags_horizontal = SIZE_EXPAND_FILL
					var hints : Array = String(property["hint_string"]).split(",")
					var to_select : String = get_value(property_name)
					for i in hints.size():
						option_button.add_item(String(hints[i]).capitalize())
					option_button.select(hints.find(to_select))
					option_button.connect("item_selected", self, "on_option_str", [option_button, hints, property_name])
					value_placeholder.add_child(option_button)
				elif property["hint"] == PROPERTY_HINT_MULTILINE_TEXT:
					var text_edit = TextEdit.new()
					text_edit.size_flags_horizontal = SIZE_EXPAND_FILL
					text_edit.text = get_value(property_name)
					text_edit.rect_min_size.y = 75
					text_edit.connect("text_changed", self, "on_text_changed", [text_edit, property_name])
					text_edit.connect("focus_exited", self, "on_text_unfocus", [text_edit, property_name])
					value_placeholder.add_child(text_edit)
				elif property["hint"] in [PROPERTY_HINT_FILE, PROPERTY_HINT_DIR]:
					var hbox_file : HBoxContainer = HBoxContainer.new()
					hbox_file.size_flags_horizontal = SIZE_EXPAND_FILL
					
					var line_edit : LineEdit = LineEdit.new()
					line_edit.size_flags_horizontal = SIZE_EXPAND_FILL
					line_edit.text = get_value(property_name)
					line_edit.connect("focus_exited", self, "on_text_unfocus", [line_edit, property_name])
					line_edit.connect("text_changed", self, "on_line_edit_changed", [property_name])
					
					hbox_file.add_child(line_edit)
					
					var folder_icon : TextureButton = TextureButton.new()
					setup_button(folder_icon, "Folder", "on_folder_button_pressed", property)
					folder_icon.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
					hbox_file.add_child(folder_icon)
					
					value_placeholder.add_child(hbox_file)
				else:
					var line_edit : LineEdit = LineEdit.new()
					line_edit.size_flags_horizontal = SIZE_EXPAND_FILL
					line_edit.text = get_value(property_name)
					line_edit.connect("focus_exited", self, "on_text_unfocus", [line_edit, property_name])
					line_edit.connect("text_changed", self, "on_line_edit_changed", [property_name])
					value_placeholder.add_child(line_edit)
			TYPE_COLOR:
				var color_rect : ColorPickerButton = ColorPickerButton.new()
				color_rect.size_flags_horizontal = SIZE_EXPAND_FILL
				color_rect.color = get_value(property_name)
				color_rect.connect("popup_closed", self, "on_color_changed", [color_rect, property_name])				
				value_placeholder.add_child(color_rect)
			TYPE_STRING_ARRAY:
				var array_button : Button = Button.new()
				array_button.size_flags_horizontal = SIZE_EXPAND_FILL
				array_button.text = "PoolStringArray (%s)" % [PoolStringArray(get_value(property_name)).size()]
				array_button.connect("pressed", self, "on_array_button_pressed", [property, property_label.text, array_button])
				value_placeholder.add_child(array_button)
			TYPE_DICTIONARY:
				var line_edit : LineEdit = LineEdit.new()
				line_edit.size_flags_horizontal = SIZE_EXPAND_FILL
				line_edit.text = "TYPE_DICTIONARY" + String(get_value(property_name))
				value_placeholder.add_child(line_edit)
			TYPE_VECTOR2, TYPE_VECTOR3:
				var vector_editor : VectorEditor = vector_editor_packed_scene.instance()
				vector_editor.set_value(get_value(property_name))
				vector_editor.connect("value_changed", self, "on_vector_value_changed", [vector_editor, property_name])
				value_placeholder.add_child(vector_editor)
				
	var remove_icon : TextureButton = TextureButton.new()
	setup_button(remove_icon, "Remove", "on_remove_button_pressed", property)
	remove_icon.hint_tooltip = "Remove from Quicksettings"
	hbox_right.add_child(remove_icon)
	hbox_right.set_meta("property_name", property_name)
	grid.add_child(hbox_right)
	
func on_hover_control(p_control : Control, p_hover : bool = true) -> void:
	p_control.modulate.a = 1.0 if p_hover else 0.7

func on_revert_button_pressed(property : Dictionary) -> void:
	var default_value = property_get_revert(property["name"])
	set_value(property["name"], default_value)
	save_value(property["name"])
	update_view()

func on_remove_button_pressed(property) -> void:
	for i in settings.size():
		if settings[i]["name"] == property['name']:
			settings.remove(i)
			settings_names.remove(i)
			break			
	for child in grid.get_children():
		if child.has_meta("property") and child.get_meta("property_name") == property['name']:
			grid.remove_child(child)
			child.queue_free()
	save_config()
	update_view()
	
func on_color_changed(color_picker : ColorPickerButton, property_name) -> void:
	save_change(property_name, color_picker.color)

func on_check_changed(checkbox : CheckBox, property_name) -> void:
	save_change(property_name, checkbox.pressed)
	
func on_option_num(id : int, option_button : OptionButton, property_name) -> void:
	save_change(property_name, id)
	
func on_option_str(id : int, option_button : OptionButton, hints, property_name) -> void:
	save_change(property_name, hints[id])

func on_spinbox_value_changed(value, property_name) -> void:
	save_change(property_name, value)

func on_text_changed(control, property_name) -> void:
	ProjectSettings.set_setting(property_name, control.text)
	text_dirty = true
	update_revert_icon(property_name)

func on_line_edit_changed(value, property_name) -> void:
	ProjectSettings.set_setting(property_name, value)
	text_dirty = true
	update_revert_icon(property_name)

func on_text_unfocus(control, property_name) -> void:
	if text_dirty:
		save_value(property_name)
		text_dirty = false

func on_folder_button_pressed(property) -> void:
	edited_property = property['name']
	if property["hint"] == PROPERTY_HINT_FILE:
		file_dialog.mode = FileDialog.MODE_OPEN_FILE
		file_dialog.filters = PoolStringArray(property["hint_string"].split(','))
		file_dialog.current_file = String(ProjectSettings.get(property["name"])).get_file()
	else:
		file_dialog.mode = FileDialog.MODE_OPEN_DIR
	
	file_dialog.current_dir = String(ProjectSettings.get(property["name"])).get_base_dir()
			
	file_dialog.popup_centered_clamped(Vector2(600,400), 0.8)
	
func on_vector_value_changed(p_vector_editor, property_name) -> void:
	save_change(property_name, p_vector_editor.get_value())
	
func on_array_button_pressed(property : Dictionary, short_name : String, button : Button) -> void:
	array_editor.configure(property["name"], short_name, button, PoolStringArray(ProjectSettings.get(property["name"])))
	array_editor.set_position(get_global_mouse_position())
	array_editor.popup()

func on_array_editor_confirmed() -> void:
	save_change(array_editor.get_property_name(), array_editor.get_array())

func save_change(property_name, value) -> void:
	set_value(property_name, value)
	save_value(property_name)
	update_revert_icon(property_name)
	
func update_revert_icon(property_name : String) -> void:
	for hbox in grid.get_children():
		if hbox is HBoxContainer and hbox.has_meta("property_name") and hbox.get_meta("property_name") == property_name:
			for button in hbox.get_children():
				if button is TextureButton and button.has_meta("revert_button"):
					if button.has_meta("property_name") and button.get_meta("property_name") == property_name:
						button.visible = property_can_revert(property_name)

func on_property_selector_confirmed() -> void:
	if not property_selector.selected_property.empty():
		var display_name : String = property_selector.get_display_name()
		add_property_from_string(property_selector.selected_property, display_name)


func _on_FileDialog_file_selected(path) -> void:
	save_change(edited_property, path)
	update_view()

# Show clipboard menu
func on_mouse_input_over_property_label(event, property) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == BUTTON_RIGHT:
			edited_property = property["name"]
			context_menu.set_edited_property(property["name"])
			context_menu.build(property["type"])
			
			context_menu.set_position(get_global_mouse_position())
			context_menu.popup()

func get_mode(property : String) -> int:
	if ProjectSettings.has_setting(property):
		return MODE.PROJECT
	elif editor_plugin and editor_plugin.get_editor_interface().get_editor_settings().has_setting(property):
		return MODE.EDITOR
	return -1

# Keep return value untyped to handle various Variant
func get_value(property : String):
	var mode :int = get_mode(property)
	if mode == MODE.PROJECT:
		return ProjectSettings.get_setting(property)
	elif mode == MODE.EDITOR:
		return editor_plugin.get_editor_interface().get_editor_settings().get_setting(property)
	return null
	
func get_properties_from_settings(mode : int) -> Array:
	if mode == MODE.PROJECT:
		return ProjectSettings.get_property_list()
	elif mode == MODE.EDITOR:
		return editor_plugin.get_editor_interface().get_editor_settings().get_property_list()
	return []
	
func property_can_revert(property : String) -> bool:
	var mode :int = get_mode(property)
	if mode == MODE.PROJECT:
		return ProjectSettings.property_can_revert(property)
	elif mode == MODE.EDITOR:
		return editor_plugin.get_editor_interface().get_editor_settings().property_can_revert(property)
	return false

# Keep parameter value untyped to handle various Variant
func set_value(property : String, value) -> void:
	var mode :int = get_mode(property)
	if mode == MODE.PROJECT:
		ProjectSettings.set_setting(property, value)
	elif mode == MODE.EDITOR:
		editor_plugin.get_editor_interface().get_editor_settings().set_setting(property, value)
	if request_restart_properties.find(property) != -1:
		show_restart_warning()
		
# Keep return value untyped to handle various Variant
func property_get_revert(property : String):
	var mode :int = get_mode(property)
	if mode == MODE.PROJECT:
		return ProjectSettings.property_get_revert(property)
	elif mode == MODE.EDITOR:
		return editor_plugin.get_editor_interface().get_editor_settings().property_get_revert(property)
	return null

func save_value(property) -> void:
	var mode :int = get_mode(property)
	if mode == MODE.PROJECT:
		ProjectSettings.save()
#	elif mode == MODE.EDITOR:
#		editor_plugin.get_editor_interface().get_editor_settings()

func show_restart_warning():
	restart_label.show()

func on_restart_pressed(_mode : int):
#	editor_plugin.get_editor_interface().save_scene();
#	editor_plugin.get_editor_interface().restart_editor();
	pass

func on_editor_settings_changed():
	update_view()

# Get customized display name or default
func get_display_name(property_name : String, default : bool = false) -> String:
	if not default:
		for setting in settings_names:
			if setting is Dictionary and setting.has("name") and setting.has("display_name"):
				if setting["name"] == property_name and setting["display_name"] != "":
					return setting["display_name"]
	return Array(property_name.split("/")).pop_back().capitalize()

# Is setting already added to QuickSettings
func has_setting(property_name : String) -> bool:
	for setting in settings_names:
		if setting is Dictionary and setting.has("name"):
			if setting["name"] == property_name:
				return true
	return false

func get_tooltip_text(property_name : String) -> String:
	var tooltip : String
	if get_mode(property_name) == MODE.PROJECT:
		tooltip += "Project Property :\n"
	if get_mode(property_name) == MODE.EDITOR:
		tooltip += "Editor Property :\n"
	tooltip += property_name
	return tooltip

func on_rename_requested(property : String):
	rename_dialog.set_property(property)
	rename_dialog.set_defaut_texture(grid.get_icon("Reload", "EditorIcons"))
	rename_dialog.popup_centered()

func on_rename_confirmed():
	var new_name : String = rename_dialog.line_edit.text.strip_edges()
	for setting in settings_names:
		if setting is Dictionary and setting.has("name"):
			if setting["name"] == edited_property:
				setting["display_name"] = new_name
				save_config()
				update_view()
	

# Load / Save plugin configuration
func load_config() -> void:
	var config_file : ConfigFile = ConfigFile.new()
	var err : int = config_file.load(config_save_location + "/QuickSettings.cfg")
	if err != OK:
		return
	settings_names = config_file.get_value("Project Settings", "settings", [])
	for setting in settings_names:
		if setting is Dictionary:
			add_property_from_string(setting["name"], setting["display_name"], true)
	
func save_config() -> void:
	var config_file : ConfigFile = ConfigFile.new()
	config_file.set_value("Project Settings", "settings", settings_names)	
	var err : int = config_file.save(config_save_location + "/QuickSettings.cfg")
	if err != OK:
		print("QuickSettings failed to write configuration on disk. (Error %s)" % [err])


func initialize(p_editor_plugin : EditorPlugin):
	editor_plugin = p_editor_plugin
	var properties = get_properties_from_settings(MODE.PROJECT)
	properties.append_array(get_properties_from_settings(MODE.EDITOR))
	for property in properties:
		if property["usage"] & 4096 and request_restart_properties.find(property["name"]) == -1:
				request_restart_properties.append(property["name"])
