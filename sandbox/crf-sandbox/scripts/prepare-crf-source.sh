#!/usr/bin/env bash
set -euo pipefail

# Prepare the REDCap source tree expected by docker/docker-compose.yml.
#
# Two supported workflows :
#   1. Manual unzip : extract the official REDCap ZIP into
#      `upstream/versions/v<MAJOR>.<MINOR>.<PATCH>/redcap/` (zero-padded
#      for lexicographic sortability). This script detects it and exits 0.
#   2. ZIP-based   : set REDCAP_ZIP to the official archive path
#      (`redcap<version>.zip`, e.g. `redcap16.1.9.zip`). This script
#      extracts it into the same versioned directory.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$SANDBOX_DIR/../.." && pwd)"

# Convention : `v` prefix + zero-padded segments (e.g. `v16.01.09`) pour
# la sortabilité lexicographique des sous-répertoires de `upstream/versions/`.
# Le ZIP officiel REDCap reste nommé `redcap<version>.zip` (sans `v` ni
# padding) — utiliser `REDCAP_ZIP` pour pointer vers lui explicitement.
REDCAP_VERSION="${REDCAP_VERSION:-v16.01.09}"
VERSIONS_DIR="$SANDBOX_DIR/upstream/versions"
SHARED_EDOCS_DIR="$SANDBOX_DIR/upstream/shared/edocs"
TARGET_DIR="$VERSIONS_DIR/$REDCAP_VERSION/redcap"

ZIP_PATH="${REDCAP_ZIP:-}"
if [ -z "$ZIP_PATH" ]; then
  if [ -f "$SANDBOX_DIR/upstream/redcap${REDCAP_VERSION}.zip" ]; then
    ZIP_PATH="$SANDBOX_DIR/upstream/redcap${REDCAP_VERSION}.zip"
  else
    ZIP_PATH="$REPO_ROOT/cli/crf-openapi/upstream/redcap${REDCAP_VERSION}.zip"
  fi
fi

mkdir -p "$VERSIONS_DIR" "$SHARED_EDOCS_DIR"
chmod 777 "$SHARED_EDOCS_DIR" 2>/dev/null || true

if [ -f "$TARGET_DIR/api/index.php" ]; then
  echo "REDCap $REDCAP_VERSION source already prepared at $TARGET_DIR"
  exit 0
fi

if [ ! -f "$ZIP_PATH" ]; then
  echo "REDCap archive not found for version $REDCAP_VERSION."
  echo "Expected: $ZIP_PATH"
  echo "Either set REDCAP_ZIP to the official redcap<version>.zip path,"
  echo "or manually unzip into $TARGET_DIR/redcap/ (see header comment)."
  exit 1
fi

TMP_DIR="$(mktemp -d "$VERSIONS_DIR/.extract-${REDCAP_VERSION}.XXXXXX")"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "Extracting REDCap $REDCAP_VERSION from $ZIP_PATH"
unzip -q -o "$ZIP_PATH" -d "$TMP_DIR"

if [ ! -f "$TMP_DIR/redcap/api/index.php" ]; then
  echo "Invalid REDCap archive: expected redcap/api/index.php after extraction."
  exit 1
fi

rm -rf "$VERSIONS_DIR/$REDCAP_VERSION"
mkdir -p "$VERSIONS_DIR/$REDCAP_VERSION"
mv "$TMP_DIR/redcap" "$TARGET_DIR"

echo "REDCap $REDCAP_VERSION source prepared at $TARGET_DIR"
