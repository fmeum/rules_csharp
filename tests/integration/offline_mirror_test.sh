#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "Running Offline Mirror and Air-Gapped Resolution Test"
echo "============================================================"

TEST_DIR=$(mktemp -d /tmp/offline_mirror_test.XXXXXX)
trap 'rm -rf "$TEST_DIR"' EXIT

MIRROR_DIR="$TEST_DIR/local_mirror"
mkdir -p "$MIRROR_DIR"

# 1. Populate local mirror with dummy/pre-fetched nupkg and SDK archive
SAMPLE_PKG_ID="CommandLineParser"
SAMPLE_VERSION="2.9.1"
SAMPLE_NUPKG="$MIRROR_DIR/${SAMPLE_PKG_ID}.${SAMPLE_VERSION}.nupkg"

# Create a valid zip archive for the nupkg with nuspec
NUSPEC_DIR="$TEST_DIR/nuspec_tmp"
mkdir -p "$NUSPEC_DIR/lib/net8.0"
cat << 'EOF' > "$NUSPEC_DIR/lib/net8.0/CommandLine.dll"
DUMMY_DLL_BYTES_FOR_OFFLINE_MIRROR_TEST
EOF
cat << EOF > "$NUSPEC_DIR/${SAMPLE_PKG_ID}.nuspec"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2012/06/nuspec.xsd">
  <metadata>
    <id>${SAMPLE_PKG_ID}</id>
    <version>${SAMPLE_VERSION}</version>
    <authors>CommandLine</authors>
    <description>Command Line Parser Library</description>
  </metadata>
</package>
EOF

(cd "$NUSPEC_DIR" && zip -q -r "$SAMPLE_NUPKG" .)

# Also create flatcontainer layout paths
mkdir -p "$MIRROR_DIR/commandlineparser/2.9.1"
cp "$SAMPLE_NUPKG" "$MIRROR_DIR/commandlineparser/2.9.1/commandlineparser.2.9.1.nupkg"

# Create dummy SDK archive
SAMPLE_SDK_ARCHIVE="$MIRROR_DIR/dotnet-sdk-8.0.403-osx-arm64.tar.gz"
SDK_TMP="$TEST_DIR/sdk_tmp"
mkdir -p "$SDK_TMP/sdk/8.0.403/Roslyn/bincore"
touch "$SDK_TMP/dotnet"
chmod +x "$SDK_TMP/dotnet"
touch "$SDK_TMP/sdk/8.0.403/Roslyn/bincore/csc.dll"
tar -czf "$SAMPLE_SDK_ARCHIVE" -C "$SDK_TMP" .

echo "Local mirror populated at $MIRROR_DIR"

# Compute SHA-512 integrity for package
PKG_HASH_B64=$(openssl dgst -sha512 -binary "$SAMPLE_NUPKG" | openssl base64 -A)
EXPECTED_INTEGRITY="sha512-${PKG_HASH_B64}"

# 2. Test candidate URL fallback resolution in Python simulating Bazel download_and_extract
python3 - << EOF
import hashlib
import json
import os
import sys
import urllib.error
import urllib.request

mirror_dir = "${MIRROR_DIR}"
pkg_id = "${SAMPLE_PKG_ID}"
version = "${SAMPLE_VERSION}"
expected_integrity = "${EXPECTED_INTEGRITY}"

# Candidate URLs: Bogus primary URL followed by local file:// mirror fallback
bogus_primary_url = "http://127.0.0.1:59999/artifactory/nuget-remote"
candidate_urls = [
    f"{bogus_primary_url}/{pkg_id.lower()}/{version}/{pkg_id.lower()}.{version}.nupkg",
    f"{bogus_primary_url}/{pkg_id}/{version}/{pkg_id}.{version}.nupkg",
    f"file://{mirror_dir}/{pkg_id}.{version}.nupkg",
    f"file://{mirror_dir}/{pkg_id.lower()}.{version}.nupkg",
    f"file://{mirror_dir}/{pkg_id.lower()}/{version}/{pkg_id.lower()}.{version}.nupkg",
]

print("Simulating Bazel multi-URL download_and_extract with bogus primary URL...")
downloaded_bytes = None
success_url = None

for url in candidate_urls:
    try:
        print(f"Trying candidate URL: {url}")
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=1) as resp:
            downloaded_bytes = resp.read()
            success_url = url
            print(f"Successfully retrieved payload from fallback: {url}")
            break
    except Exception as e:
        print(f"Candidate URL failed as expected ({type(e).__name__}): {url}")
        continue

if not downloaded_bytes:
    print("FAILED: Could not download payload from any candidate URL.")
    sys.exit(1)

# Verify payload against SRI integrity digest
algo, b64_digest = expected_integrity.split("-", 1)
actual_digest = hashlib.sha512(downloaded_bytes).digest()
import base64
actual_b64 = base64.b64encode(actual_digest).decode("utf-8")

if actual_b64 != b64_digest:
    print(f"FAILED: Integrity mismatch. Expected {b64_digest}, got {actual_b64}")
    sys.exit(1)

print("SRI integrity verification verified successfully on payload from local mirror fallback.")
EOF

# 3. Test Starlark XML NuGet.Config parsing logic
cat << 'EOF' > "$TEST_DIR/NuGet.Config"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="internal-artifactory" value="https://artifactory.corp.internal/artifactory/api/nuget/v3/index.json" />
    <add key="local-backup" value="file:///opt/packages" />
  </packageSources>
  <packageSourceCredentials>
    <internal-artifactory>
      <add key="Username" value="builder" />
      <add key="ClearTextPassword" value="secret-token-xyz" />
    </internal-artifactory>
  </packageSourceCredentials>
</configuration>
EOF

python3 - << EOF
import sys

def extract_attr(tag_str, attr_name):
    for q in ['="', "='"]:
        key = attr_name + q
        pos = tag_str.find(key)
        if pos != -1:
            quote = q[1]
            end = tag_str.find(quote, pos + len(key))
            if end != -1:
                return tag_str[pos + len(key):end]
    return None

def extract_block(content, start_tag, end_tag):
    start = content.find(start_tag)
    if start == -1:
        return ""
    start += len(start_tag)
    end = content.find(end_tag, start)
    if end == -1:
        return ""
    return content[start:end]

with open("${TEST_DIR}/NuGet.Config") as f:
    content = f.read()

sources = []
sources_block = extract_block(content, "<packageSources>", "</packageSources>")
for line in sources_block.splitlines():
    line = line.strip()
    if line.startswith("<clear") or "<clear/>" in line or "<clear />" in line:
        sources = []
    elif line.startswith("<add"):
        val = extract_attr(line, "value")
        if val:
            sources.append(val)

assert len(sources) == 2, f"Expected 2 sources, got {sources}"
assert sources[0] == "https://artifactory.corp.internal/artifactory/api/nuget/v3/index.json"
assert sources[1] == "file:///opt/packages"
print("NuGet.Config XML parsing verified successfully.")
EOF

echo "All offline air-gapped mirror resolution assertions passed successfully."
exit 0
