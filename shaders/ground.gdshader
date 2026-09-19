shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform sampler2D clay_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 route_origin=vec2(0.0);
uniform float route_heading=0.0;
uniform float travel=0.0;
uniform float dirt=0.0;
uniform sampler2D field_texture : source_color;
uniform float flash=0.0;
uniform float clock=0.0;
// Hill terrain grid (stages 5-7). The grid mesh is static; its heights and
// smooth normals come from the shared field in terrain_field.gdshaderinc,
// instead of rebuilding 1,360 points on the CPU every frame.
#include "res://shaders/terrain_field.gdshaderinc"
varying vec3 world_point;
float hash21(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float n(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);}
vec3 face(vec3 a,vec3 b,vec3 c){return normalize(cross(a-c,a-b));}
void vertex(){
 if(terrain_field){
  vec2 p=VERTEX.xz;
  float west=UV.x,east=UV.y;
  bool has_s=UV2.x>.5,has_n=UV2.y>.5;
  vec3 v=vec3(p.x,field_height(p),p.y);
  vec3 e=v,w=v,nn=v,ss=v,nw=v,se=v;
  if(east>0.0)e=vec3(p.x+east,field_height(vec2(p.x+east,p.y)),p.y);
  if(west>0.0)w=vec3(p.x-west,field_height(vec2(p.x-west,p.y)),p.y);
  if(has_n)nn=vec3(p.x,field_height(vec2(p.x,p.y-6.0)),p.y-6.0);
  if(has_s)ss=vec3(p.x,field_height(vec2(p.x,p.y+6.0)),p.y+6.0);
  if(west>0.0&&has_n)nw=vec3(p.x-west,field_height(vec2(p.x-west,p.y-6.0)),p.y-6.0);
  if(east>0.0&&has_s)se=vec3(p.x+east,field_height(vec2(p.x+east,p.y+6.0)),p.y+6.0);
  vec3 sum=vec3(0.0);
  if(east>0.0&&has_n)sum+=face(v,e,nn);
  if(west>0.0&&has_n){sum+=face(w,v,nw);sum+=face(v,nn,nw);}
  if(east>0.0&&has_s){sum+=face(ss,se,v);sum+=face(se,e,v);}
  if(west>0.0&&has_s)sum+=face(ss,v,w);
  VERTEX.y=v.y;
  NORMAL=length(sum)>0.0?normalize(sum):vec3(0.0,1.0,0.0);
 }
 world_point=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
}
void fragment(){
 vec2 p=route_origin+vec2(cos(route_heading),sin(route_heading))*world_point.x+vec2(-sin(route_heading),cos(route_heading))*world_point.z;
 float patch=n(p*.14)*.55+n(p*.73)*.15;
 vec2 uv=vec2(fract(p.x*.009),.885+fract(p.y*.012)*.108);
 vec3 field=texture(field_texture,uv).rgb;
 vec3 soil=mix(vec3(.20,.16,.106),vec3(.34,.27,.177),clamp(patch*1.6,0.0,1.0));
 float grass=n(p*.8)*.1+n(p*3.)*.04;
 vec3 clay=texture(clay_texture,p/8.0).rgb;
 vec3 grass_tex=texture(grass_texture,p/6.5).rgb;
 vec3 scrub=mix(vec3(.10,.115,.065),vec3(.20,.18,.12),n(p*.023));
 vec3 prairie=mix(clay*.55,grass_tex*1.05,.62+.14*n(p*.038));
 prairie=mix(prairie,scrub*1.08,.18);
 float swath=smoothstep(.48,.70,n(vec2(p.x*.043,p.y*.17)));
 float stubble=pow(n(vec2(p.x*6.0,p.y*.85)),3.0);
 vec3 field_soil=mix(soil*.77,vec3(.18,.20,.115),n(p*.028));
 field_soil=mix(field_soil,vec3(.28,.25,.155),swath*.35+stubble*.18);
 field_soil=mix(field_soil,grass_tex*.72,.28);
 vec3 col=mix(field_soil,prairie,dirt);
 float bump=n(p*2.4)*0.45+n(p*7.1)*0.22+n(p*18.0)*0.08;
 float hx=n(p*2.4+vec2(.08,0.0))-n(p*2.4-vec2(.08,0.0));
 float hz=n(p*2.4+vec2(0.0,.08))-n(p*2.4-vec2(0.0,.08));
 NORMAL=normalize(NORMAL+vec3(-hx,0.35,-hz)*0.55);
 float wet=smoothstep(.42,.78,n(p*.09)+n(p*.4)*.25);
 col=mix(col,col*vec3(.78,.84,.80),wet*.28);
 float sparkle=pow(max(0.0,sin(p.x*9.0+clock*6.2)*n(p*14.0+clock)),20.0)*wet;
 ALBEDO=col*(1.0+flash*0.55);
 EMISSION=col*(0.008+flash*0.22+wet*0.006)+vec3(0.07,0.09,0.10)*sparkle;
 ROUGHNESS=mix(.92,.28,wet*dirt)+grass*.18;
 METALLIC=0.0;
 SPECULAR=.45+wet*.25;
}
