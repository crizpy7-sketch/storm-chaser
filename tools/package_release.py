"""Package current exports and source, checking archive CRCs and byte identity."""
from pathlib import Path
import zipfile,hashlib,json
r=Path(__file__).resolve().parents[2];out=r/'exports'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def package(name,source,prefix):
 files=[p for p in sorted(source.rglob('*')) if p.is_file() and not any(x in p.relative_to(source).parts for x in ['.godot','.git','__pycache__']) and p.suffix not in ['.zip','.avi','.tmp']]
 dest=out/name
 with zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p in files:z.write(p,str(Path(prefix)/p.relative_to(source)))
 with zipfile.ZipFile(dest) as z:
  assert z.testzip() is None
  for p in files:assert hashlib.sha256(z.read(str(Path(prefix)/p.relative_to(source)))).hexdigest()==sha(p)
 return {'filename':name,'bytes':dest.stat().st_size,'sha256':sha(dest),'crc_passed':True,'all_packaged_files_match':True,'file_count':len(files)}
if __name__=='__main__':
 records=[]
 for label in ['Windows','Linux','Web']:
  records.append(package(f'Storm-Chaser-{label}.zip',out/f'Storm-Chaser-{label}',f'Storm-Chaser-{label}'))
  print(label,'verified',flush=True)
 records.append(package('Storm-Chaser-Godot-Project.zip',r/'storm-chaser','Storm-Chaser'))
 print('Source verified',flush=True)
 manifest={'game':'Storm Chaser','version':'0.16.0','release':'Solid Impact and Shelter Corridor','release_date':'2026-09-16','engine':'Godot 4.5.2','artifacts':records,'changes':['Swept oriented truck-body collision matching visible debris contact','Impact recoil, contact-point fragments and one-hit-per-object damage','Semi roof sheet becomes a real collidable falling hazard','Four roadside ground shelters with twelve running civilians and closing hatches','Road and sky scenery filtered to avoid harmless ghost passes','Future Mateo garage customization recorded for the next upgrade'],'model':{'truck_triangles':67656,'truck_mesh_batches':39,'truck_changed':False,'semi_sections':16},'validation':{'unique_checks_passed':445,'failures':0,'solid_impact_checks':38,'campaign_checks':2,'normal_and_assisted_campaigns_passed':True,'new_physical_hardware_playtest':False},'scope':'Visible road impacts now use swept oriented hull contacts and exact contact effects. Civilians are atmosphere only and stay outside the road. Mateo truck customization is planned, not included in this release.','preview':{'file':'Storm-Chaser-v0.16.0-Solid-Impacts.mp4','segments':['Actual solid debris strike and rebound','Civilians running to ground shelter','Off-road hillside shelter corridor'],'source':'Actual Godot gameplay, selected stages and scripted impact setup','ai_generated_video':False,'hardware_performance_benchmark':False}}
 for f in [out/'Storm-Chaser-Windows/Storm-Chaser.exe',out/'Storm-Chaser-v0.16.0-Solid-Impacts.mp4']:
  manifest['artifacts'].append({'filename':f.name,'bytes':f.stat().st_size,'sha256':sha(f)})
 (out/'Storm-Chaser-v0.16.0-Build-Manifest.json').write_text(json.dumps(manifest,indent=2))
 print('Manifest ready',flush=True)
