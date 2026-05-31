extends Control

@onready var music_slider: HSlider = $Panel/VBox/MusicRow/MusicSlider
@onready var music_value: Label = $Panel/VBox/MusicRow/MusicValue
@onready var sfx_slider: HSlider = $Panel/VBox/SfxRow/SfxSlider
@onready var sfx_value: Label = $Panel/VBox/SfxRow/SfxValue
@onready var vibration_toggle: CheckButton = $Panel/VBox/VibrationRow/VibrationToggle
@onready var back_btn: Button = $BackButton
@onready var title_label: Label = $TitleLabel


func _ready() -> void:
	_load_settings()

	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	vibration_toggle.toggled.connect(_on_vibration_toggled)
	back_btn.pressed.connect(_on_back_pressed)

	_animate_title()
	_animate_intro()


func _load_settings() -> void:
	var music: float = float(GameManager.save_data.get("music_volume", 80))
	var sfx: float = float(GameManager.save_data.get("sfx_volume", 100))
	var vibration: bool = bool(GameManager.save_data.get("vibration", true))

	music_slider.value = music
	sfx_slider.value = sfx
	vibration_toggle.button_pressed = vibration

	music_value.text = str(int(music)) + "%"
	sfx_value.text = str(int(sfx)) + "%"


func _animate_title() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(title_label, "rotation_degrees", 2.0, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(title_label, "rotation_degrees", -2.0, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _animate_intro() -> void:
	var panel := $Panel
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.85, 0.85)
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.35)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_music_changed(value: float) -> void:
	music_value.text = str(int(value)) + "%"
	GameManager.save_data["music_volume"] = value
	_apply_bus_volume("Music", value)
	GameManager.save_game()


func _on_sfx_changed(value: float) -> void:
	sfx_value.text = str(int(value)) + "%"
	GameManager.save_data["sfx_volume"] = value
	_apply_bus_volume("SFX", value)
	GameManager.save_game()


func _on_vibration_toggled(pressed: bool) -> void:
	GameManager.save_data["vibration"] = pressed
	GameManager.save_game()


func _apply_bus_volume(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	if value <= 0.0:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(value / 100.0))


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
