extends SceneTree

var game
var wall := 0.0
var ending := false
var screenshot_saved := false
var thumbnail_saved := false

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://capture-water-v080.cfg"
	root.add_child(game)
	game.save_enabled = false
	game.auto_dodges = false
	game.rng.seed = 72611
	game.start_chase()

func _process(dt: float) -> bool:
	if not is_instance_valid(game) or ending: return false
	wall += dt
	# Recorded controller inputs, using the normal spawn, damage, traction and boost rules.
	var target: float = sin(game.elapsed * 1.1) * 0.42
	for p in game.puddles:
		if not p.hit and p.z > -85.0:
			target = p.lane
			break
	var turn: float = clampf((target - game.player_x) * 3.4 - game.velocity_x * 0.28 - game.glide_velocity * 0.25, -1.0, 1.0)
	Input.action_press("left", maxf(0.0, -turn))
	Input.action_press("right", maxf(0.0, turn))
	if game.boost > 10.0 and not game.boost_locked: Input.action_press("boost")
	else: Input.action_release("boost")
	if game.charge >= 100: game.deploy_probe()
	if game.aquaplane > 0.05 and not thumbnail_saved and game.splash_pulse < 0.7:
		thumbnail_saved = true
		call_deferred("save_frame", "../exports/Storm-Chaser-v0.8-Puddle.png")
	if not screenshot_saved and game.puddle_hits >= 2:
		screenshot_saved = true
		print("PUDDLE_PREVIEW hits=", game.puddle_hits, " slip=", game.rear_slip, " hull=", game.health)
	if wall > (7.0 if "--smoke" in OS.get_cmdline_user_args() else 20.0):
		ending = true
		print("DRIVE_CAPTURE_DONE puddles=", game.puddle_hits, " hull=", game.health, " score=", game.score)
		quit()
	return false

func save_frame(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
