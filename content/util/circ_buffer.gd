class_name CircBuffer

var buffer: Array
var buf_size: int


func _init(size: int):
	self.buffer = []
	self.buf_size = size


func push_back(element: Variant) -> void:
	self.buffer.push_back(element)
	if self.buffer.size() > self.buf_size:
		self.buffer.pop_front()


func pop_front() -> Variant:
	return self.buffer.pop_front()


func empty() -> bool:
	return self.buffer.is_empty()
