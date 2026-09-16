# Storm Chaser v0.9.1 — Validation

## Scope

This release restores the original detailed truck artwork and fixed depth mapping. The driving simulation, yaw limit, puddle physics, scoring, checkpoint rules, voice reactions, gallery and driving settings retain their v0.9 behavior. The truck and Mateo share the damped suspension parent. Hull damage adds tailgate scuffs and taillight flicker without deforming the artwork.

## Automated checks

Godot 4.5.2 headless, isolated test settings:

- Driving: 21 checks passed.
- Checkpoints: 46 checks passed, including normal mission completion.
- Polish: 27 checks passed, including the restored artwork, fixed geometry, shadow-only support model, bounded suspension, damage and repair, settings, gallery state and assisted mission completion.

Total: **94 checks, zero failures**. Existing truck-specific assertions were updated for the restored artwork. The prior independent visible wheel and antenna geometry is no longer used.

## Visual and build review

A fresh 18-second recording runs the actual game through the normal controller-input path with automatic films disabled. It includes driving, puddles, overhead debris and Mateo. No new generated cinematic is included. The original truck appearance and its placement with Mateo were inspected in the rendered frames.

Windows, Linux, Web and source archives are rebuilt with version 0.9.1. ZIP CRC verification is part of packaging. The source ZIP uses ordinary Godot export-template settings. Source and exported-Linux rendering are checked separately.

## Limits

The preview is an offline 1280×720 recording at 30 frames per second, not a device performance benchmark. Galaxy Book2, Windows hardware, browsers and phones still require device testing. This is not a signed mobile release.

Godot continues to report existing ObjectDB/resources-in-use warnings at shutdown. No script or shader compile errors are accepted in the rendering or export checks.

The release reuses the existing art, audio and cinematic assets. It generates no new Higgsfield or ElevenLabs media and spends no generation credits.
