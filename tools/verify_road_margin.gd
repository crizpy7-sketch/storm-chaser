extends SceneTree
var game
var checks:=0
var failures:=0
const MediaPack = preload("res://scripts/media.gd")
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print("PASS: " if ok else "FAIL: ",label)
func fresh(level: int) -> void:
	game.start_chase();game.set_process(false);game.world.set_process(false)
	game.stage=level;game.stage_seen=level;game.route.enter(level)
	game.speed=180;game.wind=0;game.player_x=0;game.velocity_x=0;game.steer=0
func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	game=load("res://main.tscn").instantiate();game.settings_path="user://road-margin-test.cfg"
	root.add_child(game);await process_frame;game.save_enabled=false
	for fps in [30,60,120]:
		for direction in [-1.0,1.0]:
			fresh(3);game.steer=direction;game.wind=direction*.5;game.glide_velocity=direction*2.5
			for i in range(fps*3):game._update_driving(1.0/fps)
			check(absf(game.player_x)*game.route.lane_scale()+1.85<=game.route.width()*.5-.39,"full steering, wind and slide keep body inside pavement at %s fps / %s"%[fps,direction])
			game.steer=-direction
			for i in range(fps/2):game._update_driving(1.0/fps)
			check(absf(game.player_x)<.65,"countersteering promptly leaves edge at %s fps / %s"%[fps,direction])
	fresh(5);game.route.dirt=1;check(is_equal_approx(game.road_steering_limit(),1.2),"mud retains broad off-road driving range")
	fresh(3);game.steer=1;game.player_x=0;game._update_driving(.05);var center_velocity: float=game.velocity_x
	game.player_x=game.road_steering_limit()-.02;game.velocity_x=0;game._update_driving(.05)
	check(game.velocity_x<center_velocity*.3,"outward steering eases before reaching pavement margin")
	print("ROAD_MARGIN_TESTS ",checks," checks; ",failures," failures")
	game.queue_free();await process_frame;quit(1 if failures else 0)
