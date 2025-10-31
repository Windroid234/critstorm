class_name GGameGlobals extends Node

static var instance: GGameGlobals = null


func _ready() -> void:
	self.name = "GGameGlobals"
	instance = self

	var is_debug := OS.is_debug_build()
	var platform := OS.get_name()


	if is_debug:
		add_debug_menus()

		GLogger.log("Running Debug-Build.", Color.YELLOW)
		GLogger.log("Platform: " + platform, Color.YELLOW)
	else:
		GLogger.log("Running Release-Build.", Color.YELLOW)

	add_child(GSceneAdmin.new())
	add_child(GStateAdmin.new())
	add_child(GEntityAdmin.new())
	add_child(GPostProcessing.new())


func add_debug_menus() -> void:
	setup_imgui()

	add_child(DebugMenuBar.new())


func setup_imgui() -> void:
	var io := ImGui.GetIO()
	io.ConfigFlags |= ImGui.ConfigFlags_DockingEnable

	var style := ImGui.GetStyle()
	style.WindowRounding = 10.0
