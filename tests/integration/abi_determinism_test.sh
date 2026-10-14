#!/usr/bin/env bash
set -euo pipefail

VAR1_REF=$(find . -path "*abi_var1*lib.ref.dll" | head -n 1)
VAR2_REF=$(find . -path "*abi_var2*lib.ref.dll" | head -n 1)
VAR1_DLL=$(find . -path "*abi_var1*lib.dll" | head -n 1)
VAR2_DLL=$(find . -path "*abi_var2*lib.dll" | head -n 1)

if [[ -z "$VAR1_REF" || -z "$VAR2_REF" || -z "$VAR1_DLL" || -z "$VAR2_DLL" ]]; then
    echo "Error: Could not locate built assemblies in runfiles."
    echo "Found files:"
    find . -name "*.dll"
    exit 1
fi

HASH1_REF=$(shasum -a 256 "$VAR1_REF" | awk '{print $1}')
HASH2_REF=$(shasum -a 256 "$VAR2_REF" | awk '{print $1}')
HASH1_DLL=$(shasum -a 256 "$VAR1_DLL" | awk '{print $1}')
HASH2_DLL=$(shasum -a 256 "$VAR2_DLL" | awk '{print $1}')

echo "abi_var1/lib.ref.dll SHA-256: $HASH1_REF"
echo "abi_var2/lib.ref.dll SHA-256: $HASH2_REF"
echo "abi_var1/lib.dll     SHA-256: $HASH1_DLL"
echo "abi_var2/lib.dll     SHA-256: $HASH2_DLL"

if [[ "$HASH1_REF" != "$HASH2_REF" ]]; then
    echo "FAILED: .ref.dll hashes differ! Expected identical refouts for identical public APIs."
    exit 1
fi

if [[ "$HASH1_DLL" == "$HASH2_DLL" ]]; then
    echo "FAILED: .dll hashes match! Expected different implementation dlls for different method bodies."
    exit 1
fi

echo "PASSED: Invariant 2 verified. Byte-identical .ref.dll outputs with differing implementation .dlls."
exit 0
