# v0.14.2 validation

Nine suites: 392 passed, zero failed. Complete model: 67,656 triangles and 39 mesh batches. Both original orange and newly mapped body materials receive damage. CPU mesh vertices remain unchanged through steering and landings.

Actual Godot turntable and gameplay captures use the revised model. Source texture references are embedded in the standalone GLB. Native Windows/Linux and Web builds exported. No new physical hardware performance benchmark or Windows laptop playtest. Existing route-based driving retained.

The gameplay capture exposed a clearcoat shader identifier incompatible with this engine binary. It was changed to CLEARCOAT_ROUGHNESS, confirmed in the local Godot runtime. Final exports and captures are rebuilt after this correction.
