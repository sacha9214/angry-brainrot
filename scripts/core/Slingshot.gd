extends Node2D

signal character_launched(character: RigidBody2D, velocity: Vector2)
signal drag_started()
signal drag_ended()

@export var max_drag_distance: float = 120.0
@export var launch_power: float = 14.0
@export var trajectory_points: int = 30
@export var trajectory_interval: float = 0.05

@onready var anchor: Node2D = $Anchor
@onready var trajectory_line: Line2D = $TrajectoryLine
@onready var left_band: Line2D = $LeftBand
@onready var right_band: Line2D = $RightBand

var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var current_character: RigidBody2D = null
var characters_queue: Array = []


func _ready() -> void:
	trajectory_line.clear_points()


func _input(event: InputEvent) -> void:
	if current_character == null:
		return

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed = event.pressed if event is InputEventMouseButton else event.pressed
		var position = event.position

		if pressed:
			is_dragging = true
			drag_start = position
			emit_signal("drag_started")
		else:
			if is_dragging:
				_launch_character()

	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if is_dragging:
			_update_drag(event.position)


func _update_drag(touch_pos: Vector2) -> void:
	var anchor_screen = anchor.get_global_transform_with_canvas().origin
	var drag_vector = touch_pos - anchor_screen
	drag_vector = drag_vector.limit_length(max_drag_distance)

	current_character.global_position = anchor.global_position + drag_vector

	_update_bands(current_character.global_position)
	_draw_trajectory(drag_vector)


func _draw_trajectory(drag_vector: Vector2) -> void:
	trajectory_line.clear_points()
	var launch_velocity = -drag_vector * launch_power
	var pos = anchor.global_position
	var vel = launch_velocity
	var gravity = Vector2(0, ProjectSettings.get_setting("physics/2d/default_gravity"))

	for i in range(trajectory_points):
		trajectory_line.add_point(to_local(pos))
		vel += gravity * trajectory_interval
		pos += vel * trajectory_interval


func _launch_character() -> void:
	if current_character == null:
		return

	is_dragging = false
	var anchor_screen = anchor.get_global_transform_with_canvas().origin
	var drag_vector = current_character.global_position - anchor.global_position
	drag_vector = drag_vector.limit_length(max_drag_distance)

	var launch_velocity = -drag_vector * launch_power
	current_character.linear_velocity = launch_velocity
	current_character.freeze = false

	emit_signal("character_launched", current_character, launch_velocity)
	trajectory_line.clear_points()
	_reset_bands()
	current_character = null

	await get_tree().create_timer(1.5).timeout
	_load_next_character()


func _update_bands(char_pos: Vector2) -> void:
	var local_pos = to_local(char_pos)
	left_band.clear_points()
	left_band.add_point(Vector2(-15, 0))
	left_band.add_point(local_pos)
	right_band.clear_points()
	right_band.add_point(Vector2(15, 0))
	right_band.add_point(local_pos)


func _reset_bands() -> void:
	left_band.clear_points()
	left_band.add_point(Vector2(-15, 0))
	left_band.add_point(Vector2(0, 0))
	right_band.clear_points()
	right_band.add_point(Vector2(15, 0))
	right_band.add_point(Vector2(0, 0))


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
