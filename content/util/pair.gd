class_name Pair

var first
var second


func _init(first_type: Variant, second_type: Variant):
	self.first = first_type
	self.second = second_type


func swap() -> void:
	var tmp = self.first
	self.first = self.second
	self.second = tmp
