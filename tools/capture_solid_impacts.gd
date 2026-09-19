extends SceneTree
var game
func _initialize() -> void:call_deferred("run")
func shot(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("STORM_CAPTURE_DIR")+"/"+label+".png")
func run() -> void:
	game=load("res://main.tscn").instantiate();game.settings_path="user://solid-stills.cfg";root.add_child(game)
	await process_frame;game.save_enabled=false;game.start_chase();game.set_process(false);game.world.set_process(false)
	game.light_graphics=false;game.calm_fx=false;game.auto_dodges=false
	game.elapsed=0;game.world.travel=0;game.world._update_view(0)
	game.elapsed=1.2;game.world.travel=43;game.world._update_view(0)
	game.notify("CIVILIANS REACHING SHELTER",5);game.hud.rebuild()
	await shot("Shelter-Gameplay")
	var site: Dictionary=game.world.shelters.sites[0]
	game.world.camera.position=site.root.position+Vector3(-9,4,12)
	game.world.camera.look_at(site.root.position+Vector3(2,.8,1.5))
	await shot("Shelter-Detail-QA")
	game.world._update_view(0);game._spawn_item(0,.23,.948)
	game.debris.back().angle=0;game.debris.back().spin=0;game.debris.back().phase=0;game.debris.back().drift=0
	game.elapsed+=.03;game._update_debris(.03);game.world._update_view(0)
	await shot("Solid-Contact")
	game.elapsed+=.13;game._update_debris(.13);game.world.truck.step(.05);game.world.contact_fx.step(.13);game.world._update_view(0)
	await shot("Contact-Rebound")
	game.queue_free();await process_frame;quit(0)
