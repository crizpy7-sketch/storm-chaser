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
func snapshot(node: Node3D) -> Array:
	var out: Array=[node.transform,node.visible]
	for child in node.get_children():
		if child is Node3D:out.append(snapshot(child))
	return out
func close_snapshot(a: Array,b: Array) -> bool:
	if a.size()!=b.size():return false
	for i in range(a.size()):
		if a[i] is Array:
			if not close_snapshot(a[i],b[i]):return false
		elif a[i] is Transform3D:
			if not a[i].is_equal_approx(b[i]):return false
		elif a[i]!=b[i]:return false
	return true
func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	game=load("res://main.tscn").instantiate();game.settings_path="user://landscape-tests.cfg"
	root.add_child(game);await process_frame
	game.save_enabled=false;game.start_chase();game.set_process(false);game.world.set_process(false)
	var world=game.world;var land=world.landscape
	game.stage=3;game.elapsed=94;game.route.enter(3);game.route.progress=80;world.travel=80
	world._update_view(0.0)
	check(land.clusters.size()==60 and land.fires.size()==4,"bounded scenery pool has homes, trees, fences and four fire sites")
	var before: Array=snapshot(land)
	game.mode=game.Mode.PAUSED;world._update_view(.16)
	check(before==snapshot(land),"pause freezes moving roofs, tree sway and ember transforms")
	game.mode=game.Mode.RUNNING
	var burning=land.fires.filter(func(f):return f.root.visible)
	check(not burning.is_empty(),"fire sites are present in the driving corridor")
	game.light_graphics=false;land.update_view()
	var full_count: int=land.clusters.filter(func(c):return c.root.visible).size()
	game.light_graphics=true;land.update_view()
	check(land.clusters.filter(func(c):return c.root.visible).size()<full_count and land.grass.visible_instance_count==160,"lighter graphics reduces scenery and grass density")
	check(land.fires.all(func(f):return not f.root.visible or not f.node.glow.visible),"lighter graphics disables local fire lights")
	game.light_graphics=false;game.calm_fx=true;land.update_view()
	check(land.fires.all(func(f):return not f.root.visible or f.node.material.get_shader_parameter("calm")==1.0),"reduced effects reaches the fire shaders")
	var grounded:=true
	for level in [4,5,6]:
		game.stage=level;game.route.enter(level);game.route.progress=350;world.travel=350;land.update_view()
		for c in land.clusters:
			if not c.root.visible:continue
			var p: Vector3=c.root.position
			grounded=grounded and p.is_finite() and absf(p.y-world._field_height(Vector2(p.x,p.z),land.samples))<.01
	check(grounded,"visible scenery follows the same hill elevation field as the terrain")
	game.stage=4;game.route.enter(4);game.route.progress=120;world.travel=120;land.update_view()
	var junction_clear:=true
	for c in land.clusters:
		if not c.root.visible:continue
		var junction: Vector2=game.route.project(Vector2(7,-game.route.SHORTCUT_JUNCTION_Z))
		var p: Vector2=Vector2(c.root.position.x,c.root.position.z)
		junction_clear=junction_clear and p.distance_to(junction)>22.0
	check(junction_clear,"perpendicular shortcut keeps its near junction free of scenery")
	game.stage=3;game.route.enter(3);game.sky_debris.clear();game._spawn_sky_piece(0,1);world._update_view(0.0)
	var semi=world.sky_nodes[0]
	check(semi.parts.size()==16,"airborne semi contains sixteen independently moving rigid sections")
	var homes: Array=semi.parts.map(func(p):return p.position)
	semi.update_breakup(.72,94,world)
	check(semi.parts[10].position.distance_to(homes[10])>4 and semi.parts[2].position.distance_to(homes[2])>1,"roof and bogie visibly separate during flyby")
	var fractured: Array=snapshot(semi);semi.update_breakup(.72,94,world)
	check(close_snapshot(fractured,snapshot(semi)),"semi breakup and attached fire are deterministic at a fixed scene time")
	semi.update_breakup(0.0,94,world)
	check(semi.parts.map(func(p):return p.position)==homes and not semi.fire.visible,"reused semi resets intact for the next flyby")
	var total: int=world.space.get_child_count()
	for i in range(20):world._update_sky()
	check(world.space.get_child_count()==total,"repeated sky updates allocate no extra wreck nodes")
	game.sky_debris.clear();game._spawn_sky_piece(0,-1)
	game.sky_debris[0].age=1.60;game.sky_timer=999;game.lens_timer=999
	var sound_before: int=game.sfx_cursor.metal_hit
	game._update_cinematics(0.01);game._update_cinematics(0.01)
	check(game.sfx_cursor.metal_hit==sound_before+1,"each semi rupture triggers its metal impact sound exactly once")
	game.stage=7;game.route.enter(7);land.update_view()
	check(land.clusters.all(func(c):return not c.root.visible) and land.grass.visible_instance_count>0,"final tornado orbit remains unobstructed")
	print("LANDSCAPE_TESTS ",checks," checks; ",failures," failures")
	game.queue_free();await process_frame;await create_timer(.08).timeout;quit(1 if failures else 0)
