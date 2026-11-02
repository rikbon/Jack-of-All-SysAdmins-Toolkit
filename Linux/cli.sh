#!/usr/bin/env bash

# Shared CLI helpers for Linux and macOS
# Mirrors macOS/cli.sh so both platforms expose the same interface.

cli_help_requested() {
    [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]
}

cli_quiet_requested() {
    [[ "${1:-}" == "--quiet" || "${1:-}" == "-q" ]]
}

cli_usage_error() {
    printf 'Unknown option: %s\n' "$1" >&2
    return 2
}
