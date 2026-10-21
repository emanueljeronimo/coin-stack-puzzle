extends RefCounted

const TAB_DIAMONDS := 0
const TAB_RESOURCES := 1
const TAB_COMBOS := 2
const TAB_COUNT := 3

static func clamp_index(tab_index: int) -> int:
	return clampi(tab_index, 0, TAB_COUNT - 1)

static func titles() -> PackedStringArray:
	return PackedStringArray(["Diamantes", "Recursos", "Combos"])

static func is_page_visible(tab_index: int, page_index: int) -> bool:
	return clamp_index(tab_index) == page_index

