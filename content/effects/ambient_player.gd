extends AudioStreamPlayer2D

var looped: bool = true

func _ready() -> void:
	if looped:
		var play_callable := Callable(self, "play")
		if not is_connected("finished", play_callable):
			connect("finished", play_callable)




