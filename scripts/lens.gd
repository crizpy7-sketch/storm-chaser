extends Node2D

var game: Node2D
const DEBRIS: = preload("res://assets/art/debris-atlas.png")

func _draw() -> void :
	if game.mode == game.Mode.MENU: return
	for projectile in game.lens_projectiles:
		var t: float = clampf(projectile.age / projectile.duration, 0.0, 1.0)
		var approach: = pow(t, 3.5)
		var point: Vector2 = projectile.origin.lerp(projectile.target, approach)
		var size: = 12.0 + approach * 580.0
		var cell: = DEBRIS.get_size() / 2.0
		draw_set_transform(point, 0.2 + t * 5.2)
		draw_texture_rect_region(DEBRIS, Rect2( - size * 0.5, - size * 0.5, size, size), Rect2(cell, cell), Color(0.9, 0.98, 1.0, 1.0))
		draw_set_transform(Vector2.ZERO)
	for mark in game.lens_marks:
		_draw_mark(mark)

func _draw_mark(mark: Dictionary) -> void :
	var age: float = mark.age
	var point: Vector2 = mark.point
	var fade: float = clampf((mark.duration - age) / 1.1, 0.0, 1.0)

	if not game.calm_fx:
		if age < 0.14:
			draw_circle(point, 42.0 + age * 490.0, Color(0.78, 0.88, 0.91, (1.0 - age / 0.14) * 0.45))
		for ray in range(9):
			var angle: float = ray * TAU / 9.0 + mark.seed * 0.64
			var direction: = Vector2(cos(angle), sin(angle))
			var bend: = Vector2( - direction.y, direction.x)
			var length: float = 85.0 + fposmod(ray * 47.0 + mark.seed * 23.0, 130.0)
			var points: = PackedVector2Array([point, point + direction * length * 0.22 + bend * 7.0, point + direction * length * 0.52 - bend * 10.0, point + direction * length])
			draw_polyline(points, Color(0.04, 0.08, 0.1, fade * 0.75), 3.4, true)
			draw_polyline(points, Color(0.83, 0.94, 0.97, fade * 0.68), 1.15, true)
			var fork: = point + direction * length * 0.52 - bend * 10.0
			draw_line(fork, fork + direction * length * 0.22 + bend * 27.0, Color(0.8, 0.92, 0.95, fade * 0.55), 1.0, true)
			if age < 0.4:
				var shard: = point + direction * (age * 680.0 + 35.0) + Vector2(0, age * age * 350.0)
				draw_colored_polygon(PackedVector2Array([shard, shard - direction * 13.0 + bend * 5.0, shard - direction * 6.0 - bend * 4.0]), Color(0.73, 0.88, 0.92, (1.0 - age / 0.4) * 0.7))
	var water_fade: float = clampf(1.0 - age / 2.5, 0.0, 1.0) * (0.45 if game.calm_fx else 1.0)
	for i in range(17):
		var angle: float = i * 2.39996 + mark.seed
		var radius: float = 18.0 + fposmod(i * 37.0, 125.0)
		var droplet: = point + Vector2(cos(angle), sin(angle)) * radius + Vector2( - age * 28.0, age * age * 45.0)
		draw_set_transform(droplet, 0, Vector2(1.0, 1.15 + age * 0.8))
		draw_circle(Vector2.ZERO, 3.0 + fposmod(i * 7.0, 8.0), Color(0.07, 0.15, 0.18, water_fade * 0.33))
		draw_arc(Vector2.ZERO, 3.0 + fposmod(i * 7.0, 8.0), 0.3, 2.3, 8, Color(0.78, 0.9, 0.93, water_fade * 0.42), 1.0, true)
		draw_set_transform(Vector2.ZERO)
