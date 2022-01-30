tool
extends ConfirmationDialog

enum MODE { PROJECT, EDITOR }

var item_dictionary : Dictionary = {}
var selected_property : String = String()

var ignore_list : Array = ["ProjectSettings", "input", "script", "reference",
							"Resource", "resource_local_to_scene", "resource_path",
							"resource_name", "EditorSettings", "Reference",
							"projects", "favorite_projects", "shortcuts"]

var mode : int = MODE.PROJECT

onready var tree : Tree = $VBoxContainer/ScrollContainer/Tree
onready var filter_edit : LineEdit = $VBoxContainer/HBoxContainer/Filter

func _ready():
	get_ok().text = "Add"
	get_ok().icon = get_icon("Add", "EditorIcons")

# Populate tree with propertues matching filter keyword
func build_tree(filter : String = String()):
	tree.clear()
	item_dictionary.clear()
	
	item_dictionary["root_item"] = tree.create_item()
	
	var properties : Array
	if mode == MODE.PROJECT:
		properties = ProjectSettings.get_property_list()
		window_title = "Select a Project property..."
	else:
		properties = get_parent().editor_plugin.get_editor_interface().get_editor_settings().get_property_list()
		window_title = "Select an Editor property..."
		
	for property in properties:
		var property_name : String = property["name"]
		var path_elements : Array = property_name.split('/')
		
		# Skip if not a Project property
		if path_elements[0] in ignore_list:
			continue
		# Skip if filtered by keywords
		var hide_element : bool = false
		if filter != "":
			for word_filter in filter.strip_edges().split(" "):
				if not hide_element and property_name.find(word_filter) == -1:
					hide_element = true
			if hide_element:
				continue

		var parent_string : String = String()
		var parent : TreeItem = item_dictionary["root_item"]
		var current_path : String = String()

		for path_element in path_elements:
			if not parent_string.empty():
				# Folding items are not selectable
				item_dictionary[parent_string].set_selectable(0, false)
				current_path += '/'
			current_path += path_element
			
			# Do not duplicate parents item
			if not item_dictionary.has(current_path):				
				item_dictionary[current_path] = tree.create_item(parent)
				item_dictionary[current_path].set_text(0, path_element.capitalize())
				item_dictionary[current_path].set_meta("property", property_name)
				
			# Current item becomes parent for the next one
			parent = item_dictionary[current_path]
			parent_string = current_path


func searchbar_grab_focus():
	filter_edit.grab_focus()

# Reset filter before poping
func reset(p_mode = MODE.PROJECT) -> void:
	mode = p_mode
	get_ok().set_disabled(true)
	filter_edit.clear()
	build_tree()


# Single click on an item
func _on_Tree_item_selected():
	get_ok().set_disabled(false)
	selected_property = tree.get_selected().get_meta("property")


# Double click on an item
func _on_Tree_item_activated():
	emit_signal("confirmed")
	hide()
