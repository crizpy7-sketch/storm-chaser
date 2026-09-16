shader_type spatial;
uniform sampler2D material_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(.5,.4,.3,1.0);
uniform vec2 tile = vec2(0.0);
uniform float metal = 0.0;
uniform float scale_uv = .35;
varying vec3 local_point;
varying vec3 local_normal;
void vertex() { local_point=VERTEX; local_normal=NORMAL; }
vec3 sample_face(vec2 uv) { return texture(material_atlas,tile+vec2(.01)+fract(uv*scale_uv)*.48).rgb; }
void fragment() {
 vec3 w=pow(abs(normalize(local_normal)),vec3(5.0)); w/=max(.001,w.x+w.y+w.z);
 vec3 tex=sample_face(local_point.zy)*w.x+sample_face(local_point.xz)*w.y+sample_face(local_point.xy)*w.z;
 float luminance=dot(tex,vec3(.3,.5,.2));
 ALBEDO=tint.rgb*(.46+luminance*1.15);
 ROUGHNESS=mix(.92,.62,metal); METALLIC=metal;
}
