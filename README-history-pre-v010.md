# Current release: v0.9.2 — Rolling Tires

Read [README-v0.9.2.md](README-v0.9.2.md) for current features, controls, device support and validation. Earlier design and release notes follow for historical context.

# Storm Chaser

**Latest: 0.8.1 — Smooth glide.** Fishtails now use restrained, smoothly changing headings (maximum 7.5 degrees), reduced rotational kick and sideways gliding. This supersedes the extreme rotation described in the v0.8 notes below.

**Current version: 0.8.0 — Water & Thunder.** Read [README-v0.8.md](README-v0.8.md) for the current game, controls, audio, puddles, mobile vibration and checkpoint-video behavior. The earlier documentation below describes the development history; the new six-second Grok checkpoint films now play by default, with the original Mateo destruction scenes retained as a fallback.

## Earlier version notes

A Godot storm-chasing game for Cristian: chase a moving tornado, dodge debris on a wet highway, transmit storm probes, and bring the truck home. Version 0.7, **Destruction Checkpoints**, adds building-collapse scenes with Mateo, matching debris, checkpoint retries and a local top-five scoreboard.

## Destruction Checkpoints update

The mission is still **90 seconds of driving and at least three transmitted probes**. Difficulty advances with time survived, every 30 seconds. **DATA is your score**, not a currency or an unlock requirement. Cinematics and upgrade selection do not consume the mission timer.

| Front | Driving time | Cruise | Hazards |
|---|---|---|---|
| Prairie Approach | 0–30 seconds | 146 mph | Crates, barrels, tires, loose roofing |
| Barn Breakout | 30–60 seconds | 162 mph | Red timber, barn doors, broken braces, galvanized roofing |
| Warehouse Collapse | 60–90 seconds | 178 mph | Concrete with rebar, steel beams, cladding, metal roofing |

At each transition, select one upgrade. An **8.6-second in-engine cinematic** shows the tornado striking the next building, lifting its roof and throwing the structure apart. Mateo remains in the actual truck bed: he records the collapse and ducks when large pieces sweep toward the camera. The same generated surface materials appear on the building and its subsequent road debris. These two new sequences run in Godot; the older trailer, dodge films and final crash retain their existing Higgsfield footage.

Debris takes about **1.82 / 1.47 / 1.21 seconds** to reach the truck at each front's cruise speed. Later fronts also spawn more frequently, add adjacent pairs and increase crosswind. Each wave leaves at least half the highway open. Boost reaches 240 mph in every front. Overhead semis and cows remain visual set pieces; building debris on the road causes normal collision damage.

The checkpoint is saved after the chosen upgrade and cinematic. **Retry Checkpoint [R]** on the debrief, or **Resume Checkpoint** at the title screen, restores the saved score, probes, charge, hull, upgrades and stage. Failed-attempt gains are discarded. The scene does not replay and the upgrade cannot be selected again on retry. The road clears and the truck gets a brief two-second recovery window. **New Chase** starts at the beginning and clears the checkpoint. Completing the mission retires it. Saves are local to the device; Web saves depend on the browser retaining site data.

| Score source | DATA earned |
|---|---:|
| Charged probe transmitted in range | 1,500 |
| Close dodge | 100 × combo, up to 500 |
| Tracking each second | 20 / 30 / 40 by front |
| Driving outside sampling range each second | 5 |
| Green supply pickup | 300 |
| Successful finish | Remaining hull × 20 |

The title screen shows a **local top-five scoreboard**. One expedition occupies at most one row even after retries; the better result updates that row. Retried expeditions are labelled RETRY. This is a local single-player board, with no online accounts or rankings.

Space, Escape, Enter, controller A/B/X/Start or **Keep Chasing** skips the new cinematic. Skipping does not transmit a probe. Losing focus saves the checkpoint and pauses the chase. Calm FX reduces camera shake and flashes in these in-engine scenes. The original obstacle films only trigger for their matching original objects; new building fragments use live close-dodge feedback, while semi/cow celebrations remain available.

**Storm-Chaser-v0.7-Checkpoint-Gameplay.mp4** records the actual Godot game and both new checkpoint scenes. The automated driver uses normal movement, collisions, probes and upgrades. Unshown driving is simulated between preview chapters to shorten the video; the capture grants no extra score, health or probes. Automatic dodge films are disabled for this preview. Its shortened edit is not the full real-time 90-second mission.

## Final Impact update

Collisions now throw sparks and material-colored fragments, kick the camera, briefly slow the action and layer heavy crash sounds. Crates and roofing break apart; drums and tires ricochet. Smoke and a warning appear when the hull is critical.

When the hull reaches zero, the game holds the final impact for a moment, freezes the chase, and plays a eight-second cinematic of the orange truck crashing and stopping. GAME OVER then appears over the wreck, with your score and a Chase Again button. Space, Escape, Enter, controller A/B/X/Start or the on-screen skip button goes directly to Game Over. The final film is independent of the automatic dodge-film setting. It is a reusable dramatic ending, not an exact replay of your obstacle or steering.

The **Storm-Chaser-v0.6-Final-Impact-Gameplay.mp4** preview records the actual Godot app with five deliberately staged hazards to demonstrate collisions, the embedded final film and Game Over. Damage, invulnerability and playback rules are unchanged by the demonstration script.

## Mateo Storm Cam update

The 0.5.1 color pass matches Mateo to the overcast scene: muted teal clothing, cool fill lighting, softer highlights and a shadow toward the truck bed. He also responds subtly to the existing lightning, unless Calm FX is enabled.

Mateo films from inside the truck bed, using character art matched to his supplied photo: dark hair, a teal shirt, blue shorts and a black camera harness. His upper body counterbalances the truck's fishtails while his camera moves with road vibration. He raises the camera for flying debris, ducks under the semi and braces after impacts. Close dodges and successful probes earn an excited look back.

Four illustrated poses blend with continuous body and camera movement. The tailgate hides his lower body, and his character follows the truck through steering and yaw. Pause and prerecorded cinematic playback freeze his animation; restarting resets his pose. The new building cinematics animate him inside the game. Calm FX reduces the added sway and vibration. A small **MATEO / STORM CAM** recording indicator sits above the bottom controls.

The supplied **Storm-Chaser-v0.5.1-Mateo-Gameplay.mp4** is a 24-second recording of live Godot gameplay with automatic films disabled for the capture, so Mateo stays visible. The game's automatic films remain available and on by default. The existing trailer and six celebration films use their original footage and do not yet include Mateo.

## Cinematic Dodges update

Six five-second Higgsfield films celebrate clearing a **crate, barrel, tire, roofing sheet, 18-wheeler or flying cow**. They feature the same orange research pickup, wet highway and giant tornado, with close camera passes, fishtailing, speed ramps and synchronized sound. These are reusable obstacle celebrations, not recordings of the player's exact steering.

A close road dodge queues the matching film after the object clears. An overhead semi or cow pass can trigger its film when the player steers clear without taking a hit. Overhead objects remain visual set pieces and do not gain invisible damage zones or extra score. Supplies never trigger dodge films.

The chase and its audio freeze for the film, then resume from the same state. **Space, Escape, Enter, controller A/B/X/Start, or Keep Chasing** skips immediately. Skipping does not deploy a probe. Losing window focus during an automatic film returns to a paused chase.

Automatic films are on by default, with **20 seconds of driving between films**, at least 45 seconds before the same item repeats, and a maximum of **three films per chase**. The **Dodge Films: On/Off** setting on the title and pause screens saves with the other preferences. **Dodge Films** on the title screen, or **Watch** on the pause screen, opens the six-film gallery. All clips are included locally; playback needs no generation service, account, internet connection or credits.

## Skyfall 3D update

A low chase camera follows the truck through a wet, curved 3D highway. Steering now swings the rear outward and settles through countersteering. The truck does not roll sideways. Its original detailed artwork is mapped onto a depth mesh, while a solid vehicle model supplies its shadow.

A full-size 18-wheeler tumbles overhead, a cow flies past in the storm, and a roofing fragment rushes into the camera. The strike briefly kicks the view, leaves cracks and water on the lens, then clears. The overhead set pieces are visual near misses; road debris still causes damage.

The tornado fills more of the sky. Dark fields, passing poles and wires, wet road reflections, tire spray, fast rain, heavy flyby sounds and skid audio reinforce the rush. Instruments sit in the lower corners. Press **C** during a chase to hide or restore the HUD. Pause remains available in cinema view.

Cruise at **146–178 mph** and hold boost to reach **240 mph**. Debris reaches the truck in approximately **1.8 seconds at first-front cruise speed** and **1.3 seconds at full boost**. A 138 BPM action score follows the chase.

**Watch Storm Film** on the title screen plays the original generated Higgsfield trailer. Press Escape, Space, Enter or the return button to close it. The earlier v0.4 gameplay preview shows the built-in celebration playback.

## Play on Windows

Download **Storm-Chaser-Windows.zip**, extract the entire ZIP, then double-click **Storm-Chaser.exe**. The Windows build is for a 64-bit Windows PC. Godot and Python are not needed to play the exported game. This is a new, unsigned independent game build.

## Open the editable project

Extract **Storm-Chaser-Godot-Project.zip**. In Godot 4.5.2 (the tested version), choose **Import**, select `project.godot`, and press **F5** to run. The project uses GDScript and the Compatibility renderer. No API keys, network services, or plugins are required to play or edit this project.

Official engine download: https://godotengine.org/download/archive/4.5.2-stable/

## Your mission

Survive **90 seconds across three storm fronts** and send **at least three probes**. The truck automatically accelerates to cruising speed. Steering, braking and boosting remain under your control.

Stay **450–1150 meters** behind the tornado to charge a probe. Charging takes about 13.3 seconds in range. Press **Space** when the probe is ready. Boost to close a growing gap; brake if you get too close. The game uses compressed arcade distances and wind behavior, rather than real-world storm-chasing physics.

Wooden crates, rolling tires, barrels and metal roofing can damage the truck. Green supply crates restore 18 hull and 30 boost. A close dodge earns a score multiplier and a little boost. You briefly resist further impacts after a collision.

Every 30 seconds, choose a field repair, better tires, or a larger boost tank, then watch the next building collapse. A checkpoint saves at the start of the new front. Damage and upgrades carry through the run. Your top five scores, checkpoint and sound/effects preferences save locally.

| Action | Keyboard | Xbox-style controller |
|---|---|---|
| Steer | A/D or Left/Right | Left stick or D-pad |
| Boost | W, Up, or Shift | A |
| Brake | S or Down | B |
| Transmit probe | Space | X |
| Pause/resume | P or Escape | Start |
| Mute/unmute | M | On-screen sound button |
| Fullscreen | F11 | — |
| Toggle touch buttons | T | — |
| Hide/restore chase HUD | C | — |
| Retry checkpoint / restart | R | Select Retry Checkpoint / Chase Again |
| Skip a dodge film | Space / Escape / Enter | A / B / X / Start |

**Calm FX** reduces rain and camera movement, and disables impact shake, speed streaks, lens fractures, shards and lightning/impact flashes. A restrained water mark remains after a lens strike. It is available on the title and pause screens. Touch buttons appear automatically on mobile platforms, and can be toggled with T. Controller mapping is implemented; physical controller and phone testing have not been performed in this environment.

Calm FX affects the live chase. The films have their own camera motion; turn **Dodge Films Off** if you prefer uninterrupted driving with calmer effects.

## Builds and project contents

- `main.tscn` — main scene.
- `scripts/main.gd` — driving, hazards, scoring, probes, checkpoint snapshots, local scoreboard and saves.
- `scripts/checkpoints.gd` — two destructible buildings, camera choreography, dust, material continuity and safe handback.
- `scripts/world3d.gd` — 3D chase camera, road, vehicle depth mesh, overhead objects, scenery and spray.
- `scripts/mateo.gd` — filming poses, counterlean, camera motion and debris reactions.
- `scripts/world.gd` — retained previous 2.5D renderer for development reference.
- `scripts/lens.gd` — camera-bound projectiles, cracks, shards and water.
- `scripts/hud.gd` — title, instruments, controls, upgrades and debrief.
- `scripts/dodge_films.gd` — reward selection, frozen playback, skips, gallery and cooldowns.
- `shaders/` — wet road and animated vortex materials.
- `assets/art/` — nine original generated PNG assets, including Mateo's four-pose character atlas.
- `assets/models/storm-vehicles.glb` — editable pickup and 18-wheeler geometry, created in Higgsfield 3D Jutsu.
- `assets/cinematics/storm-film.ogv` — embedded ten-second Higgsfield film, with sound.
- `assets/cinematics/dodges/` — six 720p Theora films, gallery posters and provenance manifest.
- `tools/build_vehicles.py` — Blender source for the vehicle geometry.
- `assets/audio/` — original soundtrack, wind, engine, thunder and effects.
- `tools/generate_audio.py` — reproducible audio synthesis source. Only needed to regenerate audio.
- `tools/test_game.gd` — functional gameplay checks, including a complete 90-second simulated chase.
- `tools/test_checkpoints.gd` — 33 checkpoint, persistence, scoring, hazard matching and interruption checks.
- `tools/record_checkpoints.gd` — actual-game preview of both building transitions with shortened driving.
- `tools/test_crashes.gd` — 17 impact, final-film and Game Over checks.
- `tools/test_mateo.gd` — character reactions, counterlean, pause, reset and scoring isolation.
- `tools/record_mateo.gd` — demo gameplay capture with uninterrupted character animation.
- `tools/test_dodge_films.gd` — matching, cooldowns, state preservation, interruption and gallery checks.
- `tools/test_dodge_playback.gd` — actual video decoding, natural completion and controller-event skip checks, requiring a rendering display.
- `tools/capture.gd` — reproducible in-engine screenshots; run with `--fixed-fps 30` and a rendering display.
- `export_presets.cfg` — Windows, Linux and Web export settings.
- `ART-DIRECTION.md` — image prompts and asset provenance.

## Development checks

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tools/test_game.gd -- --test
godot --headless --path . --script res://tools/test_checkpoints.gd -- --test
godot --headless --path . --script res://tools/test_crashes.gd -- --test
godot --headless --path . --script res://tools/test_mateo.gd -- --test
godot --headless --path . --script res://tools/test_dodge_films.gd -- --test
godot --path . --script res://tools/test_dodge_playback.gd --fixed-fps 60 -- --test
```

With matching export templates installed:

```bash
godot --headless --path . --export-release "Windows Desktop" ../Storm-Chaser.exe
```

Godot's official command-line reference: https://docs.godotengine.org/en/4.5/tutorials/editor/command_line_tutorial.html

`--demo` starts an automated driver using the same game simulation, collisions and controls. It does not add invulnerability or extra health. Demo and test runs do not write personal bests.

This release is a single-player hybrid 3D arcade prototype with a complete beginning, three-stage chase and debrief. The highway, road props and semi are meshes; the truck uses a textured depth mesh, and the storm and cow use artwork in 3D space. It does not reproduce every detail of the generated film or use realistic vehicle and tornado physics. It is designed for future expansion with more regions, trucks, storm behaviors and cooperative play.
