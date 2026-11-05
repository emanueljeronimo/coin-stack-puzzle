extends RefCounted

static func palette_index(value: int, palette_size: int) -> int:
	if value <= 0 or palette_size <= 0:
		return 0
	return (value - 1) % palette_size

static func wrap_cycle(value: int, palette_size: int) -> int:
	if value <= 0 or palette_size <= 0:
		return 0
	return int((value - 1) / palette_size)

## Diferencia maxima por canal. Sirve para detectar rosados/verdes duplicados.
static func max_channel_delta(a: Color, b: Color) -> float:
	return maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b)))
