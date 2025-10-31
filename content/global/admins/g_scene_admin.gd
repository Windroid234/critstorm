class_name GSceneAdmin extends Node
## GSceneAdmin is responsible for managing scene transitions
## and scene-related data within the game.

## Map to hold the scene names and their corresponding GameState and resource paths.
static var scene_map := {
	"TitleScreen":
	Pair.new(GStateAdmin.GameState.TITLE_SCREEN, "res://content/ui/title_screen/title_screen.tscn"),
	"MainMenu":
	Pair.new(GStateAdmin.GameState.MAIN_MENU, "res://content/ui/main_menu/main_menu.tscn"),
	"LevelMenu":
	Pair.new(GStateAdmin.GameState.LEVEL_SELECT, "res://content/ui/level_menu/level_menu.tscn"),
	"PrototypeLevel":
	Pair.new(GStateAdmin.GameState.PLAYING, "res://content/level/PrototypeLevel.tscn"),
	"FirstLevel":
	Pair.new(GStateAdmin.GameState.PLAYING, "res://content/level/first_level/first_level.tscn"),
}

static var scene_root: Node = null  ## Reference to the current scene root node.
static var level_base: LevelBase = null  ## Reference to the LevelBase node in the scene.


func _ready() -> void:
	self.name = "GSceneAdmin"

	GSceneAdmin.fill_level_data()


## Adds a new scene to the scene map for management.
## [scene_name]: The name of the scene to add.
## [scene_state]: The game state associated with the scene.
## [res_path]: The resource path to the scene file.
static func add_scene_to_map(
	scene_name: String, scene_state: GStateAdmin.GameState, res_path: String
) -> void:
	if scene_map.has(scene_name):
		GLogger.log("GSceneAdmin: Scene " + scene_name + " already exists", Color.RED)
		return
	scene_map[scene_name] = Pair.new(scene_state, res_path)


## Switches the current scene to the specified scene.
## [scene_name]: The name of the scene to switch to.
static func switch_scene(scene_name: String) -> void:
	if not scene_map.has(scene_name):
		GLogger.log("GSceneAdmin: Scene " + scene_name + " does not exist", Color.RED)
		return


	GSceneAdmin.scene_root = null
	GSceneAdmin.level_base = null
	GEntityAdmin.entities.clear()
	GEntityAdmin.player = null

	var scene_resource := load(scene_map[scene_name].second)
	var g_instance := GGameGlobals.instance
	g_instance.get_tree().change_scene_to_packed(scene_resource)
	fill_level_data(scene_name)


## Reloads the current scene.
static func reload_scene() -> void:
	GSceneAdmin.switch_scene(scene_root.name)


## Fills in level-specific data after a scene has been loaded.
static func fill_level_data(scene_name: String = "") -> void:
	await GGameGlobals.instance.get_tree().node_added

	scene_root = GGameGlobals.instance.get_tree().current_scene
	var root_name := scene_root.name

	if not scene_map.has(root_name):
		GLogger.log("GSceneAdmin: WARNING Scene " + root_name + " not in SceneMap", Color.YELLOW)

		# If the scene does not exist in the sceneMap, it is probably a level scene.
		# So we add it, with PLAYING state to be able to switch to it later.
		add_scene_to_map(root_name, GStateAdmin.GameState.PLAYING, scene_root.scene_file_path)

	# Unpause game on scene switch.
	GStateAdmin.unpause_game()
	# Set the GameState.
	if scene_name != "":
		GStateAdmin.game_state = scene_map[scene_name].first
	else:
		GStateAdmin.game_state = scene_map[root_name].first

	# Take the first Node which is of type LevelBase.
	# Try to find a LevelBase instance anywhere in the scene tree (recursively).
	level_base = _find_level_base(scene_root)
	if level_base != null:
		GLogger.log("GSceneAdmin: Found LevelBase: %s" % level_base.name)
		return

	GLogger.log("GSceneAdmin: Could not find LevelBase (scene root: %s)" % root_name)

	# As a last resort, auto-insert a minimal LevelBase so gameplay code can proceed,
	# but only do this for actual level scenes. We determine that by checking the
	# current game state; only scenes with PLAYING state should get an auto LevelBase.
	if GStateAdmin.game_state == GStateAdmin.GameState.PLAYING:
		# Load the LevelBase script and instantiate it so we have the expected API.
		var lb_script := load("res://content/level/level_base.gd")
		if lb_script != null:
			var auto_lb = lb_script.new()
			auto_lb.name = "LevelBase_auto"

			# Try to find an existing CanvasModulate to assign to level_modulate.
			var cm := _find_canvas_modulate(scene_root)
			if cm != null:
				auto_lb.level_modulate = cm
			else:
				# create a CanvasModulate so ambience changes won't crash
				var new_cm := CanvasModulate.new()
				scene_root.add_child(new_cm)
				auto_lb.level_modulate = new_cm

			scene_root.add_child(auto_lb)
			level_base = auto_lb
			GLogger.log("GSceneAdmin: Auto-inserted LevelBase into %s" % root_name)
			return
	else:
		GLogger.log("GSceneAdmin: Not a PLAYING scene (%s) — skipping auto-insert of LevelBase." % root_name)
		return

	# If we couldn't auto-insert, leave the warning in the logs.


## Recursively search for a LevelBase node under [node].
static func _find_level_base(node: Node) -> LevelBase:
	for child in node.get_children():
		if child is LevelBase:
			return child
		var res := _find_level_base(child)
		if res != null:
			return res
	return null


## Recursively search for a CanvasModulate node under [node].
static func _find_canvas_modulate(node: Node) -> CanvasModulate:
	for child in node.get_children():
		if child is CanvasModulate:
			return child
		var res := _find_canvas_modulate(child)
		if res != null:
			return res
	return null
