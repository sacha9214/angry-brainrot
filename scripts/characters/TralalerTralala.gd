extends BaseCharacter

# Tralalero Tralala — rebondit 3x sur les surfaces, chaque rebond = dégâts + son
# "Il est un requin avec des Nike qui chante TRALALALERO TRALALA"

@export var bounce_damage: float = 35.0
@export var max_bounces: int = 3
@export var bounce_boost: float = 1.2

var bounce_count: int = 0


func _ready() -> void:
	super._ready()
	character_id = "tralalero"
	ability_name = "TRALALALERO!!!"
	ability_description = "Rebondit 3 fois en chantant — TRALALA"
	# Physique très rebondissante (bounce=0.85, friction=0.1) définie dans TralalerTralala.tscn


func _on_body_entered(body: Node) -> void:
	if not launched:
		return
	if bounce_count >= max_bounces:
		return

	bounce_count += 1
	_play_bounce_sound()
	_spawn_bounce_particles()

	if body.is_in_group("structures") or body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(bounce_damage * (1.0 + bounce_count * 0.2))

	# Boost velocity on each bounce
	linear_velocity *= bounce_boost

	if bounce_count >= max_bounces:
		await get_tree().create_timer(1.5).timeout
		queue_free()


func _play_bounce_sound() -> void:
	if audio and audio.stream:
		# Pitch up on each bounce
		audio.pitch_scale = 1.0 + (bounce_count * 0.15)
		audio.play()


func _spawn_bounce_particles() -> void:
	if particles:
		# Color changes each bounce
		var colors = [Color.CYAN, Color.YELLOW, Color.HOT_PINK]
		particles.modulate = colors[min(bounce_count - 1, 2)]
		particles.emitting = true
