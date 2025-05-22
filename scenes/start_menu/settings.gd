extends Control

@onready var musicBusID = AudioServer.get_bus_index("music")
@onready var sfxBusID = AudioServer.get_bus_index("sfx")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("SettingsPanel/SettingsBox/MusicVolumeSlider").value = db_to_linear(AudioServer.get_bus_volume_db(musicBusID))
	get_node("SettingsPanel/SettingsBox/SfxVolumeSlider").value = db_to_linear(AudioServer.get_bus_volume_db(sfxBusID))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	get_parent().get_node("ButtonClickSound").play()
	get_parent().transition("Menu")


func _on_button_hover() -> void:
	get_parent().get_node("ButtonHoverSound").play()


func _on_music_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(musicBusID, linear_to_db(value))
	AudioServer.set_bus_mute(musicBusID, value < 0.05)


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfxBusID, linear_to_db(value))
	AudioServer.set_bus_mute(sfxBusID, value < 0.05)
