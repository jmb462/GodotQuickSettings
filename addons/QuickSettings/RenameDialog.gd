tool
extends ConfirmationDialog
class_name RenamePropertyDialog



var edited_property : String = String()
var default_button : Button

onready var label : Label = $VBoxContainer/Label
onready var line_edit : LineEdit = $VBoxContainer/HBoxContainer/LineEdit
onready var revert_button : TextureButton = $VBoxContainer/HBoxContainer/TextureButton

func _ready():
	revert_button.connect("mouse_exited", self, "_on_TextureButton_mouse_exited")
	revert_button.connect("mouse_entered", self, "_on_TextureButton_mouse_entered")
	revert_button.connect("pressed", self, "_on_TextureButton_pressed")
	revert_button.modulate.a = 0.7

func set_defaut_texture(texture : Texture) -> void:
	revert_button.texture_normal = texture

func set_property(property_name : String) -> void:
	edited_property = property_name
	label.text = property_name
	line_edit.text = get_parent().get_display_name(edited_property, false)

func _on_TextureButton_pressed():
	line_edit.text = get_parent().get_display_name(edited_property, true)

func _on_TextureButton_mouse_entered():
	revert_button.modulate.a = 1.0
	
func _on_TextureButton_mouse_exited():
	revert_button.modulate.a = 0.7
