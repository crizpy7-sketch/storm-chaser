# Storm Chaser v0.13.2 validation

390 checks pass across driving (21), polish (27), checkpoints (176), route (71), finale (50), weight (13), storm art (13), rigid truck (5), and road margin (14).

Road margin tests sustain steering, outward wind and initial slide toward both edges for three seconds at 30/60/120 FPS. They verify the full 1.85-unit body half-width plus 0.40-unit clearance fits on pavement, countersteering exits the edge, outward response eases near the limit, and dirt retains the 1.2 normalized envelope. This changes the paved-road driving boundary; it does not re-center the truck automatically or remove steering/slip.

The 15-second native Linux preview uses actual gameplay, selected stages, scripted target-lane steering and an automated driver. It is not an uninterrupted campaign or a hardware frame-rate benchmark. Windows and Web are exported, not hardware/browser-playtested here. Known pre-existing harness shutdown resource warnings remain. See validation/v0.13.2 for logs and screenshots.
