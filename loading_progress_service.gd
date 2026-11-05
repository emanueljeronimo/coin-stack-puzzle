class_name LoadingProgressService
extends RefCounted

## Ease the boot bar so a cached scene still looks like it is loading.
const START_TARGET := 0.10
const LOADING_CAP := 0.92
const CRAWL_CAP := 0.72
const CRAWL_PER_SEC := 0.18
const FINISH_THRESHOLD := 0.995
const SHIMMER_PERIOD := 1.15

static func mapped_load_target(load_ratio: float, current_target: float) -> float:
	var mapped: float = START_TARGET + clampf(load_ratio, 0.0, 1.0) * (LOADING_CAP - START_TARGET)
	return maxf(current_target, mapped)

static func next_target(current_target: float, load_ratio: float, delta: float, scene_loaded: bool) -> float:
	if scene_loaded:
		return 1.0
	var crawled: float = maxf(current_target, START_TARGET) + maxf(delta, 0.0) * CRAWL_PER_SEC
	var mapped: float = mapped_load_target(load_ratio, current_target)
	var cap: float = LOADING_CAP
	if load_ratio <= 0.0:
		cap = maxf(current_target, CRAWL_CAP)
	return clampf(maxf(mapped, crawled), current_target, cap)

static func step_display(display: float, target: float, delta: float) -> float:
	var t: float = clampf(display, 0.0, 1.0)
	var speed: float = lerpf(1.05, 0.42, t)
	return clampf(move_toward(display, target, maxf(delta, 0.0) * speed), 0.0, 1.0)

static func can_finish(scene_loaded: bool, display: float) -> bool:
	return scene_loaded and display >= FINISH_THRESHOLD

static func shimmer_x(elapsed: float, bar_w: float, band_w: float, period: float = SHIMMER_PERIOD) -> float:
	if bar_w <= 0.0 or period <= 0.0:
		return -band_w
	var span: float = bar_w + band_w
	var u: float = fposmod(elapsed / period, 1.0)
	return u * span - band_w
