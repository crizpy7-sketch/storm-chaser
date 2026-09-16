extends SceneTree
var game
func _initialize() -> void:call_deferred("run")
func run() -> void:
	game=load("res://main.tscn").instantiate();game.settings_path="user://route-visual-isolated.cfg";root.add_child(game)
	await process_frame
	game.set_process(false);game.world.set_process(false);game.world.mateo.set_process(false)
	for spec in [[3,170.0,0.0],[4,185.0,0.0],[4,355.0,0.0],[5,145.0,2.5],[6,168.0,5.0],[7,220.0,0.0]]:
		game.start_chase();game.stage=spec[0];game.stage_seen=spec[0];game.elapsed=spec[0]*30.0+5.0
		game.route.enter(spec[0]);game.route.progress=spec[1];game.route.air_height=spec[2];game.route.hint=game.route.chapter_caption()
		game.world.truck.step(.016);game.speed=game.CRUISE_SPEEDS[game.stage]
		game.world.space.show();game.world.show();game.world._update_view(0)
		game.hud.queue_redraw()
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("../review/route-%d-%d.png"%[spec[0],spec[1]])
	game.finale.begin()
	for t in [1.5,5.5,8.5]:
		game.finale.age=t;game.world._update_view(0);game.finale.queue_redraw()
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("../review/vortex-%d.png"%int(t))
	game.queue_free();await process_frame;quit()
