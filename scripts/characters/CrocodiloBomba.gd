extends BaseCharacter

# Crocodilo Bomba — explose à l'impact, détruit un rayon autour de lui

@export var explosion_radius: float = 150.0
@export var explosion_damage: float = 80.0
@export var explosion_force: float = 500.0

@onready var explosion_area: Area2D = $ExplosionArea
@onready var explosion_particles: GPUParticles2D = $ExplosionParticles


func _ready() -> void:
	super._ready()
	character_id = "crocodilo"
	ability_name = "BWAAAH BOOM"
	ability_description = "Explose en touchant n'importe quoi"
	has_ability = false  # L'explosion est automatique à l'impact


func _on_body_entered(body: Node) -> void:
	if not launched:
		return
	_explode()


func _explode() -> void:
	if ability_used:
		return
	ability_used = true

	_play_sound()

	# Flash visuel
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 0.3, 0, 1), 0.05)
		tween.tween_property(sprite, "scale", Vector2(2.5, 2.5), 0.1)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.15)

	# Explosion area
	if explosion_area:
		var shape = explosion_area.get_child(0) as CollisionShape2D
		if shape:
			(shape.shape as CircleShape2D).radius = explosion_radius

		for body in explosion_area.get_overlapping_bodies():
			var dir = (body.global_position - global_position).normalized()
			var dist = global_position.distance_to(body.global_position)
			var falloff = 1.0 - clamp(dist / explosion_radius, 0.0, 1.0)

			if body.is_in_group("structures") or body.is_in_group("enemies"):
				if body.has_method("take_damage"):
					body.take_damage(explosion_damage * falloff)
				if body is RigidBody2D:
					body.apply_central_impulse(dir * explosion_force * falloff)

	if explosion_particles:
		explosion_particles.emitting = true

	await get_tree().create_timer(0.3).timeout
	queue_free()
