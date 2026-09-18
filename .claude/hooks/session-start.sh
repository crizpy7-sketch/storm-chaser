#!/bin/bash
# SessionStart hook: make `tools/run_suites.sh` runnable the moment a cloud
# session opens.
#
# This project has no package manager. Its one dependency is the Godot engine
# itself, pinned to the same version .github/workflows/verify.yml uses, and its
# one piece of generated state is the import cache in .godot/, which is
# gitignored and so is absent from a fresh clone. Without both, the first thing
# anyone does in a new session is spend several minutes downloading an engine
# by hand before a single one of the checks can run.
#
# Idempotent: an engine already on disk is not downloaded again, and the
# container state is cached after this completes, so later sessions skip
# straight past the download.
set -euo pipefail

# Cloud sessions only. A developer's own machine already has the Godot they
# chose, and this has no business reaching in and changing that.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# Keep this in step with GODOT_VERSION in .github/workflows/verify.yml, so what
# runs here is what CI runs.
GODOT_VERSION="${GODOT_VERSION:-4.5.1-stable}"
GODOT_HOME="$HOME/godot"
GODOT_BIN="$GODOT_HOME/Godot_v${GODOT_VERSION}_linux.x86_64"

if [ ! -x "$GODOT_BIN" ]; then
  echo "Installing Godot ${GODOT_VERSION}..."
  mkdir -p "$GODOT_HOME"
  url="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
  # Fail loudly rather than leaving a session to discover halfway through that
  # it has no engine. The message has to say what to do next, because whoever
  # reads it is starting cold.
  if ! curl -sSfL --retry 3 -o /tmp/godot.zip "$url"; then
    echo "Could not download Godot ${GODOT_VERSION} from ${url}" >&2
    echo "Install it by hand into ${GODOT_HOME} and export GODOT to the binary," >&2
    echo "or check that the release exists for this version." >&2
    rm -f /tmp/godot.zip
    exit 1
  fi
  unzip -q -o /tmp/godot.zip -d "$GODOT_HOME"
  # Writable disk is a fixed per-session allowance; the archive is 50 MB of it.
  rm -f /tmp/godot.zip
  chmod +x "$GODOT_BIN"
else
  echo "Godot ${GODOT_VERSION} already installed."
fi

# tools/run_suites.sh reads $GODOT, so exporting it here means the suites run as
# `tools/run_suites.sh` with nothing in front of them.
if [ -n "${CLAUDE_ENV_FILE:-}" ] && ! grep -qs "^export GODOT=" "$CLAUDE_ENV_FILE"; then
  echo "export GODOT=\"$GODOT_BIN\"" >> "$CLAUDE_ENV_FILE"
fi

# Build the import cache. A first import always reports the optional audio and
# film files this source package omits; the suites skip those checks rather than
# fail, so a non-zero status here is expected and not fatal -- the same reason
# the CI workflow ignores it.
if [ ! -d "$PROJECT_DIR/.godot" ]; then
  echo "Importing project resources..."
  "$GODOT_BIN" --headless --path "$PROJECT_DIR" --import >/dev/null 2>&1 || true
fi

echo "Ready: GODOT=$GODOT_BIN  ->  tools/run_suites.sh"
