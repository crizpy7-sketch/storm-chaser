extends Node3D
# Continuous ground-to-funnel trajectories; scene-time only, so pauses freeze them.
var game
var world
var pieces: Array[Node3D] = []
var dust: Array[MeshInstance3D] = []
var last_time := 0.0
func build() -> void:
	for i in range(24):
		var item := Node3D.new()
		add_child(item)
		if i % 12 == 0:
			var semi: Node3D = world.semi_template.duplicate()
			semi.scale = Vector3.ONE * 0.85
			item.add_child(semi)
		elif i % 8 == 0:
			var cow := Sprite3D.new()
			cow.texture = world.COW; cow.pixel_size = 0.004
			cow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			cow.modulate = Color(0.65,0.7,0.73)
			item.add_child(cow)
		elif i % 3 == 0:
			world.box(item,Vector3.ZERO,Vector3(5.2,0.18,3.0),world.mat_silver)
			for ridge in range(5): world.box(item,Vector3(-2.2+ridge*1.1,0.12,0),Vector3(.10,.12,3),world.mat_steel)
		else:
			world.box(item,Vector3.ZERO,Vector3(0.22,0.26,4.0+i%4),world.mat_wood)
		pieces.append(item)
	var dust_shader := preload("res://shaders/storm_dust.gdshader")
	for i in range(12):
		var quad:=QuadMesh.new();quad.size=Vector2(22,13)
		var mat:=ShaderMaterial.new();mat.shader=dust_shader
		mat.set_shader_parameter("seed",i*1.7)
		var puff:=MeshInstance3D.new();puff.mesh=quad;puff.material_override=mat
		puff.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(puff);dust.append(puff)
func update_view() -> void:
	var time: float = game.elapsed + (game.finale.age if game.mode == game.Mode.VORTEX else 0.0)
	last_time=time
	var center: Vector3 = world.tornado.position-Vector3(0,70,0)
	for i in range(pieces.size()):
		var item:=pieces[i]
		item.visible = not game.light_graphics or i%2==0
		var u:=fposmod(time*0.115+i/24.0,1.0)
		var lift:=smoothstep(0.2,0.92,u)
		var angle:=i*2.399+u*u*12.0
		var radius:=lerpf(62.0,19.0,smoothstep(0,0.6,u))+lift*8.0
		var height:=0.7+pow(lift,1.6)*100.0
		var shader_time: float = world.storm_material.get_shader_parameter("clock")
		var h:=clampf(height/147.0,0.0,1.0)
		var bend: float=(sin(shader_time*.22)*9.0+sin(shader_time*.47+h*3.0)*4.0)*pow(h,1.5)
		item.position=center+Vector3(sin(angle)*radius,height,cos(angle)*radius)+Vector3(bend,0,0).rotated(Vector3.UP,world.tornado.rotation.y)
		item.rotation=Vector3(u*9.0,u*13.0,i+u*7.0)*smoothstep(.16,.4,u)
		var fade:=smoothstep(0,.06,u)*(1.0-smoothstep(.92,1.0,u))
		# Decorative funnel pieces cannot make fake close passes through the truck.
		fade*=smoothstep(18.0,32.0,item.position.distance_to(world.truck.position))
		item.scale=Vector3.ONE*fade
	for i in range(dust.size()):
		var puff:=dust[i]
		puff.visible=not game.light_graphics or i%2==0
		var angle:=time*.7+i*TAU/12.0
		var radius:=19.0+sin(time+i)*5.0
		puff.position=center+Vector3(sin(angle)*radius,4.5+sin(angle*2+i)*2,cos(angle)*radius)
		puff.look_at(world.camera.global_position,Vector3.UP)
		puff.material_override.set_shader_parameter("clock",time)
