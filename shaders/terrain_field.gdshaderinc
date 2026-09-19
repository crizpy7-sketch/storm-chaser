// Shared hill elevation field (stages 5-7): the same road samples and formula as
// world3d.gd _field_height(). Used by ground.gdshader and field_grass.gdshader.
uniform bool terrain_field = false;
uniform vec3 road_samples[38];
uniform int road_sample_count = 0;
uniform vec2 field_origin = vec2(0.0);
uniform float field_heading = 0.0;
uniform float field_base = 0.0;
uniform bool field_junction = false;
uniform vec4 field_bounds = vec4(0.0);
float field_height(vec2 p){
 float c=cos(field_heading),s=sin(field_heading);
 float cx=field_origin.x+c*p.x-s*p.y;
 float cy=field_origin.y+s*p.x+c*p.y;
 float flat_junction=field_junction?1.0-smoothstep(80.0,140.0,cx):0.0;
 float rolling=-9.0+sin(cx*.024)*5.0+sin(cy*.021+cx*.012)*6.0+sin(cx*.061+cy*.038)*1.8;
 float blend=1.0;
 float elevation=-22.0-field_base;
 if(p.x>field_bounds.x-95.0&&p.x<field_bounds.y+95.0&&p.y>field_bounds.z-95.0&&p.y<field_bounds.w+95.0){
  float closest=1e7;
  for(int i=0;i<road_sample_count-1;i++){
   vec3 a=road_samples[i];vec3 b=road_samples[i+1];
   vec2 d=b.xz-a.xz;
   float along=clamp(dot(p-a.xz,d)/max(dot(d,d),.01),0.0,1.0);
   vec2 e=p-(a.xz+d*along);
   float dist=dot(e,e);
   if(dist<closest){closest=dist;elevation=mix(a.y,b.y,along)-.85;}
  }
  blend=smoothstep(14.0,95.0,sqrt(closest));
 }
 float field=mix(elevation,rolling-field_base,blend);
 return mix(field,-.055-field_base,flat_junction);
}
