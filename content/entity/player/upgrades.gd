class_name Upgrades



class Upgrade:
    var name: String
    var description: String
    var icon_texture: Texture2D
    var cost: Pair

    var level: int

    var upgrade_func: Callable



static func heal_player() -> void:
    var cost := Pair.new(Ingredient.IngredientType.BATWING, 10)
    if GEntityAdmin.player.ingredient_inventory[cost.first] < cost.second:
        return

    GEntityAdmin.player.ingredient_inventory[cost.first] -= cost.second

    var player := GEntityAdmin.player
    player.health = player.max_health

    Sound.play_sfx(Sound.Fx.BREWING_BOTTLE)

static func upgrade_mov_speed(free: bool = false) -> void:
    if not free:
        var cost := Pair.new(Ingredient.IngredientType.FUNGUS, 10)

        if GEntityAdmin.player.ingredient_inventory[cost.first] < cost.second:
            return

        GEntityAdmin.player.ingredient_inventory[cost.first] -= cost.second

    var player := GEntityAdmin.player
    var amount = 480
    player.mov_speed += amount

    Sound.play_sfx(Sound.Fx.BREWING_BOTTLE)

static func upgrade_attack_speed(free: bool = false) -> void:
    if not free:
        var cost := Pair.new(Ingredient.IngredientType.RATTAIL, 10)

        if GEntityAdmin.player.ingredient_inventory[cost.first] < cost.second:
            return

        GEntityAdmin.player.ingredient_inventory[cost.first] -= cost.second

    var player := GEntityAdmin.player
    var amount := player.attack_speed * 0.1
    player.attack_speed -= amount

    Sound.play_sfx(Sound.Fx.BREWING_BOTTLE)

static func apply_reach_potion(free: bool = false) -> void:
    var player := GEntityAdmin.player
    if player == null:
        GLogger.log("Upgrades: apply_reach_potion called but no player instance")
        return

    if not free:
        var cost := Pair.new(Ingredient.IngredientType.RATTAIL, 10)
        var have := player.ingredient_inventory[cost.first]
        GLogger.log("Upgrades: reach potion requested - have=%d rattails, cost=%d" % [have, cost.second])
        if have < cost.second:
            GLogger.log("Upgrades: not enough rattails for reach potion")
            return
        player.ingredient_inventory[cost.first] -= cost.second

    var before: float = player.reach_multiplier
    player.reach_multiplier = min(player.reach_multiplier + 0.10, 2.0)
    GLogger.log("Upgrades: reach potion applied - reach_multiplier %.2f -> %.2f" % [before, player.reach_multiplier])
    Sound.play_sfx(Sound.Fx.BREWING_BOTTLE)

static func apply_swiftness_potion(free: bool = false) -> void:
    if not free:
        var cost := Pair.new(Ingredient.IngredientType.FUNGUS, 15)
        if GEntityAdmin.player.ingredient_inventory[cost.first] < cost.second:
            return
        GEntityAdmin.player.ingredient_inventory[cost.first] -= cost.second

    var player := GEntityAdmin.player
    player.mov_speed *= 1.02
    Sound.play_sfx(Sound.Fx.BREWING_BOTTLE)

static func apply_multiply_potion(free: bool = false) -> void:
    var player := GEntityAdmin.player
    if player == null:
        GLogger.log("Upgrades: apply_multiply_potion called but no player instance registered")
        return

    if not free:
        var cost := Pair.new(Ingredient.IngredientType.FUNGUS, 10)
        var have := player.ingredient_inventory[cost.first]
        GLogger.log("Upgrades: multiply potion requested - have=%d fungus, cost=%d" % [have, cost.second])
        if have < cost.second:
            GLogger.log("Upgrades: not enough fungus for multiply potion")
            return
        player.ingredient_inventory[cost.first] -= cost.second

    var before := player.max_hits_per_attack
    player.max_hits_per_attack = min(player.max_hits_per_attack + 1, 10)
    GLogger.log("Upgrades: multiply potion applied - max_hits_per_attack %d -> %d" % [before, player.max_hits_per_attack])
    Sound.play_sfx(Sound.Fx.BREWING_BOTTLE)

