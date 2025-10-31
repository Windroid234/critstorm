class_name Player extends Node2D

enum HealthStatus {
	FULL,
	NORMAL,
	LOW,
	DEAD,
}

const LOW_HEALTH_THRESHOLD: float = 0.25
const MAX_WEAPONS: int = 5
const STD_CAMERA_ZOOM: float = 2.5

const IDLE_SPRITES := {
	"down": "res://assets/Micheal/Sprites/IDLE/idle_down.png",
	"up": "res://assets/Micheal/Sprites/IDLE/idle_up.png",
	"left": "res://assets/Micheal/Sprites/IDLE/idle_left.png",
	"right": "res://assets/Micheal/Sprites/IDLE/idle_right.png",
}

const RUN_SPRITES := {
	"down": "res://assets/Micheal/Sprites/RUN/run_down.png",
	"up": "res://assets/Micheal/Sprites/RUN/run_up.png",
	"left": "res://assets/Micheal/Sprites/RUN/run_left.png",
	"right": "res://assets/Micheal/Sprites/RUN/run_right.png",
}

@export var mov_body: CharacterBody2D
@export var sprite: Node2D
@export var hud_scene: PackedScene = preload("res://content/ui/hud/hud.tscn")
@export var camera: Camera2D

var max_health: int = 9
var health: int = max_health

var god_mode: bool = false
var health_status: HealthStatus = HealthStatus.FULL

var mov_speed: float = 6000.0
var attack_speed: float = 0.7


var crystals: int = 0
var level: int = 0
var level_progress: int = 0
var first_level_req: int = 25
var level_required: int = first_level_req
var level_req_multiplier: float = 1.3


var weapon_inventory: Array[WeaponBase] = []
var ingredient_inventory: Array[int] = []

var player_rating: float = 10.0

var kills: int = 0

var damage_taken: int = 0
var kills_in_wave: int = 0
var ingredients_collected: int = 0
var crystals_collected: int = 0



var can_move: bool = true


var camera_zoom_offset: float = 0.0

var last_dir: String = "down"

var current_anim: Anim.SpriteAnim = null

var _rng := RandomNumberGenerator.new()
var is_attacking: bool = false
var _hit_areas: Dictionary = {}

var reach_multiplier: float = 1.0
var max_hits_per_attack: int = 2
var base_unarmed_damage: int = 6
var damage_cooldown: float = 1.0
var _can_take_damage: bool = true
var _damage_cooldown_timer: Timer = null

const DEFAULT_ANIM_SPEED: float = 0.08
const RUN_ANIM_SPEED: float = 0.05


func _find_animated_anim(anim_sprite: AnimatedSprite2D, action: String, dir: String) -> String:
	var dir_low := dir.to_lower()

	var sf = null
	sf = anim_sprite.sprite_frames if "sprite_frames" in anim_sprite else null
	if sf == null:
		return ""

	var names_to_try: Array = []
	if action.to_lower() == "idle":
		match dir_low:
			"right":
				names_to_try = ["IDLE_RIGHT", "IDLE RIGHT", "IDLE"]
			"left":
				names_to_try = ["IDLE_LEFT", "IDLE LEFT", "IDLE"]
			"up":
				names_to_try = ["IDLE_UP", "IDLE UP", "IDLE"]
			_:
				names_to_try = ["IDLE"]
	elif action.to_lower() == "run":
		match dir_low:
			"right":
				names_to_try = ["WALK_RIGHT", "WALK RIGHT", "WALK"]
			"left":
				names_to_try = ["WALK LEFT", "WALK_LEFT", "WALK"]
			"up":
				names_to_try = ["WALK_UP", "WALK UP", "WALK"]
			_:
				names_to_try = ["WALK"]
	else:
		names_to_try = ["%s_%s".format([action.to_upper(), dir.to_upper()]), action.to_upper()]

	for nm in names_to_try:
		if sf.has_animation(nm):
			if Engine.is_editor_hint() == false:
				GLogger.log("Player: matched animation '%s' for action='%s' dir='%s'" % [nm, action, dir])
			return nm

	var avail := []
	if sf.has_method("get_animation_names"):
		avail = sf.get_animation_names()
	if Engine.is_editor_hint() == false:
		GLogger.log("Player: could not find animation for action='%s' dir='%s'. Available: %s" % [action, dir, avail])

	return ""

func _stop_current_anim() -> void:
	if current_anim != null:
		current_anim.stop()
		current_anim = null


func _normalize_anim_name(n: String) -> String:
	return n.to_lower().replace(" ", "").replace("_", "").replace("-", "")


func _locate_sprite_node() -> Node2D:
	var stack := [self]
	while stack.size() > 0:
		var n = stack.pop_back()
		for c in n.get_children():
			if typeof(c) == TYPE_OBJECT:
				if c is AnimatedSprite2D:
					return c as AnimatedSprite2D
				if c is Sprite2D:
					return c as Sprite2D
			stack.push_back(c)
	return null

func _setup_texture_and_anim(tex, anim_speed: float = DEFAULT_ANIM_SPEED) -> void:
	if tex == null:
		return

	if typeof(tex) == TYPE_STRING:
		var path := tex as String
		if not ResourceLoader.exists(path):
			return
		tex = ResourceLoader.load(path) as Texture2D

	if sprite == null or tex == null:
		return

	if sprite is AnimatedSprite2D:
		return

	if "texture" in sprite and "hframes" in sprite:
		sprite.texture = tex

	var tex_size: Vector2 = (tex as Texture2D).get_size()
	var frames: int = 1
	if tex_size.y > 0 and int(tex_size.x) % int(tex_size.y) == 0:
		frames = int(tex_size.x / tex_size.y)

	if frames <= 1:
		if "hframes" in sprite:
			sprite.hframes = 1
		if "frame" in sprite:
			sprite.frame = 0
		_stop_current_anim()
		return

	if "hframes" in sprite and "frame" in sprite:
		sprite.hframes = frames
		sprite.frame = 0

	_stop_current_anim()
	current_anim = Anim.SpriteAnim.new(sprite, frames, anim_speed)
	current_anim.looped = true
	current_anim.play()


func play_anim_action(action: String, dir: String) -> void:
	if sprite is AnimatedSprite2D:
		var anim_sprite := sprite as AnimatedSprite2D
		var found := _find_animated_anim(anim_sprite, action, dir)
		if found != "":
			if "visible" in anim_sprite:
				anim_sprite.visible = true
			if anim_sprite.animation != found:
				anim_sprite.play(found)
			return

	if action == "run":
		_setup_texture_and_anim(RUN_SPRITES.get(dir), RUN_ANIM_SPEED)
	elif action.begins_with("attack"):
		var attack_tex: Texture2D = null
		var path2 := "res://assets/Micheal/Sprites/ATTACK 2/attack%s_%s.png".format([action.replace("attack", ""), dir])
		if ResourceLoader.exists(path2):
			attack_tex = ResourceLoader.load(path2) as Texture2D
		if attack_tex == null:
			var path := "res://assets/Micheal/Sprites/ATTACK 1/%s_%s.png".format([action, dir])
			if ResourceLoader.exists(path):
				attack_tex = ResourceLoader.load(path) as Texture2D

		if attack_tex != null:
			_setup_texture_and_anim(attack_tex, DEFAULT_ANIM_SPEED)
		else:
			_setup_texture_and_anim(IDLE_SPRITES.get(dir), DEFAULT_ANIM_SPEED)
	else:
		_setup_texture_and_anim(IDLE_SPRITES.get(dir), DEFAULT_ANIM_SPEED)


func _play_named_anim(anim_name: String) -> bool:
	if sprite == null:
		return false
	if not (sprite is AnimatedSprite2D):
		return false
	var anim_sprite := sprite as AnimatedSprite2D
	var sf = anim_sprite.sprite_frames if "sprite_frames" in anim_sprite else null
	if sf == null:
		return false

	var norm := _normalize_anim_name(anim_name)
	var tries: Array = []
	tries.append(anim_name)
	tries.append(anim_name.to_upper())
	tries.append(anim_name.to_lower())
	tries.append(anim_name.replace(" ", "_"))
	tries.append(anim_name.replace("_", " "))
	tries.append(anim_name.replace("-", "_"))
	tries.append(anim_name.replace("-", " "))
	tries.append(norm)
	tries.append(norm.to_upper())

	var seen := {}
	var dedup: Array = []
	for t in tries:
		if t == null:
			continue
		if not seen.has(t):
			dedup.append(t)
			seen[t] = true

	for t in dedup:
		if sf.has_animation(t):
			if "visible" in anim_sprite:
				anim_sprite.visible = true
			anim_sprite.play(t)
			if Engine.is_editor_hint() == false:
				GLogger.log("Player: playing animation '%s' (matched from '%s')" % [t, anim_name])
			return true

	var avail := []
	if sf.has_method("get_animation_names"):
		avail = sf.get_animation_names()
	if Engine.is_editor_hint() == false:
		GLogger.log("Player: failed to play '%s'. Tried: %s. Available: %s" % [anim_name, dedup, avail])

	return false


func _input(event) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var idx = mb.button_index
		if mb.pressed and (idx == MOUSE_BUTTON_LEFT or idx == 1):
			GLogger.log("Player: _input detected left-click (button %d)" % idx)
			perform_attack()
		else:
			if mb.pressed:
				GLogger.log("Player: _input mouse pressed (button %d)" % idx)

	if event is InputEventKey:
		var ik := event as InputEventKey
		if ik.pressed and not ik.echo:
			if ik.physical_keycode == 75:
				GLogger.log("Player: debug key 'K' pressed -> forcing hit")
				_debug_force_hit()




func perform_attack() -> void:
	_stop_current_anim()
	if sprite is AnimatedSprite2D:
		var anim_sprite := sprite as AnimatedSprite2D
		if anim_sprite.is_playing():
			anim_sprite.stop()

	var side: String
	if _rng.randf() < 0.5:
		side = "LR"
	else:
		side = "RL"
	var anim_name := "Attack_%s" % side
	match last_dir:
		"up":
			anim_name = "Attack_%s_UP" % side
		"left":
			anim_name = "Attack_%s_LEFT" % side
		"right":
			anim_name = "Attack_%s_RIGHT" % side
		_:
			anim_name = "Attack_%s" % side

	GLogger.log("Player: attempting attack '%s' (last_dir=%s)" % [anim_name, last_dir])
	Sound.play_sfx(Sound.Fx.SWORD_SWOOSH, 1.0, 0.9)

	var played := _play_named_anim(anim_name)
	GLogger.log("Player: _play_named_anim returned %s for '%s'" % [str(played), anim_name])
	if not played:
		var attack_suffix: String
		if side == "LR":
			attack_suffix = "1"
		else:
			attack_suffix = "2"
		play_anim_action("attack%s" % attack_suffix, last_dir)

	is_attacking = true

	var hit_delay: float = attack_speed * 0.3

	var scheduled_weapon: WeaponBase = null
	if weapon_inventory.size() > 0 and weapon_inventory[0] != null:
		scheduled_weapon = weapon_inventory[0]
	else:
		if Engine.is_editor_hint() == false:
			GLogger.log("Player: no weapon equipped — using default melee for attack")
	create_tween().tween_callback(func() -> void:
		_melee_hit(scheduled_weapon)
	).set_delay(hit_delay)

	await create_tween().tween_interval(attack_speed).finished
	is_attacking = false


func _melee_hit(weapon_ref: WeaponBase = null) -> void:
	var damage_val: int = base_unarmed_damage
	var weapon_name: String = "<none>"
	if weapon_ref != null:
		if "damage" in weapon_ref:
			damage_val = int(weapon_ref.damage)
		if "weapon_name" in weapon_ref:
			weapon_name = str(weapon_ref.weapon_name)
	var hit_node_name := "hit_down"
	match last_dir:
		"up":
			hit_node_name = "hit_up"
		"left":
			hit_node_name = "hit_left"
		"right":
			hit_node_name = "hit_right"
		_:
			hit_node_name = "hit_down"

	var hit_entry: Node = null
	if _hit_areas.has(hit_node_name):
		hit_entry = _hit_areas[hit_node_name]
	elif _hit_areas.has("hit_melee"):
		hit_entry = _hit_areas["hit_melee"]

	if hit_entry != null:
		if hit_entry is Area2D:
			var hit_area: Area2D = hit_entry as Area2D
			if Engine.is_editor_hint() == false:
				GLogger.log("Player: using Area2D hitbox '%s' at %s" % [hit_area.name, str(hit_area.global_position)])
			hit_area.monitoring = true
			await get_tree().process_frame
			var bodies := hit_area.get_overlapping_bodies()
			var hit_targets_a: Array = []
			for b in bodies:
				var target: Node = null
				if b is EnemyBase:
					target = b
				else:
					target = WeaponUtils.get_enemy_node(b)
				if target != null and not hit_targets_a.has(target):
					target.take_damage(damage_val, self)
					hit_targets_a.append(target)
					if Engine.is_editor_hint() == false:
						GLogger.log("Player: hit (hitbox) %s for %d" % [target.name, damage_val])
				if hit_targets_a.size() >= max_hits_per_attack:
					break

			hit_area.monitoring = false
			var hc := hit_targets_a.size()
			if Engine.is_editor_hint() == false:
				GLogger.log("Player: melee hitbox '%s' applied to %d enemies" % [hit_area.name, hc])
			if hc > 0:
				Sound.play_sfx_replace(Sound.Fx.HIT_ENTITY, 1.2, 0.8)
			return
		else:
			var node_hit: Node = hit_entry as Node
			var temp_area := Area2D.new()
			temp_area.monitoring = true
			if Engine.is_editor_hint() == false:
				GLogger.log("Player: creating temp Area2D for hit node '%s' at %s" % [node_hit.name, str(node_hit.global_position)])
			for raw_cc in node_hit.get_children():
				if raw_cc is CollisionShape2D:
					var cc: CollisionShape2D = raw_cc as CollisionShape2D
					var cs := CollisionShape2D.new()
					cs.shape = cc.shape
					cs.position = cc.position
					cs.rotation = cc.rotation
					cs.scale = cc.scale
					temp_area.add_child(cs)

			temp_area.global_position = node_hit.global_position
			var parent := GSceneAdmin.scene_root if GSceneAdmin.scene_root != null else GGameGlobals.instance
			parent.add_child(temp_area)
			await get_tree().process_frame
			var bodies2 := temp_area.get_overlapping_bodies()
			var hit_targets2: Array = []
			for b2 in bodies2:
				var target2: Node = null
				if b2 is EnemyBase:
					target2 = b2
				else:
					target2 = WeaponUtils.get_enemy_node(b2)
				if target2 != null and not hit_targets2.has(target2):
					target2.take_damage(damage_val, self)
					hit_targets2.append(target2)
					if Engine.is_editor_hint() == false:
						GLogger.log("Player: hit (temp hitbox) %s for %d" % [target2.name, damage_val])
				if hit_targets2.size() >= max_hits_per_attack:
					break

			var hc2 := hit_targets2.size()
			if Engine.is_editor_hint() == false:
				GLogger.log("Player: temp melee hit applied to %d enemies (from node %s)" % [hc2, node_hit.name])
			if hc2 > 0:
				Sound.play_sfx_replace(Sound.Fx.HIT_ENTITY, 1.2, 0.8)
			temp_area.queue_free()
			return

	var radius: float = 24.0 * reach_multiplier
	var offset := Vector2.ZERO
	match last_dir:
		"right":
			offset = Vector2(radius * 0.6, 0)
		"left":
			offset = Vector2(-radius * 0.6, 0)
		"up":
			offset = Vector2(0, -radius * 0.6)
		_:
			offset = Vector2(0, radius * 0.6)

	var query_shape := CircleShape2D.new()
	query_shape.radius = radius

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = query_shape
	var xform := Transform2D.IDENTITY
	xform.origin = self.global_position + offset
	params.transform = xform

	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.exclude = [self]

	params.collision_mask = 0xFFFFFFFF

	var space := get_world_2d().direct_space_state
	var results := space.intersect_shape(params, 32)

	if Engine.is_editor_hint() == false:
		GLogger.log("Player: melee query at %s found %d colliders (weapon=%s damage=%d)" % [str(xform.origin), results.size(), weapon_name, damage_val])

	var hit_targets_q: Array = []
	for r in results:
		var collider = r.get("collider")
		if collider == null:
			continue
		if Engine.is_editor_hint() == false:
			GLogger.log("Player: melee collider found: %s (type=%s) pos=%s" % [str(collider.name if "name" in collider else collider), typeof(collider), str(collider.global_position if "global_position" in collider else Vector2.ZERO)])
		var target: Node = null
		if collider is EnemyBase:
			target = collider
		else:
			target = WeaponUtils.get_enemy_node(collider)
			if target == null:
				continue
		if hit_targets_q.has(target):
			continue
		target.take_damage(damage_val, self)
		hit_targets_q.append(target)
		if Engine.is_editor_hint() == false:
			GLogger.log("Player: hit enemy %s for %d" % [target.name, damage_val])
		if hit_targets_q.size() >= max_hits_per_attack:
			break
	if Engine.is_editor_hint() == false:
		GLogger.log("Player: melee hit applied to %d enemies" % hit_targets_q.size())

	if hit_targets_q.size() > 0:
		Sound.play_sfx_replace(Sound.Fx.HIT_ENTITY, 1.2, 0.8)


func _setup_hitboxes() -> void:
	var stack: Array[Node] = []
	stack.append(self)
	while stack.size() > 0:
		var n: Node = stack.pop_back() as Node
		for raw_child in n.get_children():
			if typeof(raw_child) != TYPE_OBJECT:
				continue
			var c: Node = raw_child as Node
			var nm: String = c.name
			var low: String = nm.to_lower()
			if low.begins_with("hit_") or low.begins_with("attack_"):
				if c is Area2D:
					var aarea: Area2D = c as Area2D
					aarea.monitoring = false
					_hit_areas[nm] = aarea
					if Engine.is_editor_hint() == false:
						GLogger.log("Player: found Area2D hitbox '%s' and disabled monitoring" % nm)
				else:
					var has_shape: bool = false
					for raw_cc in c.get_children():
						if raw_cc is CollisionShape2D:
							has_shape = true
							break
					if has_shape:
						_hit_areas[nm] = c
						if Engine.is_editor_hint() == false:
							GLogger.log("Player: found hit node '%s' (Node2D with CollisionShape2D)" % nm)
			stack.append(c)

func _ready() -> void:
	self.name = "Player"
	GEntityAdmin.register_entity(self)

	GPostProcessing.fade_from_black()

	ingredient_inventory.resize(Ingredient.IngredientType.keys().size())



	add_child(hud_scene.instantiate())
	set_camera_zoom()

	if sprite == null:
		var found := _locate_sprite_node()
		if found != null:
			sprite = found

	var using_animated: bool = false
	if sprite != null:
		using_animated = sprite is AnimatedSprite2D

	if sprite == null:
		GLogger.log("Player: sprite node not found (sprite == null)")
	else:
		GLogger.log("Player: sprite node found; AnimatedSprite2D=%s" % [str(using_animated)])
	if using_animated:
		play_anim_action("idle", last_dir)
	else:
		if sprite != null:
			_setup_texture_and_anim(IDLE_SPRITES.get(last_dir), DEFAULT_ANIM_SPEED)

	_rng.randomize()

	_setup_hitboxes()

	_damage_cooldown_timer = Timer.new()
	_damage_cooldown_timer.wait_time = damage_cooldown
	_damage_cooldown_timer.one_shot = true
	_damage_cooldown_timer.autostart = false
	_damage_cooldown_timer.connect("timeout", Callable(self, "_on_damage_cooldown_timeout"))
	add_child(_damage_cooldown_timer)



func _physics_process(delta: float) -> void:
	if mov_body == null:
		return

	if not can_move:
		return

	handle_player_movement(delta)
	mov_body.move_and_slide()


func handle_player_movement(delta: float) -> void:
	var direction := Vector2.ZERO

	direction = Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown")

	if direction != Vector2.ZERO:
		var dir_name := get_direction_name(direction)
		last_dir = dir_name
		if not is_attacking:
			play_anim_action("run", dir_name)
	else:
		if not is_attacking:
			play_anim_action("idle", last_dir)

	mov_body.velocity = direction.normalized() * mov_speed * delta


func get_direction_name(direction: Vector2) -> String:
	if direction == Vector2.ZERO:
		return last_dir

	if abs(direction.x) > abs(direction.y):
		if direction.x < 0:
			return "left"
		return "right"
	else:
		if direction.y < 0:
			return "up"
		return "down"




func _debug_force_hit() -> void:
	var dmg: int = 6
	if weapon_inventory.size() > 0 and weapon_inventory[0] != null:
		var w := weapon_inventory[0]
		if "damage" in w:
			dmg = int(w.damage)

	var radius: float = 24.0 * reach_multiplier
	var offset := Vector2.ZERO
	match last_dir:
		"right":
			offset = Vector2(radius * 0.6, 0)
		"left":
			offset = Vector2(-radius * 0.6, 0)
		"up":
			offset = Vector2(0, -radius * 0.6)
		_:
			offset = Vector2(0, radius * 0.6)

	var query_shape := CircleShape2D.new()
	query_shape.radius = radius

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = query_shape
	var origin := self.global_position + offset
	var xform := Transform2D.IDENTITY
	xform.origin = origin
	params.transform = xform
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.exclude = [self]
	params.collision_mask = 0xFFFFFFFF

	var space := get_world_2d().direct_space_state
	var results := space.intersect_shape(params, 32)

	if results.size() == 0:
		GLogger.log("Player: debug_force_hit - no colliders in melee area at %s" % [str(origin)])
		return

	var best: Node = null
	var best_dist := INF
	for r in results:
		var c = r.get("collider")
		if c == null:
			continue
		var dist = origin.distance_to(c.global_position if "global_position" in c else Vector2.ZERO)
		if c is EnemyBase and dist < best_dist:
			best = c
			best_dist = dist

	if best == null:
		GLogger.log("Player: debug_force_hit - no enemy colliders found (found %d colliders)" % [results.size()])
		return

	GLogger.log("Player: debug_force_hit - hitting nearest enemy %s at dist %.1f for %d" % [str(best.name), best_dist, dmg])
	best.take_damage(dmg, self)
	Sound.play_sfx_replace(Sound.Fx.HIT_ENTITY, 1.2, 0.8)


func set_health(value: int) -> void:
	self.health = value

	update_health_status()


func set_max_health(value: int) -> void:
	self.max_health = value

	set_health(min(health, max_health))
	update_health_status()


func take_damage(_damage: int) -> void:
	if god_mode:
		return

	if health_status == HealthStatus.DEAD:
		return

	if not _can_take_damage:
		if Engine.is_editor_hint() == false:
			GLogger.log("Player: damage ignored due to cooldown")
		return

	_can_take_damage = false
	if _damage_cooldown_timer != null:
		_damage_cooldown_timer.start()


	set_health(max(health - 1, 0))
	damage_taken += 1

	Sound.play_sfx(Sound.Fx.HIT_PLAYER, 3, 0.5)
	EntityEffects.play_hit_anim(sprite, Color.PURPLE)

	if GPostProcessing.instance != null:
		GPostProcessing.flash_red(0.5, 0.18)

	if health <= 0:
		health_status = HealthStatus.DEAD
		die()


func _on_damage_cooldown_timeout() -> void:
	_can_take_damage = true
	if Engine.is_editor_hint() == false:
		GLogger.log("Player: damage cooldown ended; can_take_damage=%s" % [str(_can_take_damage)])




func update_player_rating(adaptive: bool, increase: float = 3.0) -> void:
	if adaptive:

		if damage_taken > 1:
			player_rating -= damage_taken
		else:
			player_rating += 5.0

	else:
		player_rating += increase



func update_health_status() -> void:
	if health == max_health:
		health_status = HealthStatus.FULL
		return

	var health_percent = float(health) / max_health
	if health_percent <= LOW_HEALTH_THRESHOLD:
		health_status = HealthStatus.LOW
	else:
		health_status = HealthStatus.NORMAL


func add_crystal(amount: int) -> void:
	crystals += amount

	if weapon_inventory.size() > 0 and weapon_inventory[0] != null:
		var w0 := weapon_inventory[0]
		if "add_progress" in w0:
			w0.add_progress(amount)

	level_progress += amount
	if level_progress >= level_required:
		level_up()


func level_up() -> void:
	level += 1
	level_progress = 0
	update_level_req()

	base_unarmed_damage += 1

	GLogger.log("Player: Level up to %d (base_unarmed_damage=%d)" % [level, base_unarmed_damage])
	Sound.play_sfx(Sound.Fx.FINISH_WAVE)


func update_level_req() -> void:
	@warning_ignore("narrowing_conversion")
	level_required = int(first_level_req * pow(level_req_multiplier, level))


func set_camera_zoom() -> void:
	camera.zoom = Vector2(
		STD_CAMERA_ZOOM + camera_zoom_offset, STD_CAMERA_ZOOM + camera_zoom_offset
	)


func die() -> void:
	mov_body.visible = false
	weapon_inventory.clear()
	can_move = false

	var death_effect = preload("res://content/effects/enemy/death_effect.tscn").instantiate()
	death_effect.global_position = self.global_position
	var _parent := GSceneAdmin.scene_root if GSceneAdmin.scene_root != null else GGameGlobals.instance
	_parent.add_child(death_effect)


	await create_tween().tween_interval(0.3).finished

	var death_menu = preload("res://content/ui/gameover_menu/gameover_menu.tscn").instantiate()
	GGameGlobals.instance.add_child(death_menu)

	GStateAdmin.pause_game(false)
