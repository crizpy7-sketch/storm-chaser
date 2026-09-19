# v0.15.0 validation

Ten suites pass 407 checks: driving 21, polish 27, checkpoints 176, route 71, finale 50, weight 13, storm art 4, road margin 14, truck 3D 16, landscape 15. Zero failed assertions. Logs are in validation/v0.15.0.

New checks cover pause stability, scene-time breakup, reuse/reset, bounded node pools, single rupture sound, hill grounding, the square junction, reduced effects and lighter graphics. Approved truck geometry still passes its 67,656-triangle and immutable-vertex checks.

Visual capture covers highway fire sites, torn roof sheets, the semi flyby, curves and hillside ruins. Preview uses actual engine rendering, selected stages and the automated driver; it is not a hardware frame-rate benchmark. The ground palette, textured ruin materials and multi-strand fire shader were inspected in driving-camera captures.

Limitations: scenery destruction is deterministic visual animation, not a general rigid-body destruction solver. Semi fragments are overhead spectacle and do not add new collision damage. Existing hazards still apply the game's collision rules. Physical Windows/Galaxy Book2/TV/controller playtest remains pending. Headless test teardown reports existing looping audio resources still in use; passing assertions do not certify physical hardware performance.
