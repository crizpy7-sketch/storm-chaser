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
func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	game=load("res://main.tscn").instantiate();game.settings_path="user://storm-art-tests.cfg"
	root.add_child(game);await process_frame
	game.save_enabled=false;game.start_chase();game.set_process(false);game.world.set_process(false)
	# Truck geometry and articulation are covered by verify_truck_3d.gd.
	var destruction=game.world.destruction
	check(destruction.pieces.size()==24 and destruction.dust.size()==12,"storm has physical lifting objects and dust layers")
	destruction.update_view();var before: Vector3=destruction.pieces[0].position
	destruction.update_view();check(before==destruction.pieces[0].position,"storm animation freezes with scene time")
	game.elapsed+=3;destruction.update_view()
	check(before.distance_to(destruction.pieces[0].position)>5,"storm carries objects across ground and upward")
	game.light_graphics=true;destruction.update_view()
	check(destruction.pieces.filter(func(p):return p.visible).size()==12,"lighter graphics halves suction objects")
	print("STORM_ART_TESTS ",checks," checks; ",failures," failures")
	game.queue_free();await process_frame;quit(1 if failures else 0)
