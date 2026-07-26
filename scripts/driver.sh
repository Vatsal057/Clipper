#!/usr/bin/env bash
# Clipper driver — build, run, screenshot, distribute.
# Run from repo root: scripts/driver.sh <cmd>
#   build   regen xcodeproj + xcodebuild
#   run     launch the built .app
#   shot    capture window to scripts/shots/app.png
#   stop    quit the app
#   dist    Release build -> dist/Clipper.dmg
#   all     build + run + shot
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"

APP_NAME="Clipper"
EXT_NAME=""   # no widget extension

SCRIPTS="scripts"
APP="build/Build/Products/Debug/$APP_NAME.app"

team() {
  security find-certificate -c "Apple Development" -p 2>/dev/null \
    | openssl x509 -noout -subject 2>/dev/null | grep -oE 'OU=[A-Z0-9]+' | head -1 | cut -d= -f2
}

case "${1:-all}" in
  build)
    ruby "$SCRIPTS/gen_project.rb"
    T=$(team); [ -n "$T" ] || { echo "No Apple Development cert found. Install Xcode and sign in with your Apple ID."; exit 1; }
    xcodebuild -project "$APP_NAME.xcodeproj" -scheme "$APP_NAME" -configuration Debug \
      -destination 'platform=macOS' -derivedDataPath build \
      DEVELOPMENT_TEAM="$T" -allowProvisioningUpdates build \
      | grep -E "error:|warning: .*(deprecated|unused)|BUILD (SUCCEEDED|FAILED)" || true
    ;;
  run)
    killall "$APP_NAME" 2>/dev/null || true
    open "$APP"
    ;;
  shot)
    osascript -e "tell application \"$APP_NAME\" to activate" 2>/dev/null || true
    sleep 2
    mkdir -p "$SCRIPTS/shots"
    WID=$(APP_NAME="$APP_NAME" python3 - <<'PY'
import os, Quartz
for w in Quartz.CGWindowListCopyWindowInfo(Quartz.kCGWindowListOptionOnScreenOnly, Quartz.kCGNullWindowID):
    if w.get('kCGWindowOwnerName') == os.environ['APP_NAME'] and w.get('kCGWindowLayer') == 0:
        print(w['kCGWindowNumber']); break
PY
)
    if [ -n "$WID" ]; then
      screencapture -o -l"$WID" "$SCRIPTS/shots/app.png"
    else
      screencapture -o -x "$SCRIPTS/shots/app.png"
    fi
    echo "wrote $SCRIPTS/shots/app.png"
    ;;
  stop) killall "$APP_NAME" 2>/dev/null || true ;;
  dist)
    ruby "$SCRIPTS/gen_project.rb"
    T=$(team); [ -n "$T" ] || { echo "No Apple Development cert found"; exit 1; }
    xcodebuild -project "$APP_NAME.xcodeproj" -scheme "$APP_NAME" -configuration Release \
      -destination 'platform=macOS' -derivedDataPath build \
      DEVELOPMENT_TEAM="$T" -allowProvisioningUpdates build \
      | grep -E "error:|BUILD (SUCCEEDED|FAILED)" || true
    RAPP="build/Build/Products/Release/$APP_NAME.app"
    [ -d "$RAPP" ] || { echo "Release build missing"; exit 1; }
    rm -f "$RAPP/Contents/embedded.provisionprofile"
    codesign --force --options runtime --timestamp=none \
      --entitlements "Clipper/Clipper.entitlements" \
      --sign "Apple Development" "$RAPP"
    codesign --verify --deep --strict "$RAPP" && echo "codesign OK"
    mkdir -p dist/stage && rm -rf dist/stage/* "dist/$APP_NAME.dmg"
    cp -R "$RAPP" dist/stage/
    ln -s /Applications dist/stage/Applications
    hdiutil create -volname "$APP_NAME" -srcfolder dist/stage -ov -format UDZO \
      "dist/$APP_NAME.dmg" >/dev/null
    rm -rf dist/stage
    echo "wrote dist/$APP_NAME.dmg"
    ;;
  all) "$0" build && "$0" run && sleep 3 && "$0" shot ;;
  *) echo "usage: driver.sh {build|run|shot|stop|dist|all}"; exit 2 ;;
esac
