class_name DialogVisibilityService
extends RefCounted

static func is_visible(node: CanvasItem) -> bool:
	return node != null and node.visible

static func any_visible(nodes: Array) -> bool:
	for node in nodes:
		if node is CanvasItem and (node as CanvasItem).visible:
			return true
	return false
