class_name WildcardFlowService
extends "res://booster_flow_service.gd"

## Alias legado de BoosterFlowService.

static func wildcard_action_kind(booster_type: String) -> String:
	return booster_action_kind(booster_type)
