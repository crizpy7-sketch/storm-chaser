# Storm Chaser v0.13.1 validation

376 checks pass: driving 21, polish 27, checkpoints 176, route 71, finale 50, weight 13, storm art 13, rigid truck 5. New regression checks require a planar body mesh, stable original artwork across sustained left/right slip and jump transitions, straight projected edges at both yaw extremes with camera lag, registered tailgate geometry and a shared parent for Mateo. Storm-art tests now require stable silhouettes, rather than treating unregistered frame swaps as correct behavior.

Visual review covers alternating left/right steering, a collision, off-road jump movement and the tornado approach. Preview uses actual gameplay with scripted inputs, selected stages and an automated off-road driver. It is not a natural full campaign run or a hardware frame-rate benchmark. Windows is exported, not executed on a Windows computer here.

Known pre-existing shutdown resource-cleanup warnings remain in the test/capture harness. No gameplay script or shader errors are accepted. The truck remains illustrated artwork on a rigid surface, not a complete 3D vehicle model; extreme cinematic camera angles retain that limitation.
