extends RigidBody2D
class_name Structure

enum StructureMaterial { WOOD, STONE, ICE }

@export var material_type: StructureMaterial = StructureMaterial.WOOD
@export var max_health: float = 100.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var crack_sprite: Sprite2D = $CrackSprite
@onready var break_particles: GPUParticles2D = $BreakParticles
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

var current_health: float = 100.0

# Damage multipliers per material
const MATERIAL_HEALTH = {
	StructureMaterial.WOOD: 60.0,
	StructureMaterial.STONE: 150.0,
	StructureMaterial.ICE: 40.0
}

const MATERIAL_COLORS = {
	StructureMaterial.WOOD: Color(0.76, 0.52, 0.25),
	StructureMaterial.STONE: Color(0.55, 0.55, 0.55),
	StructureMaterial.ICE: Color(0.65, 0.85, 1.0, 0.85)
}


func _ready() -> void:
	add_to_group("structures")
	max_health = MATERIAL_HEALTH[material_type]
	current_health = max_health
	if sprite:
		sprite.modulate = MATERIAL_COLORS[material_type]


func take_damage(amount: float) -> void:
	current_health -= amount
	_update_crack_visual()
	if current_health <= 0:
		_break()


func _update_crack_visual() -> void:
	if crack_sprite == null:
		return
	var health_ratio = current_health / max_health
	if health_ratio < 0.6:
		crack_sprite.visible = true
		crack_sprite.modulate.a = 1.0 - health_ratio
	if health_ratio < 0.3:
		crack_sprite.frame = 1  # Heavy crack sprite frame


func _break() -> void:
	if break_particles:
		break_particles.emitting = true
	if audio and audio.stream:
		audio.play()

	# Small impulse to scatter debris feel
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.15)

	await get_tree().create_timer(0.2).timeout
	queue_free()
