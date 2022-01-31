tool
extends PopupMenu
class_name ContextMenu


signal refresh_requested
signal rename_requested

enum CONTEXT_MENU {COPY_PATH, COPY_PROPERTY, COPY_AS_TEXT, PASTE, RENAME}

# Untyped variable to store various Variant type
var property_clipboard
# Type of property in clipboard
var property_clipoard_type : int = -1
# Type of property under right mouse click
var property_click_type : int = -1

var edited_property : String = String()

func _ready():
	connect("refresh_requested", get_parent(), "update_view")
	connect("rename_requested", get_parent(), "on_rename_requested")

func set_edited_property(p_property_name : String) -> void:
	edited_property = p_property_name

func build(p_property_click_type : int):
	property_click_type = p_property_click_type
	clear()
	add_item("Copy path", CONTEXT_MENU.COPY_PATH)
	add_item("Copy value", CONTEXT_MENU.COPY_PROPERTY)
	if property_click_type != TYPE_STRING:
		add_item("Copy value as text", CONTEXT_MENU.COPY_AS_TEXT)
	add_separator("", CONTEXT_MENU.PASTE)
	add_item("Paste value", CONTEXT_MENU.PASTE)
	add_separator("", CONTEXT_MENU.RENAME)
	add_item("Rename", CONTEXT_MENU.RENAME)
	var can_paste : bool = property_clipoard_type != property_click_type and property_clipoard_type != -1 and property_click_type != -1
	set_item_disabled(get_item_count() - 1,  can_paste)
	set_size(Vector2.ZERO)


func on_ClipboardMenu_id_pressed(id):
	match id:
		CONTEXT_MENU.COPY_PATH:
			OS.set_clipboard(edited_property)
		CONTEXT_MENU.COPY_PROPERTY:
			property_clipboard = ProjectSettings.get(edited_property)
			property_clipoard_type = property_click_type
			if property_clipoard_type == TYPE_STRING:
				OS.set_clipboard(property_clipboard)
		CONTEXT_MENU.COPY_AS_TEXT: 
			OS.set_clipboard(String(ProjectSettings.get(edited_property)))
		CONTEXT_MENU.PASTE:
			ProjectSettings.set(edited_property, property_clipboard)
			emit_signal("refresh_requested")
		CONTEXT_MENU.RENAME:
			emit_signal("rename_requested", edited_property)
