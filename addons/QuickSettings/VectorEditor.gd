extends VBoxContainer
class_name VectorEditor

tool

signal value_changed

# Untyped vector can deals with Vector2 and Vector3
var value = Vector2.ZERO

onready var spin_boxes : Array = [ $HBoxX/SpinBoxX, $HBoxY/SpinBoxY, $HBoxZ/SpinBoxZ]
onready var z_box : HBoxContainer = $HBoxZ

func set_value(p_value):
	value = p_value
	
func get_value():
	return value

# Called when the node enters the scene tree for the first time.
func _ready():
	
	z_box.set_visible(value is Vector3)
	spin_boxes[0].value = value.x
	spin_boxes[1].value = value.y
	if value is Vector3:
		spin_boxes[2].value = value.z
	

func on_spinbox_value_changed(p_value : float, component : int):
	match component:
		0:
			value.x = p_value
		1:
			value.y = p_value
		2:
			value.z = p_value
	emit_signal("value_changed")
