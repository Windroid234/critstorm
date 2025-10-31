extends CanvasLayer

@export var health_label: Label
@export var heart_box: HBoxContainer

@export var time_label: Label
@export var kill_label: Label
@export var wave_label: Label

@export var crystal_label: Label
@export var level_bar: TextureProgressBar
@export var level_label: Label

const PEBARRY_FONT: Font = preload("res://assets/fonts/WhitePeaberry.fnt")

@export var ingredients_box: VBoxContainer


@export var staff_level: Label
@export var staff_bar: ProgressBar

var _prev_level: int = -1
var _prev_progress: int = -1



func _ready() -> void:
	if GEntityAdmin.player != null:
		_prev_level = GEntityAdmin.player.level
		_prev_progress = GEntityAdmin.player.level_progress
	else:
		_prev_level = -1
		_prev_progress = -1

	var clear_ingredient_children := func() -> void:
		for i in ingredients_box.get_children():
			i.queue_free()

	clear_ingredient_children.call()

func _process(_delta: float) -> void:
	if GEntityAdmin.player:
		update_health_label()
		update_heart_box()
		update_crystal_label()
		update_level_bar()
		update_level_label()
		var cur_level := GEntityAdmin.player.level
		if cur_level != _prev_level:
			_prev_level = cur_level
			_play_level_up_effect()

		update_kill_label()
		update_ingredients_box()
		update_staff()


	if GSceneAdmin.level_base:
		update_time_label()
		update_wave_label()


func update_heart_box() -> void:
	var children := heart_box.get_children()

	const HEART_NORMAL := preload("res://assets/ui/hud/heart.png")
	const HEART_EMPTY := preload("res://assets/ui/hud/heart_empty.png")

	var change_heart_count := func() -> void:
		for i in children:
			i.queue_free()

		for i in range(0, GEntityAdmin.player.max_health):
			var icon := TextureRect.new()
			icon.texture = HEART_NORMAL
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
			heart_box.add_child(icon)

	var update_heart_visuals := func() -> void:
		if children.size() != GEntityAdmin.player.max_health:
			return

		for i in range(0, GEntityAdmin.player.max_health):
			if i < GEntityAdmin.player.health:
				children[i].texture = HEART_NORMAL
			else:
				children[i].texture = HEART_EMPTY

	if children.size() != GEntityAdmin.player.max_health:
		change_heart_count.call()

	update_heart_visuals.call()


func update_kill_label() -> void:
	kill_label.text = str(GEntityAdmin.player.kills)


func update_health_label() -> void:
	health_label.text = "%d/%d" % [GEntityAdmin.player.health, GEntityAdmin.player.max_health]


func update_time_label() -> void:
	time_label.text = GSceneAdmin.level_base.get_time_string()


func update_crystal_label() -> void:
	crystal_label.text = str(GEntityAdmin.player.crystals)


func update_level_bar() -> void:
	level_bar.value = GEntityAdmin.player.level_progress
	level_bar.max_value = GEntityAdmin.player.level_required


func update_level_label() -> void:
	level_label.text = "[LVL] %d" % GEntityAdmin.player.level


func _play_level_up_effect() -> void:
	if level_label == null:
		return
	var supports_scale: bool = ("rect_scale" in level_label)
	if supports_scale:
		var original_scale: Vector2 = level_label.rect_scale
		var pop_scale: Vector2 = original_scale * 1.6
		var t = create_tween()
		t.tween_property(level_label, "rect_scale", pop_scale, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(level_label, "rect_scale", original_scale, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	else:
		var orig_label_col: Color = level_label.modulate if ("modulate" in level_label) else Color(1,1,1)
		var t_fallback = create_tween()
		t_fallback.tween_property(level_label, "modulate", Color(1,1,0.8), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t_fallback.tween_property(level_label, "modulate", orig_label_col, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	if level_bar != null:
		var orig_col := level_bar.modulate
		var pulse_col := Color(1, 1, 0.6)
		var t2 = create_tween()
		t2.tween_property(level_bar, "modulate", pulse_col, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t2.tween_property(level_bar, "modulate", orig_col, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	if Engine.is_editor_hint() == false:
		Sound.play_sfx(Sound.Fx.FINISH_WAVE, 1.2, 0.9)

	if GEntityAdmin.player != null:
		_show_damage_popup(GEntityAdmin.player.base_unarmed_damage)


func _show_damage_popup(new_damage: int) -> void:
	if level_label == null:
		return

	var popup := Label.new()
	popup.text = "+1 Damage (now %d)" % new_damage
	if PEBARRY_FONT != null:
		popup.add_theme_font_override("font", PEBARRY_FONT)

	var start_pos: Vector2 = Vector2.ZERO
	if GEntityAdmin.player != null:
		var cam := get_viewport().get_camera_2d()
		if cam != null:
			var vp_size := get_viewport().get_visible_rect().size
			var cam_pos := cam.global_position
			var zoom := cam.zoom if "zoom" in cam else Vector2.ONE
			start_pos = (GEntityAdmin.player.global_position - cam_pos) * zoom + vp_size * 0.5
			start_pos += Vector2(0, -48)
		else:
			if "rect_global_position" in level_label:
				start_pos = level_label.rect_global_position + Vector2(0, -24)
			else:
				start_pos = Vector2(10, 10)
	else:
		if "rect_global_position" in level_label:
			start_pos = level_label.rect_global_position + Vector2(0, -24)
		else:
			start_pos = Vector2(10, 10)

	popup.modulate = Color(1, 1, 1, 1)
	if "position" in popup:
		popup.position = start_pos
	elif "rect_position" in popup:
		popup.rect_position = start_pos
	else:
		popup.set_meta("popup_start_pos", start_pos)
	add_child(popup)

	var tt = create_tween()
	tt.tween_interval(3.0)
	tt.tween_property(popup, "modulate", Color(1, 1, 1, 0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tt.tween_callback(func() -> void:
		if is_instance_valid(popup):
			popup.queue_free()
	)

func update_wave_label() -> void:
	wave_label.text = "WAVE %d" % WaveSpawner.current_wave

func update_ingredients_box() -> void:
	var children := ingredients_box.get_children()


	if children.is_empty():
		for i in range(1, Ingredient.IngredientType.size()):
			var ig_container := preload("res://content/ui/hud/ingredient_container.tscn").instantiate()
			ig_container.set_icon(Ingredient.ingredient_types[i].icon_texture)
			ingredients_box.add_child(ig_container)

	var update_labels := func() -> void:
		for i in children.size():
			children[i].set_label(str(GEntityAdmin.player.ingredient_inventory[i+1]))

	update_labels.call()

func update_staff() -> void:
	if GEntityAdmin.player.weapon_inventory.is_empty():
		return

	var staff = GEntityAdmin.player.weapon_inventory[0]
	staff_level.text = "LV." + str(staff.level)
	staff_bar.value = staff.level_progress
	staff_bar.max_value = staff.level_required
