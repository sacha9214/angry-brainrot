extends Node

# Singleton - autoload as "GameManager"

signal level_completed(stars: int)
signal game_over()

var current_level: int = 1
var total_levels: int = 30
var save_data: Dictionary = {}

const SAVE_PATH = "user://savegame.json"

# IAP product IDs (Google Play Billing v6)
const IAP_REMOVE_ADS       = "remove_ads"
const IAP_CHAR_BOMBOMBINI  = "char_bombombini_gusini"   # $0.99
const IAP_CHAR_BRRBRR      = "char_brr_brr_patapim"     # $1.99
const IAP_POWERUP_PACK     = "powerup_pack_5"            # $0.99
const IAP_EPISODE_2        = "episode_pack_2"            # $1.99

var ads_removed: bool = false
# Free chars: Bombardiro Crocodilo, Capybara Chill, Tralalero Tralala
var unlocked_characters: Array = ["bombardiro", "capybara", "tralalero"]
var powerups: Dictionary = {"super_speed": 0, "extra_bird": 0, "earthquake": 0}


func _ready() -> void:
	load_save()


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_data = {
			"stars": {},
			"unlocked_chars": ["bombardiro", "capybara", "tralalero"],
			"ads_removed": false,
			"powerups": {"super_speed": 0, "extra_bird": 0, "earthquake": 0},
			"max_level": 1
		}
		save_game()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	save_data = JSON.parse_string(file.get_as_text())
	file.close()

	ads_removed = save_data.get("ads_removed", false)
	unlocked_characters = save_data.get("unlocked_chars", ["bombardiro", "capybara", "tralalero"])
	powerups = save_data.get("powerups", {"super_speed": 0, "extra_bird": 0, "earthquake": 0})


func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()


func get_level_stars(level: int) -> int:
	return save_data.get("stars", {}).get(str(level), 0)


func set_level_stars(level: int, stars: int) -> void:
	if not save_data.has("stars"):
		save_data["stars"] = {}
	var key = str(level)
	if stars > save_data["stars"].get(key, 0):
		save_data["stars"][key] = stars
	if level + 1 > save_data.get("max_level", 1):
		save_data["max_level"] = level + 1
	save_game()


func is_level_unlocked(level: int) -> bool:
	return level <= save_data.get("max_level", 1)


func is_character_unlocked(char_id: String) -> bool:
	return char_id in unlocked_characters


func use_powerup(powerup_id: String) -> bool:
	if powerups.get(powerup_id, 0) > 0:
		powerups[powerup_id] -= 1
		save_data["powerups"] = powerups
		save_game()
		return true
	return false
