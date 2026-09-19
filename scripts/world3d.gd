extends Node2D

const SKY: = preload("res://assets/art/storm-sky.png")
const VORTEX: = preload("res://assets/art/tornado-cinematic.png")
const TRUCK_ART: = preload("res://assets/art/truck.png")
const Media := preload("res://scripts/media.gd")
# Optional generated art. Media substitutes in-memory stand-ins when absent.
var COW: Texture2D
var BUILDING_ART: Texture2D
var clay_texture: Texture2D
var prairie_sky: Texture2D
var game: Node2D
var space: Node3D
var camera: Camera3D
var truck: Node3D
var water_fx: Node3D
var cue_shadows: Array[MeshInstance3D] = []
var approach_site: Node3D
var approach_theme := -1
var last_quality := -1
var pole_batches: Array[MultiMesh] = []
var marker_batches: Array[MultiMesh] = []
var mateo: Node3D
var semi_template: Node3D
var semi_wreck_template: Node3D
var landscape: Node3D
var shelters: Node3D
var contact_fx: Node3D
var hazard_bound_cache: Dictionary = {}
var road: MeshInstance3D
var ground_node: MeshInstance3D
var terrain: MeshInstance3D
# Static hill grid whose heights the ground shader evaluates (see _build_terrain_field).
var terrain_field: MeshInstance3D
var terrain_field_material: ShaderMaterial
var mesh_progress := -999.0
var mesh_level := -1
var last_landing := 0
var shortcut_sign: Node3D
var shortcut_barrier: Node3D
var destruction: Node3D
var tornado: MeshInstance3D
var sky: MeshInstance3D
var environment: Environment
var sun: DirectionalLight3D
var fill: DirectionalLight3D
var bounce: DirectionalLight3D
var contact_blobs: Array[MeshInstance3D] = []
var tornado_cross: MeshInstance3D
var dust_ring: MeshInstance3D
var rain_sheets: Array[MeshInstance3D] = []
var travel: = 0.0
var camera_pan: = 0.0
var cam_roll: = 0.0
## The boom has inertia in every axis, not only sideways. Height, reach, lens
## and aim were previously assigned raw each frame, so they read as cuts.
var cam_y_smooth: = 3.4
var cam_z_smooth: = 10.0
var cam_fov_smooth: = 66.0
var cam_focus: = Vector3(0.0, 3.9, -29.0)
var road_bend: = 99.0
var road_material: ShaderMaterial
var ground_material: ShaderMaterial
var storm_material: ShaderMaterial
var mat_steel: StandardMaterial3D
var mat_wood: Material
var mat_rubber: StandardMaterial3D
var mat_red: StandardMaterial3D
var mat_silver: StandardMaterial3D
var mat_mint: StandardMaterial3D
var building_materials: Array[StandardMaterial3D] = []
var poles: Array[Node3D] = []
var markers: Array[Node3D] = []
var turbines: Array[Node3D] = []
var hazard_nodes: Array[Node3D] = []
var puddle_nodes: Array[MeshInstance3D] = []
var sky_nodes: Array[Node3D] = []
var orbit_nodes: Array[MeshInstance3D] = []
var rain: Array[Vector3] = []
var spray: Array[Dictionary] = []
var spray_clock: = 0.0
var last_elapsed: = 0.0

func _ready() -> void :
	COW = Media.texture("res://assets/art/flying-cow.png", "cow")
	BUILDING_ART = Media.texture("res://assets/art/building-materials.png", "building")
	clay_texture = Media.texture("res://assets/art/terrain/clay-ruts.png", "clay")
	prairie_sky = Media.texture("res://assets/art/terrain/prairie-storm.png")
	if prairie_sky == null: prairie_sky = SKY
	space = Node3D.new()
	space.name = "ChaseWorld"
	add_child(space)
	mat_steel = material(Color("26343b"), 0.62, 0.44)
	mat_wood = material(Color("665344"), 0.02, 0.82)
	mat_wood = weathered(Color("655347"), 1.0, 0.0)
	mat_rubber = material(Color("11191c"), 0.0, 0.91)
	mat_red = material(Color("864032"), 0.42, 0.4)
	mat_silver = material(Color("8c9b9f"), 0.65, 0.35)
	mat_mint = material(Color("84f5ba"), 0.2, 0.3, 0.8)
	for i in range(4):
		var m: = material(Color(0.8, 0.86, 0.9), 0.45 if i in [1, 3] else 0.03, 0.48 if i in [1, 3] else 0.86)
		m.albedo_texture = BUILDING_ART
		m.uv1_scale = Vector3(0.492, 0.492, 1)
		m.uv1_offset = Vector3((i % 2) * 0.5 + 0.004, floori(i / 2.0) * 0.5 + 0.004, 0)
		building_materials.append(m)
	_build_environment()
	_build_roadside()
	pole_batches = _batch_roadside(poles)
	marker_batches = _batch_roadside(markers)
	_build_vehicles()
	destruction=Node3D.new()
	destruction.set_script(preload("res://scripts/storm_destruction.gd"))
	destruction.game=game;destruction.world=self
	space.add_child(destruction);destruction.build()
	landscape=Node3D.new();landscape.name="StormDamageCorridor"
	landscape.set_script(preload("res://scripts/storm_landscape.gd"))
	landscape.game=game;landscape.world=self
	space.add_child(landscape);landscape.build()
	shelters=Node3D.new();shelters.name="CivilianShelters";shelters.set_script(preload("res://scripts/storm_shelters.gd"))
	shelters.game=game;shelters.world=self;space.add_child(shelters);shelters.build()
	contact_fx=Node3D.new();contact_fx.name="ContactFragments";contact_fx.set_script(preload("res://scripts/contact_fx.gd"))
	contact_fx.game=game;contact_fx.world=self;space.add_child(contact_fx);contact_fx.build()
	var random: = RandomNumberGenerator.new()
	random.seed = 22097
	for _i in range(210): rain.append(Vector3(random.randf() * 1440.0, random.randf() * 860.0, random.randf_range(0.3, 1.0)))
	for i in range(42):
		var piece: = box(space, Vector3.ZERO, Vector3(0.7 + fmod(i * 0.3, 1.0), 0.2, 0.6), mat_steel)
		orbit_nodes.append(piece)
	_update_view(0.016)

func material(color: Color, metallic: float = 0.0, rough: float = 0.6, glow: float = 0.0) -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = rough
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	return m

func weathered(color: Color, wood: float, metal: float) -> ShaderMaterial:
	var m: = ShaderMaterial.new()
	m.shader = preload("res://shaders/weathered_prop.gdshader")
	m.set_shader_parameter("base_color", color)
	m.set_shader_parameter("wood", wood)
	m.set_shader_parameter("metal", metal)
	return m

func mesh_node(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var node: = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node

func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh: = BoxMesh.new()
	mesh.size = size
	return mesh_node(parent, mesh, pos, mat)

func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh: = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	return mesh_node(parent, mesh, pos, mat)

func _build_environment() -> void :
	var holder: = WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("152430")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("6a8494")
	environment.ambient_light_energy = 0.28
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.94
	environment.fog_enabled = true
	environment.fog_light_color = Color("1a2e36")
	environment.fog_light_energy = 0.88
	environment.fog_density = 0.0032
	environment.fog_sky_affect = 0.62
	environment.glow_enabled = true
	environment.glow_intensity = 0.38
	environment.glow_strength = 0.68
	environment.glow_bloom = 0.06
	environment.glow_hdr_threshold = 0.9
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.86
	environment.adjustment_contrast = 1.10
	environment.adjustment_brightness = 0.98
	holder.environment = environment
	space.add_child(holder)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-28, -118, 0)
	sun.light_color = Color("c9a574")
	sun.light_energy = 1.12
	sun.shadow_enabled = true
	sun.shadow_blur = 1.4
	sun.shadow_opacity = 0.78
	sun.shadow_bias = 0.04
	sun.directional_shadow_max_distance = 48.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	space.add_child(sun)
	fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-16, 52, 0)
	fill.light_color = Color("7a9bb0")
	fill.light_energy = 0.16
	space.add_child(fill)
	bounce = DirectionalLight3D.new()
	bounce.rotation_degrees = Vector3(72, -30, 0)
	bounce.light_color = Color("5c4a32")
	bounce.light_energy = 0.11
	space.add_child(bounce)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 66.0
	camera.near = 0.15
	camera.far = 1600.0
	space.add_child(camera)
	var quad: = QuadMesh.new()
	quad.size = Vector2(2200, 1237.5)
	var sky_mat: = StandardMaterial3D.new()
	sky_mat.albedo_texture = SKY
	sky_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sky_mat.disable_fog = true
	sky = mesh_node(space, quad, Vector3(0, 474, -600), sky_mat)
	sky.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ground: = PlaneMesh.new()
	ground.size = Vector2(8000, 8000)
	ground_material = ShaderMaterial.new()
	ground_material.shader = preload("res://shaders/ground.gdshader")
	ground_material.set_shader_parameter("field_texture", SKY)
	ground_material.set_shader_parameter("clay_texture", clay_texture)
	var grass_tex: Texture2D = Media.texture("res://assets/art/terrain/prairie-grass.png", "clay")
	if grass_tex: ground_material.set_shader_parameter("grass_texture", grass_tex)
	ground_node = mesh_node(space, ground, Vector3(0, -0.055, -400), ground_material)
	ground_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	terrain = MeshInstance3D.new()
	terrain.material_override = ground_material
	terrain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	space.add_child(terrain)
	_build_terrain_field()
	road = MeshInstance3D.new()
	road_material = ShaderMaterial.new()
	road_material.shader = preload("res://shaders/wet_road.gdshader")
	road_material.set_shader_parameter("storm_sky", SKY)
	road_material.set_shader_parameter("clay_texture", clay_texture)
	var asphalt_tex: Texture2D = Media.texture("res://assets/art/terrain/wet-asphalt.png", "clay")
	if asphalt_tex: road_material.set_shader_parameter("asphalt_texture", asphalt_tex)
	road.material_override = road_material
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	space.add_child(road)
	var storm_quad: = _storm_mesh()
	storm_material = ShaderMaterial.new()
	storm_material.shader = preload("res://shaders/storm_billboard.gdshader")
	storm_material.set_shader_parameter("storm_texture", VORTEX)
	tornado = mesh_node(space, storm_quad, Vector3(15, 70, -150), storm_material)
	tornado.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_build_storm_volume()
	_build_contact_shadows()
	_build_rain_sheets()

func _build_vehicles() -> void :
	var scene: PackedScene = load("res://assets/models/storm-vehicles.glb")
	var source: Node3D = scene.instantiate()
	var original: Node3D = source.find_child("Interceptor", true, false)
	truck = Node3D.new()
	truck.set_script(preload("res://scripts/truck_rig.gd"))
	truck.game = game
	truck.world = self
	truck.build(original)
	truck.name = "Interceptor"
	space.add_child(truck)
	semi_template = _bake_model(source.find_child("AirborneSemi", true, false))
	semi_template.name = "AirborneSemi"
	semi_wreck_template=preload("res://scripts/semi_wreck.gd").make_template(source.find_child("AirborneSemi",true,false),self)


	source.free()

	mateo = Node3D.new()
	mateo.set_script(preload("res://scripts/mateo.gd"))
	mateo.game = game
	truck.body.add_child(mateo)
	truck.seat_mateo(mateo)
	water_fx = Node3D.new()
	water_fx.set_script(preload("res://scripts/water_fx.gd"))
	water_fx.game = game
	water_fx.world = self
	space.add_child(water_fx)

func _bake_model(root_node: Node3D) -> Node3D:
	var result: = Node3D.new()
	var groups: = {}
	_collect_meshes(root_node, Transform3D.IDENTITY, groups)
	for key in groups:
		var group: Dictionary = groups[key]
		var surface: SurfaceTool = group.surface
		var built: = MeshInstance3D.new()
		built.mesh = surface.commit()
		built.material_override = group.material
		if group.material and "Trailer aluminum" in group.material.resource_name:
			built.material_override = weathered(Color("a8b4b8"), 0.0, 0.55)
		result.add_child(built)
	return result

func _collect_meshes(node: Node3D, local: Transform3D, groups: Dictionary) -> void :
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var mat: Material = node.get_active_material(surface)
			var key: int = mat.get_instance_id() if mat else 0
			if not groups.has(key):
				var st: = SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				groups[key] = {"surface": st, "material": mat}
			groups[key].surface.append_from(node.mesh, surface, local)
	for child in node.get_children():
		if child is Node3D: _collect_meshes(child, local * child.transform, groups)

func _build_roadside() -> void :
	for i in range(22):
		var pole: = Node3D.new()
		space.add_child(pole)
		cylinder(pole, Vector3(0, 4, 0), 0.12, 8, mat_wood)
		box(pole, Vector3(0, 7.2, 0), Vector3(2.5, 0.12, 0.16), mat_wood)
		for x in [ - 0.95, 0.0, 0.95]:
			cylinder(pole, Vector3(x, 7.36, 0), 0.065, 0.25, mat_silver)
			var wire: = box(pole, Vector3(x, 7.18, -18), Vector3(0.017, 0.017, 36), mat_steel)
			wire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		poles.append(pole)
	for i in range(76):
		var post: = Node3D.new()
		space.add_child(post)
		box(post, Vector3(0, 0.45, 0), Vector3(0.08, 0.9, 0.08), mat_silver)
		box(post, Vector3(0, 0.79, 0.051), Vector3(0.105, 0.15, 0.025), material(Color("dcd5a4"), 0.2, 0.4, 0.4))
		markers.append(post)
	for i in range(7):
		var turbine: = Node3D.new()
		space.add_child(turbine)
		cylinder(turbine, Vector3(0, 14, 0), 0.35, 28, mat_silver)
		var rotor: = Node3D.new()
		rotor.name = "Rotor"
		rotor.position = Vector3(0, 28, 0.6)
		turbine.add_child(rotor)
		for arm in range(3):
			var pivot: = Node3D.new()
			pivot.rotation.z = arm * TAU / 3.0
			rotor.add_child(pivot)
			var blade: = box(pivot, Vector3(0, 6.1, 0), Vector3(0.45, 12, 0.1), mat_silver)
			blade.rotation.y = 0.15
		turbines.append(turbine)

func _batch_roadside(roots: Array[Node3D]) -> Array[MultiMesh]:
	# Every pole/post uses the same geometry. Instance it instead of redrawing
	# each small bolt, insulator and reflector as a separate mesh.
	var batches: Array[MultiMesh] = []
	if roots.is_empty(): return batches
	var baked: Node3D = _bake_model(roots[0])
	for part in baked.get_children():
		if not part is MeshInstance3D: continue
		var mesh := MultiMesh.new()
		mesh.transform_format = MultiMesh.TRANSFORM_3D
		mesh.mesh = part.mesh
		mesh.instance_count = roots.size()
		var n := MultiMeshInstance3D.new()
		n.multimesh = mesh
		n.material_override = part.material_override
		space.add_child(n)
		batches.append(mesh)
	for root in roots:
		for child in root.get_children(): child.free()
	baked.free()
	return batches

func surface_point(z: float, lateral: float = 0.0) -> Vector3:
	if not game.route.active: return Vector3(road_center(z)+lateral,0,z)
	var point: Vector3=game.route.point(z,lateral)
	if game.stage in [4,5,6]: point.y=lerpf(point.y,-22.0-game.route.height_at(game.route.progress),smoothstep(255.0,360.0,-z))
	return point

func road_point(z: float, lane: float = 0.0) -> Vector3:
	return surface_point(z,lane*(game.route.lane_scale(z) if game.route.active else 5.8))

func surface_rotation(z: float) -> Vector3:
	return game.route.rotation_at(z) if game.route.active else Vector3.ZERO

func road_center(z: float) -> float:
	if game.route.active: return game.route.point(z).x
	return game.bend * 0.0007 * z * z / (1.0 + absf(z) * 0.003)

## Road rows shared by every vertex at the same z within one mesh build:
## [center, lateral direction, width, dirt]. Computing each row once keeps the
## per-frame road and shoulder rebuild cheap without changing any vertex.
func _road_row(z: float, cache: Dictionary) -> Array:
	if cache.has(z): return cache[z]
	var entry: Array
	if game.route.active:
		var frame: Array = game.route.row(z)
		var center: Vector3 = frame[0]
		if game.stage in [4,5,6]: center.y = lerpf(center.y, -22.0-game.route.height_at(game.route.progress), smoothstep(255.0, 360.0, -z))
		var dirt: float = game.route.dirt_at(game.route.progress-z)
		entry = [center, frame[1], lerpf(14.0, 11.0, dirt), dirt]
	else:
		entry = [Vector3(road_center(z), 0, z), Vector3.RIGHT, 14.0, 0.0]
	cache[z] = entry
	return entry

func _road_mesh() -> void :
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	if game.stage==4: _junction_mesh(verts, normals, colors, uvs)
	var rows := {}
	var active: bool = game.route.active
	var progress: float = game.route.progress
	for i in range(145):
		var a: = 24.0 - i * 3.0
		var b: = a - 3.0
		if game.stage==4:
			if progress-b<=260.0:continue
			a=minf(a,progress-260.0)
		var ra: Array = _road_row(a, rows)
		var rb: Array = _road_row(b, rows)
		var lift := Vector3.UP * 0.015
		var a_half: Vector3 = ra[1] * (0.5 * float(ra[2]))
		var b_half: Vector3 = rb[1] * (0.5 * float(rb[2]))
		var a0: Vector3 = ra[0] + lift - a_half
		var a1: Vector3 = ra[0] + lift + a_half
		var b0: Vector3 = rb[0] + lift - b_half
		var b1: Vector3 = rb[0] + lift + b_half
		verts.append_array(PackedVector3Array([a0, a1, b0, a1, b1, b0]))
		var ca := Color(ra[3], 0, 0)
		var cb := Color(rb[3], 0, 0)
		colors.append_array(PackedColorArray([ca, ca, cb, ca, cb, cb]))
		var va: float = progress-a if active else -a
		var vb: float = progress-b if active else -b
		uvs.append_array(PackedVector2Array([Vector2(0, va), Vector2(1, va), Vector2(0, vb), Vector2(1, va), Vector2(1, vb), Vector2(0, vb)]))
	normals.resize(verts.size())
	normals.fill(Vector3.UP)
	road.mesh = _commit_arrays(road.mesh as ArrayMesh, verts, normals, colors, uvs)
	road_bend = game.bend
	mesh_progress = game.route.progress
	mesh_level = game.stage
	if active: _terrain_mesh(rows)

func _commit_arrays(mesh: ArrayMesh, verts: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, uvs: PackedVector2Array) -> ArrayMesh:
	if mesh == null: mesh = ArrayMesh.new()
	mesh.clear_surfaces()
	if verts.is_empty(): return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	if not colors.is_empty(): arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _junction_mesh(verts: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, uvs: PackedVector2Array) -> void:
	# The road geometry is a square junction. Only the driving line rounds
	# the inside of the ninety-degree corner; neither road becomes a ramp.
	if game.route.progress>320.0:return
	var junction: float=game.route.SHORTCUT_JUNCTION_Z
	var end: Vector2=game.route.course(260.0)
	var height: float=0.015-game.route.height_at(game.route.progress)
	for mud in [false,true]:
		for uv in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
			var canonical: Vector2
			var along: float
			if mud:
				canonical=Vector2(lerpf(7.0,end.x,uv.y),-junction+(uv.x-.5)*11.0)
				along=260.0-end.x+canonical.x
			else:
				canonical=Vector2((uv.x-.5)*14.0,lerpf(32.0,-360.0,uv.y))
				along=-canonical.y
			var p: Vector2=game.route.project(canonical)
			normals.append(Vector3.UP);colors.append(Color(1.0 if mud else 0.0,0,0))
			uvs.append(Vector2(uv.x,along))
			verts.append(Vector3(p.x,height,p.y))

func _process(dt: float) -> void :
	visible = game.mode != game.Mode.MENU
	space.visible = visible
	if not visible: return
	if game.mode == game.Mode.RUNNING:
		var step: = minf(dt, 0.05)
		travel = game.route.progress if game.route.active else travel + step*game.speed*0.25
		var follow_rate: float=3.6 if game.calm_fx else lerpf(lerpf(3.6,2.5,game.aquaplane),1.8,game.route.shortcut_slide)
		if not game.calm_fx: follow_rate *= clampf(1.0 - game.powertrain.acceleration * 0.006, 0.62, 1.55)
		camera_pan = lerpf(camera_pan, game.player_x * 3.6, 1.0 - exp(-step * follow_rate))
		if game.route.landings>last_landing: water_fx.landing_burst(game.route.landing_severity)
		last_landing=game.route.landings
		_update_spray(step)
		truck.step(step)
		water_fx.step(step)
	if game.mode in [game.Mode.RUNNING,game.Mode.CRASH]:contact_fx.step(minf(dt,.05))
	_update_view(dt)
	queue_redraw()

func _update_view(_dt: float) -> void :
	water_fx.mud_lens.visible=game.mode==game.Mode.RUNNING and water_fx.mud_age<5.7
	if mesh_level != game.stage or (absf(game.route.progress-mesh_progress)>0.45 if game.route.active else absf(road_bend-game.bend)>0.003): _road_mesh()
	terrain.visible = game.route.active and game.stage in [4,5,6]
	terrain_field.visible = terrain.visible
	sky.material_override.albedo_texture = prairie_sky if terrain.visible else SKY
	ground_material.set_shader_parameter("route_origin", game.route.course(game.route.progress) if game.route.active else Vector2(0,-travel))
	ground_material.set_shader_parameter("route_heading", game.route.heading(game.route.progress) if game.route.active else 0.0)
	ground_node.position.y = -22.0-game.route.height_at(game.route.progress) if terrain.visible else -0.055
	road_material.set_shader_parameter("travel", 0.0 if game.route.active else travel)
	ground_material.set_shader_parameter("travel", travel)
	ground_material.set_shader_parameter("dirt",game.route.dirt if game.route.active else 0.0)
	if terrain_field.visible:
		for key in ["route_origin", "route_heading", "travel", "dirt", "flash", "clock"]:
			terrain_field_material.set_shader_parameter(key, ground_material.get_shader_parameter(key))
	var bolt: float = 0.0 if game.calm_fx else game.lightning
	road_material.set_shader_parameter("flash", bolt)
	road_material.set_shader_parameter("clock", game.elapsed)
	ground_material.set_shader_parameter("flash", bolt)
	ground_material.set_shader_parameter("clock", game.elapsed)
	if terrain_field.visible:
		terrain_field_material.set_shader_parameter("flash", bolt)
		terrain_field_material.set_shader_parameter("clock", game.elapsed)
	storm_material.set_shader_parameter("clock", game.elapsed * 1.45)
	storm_material.set_shader_parameter("brightness", 0.69 if game.calm_fx else 0.69 + bolt * 0.4)
	sun.light_energy = 1.12 + bolt * 2.35
	sun.light_color = Color("c9a574").lerp(Color("dce8f4"), clampf(bolt, 0.0, 1.0))
	fill.light_energy = 0.16 + bolt * 0.85
	bounce.light_energy = 0.11 + bolt * 0.12
	environment.ambient_light_energy = 0.28 + bolt * 0.5
	environment.fog_light_energy = 0.88 + bolt * 0.55
	environment.fog_light_color = Color("1a2e36").lerp(Color("8aa8b8"), clampf(bolt * 0.55, 0.0, 1.0))
	if sky.material_override is StandardMaterial3D:
		(sky.material_override as StandardMaterial3D).albedo_color = Color(1, 1, 1).lerp(Color(1.25, 1.32, 1.4), clampf(bolt, 0.0, 1.0))
	var storm_z: float = -135.0 - (game.distance - 800.0) * 0.025
	tornado.position = Vector3(road_center(storm_z) + game.storm_offset * 45.0, 70.0, storm_z)
	sky.position = Vector3(camera_pan*0.1,474,-600)
	sky.rotation = Vector3.ZERO
	truck.position = road_point(0,game.player_x)+Vector3.UP*(0.025+game.route.air_height)
	# Campaign heading drives a real mesh; secondary suspension is in truck_rig.
	truck.rotation = Vector3(game.route.pitch, scene_truck_yaw(), 0)
	var surge: float = 0.0 if game.calm_fx else game.turbo_fx
	var impact_time: float = game.crashes.impact_age if is_instance_valid(game.crashes) else 10.0
	var istr: float = game.crashes.impact_strength if is_instance_valid(game.crashes) else 0.0
	var drift_view: float=0.0 if game.calm_fx else game.route.shortcut_slide
	var want_fov: float = 66.0 + surge * 5.0 - game.cinematic_return*3.5 + drift_view*4.5
	var cam_y: float = 3.4 - surge * 0.28 + game.flyby_pressure * 0.18 - drift_view*0.22
	var want_z: float = 10.0 + surge * 0.4
	var junction_view: float=0.0
	if game.stage==4 and not game.calm_fx:
		junction_view=smoothstep(65.0,105.0,game.route.progress)*(1.0-smoothstep(game.route.SHORTCUT_TURN_END+8.0,game.route.SHORTCUT_TURN_END+45.0,game.route.progress))
		cam_y+=junction_view*1.35
		want_fov+=junction_view*3.0
	var focus := Vector3(camera_pan*0.75+game.velocity_x*0.42+game.steer_column*0.10,3.9+game.flyby_pressure*2.7,-29.0)
	# Suspension breathing and the load dolly are properties of the truck, not
	# of the route: gating them behind route.active left the first three stages
	# with a perfectly rigid camera.
	if not game.calm_fx:
		cam_y += truck.suspension * 0.85
		cam_y += clampf(-game.powertrain.acceleration * 0.0022, -0.11, 0.26)
		want_z += clampf(game.powertrain.acceleration * 0.010, -0.55, 0.42)
	if game.route.active:
		# Tighten the follow on big jumps; at fixed gain the truck left the top
		# of the frame above roughly 195 mph on stage 6.
		var air_follow: float=lerpf(0.58,0.88,clampf(game.route.air_height/13.0,0.0,1.0))
		cam_y += game.route.air_height*air_follow
		focus.y += clampf(surface_point(-30).y*0.5,-2.0,4.0)+game.route.air_height*(air_follow*0.72)
		focus.x += clampf(surface_point(-38).x*0.26,-2.2,2.2)
		focus.x += clampf(surface_point(-24).x*0.18,-1.4,1.4)*drift_view
	var ease: float = minf(_dt, 0.05)
	cam_fov_smooth = lerpf(cam_fov_smooth, want_fov, 1.0 - exp(-ease * 5.5))
	cam_y_smooth = lerpf(cam_y_smooth, cam_y, 1.0 - exp(-ease * 4.5))
	cam_z_smooth = lerpf(cam_z_smooth, want_z, 1.0 - exp(-ease * 2.8))
	cam_focus = cam_focus.lerp(focus, 1.0 - exp(-ease * 6.0))
	# The impact punch is an attack; it must not be smoothed away.
	camera.fov = cam_fov_smooth + (0.0 if game.calm_fx else pow(maxf(0.0, 1.0 - impact_time / 0.34), 2.0) * (1.8 + 3.6 * istr))
	camera.position = Vector3(camera_pan, cam_y_smooth, cam_z_smooth) + camera_shift()
	focus = cam_focus
	if game.stage==7 and game.route.active:
		var circle_view: float=smoothstep(30,140,game.route.progress)
		camera.position=camera.position.lerp(Vector3(camera_pan-13,7.0,18),circle_view)
		focus=focus.lerp(Vector3(camera_pan+18,9,-15),circle_view)
		truck.rotation.y=scene_truck_yaw()
	camera.look_at(focus,Vector3.UP)
	sky.rotation.y=camera.rotation.y
	sky.position=camera.position+Vector3(0,474,-600).rotated(Vector3.UP,camera.rotation.y)
	# A heavy cab banks out of a corner. look_at rebuilds the basis every frame,
	# so the roll has to be applied after it.
	if not game.calm_fx:
		var lean: float=clampf(-game.velocity_x*0.018-game.glide_velocity*0.022-game.rear_slip*0.010-game.steer_column*0.008,-0.052,0.052)
		cam_roll=lerpf(cam_roll,lean,1.0-exp(-minf(_dt,0.05)*3.2))
		camera.rotate_object_local(Vector3.BACK,cam_roll+game.cam_roll)
	_update_props()
	_update_hazards()
	_update_puddle_view()
	_update_sky()
	_update_cues()
	_update_approach()
	_update_shortcut()
	if is_instance_valid(game.finale): game.finale.update_storm()
	if is_instance_valid(destruction): destruction.update_view()
	if is_instance_valid(landscape): landscape.update_view()
	if is_instance_valid(shelters): shelters.update_view()
	_apply_quality()
	_update_contact_shadows()
	_update_storm_volume()
	for i in range(orbit_nodes.size()):
		var u: = i / 42.0
		var angle: float = game.elapsed * (1.1 + u) + i * 2.4
		var radius: = 8.0 + u * 12.0
		orbit_nodes[i].position = tornado.position + Vector3(sin(angle) * radius, -64 + u * 105.0, cos(angle) * radius)
		orbit_nodes[i].rotation = Vector3(angle, angle * 0.7, angle * 0.4)
		orbit_nodes[i].visible=orbit_nodes[i].position.distance_to(truck.position)>14.0
	if is_instance_valid(game.checkpoints) and game.checkpoints.active: game.checkpoints.apply_view()
	if is_instance_valid(game.finale) and (game.finale.active or game.finale.finished): game.finale.apply_view()
	if game.mode == game.Mode.GARAGE and is_instance_valid(game.garage): game.garage.apply_view()
	if is_instance_valid(mateo): mateo.face_camera(camera)
	if is_instance_valid(game.crashes):game.crashes.sync_projection()

## Every displacement the chase camera takes on top of its rest pose. The
## vortex heading in scene_truck_yaw() reconstructs the camera's X from this
## same function, so the two cannot fall out of step.
func camera_shift() -> Vector3:
	if game.calm_fx: return Vector3.ZERO
	var age: float = game.crashes.impact_age if is_instance_valid(game.crashes) else 10.0
	# The undirected ring is deliberately small: an impact is sold by the
	# directional impulse below, not by vibrating the whole frame.
	var ring: float = minf(game.shake, 9.0) * 0.0026 + game.lens_kick * 0.17
	var shift: Vector3 = Vector3(sin(age * 73.0), cos(age * 61.0), 0.0) * ring
	shift.x += game.near_side * game.near_pulse * 0.05
	shift.x += game.glide_velocity * 0.17
	shift.y += sin(game.elapsed * 46.0) * game.splash_pulse * 0.045
	return shift + game.cam_impulse

func scene_truck_yaw() -> float:
	if game.stage!=7 or not game.route.active:return game.truck_yaw
	var circle: float=smoothstep(30,140,game.route.progress)
	var x:=camera_pan+camera_shift().x
	x=lerpf(x,camera_pan-13.0,circle)
	var z:=lerpf(10.0+(0.0 if game.calm_fx else game.turbo_fx*.4),18.0,circle)
	var p:=road_point(0,game.player_x)
	return game.truck_yaw+atan2(x-p.x,z-p.z)*circle

func _update_props() -> void :
	for i in range(poles.size()):
		var z: = 23.0 - fposmod(i / 2 * 36.0 - travel, 396.0)
		var side: = -1.0 if i % 2 == 0 else 1.0
		poles[i].position = surface_point(z,side*12.5)
		poles[i].rotation = surface_rotation(z)
		poles[i].scale = Vector3.ZERO if game.stage>=4 else Vector3.ONE
		for batch in pole_batches: batch.set_instance_transform(i,poles[i].transform)
	for i in range(markers.size()):
		var z: = 18.0 - fposmod(i / 2 * 10.0 - travel, 380.0)
		var side: = -1.0 if i % 2 == 0 else 1.0
		markers[i].position = surface_point(z,side*((game.route.width(z)*0.5+0.45) if game.route.active else 7.45))
		markers[i].rotation = surface_rotation(z)
		for batch in marker_batches: batch.set_instance_transform(i,markers[i].transform)
	for i in range(turbines.size()):
		turbines[i].visible = game.stage in [1,2,3]
		var z: = -45.0 - fposmod(i * 63.0 - travel * 0.16, 340.0)
		turbines[i].position = surface_point(z,(-1 if i%2==0 else 1)*(38.0+i*3))
		turbines[i].get_node("Rotor").rotation.z = game.elapsed * 0.8 + i

func _hazard(kind: int, theme: int = 0, variant: String = "") -> Node3D:
	var n: = Node3D.new()
	n.set_meta("kind", kind)
	n.set_meta("theme", theme)
	n.set_meta("variant",variant)
	if variant=="semi_roof":
		var sheet: Node3D=semi_wreck_template.get_node("RoofSheet00").duplicate()
		sheet.position=Vector3.ZERO;n.add_child(sheet)
		return n
	if theme == 3 and kind < 4:
		if kind in [0,2]:
			var stone := SphereMesh.new()
			stone.radius = 0.85;stone.height = 1.2;stone.radial_segments = 7;stone.rings = 4
			mesh_node(n,stone,Vector3.ZERO,weathered(Color("625c4a"),0.3,0)).scale = Vector3(1.2,0.9,0.8)
		else:
			var log_piece := cylinder(n,Vector3.ZERO,0.32,2.0,mat_wood)
			log_piece.rotation.z = PI*0.5
			box(n,Vector3(0.5,0.32,0),Vector3(0.17,0.8,0.16),mat_wood).rotation.z = -0.5
		return n
	if theme > 0 and kind < 4:
		_build_fragment(n, kind, theme)
		return n
	if kind == 0:
		box(n, Vector3.ZERO, Vector3(1.45, 1.35, 1.38), mat_wood)
		for x in [ - 0.6, 0.6]:
			box(n, Vector3(x, 0, 0), Vector3(0.12, 1.46, 1.52), mat_steel)
		for y in [ - 0.56, 0.56]: box(n, Vector3(0, y, 0), Vector3(1.6, 0.13, 1.52), mat_steel)
		var brace: = box(n, Vector3(0, 0, 0.71), Vector3(0.16, 1.68, 0.07), mat_wood)
		brace.rotation.z = 0.72
	elif kind == 1:
		cylinder(n, Vector3.ZERO, 0.56, 1.45, mat_red)
		for y in [ - 0.5, 0.5]: cylinder(n, Vector3(0, y, 0), 0.59, 0.08, mat_steel)
	elif kind == 2:
		var torus: = TorusMesh.new()
		torus.inner_radius = 0.29
		torus.outer_radius = 0.7
		torus.rings = 20
		torus.ring_segments = 12
		var tire: = mesh_node(n, torus, Vector3.ZERO, mat_rubber)
		tire.rotation.x = PI / 2
	elif kind == 3:
		box(n, Vector3.ZERO, Vector3(1.8, 0.08, 1.35), mat_silver)
		for i in range(9): box(n, Vector3( - 0.8 + i * 0.2, 0.055, 0), Vector3(0.055, 0.065, 1.35), mat_steel)
	else:
		box(n, Vector3.ZERO, Vector3(0.94, 0.9, 0.9), mat_steel)
		box(n, Vector3(0, 0, 0.46), Vector3(0.61, 0.16, 0.03), mat_mint)
		box(n, Vector3(0, 0, 0.47), Vector3(0.16, 0.61, 0.03), mat_mint)
	return n

func _build_fragment(n: Node3D, kind: int, theme: int) -> void :

	var wall: Material = building_materials[0 if theme == 1 else 2]
	var metal: Material = building_materials[1 if theme == 1 else 3]
	if kind == 3:
		box(n, Vector3.ZERO, Vector3(1.8, 0.08, 1.35), metal)
		for i in range(8): box(n, Vector3( - 0.75 + i * 0.21, 0.06, 0), Vector3(0.055, 0.07, 1.35), metal)
	elif theme == 1:
		if kind == 0:
			for i in range(3):
				var plank: = box(n, Vector3((i - 1) * 0.42, 0, 0), Vector3(0.36, 1.6 + sin(i * 3.0) * 0.32, 0.14), wall)
				plank.rotation.z = (i - 1) * 0.18
			box(n, Vector3(0, - 0.25, 0.1), Vector3(1.42, 0.15, 0.14), mat_wood)
		elif kind == 1:
			box(n, Vector3.ZERO, Vector3(1.35, 1.55, 0.13), wall)
			var brace: = box(n, Vector3(0, 0, 0.1), Vector3(0.12, 1.75, 0.1), mat_wood)
			brace.rotation.z = 0.65
		else:
			for turn in [ - 0.55, 0.55]:
				var beam: = box(n, Vector3.ZERO, Vector3(0.2, 1.95, 0.2), wall)
				beam.rotation.z = turn
	else:
		if kind == 0:
			box(n, Vector3.ZERO, Vector3(1.3, 1.05, 0.6), wall)
			for x in [ - 0.4, 0.4]: box(n, Vector3(x, - 0.55, 0), Vector3(0.045, 0.5, 0.05), mat_steel)
		elif kind == 1:
			box(n, Vector3.ZERO, Vector3(1.5, 0.15, 0.62), metal)
			for y in [ - 0.37, 0.37]: box(n, Vector3(0, y, 0), Vector3(1.5, 0.08, 0.64), metal)
			box(n, Vector3.ZERO, Vector3(1.5, 0.7, 0.08), metal)
		else:
			box(n, Vector3.ZERO, Vector3(1.5, 1.15, 0.08), metal)
			for y in [ - 0.37, 0, 0.37]: box(n, Vector3(0, y, 0.05), Vector3(1.5, 0.04, 0.05), mat_silver)

func _update_hazards() -> void :
	while hazard_nodes.size() < game.debris.size():
		var n: = Node3D.new()
		n.set_meta("kind", -1)
		space.add_child(n)
		hazard_nodes.append(n)
	for i in range(hazard_nodes.size()):
		var n: = hazard_nodes[i]
		n.visible = i < game.debris.size()
		if not n.visible: continue
		var d: Dictionary = game.debris[i]
		var theme: int = int(d.get("theme", 0))
		if n.get_meta("kind") != d.kind or int(n.get_meta("theme", -1)) != theme or str(n.get_meta("variant",""))!=str(d.get("variant","")):
			n.free()
			n = _hazard(d.kind, theme,str(d.get("variant","")))
			space.add_child(n)
			hazard_nodes[i] = n
		n.visible=not d.get("consumed",false)
		n.transform=hazard_transform(d,game.elapsed)

func hazard_transform(d: Dictionary, time: float) -> Transform3D:
	if d.has("impact_age"):
		var age: float=maxf(0.0,float(d.impact_age)-.045)
		var pose: Transform3D=d.impact_transform
		pose.origin+=Vector3(d.impact_velocity)*age+Vector3.DOWN*4.5*age*age
		pose.basis=Basis.from_euler(Vector3(age*1.2,age*2.1,age*3.0))*pose.basis
		return pose
	var z: float=-85.0*(1.0-d.z)
	var lift: float=.2+absf(sin(time*5.0+d.phase))*.9 if d.kind<2 or d.kind==3 or int(d.get("theme",0))>0 else 0.0
	var p:=road_point(z,d.lane)+Vector3.UP*(.8+lift)
	var angles:=Vector3(d.angle*.44,d.angle*.5,d.angle) if d.kind<4 else Vector3(0,time*.65,0)
	var basis:=Basis.from_euler(angles)
	if d.has("fall_origin"):
		var u: float=d.z;var origin: Vector3=d.fall_origin
		z=origin.z*(1.0-u);p=road_point(z,d.lane)+Vector3.UP*1.1
		p.x=lerpf(origin.x,p.x,smoothstep(0.0,.82,u))
		p.y=lerpf(origin.y,p.y,1.0-pow(maxf(0,1.0-u),2.0))
		basis=basis*Basis(d.fall_basis)
	return Transform3D(basis,p)

func hazard_bounds(kind: int, theme: int, variant: String = "") -> AABB:
	var key: String="%d:%d:%s"%[kind,theme,variant]
	if not hazard_bound_cache.has(key):
		var root:=_hazard(kind,theme,variant);var points:=PackedVector3Array()
		_collect_bounds(root,Transform3D.IDENTITY,points)
		var bounds:=AABB(points[0],Vector3.ZERO)
		for p in points:bounds=bounds.expand(p)
		hazard_bound_cache[key]=bounds;root.free()
	return hazard_bound_cache[key]

func _collect_bounds(node: Node3D, pose: Transform3D, points: PackedVector3Array) -> void:
	if node is MeshInstance3D:
		for i in range(8):points.append(pose*node.get_aabb().get_endpoint(i))
	for child in node.get_children():
		if child is Node3D:_collect_bounds(child,pose*child.transform,points)

func sky_transform(piece: Dictionary) -> Transform3D:
	var u: float=clampf(piece.age/piece.duration,0,1)
	var z:=lerpf(-145.0,-25.0,u)
	var target: float=float(piece.get("start_x",0))*5.8+float(piece.side)*72.0
	var x:=lerpf(tornado.position.x,target,smoothstep(0,.95,u))
	var y:=26.0+sin(u*PI)*10.0
	var angles:=Vector3(.15+u*.5,PI*.5+piece.side*u*.35,PI*.75+u*1.3) if piece.kind==0 else Vector3(0,0,piece.side*(u-.5)*.65)
	return Transform3D(Basis.from_euler(angles),Vector3(x,y,z))

func _update_sky() -> void :
	while sky_nodes.size() < game.sky_debris.size():
		var n: = Node3D.new()
		n.set_meta("kind", -1)
		space.add_child(n)
		sky_nodes.append(n)
	for i in range(sky_nodes.size()):
		var n: = sky_nodes[i]
		n.visible = i < game.sky_debris.size()
		if not n.visible: continue
		var piece: Dictionary = game.sky_debris[i]
		if n.get_meta("kind") != piece.kind:
			n.free()
			if piece.kind == 0:
				n = Node3D.new();n.set_script(preload("res://scripts/semi_wreck.gd"));n.build(self)
			else:
				n = Node3D.new()
				var cow: = Sprite3D.new()
				cow.texture = COW
				cow.pixel_size = 0.0062
				cow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				cow.modulate = Color(0.86, 0.92, 0.95)
				n.add_child(cow)
			n.set_meta("kind", piece.kind)
			space.add_child(n)
			sky_nodes[i] = n
		var u: float = clampf(piece.age / piece.duration, 0.0, 1.0)
		n.transform=sky_transform(piece)
		if piece.kind == 0:
			n.update_breakup(u,game.elapsed,self)
			if piece.get("shed",false):n.parts[10].hide()

func _update_puddle_view() -> void:
	while puddle_nodes.size() < game.puddles.size():
		var surface := PlaneMesh.new()
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://shaders/puddle.gdshader")
		mat.set_shader_parameter("storm_sky", SKY)
		var n := mesh_node(space, surface, Vector3.ZERO, mat)
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		puddle_nodes.append(n)
	for i in range(puddle_nodes.size()):
		var n := puddle_nodes[i]
		n.visible = i < game.puddles.size()
		if not n.visible: continue
		var p: Dictionary = game.puddles[i]
		n.position = road_point(p.z,p.lane)+Vector3.UP*0.04
		n.rotation = surface_rotation(p.z)
		(n.mesh as PlaneMesh).size = Vector2(p.half_width*(game.route.lane_scale(p.z)*2 if game.route.active else 11.6),p.length)
		(n.material_override as ShaderMaterial).set_shader_parameter("clock", game.elapsed)
		(n.material_override as ShaderMaterial).set_shader_parameter("phase", p.phase)
		(n.material_override as ShaderMaterial).set_shader_parameter("mud",game.route.dirt_at(game.route.progress-p.z) if game.route.active else 0.0)

func splash_burst(intensity: float) -> void:
	water_fx.splash(intensity)
	var count: int = 24 if game.calm_fx or game.light_graphics else 52
	for i in range(count):
		var side := -1.0 if i % 2 == 0 else 1.0
		var a: float = i * 2.39996 + game.elapsed
		var power: float = 0.55 + absf(sin(a)) * 0.45
		var point: Vector3 = road_point(0,game.player_x)+Vector3.UP*0.18 + Vector3(side * 1.12, 0, -1.5 + fmod(i * 0.73, 3.2)).rotated(Vector3.UP, truck.rotation.y)
		spray.append({"pos": point, "velocity": Vector3(side * (3.8 + intensity * 3.6) * power + game.glide_velocity * 3.0, (2.7 + intensity * 2.4) * power, game.speed * (0.045 + power * 0.026)), "age": -fmod(i * 0.027, 0.21), "size": 0.025 + power * 0.04, "life": 0.68, "splash": true})

func _update_spray(dt: float) -> void :
	for p in spray:
		p.age += dt
		if p.age < 0.0: continue
		p.pos += p.velocity * dt
		p.velocity.y -= dt * (9.0 if p.get("splash", false) else 4.4)
	spray = spray.filter(func(p): return p.age < p.get("life", 0.43) and p.pos.z < 9.0 and p.pos.y > -0.2)
	spray_clock -= dt
	if spray_clock <= 0.0 and game.route.grounded:
		spray_clock = 0.045 if game.light_graphics else 0.028
		for side in [-1.0, 1.0]:
			for j in range(2):
				var a: float = game.elapsed * 71.0 + j * 2.6
				var point: Vector3 = truck.position + Vector3(side * 1.12, 0.15, 1.9).rotated(Vector3.UP, truck.rotation.y)
				spray.append({"pos": point, "velocity": Vector3(side * (1.7 + sin(a)) + game.rear_slip * 2.4, 1.2 + absf(sin(a)) * 0.9, game.speed * 0.07), "age": 0.0, "size": 0.04 + absf(sin(a * 1.3)) * 0.035})

func reset_motion() -> void :
	travel = 0.0
	last_landing = 0
	camera_pan = 0.0
	cam_roll = 0.0
	cam_y_smooth = 3.4
	cam_z_smooth = 10.0
	cam_fov_smooth = 66.0
	cam_focus = Vector3(0.0, 3.9, -29.0)
	spray.clear()
	spray_clock = 0.0
	road_bend = 99.0
	mesh_progress = -999.0
	mesh_level = -1
	position = Vector2.ZERO
	rotation = 0.0
	if is_instance_valid(mateo): mateo.reset_pose()
	if is_instance_valid(truck): truck.reset()
	if is_instance_valid(water_fx): water_fx.reset()
	if is_instance_valid(contact_fx): contact_fx.reset()
	if is_instance_valid(shelters): shelters.reset()

func contact_burst(point: Vector3, normal: Vector3, theme: int, kind: int) -> void:
	contact_fx.burst(point,normal,theme,kind)

func wheel_height_difference() -> float:
	_update_view(0.0)
	var left: Vector3 = truck.transform * Vector3(-1.12, 0.57, 1.68)
	var right: Vector3 = truck.transform * Vector3(1.12, 0.57, 1.68)
	return absf(left.y - right.y)

func _draw() -> void :
	if game.mode == game.Mode.MENU or not is_instance_valid(camera): return
	_draw_spray_and_skids()
	_draw_weather()
	_draw_probe()

func _draw_spray_and_skids() -> void :
	for p in spray:
		if p.age < 0.0 or camera.is_position_behind(p.pos): continue
		var point: = camera.unproject_position(p.pos)
		var burst: bool = p.get("splash", false)
		var alpha: float = (1.0 - p.age / p.get("life", 0.43)) * (0.30 if burst else 0.20)
		var radius: float = clampf((p.size + p.age * 0.3) * 90.0 / maxf(0.4, camera.position.z - p.pos.z), 0.4, 2.8 if burst else 2.0)
		draw_circle(point,radius,Color(0.65,0.43,0.23,alpha*1.7) if game.route.dirt>0.5 else Color(0.76,0.87,0.91,alpha))
	for t in game.skid_trails:
		if t.strength < 0.1: continue
		for side in [-1.0, 1.0]:
			var z: float = 1.7 + (game.route.progress-float(t.get("course",game.route.progress))) if game.route.active else 1.7+t.age*game.speed*0.25
			if z > 7.8: continue
			var tire_offset:=Vector3(side*1.08,0.035,0).rotated(Vector3.UP,float(t.get("yaw",0.0)))
			var a: Vector3 = road_point(z,t.lane)+tire_offset
			var b: Vector3 = road_point(z+0.65,t.lane)+tire_offset
			var ink:=Color(0.23,0.12,0.055,0.70*t.strength) if game.route.dirt>0.5 else Color(0.02,0.035,0.04,0.45*t.strength)
			draw_line(camera.unproject_position(a), camera.unproject_position(b), ink, 6.0 if game.route.dirt>0.5 else 4.0, true)

func _draw_weather() -> void :
	var time: float = game.elapsed
	if game.mode == game.Mode.CHECKPOINT and is_instance_valid(game.checkpoints): time += game.checkpoints.age
	if game.mode == game.Mode.VORTEX: time += game.finale.age
	if game.mode == game.Mode.GARAGE and is_instance_valid(game.garage): time += game.garage.age
	var speed_factor: float = game.speed / 180.0
	var count: = 70 if game.light_graphics else (95 if game.calm_fx else rain.size())
	for i in range(count):
		var r: = rain[i]
		var x: = fposmod(r.x + time * (135.0 + game.wind * 700.0) * r.z, 1440.0) - 80.0
		var y: = fposmod(r.y + time * (680.0 + game.speed * 2.3) * r.z, 860.0) - 90.0
		var length: = (18.0 + speed_factor * 27.0) * r.z
		draw_line(Vector2(x, y), Vector2(x - 10.0 - game.wind * 17.0, y + length), Color(0.64, 0.79, 0.84, 0.1 + r.z * 0.1), 0.6 + r.z * 0.6, true)
	if not game.calm_fx:
		for i in range(25):
			var phase: = fposmod(time * (1.1 + game.turbo_fx * 0.65) + i * 0.17, 1.0)
			var side: = -1.0 if i % 2 == 0 else 1.0
			var a: = Vector2(640 + side * (320 + phase * 470), 330 + phase * 410)
			var b: = a + Vector2(side * (30 + phase * 95), 50 + phase * 60)
			draw_line(a, b, Color(0.63, 0.76, 0.8, (0.018 + game.turbo_fx * 0.045) * phase), 1.0, true)
		if game.flash > 0.0: draw_rect(Rect2(0, 0, 1280, 720), Color(0.9, 0.34, 0.12, game.flash * 0.09))

	for i in range(12):
		var c: = Color(0.012, 0.025, 0.036, 0.011 * (12 - i))
		draw_rect(Rect2(i * 7, 0, 7, 720), c)
		draw_rect(Rect2(1273 - i * 7, 0, 7, 720), c)

func _draw_probe() -> void :
	for e in game.effects:
		if e.type != "probe": continue
		var pos: Vector3 = road_point(-35.0*(1.0-e.z),e.x)+Vector3.UP*1.1
		if camera.is_position_behind(pos): continue
		var p: = camera.unproject_position(pos)
		draw_arc(p, 8.0 + (1.8 - e.life) * 18.0, 0, TAU, 32, Color(0.4, 1, 0.74, e.life / 1.8), 2.0, true)

func _exit_tree() -> void :
	if is_instance_valid(semi_template): semi_template.free()
	if is_instance_valid(semi_wreck_template):semi_wreck_template.free()

func _cue(pool: Array[MeshInstance3D], count: int) -> void:
	while pool.size()<count:
		var plane:=PlaneMesh.new()
		var mat:=ShaderMaterial.new()
		mat.shader=preload("res://shaders/road_cue.gdshader")
		var n:=mesh_node(space,plane,Vector3.ZERO,mat)
		n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pool.append(n)

func _update_cues() -> void:
	_cue(cue_shadows,game.debris.size())
	for i in range(cue_shadows.size()):
		var n:=cue_shadows[i]
		n.visible=i<game.debris.size() and game.mode==game.Mode.RUNNING
		if not n.visible: continue
		var d: Dictionary=game.debris[i]
		n.visible=d.kind<4 and not d.checked and d.z>0.14 and d.z<1.12
		var pose:=hazard_transform(d,game.elapsed)
		var z: float=pose.origin.z
		n.position=Vector3(pose.origin.x,surface_point(z).y+.055,z)
		n.rotation=surface_rotation(z)
		(n.mesh as PlaneMesh).size=Vector2(3.1,4.5) if d.get("variant","")=="semi_roof" else Vector2(2.5,3.2)
		n.material_override.set_shader_parameter("warning",1.0 if d.z<0.94 else 0.0)

func _update_approach() -> void:
	var next_theme: int=game.stage+1
	var remain: float=(game.stage+1)*game.STAGE_LENGTH-game.elapsed
	var show_site: bool=next_theme<=2 and remain<10.0 and game.mode in [game.Mode.RUNNING,game.Mode.UPGRADE]
	if game.mode==game.Mode.UPGRADE or (game.mode==game.Mode.CHECKPOINT and game.checkpoints.film_playing):
		next_theme=game.stage; remain=0.0; show_site=next_theme<=2
	if not show_site:
		if is_instance_valid(approach_site): approach_site.hide()
		return
	if approach_theme!=next_theme:
		if is_instance_valid(approach_site): approach_site.free()
		approach_site=Node3D.new()
		space.add_child(approach_site)
		approach_theme=next_theme
		var wall: Material=building_materials[0 if next_theme==1 else 2]
		var roof_mat: Material=building_materials[1 if next_theme==1 else 3]
		var width:=18.0 if next_theme==1 else 24.0
		var height:=7.2 if next_theme==1 else 9.4
		box(approach_site,Vector3(0,height/2,0),Vector3(width,height,13.0),wall)
		for side in [-1.0,1.0]:
			var roof_panel:=box(approach_site,Vector3(side*width*0.25,height+1.4,0),Vector3(width*0.55,0.18,14.0),roof_mat)
			roof_panel.rotation.z=-side*0.28
		box(approach_site,Vector3(0,2.4,6.55),Vector3(4.0,4.8,0.1),mat_steel)
		var sign:=Label3D.new()
		sign.text="SILO COUNTY" if next_theme==1 else "FREIGHT  /  07"
		sign.position=Vector3(0,height-1,6.64)
		sign.font=preload("res://assets/fonts/display.ttf")
		sign.font_size=60;sign.pixel_size=0.014;sign.outline_size=6
		sign.modulate=Color("c9c6ad")
		approach_site.add_child(sign)
	approach_site.show()
	var u:=smoothstep(10.0,0.0,remain)
	var z:=lerpf(-140.0,-39.0,u)
	approach_site.position=Vector3(road_center(z)+25.0,0,z)

func _apply_quality() -> void:
	var quality: int=1 if game.light_graphics else 0
	if quality==last_quality: return
	last_quality=quality
	sun.shadow_enabled=not game.light_graphics
	environment.glow_enabled=not game.light_graphics
	environment.adjustment_enabled=not game.light_graphics
	get_viewport().msaa_3d=Viewport.MSAA_DISABLED if game.light_graphics else Viewport.MSAA_2X
	for i in range(orbit_nodes.size()): orbit_nodes[i].visible=not game.light_graphics or i%2==0

const FIELD_ACROSS := [-500.0,-160.0,-90.0,-48.0,-32.0,-20.0,-12.0,-6.0,0.0,6.0,12.0,20.0,32.0,48.0,90.0,160.0,500.0]
const FIELD_ROWS := 80

## Wide offsets around a hairpin fold over themselves, so the distant hills use an
## ordinary x/z grid (80 rows every 6 units, columns in FIELD_ACROSS). The grid is
## built once; ground.gdshader lifts each vertex with the _field_height() formula
## and reproduces SurfaceTool.generate_normals() from its six neighbouring faces.
func _build_terrain_field() -> void:
	var columns := FIELD_ACROSS.size()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var spacing := PackedVector2Array()
	var rows_present := PackedVector2Array()
	var indices := PackedInt32Array()
	for row in range(FIELD_ROWS):
		var z := 48.0-row*6.0
		for column in range(columns):
			var x: float = FIELD_ACROSS[column]
			verts.append(Vector3(x, 0.0, z))
			normals.append(Vector3.UP)
			spacing.append(Vector2(x-float(FIELD_ACROSS[column-1]) if column > 0 else 0.0, float(FIELD_ACROSS[column+1])-x if column < columns-1 else 0.0))
			rows_present.append(Vector2(1.0 if row > 0 else 0.0, 1.0 if row < FIELD_ROWS-1 else 0.0))
	for row in range(FIELD_ROWS-1):
		for column in range(columns-1):
			var a := row*columns+column
			indices.append_array(PackedInt32Array([a, a+1, a+columns, a+1, a+columns+1, a+columns]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = spacing
	arrays[Mesh.ARRAY_TEX_UV2] = rows_present
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	terrain_field_material = ShaderMaterial.new()
	terrain_field_material.shader = ground_material.shader
	for key in ["field_texture", "clay_texture", "grass_texture"]:
		terrain_field_material.set_shader_parameter(key, ground_material.get_shader_parameter(key))
	terrain_field_material.set_shader_parameter("terrain_field", true)
	terrain_field = MeshInstance3D.new()
	terrain_field.name = "HillField"
	terrain_field.mesh = mesh
	terrain_field.material_override = terrain_field_material
	terrain_field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Heights are applied on the GPU, so give culling the real vertical extent.
	terrain_field.custom_aabb = AABB(Vector3(-520.0, -90.0, -450.0), Vector3(1040.0, 160.0, 520.0))
	terrain_field.visible = false
	space.add_child(terrain_field)

func _terrain_mesh(rows: Dictionary = {}) -> void:
	if game.stage not in [4,5,6]: return
	var samples:=PackedVector3Array()
	for row in range(38): samples.append(surface_point(30.0-row*12.0))
	_field_prepare(samples)
	var field_inputs := {"road_samples": samples, "road_sample_count": samples.size(), "field_origin": _field_origin,
		"field_heading": atan2(_field_sin, _field_cos), "field_base": _field_base, "field_junction": game.stage==4,
		"field_bounds": Vector4(_field_bounds[0], _field_bounds[1], _field_bounds[2], _field_bounds[3])}
	# The hill grid and roadside grass read the same field inputs.
	for mat in [terrain_field_material, landscape.grass_material if is_instance_valid(landscape) else null]:
		if mat == null: continue
		for key in field_inputs: mat.set_shader_parameter(key, field_inputs[key])
	# The narrow strip joining the road edge still follows the exact road rows.
	var across := PackedFloat64Array([-9.0,-7.0,0.0,7.0,9.0])
	var drops := PackedFloat64Array()
	for side in across: drops.append(0.025+smoothstep(7.0,9.0,absf(side))*0.90)
	# Five shoulder points per row, shared by the quads on both sides of the row.
	var edges: Array[PackedVector3Array] = []
	for row in range(146):
		var r: Array = _road_row(24.0-row*3.0, rows)
		var center: Vector3 = r[0]
		var right: Vector3 = r[1]
		var points := PackedVector3Array()
		for k in range(5): points.append(center + right*across[k] - Vector3(0, drops[k], 0))
		edges.append(points)
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	for row in range(145):
		var z := 24.0-row*3.0
		var near: PackedVector3Array = edges[row]
		var far: PackedVector3Array = edges[row+1]
		for column in range(4):
			var s0: float = across[column]
			var s1: float = across[column+1]
			verts.append_array(PackedVector3Array([near[column], near[column+1], far[column], near[column+1], far[column+1], far[column]]))
			uvs.append_array(PackedVector2Array([Vector2(s0,z), Vector2(s1,z), Vector2(s0,z-3.0), Vector2(s1,z), Vector2(s1,z-3.0), Vector2(s0,z-3.0)]))
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	normals.fill(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=verts;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_TEX_UV]=uvs
	var st := SurfaceTool.new()
	st.create_from_arrays(arrays, Mesh.PRIMITIVE_TRIANGLES)
	st.generate_normals()
	terrain.mesh=st.commit()

# Terrain elevation field. The road-segment table and course frame are cached per
# sample set and progress, because scenery asks for hundreds of heights a frame.
var _field_samples := PackedVector3Array()
var _field_segments := PackedFloat64Array()
var _field_bounds := PackedFloat64Array([0.0, 0.0, 0.0, 0.0])
var _field_progress := INF
var _field_level := -1
var _field_origin := Vector2.ZERO
var _field_cos := 1.0
var _field_sin := 0.0
var _field_base := 0.0

const FIELD_STRIDE := 9

func _field_prepare(samples: PackedVector3Array) -> void:
	if _field_progress != game.route.progress or _field_level != game.route.level:
		_field_progress = game.route.progress
		_field_level = game.route.level
		var heading: float = game.route.heading(game.route.progress)
		_field_origin = game.route.course(game.route.progress)
		_field_cos = cos(heading)
		_field_sin = sin(heading)
		_field_base = game.route.height_at(game.route.progress)
		_field_samples = PackedVector3Array()
	if samples == _field_samples: return
	_field_samples = samples
	_field_segments.resize(maxi(0, samples.size()-1) * FIELD_STRIDE)
	var min_x := INF; var max_x := -INF; var min_z := INF; var max_z := -INF
	for i in range(samples.size()-1):
		var a: Vector3 = samples[i]
		var b: Vector3 = samples[i+1]
		var k := i * FIELD_STRIDE
		_field_segments[k] = a.x
		_field_segments[k+1] = a.z
		_field_segments[k+2] = b.x - a.x
		_field_segments[k+3] = b.z - a.z
		_field_segments[k+4] = maxf((b.x-a.x)*(b.x-a.x) + (b.z-a.z)*(b.z-a.z), 0.01)
		_field_segments[k+5] = a.y
		_field_segments[k+6] = b.y
		_field_segments[k+7] = minf(a.z, b.z)
		_field_segments[k+8] = maxf(a.z, b.z)
		min_x = minf(min_x, minf(a.x, b.x)); max_x = maxf(max_x, maxf(a.x, b.x))
		min_z = minf(min_z, minf(a.z, b.z)); max_z = maxf(max_z, maxf(a.z, b.z))
	_field_bounds = PackedFloat64Array([min_x, max_x, min_z, max_z])

func _field_height(point: Vector2, samples: PackedVector3Array) -> float:
	_field_prepare(samples)
	return field_height_at(point.x, point.y)

## _field_height() for callers that already ran _field_prepare() with this frame's samples.
func field_height_at(px: float, pz: float) -> float:
	var cx := _field_origin.x + _field_cos*px - _field_sin*pz
	var cy := _field_origin.y + _field_sin*px + _field_cos*pz
	var flat_junction := 0.0
	if game.stage==4: flat_junction=1.0-smoothstep(80.0,140.0,cx)
	var rolling: float = -9.0 + sin(cx*0.024)*5.0 + sin(cy*0.021+cx*0.012)*6.0 + sin(cx*0.061+cy*0.038)*1.8
	var blend := 1.0
	var elevation: float = -22.0-_field_base
	# Beyond 95 units from every road segment the field is pure rolling hills.
	var reach := 95.0
	if px > _field_bounds[0]-reach and px < _field_bounds[1]+reach and pz > _field_bounds[2]-reach and pz < _field_bounds[3]+reach:
		var closest := 10000000.0
		var segments := _field_segments
		var count := segments.size() / FIELD_STRIDE
		# Samples run ahead of the truck roughly every 12 units, so start at the
		# segment level with this point and reject segments by their depth range.
		var first := clampi(int((30.0 - pz) / 12.0), 0, maxi(0, count-1))
		for pass_index in range(2):
			var i := first if pass_index == 0 else first - 1
			var direction := 1 if pass_index == 0 else -1
			while i >= 0 and i < count:
				var k := i * FIELD_STRIDE
				i += direction
				var outside: float = segments[k+7] - pz
				if outside < 0.0: outside = pz - segments[k+8]
				if outside > 0.0 and outside*outside >= closest: continue
				var ax: float = segments[k]
				var az: float = segments[k+1]
				var dx: float = segments[k+2]
				var dz: float = segments[k+3]
				var along := clampf(((px-ax)*dx + (pz-az)*dz) / segments[k+4], 0.0, 1.0)
				var ex := px - (ax + dx*along)
				var ez := pz - (az + dz*along)
				var distance := ex*ex + ez*ez
				if distance < closest:
					closest = distance
					elevation = lerpf(segments[k+5], segments[k+6], along) - 0.85
		blend = smoothstep(14.0, 95.0, sqrt(closest))
	var field := lerpf(elevation, rolling-_field_base, blend)
	return lerpf(field, -0.055-_field_base, flat_junction)

func _update_shortcut() -> void:
	if not is_instance_valid(shortcut_sign):
		shortcut_sign=Node3D.new();space.add_child(shortcut_sign)
		box(shortcut_sign,Vector3(0,1.2,0),Vector3(0.12,2.4,0.12),mat_steel)
		box(shortcut_sign,Vector3(0,2.2,0),Vector3(4.1,1.4,0.16),material(Color("b48631"),0.8))
		var label:=Label3D.new()
		label.text="90° RIGHT\nDIRT SHORTCUT  >"
		label.font=preload("res://assets/fonts/display.ttf")
		label.font_size=42;label.pixel_size=0.009;label.outline_size=0
		label.modulate=Color("15262b");label.position=Vector3(0,2.2,0.1)
		shortcut_sign.add_child(label)
		shortcut_barrier=Node3D.new();space.add_child(shortcut_barrier)
		for side in [-1.0,1.0]: box(shortcut_barrier,Vector3(side*2.5,0.7,0),Vector3(0.18,1.4,0.25),mat_steel)
		box(shortcut_barrier,Vector3(0,1.2,0),Vector3(8,0.8,0.22),material(Color("b35c29"),0.8))
		var closed:=Label3D.new();closed.text="ROAD CLOSED"
		closed.font=preload("res://assets/fonts/display.ttf");closed.font_size=65;closed.pixel_size=0.012
		closed.position=Vector3(0,1.2,0.14);shortcut_barrier.add_child(closed)
	var show_turn: bool=game.stage==4 and game.route.progress<290
	shortcut_sign.visible=show_turn;shortcut_barrier.visible=show_turn
	if not show_turn:return
	var sign_point: Vector2=game.route.project(Vector2(-9.2,-130.0))
	shortcut_sign.position=Vector3(sign_point.x,0,sign_point.y)
	shortcut_sign.rotation.y=game.route.heading(game.route.progress)
	var block: Vector2=game.route.project(Vector2(0,-game.route.SHORTCUT_JUNCTION_Z-23.0))
	shortcut_barrier.position=Vector3(block.x,0.03,block.y)
	shortcut_barrier.rotation.y=game.route.heading(game.route.progress)

func _build_contact_shadows() -> void:
	contact_blobs.clear()
	var shader: Shader = preload("res://shaders/contact_blob.gdshader")
	for i in range(5):
		var plane := PlaneMesh.new()
		plane.size = Vector2(1.55, 1.55) if i < 4 else Vector2(2.8, 5.4)
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("opacity", 0.34 if i < 4 else 0.20)
		var n := mesh_node(space, plane, Vector3(0, 0.02, 0), mat)
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.name = "ContactBlob%d" % i
		contact_blobs.append(n)

func _build_storm_volume() -> void:
	tornado_cross = mesh_node(space, _storm_mesh(), tornado.position, storm_material)
	tornado_cross.rotation.y = PI * 0.5
	tornado_cross.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ring := PlaneMesh.new()
	ring.size = Vector2(54, 54)
	var dust_mat := ShaderMaterial.new()
	dust_mat.shader = preload("res://shaders/storm_dust.gdshader")
	var dust_tex: Texture2D = Media.texture("res://assets/art/terrain/storm-dust.png", "clay")
	if dust_tex: dust_mat.set_shader_parameter("dust_texture", dust_tex)
	dust_mat.set_shader_parameter("opacity", 0.5)
	dust_ring = mesh_node(space, ring, Vector3.ZERO, dust_mat)
	dust_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build_rain_sheets() -> void:
	var shader: Shader = preload("res://shaders/rain_curtain.gdshader")
	for i in range(3):
		var quad := QuadMesh.new()
		quad.size = Vector2(70.0 - i * 8.0, 32.0)
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("density", 0.42 - i * 0.08)
		var n := mesh_node(space, quad, Vector3.ZERO, mat)
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.name = "RainSheet%d" % i
		rain_sheets.append(n)

func _update_contact_shadows() -> void:
	if contact_blobs.size() < 5 or not is_instance_valid(truck):
		return
	var air: float = game.route.air_height
	var fade: float = 1.0 if game.route.grounded else clampf(1.0 - air / 3.6, 0.0, 1.0)
	if game.light_graphics:
		fade = 0.0
	var ground_y: float = road_point(0, game.player_x).y + 0.02
	for i in range(4):
		var p: Vector3 = truck.wheels[i].global_position
		contact_blobs[i].visible = fade > 0.03
		contact_blobs[i].global_position = Vector3(p.x, ground_y, p.z)
		contact_blobs[i].rotation = Vector3(0.0, truck.rotation.y, 0.0)
		(contact_blobs[i].material_override as ShaderMaterial).set_shader_parameter("opacity", (0.40 if i < 2 else 0.36) * fade)
	var tp: Vector3 = truck.global_position
	contact_blobs[4].visible = fade > 0.03
	contact_blobs[4].global_position = Vector3(tp.x, ground_y - 0.004, tp.z)
	contact_blobs[4].rotation = Vector3(0.0, truck.rotation.y, 0.0)
	(contact_blobs[4].material_override as ShaderMaterial).set_shader_parameter("opacity", 0.18 * fade)

func _update_storm_volume() -> void:
	if is_instance_valid(tornado_cross):
		tornado_cross.position = tornado.position
		tornado_cross.rotation = tornado.rotation + Vector3(0.0, PI * 0.5, 0.0)
		tornado_cross.visible = not game.light_graphics
	if is_instance_valid(dust_ring):
		dust_ring.position = Vector3(tornado.position.x, tornado.position.y - 68.5, tornado.position.z)
		dust_ring.rotation.y = game.elapsed * 0.55
		var dust_mat := dust_ring.material_override as ShaderMaterial
		dust_mat.set_shader_parameter("clock", game.elapsed)
		var bolt: float = 0.0 if game.calm_fx else game.lightning
		dust_mat.set_shader_parameter("opacity", 0.52 + bolt * 0.2)
		dust_ring.visible = not game.light_graphics
	for i in range(rain_sheets.size()):
		var n: MeshInstance3D = rain_sheets[i]
		var z: float = -14.0 - float(i) * 24.0
		n.position = road_point(z, 0.0) + Vector3.UP * 9.0
		if n.position.distance_to(camera.global_position) > 0.4:
			n.look_at(camera.global_position, Vector3.UP)
		var mat := n.material_override as ShaderMaterial
		mat.set_shader_parameter("clock", game.elapsed)
		mat.set_shader_parameter("wind", game.wind)
		n.visible = not game.light_graphics

func _storm_mesh() -> ArrayMesh:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(40):
		var top:=row/40.0;var bottom:=(row+1)/40.0
		for uv in [Vector2(0,top),Vector2(1,top),Vector2(0,bottom),Vector2(1,top),Vector2(1,bottom),Vector2(0,bottom)]:
			surface.set_uv(uv);surface.set_normal(Vector3.BACK)
			surface.add_vertex(Vector3((uv.x-.5)*106.0,(.5-uv.y)*147.0,0))
	return surface.commit()
