# Storm Chaser v0.10.0 — Validation

## Gameplay checks

- Driving: 21 checks covering original fishtail, puddles, grip, braking, sound, pause and checkpoint resets.
- Polish: 27 checks covering original truck art and geometry, suspension, damage, settings, sound, gallery and full assisted campaign completion.
- Checkpoints: 46 checks covering both existing movies, skip/focus/fallback behavior, seven-level checkpoint order, a full standard campaign, scoring and victory.
- Route: 49 checks covering path continuity, the ninety-degree shortcut, narrower dirt, speed-dependent curve drift, jumps and landings, brake control, elevated debris, airborne collisions and puddles, new previews/retries, a distance-based tornado circle, pause/resume, finale rewards, the three-probe objective and older saves.

At cruise speed, isolated level-six physics reached approximately 3.43 m above the descending ground; level seven reached approximately 8.81 m. Both landed again. The same hills at the 68 mph braking speed produced no launches. These are game-space values, not a vehicle engineering simulation.

The standard automated full campaign earned approximately 49,537 data with 17 probes and completed all seven checkpoints. It used the normal collision, repair/pickup, steering, score and progression rules. Assisted completion was also checked. This confirms the route is completable by the automated driver, not that every player will find its difficulty balanced.

## Visual and delivery checks

The live renderer is reviewed at the curved highway, shortcut, small hills, big jumps, combined hills/curves, tornado circle and suction. The preview records actual Godot gameplay with unshown portions simulated between highlights. The last cinematic and results are also captured from the exported Linux build. No generated trailer is substituted for gameplay.

Windows, Linux, Web and editable-source packages are exported as v0.10.0. ZIP CRCs and the source version are checked during packaging. The preview is encoded as 1280×720 H.264/AAC at 30 recorded frames per second and is checked for valid video/audio streams.

## Practical limits

This remains a 2.5D Godot game using the existing illustrated truck, character and camera-facing tornado artwork. The final camera moves through 3D space; it is not a newly generated Higgsfield movie or a fully volumetric fluid simulation. Long-range terrain is simplified and merges into the distant field. Visual tire motion is artistic tread scrolling, not measured RPM.

Offline software rendering is not a device-performance measurement. Galaxy Book2, Windows hardware, web browsers, Android/iOS, multitouch and phone vibration need device testing. The lighter graphics option remains available. No signed mobile build is included.

Pre-existing resource/ObjectDB warnings occur at engine shutdown. Runtime script and shader compilation errors are not accepted. No new AI assets or generation credits were used.
