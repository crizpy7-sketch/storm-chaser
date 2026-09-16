extends Node3D

var game: Node2D
var world: Node2D
var pool: Array[Dictionary] = []
var cursor := 0
var mist_timer := 0.0
var lens_water: ColorRect
var lens_material: ShaderMaterial
var wetness := 0.0
var drift_timer := 0.0
var mud_lens: ColorRect
var mud_material: ShaderMaterial
var mud_age := 99.0
var mud_hits := 0
var mud_power := 0.0

func _ready() -> void:
	for i in range(32):
		var quad := QuadMesh.new()
		quad.size=Vector2.ONE
		var mat := ShaderMaterial.new()
		mat.shader=preload("res://shaders/water_plume.gdshader")
		mat.set_shader_parameter("seed",i*2.399)
		var n: MeshInstance3D=world.mesh_node(self,quad,Vector3.ZERO,mat)
		n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.visible=false
		pool.append({"node":n,"mat":mat,"age":10.0,"life":1.0,"velocity":Vector3.ZERO,"power":0.0,"sheet":false})
	lens_water=ColorRect.new()
	lens_water.size=Vector2(1280,720)
	lens_water.mouse_filter=Control.MOUSE_FILTER_IGNORE
	lens_water.z_index=12
	lens_material=ShaderMaterial.new()
	lens_material.shader=preload("res://shaders/lens_water.gdshader")
	lens_water.material=lens_material
	game.add_child(lens_water)
	mud_lens=ColorRect.new()
	mud_lens.size=Vector2(1280,720)
	mud_lens.mouse_filter=Control.MOUSE_FILTER_IGNORE
	mud_lens.z_index=13
	mud_material=ShaderMaterial.new()
	mud_material.shader=preload("res://shaders/lens_mud.gdshader")
	mud_material.set_shader_parameter("splats",PackedVector3Array([
		Vector3(.16,.48,.19),Vector3(.87,.51,.18),Vector3(.29,.25,.078),Vector3(.71,.27,.063),
		Vector3(.26,.73,.090),Vector3(.78,.75,.098),Vector3(.39,.34,.030),Vector3(.66,.41,.032),
		Vector3(.34,.57,.034),Vector3(.74,.60,.042),Vector3(.12,.29,.040),Vector3(.92,.28,.032)]))
	mud_lens.material=mud_material
	mud_lens.hide()
	game.add_child(mud_lens)

func emit_water(pos: Vector3, velocity: Vector3, power: float, sheet: bool) -> void:
	var p: Dictionary=pool[cursor]
	cursor=(cursor+1)%pool.size()
	p.node.position=pos
	p.node.visible=true
	p.age=0.0; p.life=0.88 if sheet else 0.67
	p.velocity=velocity; p.power=power; p.sheet=sheet
	p.mat.set_shader_parameter("sheet",1.0 if sheet else 0.0)
	p.mat.set_shader_parameter("dust",game.route.dirt)

func splash(intensity: float) -> void:
	wetness=0.5 if game.calm_fx else 1.0
	if game.route.dirt>0.5: mud_screen_splash(intensity)
	for side in [-1.0,1.0]:
		for j in range(3 if game.light_graphics else 5):
			var pos: Vector3=world.truck.position+Vector3(side*1.19,0.27,0.5+j*0.22).rotated(Vector3.UP,world.truck.rotation.y)
			var v:=Vector3(side*(2.0+j*0.4)+game.glide_velocity*3,1.7+intensity*1.7-j*0.19,3.4+j*0.45)
			emit_water(pos,v,intensity*(0.8+j*0.05),true)

func step(dt: float) -> void:
	if game.mode!=game.Mode.RUNNING:
		mud_lens.hide();lens_water.hide();return
	wetness=maxf(0.0,wetness-dt*0.75)
	lens_material.set_shader_parameter("amount",wetness)
	lens_material.set_shader_parameter("clock",game.elapsed)
	lens_water.visible=wetness>0 and game.mode==game.Mode.RUNNING
	mud_age+=dt
	mud_material.set_shader_parameter("age",mud_age)
	mud_material.set_shader_parameter("calm",game.calm_fx)
	mud_lens.visible=mud_age<5.7
	for p in pool:
		p.age+=dt
		var n: MeshInstance3D=p.node
		n.visible=p.age<p.life and n.position.z<8.0
		if not n.visible: continue
		var u: float=p.age/p.life
		n.position+=Vector3(p.velocity)*dt
		p.velocity.y-=dt*(5.8 if p.sheet else 1.3)
		var w: float=(0.8+u*3.1)*p.power
		var h: float=(0.42+u*2.0)*p.power
		n.scale=Vector3(w,h,1)
		n.look_at(world.camera.global_position,Vector3.UP,true)
		p.mat.set_shader_parameter("age",p.age)
		p.mat.set_shader_parameter("opacity",(0.34 if p.sheet else 0.12)*(1.0-smoothstep(0.25,1.0,u)))
	drift_timer-=dt
	if game.route.shortcut_slide>0.20 and game.route.grounded and drift_timer<=0.0:
		drift_timer=0.16 if game.light_graphics or game.calm_fx else 0.10
		for side in [-1.0,1.0]:
			var point: Vector3=world.truck.position+Vector3(side*1.15,0.18,1.8).rotated(Vector3.UP,world.truck.rotation.y)
			var power: float=game.route.shortcut_slide
			emit_water(point,Vector3(side*(1.6+power)-power*2.4,1.0+power*0.6,5.5),0.70+power*0.65,true)
	mist_timer-=dt
	if mist_timer<=0 and game.route.grounded:
		mist_timer=0.12 if game.light_graphics or game.calm_fx else 0.075
		for side in [-1.0,1.0]:
			var point: Vector3=world.truck.position+Vector3(side*1.15,0.18,2.0).rotated(Vector3.UP,world.truck.rotation.y)
			emit_water(point,Vector3(side*0.4+game.rear_slip,0.25,game.speed*0.027),0.55+game.speed/420.0,false)

func landing_burst(power: float) -> void:
	for side in [-1.0,1.0]:
		for j in range(3):
			var point: Vector3=world.road_point(0,game.player_x)+Vector3(side*1.15,0.15,1.0+j*0.4)
			emit_water(point,Vector3(side*(2.0+j*.5),1.4,4.0+j),0.9+power,false)

func drift_burst() -> void:
	mud_screen_splash(1.0)
	for side in [-1.0,1.0]:
		for j in range(2 if game.light_graphics or game.calm_fx else 4):
			var point: Vector3=world.truck.position+Vector3(side*1.15,0.20,1.2+j*0.25).rotated(Vector3.UP,world.truck.rotation.y)
			emit_water(point,Vector3(side*(2.7+j*.4)-1.5,1.5+j*.2,4.5+j*.4),1.05+j*.1,true)

func mud_screen_splash(power: float) -> void:
	# Let each coat drain completely before another puddle can repaint the lens.
	if not game.route.grounded or game.route.dirt<=0.5 or mud_age<6.4:return
	mud_age=0.0;mud_hits+=1;mud_power=clampf(power,0.25,1.0)
	mud_material.set_shader_parameter("age",0.0)
	mud_material.set_shader_parameter("power",mud_power)
	mud_material.set_shader_parameter("seed",float(mud_hits)*2.39996)
	mud_material.set_shader_parameter("calm",game.calm_fx)
	mud_lens.visible=game.mode==game.Mode.RUNNING

func reset() -> void:
	wetness=0.0; mist_timer=0.0;drift_timer=0.0;mud_age=99.0;mud_hits=0;mud_power=0.0
	for p in pool: p.age=10.0; p.node.visible=false
	if is_instance_valid(lens_water): lens_water.hide()
	if is_instance_valid(mud_lens): mud_lens.hide()

func _exit_tree() -> void:
	if is_instance_valid(lens_water): lens_water.queue_free()
	if is_instance_valid(mud_lens): mud_lens.queue_free()
