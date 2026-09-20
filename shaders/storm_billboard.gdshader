shader_type spatial;
render_mode unshaded,cull_disabled,fog_disabled,depth_prepass_alpha;
uniform sampler2D storm_texture;
uniform float clock=0.0;
uniform float brightness=0.8;
void vertex(){
 float h=clamp(1.0-UV.y,0.0,1.0);
 float sway=(sin(clock*.22)*9.0+sin(clock*.47+h*3.0)*4.0)*pow(h,1.5);
 VERTEX.x+=sway;
 VERTEX.z+=sin(clock*.31+h*2.2)*pow(h,1.6)*3.5;
}
void fragment(){
 vec2 uv=UV;
 uv.x+=(sin(uv.y*11.0-clock*2.1)*.012+sin(uv.y*23.0+clock*1.6)*.004)*sin(uv.y*3.14159);
 uv.x+=sin(uv.y*6.5+clock*0.9)*.018*(1.0-UV.y);
 vec4 col=texture(storm_texture,uv);
 // The cinematic texture is magenta-keyed. Bright magenta is background,
 // never an opaque pixel, even though its luminance is above zero.
 float key_alpha=1.0-clamp(min(col.r,col.b)-col.g,0.0,1.0);
 float alpha=key_alpha*col.a;
 if(alpha<.05){discard;}
 col.rgb=clamp((col.rgb-vec3(1,0,1)*(1.0-key_alpha))/max(key_alpha,.05),vec3(0),vec3(1));
 col.rgb=mix(col.rgb,vec3(min(col.r,col.g*1.35+.015),col.g,min(col.b,col.g*1.05+.01)),1.0-smoothstep(.85,.98,alpha));
 col.b=min(col.b,col.g);
 col.r=min(col.r,col.g*1.25+.01);
 if(!OUTPUT_IS_SRGB){col.rgb=mix(col.rgb/12.92,pow((col.rgb+vec3(.055))/1.055,vec3(2.4)),step(vec3(.04045),col.rgb));}
 col.a=alpha;
 float rolling=.96+.04*sin(uv.y*32.0-clock*3.0+uv.x*8.0);
 float foot=smoothstep(0.82,1.0,UV.y);
 col.rgb=mix(col.rgb,col.rgb*vec3(1.15,1.05,0.85)+vec3(0.04,0.03,0.02),foot*0.55);
 ALBEDO=col.rgb*rolling*brightness;
 ALPHA=col.a*smoothstep(0.0,.035,UV.y);
}
