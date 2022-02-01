tool
extends PopupMenu
class_name ContextMenu


signal refresh_requested
signal rename_requested
signal moved_up
signal moved_down

enum CONTEXT_MENU {COPY_PATH, COPY_PROPERTY, COPY_AS_TEXT, PASTE, RENAME, MOVE_UP, MOVE_DOWN}

# Untyped variable to store various Variant type
var property_clipboard = null
# Type of property in clipboard
var property_clipoard_type : int = -1
# Type of property under right mouse click
var property_click_type : int = -1

var edited_property : String = String()
var property_index : int = -1

func _ready():
	connect("refresh_requested", get_parent(), "update_view")
	connect("rename_requested", get_parent(), "on_rename_requested")
	connect("moved_up", get_parent(), "on_move_up")
	connect("moved_down", get_parent(), "on_move_down")


func set_edited_property(p_property_name : String) -> void:
	edited_property = p_property_name

func build(p_property_click_type : int, p_property_index : int, p_max_index : int):
	property_click_type = p_property_click_type
	property_index = p_property_index
	clear()
	print("property index ", p_property_index)
	add_icon_item(get_icon("CopyNodePath", "EditorIcons"), "Copy path", CONTEXT_MENU.COPY_PATH)
	add_icon_item(get_icon("ActionCopy", "EditorIcons"), "Copy value", CONTEXT_MENU.COPY_PROPERTY)
	
	if property_click_type != TYPE_STRING:
		add_item("Copy value as text", CONTEXT_MENU.COPY_AS_TEXT)
	
	add_separator("", CONTEXT_MENU.PASTE)
	add_icon_item(get_icon("ActionPaste", "EditorIcons"), "Paste value", CONTEXT_MENU.PASTE)
	
	var can_paste : bool = (property_clipoard_type != property_click_type and property_clipoard_type != -1 and property_click_type != -1) or property_clipboard == null
	set_item_disabled(get_item_count() - 1,  can_paste)
	add_separator("", CONTEXT_MENU.RENAME)
	add_icon_item(get_icon("Rename", "EditorIcons"), "Rename", CONTEXT_MENU.RENAME)
	add_separator("", CONTEXT_MENU.MOVE_UP)
	add_icon_item(get_icon("MoveUp", "EditorIcons"), "Move Up", CONTEXT_MENU.MOVE_UP)
	set_item_disabled(get_item_count() - 1,  property_index < 1)
	add_icon_item(get_icon("MoveDown", "EditorIcons"), "Move Down", CONTEXT_MENU.MOVE_DOWN)
	set_item_disabled(get_item_count() - 1,  property_index >= p_max_index -1)
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
		CONTEXT_MENU.MOVE_UP:
			emit_signal("moved_up", property_index)
		CONTEXT_MENU.MOVE_DOWN:
			emit_signal("moved_down", property_index)
		
