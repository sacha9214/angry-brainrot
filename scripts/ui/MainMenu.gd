extends Control

@onready var play_btn: Button = $ButtonsPanel/VBoxContainer/PlayButton
@onready var shop_btn: Button = $ButtonsPanel/VBoxContainer/ShopButton
@onready var settings_btn: Button = $ButtonsPanel/VBoxContainer/SettingsButton
@onready var title_label: Label = $TitleLabel
@onready var bg_top: ColorRect = $BackgroundGradient/Top
@onready var bg_bottom: ColorRect = $BackgroundGradient/Bottom
@onready var characters: HBoxContainer = $CharactersRow

const ACCENT := Color(0.6, 0.2, 1.0)
const GOLD := Color(1.0, 0.8, 0.0)


func _ready() -> void:
	play_btn.pressed.connect(_on_play_pressed)
	shop_btn.pressed.connect(_on_shop_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)

	_animate_title()
	_animate_background()
	_animate_characters()
	_setup_buttons()


func _animate_title() -> void:
	title_label.pivot_offset = title_label.size * 0.5
	var tween := create_tween().set_loops()
	tween.tween_property(title_label, "rotation_degrees", 3.0, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(title_label, "scale", Vector2(1.06, 1.06), 0.25) \
		.set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(title_label, "rotation_degrees", -3.0, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.25) \
		.set_trans(Tween.TRANS_SINE)


func _animate_background() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(bg_top, "color", Color(0.18, 0.04, 0.32, 1.0), 3.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(bg_bottom, "color", Color(0.05, 0.02, 0.15, 1.0), 3.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(bg_top, "color", Color(0.10, 0.02, 0.22, 1.0), 3.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(bg_bottom, "color", Color(0.02, 0.01, 0.08, 1.0), 3.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _animate_characters() -> void:
	var delay := 0.0
	for child in characters.get_children():
		var label := child as Label
		if label == null:
			continue
		var base_y := label.position.y
		var tween := create_tween().set_loops()
		tween.tween_interval(delay)
		tween.tween_property(label, "position:y", base_y - 24.0, 0.8) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(label, "position:y", base_y, 0.8) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		delay += 0.2


func _setup_buttons() -> void:
	for btn in [play_btn, shop_btn, settings_btn]:
		btn.pivot_offset = btn.size * 0.5
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))


func _on_button_hover(btn: Button) -> void:
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(btn, "modulate", Color(1.25, 1.15, 1.4), 0.12)


func _on_button_unhover(btn: Button) -> void:
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12) \
		.set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(btn, "modulate", Color(1, 1, 1), 0.12)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/LevelSelect.tscn")


func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Shop.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Settings.tscn")
