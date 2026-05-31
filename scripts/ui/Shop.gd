extends Control

# Google Play Billing v6 — IAP with parental gate (COPPA 2.0 compliant)

@onready var parental_gate: Control = $ParentalGate
@onready var gate_question: Label = $ParentalGate/QuestionLabel
@onready var gate_input: LineEdit = $ParentalGate/AnswerInput
@onready var gate_confirm: Button = $ParentalGate/ConfirmButton
@onready var gate_cancel: Button = $ParentalGate/CancelButton

var pending_product_id: String = ""
var gate_answer: int = 0


func _ready() -> void:
	parental_gate.visible = false
	gate_confirm.pressed.connect(_on_gate_confirmed)
	gate_cancel.pressed.connect(func(): parental_gate.visible = false)
	_setup_shop_items()


func _setup_shop_items() -> void:
	# Connect each buy button to parental gate
	$Items/RemoveAds/BuyButton.pressed.connect(func(): _show_parental_gate(GameManager.IAP_REMOVE_ADS))
	$Items/BombombiniChar/BuyButton.pressed.connect(func(): _show_parental_gate(GameManager.IAP_CHAR_BOMBOMBINI))
	$Items/BrrBrrChar/BuyButton.pressed.connect(func(): _show_parental_gate(GameManager.IAP_CHAR_BRRBRR))
	$Items/PowerupPack/BuyButton.pressed.connect(func(): _show_parental_gate(GameManager.IAP_POWERUP_PACK))
	$Items/Episode2/BuyButton.pressed.connect(func(): _show_parental_gate(GameManager.IAP_EPISODE_2))


func _show_parental_gate(product_id: String) -> void:
	# Simple math question — COPPA parental gate requirement
	var a = randi_range(10, 20)
	var b = randi_range(5, 15)
	gate_answer = a + b
	gate_question.text = "Demande à un adulte :\n%d + %d = ?" % [a, b]
	gate_input.text = ""
	pending_product_id = product_id
	parental_gate.visible = true


func _on_gate_confirmed() -> void:
	var entered = gate_input.text.to_int()
	if entered == gate_answer:
		parental_gate.visible = false
		_purchase(pending_product_id)
	else:
		gate_input.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(gate_input, "modulate", Color.WHITE, 0.5)


func _purchase(product_id: String) -> void:
	# Google Play Billing v6 — handled via Android plugin
	# In production: use the GodotGooglePlayBilling plugin
	# https://github.com/godot-sdk-integrations/godot-google-play-billing
	if Engine.has_singleton("GodotGooglePlayBilling"):
		var billing = Engine.get_singleton("GodotGooglePlayBilling")
		billing.purchase(product_id)
	else:
		# Editor fallback for testing
		push_warning("GodotGooglePlayBilling not available — simulating purchase of: " + product_id)
		_on_purchase_completed(product_id)


func _on_purchase_completed(product_id: String) -> void:
	match product_id:
		GameManager.IAP_REMOVE_ADS:
			GameManager.ads_removed = true
			GameManager.save_data["ads_removed"] = true
		GameManager.IAP_CHAR_BOMBOMBINI:
			if "bombombini" not in GameManager.unlocked_characters:
				GameManager.unlocked_characters.append("bombombini")
		GameManager.IAP_CHAR_BRRBRR:
			if "brrbrr" not in GameManager.unlocked_characters:
				GameManager.unlocked_characters.append("brrbrr")
		GameManager.IAP_POWERUP_PACK:
			for key in GameManager.powerups:
				GameManager.powerups[key] += 5
	GameManager.save_game()
