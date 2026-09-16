extends SceneTree

var game
var wall := 0.0
var second_front := false
var final_leg := false
var previous_mode := -1
var finishing := false

func _initialize() -> void:
	call_deferred("start")

func advance_to(time: float) -> void:
	for frame in range(5500):
		if game.elapsed >= time or game.mode != game.Mode.RUNNING: break
		if game.charge >= 100: game.deploy_probe()
		game._simulate(1.0 / 60.0)

func start() -> void:
	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://capture-v071.cfg"
	root.add_child(game)
	game.save_enabled = false
	game.demo = true
	game.auto_dodges = false
	game.rng.seed = 72611
	game.start_chase()
	advance_to(26.0)

func _process(dt: float) -> bool:
	if not is_instance_valid(game) or finishing: return false
	wall += dt
	if game.mode != previous_mode:
		previous_mode = game.mode
		print("CAPTURE_MODE wall=", snappedf(wall, 0.01), " elapsed=", game.elapsed, " mode=", game.mode)
	if not second_front and game.mode == game.Mode.RUNNING and game.elapsed >= 32.0:
		second_front = true
		advance_to(58.0)
	if not final_leg and game.mode == game.Mode.RUNNING and game.elapsed >= 63.0:
		final_leg = true
		advance_to(89.0)
	if wall > 28.0:
		finishing = true
		print("CAPTURE_DONE score=", game.score, " probes=", game.probes, " title=", game.result_title)
		quit(0 if game.mode == game.Mode.RESULTS else 1)
	return false
