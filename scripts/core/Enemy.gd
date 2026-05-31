extends RigidBody2D
class_name Enemy

@export var max_health: float = 50.0
@export var score_value: int = 500

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var defeat_particles: GPUParticles2D = $DefeatParticles

var current_health: float = 50.0

signal enemy_defeated(score: int)


func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health


func take_damage(amount: float) -> void:
	current_health -= amount

	# Flinch animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.05)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)

	if health_bar:
		health_bar.value = (current_health / max_health) * 100.0

	if current_health <= 0:
		_defeat()


func _defeat() -> void:
	if audio and audio.stream:
		audio.play()
	if defeat_particles:
		defeat_particles.emitting = true

	emit_signal("enemy_defeated", score_value)

	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.1)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.2)

	await get_tree().create_timer(0.3).timeout
	queue_free()
