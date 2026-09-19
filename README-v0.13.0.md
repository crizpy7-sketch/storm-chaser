# Storm Chaser v0.13.0 — Storm in Motion

Seven new reference-matched truck sprites join the original straight view: light left/right steering, stronger left/right drift, takeoff, descent, and landing compression. They follow actual steering, slip, vertical velocity and suspension state. A short hold and hysteresis prevent rapid switching. The original truck geometry stays fixed; Mateo remains a separate character, with an adjusted seat height in airborne views.

A new cinematic funnel replaces the old tornado image. Its subdivided surface bends and sways progressively with height while the ground contact stays anchored; rising objects follow the same wind bend. Timber, roofing, cows and an 18-wheeler are dragged inward from ground level and spiral upward. Twelve dust layers circle its base. The distant destruction effects are visual; existing gameplay hazards still determine collisions and damage. Lighter Graphics halves those object and dust counts. Pausing freezes their scene time.

All v0.12 handling, roads, saved checkpoints, scores and approved movies are retained. No new Higgsfield or ElevenLabs generation was used. The preview is actual exported Godot gameplay, with scripted steering and automated driving across selected stages, not a prerecorded trailer or full campaign.

371 automated checks pass: the prior 358 plus 13 new movement/storm checks. The Windows build still needs a laptop playtest for the new presentation and performance. The rendering remains a hybrid of sprites and 3D scenery, not a fully 3D truck or simulated fluid tornado.
