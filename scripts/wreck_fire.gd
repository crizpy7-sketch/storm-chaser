extends Node3D
# A bounded, scene-clock effect. No TIME uniform or free-running particle clock.
var plume: MeshInstance3D
var glow: OmniLight3D
var material: ShaderMaterial
var embers: MultiMesh
var seed := 0.0
func build(size: float, variation: float, with_light: bool = true) -> void:
	seed=variation
	material=ShaderMaterial.new();material.shader=preload("res://shaders/wreck_fire.gdshader")
	material.set_shader_parameter("seed",seed)
	var quad:=QuadMesh.new();quad.size=Vector2(7.0,12.0)*size
	plume=MeshInstance3D.new();plume.mesh=quad;plume.material_override=material
	plume.position.y=6.0*size;plume.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(plume)
	var spark:=BoxMesh.new();spark.size=Vector3(.04,.13,.04)*size
	var spark_mat:=StandardMaterial3D.new();spark_mat.albedo_color=Color("ff9038")
	spark_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.emission_enabled=true;spark_mat.emission=Color("ff6518");spark_mat.emission_energy_multiplier=2
	embers=MultiMesh.new();embers.transform_format=MultiMesh.TRANSFORM_3D
	embers.mesh=spark;embers.instance_count=10
	var batch:=MultiMeshInstance3D.new();batch.multimesh=embers;batch.material_override=spark_mat
	batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(batch)
	if with_light:
		glow=OmniLight3D.new();glow.light_color=Color("ff853b");glow.omni_range=9.0*size
		glow.position.y=1.2*size;glow.shadow_enabled=false;add_child(glow)
func update_view(time: float, camera: Camera3D, light_graphics: bool, calm: bool, amount: float = 1.0) -> void:
	material.set_shader_parameter("clock",time)
	material.set_shader_parameter("calm",1.0 if calm else 0.0)
	material.set_shader_parameter("strength",amount)
	if plume.global_position.distance_squared_to(camera.global_position)>.01:
		plume.look_at(camera.global_position,Vector3.UP)
	embers.visible_instance_count=0 if light_graphics else 10
	for i in range(10):
		var u:=fposmod(time*.37+i*.137+seed,1.0)
		var p:=Vector3(sin(i*2.39)*.65+u*u*3.5,u*5.2,cos(i*2.39)*.5)
		embers.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*amount*(1.0-u)),p))
	if is_instance_valid(glow):
		glow.visible=not light_graphics and amount>.01
		glow.light_energy=(1.2+sin(time*8.0+seed)*(.08 if calm else .2))*amount
