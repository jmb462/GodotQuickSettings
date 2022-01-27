extends ConfirmationDialog
tool


var item_dictionary : Dictionary = {}
var selected_property : String = String()


onready var tree = $VBoxContainer/ScrollContainer/Tree
onready var filter_edit = $VBoxContainer/HBoxContainer/Filter


# Populate tree with propertues matching filter keyword
func build_tree(filter : String = String()):
	tree.clear()
	item_dictionary.clear()
	
	item_dictionary["root_item"] = tree.create_item()
	var properties = ProjectSettings.get_property_list()
	
	for property in properties:
		var property_name : String = property["name"]
		var path_elements : Array = property_name.split('/')
		
		# Skip if not a Project property
		if path_elements[0] in ["ProjectSettings", "input", "script"]:
			continue
					
		# Skip if filtered by keywords	
		if filter != "" and property_name.find(filter) == -1:
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


# Reset filter before poping
func reset() -> void:
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
