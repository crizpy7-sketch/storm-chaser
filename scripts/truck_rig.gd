extends Node3D
## Solid pickup mesh; route logic owns travel, this rig owns visual articulation.
const ART := preload("res://assets/art/truck.png")
const Media := preload("res://scripts/media.gd")
const MODEL_PATH := "res://assets/models/interceptor-3d.tscn"
const WHEEL_RADIUS := .655
var game: Node2D
var world
var model: Node3D
var body: Node3D
var artwork: MeshInstance3D
var finish: ShaderMaterial
var paint_finishes: Array[ShaderMaterial] = []
var wheels: Array[Node3D] = []
var antennas: Array[Node3D] = []
var brake_materials: Array[StandardMaterial3D] = []
var beacon_materials: Array[StandardMaterial3D] = []
var current_pose := "straight"
var suspension := 0.0
var suspension_velocity := 0.0
var pitch := 0.0
var roll := 0.0
var steering_angle := 0.0
var spin_angle := 0.0
var wheel_droop := 0.0
var previous_speed := 112.0
var last_puddles := 0
var last_hits := 0
var last_landings := 0
var damage_level := 0.0
var wheel_phase := 0.0
var wheel_motion := 0.0
var wheel_blur := 0.0
var recoil := Vector3.ZERO
var recoil_velocity := Vector3.ZERO
## Mateo Garage parts and finishes (scripts/truck_kit.gd).
var kit: Node3D

func build(_source: Node3D = null) -> void:
	name="Interceptor"
	# The approved scene references its reference sheet by path; Media supplies the
	# identical GLB-embedded sheet when a trimmed copy lacks the JPEG.
	Media.ensure_truck_reference()
	model=(load(MODEL_PATH) as PackedScene).instantiate()
	add_child(model)
	body=model.get_node("SprungBody")
	finish=ShaderMaterial.new()
	finish.shader=preload("res://shaders/truck_3d_finish.gdshader")
	finish.set_shader_parameter("truck_art",ART)
	paint_finishes.append(finish)
	_apply_materials(model)
	artwork=body.get_node("Reference bodywork")
	for label in ["FrontLeftWheel","FrontRightWheel","RearLeftWheel","RearRightWheel"]:
		wheels.append(model.get_node(label))
	for label in ["RearLeftAntenna","RearRightAntenna","RoofLeftAntenna","RoofRightAntenna"]:
		antennas.append(body.get_node(label))
	kit=preload("res://scripts/truck_kit.gd").new()
	add_child(kit)
	kit.setup(self)
	reset()

## Applies a sanitized garage loadout. Cosmetic only; handling reads the setup slot.
func apply_loadout(loadout: Dictionary) -> void:
	kit.apply(loadout)
	body.position.y=suspension+kit.ride_height

func _apply_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var material: Material=node.get_active_material(0)
		if material and material.resource_name=="Original orange patina":
			node.material_override=finish
		elif material is StandardMaterial3D and material.resource_name in ["Reference bodywork","Reference fascia"]:
			var paint:=ShaderMaterial.new()
			paint.shader=finish.shader
			paint.set_shader_parameter("truck_art",material.albedo_texture)
			paint.set_shader_parameter("paint_tint",Vector3(.86,.87,.88))
			paint.set_shader_parameter("paint_roughness",material.roughness)
			paint.set_shader_parameter("paint_metallic",material.metallic)
			paint.set_shader_parameter("paint_clearcoat",.38)
			node.material_override=paint;paint_finishes.append(paint)
		elif material is StandardMaterial3D:
			var copy: StandardMaterial3D=material.duplicate()
			node.material_override=copy
			if copy.resource_name=="Brake lamps":brake_materials.append(copy)
			if copy.resource_name=="Amber beacons":beacon_materials.append(copy)
	for child in node.get_children():_apply_materials(child)

func seat_mateo(character: Node3D) -> void:
	# The approved character art and reactions sit inside real bed walls.
	character.position=Vector3(.48,.98,2.22)
	character.scale=Vector3.ONE*.76
	character.rotation=Vector3.ZERO

func reset() -> void:
	current_pose="straight"
	suspension=0.0;suspension_velocity=0.0;pitch=0.0;roll=0.0
	steering_angle=0.0;spin_angle=0.0;wheel_droop=0.0
	wheel_phase=0.0;wheel_motion=0.0;wheel_blur=0.0
	recoil=Vector3.ZERO;recoil_velocity=Vector3.ZERO
	previous_speed=game.speed
	last_hits=game.hits;last_landings=game.route.landings;last_puddles=game.puddle_hits
	body.position=Vector3(0,kit.ride_height if is_instance_valid(kit) else 0.0,0);body.rotation=Vector3.ZERO
	for wheel in wheels:
		wheel.position.y=.67;wheel.rotation=Vector3.ZERO;wheel.get_node("Spin").rotation=Vector3.ZERO
	for antenna in antennas:antenna.rotation=Vector3.ZERO
	apply_damage()

func contact_kick(normal: Vector3, severity: float) -> void:
	# The sprung body moves as one rigid mesh; the artwork is never stretched.
	var local: Vector3=basis.inverse()*normal
	recoil_velocity-=local*clampf(severity,.5,1.6)*1.3
	suspension_velocity-=.85*severity
	last_hits=game.hits

func apply_damage() -> void:
	damage_level=clampf(1.0-game.health/100.0,0.0,1.0)
	for paint in paint_finishes:
		paint.set_shader_parameter("damage",damage_level)
		paint.set_shader_parameter("clock",game.elapsed)
	for mat in brake_materials:mat.emission_energy_multiplier=.60 if game.braking else .16
	for i in range(beacon_materials.size()):
		beacon_materials[i].emission_energy_multiplier=.18+(pow(maxf(0.0,sin(game.elapsed*7.5+i*PI)),8.0)*.80 if not game.calm_fx else .12)

func step(dt: float) -> void:
	if dt<=0.0:
		apply_damage();return
	var road_speed: float=absf(game.speed)*.44704
	spin_angle=fposmod(spin_angle-road_speed/WHEEL_RADIUS*dt,TAU)
	wheel_phase=spin_angle/TAU;wheel_motion=smoothstep(0,4,road_speed)
	wheel_blur=smoothstep(12,108,road_speed)*.16
	if game.puddle_hits>last_puddles:suspension_velocity-=.48
	if game.hits>last_hits:suspension_velocity-=.68
	if game.route.landings>last_landings:suspension_velocity-=game.route.landing_severity*3.6
	last_hits=game.hits;last_landings=game.route.landings;last_puddles=game.puddle_hits
	var grounded: bool=game.route.grounded
	var road_motion: float=(sin(game.elapsed*17.0)*.008+sin(game.elapsed*29.0)*.004)*game.speed/180.0*(1.0+game.route.dirt*1.4) if grounded else .025
	var remaining:=dt
	while remaining>.000001:
		var h:=minf(remaining,1.0/120.0);remaining-=h
		recoil_velocity+=(-recoil*105.0-recoil_velocity*13.0)*h
		recoil+=recoil_velocity*h
		recoil=recoil.clamp(Vector3(-.10,-.03,-.13),Vector3(.10,.03,.13))
		suspension_velocity+=((road_motion-suspension)*74.0-suspension_velocity*9.5)*h
		suspension+=suspension_velocity*h
		if suspension<-.26:suspension=-.26;suspension_velocity=maxf(0,suspension_velocity)
		if suspension>.13:suspension=.13;suspension_velocity=minf(0,suspension_velocity)
	pitch=lerpf(pitch,clampf(game.powertrain.acceleration*.00065,-.045,.035),1.0-exp(-dt*5.0))
	# The chassis leans as a rigid object. Wheels remain independently planted.
	var target_roll: float=clampf(game.steer*.024+game.glide_velocity*.007,-.045,.045) if grounded else 0.0
	roll=lerpf(roll,target_roll,1.0-exp(-dt*4.0))
	body.position=recoil+Vector3(0,suspension+kit.ride_height,0);body.rotation=Vector3(pitch,0,roll)
	var speed_steer: float=lerpf(.43,.22,clampf(game.speed/200.0,0,1))
	var desired_steer: float=clampf(-game.steer*speed_steer+game.rear_slip*.12,-.48,.48)
	steering_angle=lerpf(steering_angle,desired_steer,1.0-exp(-dt*8.0))
	wheel_droop=lerpf(wheel_droop,0.0 if grounded else -.13,1.0-exp(-dt*7.0))
	for i in range(wheels.size()):
		wheels[i].rotation.y=steering_angle if i<2 else 0.0
		wheels[i].position.y=.67+wheel_droop
		wheels[i].get_node("Spin").rotation.x=spin_angle
	for i in range(antennas.size()):
		antennas[i].rotation.z=sin(game.elapsed*6.5+i)*.012+game.wind*.027
		antennas[i].rotation.x=sin(game.elapsed*5.1+i)*.006
	kit.step(dt)
	apply_damage()
