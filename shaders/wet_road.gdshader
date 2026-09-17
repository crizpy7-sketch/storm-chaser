shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform sampler2D storm_sky : source_color;
uniform sampler2D clay_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D asphalt_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float travel=0.0;
uniform float flash=0.0;
uniform float clock=0.0;
varying vec3 world_point;
float hash21(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise2(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float x=(UV.x-.5)*14.0;
 float z=UV.y-travel;
 float grain=noise2(vec2(x*40.0,z*18.0));
 float wet=noise2(vec2(x*2.3,z*.16));
 vec3 sky=texture(storm_sky,vec2(clamp(.5+x*.047,0.0,1.0),clamp(.84-abs(world_point.z)*.009+noise2(vec2(x*9.,z*.7))*.08,.03,.9))).rgb;
 vec3 pave=texture(asphalt_texture,vec2(x*.22,z*.16)).rgb;
 vec3 asphalt=mix(vec3(.020,.033,.039)*(0.7+grain*.6),pave*vec3(.55,.68,.72),0.78);
 vec3 col=mix(asphalt,sky*.22,smoothstep(.35,.72,wet)*.55);
 float edge=1.0-smoothstep(.055,.09,abs(abs(x)-6.45));
 float dash=(1.0-smoothstep(.035,.075,abs(abs(x)-3.2)))*(1.0-step(4.5,mod(z,8.0)));
 float yellow=1.0-smoothstep(.035,.065,abs(abs(x)-.13));
 float worn=.65+.35*noise2(vec2(x*17.,z*1.5));
 col=mix(col,vec3(.46,.51,.47),max(edge,dash)*worn);
 col=mix(col,vec3(.68,.42,.075),yellow*worn);
 float dirt=COLOR.r;
 float mx=(UV.x-.5)*11.0;
 float detail=1.0-smoothstep(30.0,130.0,abs(world_point.z));
 float clay=noise2(vec2(mx*1.2,z*.20));
 float clumps=mix(.5,noise2(vec2(mx*19.0,z*5.0)),detail);
 float rut_distance=abs(abs(mx-sin(z*.035)*.18)-1.22);
 float track=1.0-smoothstep(.12,.48,rut_distance);
 float ridges=(1.0-smoothstep(.03,.13,abs(rut_distance-.48)))*detail;
 float pooled=smoothstep(.47,.73,noise2(vec2(mx*3.3,z*.11)))*track;
 pooled=max(pooled,smoothstep(.64,.79,noise2(vec2(mx*.7,z*.13)))*(1.0-smoothstep(2.0,4.5,abs(mx)))*.8);
 vec3 earth=mix(vec3(.32,.22,.15),vec3(.49,.35,.24),clay)*(.88+clumps*.22);
 earth=mix(earth,texture(clay_texture,vec2(mx/7.0,z/9.0)).rgb*1.28,0.72);
 earth=mix(earth,vec3(.28,.19,.105),track*.3);
 earth+=vec3(.10,.080,.050)*ridges;
 earth=mix(earth,sky*.28+vec3(.12,.10,.07),pooled*.7);
 col=mix(col,earth,dirt);
 float sparkle=pow(max(0.0,sin(z*11.0+clock*7.4)*noise2(vec2(x*36.0,z*20.0+clock))),18.0)*smoothstep(.3,.8,wet);
 ALBEDO=col*(1.0+flash*0.7);
 EMISSION=mix(col*(0.012+flash*0.18)+sky*smoothstep(.60,.84,wet)*.02,
              earth*(0.02+flash*0.12)+sky*pooled*.015,dirt);
 EMISSION+=vec3(0.09,0.11,0.13)*sparkle*(0.5+flash);
 float hx=noise2(vec2(x*8.0+0.05,z*4.0))-noise2(vec2(x*8.0-0.05,z*4.0));
 float hz=noise2(vec2(x*8.0,z*4.0+0.05))-noise2(vec2(x*8.0,z*4.0-0.05));
 NORMAL=normalize(vec3(-hx*(1.0+track*1.8),1.0,-hz*(1.0+track*1.8)));
 ROUGHNESS=mix(mix(.38,.08,smoothstep(.3,.8,wet)),mix(.78,.14,pooled),dirt);
 METALLIC=mix(.22,.03,dirt);
 SPECULAR=.8;
}
