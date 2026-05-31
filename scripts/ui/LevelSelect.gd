extends Control

@onready var grid: GridContainer = $ScrollContainer/GridContainer
@onready var back_btn: Button = $BackButton
@onready var title_label: Label = $Title

const TOTAL_LEVELS := 30
const LEVEL_SCENE_PATH := "res://scenes/levels/Level%02d.tscn"

const ACCENT := Color(0.6, 0.2, 1.0)
const GOLD := Color(1.0, 0.8, 0.0)
const LOCKED := Color(0.18, 0.16, 0.24)


func _ready() -> void:
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn"))
	_animate_title()
	_populate_grid()


func _animate_title() -> void:
	title_label.pivot_offset = title_label.size * 0.5
	var tween := create_tween().set_loops()
	tween.tween_property(title_label, "rotation_degrees", 2.0, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(title_label, "rotation_degrees", -2.0, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _populate_grid() -> void:
	var delay := 0.0
	for i in range(1, TOTAL_LEVELS + 1):
		var btn := _create_level_button(i)
		grid.add_child(btn)
		_animate_button_in(btn, delay)
		delay += 0.04


func _create_level_button(level: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(150, 150)
	btn.add_theme_font_size_override("font_size", 30)

	var unlocked: bool = GameManager.is_level_unlocked(level)
	var stars: int = GameManager.get_level_stars(level)

	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.border_width_bottom = 4
	style.border_width_top = 4
	style.border_width_left = 4
	style.border_width_right = 4

	if unlocked:
		btn.text = str(level) + "\n" + _stars_string(stars)
		style.bg_color = Color(0.12, 0.05, 0.22)
		style.border_color = ACCENT
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.pressed.connect(_on_level_pressed.bind(level))
	else:
		btn.text = "🔒\n" + str(level)
		style.bg_color = LOCKED
		style.border_color = Color(0.3, 0.28, 0.36)
		btn.add_theme_color_override("font_color", Color(0.5, 0.48, 0.55))
		btn.disabled = true

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("disabled", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.2, 0.08, 0.34)
	hover.border_color = GOLD
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)

	return btn


func _animate_button_in(btn: Button, delay: float) -> void:
	btn.modulate.a = 0.0
	btn.scale = Vector2(0.5, 0.5)
	btn.pivot_offset = btn.custom_minimum_size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(btn, "modulate:a", 1.0, 0.3).set_delay(delay)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.4) \
		.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _stars_string(stars: int) -> String:
	var s := ""
	for i in range(3):
		s += "⭐" if i < stars else "☆"
	return s


func _on_level_pressed(level: int) -> void:
	var path: String = LEVEL_SCENE_PATH % level
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		get_tree().change_scene_to_file("res://scenes/levels/Level01.tscn")
