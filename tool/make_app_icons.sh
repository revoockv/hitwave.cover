#!/usr/bin/env bash
# Makes the app icon of every platform from assets/icon/app_icon.svg.
#   tool/make_app_icons.sh
# Change the SVG, run this, commit the result. Needs rsvg-convert (brew install librsvg).
#
# The SVG is a rounded tile; the platforms want different cuts of it, rendered into
# build/app_icon/ (not in git):
#   app_icon.png             the rounded tile (web, Windows, Android before 8)
#   app_icon_square.png      no rounded corners, no transparency (iOS rounds them itself)
#   app_icon_macos.png       the tile at 824 of 1024 px with a soft shadow (Apple's macOS grid)
#   app_icon_foreground.png  only the guitar, in the safe zone of an Android adaptive icon
# The background of the tile and of the Android adaptive icon is the same color (#E4E8EE).
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_svg="$root/assets/icon/app_icon.svg"
out="$root/build/app_icon"
mkdir -p "$out"
command -v rsvg-convert >/dev/null || { echo "rsvg-convert is missing: brew install librsvg" >&2; exit 1; }

render() { rsvg-convert -w 1024 -h 1024 "$1" -o "$2"; }

# The rounded tile as drawn.
render "$source_svg" "$out/app_icon.png"

# Square: the same picture without the rounded clip.
sed 's#<g clip-path="url(\#tile)">#<g>#' "$source_svg" > "$out/square.svg"
render "$out/square.svg" "$out/app_icon_square.png"

# macOS: the tile on Apple's 824 px grid, with a soft shadow under it.
cat > "$out/macos.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <filter id="drop" x="-20%" y="-20%" width="140%" height="150%">
      <feGaussianBlur in="SourceAlpha" stdDeviation="14"/><feOffset dy="12"/>
      <feComponentTransfer><feFuncA type="linear" slope="0.28"/></feComponentTransfer>
      <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>
  <g filter="url(#drop)"><image x="100" y="90" width="824" height="824" xlink:href="file://$out/app_icon.png"/></g>
</svg>
SVG
render "$out/macos.svg" "$out/app_icon_macos.png"

# Android adaptive foreground: the guitar alone, scaled into the 66% safe zone.
sed -e 's#<g clip-path="url(\#tile)">#<g transform="translate(512 512) scale(0.62) translate(-512 -512)">#' \
    -e 's#<rect width="1024" height="1024" fill="\#E4E8EE"/>##' "$source_svg" > "$out/foreground.svg"
render "$out/foreground.svg" "$out/app_icon_foreground.png"

cd "$root"
dart run flutter_launcher_icons
