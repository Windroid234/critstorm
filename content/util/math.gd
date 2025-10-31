class_name Math


static func accumulate(arr: Array) -> Variant:
	var sum := 0
	for i in arr:
		sum += i
	return sum
