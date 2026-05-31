extends Node
class_name LevelManager

signal level_won(stars: int, score: int)
signal level_lost()
signal score_changed(new_score: int)
signal birds_remaining_changed(count: int)

@export var level_number: int = 1
@export var characters_in_level: Array[PackedScene] = []
@export var time_limit: float = 0.0  # 0 = no limit

@onready var slingshot: Node2D = $Slingshot
@onready var enemies_container: Node2D = $Enemies
@onready var score_label: Label = $HUD/ScoreLabel

var total_score: int = 0
var enemies_remaining: int = 0
var birds_remaining: int = 0
var level_ended: bool = false

# Bonus points
const BONUS_PER_UNUSED_BIRD: int = 3000
const STAR_THRESHOLDS: Array = [0.33, 0.66, 1.0]  # fraction of max score


func _ready() -> void:
	enemies_remaining = enemies_container.get_child_count()
	birds_remaining = characters_in_level.size()

	for enemy in enemies_container.get_children():
		enemy.enemy_defeated.connect(_on_enemy_defeated)

	slingshot.character_launched.connect(_on_character_launched)
	slingshot.drag_ended.connect(_on_no_more_birds)
	slingshot.load_characters(characters_in_level)

	emit_signal("birds_remaining_changed", birds_remaining)


func _on_enemy_defeated(score: int) -> void:
	total_score += score
	emit_signal("score_changed", total_score)
	enemies_remaining -= 1

	if enemies_remaining <= 0:
		_win()


func _on_character_launched(_char, _vel) -> void:
	birds_remaining -= 1
	emit_signal("birds_remaining_changed", birds_remaining)


func _on_no_more_birds() -> void:
	if enemies_remaining > 0 and not level_ended:
		await get_tree().create_timer(2.0).timeout
		_lose()


func _win() -> void:
	if level_ended:
		return
	level_ended = true

	total_score += birds_remaining * BONUS_PER_UNUSED_BIRD
	emit_signal("score_changed", total_score)

	var stars = _calculate_stars()
	GameManager.set_level_stars(level_number, stars)
	await get_tree().create_timer(1.5).timeout
	emit_signal("level_won", stars, total_score)


func _lose() -> void:
	if level_ended:
		return
	level_ended = true
	await get_tree().create_timer(1.0).timeout
	emit_signal("level_lost")


func _calculate_stars() -> int:
	# Stars based on score vs enemies killed ratio + unused birds
	if enemies_remaining == 0 and birds_remaining == characters_in_level.size() - 1:
		return 3
	elif enemies_remaining == 0 and birds_remaining > 0:
		return 2
	elif enemies_remaining == 0:
		return 1
	return 0
