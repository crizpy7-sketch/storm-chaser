# Storm Chaser v0.10.0 — Into the Vortex

Eight escalating levels carry the original orange interceptor and Mateo from the highway into the tornado. The original truck art, restrained fishtail, moving tire tread, colored storm lighting, bottom instrument cluster, existing ElevenLabs audio, building movies, dodge celebrations and impact ending are retained.

## Play the campaign

| Level | Route | New challenge | Cruise |
|---|---|---|---:|
| 1 | Prairie Approach | Wet highway, debris and puddles | 146 mph |
| 2 | Barn Breakout | Barn destruction checkpoint, timber and roofing | 162 mph |
| 3 | Warehouse Collapse | Warehouse checkpoint, concrete and steel | 178 mph |
| 4 | Crosswind Curves | Repeated bends push the truck toward the outside shoulder | 146 mph |
| 5 | Dirt Shortcut | A marked ninety-degree right turn leaves the closed highway for narrower dirt and small hills | 122 mph |
| 6 | Ridgeline Jumps | Larger crests launch the truck; sideways landings break traction | 136 mph |
| 7 | Wild Hills | Large jumps and curves together, with less grip | 148 mph |
| 8 | Vortex Run | Follow a full circle around the tornado, then get pulled into it | 112 mph |

The first seven levels last 30 seconds of active driving each. Upgrades, checkpoint previews and celebration videos freeze progression. The final level advances by actual route distance: approach the tornado and complete the circle at your own speed. It has no countdown that can end the lap early.

Survive to the vortex and transmit at least **three probes** for a completed survey. The suction finale still plays if you arrive with fewer probes; the debrief then reports an incomplete survey and offers a checkpoint retry. Mateo stays with the truck, braces during jumps and landings, and appears in the new in-engine previews and finale.

## Controls and handling

- **A/D or arrows:** steer. **W / Shift / Up:** boost, up to 240 mph. **S / Down:** brake.
- **Space:** transmit a charged probe while in range. **P / Escape:** pause, including during the vortex finale.
- **T:** touch controls. **M:** mute. **C:** hide the driving HUD. **F11:** fullscreen.
- Controller: left stick / D-pad steers, A boosts, B brakes, X transmits, Start pauses.

Brake before a tight curve, hold steering against the outward drift, then accelerate out. Dirt reduces grip. Braking over big crests helps keep the tires down; at higher speed the truck follows a ballistic jump and must reconnect with the terrain. Steering is weaker in the air. Land straight to earn data; landing with a large sideways slide can damage the hull and kick the rear outward. High jumps can clear low debris, but cannot collect ground supplies or trigger puddles beneath the truck. Staying on the shoulder too long damages the truck.

Each of seven checkpoints offers repair, grip or boost capacity. The first two play the existing building movies. Later checkpoints use short Godot camera previews of the next terrain, with Mateo in the truck. **Keep Chasing** skips a preview. Retry restores the saved level entrance, hull, upgrades, score and probes, clears airborne/sliding state, and grants no second upgrade or failed-attempt rewards. Existing older checkpoint saves remain compatible.

DATA remains the score. Probes, close dodges, supplies and tracking earn data as before; controlled landings earn 200–450, directly clearing a low obstacle in a high jump earns 125, and the final transmission earns 2,000. A successful survey also awards remaining hull × 20. The local top-five scoreboard identifies retried and assisted expeditions.

## Install

- **Windows / Galaxy Book2:** extract the entire Windows ZIP and open `Storm-Chaser.exe`.
- **Linux:** extract the Linux ZIP and run `./Storm-Chaser.x86_64`.
- **Godot:** extract the project ZIP and import `project.godot` with Godot 4.5.2. Install official export templates to export on your own machine.
- **Web:** serve the complete Web folder over HTTP(S); opening `index.html` directly from disk is not supported.

The driving/display menu retains optional steering recovery, extra hazard reaction time, lighter graphics, reduced camera effects and Mateo voice controls. Touch controls and vibration hooks remain available, subject to device/browser support. No Android or iOS package is included. Galaxy Book2, real Windows hardware, browser/mobile performance, multitouch and phone vibration still need device testing.

## Preview and implementation

`Storm-Chaser-v0.10.0-Into-the-Vortex.mp4` is a fresh recording of the actual Godot build, edited to show the new levels. An automated driver uses ordinary game handling, collisions, upgrades and probes. Unshown driving is simulated between highlights; health and earned progress carry through the campaign. Automatic dodge films are disabled for the capture. It is recorded offline at 30 fps, not a device performance benchmark.

The road, ground, obstacles and puddles share the same route samples. The art uses the game's existing 2.5D presentation: the finale reuses the detailed tornado artwork with a camera-facing orientation while the truck follows a spiral in 3D space. This release creates no new AI images, movies or audio and spends no Higgsfield or ElevenLabs credits.

See `VALIDATION-v0.10.0.md` for checks and practical limits; older release notes are historical.
