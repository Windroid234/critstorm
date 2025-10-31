
extends Node2D

@export var hitbox: Area2D

var speed: float = 200.0
var direction: Vector2 = Vector2.RIGHT
var damage: int = 5


func _ready() -> void:
	self.name = "StaffProj (deprecated)"
	if hitbox:
		hitbox.connect("body_entered", on_hit)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func on_hit(body) -> void:
	var enemy = WeaponUtils.get_enemy_node(body)
	if enemy and enemy is EnemyBase:
		enemy.take_damage(damage)

	queue_free()
