extends Control

@onready var grid: GridContainer = $ScrollContainer/GridContainer
@onready var back_btn: Button = $BackButton

const TOTAL_LEVELS = 30
const LEVEL_SCENE_PATH = "res://scenes/levels/Level%02d.tscn"


func _ready() -> void:
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn"))
	_populate_grid()


func _populate_grid() -> void:
	for i in range(1, TOTAL_LEVELS + 1):
		var btn = _create_level_button(i)
		grid.add_child(btn)


func _create_level_button(level: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(150, 150)

	var unlocked = GameManager.is_level_unlocked(level)
	var stars = GameManager.get_level_stars(level)

	if unlocked:
		btn.text = str(level) + "\n" + _stars_string(stars)
		btn.pressed.connect(_on_level_pressed.bind(level))
	else:
		btn.text = "🔒"
		btn.disabled = true

	return btn


func _stars_string(stars: int) -> String:
	var s = ""
	for i in range(3):
		s += "⭐" if i < stars else "☆"
	return s


func _on_level_pressed(level: int) -> void:
	var path = LEVEL_SCENE_PATH % level
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		# Fallback to level 1 template if specific level doesn't exist yet
		get_tree().change_scene_to_file("res://scenes/levels/Level01.tscn")
