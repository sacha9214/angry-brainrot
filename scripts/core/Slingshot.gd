extends Node2D

signal character_launched(character: RigidBody2D, velocity: Vector2)
signal drag_started()
signal drag_ended()

# --- Physique calquée sur les clones Angry Birds Box2D ---
# Scale: 50px = 1m, gravity 980 px/s²
@export var max_drag_distance: float = 130.0
@export var launch_force: float = 22.0
@export var trajectory_points: int = 40
@export var trajectory_interval: float = 0.04

# Anchor local au noeud Slingshot
const ANCHOR_OFFSET := Vector2(0, -40)

# Détection d'arrêt de l'oiseau
const STOP_VELOCITY_THRESHOLD: float = 5.0
const STOP_TIME: float = 3.0

@onready var anchor: Node2D = $Anchor
@onready var trajectory_line: Line2D = $TrajectoryLine
@onready var left_band: Line2D = $LeftBand
@onready var right_band: Line2D = $RightBand

var is_dragging: bool = false
var current_character: RigidBody2D = null
var characters_queue: Array = []

# Suivi de l'oiseau lancé pour charger le suivant
var launched_character: RigidBody2D = null
var stop_timer: float = 0.0
var waiting_for_stop: bool = false


func _ready() -> void:
	anchor.position = ANCHOR_OFFSET
	trajectory_line.clear_points()
	_reset_bands()


func _process(delta: float) -> void:
	if not waiting_for_stop:
		return
	if launched_character == null or not is_instance_valid(launched_character):
		waiting_for_stop = false
		_load_next_character()
		return

	if launched_character.linear_velocity.length() < STOP_VELOCITY_THRESHOLD:
		stop_timer += delta
		if stop_timer >= STOP_TIME:
			waiting_for_stop = false
			launched_character = null
			_load_next_character()
	else:
		stop_timer = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if current_character == null:
		return

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
			return

		if event.pressed:
			_start_drag(event.position)
		elif is_dragging:
			_launch_character()

	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if is_dragging:
			_update_drag(event.position)


func _start_drag(screen_pos: Vector2) -> void:
	# On ne démarre le drag que si on attrape près de l'oiseau / de l'ancre
	var anchor_screen := anchor.get_global_transform_with_canvas().origin
	if screen_pos.distance_to(anchor_screen) > max_drag_distance * 2.0:
		return
	is_dragging = true
	current_character.freeze = true
	emit_signal("drag_started")
	_update_drag(screen_pos)


func _get_drag_vector(screen_pos: Vector2) -> Vector2:
	# Vecteur ancre -> doigt, exprimé en coordonnées monde, borné à max_drag_distance
	var anchor_screen := anchor.get_global_transform_with_canvas().origin
	var drag_vector := screen_pos - anchor_screen
	return drag_vector.limit_length(max_drag_distance)


func _update_drag(screen_pos: Vector2) -> void:
	var drag_vector := _get_drag_vector(screen_pos)
	current_character.global_position = anchor.global_position + drag_vector

	_update_bands(current_character.global_position)
	_draw_trajectory(drag_vector)


func _draw_trajectory(drag_vector: Vector2) -> void:
	trajectory_line.clear_points()
	if current_character == null:
		return

	# Vitesse initiale = impulsion / masse (apply_central_impulse)
	var impulse := -drag_vector.normalized() * launch_force * drag_vector.length()
	var mass: float = current_character.mass if current_character.mass > 0.0 else 1.0
	var v0 := impulse / mass

	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	var origin := anchor.global_position

	# Equations balistiques: x = v0x*t, y = v0y*t + 0.5*g*t²
	for i in range(trajectory_points):
		var t := i * trajectory_interval
		var px := origin.x + v0.x * t
		var py := origin.y + v0.y * t + 0.5 * gravity * t * t
		trajectory_line.add_point(to_local(Vector2(px, py)))


func _launch_character() -> void:
	if current_character == null:
		return

	is_dragging = false
	var drag_vector := current_character.global_position - anchor.global_position
	drag_vector = drag_vector.limit_length(max_drag_distance)

	var bird := current_character
	bird.freeze = false

	# apply_central_impulse — direction opposée au drag, magnitude proportionnelle
	var impulse := -drag_vector.normalized() * launch_force * drag_vector.length()
	bird.apply_central_impulse(impulse)

	if bird.has_method("on_launched"):
		bird.on_launched()

	var launch_velocity := impulse / (bird.mass if bird.mass > 0.0 else 1.0)
	emit_signal("character_launched", bird, launch_velocity)

	trajectory_line.clear_points()
	_reset_bands()

	current_character = null
	launched_character = bird
	stop_timer = 0.0
	waiting_for_stop = true


func _update_bands(char_pos: Vector2) -> void:
	var local_pos := to_local(char_pos)
	left_band.clear_points()
	left_band.add_point(to_local(anchor.global_position) + Vector2(-15, 0))
	left_band.add_point(local_pos)
	right_band.clear_points()
	right_band.add_point(to_local(anchor.global_position) + Vector2(15, 0))
	right_band.add_point(local_pos)


func _reset_bands() -> void:
	var anchor_local := to_local(anchor.global_position)
	left_band.clear_points()
	left_band.add_point(anchor_local + Vector2(-15, 0))
	left_band.add_point(anchor_local)
	right_band.clear_points()
	right_band.add_point(anchor_local + Vector2(15, 0))
	right_band.add_point(anchor_local)


func load_characters(char_scenes: Array) -> void:
	characters_queue = char_scenes.duplicate()
	_load_next_character()


func _load_next_character() -> void:
	if characters_queue.is_empty():
		emit_signal("drag_ended")
		return

	var scene = characters_queue.pop_front()
	current_character = scene.instantiate()
	get_parent().add_child(current_character)
	current_character.global_position = anchor.global_position
	current_character.freeze = true
	_reset_bands()
