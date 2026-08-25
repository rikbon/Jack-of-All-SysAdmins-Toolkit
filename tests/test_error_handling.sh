#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

source "$ROOT/Linux/globals.sh"

if run_logged 'expected failure' false >/dev/null 2>&1; then
    printf 'FAIL: run_logged propagates command failure\n' >&2
    exit 1
fi
printf 'PASS: run_logged propagates command failure\n'

if require_command command-that-does-not-exist >/dev/null 2>&1; then
    printf 'FAIL: require_command rejects missing commands\n' >&2
    exit 1
fi
printf 'PASS: require_command rejects missing commands\n'

cat > "$TEMP_DIR/failing.sh" <<'SCRIPT'
#!/usr/bin/env bash
exit 23
SCRIPT
chmod +x "$TEMP_DIR/failing.sh"

if bash "$TEMP_DIR/failing.sh"; then
    printf 'FAIL: failing child script returns nonzero\n' >&2
    exit 1
fi
printf 'PASS: failing child script returns nonzero\n'

printf 'All error-handling tests passed.\n'
