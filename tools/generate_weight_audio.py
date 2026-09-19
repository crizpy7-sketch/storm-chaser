"""Original procedural low motor/body layers; existing ElevenLabs engine stays lead."""
from pathlib import Path
import numpy as np
import wave
root=Path(__file__).resolve().parents[1]/'assets/audio'
rng=np.random.default_rng(120)
sr=44100
def save(name,x):
    x=x/max(1.0,float(np.max(np.abs(x))))*.8
    with wave.open(str(root/(name+'.wav')),'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
        w.writeframes((x*32767).astype('<i2').tobytes())
t=np.arange(sr*4)/sr
# Integer frequency cycles make an exactly periodic four-second motor loop.
motor=sum(np.sin(2*np.pi*60*k*t+0.18*k)/k**1.6 for k in range(1,9))
motor*=.55+.10*np.sin(2*np.pi*15*t)
save('motor_body',motor)
t=np.arange(int(sr*1.1))/sr
noise=rng.normal(0,1,len(t)); filtered=np.convolve(noise,np.ones(24)/24,mode='same')
impact=.75*np.sin(2*np.pi*(66*t-14*t*t))*np.exp(-t*11)+filtered*.9*np.exp(-t*18)
impact+=.18*np.sin(2*np.pi*113*t)*np.exp(-t*7)
impact*=np.minimum(t/.004,1)
impact[-400:]*=np.linspace(1,0,400)
save('landing_body',impact)
