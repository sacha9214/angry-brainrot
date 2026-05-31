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
var _broken: bool = false

# Santé par matériau (clones Box2D de référence)
const MATERIAL_HEALTH = {
	StructureMaterial.WOOD: 60.0,
	StructureMaterial.STONE: 150.0,
	StructureMaterial.ICE: 40.0
}

# Masse par matériau
const MATERIAL_MASS = {
	StructureMaterial.WOOD: 3.0,
	StructureMaterial.STONE: 8.0,
	StructureMaterial.ICE: 1.5
}

# Seuil d'impulsion d'impact avant de prendre des dégâts
const MATERIAL_IMPACT_THRESHOLD = {
	StructureMaterial.WOOD: 8.0,
	StructureMaterial.STONE: 20.0,
	StructureMaterial.ICE: 5.0
}

# Multiplicateur impulsion -> dégâts (l'ice casse plus vite)
const MATERIAL_DAMAGE_MULT = {
	StructureMaterial.WOOD: 0.5,
	StructureMaterial.STONE: 0.35,
	StructureMaterial.ICE: 0.8
}

# Matériau physique (friction / rebond) par type
const MATERIAL_FRICTION = {
	StructureMaterial.WOOD: 0.3,
	StructureMaterial.STONE: 0.4,
	StructureMaterial.ICE: 0.1
}

const MATERIAL_BOUNCE = {
	StructureMaterial.WOOD: 0.1,
	StructureMaterial.STONE: 0.05,
	StructureMaterial.ICE: 0.3
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
	mass = MATERIAL_MASS[material_type]

	# Anti-tunneling pour les impacts rapides
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE

	# Matériau physique correct
	var pm := PhysicsMaterial.new()
	pm.friction = MATERIAL_FRICTION[material_type]
	pm.bounce = MATERIAL_BOUNCE[material_type]
	physics_material_override = pm

	# Nécessaire pour lire les impulsions de contact dans _integrate_forces
	contact_monitor = true
	max_contacts_reported = 6

	if sprite:
		sprite.modulate = MATERIAL_COLORS[material_type]


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _broken:
		return

	var threshold: float = MATERIAL_IMPACT_THRESHOLD[material_type]
	var mult: float = MATERIAL_DAMAGE_MULT[material_type]
	var total_damage: float = 0.0

	for i in range(state.get_contact_count()):
		var impulse_len := state.get_contact_impulse(i).length()
		if impulse_len > threshold:
			total_damage += impulse_len * mult

	if total_damage > 0.0:
		take_damage(total_damage)


func take_damage(amount: float) -> void:
	if _broken:
		return
	current_health -= amount
	_update_crack_visual()
	if current_health <= 0:
		_break()


func _update_crack_visual() -> void:
	if crack_sprite == null:
		return
	var health_ratio := current_health / max_health
	if health_ratio < 0.6:
		crack_sprite.visible = true
		crack_sprite.modulate.a = 1.0 - health_ratio
	if health_ratio < 0.3:
		crack_sprite.frame = 1  # Heavy crack sprite frame


func _break() -> void:
	if _broken:
		return
	_broken = true

	if break_particles:
		break_particles.emitting = true
	if audio and audio.stream:
		audio.play()

	# Plus de collision/réactivité une fois cassé
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.15)

	await get_tree().create_timer(0.2).timeout
	queue_free()
