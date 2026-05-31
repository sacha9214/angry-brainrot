extends Control

@onready var play_btn: Button = $VBoxContainer/PlayButton
@onready var shop_btn: Button = $VBoxContainer/ShopButton
@onready var settings_btn: Button = $VBoxContainer/SettingsButton
@onready var title_label: Label = $TitleLabel


func _ready() -> void:
	play_btn.pressed.connect(_on_play_pressed)
	shop_btn.pressed.connect(_on_shop_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	_animate_title()


func _animate_title() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(title_label, "rotation_degrees", 3.0, 0.5)
	tween.tween_property(title_label, "rotation_degrees", -3.0, 0.5)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/LevelSelect.tscn")


func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Shop.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Settings.tscn")
