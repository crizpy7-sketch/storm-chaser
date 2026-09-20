extends SceneTree
## GPU regression for the tornado matte. Run without --headless:
## godot --path . --script res://tools/check_storm_render.gd
## Synthetic colors isolate keying from the original texture and scene lighting.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.15, 0.45, 0.7)
	scene.add_child(env)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.0
	camera.position.z = 3.0
	scene.add_child(camera)
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/storm_billboard.gdshader")
	material.set_shader_parameter("brightness", 1.0)
	var panel := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(2.0, 1.0)
	panel.mesh = mesh
	panel.material_override = material
	panel.visible = false
	scene.add_child(panel)
	material.set_shader_parameter("clock", 0.0)
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	var center := rendered.get_size() / 2
	var background := rendered.get_pixel(center.x, center.y)
	panel.visible = true
	var failures := 0
	# Uniform textures avoid interpolation between test colors at warped UVs.
	for sample in [[Color.MAGENTA, true, "magenta key"], [Color(0.6, 0.6, 0.6), false, "cloud body"], [Color(0, 0, 0, 0), true, "source alpha"], [Color.BLACK, false, "opaque dark cloud"]]:
		var source := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		source.fill(sample[0])
		material.set_shader_parameter("storm_texture", ImageTexture.create_from_image(source))
		for i in range(3): await process_frame
		await RenderingServer.frame_post_draw
		rendered = root.get_texture().get_image()
		var color := rendered.get_pixel(center.x, center.y)
		var difference := Vector3(color.r, color.g, color.b).distance_to(Vector3(background.r, background.g, background.b))
		var passed := difference < 0.03 if bool(sample[1]) else difference > 0.15
		if not passed: failures += 1
		print("PASS: " if passed else "FAIL: ", sample[2], " background difference=", difference)
	print("STORM_RENDER_TESTS 4 checks; ", failures, " failures")
	scene.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
