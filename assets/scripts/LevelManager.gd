extends Node2D

var container
var player
var drag_indicator

var max_displacement = 50.0
var close_point_threshold = 30.0

func _ready():
	container = get_node("Container")
	player = get_node("Player")
	drag_indicator = get_node("DragIndicator")
	player.teleport(container.curve.interpolate(0,0))

func _input(event):
	if event is InputEventScreenDrag:
		drag_indicator.update_line(event, player.position)
	if event is InputEventScreenTouch:
		if event.pressed:
			drag_indicator.initialise(event.position)
			drag_indicator.show()
		else:
			drag_indicator.hide()

func _input_old(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			var target_position = get_node("Crosshair").position
			var to_point = container.curve.get_closest_point(target_position)
			var new_point = container.linear_extrapolation(player.position, to_point,
				min(max_displacement, (player.position - target_position).length()))
			var moved_already_created_point = false
			for idx in range(container.curve.get_point_count()):
				var point_position = container.curve.get_point_position(idx)
				if point_position.distance_to(to_point) < close_point_threshold:
					container.curve.set_point_position(idx, point_position + (new_point - to_point))
					moved_already_created_point = true
			if not moved_already_created_point:
				container.insert_new_point(new_point, to_point)
			container.update()
			player.move_to(container.curve.get_closest_point(new_point))
	elif event is InputEventMouseMotion:
		var baked_points = container.curve.get_baked_points()
		var intersection_points = []
		for idx in range(len(baked_points)-1):
			var intersect_point = Geometry.line_intersects_line_2d(
				baked_points[idx], baked_points[idx+1]-baked_points[idx],
				player.position, event.position-player.position)
			if ((sign(baked_points[idx].x - intersect_point.x) != sign(baked_points[idx+1].x - intersect_point.x)) and
				(sign(baked_points[idx].y - intersect_point.y) != sign(baked_points[idx+1].y - intersect_point.y)) and
				(intersect_point - player.position).length() > 5 and 
				player.position.distance_to(intersect_point) < event.position.distance_to(intersect_point)):
				intersection_points.append(intersect_point)
		var distances = []
		for point in intersection_points:
			distances.append(player.position.distance_to(point))
		var target_idx = distances.find(distances.min())
		if target_idx >= 0:
			get_node("Crosshair").position = intersection_points[target_idx]
			get_node("Crosshair").show()
		else:
			get_node("Crosshair").hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
