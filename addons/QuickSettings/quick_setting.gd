tool
extends EditorPlugin

var dock : QuickSettings

func _enter_tree():
	dock = preload("res://addons/QuickSettings/QuickSettings.tscn").instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

func _exit_tree() -> void:
	remove_control_from_docks(dock)
	if is_instance_valid(dock):
		dock.queue_free()
	
func _ready():
	dock.editor_plugin = self
	get_editor_interface().get_editor_settings().connect("settings_changed", dock, "on_editor_settings_changed")
	dock.load_config()
