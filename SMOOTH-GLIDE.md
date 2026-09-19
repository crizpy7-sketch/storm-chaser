# Smooth glide — 0.8.1

The rear-view truck art was visibly distorted by large rotation angles in 0.8.0. This patch caps the heading at 7.5 degrees, smooths its response independently of sideways travel, increases fishtail damping and reduces the rotational impulse from puddles. Water still causes a real lateral glide with countersteer/brake recovery.

All 21 driving/audio checks and 46 checkpoint checks pass. Rapid steering reversals also check for abrupt heading changes. Windows, Web and phone device testing remain outstanding.
