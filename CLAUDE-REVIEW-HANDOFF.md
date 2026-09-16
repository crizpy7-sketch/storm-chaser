# Update for the accompanying v0.13.2 source

The source now includes the paved-road margin fix in `scripts/main.gd`: `road_steering_limit()` reserves half-body width plus 0.40 units from the road edge, `_update_driving()` eases outward input near that limit, and dirt blends back to the existing 1.2 range. There are 390 passing checks; `tools/verify_road_margin.gd` adds 14 cases. Review these boundary changes and the road alignment alongside the original truck-rendering concerns below. Latest evidence is in `validation/v0.13.2`. The following v0.13.1 handoff remains historical context.

# Storm Chaser — Claude Code review handoff

## Request from the owner

Please independently review this Godot game, especially the truck distortion during swerving. Start with a read-only review and report findings before changing code. Do not assume passing tests prove that the movement looks correct. The owner has repeatedly seen distortion after earlier fixes were reported as complete.

Use the accompanying **Storm-Chaser-Godot-Project.zip**, version **0.13.1**, as the authoritative source. Extract it; the project root is the `Storm-Chaser` directory containing `project.godot`. The separately supplied Windows executable and gameplay preview belong to this version. Do not use an older downloaded copy. Consult `validation/v0.13.1` and the build manifest for evidence and hashes.

## Product and visual intent

Storm Chaser is a Godot 4.5.2 game about driving an orange storm-chaser pickup toward a tornado while dodging debris and collecting storm data. Mateo is a child filming from the back of the truck. Preserve his established appearance and age, his connection to the truck, the original detailed orange truck style, and the existing campaign, checkpoint films, score/progress, controller support and settings.

The owner wants heavy acceleration, audible engine load, realistic smooth fishtailing and gliding, wheel movement, loss of grip in puddles, suspension compression on landing, harder curves and off-road hills, and a dangerous tornado that sways and picks up objects. Bodywork must remain rigid through steering, countersteering, takeoff, airborne motion and landing. Do not substitute a slanted, rubbery, stretching or morphing truck for a realistic drift. Do not increase camera shake as a substitute for weight.

The campaign includes road curves, a sharp right turn onto lighter muddy ground, progressively larger hills and jumps, combined hills/curves, and the tornado approach/finale. Cinematic clips are separate from interactive rendering; a good-looking generated trailer does not prove the game looks or handles that way.

## Implementation and latest change

This is a hybrid renderer: much of the world is 3D, but the visible detailed truck is illustrated artwork rendered on a mesh. It is NOT a fully modeled and rigged 3D truck. A separate baked pickup mesh casts its road shadow. Mateo is separately illustrated and animated.

Version 0.13.0 introduced seven generated truck views. Their body proportions, equipment placement and silhouettes were not registered closely enough to serve as interchangeable animation frames. Switching them while turning could make the truck appear to morph. In addition, the original body artwork used 32 rows with different depths, compensated for one camera position. That bent surface could shear visually when the chase camera or truck moved. Earlier tests only confirmed unchanged mesh vertices, which did not detect projection distortion.

The 0.13.1 fix:

- Replaces the bent depth strips with one planar six-vertex body surface at local z=2.66, using the original `assets/art/truck.png`.
- Disables generated pose swaps during steering AND jumps. The seven images remain available as optional assets, but are not active animation frames. This is a deliberate visual tradeoff, not completion of a multi-angle truck animation system.
- Keeps physical lateral slip, modest whole-truck yaw, sprung-body movement, tread animation and the existing heavy powertrain/landing behavior.
- Places Mateo at local z=2.69 between the body artwork and a tailgate overlay at z=2.72. The overlay reuses the identical mesh and UVs, with `layer_min_v=0.54`. It shares the sprung parent and receives the same damage/braking/wheel uniforms.
- Preserves the previously added tornado sway, dust, suction objects and campaign features.

Please scrutinize whether this fixes visible distortion robustly, whether the layered tailgate introduces seams or parallax, and whether the remaining flat illustration is acceptable at the orbit/finale camera angles. A future fully rigged 3D truck or properly registered angle set may be required for convincing large-angle rotation. Do not claim that exists now.

## Code map

| File | Responsibility |
| --- | --- |
| `scripts/main.gd` | Input, game state, driving/slip/yaw, scoring and campaign integration |
| `scripts/truck_rig.gd` | Visible truck geometry, original texture, tailgate overlay, suspension and wheel uniforms |
| `shaders/classic_truck.gdshader` | Original truck rendering, tire tread, wear/braking and tailgate cutoff; legacy pose-keying branch remains inactive |
| `scripts/world3d.gd` | World, truck transform, chase camera, road/terrain, hazards and late checkpoint/finale camera overrides |
| `scripts/mateo.gd` / `shaders/mateo_camera.gdshader` | Mateo's separate artwork, filming reactions and storm color grading |
| `scripts/powertrain.gd` | Acceleration, RPM/load, gears and shift behavior |
| `scripts/storm_destruction.gd` | Distant objects dragged and lifted around the funnel; environmental effects, not collision hazards |
| `shaders/storm_billboard.gdshader` | Keyed funnel art, upper sway with anchored base, texture turbulence and lighting |
| `tools/verify_*.gd` | Automated tests |
| `tools/record_rigid_swerves.gd` | Actual gameplay preview harness with selected stages and scripted inputs |
| `validation/v0.13.1/` | Latest test logs, native capture evidence and edited-file hashes |
| `export_presets.cfg` | Linux, Windows and Web exports |

## Review priorities

1. **Truck rigidity and continuity:** alternate full left/right inputs; sustain each turn; countersteer out of a puddle; combine steering with collision and landing; test both road edges while the chase camera lags. Watch cab, bed, wheel spacing, dish, antennas and silhouette. Check projection and texture changes, not only immutable vertex arrays.
2. **Mateo and truck integration:** ensure he remains child-sized and attached through spring travel, route pitch, damage reactions, jumps, pause/resume, reset, checkpoints and finale. Inspect tailgate occlusion, overlap with gear, seams and any floating appearance.
3. **Airborne and cinematic views:** review off-road crests, takeoff, descent, compression and orbit/finale cameras. Inspect whether planar art becomes too thin or looks like a sticker. Follow the full camera override order in `world3d.gd`.
4. **Driving regressions:** preserve meaningful steering, heavy response, lateral slip, landing recovery and controller behavior. Check simulation behavior at 30/60/120 FPS; distinguish real frame-time behavior from offline fixed-FPS capture.
5. **Tornado integration and performance:** inspect anchored contact, sway, occlusion, depth ordering, magenta edges, lifted objects and light-graphics mode. The funnel is an animated image mesh with separate objects, not volumetric fluid simulation.
6. **Release quality:** check source/export consistency, crash/script/shader errors, saves and checkpoint compatibility. Flag genuine defects without expanding scope into unrelated redesign.

## Local setup and verification

Install/open **Godot 4.5.2 stable**, using the Compatibility renderer configured by the project. Import `project.godot` and let imports finish. No API keys, Higgsfield credits or new media generation are needed to review the supplied assets.

From the extracted project root, with your local Godot executable available as `godot`:

```bash
godot --editor --path .
godot --path . -- --test
godot --headless --path . --script res://tools/verify_rigid_truck.gd -- --test
godot --headless --path . --script res://tools/verify_storm_art.gd -- --test
godot --headless --path . --script res://tools/verify_polish.gd -- --test
godot --headless --path . --script res://tools/verify_weight.gd -- --test
```

For broader regression coverage, also run `verify_driving.gd`, `verify_route.gd`, `verify_checkpoints.gd` and `verify_finale.gd` with the same flags. On Windows use the installed Godot console executable path if `godot` is not on PATH. Exporting requires matching 4.5.2 templates; preset names are `Windows`, `Linux`, `Web`.

The existing `tools/run_render.py` helper expects the original workspace's local Xvfb/Mesa paths and is not a portable installation requirement. On your machine, render directly with Godot and the normal graphics/display environment. If using the capture script, set `STORM_CAPTURE_DIR` to an existing absolute output directory before launching it. Use your own output paths. Do not hardcode `/workspace/scratch/67b1f15ec186` into game code.

Controls shown in the game: A/D steer, W boost, S brake, Space probe, P pause. Consult the in-game settings and `PLAY-ON-LAPTOP-AND-TV.txt` for controller and display instructions. Keep review saves isolated; the test harnesses use separate settings paths and suppress normal save writes.

## Evidence and limits

376 automated checks pass: driving 21, polish 27, checkpoints 176, route 71, finale 50, weight 13, storm art 13, rigid truck 5. The five new checks cover coplanar body geometry, stable artwork during steering/jump transitions, projected straight edges at lateral camera offsets/yaw extremes, tailgate/Mateo depth order and a common sprung parent.

These tests do not establish visual realism. The projected-edge check is only a limited invariant, not a pixel-level proof of silhouette quality. Older test descriptions about unchanged vertices should not be taken as independent proof of no distortion.

A 15-second preview is rendered from actual game logic. It includes scripted alternating steering followed by automated driving across selected stages. Stage selection resets health/boost and some state; it is not an uninterrupted player campaign. The native validation capture uses the Linux export with software rendering, not Windows or the owner's Galaxy Book2. Windows and Web have been exported but this review should independently exercise them where possible. Do not quote offline capture speed as hardware performance.

Known pre-existing exit warnings mention leaked ObjectDB instances and approximately seven resources still in use when the harness shuts down. Distinguish these from gameplay script/shader errors, and investigate ownership cleanup if it causes a real runtime problem.

Shader color caveat: the keyed pose/tornado textures use raw color samples. Godot Compatibility expects different handling from linear rendering; unconditional manual sRGB-to-linear conversion previously made artwork nearly black. Inspect `OUTPUT_IS_SRGB` conditions before changing grading. The original truck texture uses `source_color`.

## Requested review response

Lead with actionable findings, ordered by severity. For each finding provide:

- File and line references from your extracted copy.
- Reproduction steps or a concrete code path.
- Expected versus observed behavior, preferably with screenshots or a short actual-game recording.
- A minimal suggested fix and how to verify it without breaking the original truck, Mateo or handling.

Separate confirmed defects from suspected visual risks and future enhancements. State exactly which tests and platforms you ran. If no defect is confirmed, say so and list remaining visual/hardware gaps. Ask the owner before implementing a substantial rendering redesign; do not silently replace the truck style or spend media-generation credits.
