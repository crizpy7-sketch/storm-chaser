# Storm Chaser 0.8 — Water & Thunder

Chase a tornado, dodge flying debris, collect storm data and bring Mateo's footage home. This update adds stronger fishtails, puddles that break traction, large splashes, ElevenLabs audio and mobile vibration hooks. The two supplied Grok videos now play at the barn and warehouse checkpoints.

## Play

On Windows, extract Storm-Chaser-Windows.zip and run Storm-Chaser.exe. On Linux, extract Storm-Chaser-Linux.zip, allow the executable to run and launch Storm-Chaser.x86_64. Both are x86_64 builds; neither needs Godot or an AI account to play.

The editable project uses Godot 4.5.2 and the Compatibility renderer. Import project.godot, then press F5. Install the matching official Godot export templates to build other platforms. The Android preset includes vibration permission but still needs the Android SDK, signing configuration and device testing; no APK or iOS app is supplied.

For the Web folder, serve its entire contents over HTTP/HTTPS. For local desktop use, run `python3 -m http.server 8000` in that folder and open http://localhost:8000. Opening index.html directly will not work. Browser and phone performance still need testing.

| Action | Keyboard | Controller / touch |
|---|---|---|
| Steer | A / D or left / right | Left stick, D-pad / arrow buttons |
| Boost | W, up or Shift | A / Boost |
| Brake | S or down | B / Brake |
| Send probe | Space | X / Transmit Probe |
| Pause | P or Escape | Start / pause button |
| Hide HUD | C | — |
| Sound | M | Sound button |
| Touch controls | T | Automatic on supported mobile targets |
| Fullscreen | F11 | — |

## Fishtails and puddles

The truck now yaws farther and carries sideways momentum through quick steering reversals. It stays upright: the chassis has no sideways roll. Mateo counterbalances the movement from the bed.

Reflective puddles appear on the highway. Each leaves room to drive around it. Hitting one throws water from the wheels, briefly lowers GRIP and kicks the truck into a sideways glide. More speed means a harder kick; brake and countersteer to recover. Better tires reduce the kick. Water alone does not remove hull, but sliding into debris can. Later fronts bring puddles more frequently.

Pause freezes the slide. A checkpoint or retry clears the water and restores grip before handing control back. Calm FX reduces spray and camera movement without changing driving rules.

## Mission and score

Survive 90 seconds of driving and transmit at least three probes. Stay 450–1150 meters behind the tornado to charge a probe, then send it with Space. Boost closes the gap; braking increases it. Cinematics and upgrade menus freeze the mission timer.

| Front | Driving time | Cruise speed | Road debris |
|---|---|---|---|
| Prairie Approach | 0–30 seconds | 146 mph | Crates, drums, tires, roofing |
| Barn Breakout | 30–60 seconds | 162 mph | Red timber, doors, braces, galvanized roofing |
| Warehouse Collapse | 60–90 seconds | 178 mph | Concrete, rebar, steel, cladding |

Boost reaches 240 mph. Later fronts increase debris speed, spawn frequency and crosswind. Road hazards cause damage; the overhead semi and cow are cinematic near misses.

DATA is the score: 1,500 per probe; 100–500 per close dodge; 20/30/40 each second in tracking range; 5 per second outside it; 300 per supply; and remaining hull ×20 on victory. The local top five keeps one entry per expedition, marks retries and retains the better result. It is not an online leaderboard.

## Checkpoints and films

At 30 and 60 driving seconds, choose repair, better tires or a larger boost tank. Then the matching six-second Grok barn or warehouse destruction video plays. Its audio takes over while gameplay is frozen. Playback completion saves the checkpoint and fades back to the faster front. If video playback is unavailable, the original 8.6-second in-engine destruction scene plays instead.

The supplied Grok films are 910×512 at 30 fps and do not contain Mateo. Mateo remains in live gameplay and in the in-engine fallback scenes. Their original camera angles and truck movement have not been regenerated. The trailer, six dodge celebrations and final-crash film retain their existing Higgsfield footage and embedded sound.

Space, Enter, Escape, controller A/B/X/Start or Keep Chasing skips a checkpoint. Skipping saves it without sending a probe. Retry Checkpoint [R] or Resume Checkpoint restores the entry score, probes, hull and upgrades. Failed-attempt gains are discarded, and the upgrade/movie does not repeat on retry. New Chase clears the checkpoint; victory retires it. Saves stay on the device and depend on browser site-data retention in Web builds.

The six item-dodge films celebrate good moves; they are reusable clips rather than exact replays. They can be disabled in the menu. The final hull impact still plays the existing cinematic before Game Over.

## ElevenLabs sound and vibration

Nineteen generated audio categories replace the gameplay sound palette and music: engine, wind/rain, wet skids, turbo loop and surge, splash, directional flyby, heavy semi pass, cow, thunder, generic/wood/metal hits, lens strike, probe, supply, dodge confirmation, UI click and chase score. One-shot takes rotate to reduce repetition. Loops have smoothed seams; the mix has a peak limiter. Generation IDs and processing details are in assets/audio/elevenlabs-manifest.json. No online generation happens while playing.

Vibration can be switched off on the title and pause screens. Puddles request an 85 ms pulse and collisions request 150 ms, with a cooldown. Native Android needs the VIBRATE permission, enabled in the setup preset. Godot also supports native iOS and compatible Web browsers; mobile Safari does not support this game's standard Web vibration path. Unsupported targets safely ignore it. Physical phone vibration has not been tested here.

Technical references: https://docs.godotengine.org/en/4.5/classes/class_input.html#class-input-method-vibrate-handheld and https://developer.mozilla.org/en-US/docs/Web/API/Navigator/vibrate

## Preview and verification

The v0.8 preview records the actual Godot renderer and game audio. Its first chapter uses recorded controller inputs to deliberately drive through naturally spawned puddles. Its checkpoint chapter uses the normal automated driver, with unshown driving simulated between chapters. There are no score, health or probe grants. The edit is shorter than a complete mission. Films shown inside the capture are the actual prerecorded overlays played by the app.

Run the current behavior checks with:

```
godot --headless --path . --script res://tools/verify_driving.gd -- --test
godot --headless --path . --script res://tools/verify_checkpoints.gd -- --test
```

These use isolated test settings and do not alter the player's saves. See VALIDATION-v0.8.md for results and platform limits. The source was recovered from the intact v0.7 release package after the earlier source archive proved incomplete; RECOVERY.md explains the provenance.
