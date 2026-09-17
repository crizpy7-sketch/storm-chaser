shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,shadows_disabled,fog_disabled;
uniform float clock=0.0;
uniform float seed=0.0;
uniform float opacity=0.45;
uniform sampler2D dust_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec2 p=UV*2.0-1.0;
 float ang=atan(p.y,p.x)+clock*.35;
 float rad=length(p);
 vec2 swirl=vec2(cos(ang),sin(ang))*rad;
 float grain=noise(swirl*3.4+vec2(clock*.25+seed,-clock*.2));
 float tex=texture(dust_texture,swirl*0.7+vec2(clock*.05,-clock*.04)).r;
 float shape=1.0-smoothstep(.18,1.0,rad+grain*.16);
 ALBEDO=mix(vec3(.17,.14,.11),vec3(.40,.32,.22),grain*.55+tex*.45);
 ALPHA=shape*opacity*(.28+grain*.24+tex*.18);
}
