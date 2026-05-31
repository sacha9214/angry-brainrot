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

const BIRD_COLORS := [
	Color(0.2, 0.8, 0.3),   # Bombardiro - vert croco
	Color(0.9, 0.7, 0.3),   # Capybara - beige
	Color(0.3, 0.6, 1.0),   # Tralalero - bleu
	Color(0.9, 0.3, 0.3),   # Bombombini - rouge
	Color(0.7, 0.4, 0.9),   # Brr Brr - violet
]


func _ready() -> void:
	win_panel.visible = false
	lose_panel.visible = false
	pause_btn.pressed.connect(_on_pause)
	$WinPanel/Buttons/NextButton.pressed.connect(func(): emit_signal("next_level_requested"))
	$WinPanel/Buttons/RestartButton.pressed.connect(func(): emit_signal("restart_requested"))
	$WinPanel/Buttons/MenuButton.pressed.connect(func(): emit_signal("menu_requested"))
	$LosePanel/Buttons/RestartButton.pressed.connect(func(): emit_signal("restart_requested"))
	$LosePanel/Buttons/MenuButton.pressed.connect(func(): emit_signal("menu_requested"))


func update_score(score: int) -> void:
	score_label.text = str(score)
	score_label.pivot_offset = score_label.size * 0.5
	var tween := create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.35, 1.35), 0.1) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.12) \
		.set_trans(Tween.TRANS_SINE)


func update_birds(count: int) -> void:
	for child in birds_container.get_children():
		child.queue_free()
	for i in range(count):
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(52, 52)
		icon.color = BIRD_COLORS[i % BIRD_COLORS.size()]
		# Rounded look via a child margin is overkill; use a simple square chip
		birds_container.add_child(icon)
		_animate_bird_in(icon, i * 0.05)


func _animate_bird_in(icon: ColorRect, delay: float) -> void:
	icon.scale = Vector2(0.0, 0.0)
	icon.pivot_offset = Vector2(26, 26)
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func show_win(stars: int, score: int) -> void:
	win_panel.visible = true
	$WinPanel/ScoreLabel.text = "Score : " + str(score)
	_pop_panel(win_panel)
	_animate_stars(stars)


func show_lose() -> void:
	lose_panel.visible = true
	_pop_panel(lose_panel)
	await get_tree().create_timer(0.25).timeout
	_shake_panel(lose_panel)


func _pop_panel(panel: Control) -> void:
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.7, 0.7)
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _shake_panel(panel: Control) -> void:
	var base := panel.position
	var tween := create_tween()
	for i in range(6):
		var amp := 18.0 * (1.0 - float(i) / 6.0)
		tween.tween_property(panel, "position:x", base.x + amp, 0.04)
		tween.tween_property(panel, "position:x", base.x - amp, 0.04)
	tween.tween_property(panel, "position:x", base.x, 0.04)


func _animate_stars(stars: int) -> void:
	for i in range(3):
		var star := stars_container.get_child(i) as Label
		star.scale = Vector2(0.3, 0.3)
		star.pivot_offset = star.size * 0.5
		if i < stars:
			star.text = "⭐"
			star.modulate = Color(1.0, 0.8, 0.0)
			await get_tree().create_timer(0.35).timeout
			var tween := create_tween()
			tween.tween_property(star, "scale", Vector2(1.6, 1.6), 0.18) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(star, "scale", Vector2(1.0, 1.0), 0.12) \
				.set_trans(Tween.TRANS_SINE)
		else:
			star.text = "☆"
			star.modulate = Color(0.4, 0.4, 0.45)
			star.scale = Vector2(1.0, 1.0)


func _on_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_btn.text = "▶" if get_tree().paused else "⏸"
