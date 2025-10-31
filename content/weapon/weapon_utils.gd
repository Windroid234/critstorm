class_name WeaponUtils

enum WeaponType {
	SWORD,
}

static var weapon_map: Dictionary = {
	WeaponType.SWORD: preload("res://content/weapon/sword/sword.tscn"),
}

static func get_closest_enemy(node: Node2D, _range_area: Area2D) -> Node2D:
	var closest_enemy = null
	var closest_distance = INF

	for body in GEntityAdmin.entities:
		if body is EnemyBase:
			var distance = node.global_position.distance_to(body.global_position)

			if distance < closest_distance:
				closest_distance = distance
				closest_enemy = body


	return closest_enemy


static func get_enemy_node(node: Node2D) -> Node2D:
	for child in node.get_children():
		if child is EnemyBase:
			return child

	return null

static func add_weapon_to_player(weapon: WeaponType) -> void:
	var player := GEntityAdmin.player

	if player == null:
		return

	var weapon_scene = weapon_map[weapon].instantiate()


	player.weapon_inventory.push_front(weapon_scene)


	update_weapon_slots()

	if player.weapon_inventory.size() > player.MAX_WEAPONS:
		var weapon_to_remove = player.weapon_inventory.pop_back()

		if weapon_to_remove != null:
			weapon_to_remove.queue_free()


	player.add_child(weapon_scene)

static func discard_weapon_from_player(slot: int) -> void:
	var player := GEntityAdmin.player

	if player == null:
		return

	var inv = player.weapon_inventory

	if slot < 0 or slot >= inv.size():
		return

	var weapon_to_remove = inv[slot]
	inv.erase(slot)
	update_weapon_slots()
	weapon_to_remove.queue_free()

static func update_weapon_slots() -> void:
	var player := GEntityAdmin.player

	if player == null:
		return

	var set_weapon_slots = func() -> void:
		if player.weapon_inventory.size() == 0:
			return

		for i in player.weapon_inventory.size():
			if player.weapon_inventory[i] == null:
				continue

			player.weapon_inventory[i].weapon_slot = i + 1

	set_weapon_slots.call()
