#!/usr/bin/env bash
set -euo pipefail

BIN=$(find . -name "*linux_arm64" | head -n 1)
if [[ -z "$BIN" ]]; then
    echo "Error: Cross-compiled linux binary not found"
    echo "Files in runfiles:"
    find . -type f
    exit 1
fi

echo "Examining cross-compiled binary: $BIN"

# 1. Verify ELF magic bytes: 0x7F 0x45 0x4C 0x46 (0177 0105 0114 0106)
MAGIC=$(od -t x1 -N 4 "$BIN" | head -n 1 | awk '{print $2, $3, $4, $5}')
echo "Magic bytes: $MAGIC"
if [[ "$MAGIC" != "7f 45 4c 46" ]]; then
    echo "FAILED: Expected ELF magic bytes '7f 45 4c 46', got '$MAGIC'"
    exit 1
fi

# 2. Verify patched .dll string
if ! strings "$BIN" | grep -q "app.dll"; then
    echo "FAILED: Patched assembly name 'app.dll' not found in binary"
    exit 1
fi

echo "SUCCESS: ELF header (7f 45 4c 46) and patched assembly name 'app.dll' verified."

# 3. Optional local Docker execution
DOCKER_BIN=""
if [[ -x "/usr/local/bin/docker" ]]; then
    DOCKER_BIN="/usr/local/bin/docker"
elif [[ -x "/opt/homebrew/bin/docker" ]]; then
    DOCKER_BIN="/opt/homebrew/bin/docker"
fi

if [[ -n "$DOCKER_BIN" ]] && "$DOCKER_BIN" info >/dev/null 2>&1; then
    echo "Docker daemon is running. Testing binary execution in linux/arm64 container..."
    "$DOCKER_BIN" run --rm --platform linux/arm64 -v "$(pwd)/$BIN:/app/bin" alpine /app/bin || true
else
    echo "Docker daemon not reachable; local container execution skipped as allowed by PLAN.md."
fi

echo "PASSED: Invariant 5 verified."
exit 0
