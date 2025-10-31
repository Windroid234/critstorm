extends Button

enum ButtonState {
	NORMAL,
	FOCUSED,
	PRESSED,
}

const HOVER_SCALE := 1.05
const DOWN_SCALE := 1.02

var state: ButtonState = ButtonState.NORMAL
var std_scale: Vector2
var press_event := Callable()


func _ready() -> void:
	pressed.connect(on_pressed)
	focus_entered.connect(on_focus_begin)
	focus_exited.connect(on_focus_end)
	mouse_entered.connect(on_hover_begin)
	mouse_exited.connect(on_hover_end)
	button_down.connect(on_down)




func change_state(new_state: ButtonState) -> void:
	state = new_state

	match state:
		ButtonState.NORMAL:
			var t = create_tween()
			if t:
				t.tween_property(self, "scale", std_scale, 0.03)
		ButtonState.FOCUSED:
			var t = create_tween()
			if t:
				create_tween().tween_property(self, "scale", std_scale * HOVER_SCALE, 0.03)
		ButtonState.PRESSED:
			var t = create_tween()
			if t:
				create_tween().tween_property(self, "scale", std_scale * DOWN_SCALE, 0.03)


func on_pressed() -> void:
	if not press_event.is_null():
		press_event.call()


func on_down() -> void:
	Sound.play_sfx(Sound.Fx.CLICK, 2)



func on_focus_begin() -> void:
	Sound.play_sfx(Sound.Fx.HOVER, 2, 0.5)


func on_focus_end() -> void:
	pass

func on_hover_end() -> void:
	self.release_focus()

func on_hover_begin() -> void:
	self.grab_focus()
