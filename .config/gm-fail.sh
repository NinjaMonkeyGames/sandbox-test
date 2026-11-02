#!/bin/bash

# Log path: first argument if given, otherwise test_output.log at the workspace root,
# which is where the "Run tests under Xvfb" step writes it (independent of the project folder name).
LOG_FILE="${1:-${GITHUB_WORKSPACE:-.}/test_output.log}"

if [ -z "$LOG_FILE" ] || [ ! -f "$LOG_FILE" ]; then
  echo "Error: Log file not provided or does not exist: '$LOG_FILE'"
  exit 1
fi

# Use the LAST summary line, in case the log contains more than one run.
# grep -a (treat as text): the captured output can contain NUL / non-UTF8 bytes, which makes plain
# grep print "binary file matches" instead of the matching line.
SUMMARY=$(grep -a "UNIT TESTS COMPLETE:" "$LOG_FILE" | tail -n 1 | tr -d '\r')

if [ -z "$SUMMARY" ]; then
  echo "Error: no 'UNIT TESTS COMPLETE' summary line found. The tests did not run to completion."
  exit 1
fi

# Extract the number in front of "failed", e.g. "UNIT TESTS COMPLETE: 185 passed, 0 failed."
FAILED=$(echo "$SUMMARY" | sed -n 's/.* \([0-9][0-9]*\) failed.*/\1/p')

if [ -z "$FAILED" ]; then
  echo "Error: could not read the failed count from the summary line."
  exit 1
fi

if [ "$FAILED" -gt 0 ]; then
  echo "$SUMMARY"
  echo "Test failure detected: $FAILED failed."
  grep -an "\[FAIL\]" "$LOG_FILE"   # Show which tests failed.
  exit 1
fi

exit 0 # Success is silent: the step simply passes.