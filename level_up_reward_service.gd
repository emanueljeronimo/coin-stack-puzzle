extends RefCounted
class_name LevelUpRewardService

## Estrellas al subir de nivel: desde el 5, 10 por subida. El ad duplica.

const START_LEVEL := 5
const STARS_PER_LEVEL := 10

static func should_grant(level: int) -> bool:
	return level >= START_LEVEL

static func base_stars(level: int) -> int:
	if not should_grant(level):
		return 0
	return STARS_PER_LEVEL

static func claim_stars(level: int, doubled: bool) -> int:
	var base := base_stars(level)
	if base <= 0:
		return 0
	if doubled:
		return base * 2
	return base
