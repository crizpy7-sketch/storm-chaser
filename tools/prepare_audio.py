"""Prepare downloaded ElevenLabs takes for Godot; originals remain untouched."""
import collections
import json
import pathlib
import subprocess
import numpy as np
import wave

workspace = pathlib.Path(__file__).resolve().parents[2]
data = json.loads((workspace / 'audio-production/takes.json').read_text())
output = workspace / 'storm-chaser/assets/audio'
groups = collections.defaultdict(list)
for item in data:
    groups[item['name']].append(item)

def decode(item):
    raw = subprocess.check_output(['ffmpeg','-v','error','-i',str(workspace / item['path']),'-f','f32le','-ar','44100','-ac','2','pipe:1'])
    samples = np.frombuffer(raw, dtype='<f4').reshape(-1, 2).copy()
    if not len(samples) or not np.isfinite(samples).all() or np.max(np.abs(samples)) < 0.001:
        raise ValueError('Empty or invalid audio: ' + item['path'])
    return samples

def write(path, samples):
    peak = float(np.max(np.abs(samples)))
    samples *= 0.79 / max(peak, 0.001)
    with wave.open(str(path), 'wb') as w:
        w.setparams((2, 2, 44100, 0, 'NONE', 'not compressed'))
        w.writeframes((np.clip(samples,-1,1)*32767).astype('<i2').tobytes())

manifest = {'provider':'ElevenLabs','effects_model':'eleven_text_to_sound_v2','music_model':'eleven_music_v2','processing':'44.1 kHz stereo PCM; -2 dBFS peak; loop seam crossfade; trimmed one-shot leading silence. Original MP3 takes preserved separately.','sounds':{}}
for name, items in groups.items():
    waves = [(item, decode(item)) for item in items]
    if items[0]['loop']:
        # Prefer the most stable loop, then crossfade the boundary to prevent clicks.
        if name != 'chase':
            waves.sort(key=lambda pair: float(np.std([np.sqrt(np.mean(c*c)) for c in np.array_split(pair[1],12)])))
        waves = waves[:1]
    records=[]
    for index, (item, samples) in enumerate(waves):
        if item['loop']:
            n = min(int(44100 * (0.25 if name == 'chase' else 0.055)), len(samples)//4)
            t = np.linspace(0,1,n)[:,None]
            samples[:n] = samples[-n:]*(1-t) + samples[:n]*t
            samples = samples[:-n]
        else:
            active = np.flatnonzero(np.max(np.abs(samples),axis=1) > np.max(np.abs(samples)) * 0.012)
            if len(active): samples=samples[max(0,int(active[0])-220):]
            n = min(441, len(samples)//4)
            samples[:44] *= np.linspace(0,1,44)[:,None]
            samples[-n:] *= np.linspace(1,0,n)[:,None]
        filenames = []
        targets = ['pass_left','pass_right'] if name == 'pass' else [name]
        for target in targets:
            filename = target + ('' if index == 0 else '_v'+str(index+1)) + '.wav'
            stereo = samples.copy()
            if name == 'pass':
                mono = np.mean(stereo,axis=1)
                stereo = np.stack([mono,mono],axis=1)
                stereo[:, 1 if target == 'pass_left' else 0] *= 0.24
            write(output / filename, stereo)
            filenames.append(filename)
        records.append({'generation_id':item['generation_id'],'files':filenames,'seconds':round(len(samples)/44100,4),'prompt':item['prompt']})
    manifest['sounds'][name] = records
(output/'elevenlabs-manifest.json').write_text(json.dumps(manifest,indent=2))
print('Prepared',len(groups),'sound categories,',sum(len(x) for x in manifest['sounds'].values()),'selected takes')
