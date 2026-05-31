extends Control

# Boutique Angry Brainrot — Google Play Billing v6, parental gate COPPA-compliant.
# L'UI est construite procéduralement dans _ready() puis rafraîchie via _refresh_ui().

# ---------------------------------------------------------------------------
# Thème couleurs
# ---------------------------------------------------------------------------
const COL_BG          := Color(0.05, 0.02, 0.15)
const COL_CARD_BG     := Color(0.1, 0.05, 0.2)
const COL_BORDER      := Color(0.6, 0.2, 1.0)
const COL_FREE        := Color(0.2, 0.8, 0.2)
const COL_OWNED       := Color(0.3, 0.3, 0.3)
const COL_BUY         := Color(1.0, 0.6, 0.0)
const COL_TEXT        := Color(0.95, 0.95, 1.0)
const COL_TEXT_DIM    := Color(0.7, 0.7, 0.8)

# ---------------------------------------------------------------------------
# Données des personnages : id, emoji, nom, description, prix, product_id IAP
# free == true => possédé d'office (gratuit)
# ---------------------------------------------------------------------------
var CHARACTERS := [
	{
		"id": "bombardiro", "emoji": "🐊", "name": "Bombardiro Crocodilo",
		"desc": "Explose tout à l'impact", "price": "GRATUIT",
		"product": "", "free": true,
	},
	{
		"id": "capybara", "emoji": "🦫", "name": "Capybara Chill",
		"desc": "Traverse les structures", "price": "GRATUIT",
		"product": "", "free": true,
	},
	{
		"id": "tralalero", "emoji": "🦈", "name": "Tralalero Tralala",
		"desc": "Rebondit 3 fois", "price": "GRATUIT",
		"product": "", "free": true,
	},
	{
		"id": "bombombini", "emoji": "🪿", "name": "Bombombini Gusini",
		"desc": "Tourne et détruit la pierre", "price": "$0.99",
		"product": GameManager.IAP_CHAR_BOMBOMBINI, "free": false,
	},
	{
		"id": "brrbrr", "emoji": "🕷️", "name": "Brr Brr Patapim",
		"desc": "Se divise en 3 projectiles", "price": "$1.99",
		"product": GameManager.IAP_CHAR_BRRBRR, "free": false,
	},
]

var ITEMS := [
	{
		"emoji": "⚡", "name": "Pack Power-ups x5",
		"desc": "5 de chaque power-up", "price": "$0.99",
		"product": GameManager.IAP_POWERUP_PACK,
	},
	{
		"emoji": "🗺️", "name": "Épisode 2",
		"desc": "20 nouveaux niveaux", "price": "$1.99",
		"product": GameManager.IAP_EPISODE_2,
	},
	{
		"emoji": "🚫", "name": "Supprimer les pubs",
		"desc": "Plus jamais de publicité", "price": "$2.99",
		"product": GameManager.IAP_REMOVE_ADS,
	},
]

# Références UI construites dynamiquement
var _char_panels := {}        # id -> { panel, badge, buy_btn, pulse_tween }
var _item_buttons := {}       # product_id -> Button (pour rafraîchir "Supprimer pubs")

# Parental gate
var _parental_gate: Control
var _gate_panel: Panel
var _gate_question: Label
var _gate_input: LineEdit
var _gate_answer: int = 0
var _pending_product_id: String = ""

# Flash de feedback achat
var _flash: ColorRect


func _ready() -> void:
	_build_ui()
	_refresh_ui()


# ===========================================================================
# CONSTRUCTION UI
# ===========================================================================
func _build_ui() -> void:
	# Fond dégradé
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = COL_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var grad := TextureRect.new()
	grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grad.texture = _make_gradient_texture()
	grad.stretch_mode = TextureRect.STRETCH_SCALE
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grad)

	# Bouton RETOUR (haut gauche)
	var back_btn := Button.new()
	back_btn.text = "← RETOUR"
	back_btn.position = Vector2(30, 30)
	back_btn.custom_minimum_size = Vector2(180, 70)
	back_btn.add_theme_font_size_override("font_size", 26)
	back_btn.add_theme_stylebox_override("normal", _make_button_style(Color(0.2, 0.1, 0.35)))
	back_btn.add_theme_stylebox_override("hover", _make_button_style(Color(0.3, 0.15, 0.5)))
	back_btn.add_theme_stylebox_override("pressed", _make_button_style(Color(0.15, 0.08, 0.28)))
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)

	# Titre animé
	var title := Label.new()
	title.text = "BOUTIQUE"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", COL_BORDER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 40.0
	title.offset_bottom = 140.0
	title.pivot_offset = Vector2(540, 50)
	add_child(title)
	_animate_title(title)

	# ScrollContainer principal
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 160.0
	scroll.offset_left = 30.0
	scroll.offset_right = -30.0
	scroll.offset_bottom = -30.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 24)
	scroll.add_child(content)

	# --- Section PERSONNAGES ---
	content.add_child(_make_section_header("🎮 PERSONNAGES"))
	for data in CHARACTERS:
		content.add_child(_make_character_card(data))

	# --- Section POWER-UPS & ÉPISODES (items) ---
	content.add_child(_make_section_header("⚡ POWER-UPS & ÉPISODES"))
	for data in ITEMS:
		content.add_child(_make_item_card(data))

	# Espace bas
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	content.add_child(spacer)

	# Parental gate (overlay) + flash feedback
	_build_parental_gate()
	_build_flash()


func _make_gradient_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, COL_BG)
	grad.set_color(1, Color(0.12, 0.04, 0.28))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	return tex


func _make_section_header(txt: String) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_color", COL_TEXT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return lbl


func _make_card_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_CARD_BG
	sb.set_corner_radius_all(24)
	sb.set_border_width_all(3)
	sb.border_color = COL_BORDER
	sb.set_content_margin_all(20)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 8
	return sb


func _make_button_style(col: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(12)
	return sb


func _make_badge_style(col: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


# ---------------------------------------------------------------------------
# Carte personnage
# ---------------------------------------------------------------------------
func _make_character_card(data: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_card_style())
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	panel.add_child(row)

	# Emoji 80px
	var emoji := Label.new()
	emoji.text = data["emoji"]
	emoji.add_theme_font_size_override("font_size", 80)
	emoji.custom_minimum_size = Vector2(110, 110)
	emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(emoji)

	# Bloc texte (nom + description)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 6)
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = data["name"]
	name_lbl.add_theme_font_size_override("font_size", 30)
	name_lbl.add_theme_color_override("font_color", COL_TEXT)
	info.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = data["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 22)
	desc_lbl.add_theme_color_override("font_color", COL_TEXT_DIM)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc_lbl)

	# Bloc droite (badge + bouton)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(right)

	var badge := Label.new()
	badge.add_theme_font_size_override("font_size", 22)
	badge.add_theme_color_override("font_color", Color.WHITE)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.custom_minimum_size = Vector2(160, 0)
	right.add_child(badge)

	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(180, 64)
	buy_btn.add_theme_font_size_override("font_size", 24)
	right.add_child(buy_btn)
	if not data["free"]:
		buy_btn.pressed.connect(_show_parental_gate.bind(data["product"]))

	_char_panels[data["id"]] = {
		"panel": panel,
		"badge": badge,
		"buy_btn": buy_btn,
		"data": data,
		"pulse": null,
	}
	return panel


# ---------------------------------------------------------------------------
# Carte item (power-up / épisode / supprimer pubs)
# ---------------------------------------------------------------------------
func _make_item_card(data: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_card_style())
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	panel.add_child(row)

	var emoji := Label.new()
	emoji.text = data["emoji"]
	emoji.add_theme_font_size_override("font_size", 64)
	emoji.custom_minimum_size = Vector2(90, 90)
	emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(emoji)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 6)
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = data["name"]
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_color", COL_TEXT)
	info.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = data["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 20)
	desc_lbl.add_theme_color_override("font_color", COL_TEXT_DIM)
	info.add_child(desc_lbl)

	var buy_btn := Button.new()
	buy_btn.text = data["price"]
	buy_btn.custom_minimum_size = Vector2(180, 64)
	buy_btn.add_theme_font_size_override("font_size", 24)
	buy_btn.add_theme_color_override("font_color", Color.WHITE)
	buy_btn.add_theme_stylebox_override("normal", _make_button_style(COL_BUY))
	buy_btn.add_theme_stylebox_override("hover", _make_button_style(COL_BUY.lightened(0.1)))
	buy_btn.add_theme_stylebox_override("pressed", _make_button_style(COL_BUY.darkened(0.15)))
	buy_btn.add_theme_color_override("font_color_disabled", COL_TEXT_DIM)
	buy_btn.add_theme_stylebox_override("disabled", _make_button_style(COL_OWNED))
	buy_btn.pressed.connect(_show_parental_gate.bind(data["product"]))
	row.add_child(buy_btn)

	_item_buttons[data["product"]] = buy_btn
	return panel


# ===========================================================================
# RAFRAÎCHISSEMENT VISUEL
# ===========================================================================
func _refresh_ui() -> void:
	for id in _char_panels:
		var entry: Dictionary = _char_panels[id]
		var data: Dictionary = entry["data"]
		var badge: Label = entry["badge"]
		var buy_btn: Button = entry["buy_btn"]
		var owned := GameManager.is_character_unlocked(id)

		if data["free"]:
			# Gratuit => toujours possédé visuellement
			badge.text = "GRATUIT"
			badge.add_theme_stylebox_override("normal", _make_badge_style(COL_FREE))
			buy_btn.text = "JOUER"
			buy_btn.disabled = false
			_style_button(buy_btn, COL_FREE)
			_stop_pulse(entry)
		elif owned:
			badge.text = "POSSÉDÉ"
			badge.add_theme_stylebox_override("normal", _make_badge_style(COL_OWNED))
			buy_btn.text = "✓ POSSÉDÉ"
			buy_btn.disabled = true
			_style_button(buy_btn, COL_OWNED)
			_stop_pulse(entry)
		else:
			badge.text = data["price"]
			badge.add_theme_stylebox_override("normal", _make_badge_style(COL_BORDER))
			buy_btn.text = "ACHETER"
			buy_btn.disabled = false
			_style_button(buy_btn, COL_BUY)
			_start_pulse(entry)

	# Bouton "Supprimer les pubs" : désactivé si déjà acheté
	if _item_buttons.has(GameManager.IAP_REMOVE_ADS) and GameManager.ads_removed:
		var ads_btn: Button = _item_buttons[GameManager.IAP_REMOVE_ADS]
		ads_btn.text = "✓ ACTIF"
		ads_btn.disabled = true


func _style_button(btn: Button, col: Color) -> void:
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_color_disabled", Color(0.85, 0.85, 0.9))
	btn.add_theme_stylebox_override("normal", _make_button_style(col))
	btn.add_theme_stylebox_override("hover", _make_button_style(col.lightened(0.12)))
	btn.add_theme_stylebox_override("pressed", _make_button_style(col.darkened(0.15)))
	btn.add_theme_stylebox_override("disabled", _make_button_style(col))


func _start_pulse(entry: Dictionary) -> void:
	if entry["pulse"] != null and is_instance_valid(entry["pulse"]):
		return
	var panel: PanelContainer = entry["panel"]
	panel.pivot_offset = panel.size / 2.0
	var tw := create_tween().set_loops()
	tw.tween_property(panel, "scale", Vector2(1.03, 1.03), 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.7).set_trans(Tween.TRANS_SINE)
	entry["pulse"] = tw


func _stop_pulse(entry: Dictionary) -> void:
	if entry["pulse"] != null and is_instance_valid(entry["pulse"]):
		entry["pulse"].kill()
		entry["pulse"] = null
	var panel: PanelContainer = entry["panel"]
	panel.scale = Vector2.ONE


func _animate_title(title: Label) -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(title, "scale", Vector2(1.06, 1.06), 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(title, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE)


# ===========================================================================
# PARENTAL GATE (COPPA)
# ===========================================================================
func _build_parental_gate() -> void:
	_parental_gate = Control.new()
	_parental_gate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_parental_gate.visible = false
	add_child(_parental_gate)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.7)
	_parental_gate.add_child(dim)

	_gate_panel = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_CARD_BG
	sb.set_corner_radius_all(28)
	sb.set_border_width_all(4)
	sb.border_color = COL_BORDER
	_gate_panel.add_theme_stylebox_override("panel", sb)
	_gate_panel.set_anchors_preset(Control.PRESET_CENTER)
	_gate_panel.custom_minimum_size = Vector2(640, 460)
	_gate_panel.size = Vector2(640, 460)
	_gate_panel.position = Vector2(220, 730)
	_parental_gate.add_child(_gate_panel)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 40
	vb.offset_right = -40
	vb.offset_top = 40
	vb.offset_bottom = -40
	vb.add_theme_constant_override("separation", 24)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	_gate_panel.add_child(vb)

	var lock := Label.new()
	lock.text = "🔒 Contrôle parental"
	lock.add_theme_font_size_override("font_size", 32)
	lock.add_theme_color_override("font_color", COL_BORDER)
	lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(lock)

	_gate_question = Label.new()
	_gate_question.add_theme_font_size_override("font_size", 28)
	_gate_question.add_theme_color_override("font_color", COL_TEXT)
	_gate_question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gate_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_gate_question)

	_gate_input = LineEdit.new()
	_gate_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gate_input.add_theme_font_size_override("font_size", 32)
	_gate_input.placeholder_text = "Réponse"
	_gate_input.custom_minimum_size = Vector2(0, 64)
	_gate_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	vb.add_child(_gate_input)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 20)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(btns)

	var cancel := Button.new()
	cancel.text = "ANNULER"
	cancel.custom_minimum_size = Vector2(220, 70)
	cancel.add_theme_font_size_override("font_size", 26)
	_style_button(cancel, Color(0.4, 0.2, 0.5))
	cancel.pressed.connect(func(): _parental_gate.visible = false)
	btns.add_child(cancel)

	var confirm := Button.new()
	confirm.text = "VALIDER"
	confirm.custom_minimum_size = Vector2(220, 70)
	confirm.add_theme_font_size_override("font_size", 26)
	_style_button(confirm, COL_FREE)
	confirm.pressed.connect(_on_gate_confirmed)
	btns.add_child(confirm)


func _show_parental_gate(product_id: String) -> void:
	if product_id == "":
		return
	var a := randi_range(10, 20)
	var b := randi_range(5, 15)
	_gate_answer = a + b
	_gate_question.text = "Demande à un adulte :\n%d + %d = ?" % [a, b]
	_gate_input.text = ""
	_pending_product_id = product_id
	_parental_gate.visible = true
	_gate_input.grab_focus()


func _on_gate_confirmed() -> void:
	var entered := _gate_input.text.to_int()
	if entered == _gate_answer:
		_parental_gate.visible = false
		_purchase(_pending_product_id)
	else:
		_shake_gate()


func _shake_gate() -> void:
	_gate_input.add_theme_color_override("font_color", Color.RED)
	var base := _gate_panel.position
	var tw := create_tween()
	for i in range(4):
		tw.tween_property(_gate_panel, "position", base + Vector2(18, 0), 0.04)
		tw.tween_property(_gate_panel, "position", base - Vector2(18, 0), 0.04)
	tw.tween_property(_gate_panel, "position", base, 0.04)
	tw.tween_callback(func(): _gate_input.remove_theme_color_override("font_color"))


# ===========================================================================
# ACHAT — Google Play Billing v6
# ===========================================================================
func _purchase(product_id: String) -> void:
	if Engine.has_singleton("GodotGooglePlayBilling"):
		var billing = Engine.get_singleton("GodotGooglePlayBilling")
		billing.purchase(product_id)
	else:
		# Fallback éditeur pour test
		push_warning("GodotGooglePlayBilling indisponible — simulation achat : " + product_id)
		_on_purchase_completed(product_id)


func _on_purchase_completed(product_id: String) -> void:
	match product_id:
		GameManager.IAP_REMOVE_ADS:
			GameManager.ads_removed = true
			GameManager.save_data["ads_removed"] = true
		GameManager.IAP_CHAR_BOMBOMBINI:
			if "bombombini" not in GameManager.unlocked_characters:
				GameManager.unlocked_characters.append("bombombini")
			GameManager.save_data["unlocked_chars"] = GameManager.unlocked_characters
		GameManager.IAP_CHAR_BRRBRR:
			if "brrbrr" not in GameManager.unlocked_characters:
				GameManager.unlocked_characters.append("brrbrr")
			GameManager.save_data["unlocked_chars"] = GameManager.unlocked_characters
		GameManager.IAP_POWERUP_PACK:
			for key in GameManager.powerups:
				GameManager.powerups[key] += 5
			GameManager.save_data["powerups"] = GameManager.powerups
	GameManager.save_game()
	_refresh_ui()
	_purchase_feedback()


# ===========================================================================
# FEEDBACK VISUEL (flash vert + confettis)
# ===========================================================================
func _build_flash() -> void:
	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0.2, 0.9, 0.3, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)


func _purchase_feedback() -> void:
	# Flash vert
	_flash.color = Color(0.2, 0.9, 0.3, 0.5)
	var tw := create_tween()
	tw.tween_property(_flash, "color", Color(0.2, 0.9, 0.3, 0.0), 0.6)
	_spawn_confetti()


func _spawn_confetti() -> void:
	var colors := [
		Color(1.0, 0.3, 0.3), Color(0.3, 1.0, 0.4), Color(0.3, 0.5, 1.0),
		Color(1.0, 0.9, 0.2), Color(0.9, 0.3, 1.0), Color(0.2, 1.0, 0.9),
	]
	for i in range(40):
		var c := ColorRect.new()
		c.color = colors[randi() % colors.size()]
		c.size = Vector2(randf_range(10, 20), randf_range(10, 20))
		c.position = Vector2(randf_range(0, 1080), -30)
		c.rotation = randf_range(0, TAU)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(c)
		var fall := randf_range(1.0, 1.8)
		var target_y := 2000.0
		var drift := randf_range(-120, 120)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(c, "position:y", target_y, fall).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(c, "position:x", c.position.x + drift, fall)
		tw.tween_property(c, "rotation", c.rotation + randf_range(-TAU, TAU), fall)
		tw.chain().tween_callback(c.queue_free)


# ===========================================================================
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
