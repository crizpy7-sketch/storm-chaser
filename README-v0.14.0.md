# Storm Chaser v0.14.0 — Interceptor in 3D

The orange storm-chaser pickup is now a solid 3D mesh with a cab, bed, hood, undercarriage, armor, four separate wheels, cage, dish, beacons, antennas and equipment cases. Body panels and equipment reuse details from the approved artwork. The tailgate has actual depth and uses the original tailgate texture. This is an original mesh reconstruction of the design, not an exact scanned replica.

Front wheels steer, all four wheel meshes spin by distance, and wheels extend during jumps. The chassis compresses on landings with restrained rigid-body lean; no truck vertices are warped or replaced by alternate sprites. Brake lights and beacons respond to the game. Mateo's existing approved character art and reactions remain attached inside the bed.

This release upgrades the visible truck and its articulation. Travel, drifting, jumps and collisions still use the established campaign controller; the researched raycast tire controller has not been integrated yet. The truck model is prepared with independent wheel pivots for that next step. The full campaign, cinematic rewards, controls, audio, settings and checkpoint saves remain available.

392 automated checks pass across nine suites, including 16 new model/articulation checks. Actual Godot captures cover the truck from all sides and its use during curves, hills and the tornado approach. The Windows executable is exported, but has not been playtested on the Galaxy Book2 in this session.

The separate Interceptor-07-3D.glb is a self-contained 3D asset. Its source construction script is tools/build_interceptor_3d.gd. The game loads assets/models/interceptor-3d.tscn, with steering and suspension articulation in scripts/truck_rig.gd. See VALIDATION-v0.14.0.md for validation and remaining scope.

