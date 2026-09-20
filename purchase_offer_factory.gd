class_name PurchaseOfferFactory
extends RefCounted

static func build_offer_button(amount: int, cost: int, star_icon: Texture2D, label_factory: Callable, on_pressed: Callable) -> Dictionary:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(on_pressed)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(center)

	var content := HBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(content)

	var qty_label: Label = label_factory.call("x%d" % amount, 52, Color(0.95, 0.98, 0.92))
	content.add_child(qty_label)

	var gem_icon := TextureRect.new()
	gem_icon.texture = star_icon
	gem_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gem_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gem_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(gem_icon)

	var cost_label: Label = label_factory.call(str(cost), 56, Color(0.95, 0.98, 0.92))
	content.add_child(cost_label)

	return {
		"button": btn,
		"center": center,
		"content": content,
		"qty_label": qty_label,
		"gem_icon": gem_icon,
		"cost_label": cost_label,
	}
