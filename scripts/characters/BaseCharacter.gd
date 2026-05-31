extends RigidBody2D
class_name BaseCharacter

# Override these in each character script
@export var character_id: String = "base"
@export var ability_name: String = "None"
@export var ability_description: String = ""

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var particles: GPUParticles2D = $Particles
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

var ability_used: bool = false
var has_ability: bool = true
var launched: bool = false


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)


func _input(event: InputEvent) -> void:
	if not launched or ability_used or not has_ability:
		return
	if event is InputEventScreenTouch and event.pressed:
		use_ability()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		use_ability()


func on_launched() -> void:
	launched = true


# Override in subclass
func use_ability() -> void:
	ability_used = true
	_play_sound()
	_spawn_particles()


func _on_body_entered(body: Node) -> void:
	if not launched:
		return
	if body.is_in_group("structures"):
		_on_hit_structure(body)
	elif body.is_in_group("enemies"):
		_on_hit_enemy(body)
	elif body.is_in_group("ground"):
		_on_hit_ground()


func _on_hit_structure(structure: Node) -> void:
	_play_sound()
	_spawn_particles()


func _on_hit_enemy(enemy: Node) -> void:
	_play_sound()
	_spawn_particles()
	enemy.take_damage(get_impact_damage())


func _on_hit_ground() -> void:
	_play_sound()
	_spawn_particles()
	await get_tree().create_timer(2.0).timeout
	queue_free()


func get_impact_damage() -> float:
	return linear_velocity.length() * 0.5


func _play_sound() -> void:
	if audio and audio.stream:
		audio.play()


func _spawn_particles() -> void:
	if particles:
		particles.emitting = true
