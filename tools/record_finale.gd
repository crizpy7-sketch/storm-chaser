extends SceneTree
var game
var wall:=0.0
var ending_age:=0.0
var saved:=false
var result_saved:=false
func _initialize() -> void:call_deferred("start")
func start() -> void:
	game=load("res://main.tscn").instantiate();game.settings_path="user://finale-capture-isolated.cfg";root.add_child(game)
	game.demo=true;game.auto_dodges=false;game.save_enabled=false;game.rng.seed=72611
	game.start_chase()
	game.set_process(false)
	for i in range(48000):
		if game.mode==game.Mode.UPGRADE:game.choose_upgrade(0 if game.health<80 else 1);game.checkpoints.complete()
		if game.mode==game.Mode.RUNNING:
			if game.charge>=100:game.deploy_probe()
			game._simulate(1.0/60.0)
		if game.mode in [game.Mode.VORTEX,game.Mode.RESULTS,game.Mode.CRASH]:break
	if game.mode!=game.Mode.VORTEX:
		printerr("FINAL_CAPTURE_FAILED: ",game.mode);quit(1);return
	# Resolve the last road/camera pose before starting the recorded finale.
	game.finale.reset();game.mode=game.Mode.RUNNING;game.world._update_view(0);game.finale.begin()
	game.set_process(true)
	print("FINAL_CAPTURE_BEGIN version=",ProjectSettings.get_setting("application/config/version")," score=",game.score," probes=",game.probes)
func _process(dt: float) -> bool:
	if not is_instance_valid(game):return false
	wall+=dt
	if game.mode==game.Mode.VORTEX and game.finale.age>7.7 and not saved:
		saved=true;call_deferred("frame","Into-the-Vortex")
	if game.mode==game.Mode.RESULTS:
		ending_age+=dt
		if not result_saved and ending_age>.2:
			result_saved=true;call_deferred("frame","Results")
		if ending_age>2.5:
			print("FINAL_CAPTURE_DONE wall=",wall," title=",game.result_title," score=",game.score)
			quit()
	if wall>17:quit(1)
	return false
func frame(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("../Storm-Chaser-v0.10.0-"+label+".png")
