class_name EnemyBase extends Node2D

@export var mov_body: CharacterBody2D
@export var sprite: Sprite2D
@export var hit_box: Area2D

var health: int = 100
var mov_speed: float = 2000.0

var melee_damage: int = 5
var melee_cooldown: float = 0.3
var cooldown: Tween
var player_touching: bool = false

var crystal_rating: float = 0.2
var ingredient: Ingredient.IngredientType = Ingredient.IngredientType.NONE
var ingredient_chance: float = 0.5

var movement_method: Callable


func _ready() -> void:
	self.name = "Enemy"

	GEntityAdmin.register_entity(self)

	hit_box.connect("body_entered", on_player_enter)
	hit_box.connect("body_exited", on_player_exit)


func _exit_tree() -> void:
	GEntityAdmin.unregister_entity(self)


func _physics_process(delta: float) -> void:
	movement_method.call(delta)
	mov_body.move_and_slide()


func take_damage(damage: int, source: Node = null) -> void:
	var before_hp: int = int(health)
	health -= damage
	var after_hp: int = int(health)

	var src_name := "<unknown>"
	var src_pos := Vector2.ZERO
	var src_type := "<none>"
	if source != null:
		src_name = str(source.name)
		if "global_position" in source:
			src_pos = source.global_position
		src_type = str(source.get_class())

	var my_pos := self.global_position if "global_position" in self else Vector2.ZERO
	var layer_info := "-"
	if mov_body != null:
		layer_info = str(mov_body.get_collision_layer())

	var log_msg := "Enemy '%s' took %d damage (hp %d -> %d) src=%s[%s] src_pos=%s my_pos=%s layer=%s" % [str(self.name), int(damage), before_hp, after_hp, src_name, src_type, str(src_pos), str(my_pos), layer_info]
	if Engine.is_editor_hint() == false:
		GLogger.log(log_msg)
	print(log_msg)

	Sound.play_sfx_replace(Sound.Fx.HIT_ENTITY, 1.25, 0.7)
	EntityEffects.add_damage_numbers(self, damage, false)
	EntityEffects.play_hit_anim(sprite, Color.RED)
	CameraEffects.play_camera_shake()

	if after_hp <= 0:
		GLogger.log("Enemy '%s' dying (hp <= 0)" % [str(self.name)])
		die()


func die(spawn_loot: bool = true, get_kills: bool = true) -> void:
	if spawn_loot:
		EnemyUtils.spawn_loot(self.global_position, crystal_rating, ingredient, ingredient_chance)

	if get_kills and GEntityAdmin.player:
		GEntityAdmin.player.kills += 1
		GEntityAdmin.player.kills_in_wave += 1


	var death_effect = preload("res://content/effects/enemy/death_effect.tscn").instantiate()

	var _parent := GSceneAdmin.scene_root if GSceneAdmin.scene_root != null else GGameGlobals.instance

	var shatter := preload("res://content/effects/enemy/death_shatter.tscn").instantiate()
	shatter.global_position = self.global_position
	_parent.add_child(shatter)

	death_effect.global_position = self.global_position
	_parent.add_child(death_effect)

	self.get_parent().queue_free()


func on_player_enter(body: Node2D) -> void:
	if body != GEntityAdmin.player:
		return

	player_touching = true

	var do_damage := func() -> void: GEntityAdmin.player.take_damage(melee_damage)
	do_damage.call()
	cooldown = create_tween()
	cooldown.set_loops()
	cooldown.tween_callback(do_damage).set_delay(melee_cooldown)


func on_player_exit(body: Node2D) -> void:
	if body != GEntityAdmin.player:
		return

	player_touching = false
	cooldown.kill()
