class_name EntityEffects


static func play_hit_anim(node: Node2D, hit_color: Color) -> void:

	var dmg_fx := preload("res://content/effects/damage/damage_fx.tscn").instantiate()
	var _parent := GSceneAdmin.scene_root if GSceneAdmin.scene_root != null else GGameGlobals.instance
	_parent.add_child(dmg_fx)
	dmg_fx.global_position = node.global_position

	var size := 24
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			img.set_pixel(x, y, Color(0, 0, 0, 0))
	var cx := float(size) / 2.0
	var cy := float(size) / 2.0
	for y in size:
		for x in size:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			var r := size * 0.42
			if dist <= r:
				var a = clamp(1.0 - (dist / r), 0.0, 1.0)
				img.set_pixel(x, y, Color(1.0, 0.15, 0.15, a))
	var splash_tex := ImageTexture.create_from_image(img)

	var splash := Sprite2D.new()
	splash.texture = splash_tex
	splash.z_index = 3
	splash.scale = Vector2.ONE * randf_range(0.6, 1.0)
	splash.centered = true
	splash.rotation = randf() * PI * 2.0
	splash.global_position = node.global_position + Vector2(randf_range(-6, 6), randf_range(-6, 6))
	splash.modulate = Color(1, 0.25, 0.25, 0.95)
	_parent.add_child(splash)

	var s_tween := splash.create_tween()
	s_tween.tween_property(splash, "modulate:a", 0.0, 0.6)
	s_tween.tween_property(splash, "scale", splash.scale * 1.6, 0.6)
	s_tween.tween_callback(splash.queue_free).set_delay(0.6)

	var tween = node.create_tween()
	if node:
		tween.tween_property(node, "modulate", hit_color, 0.2)

	await tween.finished
	if is_instance_valid(node):
		tween.kill()
		node.modulate = Color.WHITE


static func add_damage_numbers(node: Node, amount: int, crit: bool = false) -> void:
	var dmg_num := preload("res://content/effects/damage/damage_numbers.tscn").instantiate()
	dmg_num.text = str(amount)

	var _parent2 := GSceneAdmin.scene_root if GSceneAdmin.scene_root != null else GGameGlobals.instance
	_parent2.add_child(dmg_num)
	dmg_num.global_position = node.global_position + randf_range(-20, 20) * Vector2(1, 1)

	if crit:
		dmg_num.modulate = Color.RED

	var tween := dmg_num.create_tween()
	tween.tween_property(dmg_num, "modulate:a", 0.0, 0.5)
	tween.tween_callback(dmg_num.queue_free)
