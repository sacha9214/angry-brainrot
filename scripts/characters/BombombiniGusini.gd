extends BaseCharacter

# Bombombini Gusini — l'oie aux bombes, tourne sur elle-même et détruit la pierre
# "Il est une oie qui porte des bombes et tourne comme une toupie"
# IAP $0.99

@export var spin_damage: float = 60.0
@export var spin_radius: float = 80.0
@export var spin_duration: float = 1.5

var is_spinning: bool = false


func _ready() -> void:
	super._ready()
	character_id = "bombombini"
	ability_name = "BOMBOMBINI SPIN!"
	ability_description = "Tap pour tourner comme une folle"


func use_ability() -> void:
	if is_spinning:
		return
	super.use_ability()
	is_spinning = true
	_start_spin()


func _start_spin() -> void:
	# Visual spin
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "rotation", sprite.rotation + TAU * 3, spin_duration)

	# Area damage during spin — hits everything nearby each 0.2s
	var timer = 0.0
	while timer < spin_duration:
		await get_tree().create_timer(0.2).timeout
		timer += 0.2
		_spin_damage_nearby()

	is_spinning = false
	await get_tree().create_timer(0.5).timeout
	queue_free()


func _spin_damage_nearby() -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = spin_radius
	query.shape = circle
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 0b11  # structures + enemies layers

	var results = space_state.intersect_shape(query)
	for result in results:
		var body = result.collider
		if body != self and body.has_method("take_damage"):
			body.take_damage(spin_damage * 0.2)
		if body is RigidBody2D and body != self:
			var dir = (body.global_position - global_position).normalized()
			body.apply_central_impulse(dir * 200)

	_spawn_particles()
