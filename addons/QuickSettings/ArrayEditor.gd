extends AcceptDialog
class_name ArrayEditor
tool

# Array Editor variables
var array : PoolStringArray = []
var array_items : Array = []
var property_name : String
var array_button : Button

onready var tree : Tree = $VBoxContainer/ScrollContainer/Tree
onready var size_spin = $VBoxContainer/HBoxContainer/SizeSpin

func _ready():
	pass # Replace with function body.

func configure(p_property_name : String, p_short_name : String, p_button : Button, p_array : PoolStringArray) -> void:
	property_name = p_property_name
	array_button = p_button
	array = p_array
	window_title = p_short_name
	
	size_spin.value = array.size()
	var root = tree.create_item()
	tree.set_hide_root(true)
	tree.set_column_expand(0, false)
	tree.set_column_min_width(0, 32)
	tree.set_column_expand(1, true)
	
	update_tree()

func update_tree():
	tree.clear()
	array_items.clear()
	var root = tree.create_item()
	for id in array.size():
		var item = tree.create_item(root)
		array_items.append(item)
		item.set_text(0, str(id))
		item.set_text(1, array[id])
		item.set_editable(1, true)

func get_property_name() -> String:
	return property_name

func get_array() -> PoolStringArray: 
	array.resize(0)
	for item in array_items:
		array.append(item.get_text(1))
	return array
	
func on_SizeSpin_value_changed(value):
	array.resize(value)
	update_tree()
	array_button.text = "PoolStringArray (%s)" % [value]
	emit_signal("confirmed")

func on_Tree_item_edited():
	emit_signal("confirmed")
