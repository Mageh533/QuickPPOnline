extends Polygon2D

func _draw():
	var polygonsDraw = polygon
	polygonsDraw.append(Vector2(2, 3))
	draw_polyline(polygonsDraw, Color.WHITE, 2)
