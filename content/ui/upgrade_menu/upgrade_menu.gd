extends Control

@export var wave_label: Label
@export var continue_button: Button


@export var health_button: Button
@export var speed_button: Button
@export var dex_button: Button

@export var health_ing_label: Label
@export var speed_ing_label: Label
@export var dex_ing_label: Label

var _reach_label: Label = null
var _swift_label: Label = null
var _multi_label: Label = null
var _prev_music_db: float = 0.0
var _prev_music_db_saved: bool = false

func _ready() -> void:
	wave_label.text = "Wave " + str(WaveSpawner.current_wave) + " ended!"
	continue_button.press_event = on_continue

	GStateAdmin.can_pause = false

	Sound.play_sfx(Sound.Fx.FINISH_WAVE, 2, 0.2)

	health_button.press_event = func(): Upgrades.heal_player()
	speed_button.press_event = func(): Upgrades.apply_multiply_potion()

	var reach_btn = $HBoxContainer/Upgrade5/reachButton if has_node("HBoxContainer/Upgrade5/reachButton") else null
	if reach_btn != null:
		reach_btn.press_event = func(): _on_reach_pressed()

	var swift_btn = $HBoxContainer/Upgrade4/SwiftButton if has_node("HBoxContainer/Upgrade4/SwiftButton") else null
	if swift_btn != null:
		swift_btn.press_event = func(): Upgrades.apply_swiftness_potion()


func _show_toast(text: String, duration: float = 1.2) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", preload("res://assets/fonts/WhitePeaberry.fnt"))
	lbl.modulate = Color(1,1,1,1)
	lbl.anchor_left = 0.25
	lbl.anchor_right = 0.75
	lbl.anchor_top = 0.35
	lbl.anchor_bottom = 0.45
	lbl.margin_left = 0
	lbl.margin_top = 0
	add_child(lbl)

	var tw = create_tween()
	tw.tween_property(lbl, "modulate", Color(1,1,1,0), duration).set_delay(duration * 0.4)
	tw.tween_callback(func() -> void:
		if is_instance_valid(lbl):
			lbl.queue_free()
	)


func _on_reach_pressed() -> void:
	if GEntityAdmin.player == null:
		_show_toast("No player", 1.0)
		return
	var cost := Pair.new(Ingredient.IngredientType.RATTAIL, 10)
	var have := GEntityAdmin.player.ingredient_inventory[cost.first]
	if have < cost.second:
		_show_toast("Not enough Rattails (%d/%d)" % [have, cost.second], 1.4)
		GLogger.log("UpgradeMenu: reach press failed - have=%d need=%d" % [have, cost.second])
		return
	Upgrades.apply_reach_potion()
	_show_toast("Reach increased!", 1.4)
	GLogger.log("UpgradeMenu: reach applied (have before=%d)" % [have])

	if Sound.music_player != null:
		_prev_music_db = Sound.music_player.volume_db
		_prev_music_db_saved = true
		Sound.music_player.volume_db = _prev_music_db - 10.0

	if has_node("HBoxContainer/Upgrade5/DexIngLabel"):
		_reach_label = $HBoxContainer/Upgrade5/DexIngLabel as Label

	if has_node("HBoxContainer/Upgrade4/DexIngLabel"):
		_swift_label = $HBoxContainer/Upgrade4/DexIngLabel as Label

	if has_node("HBoxContainer/Upgrade2/SpeedIngLabel"):
		_multi_label = $HBoxContainer/Upgrade2/SpeedIngLabel as Label


func on_continue() -> void:
	GStateAdmin.unpause_game()
	if _prev_music_db_saved and Sound.music_player != null:
		Sound.music_player.volume_db = _prev_music_db
		_prev_music_db_saved = false
	WaveSpawner.wave_ref.start_wave()
	GStateAdmin.can_pause = true
	self.queue_free()


func _process(_delta: float) -> void:
	if GEntityAdmin.player == null:
		return
	var inv = GEntityAdmin.player.ingredient_inventory
	if Engine.is_editor_hint() == false:
		GLogger.log("UpgradeMenu: ingredients BATWING=%d FUNGUS=%d RATTail=%d" % [inv[Ingredient.IngredientType.BATWING], inv[Ingredient.IngredientType.FUNGUS], inv[Ingredient.IngredientType.RATTAIL]])
	health_ing_label.text = str(inv[Ingredient.IngredientType.BATWING]) + " / 10"

	if _multi_label != null:
		_multi_label.text = str(inv[Ingredient.IngredientType.FUNGUS]) + " / 10"
	if speed_ing_label != null:
		speed_ing_label.text = str(inv[Ingredient.IngredientType.FUNGUS]) + " / 10"



	if _swift_label != null:
		_swift_label.text = str(inv[Ingredient.IngredientType.FUNGUS]) + " / 15"
