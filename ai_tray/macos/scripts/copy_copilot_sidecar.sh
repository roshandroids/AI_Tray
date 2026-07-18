#!/bin/sh

# Copies the preassembled architecture-matched sidecar into a signable resource
# location. Assembly is intentionally separate so Xcode never downloads tools.

set -eu

if [ "${CONFIGURATION:-}" != "Release" ]; then
  exit 0
fi

TARGET_NAME="${COPILOT_SIDECAR_TARGET:-}"
if [ -z "$TARGET_NAME" ]; then
  ARCH="${CURRENT_ARCH:-}"
  if [ -z "$ARCH" ] || [ "$ARCH" = "undefined_arch" ]; then
    ARCH="${ARCHS%% *}"
  fi
  case "$ARCH" in
    arm64)
      TARGET_NAME="macos-arm64"
      ;;
    x86_64)
      TARGET_NAME="macos-x64"
      ;;
    *)
      echo "error: unsupported Copilot sidecar architecture: $ARCH" >&2
      exit 1
      ;;
  esac
fi

case "$TARGET_NAME" in
  macos-arm64)
    CLI_PACKAGE="copilot-darwin-arm64"
    ;;
  macos-x64)
    CLI_PACKAGE="copilot-darwin-x64"
    ;;
  *)
    echo "error: unsupported Copilot sidecar target: $TARGET_NAME" >&2
    exit 1
    ;;
esac

SOURCE_ROOT="${SRCROOT}/../build/copilot_sdk/${TARGET_NAME}"
DESTINATION="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/copilot_sdk"

if [ ! -f "${SOURCE_ROOT}/payload-manifest.json" ]; then
  echo "error: missing ${TARGET_NAME} payload; run npm run distribution:assemble" >&2
  exit 1
fi

rm -rf "$DESTINATION"
mkdir -p "$(dirname "$DESTINATION")"
/usr/bin/ditto "$SOURCE_ROOT" "$DESTINATION"

NODE_EXECUTABLE="${DESTINATION}/node/bin/node"
CLI_EXECUTABLE="${DESTINATION}/bridge/node_modules/@github/${CLI_PACKAGE}/copilot"
chmod 755 "$NODE_EXECUTABLE" "$CLI_EXECUTABLE"

if [ "${CODE_SIGNING_ALLOWED:-NO}" = "YES" ] &&
   [ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ] &&
   [ "${EXPANDED_CODE_SIGN_IDENTITY}" != "-" ]; then
  HELPER_ENTITLEMENTS="${SRCROOT}/Runner/Release.entitlements"
  /usr/bin/codesign --force --options runtime --entitlements \
    "$HELPER_ENTITLEMENTS" --sign \
    "$EXPANDED_CODE_SIGN_IDENTITY" "$NODE_EXECUTABLE"
  /usr/bin/codesign --force --options runtime --entitlements \
    "$HELPER_ENTITLEMENTS" --sign \
    "$EXPANDED_CODE_SIGN_IDENTITY" "$CLI_EXECUTABLE"
  find "$DESTINATION" -type f -name '*.node' -print0 |
    while IFS= read -r -d '' native_module; do
      /usr/bin/codesign --force --options runtime --sign \
        "$EXPANDED_CODE_SIGN_IDENTITY" "$native_module"
    done
fi
