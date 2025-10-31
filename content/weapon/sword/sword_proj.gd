class_name SwordProj extends Node2D

@export var sprite: Sprite2D
@export var hitbox: Area2D

var direction: Vector2 = Vector2.RIGHT
var damage: int = 5


func _ready() -> void:
	self.name = "SwordProj"
	hitbox.connect("body_entered", on_hit)

	var std_anim = Anim.SpriteAnim.new(sprite, 9, 0.1)
	std_anim.play()
	var anim_finished_callable := Callable(self, "anim_finished")
	if not std_anim.is_connected("finished", anim_finished_callable):
		std_anim.connect("finished", anim_finished_callable)


func anim_finished() -> void:
	self.queue_free()


func on_hit(body) -> void:
	var enemy = WeaponUtils.get_enemy_node(body)
	if enemy is EnemyBase and enemy != null:
		enemy.take_damage(damage)
