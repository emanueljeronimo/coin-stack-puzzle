class_name BootCoverLayoutService
extends RefCounted

const REF_WIDTH := 1080.0
const PLAY_WIDTH_RATIO := 0.46
const PLAY_BOTTOM_MARGIN := 0.0
const PLAY_Y_DROP := -90.0
const PLAY_VISIBLE_HEIGHT := 0.86
const SLOT_HEIGHT_RATIO := 0.28

static func cover_draw_rect(viewport_size: Vector2, tex_size: Vector2) -> Rect2:
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return Rect2(Vector2.ZERO, viewport_size)
	var cover_scale: float = maxf(viewport_size.x / tex_size.x, viewport_size.y / tex_size.y)
	var drawn_size: Vector2 = tex_size * cover_scale
	var offset: Vector2 = (viewport_size - drawn_size) * 0.5
	return Rect2(offset, drawn_size)

static func default_slot_size(cover_width: float) -> Vector2:
	var slot_w: float = cover_width * PLAY_WIDTH_RATIO
	return Vector2(slot_w, slot_w * SLOT_HEIGHT_RATIO)

static func play_slot_rect(viewport_size: Vector2, cover: Rect2, slot_size: Vector2) -> Rect2:
	var ui_scale: float = viewport_size.x / REF_WIDTH if REF_WIDTH > 0.0 else 1.0
	var slot_x: float = cover.position.x + (cover.size.x - slot_size.x) * 0.5
	var cover_bottom: float = minf(cover.position.y + cover.size.y, viewport_size.y)
	var slot_y: float = cover_bottom - slot_size.y - (PLAY_BOTTOM_MARGIN * ui_scale) + (PLAY_Y_DROP * ui_scale)
	var max_y: float = viewport_size.y - slot_size.y * PLAY_VISIBLE_HEIGHT
	slot_y = minf(slot_y, max_y)
	return Rect2(Vector2(slot_x, slot_y), slot_size)
