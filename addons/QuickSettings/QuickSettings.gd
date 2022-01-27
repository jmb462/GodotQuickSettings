tool
extends EditorPlugin

var dock : Control

func _enter_tree():
	dock = preload("res://addons/QuickSettings/QuickSettings.tscn").instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
