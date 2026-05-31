extends BaseCharacter

# Capybara Chill — traverse les structures sans s'arrêter, dégâts constants

@export var pierce_damage: float = 40.0
@export var max_pierces: int = 5

var pierce_count: int = 0
var pierced_bodies: Array = []


func _ready() -> void:
	super._ready()
	character_id = "capybara"
	ability_name = "ULTRA CHILL"
	ability_description = "Tap pour accélérer"
	# Physique spéciale : moins de friction
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.0
	physics_material_override.bounce = 0.0


func use_ability() -> void:
	super.use_ability()
	# Boost de vitesse au tap
	var current_vel = linear_velocity
	linear_velocity = current_vel * 1.8
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.5, 1.0, 0.5, 1), 0.1)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.2)


func _on_body_entered(body: Node) -> void:
	if not launched:
		return
	if body in pierced_bodies:
		return

	pierced_bodies.append(body)

	if body.is_in_group("structures"):
		if body.has_method("take_damage"):
			body.take_damage(pierce_damage)
		pierce_count += 1
		_play_sound()
		_spawn_particles()

		if pierce_count >= max_pierces:
			await get_tree().create_timer(1.0).timeout
			queue_free()

	elif body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(pierce_damage * 2)
		_on_hit_enemy(body)

	elif body.is_in_group("ground"):
		_on_hit_ground()
