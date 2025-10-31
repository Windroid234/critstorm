class_name GLogger

const LOG_BUF_SIZE := 200
static var log_buffer: Array = []


static func log(msg: String, color: Color = Color.GRAY) -> void:
	var now := Time.get_time_dict_from_system()
	var time_str := "%02d:%02d:%02d" % [now.hour, now.minute, now.second]

	print_rich(
		(
			"[color=%s][%s][LOG][/color][color=%s] %s[/color]"
			% [Color.ORANGE.to_html(), time_str, color.to_html(), msg]
		)
	)

	var buf_msg := "[%s][LOG] %s" % [time_str, msg]
	var buf_pair := Pair.new(color, buf_msg)
	log_buffer.append(buf_pair)

	if log_buffer.size() > LOG_BUF_SIZE:
		log_buffer.pop_front()


static func clear_log_buffer() -> void:
	log_buffer.clear()
