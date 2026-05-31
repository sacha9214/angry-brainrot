extends BaseCharacter

# Brr Brr Patapim — se divise en 3 projectiles en plein vol
# "Il est une créature chaos qui se multiplie comme des araignées"
# IAP $1.99

@export var split_count: int = 3
@export var split_spread_angle: float = 25.0
@export var split_damage: float = 30.0

var has_split: bool = false


func _ready() -> void:
	super._ready()
	character_id = "brrbrr"
	ability_name = "BRR BRR SPLIT!"
	ability_description = "Tap pour se diviser en 3 — PATAPIM"


func use_ability() -> void:
	if has_split:
		return
	super.use_ability()
	has_split = true
	_split()


func _split() -> void:
	var current_vel = linear_velocity
	var current_pos = global_position

	# Hide self
	if sprite:
		sprite.visible = false
	collision_layer = 0
	collision_mask = 0

	# Spawn 3 mini versions
	for i in range(split_count):
		var angle_offset = (i - 1) * deg_to_rad(split_spread_angle)
		var rotated_vel = current_vel.rotated(angle_offset)

		var mini = _create_mini_projectile(current_pos, rotated_vel)
		get_parent().add_child(mini)

	_play_sound()
	_spawn_particles()
	queue_free()


func _create_mini_projectile(pos: Vector2, vel: Vector2) -> RigidBody2D:
	var mini = RigidBody2D.new()
	mini.add_to_group("characters")

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 18.0
	col.shape = shape
	mini.add_child(col)

	var spr = Sprite2D.new()
	spr.scale = Vector2(0.5, 0.5)
	mini.add_child(spr)

	mini.global_position = pos
	mini.linear_velocity = vel * 0.9
	mini.contact_monitor = true
	mini.max_contacts_reported = 2

	# Auto-damage on contact
	mini.body_entered.connect(func(body):
		if body.has_method("take_damage"):
			body.take_damage(split_damage)
		mini.queue_free()
	)

	# Auto cleanup
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(mini): mini.queue_free()
	)

	return mini
