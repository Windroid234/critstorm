extends Node2D

@export var particles_path: NodePath = NodePath("GPUParticles2D")

func _ready() -> void:
	var p := get_node_or_null(particles_path) as GPUParticles2D
	if not p:
		queue_free()
		return

	if GEntityAdmin.player != null and GEntityAdmin.player.has_method("global_position"):
		var player_pos := GEntityAdmin.player.global_position
		var away := (global_position - player_pos)
		if away.length() > 0.001:
			var dir3 := Vector3(away.normalized().x, away.normalized().y, 0.0)
			var mat := p.process_material
			if mat and mat is ParticleProcessMaterial:
				mat.direction = dir3
				mat.spread = deg_to_rad(40.0)
				mat.initial_velocity = mat.initial_velocity * 1.15

	p.amount = max(p.amount, 24)
	p.emitting = true

	var shard_size := 8
	var shard_img := Image.create(shard_size, shard_size, false, Image.FORMAT_RGBA8)
	for yy in range(shard_size):
		for xx in range(shard_size):
			shard_img.set_pixel(xx, yy, Color(0, 0, 0, 0))
	for yy in range(shard_size):
		for xx in range(shard_size):
			if xx > yy * 0.5:
				var a = clamp(1.0 - (abs((float(xx) - float(shard_size) * 0.6)) / float(shard_size)), 0.2, 1.0)
				shard_img.set_pixel(xx, yy, Color(0.9, 0.05, 0.05, a))
	var shard_tex := ImageTexture.create_from_image(shard_img)

	var shard_count := 10
	for i in range(shard_count):
		var s := Sprite2D.new()
		s.texture = shard_tex
		s.z_index = 6
		s.scale = Vector2.ONE * randf_range(0.16, 0.42)
		s.centered = true
		s.rotation = randf() * PI * 2.0
		add_child(s)
		s.position = Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))

		var dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		if GEntityAdmin.player != null:
			var away2 := (global_position - GEntityAdmin.player.global_position)
			if away2.length() > 0.01:
				var base_dir := away2.normalized()
				var angle_deg := randf_range(-20.0, 20.0)
				dir = base_dir.rotated(deg_to_rad(angle_deg))

		var dist := randf_range(36.0, 120.0)
		var t := s.create_tween()
		t.tween_property(s, "global_position", s.global_position + dir * dist, 0.6)
		t.tween_property(s, "modulate:a", 0.0, 0.6)
		t.tween_callback(s.queue_free).set_delay(0.6)

	await get_tree().create_timer(p.lifetime + 0.05).timeout
	queue_free()
