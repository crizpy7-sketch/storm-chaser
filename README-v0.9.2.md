# Storm Chaser v0.9.2 — Rolling Tires

The original detailed orange pickup now has moving tire tread and speed-sensitive blur. Smooth gliding and all current gameplay systems are retained.

Follow the tornado, collect storm data, dodge debris, and bring Mateo's footage home.

## Start playing

- Windows: extract the complete Windows ZIP, then open `Storm-Chaser.exe`.
- Linux: extract the complete Linux ZIP and run `Storm-Chaser.x86_64`.
- Godot source: open `project.godot` with Godot 4.5.2, wait for import, then press F6/F5 to run the main scene.
- Web: serve the complete Web folder over HTTP(S). Opening `index.html` directly from a file browser does not load the game.

Controls: A/D or arrows steer; W/Shift boosts; S brakes; Space sends a charged probe; P/Escape pauses; M toggles sound; C hides the dashboard; F11 changes fullscreen; T toggles touch buttons. A controller can use its left stick, A to boost, B to brake, X to transmit, and Start to pause.

Three 30-second fronts, two checkpoint rewards. Keep within 450–1150 m to charge probes. Send at least three probes and survive all three fronts. Field data and near misses feed the local top-five scoreboard.

## The upgrades

- The original detailed orange pickup artwork and its fixed depth mapping are restored. Smooth yaw remains capped at 7.5 degrees; damped suspension moves the truck and Mateo together. Steering does not warp the body or silhouette. Only the visible rubber samples moving tread from its own artwork, with more blur at higher speeds. The solid pickup supplies the road shadow; the original wheels and roof equipment keep their shapes. Wheel motion freezes during pauses and films, and resets for a new chase.
- Water now has layered sheets, tire mist, droplets and short lens splashes. The smooth sideways glide remains. Braking and countersteering help recover traction.
- Road debris has a visible ground shadow and a subtle approach outline. Overhead semis and cows have broad moving shadows and an early directional sound cue. Overhead trajectories are fixed when spawned, rather than following the player's steering.
- Brief calm stretches separate the debris bursts. Barn and warehouse landmarks appear before their checkpoints, with an on-screen countdown to the footage reward. Debris after each film matches the building.
- **Mateo's Footage** includes the six existing dodge films and two checkpoint movies. Checkpoint movies unlock as you reach each checkpoint and remain available between runs. Playback from pause or results cannot award score, advance the mission or change your checkpoint.
- Tailgate scuffs and damaged-taillight flicker follow hull damage without changing the artwork's shape. The engine retains its uneven note at low hull. Repairing hull clears the added wear.
- Three brief ElevenLabs character lines have captions and a 13-second cooldown. This is a synthetic character voice, not a recording or clone of the real Mateo.
- **Driving & Display** offers steering recovery, 22% slower debris with more time between waves, lighter graphics, Mateo's voice, calm effects, vibration, and automatic dodge movies. These settings save automatically. All checkpoint rewards remain earnable with assistance. Runs that use either driving assist are labeled **ASSISTED** on the local scoreboard, even if assistance is switched off later.

## Cinematics and device support

Existing prerecorded checkpoint, dodge and final-impact movies are retained. The checkpoint color pass and entry/return transitions are updated; no new Higgsfield videos were generated. Prerecorded movies are celebratory scenes, not reconstructions of the exact current maneuver. The supplied checkpoint movies do not show Mateo; he remains visible in gameplay and the in-engine fallback scenes.

Repeated roadside poles and reflectors are batched into five instanced mesh groups instead of hundreds of individual draws. The lighter graphics setting disables MSAA and real-time sun shadows and reduces rain, water and orbiting debris. It is the default on native mobile builds. Galaxy Book2, Windows hardware, browser, Android and iPhone performance still require device testing. This release includes Windows, Linux, Web and editable source; it does not include a signed mobile app. Vibration only runs on supported devices and requires an appropriate native export/browser capability.

No generation service, API key, internet connection or credits are needed while playing the desktop game.

## Validation

48 existing driving and polish checks pass for this update. A separate rendered review checks stopped tires, speed response, pause and checkpoint freezes, restart, and confines frame changes to the tires. See `VALIDATION-v0.9.2.md` for results and limits.

## Next requested upgrade

Road curves, off-road sections and small hills are the next planned work. They are not added by this wheel-animation release. See `NEXT-UPGRADE.md` for the agreed direction.
