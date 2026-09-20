#!/usr/bin/env bash
# Exercise the runner without Godot or changes to the real project.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_parent="$(cd "${TMPDIR:-/tmp}" && pwd -P)"
temp_root="$(mktemp -d "$temp_parent/storm-chaser-runner.XXXXXXXX")"
cleanup() {
	# Only remove the exact temporary directory created by this test.
	if [[ -d "$temp_root" && "$(cd "$temp_root" && pwd -P)" == "$temp_parent"/storm-chaser-runner.* ]]; then
		rm -rf -- "$temp_root"
	fi
}
trap cleanup EXIT
mkdir "$temp_root/tools"
cp "$ROOT/tools/run_suites.sh" "$temp_root/tools/"
touch "$temp_root/tools/verify_probe.gd"
cat >"$temp_root/fake-godot" <<'FAKE'
#!/usr/bin/env bash
case "$PROBE_CASE" in
	pass) echo 'PROBE_TESTS 4 checks; 0 failures; 2 skipped' ;;
	pass_digits) echo 'TRUCK_3D_TESTS 4 checks; 0 failures; 67656 triangles' ;;
	crash) echo 'PROBE_TESTS 4 checks; 0 failures'; exit 23 ;;
	timeout) echo 'PROBE_TESTS 4 checks; 0 failures'; exit 124 ;;
	script_error) echo 'SCRIPT ERROR: Invalid call'; echo 'PROBE_TESTS 4 checks; 0 failures' ;;
	parse_error) echo 'Parse Error: Invalid syntax'; echo 'PROBE_TESTS 4 checks; 0 failures' ;;
	no_summary) echo 'The suite stopped before reporting its result.' ;;
	failed_check) echo 'PROBE_TESTS 4 checks; 1 failures' ;;
	multiple) echo 'OTHER_TESTS 1 checks; 0 failures'; echo 'PROBE_TESTS 4 checks; 1 failures' ;;
esac
FAKE
chmod +x "$temp_root/fake-godot"

checks=0
for probe in pass pass_digits crash timeout script_error parse_error no_summary failed_check multiple; do
	status=0
	PROBE_CASE="$probe" GODOT="$temp_root/fake-godot" bash "$temp_root/tools/run_suites.sh" >"$temp_root/result" 2>&1 || status=$?
	if [[ "$probe" == pass || "$probe" == pass_digits ]]; then
		if ((status != 0)) || ! grep -q 'All suites passed.' "$temp_root/result"; then
			cat "$temp_root/result"
			echo 'FAIL: a successful suite must pass'
			exit 1
		fi
	elif ((status == 0)) || grep -q 'All suites passed.' "$temp_root/result"; then
		cat "$temp_root/result"
		echo "FAIL: $probe must fail the runner"
		exit 1
	fi
	checks=$((checks + 1))
	echo "PASS: $probe"
done
echo "RUNNER_REGRESSIONS $checks checks; 0 failures"
