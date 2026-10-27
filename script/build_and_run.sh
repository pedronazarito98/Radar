#!/bin/bash
set -euo pipefail
RADAR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RADAR_MODE="${1:-run}"
RADAR_BUNDLE="$RADAR_ROOT/.build/DerivedData/Build/Products/Debug/Radar.app"
RADAR_DERIVED_DATA="$RADAR_ROOT/.build/DerivedData"
RADAR_BUILD_OPTIONS=()
RADAR_LAUNCH_OPTIONS=()
case "$RADAR_MODE" in
  run|--verify|--build-only) ;;
  --demo)
    RADAR_DERIVED_DATA="$RADAR_ROOT/.build/DemoDerivedData"
    RADAR_BUNDLE="$RADAR_DERIVED_DATA/Build/Products/Debug/RadarDemo.app"
    RADAR_BUILD_OPTIONS=(PRODUCT_NAME=RadarDemo PRODUCT_BUNDLE_IDENTIFIER=dev.pedronazarito.Radar.demo)
    RADAR_LAUNCH_OPTIONS=(--args --demo)
    ;;
  *) echo "Uso: $0 [run|--verify|--build-only|--demo]" >&2; exit 2 ;;
esac
if [[ "$RADAR_MODE" != "--build-only" ]]; then
  while IFS= read -r radar_pid; do
    radar_executable="$(/bin/ps -p "$radar_pid" -o comm= 2>/dev/null || true)"
    if [[ "$radar_executable" == "$RADAR_BUNDLE/Contents/MacOS/$(basename "$RADAR_BUNDLE" .app)" ]]; then
      /bin/kill "$radar_pid" 2>/dev/null || true
    fi
  done < <(/usr/bin/pgrep -x 'Radar|RadarDemo' || true)
fi
/usr/bin/xcodebuild -quiet -project "$RADAR_ROOT/Radar.xcodeproj" -scheme Radar -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath "$RADAR_DERIVED_DATA" "${RADAR_BUILD_OPTIONS[@]}" build
if [[ "$RADAR_MODE" != "--build-only" ]]; then
  /usr/bin/open -n "$RADAR_BUNDLE" "${RADAR_LAUNCH_OPTIONS[@]}"
fi
if [[ "$RADAR_MODE" == "--verify" ]]; then
  /bin/sleep 1
  radar_found=0
  while IFS= read -r radar_pid; do
    radar_executable="$(/bin/ps -p "$radar_pid" -o comm= 2>/dev/null || true)"
    if [[ "$radar_executable" == "$RADAR_BUNDLE/Contents/MacOS/Radar" ]]; then
      radar_found=1
    fi
  done < <(/usr/bin/pgrep -x Radar || true)
  [[ "$radar_found" == 1 ]]
  echo 'Build e processo Radar confirmados; interação da UI é um gate separado.'
fi
