#!/usr/bin/env bash
# Runs every tools/verify_*.gd suite and fails if any check fails or any suite
# crashes. Used by .github/workflows/verify.yml and runnable by hand:
#
#   GODOT=/path/to/Godot_v4.5.1-stable_linux.x86_64 tools/run_suites.sh
#
set -uo pipefail
GODOT="${GODOT:-godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGS="$ROOT/.suite-logs"
mkdir -p "$LOGS"

total=0
failed_checks=0
broken=()

printf '%-26s %8s %9s\n' "SUITE" "CHECKS" "FAILURES"
printf -- '-------------------------------------------\n'

for path in "$ROOT"/tools/verify_*.gd; do
	name="$(basename "$path" .gd)"
	log="$LOGS/$name.log"
	timeout 600 "$GODOT" --headless --path "$ROOT" --script "res://tools/$name.gd" -- --test >"$log" 2>&1
	# The suites report their own tally. A missing tally means the suite crashed
	# or hung before finishing, which is a failure even if the exit code is 0.
	summary="$(grep -oE '[A-Z_]+_TESTS [0-9]+ checks; [0-9]+ failures' "$log" | head -1)"
	if [[ -z "$summary" ]]; then
		printf '%-26s %8s %9s\n' "$name" "-" "NO SUMMARY"
		broken+=("$name")
		continue
	fi
	checks="$(sed -E 's/.*TESTS ([0-9]+) checks.*/\1/' <<<"$summary")"
	fails="$(sed -E 's/.*; ([0-9]+) failures.*/\1/' <<<"$summary")"
	printf '%-26s %8s %9s\n' "$name" "$checks" "$fails"
	total=$((total + checks))
	failed_checks=$((failed_checks + fails))
	[[ "$fails" != "0" ]] && broken+=("$name")
done

printf -- '-------------------------------------------\n'
printf '%-26s %8s %9s\n' "TOTAL" "$total" "$failed_checks"

if ((${#broken[@]})); then
	echo
	echo "Failing suites: ${broken[*]}"
	for name in "${broken[@]}"; do
		echo
		echo "===== $name ====="
		grep -E '^FAIL|SCRIPT ERROR|Parse Error' "$LOGS/$name.log" | head -30
	done
	exit 1
fi

echo
echo "All suites passed."
