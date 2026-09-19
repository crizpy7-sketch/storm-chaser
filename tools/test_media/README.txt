stand_in_film.ogv is a 10 KB, 24-second 64x36 Theora test pattern (ffmpeg testsrc2).

The verify_*.gd suites use it only when the real prerecorded films are missing (for
example in a trimmed review copy), so checkpoint, finale and gallery playback logic
is still exercised. It is never used by the game itself, and tools/* is excluded
from every export preset. With the complete media pack installed, the suites use the
real films and report no skipped checks.
