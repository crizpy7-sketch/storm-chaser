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
	check(game.world.contact_blobs.size()==5,"truck has five contact-shadow blobs")
	check(is_instance_valid(game.world.tornado_cross),"tornado has a cross-card for volume")
	check(is_instance_valid(game.world.dust_ring),"tornado sits in a spinning dust foot")
	check(game.world.rain_sheets.size()==3,"world-space rain curtains sit in the chase")
	check(game.world.environment.ambient_light_energy<0.4,"ambient is low enough for contact shadows to read")
	check(is_instance_valid(game.world.fill) and is_instance_valid(game.world.bounce),"fill and ground-bounce lights exist")
	check(game.world.ground_node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"the prairie ground does not wreck the shadow map")
	check(game.world.sun.directional_shadow_max_distance<=48.01,"directional shadows stay dense around the truck")
	game.world._update_view(0.016)
	check(game.world.contact_blobs[0].visible,"contact shadows are visible at default quality")
	check(game.world.truck.paint_finishes.all(func(p):return float(p.get_shader_parameter("wetness"))>0.2),"truck paint carries rain wetness")
	var destruction=game.world.destruction
	check(destruction.pieces.size()==24 and destruction.dust.size()==12,"storm has physical lifting objects and dust layers")
	destruction.update_view();var before: Vector3=destruction.pieces[0].position
	destruction.update_view();check(before==destruction.pieces[0].position,"storm animation freezes with scene time")
	game.elapsed+=3;destruction.update_view()
	check(before.distance_to(destruction.pieces[0].position)>5,"storm carries objects across ground and upward")
	game.light_graphics=true;game.world.last_quality=-1;game.world._apply_quality()
	game.world._update_contact_shadows();game.world._update_storm_volume()
	check(game.world.contact_blobs.all(func(n):return not n.visible),"lighter graphics hides contact shadows")
	check(not game.world.tornado_cross.visible and not game.world.dust_ring.visible,"lighter graphics hides extra storm volume")
	destruction.update_view()
	check(destruction.pieces.filter(func(p):return p.visible).size()==12,"lighter graphics halves suction objects")
	print("STORM_ART_TESTS ",checks," checks; ",failures," failures")
	game.queue_free();await process_frame;quit(1 if failures else 0)
