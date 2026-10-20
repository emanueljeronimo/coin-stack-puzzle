class_name WavyDialogCardService
extends RefCounted

const FILL_TOP := Color(0.93, 0.99, 0.94, 1.0)
const FILL_BOTTOM := Color(0.86, 0.96, 0.88, 1.0)
const WAVE_COUNT := 10
const BASE_AMPLITUDE := 18.0
const BASE_CORNER := 52.0

static func amplitude_for_scale(ui_scale: float) -> float:
	return clampf(BASE_AMPLITUDE * ui_scale, 14.0, 26.0)

static func corner_for_scale(ui_scale: float) -> float:
	return clampf(BASE_CORNER * ui_scale, 36.0, 64.0)

static func vertex_fill_color(point: Vector2, size: Vector2) -> Color:
	var t: float = 0.0
	if size.y > 0.001:
		t = clampf(point.y / size.y, 0.0, 1.0)
	return FILL_TOP.lerp(FILL_BOTTOM, t)

static func fill_colors_for(points: PackedVector2Array, size: Vector2) -> PackedColorArray:
	var colors := PackedColorArray()
	colors.resize(points.size())
	for i in range(points.size()):
		colors[i] = vertex_fill_color(points[i], size)
	return colors

static func rainbow_at(t: float) -> Color:
	var hue: float = fposmod(0.94 - t * 0.78, 1.0)
	var rainbow := Color.from_hsv(hue, 0.72, 0.98, 1.0)
	return rainbow.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.10)

static func perimeter_rainbow_colors(count: int) -> PackedColorArray:
	var colors := PackedColorArray()
	if count <= 0:
		return colors
	colors.resize(count)
	for i in range(count):
		colors[i] = rainbow_at(float(i) / float(count))
	return colors

static func closed_rainbow_colors(count: int) -> PackedColorArray:
	var colors: PackedColorArray = perimeter_rainbow_colors(count)
	if colors.size() > 0:
		colors.append(colors[0])
	return colors

static func border_quad(
	outer: PackedVector2Array,
	inner: PackedVector2Array,
	index: int
) -> PackedVector2Array:
	var n: int = outer.size()
	var next_i: int = (index + 1) % n
	return PackedVector2Array([
		outer[index],
		outer[next_i],
		inner[next_i],
		inner[index],
	])

static func build_wave_points(
	size: Vector2,
	amplitude: float,
	wave_count: int,
	corner_radius: float
) -> PackedVector2Array:
	if size.x < 16.0 or size.y < 16.0:
		return PackedVector2Array()
	var amp: float = maxf(amplitude, 1.0)
	var inset: float = amp
	var inner := Vector2(size.x - inset * 2.0, size.y - inset * 2.0)
	if inner.x < 12.0 or inner.y < 12.0:
		return PackedVector2Array()
	var radius: float = minf(corner_radius, minf(inner.x, inner.y) * 0.42)
	var base := _rounded_rect_points(inner, radius)
	for i in range(base.size()):
		base[i] = base[i] + Vector2(inset, inset)
	return offset_by_wave(base, amp, maxi(wave_count, 3))

static func offset_by_wave(
	points: PackedVector2Array,
	amplitude: float,
	wave_count: int
) -> PackedVector2Array:
	var n: int = points.size()
	var out := PackedVector2Array()
	if n < 8:
		return out
	out.resize(n)
	var perim := 0.0
	var segs := PackedFloat32Array()
	segs.resize(n)
	for i in range(n):
		var d: float = points[i].distance_to(points[(i + 1) % n])
		segs[i] = d
		perim += d
	if perim <= 0.001:
		return points
	var s := 0.0
	var waves: float = float(wave_count)
	for i in range(n):
		var tangent: Vector2 = points[(i + 1) % n] - points[(i - 1 + n) % n]
		var normal := Vector2(tangent.y, -tangent.x)
		if normal.length_squared() > 0.000001:
			normal = normal.normalized()
		else:
			normal = Vector2.UP
		var t: float = s / perim
		var wave: float = 0.55 + 0.45 * sin(t * waves * TAU)
		out[i] = points[i] + normal * (amplitude * wave)
		s += segs[i]
	return out

static func inset_along_normals(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var n: int = points.size()
	var out := PackedVector2Array()
	if n < 8:
		return out
	out.resize(n)
	for i in range(n):
		var tangent: Vector2 = points[(i + 1) % n] - points[(i - 1 + n) % n]
		var normal := Vector2(tangent.y, -tangent.x)
		if normal.length_squared() > 0.000001:
			normal = normal.normalized()
		else:
			normal = Vector2.UP
		out[i] = points[i] - normal * amount
	return out

static func translated(points: PackedVector2Array, delta: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(points.size())
	for i in range(points.size()):
		out[i] = points[i] + delta
	return out

static func closed_polyline(points: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array(points)
	if points.size() > 0:
		out.append(points[0])
	return out

static func _rounded_rect_points(size: Vector2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var w: float = size.x
	var h: float = size.y
	var r: float = minf(maxf(radius, 8.0), minf(w, h) * 0.5)
	var samples_x: int = maxi(int(w / 14.0), 12)
	var samples_y: int = maxi(int(h / 14.0), 10)
	var corner_samples: int = 8
	_append_line(pts, Vector2(r, 0.0), Vector2(w - r, 0.0), samples_x)
	_append_arc(pts, Vector2(w - r, r), r, -PI * 0.5, 0.0, corner_samples)
	_append_line(pts, Vector2(w, r), Vector2(w, h - r), samples_y)
	_append_arc(pts, Vector2(w - r, h - r), r, 0.0, PI * 0.5, corner_samples)
	_append_line(pts, Vector2(w - r, h), Vector2(r, h), samples_x)
	_append_arc(pts, Vector2(r, h - r), r, PI * 0.5, PI, corner_samples)
	_append_line(pts, Vector2(0.0, h - r), Vector2(0.0, r), samples_y)
	_append_arc(pts, Vector2(r, r), r, PI, PI * 1.5, corner_samples)
	return pts

static func _append_line(pts: PackedVector2Array, a: Vector2, b: Vector2, samples: int) -> void:
	var n: int = maxi(samples, 2)
	for i in range(n):
		var t: float = float(i) / float(n)
		pts.append(a.lerp(b, t))

static func _append_arc(
	pts: PackedVector2Array,
	center: Vector2,
	radius: float,
	a0: float,
	a1: float,
	samples: int
) -> void:
	var n: int = maxi(samples, 2)
	for i in range(n):
		var t: float = float(i) / float(n)
		var ang: float = lerpf(a0, a1, t)
		pts.append(center + Vector2(cos(ang), sin(ang)) * radius)
