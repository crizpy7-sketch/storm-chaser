# Storm Chaser: making the truck feel heavy

Research and implementation notes · v0.12.0 · 15 September 2026

## Decision

Keep the existing playable game and original orange interceptor, but coordinate the motor, transmission, suspension, landing grip and camera around the same driving events. Improve off-road depth with lit rolling terrain and new clay and storm artwork. This is an arcade handling upgrade, not a claim to simulate a particular real truck.

Cristian’s playtest is the starting evidence: the existing game is enjoyable, but acceleration, engine presence and landings feel too light. The objective is a substantial truck that takes a moment to gather speed, compresses on landing, and carries lateral momentum until the player catches it. Adding random shaking or making steering uniformly slower would not meet that objective.

## Research findings

### 1. Separate the motor from the speedometer

NVIDIA’s vehicle architecture separates engine rotation, gearing, clutch coupling, wheel rotation and vehicle momentum. Tire forces also depend on contact, load, friction and slip. This supports separating motor revs from road speed: wheels can unload during a jump while the engine continues revving. These concepts inform our simplified model; Storm Chaser does not use the PhysX SDK or reproduce its complete tire model. [NVIDIA, PhysX 5.4.1 Vehicles](https://nvidia-omniverse.github.io/PhysX/physx/5.4.1/docs/Vehicles.html)

**Implementation judgment:** preserve automatic forward driving, W/Shift boost and S brake. Give throttle a finite rise time, introduce six speed bands with shift hysteresis, briefly reduce drive during shifts, and smooth acceleration itself. Uphill grade and loose surfaces modestly reduce acceleration. Airborne acceleration cannot add ground thrust; the engine revs with much less load instead. Braking in flight does not magically slow the truck like road braking.

The original code moved toward cruise at 68 displayed mph per second and toward boost at 96, with no motor state. The new motor takes time to build torque and briefly unloads while shifting. It still accelerates strongly enough for the game’s short stages.

### 2. Weight needs compression and settling

A spring supplies a restoring force proportional to displacement; a damper removes energy in proportion to velocity. The familiar combined form is `F = -k*x - b*v`. Without damping, a displaced spring continues oscillating. [Glenn Fiedler, Spring Physics](https://gafferongames.com/post/spring_physics/)

**Implementation judgment:** increase the truck’s visible landing travel while retaining a damped return. The body uses a bounded spring with a stronger landing impulse; acceleration pitches the complete body slightly and braking pitches it in the opposite direction. Mateo stays under the same body parent. The truck’s illustrated mesh and UV coordinates remain fixed, and there is no added side roll or stretching.

Travel limits are presentation limits in this game’s scene scale, not measured suspension specifications. The model intentionally gives a brief visible rebound for feedback. It should settle quickly enough that the next obstacle remains readable. The camera follows part of the compression and longitudinal movement rather than adding a large unrelated shake.

### 3. Rough landings should preserve the player’s mistake

**Implementation judgment:** use landing impact severity and existing sideways movement to determine the skid. A straight landing must not acquire an arbitrary left or right kick. A crooked landing should carry its existing direction, temporarily reduce traction and restore grip gradually. Countersteering and braking must still help. Existing steering recovery and grip upgrades remain useful.

The route already had airborne motion and a lateral landing impulse. The upgrade extends its recovery envelope and increases suspension and sound feedback. Damage and landing data rewards keep their existing rules. Suspension rebound does not create another collision reward or another landing event.

### 4. Use bounded integration where the new dynamics are sensitive

Variable timesteps can alter simulation behavior and destabilize spring integration. Bounding the integration step limits that problem; a fixed-step accumulator can decouple simulation from rendering, with a maximum catch-up budget to avoid falling further behind. [Glenn Fiedler, Fix Your Timestep!](https://gafferongames.com/post/fix_your_timestep/)

**Implementation judgment:** integrate the new powertrain and body suspension in steps no larger than 1/120 second. This is a targeted change, not a conversion of the entire older game to a fixed-timestep architecture. Existing route, hazards and campaign timing retain their current loop. Validate the motor at 30, 60 and 120 Hz and keep travel clamps for suspension impacts.

A complete physics-loop rewrite is deferred because it would affect hazards, movies, stage timing and the original truck presentation at the same time. That risk is disproportionate to the requested feel upgrade.

### 5. Sound should convey load as well as revs

Godot exposes pitch and volume controls on AudioStreamPlayer. Changing pitch affects both pitch and playback speed. These controls can drive a layered engine response, but simply pitching one recording is not the same as a recorded multichannel engine simulation. [Godot 4.5, AudioStreamPlayer](https://docs.godotengine.org/en/4.5/classes/class_audiostreamplayer.html)

**Implementation judgment:** retain the existing ElevenLabs engine as the main sound. Drive its pitch from the new RPM state and its loudness from load. Add an original synthesized low motor layer underneath, plus a separate short body thump for landing severity. The latter replaces the landing’s generic wood impact sound; collision sounds for debris stay intact.

The new audio layers are generated locally by a reproducible DSP script, with no new paid audio or video generation. A limiter remains on the mix. Low fundamentals are reinforced by harmonics so the motor is not entirely dependent on a subwoofer. Actual perceived bass still depends on the laptop, TV, headphones and volume. A gameplay recording is a useful audition, not a substitute for the player’s own speakers.

### 6. Hills need geometry and consistent lighting, not only a picture

Godot’s material documentation distinguishes base color, roughness and normal detail. Roughness changes how reflections spread; normal mapping changes lighting response without changing geometry. Unshaded surfaces do not respond to scene lights. [Godot 4.5, Standard Material 3D](https://docs.godotengine.org/en/4.5/tutorials/3d/standard_material_3d.html)

**Implementation judgment:** use a newly generated overhead tan clay texture on the road, keep directional ruts and wet pools, and render off-road terrain with light-responsive normals. Replace the broad flat surrounding basin with rolling prairie elevations blended away from the driving corridor. Use world-stable terrain coordinates so textures do not rotate independently when the route bends. Place a new storm/prairie panorama behind the real terrain in the three dirt/hill stages.

The road texture follows the route longitudinally; the large right-angle junction remains a perpendicular branch. Warm soil should distinguish dirt from dark wet asphalt immediately. Wetness remains selective, so the whole road does not become a reflective black ribbon. The panorama is a background image, not extra collision geometry. Existing road shape still determines drivable height.

### 7. Keep the proven vehicle architecture

Godot documents limitations in VehicleBody3D and notes that advanced vehicle physics may need custom integration. It also does not simulate gears automatically. [Godot 4.5, VehicleBody3D](https://docs.godotengine.org/en/4.5/classes/class_vehiclebody3d.html)

**Implementation judgment:** migrating to a new rigid-body vehicle would also require rebuilding the truck and its collision representation. That could reintroduce the warped or slanted appearance Cristian rejected. A focused upgrade to the existing route simulation is the practical next step. A future fully 3D truck would be a separate art and physics project, requiring a new approved model and substantially broader playtesting.

## Implemented tuning

| System | v0.12.0 behavior | Purpose |
|---|---|---|
| Throttle | Exponential build, faster release | Perceptible motor response without a dead input delay |
| Transmission | Six bands, 12 mph downshift hysteresis, 0.23-second shift reduction | Audible RPM changes without repeated gear hunting |
| Acceleration | Smoothed force request; reduced drive on dirt/uphill | Truck gathers momentum rather than snapping to target |
| Airborne drive | No positive ground acceleration; free rev response | Connect sound and traction to tire contact |
| Suspension | Stronger landing impulse, bounded compression/rebound, 120 Hz maximum step | Solid landing and visible settling |
| Body motion | Small acceleration/braking pitch; no added roll or mesh distortion | Weight transfer while keeping original truck identity |
| Grip | Extended landing recovery; existing countersteer/brake assistance | A controllable consequence for landing sideways |
| Audio | RPM-driven lead engine, load-driven body layer, severity-driven landing thud | Engine presence and impact weight |
| Camera | Partial suspension and acceleration response; reduced-effects option respected | Reinforce movement without losing the road |
| Terrain | New clay art, rolling lit fields, new storm panorama | Readable off-road surface and hill depth |
| Haptics | Short event pulses sent to connected gamepads, plus existing handheld path | Impact feedback where hardware supports it |

## Validation and limits

The six automated suites cover 358 checks: driving 21, polish 27, checkpoints 176, route 71, finale 50, and new weight tests 13. The existing normal and assisted campaign completion checks remain part of this validation. Logs ship inside the source project.

In the isolated motor test, starting at 112 mph and holding boost for three seconds reaches 221.51 displayed mph and passes through three shifts. The 30, 60 and 120 Hz runs agree within the test’s 0.05 mph tolerance. This is a repeatability and tuning measurement; it is not a real-world truck acceleration claim. The game intentionally retains exaggerated arcade speeds and its original route-distance scale.

New checks also cover free revving without airborne thrust, useful braking, straight versus crooked landing response, bounded compression, settling, recovery, motor reset and audio loading. Existing checks protect original truck geometry, score/reward behavior, checkpoint retries and the ending.

The preview uses the actual Godot renderer and game logic with isolated stage selection to show highway acceleration, the dirt shortcut, Ridgeline Jumps and Wild Hills. It is not a filmed full campaign, a Grok trailer or a hardware performance benchmark. Rendering and audio should be reviewed alongside the test results. Native Linux capture cannot verify Windows controller drivers, physical vibration or speaker response on Cristian’s Galaxy Book2. Cristian has already playtested the prior Windows release; this new handling tune needs his comparison.

## Suggested next playtest

1. On the highway, hold boost, release it, then brake. Listen for the engine loading up and RPM drops between gears.
2. Brake before the shortcut, then accelerate onto the light clay. Check that the road edge and ruts remain readable.
3. Approach a big crest straight, then try one with some sideways movement. The second landing should require a correction; neither should stretch the truck.
4. Use a brief brake and countersteer after landing. The slide should decay rather than snap instantly or continue indefinitely.
5. Compare normal and reduced camera effects. Report whether the truck feels heavy, floaty, sluggish or too slippery, and at which level.

The next tuning decision should follow those observations. More suspension travel, more bass and less grip are independent changes; increasing all three indefinitely would make the game harder without necessarily making it better.

## Sources and scope

Primary technical sources were consulted on 15 September 2026. The material above separates their mechanical or API explanations from our game-specific design decisions. No source establishes that these exact values will feel best to this player. The inaccessible Audiokinetic article discovered during search was not used as evidence.

- [NVIDIA PhysX 5.4.1 vehicle guide](https://nvidia-omniverse.github.io/PhysX/physx/5.4.1/docs/Vehicles.html)
- [Glenn Fiedler: Spring Physics](https://gafferongames.com/post/spring_physics/)
- [Glenn Fiedler: Fix Your Timestep!](https://gafferongames.com/post/fix_your_timestep/)
- [Godot 4.5: AudioStreamPlayer](https://docs.godotengine.org/en/4.5/classes/class_audiostreamplayer.html)
- [Godot 4.5: Standard Material 3D](https://docs.godotengine.org/en/4.5/tutorials/3d/standard_material_3d.html)
- [Godot 4.5: VehicleBody3D](https://docs.godotengine.org/en/4.5/classes/class_vehiclebody3d.html)
