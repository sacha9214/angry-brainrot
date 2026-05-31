extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var birds_container: HBoxContainer = $BirdsContainer
@onready var pause_btn: Button = $PauseButton
@onready var win_panel: Control = $WinPanel
@onready var lose_panel: Control = $LosePanel
@onready var stars_container: HBoxContainer = $WinPanel/StarsContainer

signal restart_requested()
signal menu_requested()
signal next_level_requested()


func _ready() -> void:
	win_panel.visible = false
	lose_panel.visible = false
	pause_btn.pressed.connect(_on_pause)
	$WinPanel/NextButton.pressed.connect(func(): emit_signal("next_level_requested"))
	$WinPanel/MenuButton.pressed.connect(func(): emit_signal("menu_requested"))
	$LosePanel/RestartButton.pressed.connect(func(): emit_signal("restart_requested"))
	$LosePanel/MenuButton.pressed.connect(func(): emit_signal("menu_requested"))


func update_score(score: int) -> void:
	score_label.text = str(score)
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)


func update_birds(count: int) -> void:
	for child in birds_container.get_children():
		child.queue_free()
	for i in range(count):
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		birds_container.add_child(icon)


func show_win(stars: int, score: int) -> void:
	win_panel.visible = true
	$WinPanel/ScoreLabel.text = "Score: " + str(score)
	_animate_stars(stars)


func show_lose() -> void:
	lose_panel.visible = true


func _animate_stars(stars: int) -> void:
	for i in range(3):
		var star = stars_container.get_child(i)
		if i < stars:
			await get_tree().create_timer(0.3 * i).timeout
			var tween = create_tween()
			tween.tween_property(star, "scale", Vector2(1.5, 1.5), 0.15)
			tween.tween_property(star, "scale", Vector2(1.0, 1.0), 0.1)
			star.modulate = Color.YELLOW
		else:
			star.modulate = Color(0.4, 0.4, 0.4)


func _on_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_btn.text = "▶" if get_tree().paused else "⏸"
