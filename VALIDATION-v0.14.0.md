# v0.14.0 — 3D truck validation

The nine current Godot suites pass 392 checks with zero assertion failures. These checks cover source scene loading and game logic, not physical hardware performance.

- verify_truck_3d: 16
- verify_route: 71
- verify_weight: 13
- verify_polish: 27
- verify_storm_art: 4
- verify_road_margin: 14
- verify_finale: 50
- verify_checkpoints: 176
- verify_driving: 21

The old flat-plane-only truck assertions were replaced because the user explicitly requested a solid 3D vehicle. Their no-distortion requirement is retained: every mesh's vertex data stays unchanged through steering, yaw, pitch, and landings. Body scale remains one, steering and wheel spin use separate pivots, and the rear wheels do not steer. Existing route, recovery, road-margin, movie, score and save checks still pass. verify_rigid_truck is a compatibility entry point for verify_truck_3d, not an additional counted suite.

The model exports as a GLB with 49,002 triangles and 36 mesh/material batches before Mateo. It retains named front/rear wheel pivots and a sprung body. A construction issue mixing indexed primitives with unindexed triangles was fixed; the triangle completeness check guards against dropped mesh faces.

New captures are actual Godot renders. The turntable is a model presentation; gameplay footage uses selected stages and scripted steering/automated input. These are not AI-generated trailers, hardware FPS benchmarks, or a full manual campaign playtest. Imported texture and mesh source can be regenerated locally without paid generation services.

Known scope: the free vehicle-physics controller is not installed in the campaign. Four-wheel articulation here is driven by the existing speed/input/route state, not new contact-force simulation. Mateo remains approved animated 2D art, attached to the 3D truck. No Galaxy Book2, mobile, or physical-gamepad testing was performed in this session. Some headless shutdowns report resources still in use; suite exits and gameplay assertions pass.

Godot export APIs used for the standalone model: https://docs.godotengine.org/en/4.5/classes/class_gltfdocument.html
