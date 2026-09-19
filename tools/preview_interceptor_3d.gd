extends SceneTree
var vehicle: Node3D
var camera: Camera3D
var clock:=0.0
var taken: Dictionary={}
var output: String
func _initialize() -> void:call_deferred("start")
func start() -> void:
	output=OS.get_environment("STORM_CAPTURE_DIR")
	var scene:=Node3D.new();root.add_child(scene)
	var env_node:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("535f67")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("bdc6c9");env.ambient_light_energy=.70
	env.tonemap_mode=Environment.TONE_MAPPER_ACES
	env.fog_enabled=false;env.fog_density=.020;env.fog_light_color=Color("535f67");env.fog_light_energy=.45
	env.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	var sky:=Sky.new();var sky_mat:=ProceduralSkyMaterial.new()
	sky_mat.sky_top_color=Color("647681");sky_mat.sky_horizon_color=Color("b3bebc")
	sky_mat.ground_bottom_color=Color("1a2227");sky_mat.ground_horizon_color=Color("74838a")
	sky.sky_material=sky_mat;env.sky=sky
	env_node.environment=env;scene.add_child(env_node)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-35,0)
	sun.light_color=Color("fff0d9");sun.light_energy=1.05;sun.shadow_enabled=true;scene.add_child(sun)
	var fill:=OmniLight3D.new();fill.position=Vector3(-4,4,-3);fill.omni_range=15;fill.light_energy=2.0;fill.light_color=Color("a6c9e4");scene.add_child(fill)
	var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(80,80)
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("3d474e");mat.roughness=.65;mat.metallic=.02
	ground.mesh=plane;ground.material_override=mat;ground.position.y=-.015;scene.add_child(ground)
	vehicle=load("res://assets/models/interceptor-3d.tscn").instantiate();scene.add_child(vehicle)
	camera=Camera3D.new();camera.fov=38;scene.add_child(camera);camera.current=true
	var ui:=CanvasLayer.new();root.add_child(ui)
	var title:=Label.new();title.text="INTERCEPTOR 07";title.position=Vector2(44,30);title.add_theme_font_size_override("font_size",30);ui.add_child(title)
	var subtitle:=Label.new();subtitle.text="STORM CHASER  /  SCULPTED PICKUP / ORIGINAL REFERENCE";subtitle.position=Vector2(46,72);subtitle.add_theme_font_size_override("font_size",15);subtitle.modulate=Color("dda859");ui.add_child(subtitle)
	var note:=Label.new();note.text="ACTUAL GODOT MODEL PREVIEW  ·  INDEPENDENT WHEELS  ·  CURVED BODY PANELS";note.position=Vector2(44,674);note.add_theme_font_size_override("font_size",15);note.modulate=Color("adb9bd");ui.add_child(note)
	set_view(0)
func set_view(t: float) -> void:
	var angle:=deg_to_rad(25.0)+t*TAU/16.0
	camera.position=Vector3(sin(angle)*10.9,4.1,cos(angle)*10.9)
	camera.look_at(Vector3(0,1.75,0),Vector3.UP)
	for label in ["FrontLeftWheel","FrontRightWheel"]:
		vehicle.get_node(label).rotation.y=sin(t*1.1)*.38
func _process(dt: float) -> bool:
	if not is_instance_valid(vehicle):return false
	clock+=dt;set_view(clock)
	for spec in [[.2,"rear-three-quarter"],[3.0,"side"],[5.5,"front-three-quarter"],[7.0,"front"],[13.0,"rear-other-side"]]:
		if clock>=spec[0] and not taken.has(spec[1]):
			taken[spec[1]]=true;call_deferred("capture",spec[1])
	if clock>16:
		print("TRUCK_3D_TURNTABLE_COMPLETE");quit()
	return false
func capture(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/Truck-3D-"+label+".png")
