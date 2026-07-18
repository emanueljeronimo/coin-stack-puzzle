#!/usr/bin/env bash
set -euo pipefail

if command -v godot >/dev/null 2>&1; then
  GODOT_BIN="godot"
elif command -v godot4 >/dev/null 2>&1; then
  GODOT_BIN="godot4"
else
  echo "Godot executable not found (expected godot or godot4)."
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TEST_SCRIPTS=(
  "res://tests/cycle_reset_test.gd"
  "res://tests/crash_stress_test.gd"
  "res://tests/game_engine_test.gd"
  "res://tests/game_board_engine_test.gd"
  "res://tests/game_fusion_engine_test.gd"
  "res://tests/game_session_service_test.gd"
  "res://tests/game_slot_service_test.gd"
  "res://tests/game_rules_test.gd"
  "res://tests/game_turn_engine_test.gd"
  "res://tests/game_economy_service_test.gd"
  "res://tests/integration_gameplay_progression_test.gd"
  "res://tests/integration_runtime_resume_test.gd"
  "res://tests/integration_stack_flow_test.gd"
  "res://tests/integration_turn_economy_flow_test.gd"
)

FAILURES=0
for script in "${TEST_SCRIPTS[@]}"; do
  echo "==> Running $script"
  set +e
  output="$($GODOT_BIN --headless --path . --script "$script" 2>&1)"
  status=$?
  set -e
  echo "$output"
  if [[ "$status" -ne 0 ]] || echo "$output" | grep -Fq "Failed to load script \"$script\""; then
    echo "FAILED: $script"
    FAILURES=$((FAILURES + 1))
  fi
  echo
done

if [[ "$FAILURES" -gt 0 ]]; then
  echo "Test run finished with $FAILURES failure(s)."
  exit 1
fi

echo "All tests passed."
