#!/bin/bash
# Wrapper for opencode that resets terminal state after exit (including SIGKILL).
# Place this as 'opencode' next to 'opencode-core.exe' in the install directory.
#
# Why: terminal mouse tracking and Kitty keyboard protocol are modes set on the
# terminal emulator, not the process. If opencode is killed (SIGKILL/OOM), these
# modes remain enabled and produce garbage characters in the shell. This wrapper
# always runs cleanup after the child process exits, regardless of how it died.

DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")"

# Detect non-TUI commands that don't need terminal reset
NO_RESET=false
for arg in "$@"; do
  case "$arg" in
    --version|--help|-h|-v|version|help) NO_RESET=true; break ;;
  esac
done

"$DIR/opencode-core.exe" "$@"
EXIT_CODE=$?

# Reset terminal state after TUI session - covers SIGKILL of child process
if [ "$NO_RESET" = false ] && [ -t 1 ]; then
  printf '\x1b[?1000l\x1b[?1002l\x1b[?1003l\x1b[?1006l\x1b[?1049l\x1b[?25h\x1b[>4;0m\x1b[?2004l' 2>/dev/null
  stty sane 2>/dev/null
fi

exit $EXIT_CODE
