class_name LoadingProgressService
extends RefCounted

const FINISH_THRESHOLD := 0.995
const SHIMMER_PERIOD := 1.15
const CATCHUP_PER_SEC := 8.0

static func mapped_load_target(load_ratio: float, current_target: float) -> float:
	return maxf(current_target, clampf(load_ratio, 0.0, 1.0))

static func next_target(current_target: float, load_ratio: float, _delta: float, scene_loaded: bool) -> float:
	if scene_loaded:
		return 1.0
	return mapped_load_target(load_ratio, current_target)

static func step_display(display: float, target: float, delta: float) -> float:
	return clampf(
		move_toward(display, target, maxf(delta, 0.0) * CATCHUP_PER_SEC),
		0.0,
		1.0
	)

static func can_finish(scene_loaded: bool, display: float) -> bool:
	return scene_loaded and display >= FINISH_THRESHOLD

static func shimmer_x(elapsed: float, bar_w: float, band_w: float, period: float = SHIMMER_PERIOD) -> float:
	if bar_w <= 0.0 or period <= 0.0:
		return -band_w
	var span: float = bar_w + band_w
	var u: float = fposmod(elapsed / period, 1.0)
	return u * span - band_w
