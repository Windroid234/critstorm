extends GPUParticles2D


func _ready() -> void:
	self.emitting = true
	var del_callable := Callable(self, "delete")
	if not is_connected("finished", del_callable):
		connect("finished", del_callable)


func delete() -> void:
	self.get_parent().queue_free()
