"""Run Godot with a private local Xvfb display for software-rendered QA."""
import os
import pathlib
import secrets
import shutil
import socket
import struct
import subprocess
import sys
import time

workspace = pathlib.Path(__file__).resolve().parents[2]
env = os.environ.copy()
env["DISPLAY"] = "127.0.0.1:109"
env["LIBGL_ALWAYS_SOFTWARE"] = "1"
portable = workspace / "tools/display/root"
xvfb = shutil.which("Xvfb") or str(portable / "usr/bin/Xvfb")
if portable.exists():
    env["LD_LIBRARY_PATH"] = str(portable / "usr/lib/x86_64-linux-gnu") + ":" + env.get("LD_LIBRARY_PATH", "")
    env["XKB_BINDIR"] = str(portable / "usr/bin")
godot = os.environ.get("STORM_GODOT", str(workspace / "tools/Godot_v4.5.2-stable_linux.x86_64"))
project = os.environ.get("STORM_PROJECT_PATH", str(workspace / "storm-chaser"))
env.setdefault("STORM_CAPTURE_DIR", str(workspace / "review"))
auth = workspace / "tools/display/qa.xauth"
auth.parent.mkdir(parents=True, exist_ok=True)
def field(value):
    return struct.pack(">H", len(value)) + value
auth.write_bytes(struct.pack(">H", 65535) + field(b"") + field(b"109") + field(b"MIT-MAGIC-COOKIE-1") + field(secrets.token_bytes(16)))
auth.chmod(0o600)
env["XAUTHORITY"] = str(auth)
with (workspace / "tools/xvfb.log").open("w") as log:
    display = subprocess.Popen([xvfb, ":109", "-screen", "0", "1280x720x24", "-nolisten", "unix", "-nolisten", "local", "-listen", "tcp", "-noreset", "-auth", str(auth)], env=env, stdout=log, stderr=log)
    try:
        for _ in range(30):
            if display.poll() is not None:
                raise RuntimeError("Display server failed; see tools/xvfb.log")
            try:
                connection = socket.create_connection(("127.0.0.1", 6109), timeout=0.1)
                connection.close()
                break
            except OSError:
                pass
            time.sleep(0.1)
        result = subprocess.run([godot, "--path", project, *sys.argv[1:]], env=env)
        sys.exit(result.returncode)
    finally:
        display.terminate()
        display.wait(timeout=10)
        auth.unlink(missing_ok=True)
