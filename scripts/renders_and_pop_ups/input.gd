# File: InputPopup.gd
extends RefCounted
class_name InputPopup

signal value_submitted(value)

func show_input_dialog(parent_node: Node) -> void:
	var dialog := AcceptDialog.new()
	
	var style = StyleBoxTexture.new()
	var texture = preload("res://assets/ui/04_Stone_Theme/Sprites/UI_Stone_Frame_Standard_02a.png")
	style.texture = texture
	style.texture_margin_bottom = 20
	style.texture_margin_top = 20
	style.texture_margin_left = 100
	style.texture_margin_right = 100
	dialog.add_theme_stylebox_override("panel", style)
	
	dialog.title = "Enter a value"
	dialog.name = "InputDialog"  
	
	var line_edit := LineEdit.new()
	line_edit.placeholder_text = "Type something..."

	dialog.add_child(line_edit)
	dialog.connect("confirmed", Callable(self, "_on_dialog_confirmed").bind(line_edit))

	parent_node.add_child(dialog)

	dialog.popup_centered()

func _on_dialog_confirmed(line_edit: LineEdit) -> void:
	emit_signal("value_submitted", line_edit.text)
