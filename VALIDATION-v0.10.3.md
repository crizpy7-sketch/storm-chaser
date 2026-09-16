# Storm Chaser v0.10.3 — Validation

203 gameplay checks pass: 21 driving, 27 polish, 98 checkpoint and 57 route checks. These include normal and assisted full-campaign completion, all four checkpoint movie mappings, replay persistence and save compatibility.

New shortcut checks compare a 122 mph turn with a 68 mph braking turn. The faster turn produces sustained lateral drift; braking reduces it. An input-driven steering recovery keeps the truck within the lane, while no steering sends it onto the outer shoulder. Peak yaw remains below 0.13 radians, the original truck vertices remain unchanged, and turn momentum settles after the exit. Restart/checkpoint entry clears the drift state. The field mesh is checked for overturned triangles at the tight bend.

In the isolated turn check, the controlled truck stays within 0.129 normalized lane units; the unattended truck reaches the outer 1.2 limit. These are controlled software checks, not a promise of identical player outcomes. The standard automated full campaign completes with 17 probes, approximately 50,337 data and a full hull after normal repairs and pickups.

Visual review covers the asphalt approach, drift apex, lighter muddy track, wet wheel ruts and puddles. The release preview records the actual exported Linux game, with the stronger slide and subsequent dirt driving. It contains no AI movie segment. Package CRCs, source contents and native binary matches are verified during packaging; the preview's video and audio streams are decoded for errors.

Windows/Galaxy Book2 hardware, browser performance and mobile controls/vibration still need device testing. No mobile package is included. Existing ObjectDB/resources-in-use messages occur at engine shutdown; no gameplay script or shader compilation errors are accepted. No generation credits were spent.
