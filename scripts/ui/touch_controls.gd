class_name TouchControls
extends Control

## Landscape touch layer. No buttons, no bars.
## Left side: a stick that exists only while the thumb is down.
## Right side: drag to orbit. Two fingers: pinch to zoom.
## Keyboard and mouse keep working beside this.

const LEFT_FRACTION := 0.42
const DEADZONE := 0.12

var move_vector: Vector2 = Vector2.ZERO
var yaw_delta: float = 0.0
var zoom_delta: float = 0.0

var _pointers: Dictionary = {}
var _pinch_distance: float = -1.0
var _stick_origin: Vector2 = Vector2.ZERO
var _stick_knob: Vector2 = Vector2.ZERO
var _stick_visible: bool = false


func _enter_tree() -> void:
	add_to_group("touch_controls")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var local := make_input_local(event)
		if event.pressed:
			_pointers[event.index] = {"pos": local.position, "origin": local.position}
		else:
			_pointers.erase(event.index)
			if _pointers.size() < 2:
				_pinch_distance = -1.0
		_refresh()
	elif event is InputEventScreenDrag:
		if not _pointers.has(event.index):
			return
		var local := make_input_local(event)
		var previous: Vector2 = _pointers[event.index].pos
		_pointers[event.index].pos = local.position
		if _pointers.size() >= 2:
			_update_pinch()
			_hide_stick()
		elif _pinch_distance < 0.0:
			var data: Dictionary = _pointers[event.index]
			if data.origin.x <= size.x * LEFT_FRACTION:
				_show_stick(data.origin, data.pos)
			else:
				var drag: Vector2 = local.position - previous
				yaw_delta -= drag.x * 0.005
	elif event is InputEventMagnifyGesture:
		zoom_delta += (1.0 - event.factor) * 18.0


## Screen-space stick. Y is flipped so dragging up is forward.
static func stick_vector(origin: Vector2, current: Vector2, radius: float, deadzone: float) -> Vector2:
	if radius <= 0.001:
		return Vector2.ZERO
	var delta := current - origin
	var magnitude := delta.length()
	if magnitude < 0.001:
		return Vector2.ZERO
	var clamped := minf(magnitude, radius)
	var scaled := delta / radius * (clamped / magnitude)
	var output := Vector2(scaled.x, -scaled.y)
	if output.length() < deadzone:
		return Vector2.ZERO
	return output


func _refresh() -> void:
	if _pointers.size() >= 2:
		_update_pinch()
		_hide_stick()
		return
	if _pointers.is_empty():
		_hide_stick()
		return
	if _pinch_distance >= 0.0:
		_hide_stick()
		return
	var data: Dictionary = _pointers.values()[0]
	if data.origin.x <= size.x * LEFT_FRACTION:
		_show_stick(data.origin, data.pos)
	else:
		_hide_stick()


func _show_stick(origin: Vector2, current: Vector2) -> void:
	var radius := _radius()
	_stick_visible = true
	_stick_origin = origin
	var delta := current - origin
	if delta.length() > radius:
		delta = delta.normalized() * radius
	_stick_knob = origin + delta
	move_vector = stick_vector(origin, current, radius, DEADZONE)
	queue_redraw()


func _hide_stick() -> void:
	move_vector = Vector2.ZERO
	if _stick_visible:
		_stick_visible = false
		queue_redraw()


func _update_pinch() -> void:
	if _pointers.size() < 2:
		return
	var points: Array = _pointers.values()
	var first: Vector2 = points[0].pos
	var second: Vector2 = points[1].pos
	var dist := first.distance_to(second)
	if _pinch_distance > 8.0:
		var factor := dist / _pinch_distance
		zoom_delta += clampf((factor - 1.0) * 22.0, -3.5, 3.5)
	_pinch_distance = dist


func _radius() -> float:
	var height := size.y
	if height < 10.0:
		height = 720.0
	return clampf(height * 0.16, 64.0, 120.0)


func _draw() -> void:
	if not _stick_visible:
		return
	var radius := _radius()
	draw_circle(_stick_origin, radius, Color(1, 1, 1, 0.07))
	draw_arc(_stick_origin, radius, 0.0, TAU, 40, Color(1, 0.94, 0.82, 0.28), 2.0, true)
	draw_circle(_stick_knob, radius * 0.38, Color(1, 0.92, 0.78, 0.32))
