#!/bin/bash
set -euo pipefail

if [[ $# -ne 0 ]]; then
  echo "Uso: $0" >&2
  exit 2
fi

RADAR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RADAR_PACKAGING="$RADAR_ROOT/.build/Packaging"
RADAR_BUNDLE="$RADAR_PACKAGING/DerivedData/Build/Products/Release/Radar.app"
RADAR_OUTPUT="$RADAR_ROOT/dist"

# Build separado do app em uso; nunca copiar preferências ou credenciais locais.
/usr/bin/xcodebuild -quiet -project "$RADAR_ROOT/Radar.xcodeproj" -scheme Radar \
  -configuration Release -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$RADAR_PACKAGING/DerivedData" build

/usr/bin/codesign --verify --deep --strict "$RADAR_BUNDLE"
RADAR_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$RADAR_BUNDLE/Contents/Info.plist")"
if [[ ! "$RADAR_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo 'Versão do bundle inválida para empacotamento.' >&2
  exit 1
fi
RADAR_FILENAME="Radar-$RADAR_VERSION-apple-silicon.dmg"
if [[ -e "$RADAR_OUTPUT/$RADAR_FILENAME" || -e "$RADAR_OUTPUT/$RADAR_FILENAME.sha256" ]]; then
  echo 'O pacote dessa versão já existe em dist; preserve-o antes de gerar outro.' >&2
  exit 1
fi

/bin/mkdir -p "$RADAR_OUTPUT"
RADAR_STAGE="$(/usr/bin/mktemp -d "$RADAR_PACKAGING/stage.XXXXXX")"
trap '/bin/rm -rf "$RADAR_STAGE"' EXIT
/bin/mkdir "$RADAR_STAGE/disk"
/usr/bin/ditto --norsrc --noextattr "$RADAR_BUNDLE" "$RADAR_STAGE/disk/Radar.app"
/usr/bin/codesign --verify --deep --strict "$RADAR_STAGE/disk/Radar.app"
/bin/ln -s /Applications "$RADAR_STAGE/disk/Aplicativos"
/bin/cp "$RADAR_ROOT/docs/installation.txt" "$RADAR_STAGE/disk/LEIA-ME.txt"

/usr/bin/hdiutil create -quiet -volname Radar -fs HFS+ -format UDZO \
  -srcfolder "$RADAR_STAGE/disk" "$RADAR_STAGE/$RADAR_FILENAME"
/usr/bin/hdiutil verify "$RADAR_STAGE/$RADAR_FILENAME"
/bin/mv "$RADAR_STAGE/$RADAR_FILENAME" "$RADAR_OUTPUT/$RADAR_FILENAME"
(
  cd "$RADAR_OUTPUT"
  /usr/bin/shasum -a 256 "$RADAR_FILENAME" > "$RADAR_FILENAME.sha256"
)
echo "DMG pessoal gerado: $RADAR_OUTPUT/$RADAR_FILENAME"
echo 'Assinatura ad-hoc; sem notarização. Primeira abertura no outro Mac precisa de validação.'
