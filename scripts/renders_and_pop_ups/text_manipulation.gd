extends RefCounted

class_name DynamicRichText

var textBox: RichTextLabel  # Store reference to the RichTextLabel

func create_rich_text_label(parent: Node):
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10  # Ensure it's above everything
	parent.add_child(canvas_layer)

	# Create Background Panel (Ensures it stays behind the text)
	var background = Panel.new()
	background.size = Vector2(400, 80)  # Define fixed size
	background.position = Vector2(800, 5)

	# Create StyleBox for Background Color
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.75)  # Semi-transparent black
	background.add_theme_stylebox_override("panel", style)

	# Create VBoxContainer to center the text vertically
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.custom_minimum_size = Vector2(400, 100)
	container.alignment = BoxContainer.ALIGNMENT_CENTER  # Ensures vertical centering

	# Create RichTextLabel
	textBox = RichTextLabel.new()
	textBox.name = "DynamicTextBox"
	textBox.bbcode_enabled = true
	textBox.text = "[center][color=white]Hello, this is a dynamically created label![/color][/center]"
	textBox.autowrap_mode = TextServer.AUTOWRAP_WORD
	textBox.fit_content = true
	textBox.clip_contents = false  

	# Ensure text stretches and centers vertically
	textBox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textBox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	await parent.get_tree().process_frame  # Ensure UI updates correctly

	# Properly organize elements to ensure background is behind text
	background.add_child(container)  # Make container a child of the background
	container.add_child(textBox)  # Add text inside container
	canvas_layer.add_child(background)  # Add background to canvas layer

	# Ensure everything is centered
	background.set_anchors_preset(Control.PRESET_CENTER)
	container.set_anchors_preset(Control.PRESET_CENTER)
	textBox.set_anchors_preset(Control.PRESET_CENTER)

	return self  # Return reference to the class so we can call `set_text` later

func set_text(new_text: String):
	if textBox:
		textBox.text = "[center][color=white]" + new_text + "[/color][/center]"
