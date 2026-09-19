# Storm Chaser v0.16.0 — Solid Impact and Shelter Corridor

Road debris now uses continuous swept oriented collision against the truck’s rigid body, cab, bed and wheel boxes. A visible strike stops at the actual contact point, subtracts hull and speed, compresses suspension, kicks the body as one piece, emits contact fragments and can only damage once. Clean side clearance and high jumps remain safe. The large semi stays a distant cinematic set piece, but one roof sheet it sheds becomes a real falling hazard that can be dodged or hit.

Four roadside ground shelters add twelve articulated civilians. People run from damaged homes along off-road paths, enter a recessed hatch, then the hatch closes. They never enter the highway or become hazards; their animation freezes with the game clock and resets cleanly when scenery streams away. Hills use the same terrain elevation field as the route.

The approved modern orange 3D truck and Mateo remain unchanged. The next upgrade is a Mateo Garage for paint, wheels, equipment, armor and suspension customization; it is documented in `NEXT-UPGRADE.md` but not included in this build.

## Controls

A/D or arrows steer; W/Shift/Up boosts; S/Down brakes; Space transmits a charged probe; P/Escape pauses; C hides the HUD; F11 toggles fullscreen. A controller uses the left stick/D-pad, A boost, B brake, X probe and Start pause.

Windows/Galaxy Book2: extract the Windows ZIP and run `Storm-Chaser.exe`. Linux: run `Storm-Chaser.x86_64`. Web: serve the complete Web folder over HTTP(S). Physical Windows, Galaxy Book2, controller, TV and browser performance still need the user’s playtest.
