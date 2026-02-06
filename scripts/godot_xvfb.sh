#!/usr/bin/env bash
set -euo pipefail

# Wrapper to run Godot under Xvfb on CI.
# Some runner environments can segfault during export without a display server.

exec xvfb-run -a godot "$@"
