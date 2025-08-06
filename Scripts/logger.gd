extends Node

class_name logger

var is_log_enabled : bool = true
var is_time_needed : bool = true

var logger_node : log

func log(_name : String = "", log_text : String = ""):
	var time : String = ""
	if is_time_needed:
		time = str(float(Time.get_ticks_msec() / 1000.0))
	if is_log_enabled:
		logger_node.add_text_to_log(str(_name, " ", log_text, " ", time))

func setup_log(_logger_node):
	logger_node = _logger_node
