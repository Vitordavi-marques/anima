tool
extends Control
class_name AnimaAnimatable

const BASE_PROPERTIES := {
	ANIMATE_PROPERTY_CHANGE = {
		name = "Animation/AnimatePropertyChange",
		type = TYPE_BOOL,
		default = true
	},
	ANIMATION_SPEED = {
		name = "Animation/Speed",
		type = TYPE_REAL,
		default = 0.15
	},
	ANIMATION_EASING = {
		name = "Animation/Easing",
		type = TYPE_INT,
		hint = PROPERTY_HINT_ENUM,
		hint_string = AnimaEasing.EASING,
		default = Anima.EASING.LINEAR
	},
}

var _property_list := AnimaPropertyList.new()
var _is_animating_property_change := false

func _init():
	_add_properties(BASE_PROPERTIES)

func _add_properties(properties: Dictionary) -> void:
	for key in properties:
		_property_list.add(properties[key])

func _add_property(name: String, value: Dictionary) -> void:
	value.name = name

	_property_list.add(value)

func _hide_properties(properties: Dictionary) -> void:
	for key in properties:
		_property_list.hide(properties[key].name)

func _get(property: String):
	return _property_list.get(property)

func _set(property: String, value):
	if not _property_list.exists(property):
		return

	var old_value = _property_list.get(property)

	_property_list.set(property, value)

	var has_value_changed = old_value != value

	if value is bool or value is String:
		return update()

	if not is_inside_tree() or \
		not has_value_changed:
			return

	var animate_property_change = get_property(BASE_PROPERTIES.ANIMATE_PROPERTY_CHANGE.name)

	if _is_animating_property_change or not animate_property_change:
		update()
	else:
		var from = old_value if Engine.editor_hint else null

		animate_param(property, value, from)

func set(name: String, value) -> void:
	var old_value = get_property(BASE_PROPERTIES.ANIMATE_PROPERTY_CHANGE.name)

	_property_list.set(BASE_PROPERTIES.ANIMATE_PROPERTY_CHANGE.name, false)
	.set(name, value)

	_property_list.set(BASE_PROPERTIES.ANIMATE_PROPERTY_CHANGE.name, old_value)


func _get_property_list() -> Array:
	if _property_list:
		return _property_list.get_property_list()

	return []

func get_property(name: String):
	return _get(name)

func get_property_initial_value(key: String):
	return _property_list.get_initial_value(key)

func animate_param(property: String, value, from = null) -> void:
	var animation := Anima.Node(self)

	animation.anima_property(property)

	if from != null:
		animation.anima_from(from)

	var easing: int = get_property(BASE_PROPERTIES.ANIMATION_EASING.name)
	var duration: float = get_property(BASE_PROPERTIES.ANIMATION_SPEED.name)

	animation.anima_to(value)
	animation.anima_duration(duration)
	animation.anima_easing(easing)

	animate([animation])

func animate_params(params: Array) -> void:
	var animations := []
	var easing: int = get_property(BASE_PROPERTIES.ANIMATION_EASING.name)
	var duration: float = get_property(BASE_PROPERTIES.ANIMATION_SPEED.name)

	for param in params:
		var animation := Anima.Node(self)

		animation.anima_property(param.property)

		if param.has("from"):
			animation.anima_from(param.from)

		animation.anima_to(param.to)
		animation.anima_duration(duration)
		animation.anima_easing(easing)

		animations.push_back(animation)

	animate(animations)

func animate(anima_data: Array) -> AnimaNode:
	var anima: AnimaNode = Anima.begin_single_shot(self)

	for data in anima_data:
		anima.with(data)

	_is_animating_property_change = true

	anima.play()
	yield(anima, "animation_completed")

	_is_animating_property_change = false

	return anima

func set_position(position: Vector2, default := false):
	animate_param("position", position)