#!/bin/bash
set -euo pipefail
RADAR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RADAR_MODE="${1:-run}"
RADAR_BUNDLE="$RADAR_ROOT/.build/DerivedData/Build/Products/Debug/Radar.app"
case "$RADAR_MODE" in
  run|--verify|--build-only) ;;
  *) echo "Uso: $0 [run|--verify|--build-only]" >&2; exit 2 ;;
esac
if [[ "$RADAR_MODE" != "--build-only" ]]; then
  while IFS= read -r radar_pid; do
    radar_executable="$(/bin/ps -p "$radar_pid" -o comm= 2>/dev/null || true)"
    if [[ "$radar_executable" == "$RADAR_BUNDLE/Contents/MacOS/Radar" ]]; then
      /bin/kill "$radar_pid" 2>/dev/null || true
    fi
  done < <(/usr/bin/pgrep -x Radar || true)
fi
/usr/bin/xcodebuild -quiet -project "$RADAR_ROOT/Radar.xcodeproj" -scheme Radar -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath "$RADAR_ROOT/.build/DerivedData" build
if [[ "$RADAR_MODE" != "--build-only" ]]; then
  /usr/bin/open -n "$RADAR_BUNDLE"
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
