class_name GPostProcessing extends CanvasLayer

const COLOR_BLIND_SHADER: Shader = preload("res://content/shader/colorblind.gdshader")
const GAMMA_CORRECTION_SHADER: Shader = preload("res://content/shader/gamma.gdshader")

static var color_blind_filter: ColorRect = null
static var gamma_correction: ColorRect = null

static var fade_filter: ColorRect = null
static var fade_tween: Tween = null

static var red_flash: ColorRect = null
static var red_tween: Tween = null

static var instance: GPostProcessing = null

func _ready() -> void:
	self.name = "GPostProcessing"

	instance = self

	layer = 2

	color_blind_filter = ColorRect.new()
	add_child(color_blind_filter)
	color_blind_filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_blind_filter.anchors_preset = Control.PRESET_FULL_RECT
	color_blind_filter.material = ShaderMaterial.new()
	color_blind_filter.material.shader = COLOR_BLIND_SHADER
	color_blind_filter.visible = false

	var back_buffer_copy := BackBufferCopy.new()
	add_child(back_buffer_copy)
	back_buffer_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT

	gamma_correction = ColorRect.new()
	add_child(gamma_correction)
	gamma_correction.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gamma_correction.anchors_preset = Control.PRESET_FULL_RECT
	gamma_correction.material = ShaderMaterial.new()
	gamma_correction.material.shader = GAMMA_CORRECTION_SHADER

	fade_filter = ColorRect.new()
	add_child(fade_filter)
	fade_filter.color = Color(0, 0, 0, 0)
	fade_filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_filter.anchors_preset = Control.PRESET_FULL_RECT

	red_flash = ColorRect.new()
	add_child(red_flash)
	red_flash.color = Color(1, 0, 0, 0)
	red_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	red_flash.anchors_preset = Control.PRESET_FULL_RECT


static func set_color_blind_filter_mode(mode: LocalSettings.ColorBlindFilter) -> void:
	if mode == LocalSettings.ColorBlindFilter.NONE:
		color_blind_filter.visible = false
		return

	color_blind_filter.visible = true

	match mode:
		LocalSettings.ColorBlindFilter.PROTANOPIA:
			color_blind_filter.material.set_shader_parameter("mode", 0)
		LocalSettings.ColorBlindFilter.DEUTERANOPIA:
			color_blind_filter.material.set_shader_parameter("mode", 1)
		LocalSettings.ColorBlindFilter.TRITANOPIA:
			color_blind_filter.material.set_shader_parameter("mode", 2)


static func set_colorblind_filter_strength(strength: float) -> void:
	color_blind_filter.material.set_shader_parameter("intensity", strength)


static func set_gamma(strength: float) -> void:
	gamma_correction.material.set_shader_parameter("gamma", strength)



static func fade_to_black() -> void:
	if fade_tween:
		fade_tween.kill()

	fade_tween = instance.create_tween()
	fade_tween.tween_property(fade_filter, "color:a", 1, 3)


static func fade_from_black() -> void:
	fade_filter.color = Color(0, 0, 0, 1)
	if fade_tween:
		fade_tween.kill()

	fade_tween = instance.create_tween()
	fade_tween.tween_property(fade_filter, "color:a", 0, 3)


static func fade_transition(callback: Callable) -> void:
	if fade_tween:
		fade_tween.kill()

	fade_tween = instance.create_tween()
	fade_tween.tween_property(fade_filter, "color:a", 1, 0.5)
	await fade_tween.finished
	fade_tween.stop()
	callback.call()
	fade_tween.tween_property(fade_filter, "color:a", 0, 1)
	fade_tween.play()

	await fade_tween.finished


static func flash_red(duration: float = 1.0, intensity: float = 0.25) -> void:
	if red_tween:
		red_tween.kill()

	red_flash.color = Color(1, 0, 0, intensity)

	red_tween = instance.create_tween()
	red_tween.tween_property(red_flash, "color:a", 0.0, duration)
	await red_tween.finished
	red_tween.kill()

