extends Node3D
## Mateo Garage parts for the approved interceptor.
##
## Parts are separate rigid meshes parented to the sprung body (or beside each
## wheel for coilovers), built on first use and only shown or recolored after
## that. The approved truck meshes are never modified; the stock loadout shows
## no added geometry and restores every original material value.

const Loadout := preload("res://scripts/loadout.gd")

var rig: Node3D
var loadout: Dictionary = {}
var parts: Dictionary = {}
var accent: StandardMaterial3D
var accent_targets: Array[StandardMaterial3D] = []
var accent_originals: Array[Dictionary] = []
var rim_targets: Array[StandardMaterial3D] = []
var rim_originals: Array[Dictionary] = []
var bolt_targets: Array[StandardMaterial3D] = []
var bolt_originals: Array[Dictionary] = []
var coilovers: Array[Dictionary] = []
var anemometer: Node3D
var vane: Node3D
var ride_height := 0.0

func setup(truck: Node3D) -> void:
	rig = truck
	name = "GarageKit"
	accent = StandardMaterial3D.new()
	accent.resource_name = "Garage accent"
	for path in ["Graphite armor", "Tailgate/Graphite armor", "Textured graphite"]:
		_remember(rig.body.get_node_or_null(path), accent_targets, accent_originals)
	for wheel in rig.wheels:
		_remember(wheel.get_node_or_null("Spin/Graphite armor"), rim_targets, rim_originals)
		_remember(wheel.get_node_or_null("Spin/Fasteners"), bolt_targets, bolt_originals)
	var stock: Dictionary = accent_originals[0] if not accent_originals.is_empty() else {"color": Color(0.145, 0.157, 0.165), "metallic": 0.56, "roughness": 0.45}
	_paint(accent, stock)

func _remember(node: Node, targets: Array[StandardMaterial3D], originals: Array[Dictionary]) -> void:
	if not node is MeshInstance3D: return
	var mat := (node as MeshInstance3D).material_override as StandardMaterial3D
	if mat == null: return
	targets.append(mat)
	originals.append({"color": mat.albedo_color, "metallic": mat.metallic, "roughness": mat.roughness})

static func _paint(mat: StandardMaterial3D, finish: Dictionary) -> void:
	mat.albedo_color = finish.color
	mat.metallic = finish.metallic
	mat.roughness = finish.roughness

func apply(next: Dictionary) -> void:
	loadout = Loadout.sanitize(next)
	# Paint accents: armor, cage and bumpers. Stock restores the original values.
	var paint := Loadout.option("accent", loadout.accent)
	for i in range(accent_targets.size()):
		_paint(accent_targets[i], accent_originals[i] if loadout.accent == "stock" else paint)
	_paint(accent, accent_originals[0] if loadout.accent == "stock" and not accent_originals.is_empty() else paint)
	# Wheels.
	var wheels := Loadout.option("wheels", loadout.wheels)
	for i in range(rim_targets.size()):
		_paint(rim_targets[i], rim_originals[i] if loadout.wheels == "stock" else {"color": wheels.rim, "metallic": wheels.rim_metallic, "roughness": wheels.rim_roughness})
	for i in range(bolt_targets.size()):
		var bolts: Color = wheels.bolts
		_paint(bolt_targets[i], bolt_originals[i] if bolts.a == 0.0 else {"color": bolts, "metallic": 0.85, "roughness": 0.3})
	# Roof equipment and bumper armor.
	for id in ["light_bar", "weather_mast", "doppler_dome"]:
		_show("roof:" + id, loadout.roof == id)
	var dish: Node3D = rig.body.get_node_or_null("RadarDish")
	if dish: dish.visible = loadout.roof != "doppler_dome"
	for id in ["bull_bar", "ram_plate", "winch"]:
		_show("armor:" + id, loadout.armor == id)
	# Suspension trim.
	var trim := Loadout.option("trim", loadout.trim)
	ride_height = float(trim.get("lift", 0.0))
	for id in ["lift_kit", "rally", "desert_runner"]:
		_show("trim:" + id, loadout.trim == id)
	step(0.0)

func _show(key: String, wanted: bool) -> void:
	if wanted and not parts.has(key): parts[key] = _build(key)
	if parts.has(key): parts[key].visible = wanted

func has_visible_parts() -> bool:
	return parts.values().any(func(n): return n.visible)

## Keeps coilovers spanning wheel and body, and spins the anemometer.
func step(_dt: float) -> void:
	for c in coilovers:
		var root: Node3D = c.root
		if not root.visible: continue
		var wheel: Node3D = c.wheel
		var top: Vector3 = rig.body.position + c.top
		var bottom := Vector3(c.x, wheel.position.y + 0.03, wheel.position.z)
		var span := top - bottom
		var node: Node3D = c.node
		node.position = bottom
		node.basis = Basis(Vector3.UP.cross(span.normalized()).normalized(), Vector3.UP.angle_to(span.normalized())) if Vector3.UP.cross(span.normalized()).length() > 0.0001 else Basis.IDENTITY
		node.scale = Vector3(1.0, span.length() / c.rest, 1.0)
	if is_instance_valid(anemometer) and anemometer.is_visible_in_tree():
		var t: float = rig.game.clock
		anemometer.rotation.y = fposmod(t * (4.0 + rig.game.speed * 0.06), TAU)
		vane.rotation.y = sin(t * 0.9) * 0.35 + rig.game.wind * 0.8

# --- Geometry -----------------------------------------------------------------

func _mat(color: Color, metallic: float = 0.3, roughness: float = 0.5, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	return m

func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _node(parent, mesh, pos, mat, rot)

func _tube(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material, sides: int = 10) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = sides
	mesh.rings = 1
	var n := _node(parent, mesh, (a + b) * 0.5, mat)
	var dir := (b - a).normalized()
	var axis := Vector3.UP.cross(dir)
	if axis.length() > 0.0001:
		n.basis = Basis(axis.normalized(), Vector3.UP.angle_to(dir))
	elif dir.y < 0.0:
		n.basis = Basis(Vector3.RIGHT, PI)
	return n

func _node(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	n.rotation = rot
	parent.add_child(n)
	return n

func _build(key: String) -> Node3D:
	var root := Node3D.new()
	root.name = key.replace(":", "_")
	root.set_meta("garage_part", key)
	var on_body := not key.begins_with("trim:")
	(rig.body if on_body else rig.model).add_child(root)
	var steel := _mat(Color(0.30, 0.32, 0.33), 0.75, 0.38)
	var black := _mat(Color(0.03, 0.035, 0.04), 0.2, 0.7)
	var lamp := _mat(Color(0.92, 0.95, 1.0), 0.0, 0.2, 2.2)
	match key:
		"roof:light_bar":
			_box(root, Vector3(0, 2.50, -0.98), Vector3(1.56, 0.13, 0.17), black)
			for i in range(10):
				_box(root, Vector3(-0.675 + i * 0.15, 2.50, -1.07), Vector3(0.11, 0.075, 0.02), lamp)
			for x in [-0.62, 0.62]:
				_box(root, Vector3(x, 2.44, -0.95), Vector3(0.05, 0.08, 0.12), accent)
		"roof:weather_mast":
			_tube(root, Vector3(0, 2.42, 0.42), Vector3(0, 3.62, 0.42), 0.028, accent)
			_box(root, Vector3(0, 2.44, 0.42), Vector3(0.22, 0.04, 0.22), accent)
			anemometer = Node3D.new()
			anemometer.position = Vector3(0, 3.66, 0.42)
			root.add_child(anemometer)
			_tube(anemometer, Vector3(0, -0.04, 0), Vector3(0, 0.05, 0), 0.03, steel)
			var cup := SphereMesh.new()
			cup.radius = 0.055
			cup.height = 0.11
			cup.radial_segments = 10
			cup.rings = 5
			var cup_mat := _mat(Color(0.86, 0.87, 0.85), 0.1, 0.4)
			for i in range(3):
				var a := i * TAU / 3.0
				var tip := Vector3(cos(a), 0.0, sin(a)) * 0.26
				_tube(anemometer, Vector3.ZERO, tip, 0.008, steel, 6)
				_node(anemometer, cup, tip, cup_mat)
			vane = Node3D.new()
			vane.position = Vector3(0, 3.40, 0.42)
			root.add_child(vane)
			_tube(vane, Vector3(0, 0, -0.18), Vector3(0, 0, 0.26), 0.01, steel, 6)
			_box(vane, Vector3(0, 0.03, 0.24), Vector3(0.012, 0.12, 0.14), _mat(Color(0.86, 0.40, 0.1), 0.1, 0.5))
			_box(vane, Vector3(0, 0, -0.2), Vector3(0.03, 0.03, 0.06), steel)
		"roof:doppler_dome":
			var dome := SphereMesh.new()
			dome.radius = 0.41
			dome.height = 0.82
			dome.radial_segments = 24
			dome.rings = 12
			_node(root, dome, Vector3(0, 3.21, -0.42), _mat(Color(0.56, 0.59, 0.58), 0.05, 0.48))
			_tube(root, Vector3(0, 2.78, -0.42), Vector3(0, 2.92, -0.42), 0.2, accent, 16)
			_box(root, Vector3(0, 3.21, -0.83), Vector3(0.16, 0.035, 0.02), _mat(Color(0.95, 0.55, 0.12), 0.0, 0.4, 1.2))
		"armor:bull_bar":
			for x in [-0.64, 0.64]:
				_tube(root, Vector3(x, 0.62, -3.10), Vector3(x, 1.42, -3.10), 0.045, accent)
				_tube(root, Vector3(x, 0.72, -3.10), Vector3(x, 0.72, -2.90), 0.035, accent)
				_tube(root, Vector3(x, 0.95, -3.10), Vector3(signf(x) * 1.02, 0.78, -2.92), 0.038, accent)
			_tube(root, Vector3(-0.64, 1.42, -3.10), Vector3(0.64, 1.42, -3.10), 0.045, accent)
			_tube(root, Vector3(-0.64, 1.08, -3.10), Vector3(0.64, 1.08, -3.10), 0.035, accent)
			for x in [-0.34, 0.34]:
				var light := _tube(root, Vector3(x, 1.52, -3.06), Vector3(x, 1.52, -3.18), 0.07, black, 14)
				light.name = "WorkLight"
				_tube(root, Vector3(x, 1.52, -3.182), Vector3(x, 1.52, -3.19), 0.058, lamp, 14)
		"armor:ram_plate":
			_box(root, Vector3(0, 0.80, -3.01), Vector3(1.72, 0.38, 0.07), steel)
			for x in [-0.72, -0.24, 0.24, 0.72]:
				for y in [0.68, 0.92]:
					_tube(root, Vector3(x, y, -3.045), Vector3(x, y, -3.07), 0.022, black, 8)
			for side in [-1.0, 1.0]:
				_box(root, Vector3(side * 0.43, 0.80, -3.05), Vector3(0.62, 0.05, 0.02), accent, Vector3(0, 0, side * 0.55))
			_box(root, Vector3(0, 0.58, -2.62), Vector3(1.32, 0.04, 0.7), steel, Vector3(-0.12, 0, 0))
		"armor:winch":
			_box(root, Vector3(0, 0.84, -2.97), Vector3(0.62, 0.22, 0.2), black)
			_tube(root, Vector3(-0.26, 0.84, -3.0), Vector3(0.26, 0.84, -3.0), 0.085, _mat(Color(0.55, 0.12, 0.07), 0.35, 0.5), 14)
			_box(root, Vector3(0, 0.84, -3.09), Vector3(0.3, 0.1, 0.03), steel)
			var hook := TorusMesh.new()
			hook.inner_radius = 0.035
			hook.outer_radius = 0.07
			hook.rings = 12
			hook.ring_segments = 8
			var red := _mat(Color(0.78, 0.1, 0.06), 0.3, 0.45)
			_node(root, hook, Vector3(0, 0.72, -3.12), steel, Vector3(0, PI * 0.5, PI * 0.5))
			for x in [-0.8, 0.8]:
				var shackle := TorusMesh.new()
				shackle.inner_radius = 0.04
				shackle.outer_radius = 0.085
				shackle.rings = 14
				shackle.ring_segments = 8
				_node(root, shackle, Vector3(x, 0.72, -3.0), red, Vector3(0, PI * 0.5, PI * 0.5))
			_box(root, Vector3(0, 0.82, 3.02), Vector3(0.14, 0.14, 0.34), black)
			_tube(root, Vector3(0, 0.89, 3.16), Vector3(0, 0.97, 3.16), 0.018, steel, 8)
			var ball := SphereMesh.new()
			ball.radius = 0.045
			ball.height = 0.09
			_node(root, ball, Vector3(0, 0.99, 3.16), steel)
		_:
			if key.begins_with("trim:"):
				_build_coilovers(root, Loadout.option("trim", key.substr(5)))
	return root

func _build_coilovers(root: Node3D, trim: Dictionary) -> void:
	var spring_mat := _mat(trim.get("spring", Color(0.8, 0.6, 0.1)), 0.35, 0.45)
	var shock_mat := _mat(Color(0.08, 0.085, 0.09), 0.5, 0.4)
	var rest := 0.62
	for wheel in rig.wheels:
		var side := signf(wheel.position.x)
		var node := Node3D.new()
		root.add_child(node)
		_tube(node, Vector3.ZERO, Vector3(0, rest, 0), 0.028, shock_mat, 8)
		for i in range(6):
			var ring := TorusMesh.new()
			ring.inner_radius = 0.052
			ring.outer_radius = 0.072
			ring.rings = 12
			ring.ring_segments = 6
			_node(node, ring, Vector3(0, 0.14 + i * 0.075, 0), spring_mat)
		if str(trim.id) == "desert_runner":
			_tube(node, Vector3(-side * 0.09, 0.30, 0), Vector3(-side * 0.09, 0.56, 0), 0.03, spring_mat, 8)
		coilovers.append({"root": root, "node": node, "rest": rest, "wheel": wheel, "x": side * 0.86, "top": Vector3(side * 0.80, 1.32, wheel.position.z)})
