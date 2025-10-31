class_name Sword extends WeaponBase

@export var proj_scene: PackedScene
@export var weapon_range: Area2D


func _ready() -> void:
	super()
	self.name = "Sword"

	weapon_name = "Sword"




func attack(_ctx: Dictionary = {}) -> void:
	var target = null
	if _ctx.has("target"):
		target = _ctx["target"]
	else:
		target = WeaponUtils.get_closest_enemy(self, weapon_range)

	if target == null:
		return

	var projectile := proj_scene.instantiate()
	var _parent := GSceneAdmin.scene_root if GSceneAdmin.scene_root != null else GGameGlobals.instance
	_parent.add_child(projectile)
	projectile.damage = damage
	projectile.scale = Vector2(1.3, 1.3)

	var direction = global_position.direction_to(target.global_position)
	projectile.global_position = self.global_position + direction * 25
	projectile.rotation = direction.angle()
