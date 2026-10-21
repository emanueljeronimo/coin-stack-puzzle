extends RefCounted
class_name LevelUpRewardService

## Diamantes al subir de nivel: desde el 5. El ad duplica.
## 20 hasta el 50, 25 hasta el 100, 30 despues.

const START_LEVEL := 5
const DIAMONDS_EARLY := 20
const DIAMONDS_MID := 25
const DIAMONDS_LATE := 30
const MID_FROM_LEVEL := 51
const LATE_FROM_LEVEL := 101
const DIAMONDS_PER_LEVEL := DIAMONDS_EARLY

static func should_grant(level: int) -> bool:
	return level >= START_LEVEL

static func base_diamonds(level: int) -> int:
	if not should_grant(level):
		return 0
	if level >= LATE_FROM_LEVEL:
		return DIAMONDS_LATE
	if level >= MID_FROM_LEVEL:
		return DIAMONDS_MID
	return DIAMONDS_EARLY

static func claim_diamonds(level: int, doubled: bool) -> int:
	var base := base_diamonds(level)
	if base <= 0:
		return 0
	if doubled:
		return base * 2
	return base
