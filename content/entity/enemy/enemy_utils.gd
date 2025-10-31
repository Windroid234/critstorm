class_name EnemyUtils


static func move_to_player(mov_body: CharacterBody2D, mov_speed: float, delta: float) -> void:
	var player := GEntityAdmin.player
	if player == null or mov_body == null:
		return

	var direction := Vector2.ZERO

	direction = mov_body.global_position.direction_to(player.mov_body.global_position)

	mov_body.velocity = direction.normalized() * mov_speed * delta


static func move_to_direction(
	mov_body: CharacterBody2D, direction: Vector2, mov_speed: float, delta: float
) -> void:
	mov_body.velocity = direction.normalized() * mov_speed * delta


static func spawn_loot(
	pos: Vector2,
	crystal_rating: float,
	ingredient: Ingredient.IngredientType,
	ingredient_chance: float = 0.5
) -> void:
	var crystal_spawned = false

	var rand_large = randf_range(0.0, 1.0)
	if rand_large <= crystal_rating * 0.5:
		PickupUtils.spawn_crystal(pos, PickupUtils.CrystalType.LARGE)
		crystal_spawned = true

	var rand_med = randf_range(0.0, 1.0)
	if not crystal_spawned and rand_med <= crystal_rating * 0.8:
		PickupUtils.spawn_crystal(pos, PickupUtils.CrystalType.MED)
		crystal_spawned = true

	if not crystal_spawned:
		PickupUtils.spawn_crystal(pos, PickupUtils.CrystalType.SMALL)

	if ingredient == Ingredient.IngredientType.NONE:
		return

	var rand = randf_range(0.0, 1.0)
	if rand <= ingredient_chance:

		var rand_pos = pos + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		PickupUtils.spawn_ingredient(rand_pos, ingredient)

static func flip_sprite(sprite: Sprite2D, mov_body: CharacterBody2D) -> void:
	if mov_body.velocity.x < 0:
		sprite.flip_h = true
	elif mov_body.velocity.x > 0:
		sprite.flip_h = false
