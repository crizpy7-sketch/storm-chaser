# Project recovery

The stored v0.7 source ZIP ended partway through assets/cinematics/storm-film.ogv and lacked a ZIP central directory. It could not be opened as a complete source archive.

The intact v0.7 Linux release was verified and extracted using GDRETools 2.6.4. All 118 packaged files passed verification. All nine GDScript files were recovered with no decompilation failures, and 47 resources converted without failures. Twenty-four resource conversions were marked lossy by the recovery tool. Ninety-one CRC-verified original files from the partial source ZIP were then restored over the recovered copies where available.

The recovered project imported in Godot 4.5.2, loaded Mateo and all six dodge films, and completed the normal 90-second mission. The current checkpoint and driving checks are included under tools. Comments, original source-only tooling and the old export presets could not be recovered; current tools/presets were rebuilt. Historical validation notes describe earlier builds, not a rerun of missing historical test scripts.

The new source ZIP must be fully closed and CRC-tested before distribution. Do not upload an archive while it is still being written.
