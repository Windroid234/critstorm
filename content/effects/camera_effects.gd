class_name CameraEffects


static func play_camera_shake() -> void:
	var camera = null
	if GSceneAdmin.scene_root != null:
		var vp := GSceneAdmin.scene_root.get_viewport()
		if vp:
			camera = vp.get_camera_2d()

	if camera == null and GEntityAdmin.player != null:
		if "camera" in GEntityAdmin.player:
			camera = GEntityAdmin.player.camera

	if camera and LocalSettings.camera_shake_enabled:
		var rot_amount := 0.01
		var off_amount := 6.0
		var tween = camera.create_tween()
		var tween2 = camera.create_tween()

		tween.tween_property(camera, "rotation", randf_range(-rot_amount, rot_amount), 0.05)
		tween2.tween_property(
			camera, "offset", Vector2(randf_range(-off_amount, off_amount), randf_range(-off_amount, off_amount)), 0.05
		)

		tween.tween_property(camera, "rotation", 0, 0.05)
		tween2.tween_property(camera, "offset", Vector2.ZERO, 0.05)
