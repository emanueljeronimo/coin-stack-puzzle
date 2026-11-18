class_name PlayDaysService
extends RefCounted

static func today_key() -> String:
	return day_key_from_dict(Time.get_date_dict_from_system())

static func day_key_from_dict(date: Dictionary) -> String:
	return "%04d-%02d-%02d" % [
		int(date.get("year", 0)),
		int(date.get("month", 0)),
		int(date.get("day", 0)),
	]

static func tick(saved_day: String, saved_count: int, today: String) -> Dictionary:
	var count: int = maxi(int(saved_count), 0)
	var day := str(saved_day).strip_edges()
	var now := str(today).strip_edges()
	if now.is_empty():
		return {"day": day, "count": maxi(count, 1)}
	if day == now:
		return {"day": now, "count": maxi(count, 1)}
	if day.is_empty():
		return {"day": now, "count": maxi(count, 1)}
	return {"day": now, "count": count + 1}
